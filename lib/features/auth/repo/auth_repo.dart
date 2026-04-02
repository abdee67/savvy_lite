import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:pointycastle/export.dart';
import 'package:savvy_stock/core/repositories/base_repo.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/admin/privilege/models/privilege_model.dart';
import 'package:savvy_stock/features/admin/role/models/role_model.dart';
import 'package:savvy_stock/features/admin/users/models/user_model.dart';
import 'package:savvy_stock/features/admin/users/models/user_with_role.dart';
import 'package:savvy_stock/features/company/models/company_model.dart';
import 'package:sqflite/sqflite.dart';

class AuthRepository extends BaseRepository {
  @override
  final LocalDatabaseService databaseService;

  AuthRepository({required this.databaseService});

  /// Debug: log all users in the user_table
  Future<void> debugUserTable() async {
    try {
      final db = await databaseService.database;
      final allUsers = await db.query('user_table');
      developer.log('=== USER TABLE DEBUG INFO ===');
      for (final user in allUsers) {
        developer.log(
          'User: ${user['user_name']}, Password: ${user['password']}, Status: ${user['status']}',
        );
      }
      developer.log('=== END DEBUG INFO ===');
    } catch (e) {
      developer.log('Debug error: $e');
    }
  }

  /// Look up a user by username and hashed password, joining with company info.
  /// Returns null if no matching active user is found.
  Future<UserModel?> findUserByCredentials(
    String username,
    String hashedPassword,
  ) async {
    final db = await databaseService.database;

    final users = await db.rawQuery(
      '''
      SELECT u.*, c.company_name, c.logo_company
      FROM user_table u
      LEFT JOIN company_table c ON u.company = c.id
      WHERE u.user_name = ? AND u.password = ? AND u.status = "active"
    ''',
      [username, hashedPassword],
    );

    developer.log('Found ${users.length} users matching credentials');

    if (users.isEmpty) {
      return null;
    }

    return UserModel.fromMap(users.first);
  }

  /// Find a user by their local ID, joining with company info.
  /// Used after remote data population to load the newly-inserted user.
  Future<UserModel?> findUserById(int userId) async {
    final db = await databaseService.database;

    final users = await db.rawQuery(
      '''
      SELECT u.*, c.company_name, c.logo_company
      FROM user_table u
      LEFT JOIN company_table c ON u.company = c.id
      WHERE u.id = ? AND u.status = "active"
    ''',
      [userId],
    );

    if (users.isEmpty) return null;
    return UserModel.fromMap(users.first);
  }

  /// Find a user by their sync_key, joining with company info.
  /// Used after remote data population when we know the sync_key but not the local ID.
  Future<UserModel?> findUserBySyncKey(String syncKey) async {
    final db = await databaseService.database;

    final users = await db.rawQuery(
      '''
      SELECT u.*, c.company_name, c.logo_company
      FROM user_table u
      LEFT JOIN company_table c ON u.company = c.id
      WHERE u.sync_key = ? AND u.status = "active"
    ''',
      [syncKey],
    );

    if (users.isEmpty) return null;
    return UserModel.fromMap(users.first);
  }

  /// Get the user's roles and privileges via join tables.
  Future<UserWithRole> getUserWithRolesAndPrivileges(UserModel user) async {
    final db = await databaseService.database;

    final rolesResult = await db.rawQuery(
      '''
      SELECT r.* FROM role_table r
      INNER JOIN user_role ur ON ur.role_table_id = r.id
        WHERE ur.user_id = ? AND r.company = ?
      ''',
      [user.id, user.company!],
    );

    final roles = await Future.wait(
      rolesResult.map((roleData) => Role.withPrivileges(roleData, db)),
    );

    return UserWithRole(user: user, roles: roles);
  }

  /// Get companies for a list of user maps (used during company selection).
  Future<List<Company>> getCompaniesForUsers(
    List<Map<String, dynamic>> users,
  ) async {
    final db = await databaseService.database;
    final companyIds = users.map((u) => u['company'] as int).toList();

    final placeholders =
        List.generate(companyIds.length, (_) => '?').join(',');
    final results = await db.rawQuery('''
      SELECT * FROM company_table 
      WHERE id IN ($placeholders)
    ''', companyIds);

    return results.map((c) => Company.fromMap(c)).toList();
  }

  /// Hash a password using SHA-256 (runs in a separate isolate via compute).
  Future<String> hashPassword(String password) async {
    return await compute(_sha256Hash, password);
  }

  /// Static SHA-256 hash function (suitable for use with compute/isolate).
  static Future<String> _sha256Hash(String password) async {
    final bytes = utf8.encode(password);
    final digest = SHA256Digest();
    final hash = digest.process(bytes);
    return hash.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }
}
