import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:savvy_stock/core/repositories/base_repo.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/admin/users/models/user_model.dart';
import 'package:savvy_stock/features/auth/model/subscription_management_model.dart';
import 'package:savvy_stock/features/registration/model/signup_data_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:savvy_stock/core/services/supabase/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Result of registration operation
class RegistrationResult {
  final bool success;
  final String message;
  final int? userId;
  final String? confirmationCode;

  const RegistrationResult({
    required this.success,
    required this.message,
    this.userId,
    this.confirmationCode,
  });
}

/// Service handling user registration - mirrors Java RegistrationService
class RegistrationService extends BaseRepository {
  @override
  final LocalDatabaseService databaseService;
  final http.Client httpClient;

  RegistrationService({required this.databaseService, http.Client? httpClient})
    : httpClient = httpClient ?? http.Client();

  /// Main registration method - creates all entities in a transaction
  /// Mirrors Java's register(SignupData signupData) method
  Future<RegistrationResult> register(SignupData signupData) async {
    final db = await databaseService.database;

    try {
      // Validate input
      if (signupData.initialSettings == null) {
        return const RegistrationResult(
          success: false,
          message: 'Configuration error: Subscription settings missing',
        );
      }

      final settings = signupData.initialSettings!;
      final registrationTime = DateTime.now();
      final hashedPassword = await UserModel.sha256Hash(
        signupData.adminUser.password!,
      );
      final confirmationCode = _generateConfirmationCode();
      final confirmationExpireTime = registrationTime.add(
        const Duration(minutes: 10),
      );

      // Check company count limit (max 1 for this app)
      final companyCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM company_table'),
      );
      if (companyCount != null && companyCount > 0) {
        return const RegistrationResult(
          success: false,
          message: 'LIMIT_EXCEEDED: Only one company can be registered',
        );
      }

      final usernameAvailable = await isUsernameAvailable(
        signupData.adminUser.userName!,
      );
      if (!usernameAvailable) {
        return const RegistrationResult(
          success: false,
          message: 'Username already taken',
        );
      }

      final baseCompanyMap = signupData.company
          .copyWith(
            userLimmit: settings.initialSubscriptionUsers,
            branchLimmit: settings.initialSubscriptionBranches,
            emailAddress1: signupData.adminUser.userEmail,
            daysLeft: settings.initialSubscriptionDays,
            subscriptionFee: settings.initialPayment,
            dateCreated: registrationTime,
          )
          .toMap();
      baseCompanyMap.remove('id');
      final payloadForCompany = withSyncKey(
        _blankStringsToNull(baseCompanyMap),
      );

      final baseBranchMap = withSyncKey(_buildBranchMap(signupData));
      final baseEmployeeMap = withSyncKey(_buildEmployeeMap(signupData));
      final serverUserMap = withSyncKey(
        _buildServerUserMap(signupData: signupData),
      );

      final verifyResult = await _verifyUserWithServer(
        company: payloadForCompany,
        branch: baseBranchMap,
        employee: baseEmployeeMap,
        user: serverUserMap,
      );

      if (!verifyResult.success) {
        return RegistrationResult(
          success: false,
          message: verifyResult.message,
        );
      }

      final verifiedCompanyId = verifyResult.companyId!;
      final verifiedBranchId = verifyResult.branchId;
      final verifiedEmployeeId = verifyResult.employeeId;
      final verifiedUserId = verifyResult.userId;
      if (verifiedBranchId == null ||
          verifiedBranchId <= 0 ||
          verifiedEmployeeId == null ||
          verifiedEmployeeId <= 0 ||
          verifiedUserId == null ||
          verifiedUserId <= 0) {
        return const RegistrationResult(
          success: false,
          message:
              'Server did not return valid branch, employee, and user ids.',
        );
      }

      final existingCompanyIdCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM company_table WHERE id = ?', [
          verifiedCompanyId,
        ]),
      );
      if (existingCompanyIdCount != null && existingCompanyIdCount > 0) {
        return const RegistrationResult(
          success: false,
          message: 'Company id already exists locally',
        );
      }
      if (await _idExists('branch_table', verifiedBranchId) ||
          await _idExists('employees', verifiedEmployeeId) ||
          await _idExists('user_table', verifiedUserId)) {
        return const RegistrationResult(
          success: false,
          message: 'Server id already exists locally',
        );
      }

      // Perform all inserts in a transaction
      int? userId;

      await db.transaction((txn) async {
        // 1. Create Company with subscription limits
        payloadForCompany['id'] = verifiedCompanyId;
        final companyId = await txn.insert('company_table', payloadForCompany);
        await captureSync(
          tableName: 'company_table',
          entityMap: payloadForCompany,
          entityId: companyId.toString(),
          operation: 'UPDATE',
          company: companyId.toString(),
          txn: txn,
        );
        developer.log('Created company with ID: $companyId');

        // 1.5 Insert SubscriptionManagement plan explicitly
        final payloadForSubscription = withSyncKey({
          'name': settings.name ?? 'Free Trial',
          'description': settings.description ?? 'Free trial subscription',
          'initial_subscription_branches': settings.initialSubscriptionBranches,
          'initial_subscription_users': settings.initialSubscriptionUsers,
          'initial_payment': settings.initialPayment,
          'initial_subscription_days': settings.initialSubscriptionDays,
          'status': _normalizeServerStatus(settings.status),
        });
        final subscriptionId = await txn.insert(
          'subscription_management',
          payloadForSubscription,
        );
        await captureSync(
          tableName: 'subscription_management',
          entityMap: payloadForSubscription,
          entityId: subscriptionId.toString(),
          operation: 'INSERT',
          company: companyId.toString(),
          txn: txn,
        );

        // 2. Create CompanySubscription
        final now = DateTime.now();
        final expireDate = now.add(
          Duration(days: settings.initialSubscriptionDays ?? 7),
        );

        final payloadForCompanySubscription = withSyncKey({
          'company_id': companyId,
          'subscription_id':
              subscriptionId, // Use the new subscription ID directly
          'date_subscribed': now.toIso8601String(),
          'date_effective': now.toIso8601String(),
          'date_expire': expireDate.toIso8601String(),
          'status': 'Active',
        });
        final id = await txn.insert(
          'company_subscription',
          payloadForCompanySubscription,
        );
        await captureSync(
          tableName: 'company_subscription',
          entityMap: payloadForCompanySubscription,
          entityId: id.toString(),
          operation: 'INSERT',
          company: companyId.toString(),
          txn: txn,
        );
        developer.log('Created company subscription');

        // 3. Create Branch
        final branchMap = Map<String, dynamic>.from(baseBranchMap);
        branchMap['id'] = verifiedBranchId;
        branchMap['company'] = companyId;

        final payloadForBranch = withSyncKey(branchMap);
        final branchId = await txn.insert('branch_table', payloadForBranch);
        await captureSync(
          tableName: 'branch_table',
          entityMap: payloadForBranch,
          entityId: branchId.toString(),
          operation: 'UPDATE',
          company: companyId.toString(),
          txn: txn,
        );
        developer.log('Created branch with ID: $branchId');

        // 4. Create Employee
        final employeeMap = Map<String, dynamic>.from(baseEmployeeMap);
        employeeMap['id'] = verifiedEmployeeId;
        employeeMap['company'] = companyId;
        employeeMap['branch'] = branchId;

        final payloadForEmployee = withSyncKey(employeeMap);
        final employeeId = await txn.insert('employees', payloadForEmployee);
        await captureSync(
          tableName: 'employees',
          entityMap: payloadForEmployee,
          entityId: employeeId.toString(),
          operation: 'UPDATE',
          company: companyId.toString(),
          txn: txn,
        );
        developer.log('Created employee with ID: $employeeId');

        // 5. Create Admin User
        final userMap = {
          'id': verifiedUserId,
          'employees_id': employeeId,
          'branch': branchId,
          'company': companyId,
          'password': hashedPassword,
          'status': 'Active',
          'date_created': registrationTime.millisecondsSinceEpoch,
          'password_last_updated': registrationTime.millisecondsSinceEpoch,
          'confirmation_code': confirmationCode,
          'confirmations_expire_time':
              confirmationExpireTime.millisecondsSinceEpoch,
          'user_email': signupData.adminUser.userEmail,
          'user_name': signupData.adminUser.userName,
          'type': 'Company',
          'sync_key': serverUserMap['sync_key'],
        };

        final payloadForUser = withSyncKey(userMap);
        userId = await txn.insert('user_table', payloadForUser);
        await captureSync(
          tableName: 'user_table',
          entityMap: payloadForUser,
          entityId: userId.toString(),
          operation: 'UPDATE',
          company: companyId.toString(),
          txn: txn,
        );
        developer.log('Created user with ID: $userId');

        // 6. Create FS Table entry
        final companyName = signupData.company.companyName;
        final branchDesc = signupData.primaryBranch.description ?? '';
        final prefixCode = _generateCompanyCodePre(companyName);
        final postfixCode = _generateCompanyCodePost(
          '$companyName $branchDesc',
        );

        final payloadForFsTable = withSyncKey({
          'fs_number': 1,
          'branch': branchId,
          'mrc_number': prefixCode,
          'company': companyId,
          'prefix_up_to_three': prefixCode,
          'postfix_up_to_four': postfixCode,
        });
        final idFs = await txn.insert('fs_table', payloadForFsTable);
        await captureSync(
          tableName: 'fs_table',
          entityMap: payloadForFsTable,
          entityId: idFs.toString(),
          operation: 'INSERT',
          company: companyId.toString(),
          txn: txn,
        );
        developer.log('Created FS table entry');

        // 7. Copy default roles and assign to user
        final defaultRoles = await txn.rawQuery('''
          SELECT * FROM role_table WHERE company IS NULL
        ''');

        if (defaultRoles.isEmpty) {
          developer.log('Warning: No default roles found, creating admin role');
          // Create a basic admin role if none exist
          final payloadForAdminRole = withSyncKey({
            'name': '${signupData.company.companyName} Admin',
            'description': 'Administrator role',
            'company': companyId,
            'date_created': DateTime.now().toIso8601String(),
            'created_by': userId,
          });
          final adminRoleId = await txn.insert(
            'role_table',
            payloadForAdminRole,
          );
          await captureSync(
            tableName: 'role_table',
            entityMap: payloadForAdminRole,
            entityId: adminRoleId.toString(),
            operation: 'INSERT',
            company: companyId.toString(),
            txn: txn,
          );

          // Assign admin role to user
          final payloadForUserRole = withSyncKey({
            'user_id': userId,
            'role_table_id': adminRoleId,
            'created_by': userId,
            'date_created': DateTime.now().toIso8601String(),
          });
          final idUserRole = await txn.insert('user_role', payloadForUserRole);
          await captureSync(
            tableName: 'user_role',
            entityMap: payloadForUserRole,
            entityId: idUserRole.toString(),
            operation: 'INSERT',
            company: companyId.toString(),
            txn: txn,
          );

          // Assign ALL privileges to this Admin role
          final allPrivileges = await txn.query('previlage_table');
          for (final privilege in allPrivileges) {
            // 1. Create the new record map first, THEN wrap it with withSyncKey
            final payload = withSyncKey({
              'role_table_id': adminRoleId,
              'previlage_table_id': privilege['id'],
              'date_created': DateTime.now().toIso8601String(),
              'created_by': userId,
            });
            // 2. Insert the wrapped payload
            final id = await txn.insert('role_privilege', payload);
            // 3. Pass the payload to captureSync
            await captureSync(
              tableName: 'role_privilege',
              entityMap: payload, // Uses the map that now contains sync_key
              entityId: id.toString(),
              operation: 'INSERT',
              company: companyId.toString(),
              txn: txn,
            );
          }
          developer.log('Assigned all privileges to Admin role');
        } else {
          for (final defaultRole in defaultRoles) {
            // Create company-specific role
            final payload = withSyncKey({
              'name':
                  '${signupData.company.companyName} ${defaultRole['name']}',
              'description': defaultRole['description'],
              'company': companyId,
              'date_created': DateTime.now().toIso8601String(),
              'created_by': employeeId,
            });
            final newRoleId = await txn.insert('role_table', payload);
            await captureSync(
              tableName: 'role_table',
              entityMap: payload,
              entityId: newRoleId.toString(),
              operation: 'INSERT',
              company: companyId.toString(),
              txn: txn,
            );

            // Copy privileges for this role
            final defaultPrivileges = await txn.rawQuery(
              '''
              SELECT * FROM role_privilege WHERE role_table_id = ?
            ''',
              [defaultRole['id']],
            );

            for (final privilege in defaultPrivileges) {
              final payload = withSyncKey({
                'role_table_id': newRoleId,
                'previlage_table_id': privilege['previlage_table_id'],
                'date_created': DateTime.now().toIso8601String(),
                'created_by': employeeId,
              });
              final id = await txn.insert('role_privilege', payload);
              await captureSync(
                tableName: 'role_privilege',
                entityMap: payload,
                entityId: id.toString(),
                operation: 'INSERT',
                company: companyId.toString(),
                txn: txn,
              );
            }

            // Assign role to admin user
            final payloadForUserRole = withSyncKey({
              'user_id': userId,
              'role_table_id': newRoleId,
              'created_by': employeeId,
              'date_created': DateTime.now().toIso8601String(),
            });
            final id = await txn.insert('user_role', payloadForUserRole);
            await captureSync(
              tableName: 'user_role',
              entityMap: payloadForUserRole,
              entityId: id.toString(),
              operation: 'INSERT',
              company: companyId.toString(),
              txn: txn,
            );
          }
        }
        developer.log('Created roles and assigned to user');

        // 8. Copy default NextNumbers
        final defaultNextNumbers = await txn.rawQuery('''
          SELECT * FROM next_number WHERE company IS NULL
        ''');

        for (final nn in defaultNextNumbers) {
          final payload = withSyncKey({
            'next_number': nn['next_number'],
            'next_number_code': nn['next_number_code'],
            'next_number_description': nn['next_number_description'],
            'company': companyId,
          });
          final id = await txn.insert('next_number', payload);
          await captureSync(
            tableName: 'next_number',
            entityMap: payload,
            entityId: id.toString(),
            operation: 'INSERT',
            company: companyId.toString(),
            txn: txn,
          );
        }
        developer.log('Created next numbers: ${defaultNextNumbers.length}');

        // 9. Generate default SystemConstants

        final defaultHeaderLotTypeId = await txn.rawQuery(
          "SELECT id FROM udc_header WHERE udc_code = 'LT'",
        );

        final List<Map<String, dynamic>> udcDetails = await txn.query(
          'udc_details',
          columns: ['id'],
          where: "detail_code = ? AND record_header = ?",
          whereArgs: ['X', defaultHeaderLotTypeId.first['id']],
        );

        int? lotTypeId;
        if (udcDetails.isNotEmpty) {
          lotTypeId = udcDetails.first['id'] as int;
        }

        final systemConstPayload = withSyncKey({
          'apply_lot_mgm': 'Y',
          'apply_location_mgm': 'Y',
          'decimal_places': 2,
          'generate_barcode_for_item': 'N',
          'company': companyId,
          'rate_vat_percentage': 15.0,
          'rate_with_percentage': 2.0,
          'with_hold_initials': 1000.0,
          'auto_sales_price': 'N',
          'lot_qty_auto_for_sales': 'Y',
          'discount_display': 'Y',
          'tax_info_display': 'Y',
          'reorder_point_uom_type': 'I',
          'currency_code': 'Birr',
          'pos_integrated': 'N',
          'apply_overhead_cost': 'N',
          'attached_branch_only': 'N',
          'days_left': 180,
          'location_category_level': 1,
          'is_synced': 0,
          'lot_type': lotTypeId,
          'created_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
          'updated_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        });
        final idSc = await txn.insert('system_constant', systemConstPayload);
        await captureSync(
          tableName: 'system_constant',
          entityMap: systemConstPayload,
          entityId: idSc.toString(),
          operation: 'INSERT',
          company: companyId.toString(),
          txn: txn,
        );
        developer.log('Created default system constants');
      });

      developer.log('Registration completed successfully');

      return RegistrationResult(
        success: true,
        message: 'Registration successful',
        userId: userId,
        confirmationCode: confirmationCode,
      );
    } catch (e, stackTrace) {
      developer.log('Registration failed: $e', stackTrace: stackTrace);
      return RegistrationResult(
        success: false,
        message: 'Registration failed: ${e.toString()}',
      );
    }
  }

  /// Check if username is available
  Future<bool> isUsernameAvailable(String username) async {
    final db = await databaseService.database;
    final result = await db.query(
      'user_table',
      where: 'user_name = ?',
      whereArgs: [username],
      limit: 1,
    );
    return result.isEmpty;
  }

  /// Check if email is available
  Future<bool> isEmailAvailable(String email) async {
    final db = await databaseService.database;
    final result = await db.query(
      'user_table',
      where: 'user_email = ?',
      whereArgs: [email],
      limit: 1,
    );
    return result.isEmpty;
  }

  /// Check if company name is available
  Future<bool> isCompanyNameAvailable(String companyName) async {
    final db = await databaseService.database;
    final result = await db.query(
      'company_table',
      where: 'company_name = ?',
      whereArgs: [companyName],
      limit: 1,
    );
    return result.isEmpty;
  }

  /// Get default subscription plan (free trial)
  Future<SubscriptionManagement?> getDefaultSubscription() async {
    final db = await databaseService.database;

    // First try to get an existing subscription plan
    final result = await db.query(
      'subscription_management',
      orderBy: 'id ASC',
      limit: 1,
    );

    if (result.isNotEmpty) {
      return SubscriptionManagement.fromMap(result.first);
    }

    // Just return the default configuration in memory
    // It will be persisted during the registration transaction
    return const SubscriptionManagement(
      name: 'Free Trial',
      description: 'Free trial with 2 branches and 3 users',
      initialSubscriptionBranches: 2,
      initialSubscriptionUsers: 3,
      initialPayment: 0.0,
      initialSubscriptionDays: 5,
      status: 'Active',
    );
  }

  String _normalizeServerStatus(String? status) {
    final trimmed = status?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return 'Active';
    }
    if (trimmed.toLowerCase() == 'active') {
      return 'Active';
    }
    return trimmed;
  }

  /// Generate 6-digit confirmation code
  String _generateConfirmationCode() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  /// Generate company code prefix (first 3 characters)
  /// Mirrors Java's generateCompanyCodePre method
  String _generateCompanyCodePre(String companyName) {
    if (companyName.isEmpty) return '';
    final trimmed = companyName.trim();
    if (trimmed.length >= 3) {
      return trimmed.substring(0, 3).toUpperCase();
    }
    return trimmed.toUpperCase();
  }

  /// Generate company code postfix (4 random characters from words)
  /// Mirrors Java's generateCompanyCodePost method
  String _generateCompanyCodePost(String companyName) {
    if (companyName.isEmpty) return '';

    final trimmed = companyName.trim().toUpperCase();
    final words = trimmed.split(RegExp(r'\s+'));
    final random = Random();
    final code = StringBuffer();

    while (code.length < 4) {
      for (final word in words) {
        if (word.isNotEmpty && code.length < 4) {
          final index = random.nextInt(word.length);
          code.write(word[index]);
        }
      }
      if (code.length < 4) {
        final noSpaces = trimmed.replaceAll(RegExp(r'\s+'), '');
        if (noSpaces.isNotEmpty) {
          final index = random.nextInt(noSpaces.length);
          code.write(noSpaces[index]);
        }
      }
    }

    return code.toString().substring(0, 4);
  }

  /// Send email verification code
  Future<bool> sendEmailVerificationCode(String email) async {
    try {
      await SupabaseService.instance.auth.signInWithOtp(email: email);
      return true;
    } catch (e) {
      developer.log('Error sending verification code: $e');
      return false;
    }
  }

  /// Verify email verification code
  Future<bool> verifyEmailVerificationCode(String email, String code) async {
    try {
      final response = await SupabaseService.instance.auth.verifyOTP(
        token: code,
        type: OtpType.email,
        email: email,
      );
      return response.session != null;
    } catch (e) {
      developer.log('Error verifying code: $e');
      return false;
    }
  }

  Map<String, dynamic> _buildBranchMap(SignupData signupData) {
    final map = Map<String, dynamic>.from(signupData.primaryBranch.toMap());
    map.remove('id');
    map.remove('company');
    return _blankStringsToNull(map);
  }

  Map<String, dynamic> _buildEmployeeMap(SignupData signupData) {
    final map = Map<String, dynamic>.from(signupData.employee.toMap());
    map.remove('id');
    map.remove('company');
    map.remove('branch');
    return _blankStringsToNull(map);
  }

  Map<String, dynamic> _buildServerUserMap({required SignupData signupData}) {
    final map = <String, dynamic>{
      'password': signupData.adminUser.password,
      'user_email': signupData.adminUser.userEmail,
      'user_name': signupData.adminUser.userName,
      'type': 'Company',
    };
    return _blankStringsToNull(map);
  }

  Future<_VerifyUserResult> _verifyUserWithServer({
    required Map<String, dynamic> company,
    required Map<String, dynamic> branch,
    required Map<String, dynamic> employee,
    required Map<String, dynamic> user,
  }) async {
    final baseUrl = await _getServerBaseUrl();
    if (baseUrl == null || baseUrl.isEmpty) {
      return const _VerifyUserResult.failure(
        'No server URL configured. Please configure the server URL first.',
      );
    }

    final payload = jsonEncode({
      'company': _convertKeysToCamelCase(company),
      'branch': _convertKeysToCamelCase(branch),
      'employees': _convertKeysToCamelCase(employee),
      'user': _convertKeysToCamelCase(user),
    });

    http.Response? lastResponse;
    for (final url in _verifyUserUrls(baseUrl)) {
      try {
        developer.log('Content to send: $payload');
        developer.log('RegistrationService: Verifying registration at $url');
        final response = await httpClient
            .post(
              Uri.parse(url),
              headers: const {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'ngrok-skip-browser-warning': 'true',
              },
              body: payload,
            )
            .timeout(const Duration(seconds: 120));

        lastResponse = response;
        developer.log(
          'RegistrationService: verifyUser response '
          '(${response.statusCode}): ${response.body}',
        );
        if (response.statusCode == 404 || response.statusCode == 405) {
          continue;
        }

        if (response.statusCode < 200 || response.statusCode >= 300) {
          return _VerifyUserResult.failure(
            'Server verification failed (${response.statusCode}). Please try again.',
          );
        }

        return _parseVerifyUserResponse(response.body);
      } on FormatException {
        return const _VerifyUserResult.failure(
          'Invalid server verification response.',
        );
      } on TimeoutException {
        return const _VerifyUserResult.failure(
          'Server verification timed out. Please try again.',
        );
      } on http.ClientException {
        return const _VerifyUserResult.failure(
          'Cannot reach server. Please check your internet connection.',
        );
      }
    }

    final status = lastResponse?.statusCode;
    return _VerifyUserResult.failure(
      status == null
          ? 'Could not verify registration with server.'
          : 'Server verification endpoint not found ($status).',
    );
  }

  List<String> _verifyUserUrls(String baseUrl) {
    final normalized = baseUrl.replaceAll(RegExp(r'/+$'), '');
    return <String>{
      //  '$normalized/verifyUser',
      // '$normalized/api/auth/verifyUser',
      '$normalized/api/sync/verifyUser',
    }.toList();
  }

  String _snakeToCamel(String input) {
    final parts = input.split('_');
    if (parts.length <= 1) return input;
    return parts.first +
        parts
            .skip(1)
            .map(
              (part) => part.isEmpty
                  ? ''
                  : '${part[0].toUpperCase()}${part.substring(1)}',
            )
            .join();
  }

  Map<String, dynamic> _convertKeysToCamelCase(Map<String, dynamic> input) {
    final result = <String, dynamic>{};
    for (final entry in input.entries) {
      result[_snakeToCamel(entry.key)] = entry.value;
    }
    return result;
  }

  Map<String, dynamic> _blankStringsToNull(Map<String, dynamic> input) {
    final result = <String, dynamic>{};
    for (final entry in input.entries) {
      final value = entry.value;
      result[entry.key] = value is String && value.trim().isEmpty
          ? null
          : value;
    }
    return result;
  }

  _VerifyUserResult _parseVerifyUserResponse(String body) {
    final decoded = jsonDecode(body);
    final data = decoded is List && decoded.isNotEmpty
        ? decoded.first
        : decoded;

    if (data is bool) {
      return data
          ? const _VerifyUserResult.failure(
              'Server did not return a company id.',
            )
          : const _VerifyUserResult.failure('Username already taken');
    }

    if (data is! Map<String, dynamic>) {
      return const _VerifyUserResult.failure(
        'Invalid server verification response.',
      );
    }

    final usernameAvailable = _readAvailability(data);
    if (usernameAvailable == false) {
      return const _VerifyUserResult.failure('Username already taken');
    }

    final companyId = _readCompanyId(data);
    if (companyId == null || companyId <= 0) {
      return const _VerifyUserResult.failure(
        'Server did not return a valid company id.',
      );
    }

    final result = _VerifyUserResult.success(
      companyId: companyId,
      branchId: _readEntityId(data, const ['branchId', 'branch_id'], 'branch'),
      employeeId: _readEntityId(data, const [
        'employeeId',
        'employeesId',
        'employee_id',
        'employees_id',
      ], 'employees'),
      userId: _readEntityId(data, const ['userId', 'user_id'], 'user'),
      created: _readBool(data['created']),
    );
    developer.log(
      'RegistrationService: parsed verifyUser ids '
      'companyId=${result.companyId}, branchId=${result.branchId}, '
      'employeeId=${result.employeeId}, userId=${result.userId}, '
      'created=${result.created}',
    );
    return result;
  }

  bool? _readAvailability(Map<String, dynamic> data) {
    const keys = [
      'usernameAvailable',
      'userNameAvailable',
      'isUsernameAvailable',
      'available',
      'valid',
      'success',
      'username',
      'user',
    ];

    for (final key in keys) {
      final value = data[key];
      if (value is bool) return value;
      if (value is String) {
        final normalized = value.toLowerCase();
        if (normalized == 'true' || normalized == 'available') return true;
        if (normalized == 'false' || normalized == 'taken') return false;
      }
    }

    const unavailableWhenTrueKeys = [
      'usernameExists',
      'userNameExists',
      'userExists',
      'exists',
      'duplicate',
      'duplicated',
    ];

    for (final key in unavailableWhenTrueKeys) {
      final value = data[key];
      if (value is bool) return !value;
      if (value is String) {
        final normalized = value.toLowerCase();
        if (normalized == 'true') return false;
        if (normalized == 'false') return true;
      }
    }

    return null;
  }

  int? _readCompanyId(Map<String, dynamic> data) {
    const keys = [
      'companyId',
      'company_id',
      'latestCompanyId',
      'newCompanyId',
      'nextCompanyId',
      'tenantId',
      'id',
    ];

    for (final key in keys) {
      final parsed = _asInt(data[key]);
      if (parsed != null) return parsed;
    }

    final company = data['company'];
    if (company is Map<String, dynamic>) {
      return _asInt(company['id']) ?? _asInt(company['companyId']);
    }
    return _asInt(company);
  }

  int? _readEntityId(
    Map<String, dynamic> data,
    List<String> keys,
    String nestedKey,
  ) {
    for (final key in keys) {
      final parsed = _asInt(data[key]);
      if (parsed != null) return parsed;
    }

    final nested = data[nestedKey];
    if (nested is Map<String, dynamic>) {
      return _asInt(nested['id']) ??
          _asInt(nested['${nestedKey}Id']) ??
          _asInt(nested['${nestedKey}_id']);
    }
    return _asInt(nested);
  }

  bool? _readBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) {
      final normalized = value.toLowerCase();
      if (normalized == 'true') return true;
      if (normalized == 'false') return false;
    }
    return null;
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  Future<String?> _getServerBaseUrl() async {
    try {
      final db = await databaseService.database;
      final results = await db.query(
        'system_url_config',
        where: "config_key = ? AND active = ?",
        whereArgs: ['auth_server', 'Y'],
        limit: 1,
      );

      if (results.isNotEmpty) {
        return results.first['config_value'] as String?;
      }

      final fallback = await db.query(
        'system_url_config',
        where: "active = ?",
        whereArgs: ['Y'],
        limit: 1,
      );

      if (fallback.isNotEmpty) {
        return fallback.first['config_value'] as String?;
      }

      return null;
    } catch (e) {
      developer.log('RegistrationService: Error getting server URL: $e');
      return null;
    }
  }

  Future<bool> _idExists(String tableName, int id) async {
    final db = await databaseService.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $tableName WHERE id = ?', [id]),
    );
    return count != null && count > 0;
  }
}

class _VerifyUserResult {
  final bool success;
  final String message;
  final int? companyId;
  final int? branchId;
  final int? employeeId;
  final int? userId;
  final bool? created;

  const _VerifyUserResult._({
    required this.success,
    required this.message,
    this.companyId,
    this.branchId,
    this.employeeId,
    this.userId,
    this.created,
  });

  const _VerifyUserResult.failure(String message)
    : this._(success: false, message: message);

  const _VerifyUserResult.success({
    required int companyId,
    int? branchId,
    int? employeeId,
    int? userId,
    bool? created,
  }) : this._(
         success: true,
         message: 'Registration verified',
         companyId: companyId,
         branchId: branchId,
         employeeId: employeeId,
         userId: userId,
         created: created,
       );
}
