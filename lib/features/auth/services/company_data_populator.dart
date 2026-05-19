import 'dart:developer' as developer;

import 'package:savvy_stock/core/repositories/base_repo.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/auth/model/remote_login_response.dart';
import 'package:sqflite/sqflite.dart';

/// Populates the local SQLite database with company-level data received
/// from the Java server after a successful remote login.
///
/// All inserts happen in a single transaction to ensure atomicity.
/// Uses `sync_key` (UUID) to detect duplicates:
///   - If sync_key matches an existing record → update if data changed
///   - If sync_key doesn't exist → insert new record
///
/// Foreign key IDs are remapped from server IDs to local auto-increment IDs.
class CompanyDataPopulator extends BaseRepository {
  @override
  final LocalDatabaseService databaseService;

  CompanyDataPopulator({required this.databaseService});

  /// Populate the local database with company data from a remote login response.
  ///
  /// Returns the local user ID of the logged-in user after population,
  /// or null if population failed.
  Future<int?> populateFromRemoteLogin(RemoteLoginResponse response) async {
    if (!response.hasCompanyData) {
      developer.log('CompanyDataPopulator: Response missing required data');
      return null;
    }

    final db = await databaseService.database;
    int? localUserId;

    try {
      await db.transaction((txn) async {
        developer.log('CompanyDataPopulator: Starting data population...');

        // ─── 1. Company ──────────────────────────────────────────────
        final serverCompanyId = response.company!['id'];
        final localCompanyId = await _upsertBySyncKey(
          txn,
          'company_table',
          response.company!,
          serverCompanyId,
        );
        developer.log(
          'CompanyDataPopulator: Company → server=$serverCompanyId, '
          'local=$localCompanyId',
        );

        // ─── 2. Company Subscription ─────────────────────────────────
        if (response.companySubscription != null) {
          final subData = Map<String, dynamic>.from(
            response.companySubscription!,
          );
          subData['company_id'] = localCompanyId;
          await _upsertBySyncKey(
            txn,
            'company_subscription',
            subData,
            subData['id'],
          );
          developer.log('CompanyDataPopulator: Company subscription inserted');
        }

        // ─── 3. Branch ───────────────────────────────────────────────
        final serverBranchId = response.branch!['id'];
        final branchData = Map<String, dynamic>.from(response.branch!);
        branchData['company'] = localCompanyId;
        final localBranchId = await _upsertBySyncKey(
          txn,
          'branch_table',
          branchData,
          serverBranchId,
        );
        developer.log(
          'CompanyDataPopulator: Branch → server=$serverBranchId, '
          'local=$localBranchId',
        );

        // ─── 4. Employee ─────────────────────────────────────────────
        final serverEmployeeId = response.employee!['id'];
        final employeeData = Map<String, dynamic>.from(response.employee!);
        employeeData['company'] = localCompanyId;
        employeeData['branch'] = localBranchId;
        final localEmployeeId = await _upsertBySyncKey(
          txn,
          'employees',
          employeeData,
          serverEmployeeId,
        );
        developer.log(
          'CompanyDataPopulator: Employee → server=$serverEmployeeId, '
          'local=$localEmployeeId',
        );

        // ─── 5. Roles (company-specific) ─────────────────────────────
        // Build a mapping of server role ID → local role ID
        final roleIdMap = <int, int>{};
        for (final role in response.roles) {
          final serverRoleId = role['id'] as int;
          final roleData = Map<String, dynamic>.from(role);
          roleData['company'] = localCompanyId;
          // Remap created_by / updated_by to local employee ID
          if (roleData['created_by'] == serverEmployeeId) {
            roleData['created_by'] = localEmployeeId;
          }
          if (roleData['updated_by'] == serverEmployeeId) {
            roleData['updated_by'] = localEmployeeId;
          }
          final localRoleId = await _upsertBySyncKey(
            txn,
            'role_table',
            roleData,
            serverRoleId,
          );
          roleIdMap[serverRoleId] = localRoleId;
          developer.log(
            'CompanyDataPopulator: Role "${role['name']}" → '
            'server=$serverRoleId, local=$localRoleId',
          );
        }

        // ─── 6. Role-Privilege mappings ──────────────────────────────
        for (final rp in response.rolePrivileges) {
          final rpData = Map<String, dynamic>.from(rp);
          // Remap role_table_id to local role ID
          final serverRoleId = rpData['role_table_id'] as int?;
          if (serverRoleId != null && roleIdMap.containsKey(serverRoleId)) {
            rpData['role_table_id'] = roleIdMap[serverRoleId];
          }
          // previlage_table_id stays the same — previlages are system-level
          // and have the same IDs on every device (seeded identically).
          // However, if sync_key is used, we should look up by sync_key.
          final serverPrivilegeId = rpData['previlage_table_id'] as int?;
          if (serverPrivilegeId != null) {
            final localPrivilegeId = await _findLocalIdBySyncKeyOrFallback(
              txn,
              'previlage_table',
              rpData['sync_key'] as String?,
              serverPrivilegeId,
            );
            if (localPrivilegeId != null) {
              rpData['previlage_table_id'] = localPrivilegeId;
            }
          }
          // Remap created_by
          if (rpData['created_by'] == serverEmployeeId) {
            rpData['created_by'] = localEmployeeId;
          }
          await _upsertBySyncKey(txn, 'role_privilege', rpData, rpData['id']);
        }
        developer.log(
          'CompanyDataPopulator: Inserted ${response.rolePrivileges.length} '
          'role-privilege mappings',
        );

        // ─── 7. User ────────────────────────────────────────────────
        final serverUserId = response.user!['id'];
        final userData = Map<String, dynamic>.from(response.user!);
        userData['company'] = localCompanyId;
        userData['branch'] = localBranchId;
        userData['employees_id'] = localEmployeeId;
        // Remap created_by / updated_by
        if (userData['created_by'] == serverEmployeeId) {
          userData['created_by'] = localEmployeeId;
        }
        if (userData['updated_by'] == serverEmployeeId) {
          userData['updated_by'] = localEmployeeId;
        }
        localUserId = await _upsertBySyncKey(
          txn,
          'user_table',
          userData,
          serverUserId,
        );
        developer.log(
          'CompanyDataPopulator: User → server=$serverUserId, '
          'local=$localUserId',
        );

        // ─── 8. User-Role mappings ──────────────────────────────────
        for (final ur in response.userRoles) {
          final urData = Map<String, dynamic>.from(ur);
          // Remap user_id to local user ID
          if (urData['user_id'] == serverUserId) {
            urData['user_id'] = localUserId;
          }
          // Remap role_table_id to local role ID
          final serverRoleId = urData['role_table_id'] as int?;
          if (serverRoleId != null && roleIdMap.containsKey(serverRoleId)) {
            urData['role_table_id'] = roleIdMap[serverRoleId];
          }
          // Remap created_by
          if (urData['created_by'] == serverEmployeeId) {
            urData['created_by'] = localEmployeeId;
          }
          await _upsertBySyncKey(txn, 'user_role', urData, urData['id']);
        }
        developer.log(
          'CompanyDataPopulator: Inserted ${response.userRoles.length} '
          'user-role mappings',
        );

        // ─── 9. System Constants ────────────────────────────────────
        for (final sc in response.systemConstants) {
          final scData = Map<String, dynamic>.from(sc);
          scData['company'] = localCompanyId;
          await _upsertBySyncKey(txn, 'system_constant', scData, scData['id']);
        }
        developer.log(
          'CompanyDataPopulator: Inserted ${response.systemConstants.length} '
          'system constants',
        );

        // ─── 10. Next Numbers ───────────────────────────────────────
        for (final nn in response.nextNumbers) {
          final nnData = Map<String, dynamic>.from(nn);
          nnData['company'] = localCompanyId;
          await _upsertBySyncKey(txn, 'next_number', nnData, nnData['id']);
        }
        developer.log(
          'CompanyDataPopulator: Inserted ${response.nextNumbers.length} '
          'next numbers',
        );

        // ─── 11. FS Table ───────────────────────────────────────────
        for (final fs in response.fsTables) {
          final fsData = Map<String, dynamic>.from(fs);
          fsData['company'] = localCompanyId;
          if (fsData['branch'] == serverBranchId) {
            fsData['branch'] = localBranchId;
          }
          await _upsertBySyncKey(txn, 'fs_table', fsData, fsData['id']);
        }
        developer.log(
          'CompanyDataPopulator: Inserted ${response.fsTables.length} '
          'FS table entries',
        );

        developer.log(
          '✅ CompanyDataPopulator: All company data populated successfully',
        );
      });

      return localUserId;
    } catch (e, stackTrace) {
      developer.log(
        '❌ CompanyDataPopulator: Population failed: $e',
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Upsert a record by sync_key.
  ///
  /// - If a record with the same sync_key exists → update it, return its local ID
  /// - If no match → insert new record, return new local ID
  /// - If no sync_key in data → insert new record
  ///
  /// The server's `id` field is stripped before insert to let SQLite
  /// auto-generate the local ID.
  Future<int> _upsertBySyncKey(
    Transaction txn,
    String tableName,
    Map<String, dynamic> data,
    dynamic serverId,
  ) async {
    final syncKey = data['sync_key'] as String?;
    final insertData = Map<String, dynamic>.from(data);

    // Always strip the server's ID — let SQLite auto-generate
    insertData.remove('id');

    if (syncKey != null && syncKey.isNotEmpty) {
      // Check if record with this sync_key already exists
      final existing = await txn.query(
        tableName,
        where: 'sync_key = ?',
        whereArgs: [syncKey],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        final localId = existing.first['id'] as int;
        // Update existing record with any changed data
        await txn.update(
          tableName,
          insertData,
          where: 'id = ?',
          whereArgs: [localId],
        );
        developer.log(
          'CompanyDataPopulator: Updated $tableName (sync_key=$syncKey, '
          'localId=$localId)',
        );
        return localId;
      }
    }

    // Insert new record
    final localId = await txn.insert(
      tableName,
      insertData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    developer.log(
      'CompanyDataPopulator: Inserted $tableName (sync_key=$syncKey, '
      'localId=$localId)',
    );
    return localId;
  }

  /// Look up a local ID by sync_key first, falling back to direct ID match.
  ///
  /// This is used for previlage_table lookups where privileges are system-level
  /// and already seeded locally, but the server's IDs may differ.
  Future<int?> _findLocalIdBySyncKeyOrFallback(
    Transaction txn,
    String tableName,
    String? syncKey,
    int serverId,
  ) async {
    // Try sync_key first
    if (syncKey != null && syncKey.isNotEmpty) {
      final result = await txn.query(
        tableName,
        columns: ['id'],
        where: 'sync_key = ?',
        whereArgs: [syncKey],
        limit: 1,
      );
      if (result.isNotEmpty) {
        return result.first['id'] as int;
      }
    }

    // Fallback: check if the server ID happens to exist locally
    final result = await txn.query(
      tableName,
      columns: ['id'],
      where: 'id = ?',
      whereArgs: [serverId],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return result.first['id'] as int;
    }

    return null;
  }
}
