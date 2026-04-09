
import 'package:savvy_stock/core/repositories/base_repo.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/admin/role/models/role_model.dart';
import 'package:savvy_stock/features/admin/users/models/user_model.dart';
import 'package:savvy_stock/features/admin/users/models/user_with_role.dart';
import 'package:sqflite/sqflite.dart';

class UserRepository extends BaseRepository {
  @override
  final LocalDatabaseService databaseService;

  UserRepository({required this.databaseService});

  // ─── Read ──────────────────────────────────────────────────────────────

  /// Load all users with their roles.
  Future<List<UserWithRole>> loadUsersWithRoles() async {
    final db = await databaseService.database;
    final users = await db.query('user_table');

    return Future.wait(
      users.map((u) => _getUserWithRoles(u, db)),
    );
  }

  /// Check if a username already exists.
  Future<bool> isUsernameTaken(String username) async {
    final db = await databaseService.database;
    final result = await db.query(
      'user_table',
      where: 'user_name = ?',
      whereArgs: [username],
    );
    return result.isNotEmpty;
  }

  /// Get the current total user count.
  Future<int> getUserCount() async {
    final db = await databaseService.database;
    return Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM user_table'),
        ) ??
        0;
  }

  /// Find a user by id and company.
  Future<UserModel?> findUser(int userId, int companyId) async {
    final db = await databaseService.database;
    final results = await db.query(
      'user_table',
      where: 'id = ? AND company = ?',
      whereArgs: [userId, companyId],
    );
    if (results.isEmpty) return null;
    return UserModel.fromMap(results.first);
  }

  // ─── Write ─────────────────────────────────────────────────────────────

  /// Insert a new user and optionally assign roles. Returns the new user id.
  Future<int> insertUser(
    UserModel user,
    int companyId,
    int createdBy, {
    List<Role> roles = const [],
  }) async {
    final db = await databaseService.database;

    final password = await UserModel.sha256Hash(user.password!);

    final userMap = user
        .copyWith(
          company: companyId,
          createdBy: createdBy,
          dateCreated: DateTime.now(),
          password: password,
        )
        .toMap();
    userMap.remove('id');

    final userId = await db.insert('user_table', withSyncKey(userMap));

    if (roles.isNotEmpty) {
      await _assignRoles(db, userId, roles, createdBy);
    }

    userMap['id'] = userId;
    captureSync(
      tableName: 'UserTable',
      entityMap: userMap,
      entityId: userId.toString(),
      operation: 'INSERT',
      company: companyId.toString(),
    );

    return userId;
  }

  /// Update an existing user. Optionally updates password and/or roles.
  /// Returns the number of rows affected.
  Future<int> updateUser(
    UserModel user,
    int companyId,
    int updatedBy, {
    String? newPassword,
    List<Role> roles = const [],
  }) async {
    final db = await databaseService.database;

    // Hash password if provided
    String? finalPassword;
    if (newPassword != null && newPassword.isNotEmpty) {
      finalPassword = await UserModel.sha256Hash(newPassword);
    }

    // Build the updated user model
    UserModel updatedUser = user.copyWith(
      updatedBy: updatedBy,
      dateUpdated: DateTime.now(),
    );
    if (finalPassword != null) {
      updatedUser = updatedUser.copyWith(
        password: finalPassword,
        passwordLastUpdated: DateTime.now(),
      );
    }

    // Prepare map – strip password fields if not being changed
    final userMap = updatedUser.toMap();
    if (finalPassword == null || finalPassword.isEmpty) {
      userMap.remove('password');
      userMap.remove('password_last_updated');
    }

    final result = await db.update(
      'user_table',
      userMap,
      where: 'id = ? AND company = ?',
      whereArgs: [updatedUser.id, companyId],
    );

    if (result == 0) {
      throw Exception('Failed to update user – no rows affected');
    }

    // Update roles if provided
    if (roles.isNotEmpty) {
      await _removeRoles(db, updatedUser.id!);
      await _assignRoles(db, updatedUser.id!, roles, updatedBy);
    }

    captureSync(
      tableName: 'UserTable',
      entityMap: userMap,
      entityId: updatedUser.id.toString(),
      operation: 'UPDATE',
      company: companyId.toString(),
    );

    return result;
  }

  /// Assign roles to a user (replaces existing roles).
  Future<void> assignRolesToUser(
    int userId,
    List<Role> roles,
    int createdBy,
  ) async {
    final db = await databaseService.database;
    await _removeRoles(db, userId);
    await _assignRoles(db, userId, roles, createdBy);
  }

  /// Delete a single user and their role assignments.
  Future<int> deleteUser(int userId, int companyId) async {
    final db = await databaseService.database;

    // Fetch full user row BEFORE deleting
    final userRows = await db.query(
      'user_table',
      where: 'id = ? AND company = ?',
      whereArgs: [userId, companyId],
    );

    // Delete role assignments first (foreign key)
    await _removeRoles(db, userId);

    // Delete the user
    final result = await db.delete(
      'user_table',
      where: 'id = ? AND company = ?',
      whereArgs: [userId, companyId],
    );

    if (result == 0) {
      throw Exception('Failed to delete user – no rows affected');
    }

    // Capture sync with full row data
    for (final row in userRows) {
      captureSync(
        tableName: 'UserTable',
        entityMap: row,
        entityId: row['id'].toString(),
        operation: 'DELETE',
        company: companyId.toString(),
      );
    }

    return result;
  }

  /// Delete multiple users by id.
  Future<void> deleteMultipleUsers(
    List<int> userIds,
    int companyId,
  ) async {
    final db = await databaseService.database;
    final placeholders = List.filled(userIds.length, '?').join(',');
    final whereArgs = [...userIds, companyId];

    // Fetch full row data BEFORE deleting
    final userRoleRows = await db.query(
      'user_role',
      where: 'user_id IN ($placeholders)',
      whereArgs: userIds,
    );
    final userRows = await db.query(
      'user_table',
      where: 'id IN ($placeholders) AND company = ?',
      whereArgs: whereArgs,
    );

    // Delete role assignments
    await db.delete(
      'user_role',
      where: 'user_id IN ($placeholders)',
      whereArgs: userIds,
    );

    // Delete users
    await db.delete(
      'user_table',
      where: 'id IN ($placeholders) AND company = ?',
      whereArgs: whereArgs,
    );

    // Capture sync with full row data
    for (final row in userRoleRows) {
      captureSync(
        tableName: 'UserRole',
        entityMap: row,
        entityId: row['id'].toString(),
        operation: 'DELETE',
        company: companyId.toString(),
      );
    }
    for (final row in userRows) {
      captureSync(
        tableName: 'UserTable',
        entityMap: row,
        entityId: row['id'].toString(),
        operation: 'DELETE',
        company: companyId.toString(),
      );
    }
  }

  /// Re-insert users (for undo operations).
  Future<void> batchInsertUsers(List<UserModel> users) async {
    final db = await databaseService.database;
    final batch = db.batch();

    for (final user in users) {
      batch.insert(
        'user_table',
        user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit();
  }

  // ─── Private helpers ───────────────────────────────────────────────────

  Future<UserWithRole> _getUserWithRoles(
    Map<String, dynamic> userData,
    Database db,
  ) async {
    final user = UserModel.fromMap(userData);

    final roleResults = await db.rawQuery(
      '''
      SELECT r.* FROM role_table r
      INNER JOIN user_role ur ON ur.role_table_id = r.id
      WHERE ur.user_id = ?
    ''',
      [user.id],
    );

    final roles = roleResults.map((r) => Role.fromMap(r)).toList();
    return UserWithRole(user: user, roles: roles);
  }

  Future<void> _assignRoles(
    Database db,
    int userId,
    List<Role> roles,
    int createdBy,
  ) async {
    for (final role in roles) {
      final payload = withSyncKey({
        'user_id': userId,
        'role_table_id': role.id,
        'created_by': createdBy,
        'date_created': DateTime.now().toIso8601String(),
      });
      final id = await db.insert('user_role', payload);
      payload['id'] = id;
      captureSync(
        tableName: 'UserRole',
        entityMap: payload,
        entityId: id.toString(),
        operation: 'INSERT',
      );
    }
  }

  Future<void> _removeRoles(Database db, int userId) async {
    // Fetch full row data BEFORE deleting
    final existingRows = await db.query(
      'user_role',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    await db.delete(
      'user_role',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    // Capture sync with full row data
    for (final row in existingRows) {
      captureSync(
        tableName: 'UserRole',
        entityMap: row,
        entityId: row['id'].toString(),
        operation: 'DELETE',
      );
    }
  }
}
