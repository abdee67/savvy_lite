import 'dart:developer' as developer;
import 'dart:math';

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

  RegistrationService({required this.databaseService});

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

      // Perform all inserts in a transaction
      int? userId;
      String? confirmationCode;

      await db.transaction((txn) async {
        // 1. Create Company with subscription limits
        final companyMap = signupData.company
            .copyWith(
              userLimmit: settings.initialSubscriptionUsers,
              branchLimmit: settings.initialSubscriptionBranches,
              emailAddress1: signupData.adminUser.userEmail,
              daysLeft: settings.initialSubscriptionDays,
              subscriptionFee: settings.initialPayment,
              dateCreated: DateTime.now(),
            )
            .toMap();
        companyMap.remove('id');
        final payloadForCompany = withSyncKey(companyMap);
        final companyId = await txn.insert('company_table', payloadForCompany);
        captureSync(
          tableName: 'CompanyTable',
          entityMap: payloadForCompany,
          entityId: companyId.toString(),
          operation: 'INSERT',
          company: companyId.toString(),
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
          'status': settings.status ?? 'active',
        });
        final subscriptionId = await txn.insert(
          'subscription_management',
          payloadForSubscription,
        );
        captureSync(
          tableName: 'SubscriptionManagement',
          entityMap: payloadForSubscription,
          entityId: subscriptionId.toString(),
          operation: 'INSERT',
          company: companyId.toString(),
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
          'status': 'active',
        });
        final id = await txn.insert(
          'company_subscription',
          payloadForCompanySubscription,
        );
        captureSync(
          tableName: 'CompanySubscription',
          entityMap: payloadForCompanySubscription,
          entityId: id.toString(),
          operation: 'INSERT',
          company: companyId.toString(),
        );
        developer.log('Created company subscription');

        // 3. Create Branch
        final branchMap = signupData.primaryBranch.toMap();
        branchMap.remove('id');
        branchMap['company'] = companyId;

        final payloadForBranch = withSyncKey(branchMap);
        final branchId = await txn.insert('branch_table', payloadForBranch);
        captureSync(
          tableName: 'BranchTable',
          entityMap: payloadForBranch,
          entityId: branchId.toString(),
          operation: 'INSERT',
          company: companyId.toString(),
        );
        developer.log('Created branch with ID: $branchId');

        // 4. Create Employee
        final employeeMap = signupData.employee.toMap();
        employeeMap.remove('id');
        employeeMap['company'] = companyId;
        employeeMap['branch'] = branchId;

        final payloadForEmployee = withSyncKey(employeeMap);
        final employeeId = await txn.insert('employees', payloadForEmployee);
        captureSync(
          tableName: 'Employees',
          entityMap: payloadForEmployee,
          entityId: employeeId.toString(),
          operation: 'INSERT',
          company: companyId.toString(),
        );
        developer.log('Created employee with ID: $employeeId');

        // 5. Create Admin User
        final hashedPassword = await UserModel.sha256Hash(
          signupData.adminUser.password!,
        );
        confirmationCode = _generateConfirmationCode();
        final confirmationExpireTime = DateTime.now().add(
          const Duration(minutes: 10),
        );

        final userMap = {
          'employees_id': employeeId,
          'branch': branchId,
          'company': companyId,
          'password': hashedPassword,
          'status': 'active',
          'date_created': DateTime.now().millisecondsSinceEpoch,
          'password_last_updated': DateTime.now().millisecondsSinceEpoch,
          'confirmation_code': confirmationCode,
          'confirmations_expire_time':
              confirmationExpireTime.millisecondsSinceEpoch,
          'user_email': signupData.adminUser.userEmail,
          'user_name': signupData.adminUser.userName,
          'type': 'Company',
        };

        final payloadForUser = withSyncKey(userMap);
        userId = await txn.insert('user_table', payloadForUser);
        captureSync(
          tableName: 'UserTable',
          entityMap: payloadForUser,
          entityId: userId.toString(),
          operation: 'INSERT',
          company: companyId.toString(),
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
        captureSync(
          tableName: 'FsTable',
          entityMap: payloadForFsTable,
          entityId: idFs.toString(),
          operation: 'INSERT',
          company: companyId.toString(),
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
          captureSync(
            tableName: 'RoleTable',
            entityMap: payloadForAdminRole,
            entityId: adminRoleId.toString(),
            operation: 'INSERT',
            company: companyId.toString(),
          );

          // Assign admin role to user
          final payloadForUserRole = withSyncKey({
            'user_id': userId,
            'role_table_id': adminRoleId,
            'created_by': userId,
            'date_created': DateTime.now().toIso8601String(),
          });
          final idUserRole = await txn.insert('user_role', payloadForUserRole);
          captureSync(
            tableName: 'UserRole',
            entityMap: payloadForUserRole,
            entityId: idUserRole.toString(),
            operation: 'INSERT',
            company: companyId.toString(),
          );

          // Assign ALL privileges to this Admin role
          final allPrivileges = await txn.query('privilege_table');
          for (final privilege in allPrivileges) {
            // 1. Create the new record map first, THEN wrap it with withSyncKey
            final payload = withSyncKey({
              'role_table_id': adminRoleId,
              'privilege_table_id': privilege['id'],
              'date_created': DateTime.now().toIso8601String(),
              'created_by': userId,
            });
            // 2. Insert the wrapped payload
            final id = await txn.insert('role_privilege', payload);
            // 3. Pass the payload to captureSync
            captureSync(
              tableName: 'RolePrevilage',
              entityMap: payload, // Uses the map that now contains sync_key
              entityId: id.toString(),
              operation: 'INSERT',
              company: companyId.toString(),
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
            captureSync(
              tableName: 'RoleTable',
              entityMap: payload,
              entityId: newRoleId.toString(),
              operation: 'INSERT',
              company: companyId.toString(),
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
                'privilege_table_id': privilege['privilege_table_id'],
                'date_created': DateTime.now().toIso8601String(),
                'created_by': employeeId,
              });
              final id = await txn.insert('role_privilege', payload);
              captureSync(
                tableName: 'RolePrevilage',
                entityMap: payload,
                entityId: id.toString(),
                operation: 'INSERT',
                company: companyId.toString(),
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
            captureSync(
              tableName: 'UserRole',
              entityMap: payloadForUserRole,
              entityId: id.toString(),
              operation: 'INSERT',
              company: companyId.toString(),
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
          captureSync(
            tableName: 'NextNumber',
            entityMap: payload,
            entityId: id.toString(),
            operation: 'INSERT',
            company: companyId.toString(),
          );
        }
        developer.log('Created next numbers: ${defaultNextNumbers.length}');

        // 9. Generate default SystemConstants
        final List<Map<String, dynamic>> udcDetails = await txn.query(
          'udc_details',
          columns: ['id'],
          where: "detail_code = ? AND udc_group = ?",
          whereArgs: ['X', 'LT'],
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
        captureSync(
          tableName: 'SystemConfiguration',
          entityMap: systemConstPayload,
          entityId: idSc.toString(),
          operation: 'INSERT',
          company: companyId.toString(),
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
      status: 'active',
    );
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
}
