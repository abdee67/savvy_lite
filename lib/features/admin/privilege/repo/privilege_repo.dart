import 'package:savvy_stock/core/repositories/base_repo.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/admin/privilege/models/privilege_model.dart';

class PrivilegeRepository extends BaseRepository {
  @override
  final LocalDatabaseService databaseService;

  PrivilegeRepository({required this.databaseService});

  // ─── Read ──────────────────────────────────────────────────────────────

  /// Load all privileges.
  Future<List<Privilege>> loadPrivileges() async {
    final db = await databaseService.database;
    final results = await db.query('previlage_table');
    return results.map((p) => Privilege.fromMap(p)).toList();
  }

  // ─── Write ─────────────────────────────────────────────────────────────

  /// Create a new privilege. Returns the new id.
  Future<int> insertPrivilege({
    required String name,
    required String description,
    required String type,
    required String uri,
    required String linkLabel,
    required String buttonLabel,
    required bool vendorOnly,
    required int createdBy,
  }) async {
    final db = await databaseService.database;

    final map = withSyncKey({
      'name': name,
      'description': description,
      'type': type,
      'link': uri,
      'link_lable': linkLabel,
      'button_lable': buttonLabel,
      'vendor_only': vendorOnly ? 'Y' : 'N',
      'created_by': createdBy,
      'date_created': DateTime.now().toIso8601String(),
    });

    final id = await db.insert('previlage_table', map);

    captureSync(
      tableName: 'previlage_table',
      entityMap: {...map, 'id': id},
      entityId: id.toString(),
      operation: 'INSERT',
    );

    return id;
  }

  /// Update an existing privilege.
  Future<int> updatePrivilege(Privilege privilege) async {
    final db = await databaseService.database;

    final result = await db.update(
      'previlage_table',
      privilege.toMap(),
      where: 'id = ?',
      whereArgs: [privilege.id],
    );

    captureSync(
      tableName: 'previlage_table',
      entityMap: privilege.toMap(),
      entityId: privilege.id.toString(),
      operation: 'UPDATE',
    );

    return result;
  }

  /// Delete a privilege and remove it from all role assignments.
  Future<void> deletePrivilege(int privilegeId) async {
    final db = await databaseService.database;

    // Fetch full row data BEFORE deleting
    final privilegeRows = await db.query(
      'previlage_table',
      where: 'id = ?',
      whereArgs: [privilegeId],
    );
    final rolePrivilegeRows = await db.query(
      'role_privilege',
      where: 'previlage_table_id = ?',
      whereArgs: [privilegeId],
    );

    // Delete privilege
    await db.delete(
      'previlage_table',
      where: 'id = ?',
      whereArgs: [privilegeId],
    );

    // Delete role_privilege associations
    await db.delete(
      'role_privilege',
      where: 'previlage_table_id = ?',
      whereArgs: [privilegeId],
    );

    // Capture sync with full row data
    for (final row in privilegeRows) {
      captureSync(
        tableName: 'previlage_table',
        entityMap: row,
        entityId: row['id'].toString(),
        operation: 'DELETE',
      );
    }
    for (final row in rolePrivilegeRows) {
      captureSync(
        tableName: 'role_privilege',
        entityMap: row,
        entityId: row['id'].toString(),
        operation: 'DELETE',
      );
    }
  }
}
