import 'dart:developer' as developer;
import 'dart:math';

import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/admin/users/models/user_model.dart';
import 'package:savvy_stock/features/auth/model/subscription_management_model.dart';
import 'package:savvy_stock/features/registration/model/signup_data_model.dart';
import 'package:sqflite/sqflite.dart';

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
class RegistrationService {
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

        final companyId = await txn.insert('company_table', companyMap);
        developer.log('Created company with ID: $companyId');

        // 2. Create CompanySubscription
        final now = DateTime.now();
        final expireDate = now.add(
          Duration(days: settings.initialSubscriptionDays ?? 7),
        );

        await txn.insert('company_subscription', {
          'company_id': companyId,
          'subscription_id': settings.id,
          'date_subscribed': now.toIso8601String(),
          'date_effective': now.toIso8601String(),
          'date_expire': expireDate.toIso8601String(),
          'status': 'active',
        });
        developer.log('Created company subscription');

        // 3. Create Branch
        final branchMap = signupData.primaryBranch.toMap();
        branchMap.remove('id');
        branchMap['company'] = companyId;

        final branchId = await txn.insert('branch_table', branchMap);
        developer.log('Created branch with ID: $branchId');

        // 4. Create Employee
        final employeeMap = signupData.employee.toMap();
        employeeMap.remove('id');
        employeeMap['company'] = companyId;
        employeeMap['branch'] = branchId;

        final employeeId = await txn.insert('employees', employeeMap);
        developer.log('Created employee with ID: $employeeId');

        // 5. Create Admin User
        final hashedPassword = await UserModel.generateArgon2Hash(
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

        userId = await txn.insert('user_table', userMap);
        developer.log('Created user with ID: $userId');

        // 6. Create FS Table entry
        final companyName = signupData.company.companyName;
        final branchDesc = signupData.primaryBranch.description ?? '';
        final prefixCode = _generateCompanyCodePre(companyName);
        final postfixCode = _generateCompanyCodePost(
          '$companyName $branchDesc',
        );

        await txn.insert('fs_table', {
          'fs_number': 1,
          'branch': branchId,
          'mrc_number': prefixCode,
          'company': companyId,
          'prefix_up_to_three': prefixCode,
          'postfix_up_to_four': postfixCode,
        });
        developer.log('Created FS table entry');

        // 7. Copy default roles and assign to user
        final defaultRoles = await txn.rawQuery('''
          SELECT * FROM role_table WHERE company IS NULL
        ''');

        if (defaultRoles.isEmpty) {
          developer.log('Warning: No default roles found, creating admin role');
          // Create a basic admin role if none exist
          final adminRoleId = await txn.insert('role_table', {
            'name': '${signupData.company.companyName} Admin',
            'description': 'Administrator role',
            'company': companyId,
            'date_created': DateTime.now().toIso8601String(),
            'created_by': employeeId,
          });

          // Assign admin role to user
          await txn.insert('user_role', {
            'user_id': userId,
            'role_table_id': adminRoleId,
            'created_by': employeeId,
            'date_created': DateTime.now().toIso8601String(),
          });

          // Assign ALL privileges to this Admin role
          final allPrivileges = await txn.query('privilege_table');
          for (final privilege in allPrivileges) {
            await txn.insert('role_privilege', {
              'role_table_id': adminRoleId,
              'privilege_table_id': privilege['id'],
              'date_created': DateTime.now().toIso8601String(),
              'created_by': employeeId,
            });
          }
          developer.log('Assigned all privileges to Admin role');
        } else {
          for (final defaultRole in defaultRoles) {
            // Create company-specific role
            final newRoleId = await txn.insert('role_table', {
              'name':
                  '${signupData.company.companyName} ${defaultRole['name']}',
              'description': defaultRole['description'],
              'company': companyId,
              'date_created': DateTime.now().toIso8601String(),
              'created_by': employeeId,
            });

            // Copy privileges for this role
            final defaultPrivileges = await txn.rawQuery(
              '''
              SELECT * FROM role_privilege WHERE role_table_id = ?
            ''',
              [defaultRole['id']],
            );

            for (final privilege in defaultPrivileges) {
              await txn.insert('role_privilege', {
                'role_table_id': newRoleId,
                'privilege_table_id': privilege['privilege_table_id'],
                'date_created': DateTime.now().toIso8601String(),
                'created_by': employeeId,
              });
            }

            // Assign role to admin user
            await txn.insert('user_role', {
              'user_id': userId,
              'role_table_id': newRoleId,
              'created_by': employeeId,
              'date_created': DateTime.now().toIso8601String(),
            });
          }
        }
        developer.log('Created roles and assigned to user');

        // 8. Copy default NextNumbers
        final defaultNextNumbers = await txn.rawQuery('''
          SELECT * FROM next_number WHERE company IS NULL
        ''');

        for (final nn in defaultNextNumbers) {
          await txn.insert('next_number', {
            'next_number': nn['next_number'],
            'next_number_code': nn['next_number_code'],
            'next_number_description': nn['next_number_description'],
            'company': companyId,
          });
        }
        developer.log('Created next numbers: ${defaultNextNumbers.length}');

        // 9. Copy default SystemConstants
        final defaultConstants = await txn.rawQuery('''
          SELECT * FROM system_constant WHERE company IS NULL
        ''');

        for (final sc in defaultConstants) {
          final newConstant = Map<String, dynamic>.from(sc);
          newConstant.remove('id');
          newConstant['company'] = companyId;
          await txn.insert('system_constant', newConstant);
        }
        developer.log('Created system constants: ${defaultConstants.length}');
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

    // If no subscription exists, create a default free trial
    final defaultId = await db.insert('subscription_management', {
      'name': 'Free Trial',
      'description': '7-day free trial with 1 branch and 5 users',
      'initial_subscription_branches': 1,
      'initial_subscription_users': 5,
      'initial_payment': 0.0,
      'initial_subscription_days': 7,
      'status': 'active',
    });

    final inserted = await db.query(
      'subscription_management',
      where: 'id = ?',
      whereArgs: [defaultId],
    );

    if (inserted.isNotEmpty) {
      return SubscriptionManagement.fromMap(inserted.first);
    }

    return null;
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
}
