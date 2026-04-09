import 'package:savvy_stock/core/repositories/base_repo.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/admin/role/models/role_model.dart';
import 'package:sqflite/sqflite.dart';

class RoleRepository extends BaseRepository {
  @override
  final LocalDatabaseService databaseService;

  RoleRepository({required this.databaseService});

  // ─── Read ──────────────────────────────────────────────────────────────

  /// Load all roles (with their privileges) for a company.
  Future<List<Role>> loadRoles(int companyId) async {
    final db = await databaseService.database;
    final roles = await db.query(
      'role_table',
      where: 'company = ?',
      whereArgs: [companyId],
    );

    return Future.wait(roles.map((r) => Role.withPrivileges(r, db)));
  }

  // ─── Write ─────────────────────────────────────────────────────────────

  /// Create a new role and optionally assign privileges. Returns the new id.
  Future<int> insertRole({
    required String name,
    required String description,
    required int companyId,
    required int createdBy,
    List<int> privilegeIds = const [],
  }) async {
    final db = await databaseService.database;

    final payload = withSyncKey({
      'name': name,
      'description': description,
      'company': companyId,
      'created_by': createdBy,
      'date_created': DateTime.now().toIso8601String(),
    });

    final roleId = await db.insert('role_table', payload);
    payload['id'] = roleId;

    if (privilegeIds.isNotEmpty) {
      await _assignPrivileges(db, roleId, privilegeIds, companyId, createdBy);
    }

    captureSync(
      tableName: 'RoleTable',
      entityMap: payload,
      entityId: roleId.toString(),
      operation: 'INSERT',
      company: companyId.toString(),
    );

    return roleId;
  }

  /// Update an existing role.
  Future<int> updateRole(Role role, int companyId) async {
    final db = await databaseService.database;

    final result = await db.update(
      'role_table',
      role.toMap(),
      where: 'id = ? AND company = ?',
      whereArgs: [role.id, companyId],
    );

    captureSync(
      tableName: 'RoleTable',
      entityMap: role.toMap(),
      entityId: role.id.toString(),
      operation: 'UPDATE',
      company: companyId.toString(),
    );

    return result;
  }

  /// Assign privileges to a role (replaces existing).
  Future<void> assignPrivilegesToRole({
    required int roleId,
    required List<int> privilegeIds,
    required int companyId,
    required int createdBy,
  }) async {
    final db = await databaseService.database;

    // Fetch existing role_privilege rows BEFORE deleting
    final existingRows = await db.query(
      'role_privilege',
      where: 'role_table_id = ? AND company = ?',
      whereArgs: [roleId, companyId],
    );

    // Delete existing privileges
    await db.delete(
      'role_privilege',
      where: 'role_table_id = ? AND company = ?',
      whereArgs: [roleId, companyId],
    );

    // Capture sync for each deleted row with full data
    for (final row in existingRows) {
      captureSync(
        tableName: 'RolePrevilage',
        entityMap: row,
        entityId: row['id'].toString(),
        operation: 'DELETE',
        company: companyId.toString(),
      );
    }

    // Add new privileges
    await _assignPrivileges(db, roleId, privilegeIds, companyId, createdBy);
  }

  /// Delete a single role and all its associations (role_privilege, user_role).
  /// Returns the number of affected users.
  Future<int> deleteRole(Role role, int companyId) async {
    final db = await databaseService.database;
    int affectedUsers = 0;

    // Fetch all related rows BEFORE the transaction deletes them
    final userRoleRows = await db.query(
      'user_role',
      where: 'role_table_id = ?',
      whereArgs: [role.id],
    );
    final rolePrivilegeRows = await db.query(
      'role_privilege',
      where: 'role_table_id = ? AND company = ?',
      whereArgs: [role.id, companyId],
    );
    final roleRows = await db.query(
      'role_table',
      where: 'id = ? AND company = ?',
      whereArgs: [role.id, companyId],
    );

    affectedUsers = userRoleRows.length;

    await db.transaction((txn) async {
      // 1. Remove role from all users
      await txn.delete(
        'user_role',
        where: 'role_table_id = ?',
        whereArgs: [role.id],
      );

      // 2. Remove privileges from role
      await txn.delete(
        'role_privilege',
        where: 'role_table_id = ? AND company = ?',
        whereArgs: [role.id, companyId],
      );

      // 3. Delete the role itself
      final result = await txn.delete(
        'role_table',
        where: 'id = ? AND company = ?',
        whereArgs: [role.id, companyId],
      );

      if (result == 0) {
        throw Exception('Role not found or already deleted');
      }
    });

    // Capture sync with full row data for each deleted row
    for (final row in userRoleRows) {
      captureSync(
        tableName: 'UserRole',
        entityMap: row,
        entityId: row['id'].toString(),
        operation: 'DELETE',
        company: companyId.toString(),
      );
    }
    for (final row in rolePrivilegeRows) {
      captureSync(
        tableName: 'RolePrevilage',
        entityMap: row,
        entityId: row['id'].toString(),
        operation: 'DELETE',
        company: companyId.toString(),
      );
    }
    for (final row in roleRows) {
      captureSync(
        tableName: 'RoleTable',
        entityMap: row,
        entityId: row['id'].toString(),
        operation: 'DELETE',
        company: companyId.toString(),
      );
    }

    return affectedUsers;
  }

  /// Delete multiple roles and all their associations.
  Future<void> deleteMultipleRoles(List<Role> roles, int companyId) async {
    final db = await databaseService.database;
    final roleIds = roles.map((r) => r.id).toList();
    final placeholders = List.filled(roleIds.length, '?').join(',');

    // Fetch all related rows BEFORE deleting
    final userRoleRows = await db.query(
      'user_role',
      where: 'role_table_id IN ($placeholders)',
      whereArgs: roleIds,
    );
    final rolePrivilegeRows = await db.query(
      'role_privilege',
      where: 'role_table_id IN ($placeholders)',
      whereArgs: roleIds,
    );
    final roleRows = await db.query(
      'role_table',
      where: 'id IN ($placeholders) AND company = ?',
      whereArgs: [...roleIds, companyId],
    );

    await db.transaction((txn) async {
      await txn.delete(
        'user_role',
        where: 'role_table_id IN ($placeholders)',
        whereArgs: roleIds,
      );

      await txn.delete(
        'role_privilege',
        where: 'role_table_id IN ($placeholders)',
        whereArgs: roleIds,
      );

      await txn.delete(
        'role_table',
        where: 'id IN ($placeholders) AND company = ?',
        whereArgs: [...roleIds, companyId],
      );
    });

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
    for (final row in rolePrivilegeRows) {
      captureSync(
        tableName: 'RolePrevilage',
        entityMap: row,
        entityId: row['id'].toString(),
        operation: 'DELETE',
        company: companyId.toString(),
      );
    }
    for (final row in roleRows) {
      captureSync(
        tableName: 'RoleTable',
        entityMap: row,
        entityId: row['id'].toString(),
        operation: 'DELETE',
        company: companyId.toString(),
      );
    }
  }

  // ─── Private helpers ───────────────────────────────────────────────────

  Future<void> _assignPrivileges(
    Database db,
    int roleId,
    List<int> privilegeIds,
    int companyId,
    int createdBy,
  ) async {
    for (final privilegeId in privilegeIds) {
      final payload = withSyncKey({
        'role_table_id': roleId,
        'privilege_table_id': privilegeId,
        'company': companyId,
        'created_by': createdBy,
        'date_created': DateTime.now().toIso8601String(),
      });
      final id = await db.insert('role_privilege', payload);
      payload['id'] = id;
      captureSync(
        tableName: 'RolePrevilage',
        entityMap: payload,
        entityId: id.toString(),
        operation: 'INSERT',
      );
    }
  }
}
