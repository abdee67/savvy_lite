import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:pointycastle/export.dart';
import 'package:savvy_stock/core/repositories/base_repo.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/core/services/sync/models/sync_event_model.dart';
import 'package:savvy_stock/features/admin/privilege/models/privilege_model.dart';
import 'package:savvy_stock/features/admin/role/models/role_model.dart';
import 'package:savvy_stock/features/admin/users/models/user_model.dart';
import 'package:savvy_stock/features/admin/users/models/user_with_role.dart';
import 'package:savvy_stock/features/auth/services/initial_data_sync_service.dart';
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

    final placeholders = List.generate(companyIds.length, (_) => '?').join(',');
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

  Future<String?> getServerBaseUrl() async {
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

      // Fallback: try any active config
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
      developer.log('RemoteAuthService: Error getting server URL: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  STEP 2: STORE EVENTS LOCALLY
  // ═══════════════════════════════════════════════════════════════════════

  /// Persist all server events into the local `sync_event` table.
  /// Uses batch insert for speed. All events get status INITIAL_PENDING.
  Future<void> storeEventsLocally(
    List<Map<String, dynamic>> serverEvents,
  ) async {
    final db = await databaseService.database;

    // Use batch for high-speed insertion
    final batch = db.batch();

    for (final eventMap in serverEvents) {
      final syncEvent = SyncEventModel(
        entityName: eventMap['entity_name'] as String? ?? '',
        entityId: eventMap['entity_id']?.toString(),
        operation: eventMap['operation'] as String? ?? 'INSERT',
        payload: eventMap['payload'] is String
            ? eventMap['payload'] as String
            : jsonEncode(eventMap['payload']),
        sourceNode: eventMap['source_node'] as String?,
        createdAt: eventMap['created_at'] as String?,
        company: eventMap['company']?.toString(),
        sourceKey: eventMap['source_key'] as String?,
        sourceAddress: eventMap['source_address'] as String?,
        sourceId: eventMap['source_id']?.toString(),
        syncStatus: SyncStatus.initialPending,
        sequenceNumber: eventMap['sequence_number'] as int? ?? 0,
      );

      final map = syncEvent.toMap();
      map.remove('id'); // Let SQLite auto-generate
      batch.insert('sync_event', map);
    }

    await batch.commit(noResult: true);
  }

  /// Check if company data already exists locally (skip re-download).
  Future<bool> hasCompanyDataLocally(String companySyncKey) async {
    final db = await databaseService.database;
    final result = await db.query(
      'company_table',
      where: 'sync_key = ?',
      whereArgs: [companySyncKey],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  STEP 3: PROCESS STORED EVENTS
  // ═══════════════════════════════════════════════════════════════════════

  /// Process all INITIAL_PENDING events in sequence order.
  ///
  /// For each event:
  /// 1. Decode the JSON payload
  /// 2. Skip locally-seeded tables (udc_header, udc_details, privilege_table)
  /// 3. Upsert the record into the target table using sync_key
  /// 4. Mark the event as SUCCESS
  ///
  /// Returns the local user ID of the logged-in user, or null.
  Future<int?> processStoredEvents({
    required int totalEvents,
    required void Function(InitialSyncProgress) onProgress,
  }) async {
    /// Tables that are seeded locally and should NOT be overwritten by initial sync.
    final locallySeededTables = {
      'udc_header',
      'udc_details',
      'privilege_table',
    };

    final db = await databaseService.database;
    int? localUserId;
    int processedCount = 0;

    // ID remapping: serverId → localId, keyed by table name
    // Used to fix foreign key references across tables
    final idMap = <String, Map<int, int>>{};
    // Also track sync_key → localId for FK resolution
    final syncKeyToLocalId = <String, Map<String, int>>{};

    // Fetch all INITIAL_PENDING events ordered by sequence then created_at
    final rows = await db.query(
      'sync_event',
      where: 'sync_status = ?',
      whereArgs: [SyncStatus.initialPending],
      orderBy: 'sequence_number ASC, created_at ASC',
    );

    if (rows.isEmpty) {
      developer.log('InitialDataSync: No INITIAL_PENDING events found');
      return null;
    }

    developer.log('InitialDataSync: Processing ${rows.length} events...');

    for (final row in rows) {
      final event = SyncEventModel.fromMap(row);
      final tableName = event.entityName;

      // Skip locally-seeded tables
      if (locallySeededTables.contains(tableName)) {
        await _markEventSuccess(db, event.id!);
        processedCount++;
        continue;
      }

      // Update progress
      onProgress(
        InitialSyncProgress(
          totalEvents: totalEvents,
          processedEvents: processedCount,
          currentTable: tableName,
          message: 'Setting up ${_humanTableName(tableName)}...',
        ),
      );

      try {
        // Decode payload
        final payload = jsonDecode(event.payload) as Map<String, dynamic>;
        final serverId = payload['id'] as int?;
        final syncKey = payload['sync_key'] as String?;

        // Prepare insert data: strip server ID, remap foreign keys
        final insertData = Map<String, dynamic>.from(payload);
        insertData.remove('id'); // Let SQLite auto-generate

        // Remap foreign keys using previously inserted records
        _remapForeignKeys(tableName, insertData, idMap, syncKeyToLocalId);

        // Upsert by sync_key
        int localId;
        if (syncKey != null && syncKey.isNotEmpty) {
          final existing = await db.query(
            tableName,
            where: 'sync_key = ?',
            whereArgs: [syncKey],
            limit: 1,
          );
          if (existing.isNotEmpty) {
            localId = existing.first['id'] as int;
            await db.update(
              tableName,
              insertData,
              where: 'id = ?',
              whereArgs: [localId],
            );
          } else {
            localId = await db.insert(
              tableName,
              insertData,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        } else {
          localId = await db.insert(
            tableName,
            insertData,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        // Store ID mapping for foreign key resolution
        if (serverId != null) {
          idMap.putIfAbsent(tableName, () => {})[serverId] = localId;
        }
        if (syncKey != null && syncKey.isNotEmpty) {
          syncKeyToLocalId.putIfAbsent(tableName, () => {})[syncKey] = localId;
        }

        // Track user_table local ID for return
        if (tableName == 'user_table') {
          localUserId = localId;
        }

        // Mark event as processed
        await _markEventSuccess(db, event.id!);
      } catch (e) {
        developer.log(
          '❌ InitialDataSync: Error processing event '
          '${event.entityName}#${event.entityId}: $e',
        );
        await _markEventFailed(db, event.id!, e.toString());
      }

      processedCount++;
    }

    // Final progress
    onProgress(
      InitialSyncProgress(
        totalEvents: totalEvents,
        processedEvents: processedCount,
        currentTable: '',
        message: 'Setup complete!',
      ),
    );

    return localUserId;
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  FOREIGN KEY REMAPPING
  // ═══════════════════════════════════════════════════════════════════════

  /// Remap foreign key values in [data] from server IDs to local IDs.
  ///
  /// Uses the [idMap] (table → serverId → localId) built during processing.
  /// Since events are processed in dependency order (via sequence_number),
  /// parent records are always inserted before child records.
  void _remapForeignKeys(
    String tableName,
    Map<String, dynamic> data,
    Map<String, Map<int, int>> idMap,
    Map<String, Map<String, int>> syncKeyToLocalId,
  ) {
    // Define which FK columns map to which parent tables
    final fkMappings = <String, String>{
      // Common across many tables
      'company': 'company_table',
      'branch': 'branch_table',
      'created_by': 'employees',
      'updated_by': 'employees',
      'user_id': 'user_table',
      'ubpdated_by': 'user_table',

      // Employee / User specific
      'employees_id': 'employees',
      'salesperson': 'salespersons',

      // Item related
      'item_number': 'items_table',
      'unit_of_measure': 'udc_details',
      'from_uom': 'udc_details',
      'to_uom': 'udc_details',
      'tax_rate_area': 'tax_rate_area',
      'defualt_uom': 'udc_details',

      // Category codes (item_master)
      'company_category': 'udc_details',
      'category_code_01': 'udc_details',
      'category_code_02': 'udc_details',
      'category_code_03': 'udc_details',
      'category_code_04': 'udc_details',
      'category_code_05': 'udc_details',
      'category_code_06': 'udc_details',
      'category_code_07': 'udc_details',
      'category_code_08': 'udc_details',
      'category_code_09': 'udc_details',
      'category_code_10': 'udc_details',

      // Location
      'location': 'location_master',

      // Lot
      'lot_number': 'lot_master',
      'lot_status': 'udc_details',
      'lot_type': 'udc_details',
      'color_type': 'udc_details',

      // Role / Privilege
      'role_table_id': 'role_table',
      'privilege_table_id': 'privilege_table',

      // Sales
      'customer_bill_to': 'customer_table',
      'customer_table_id': 'customer_table',
      'customer': 'customer_table',
      'sales_order_header_id': 'sales_order_header',
      'sales_return_header_id': 'sales_return_header',
      'items_table_id': 'items_table',
      'item_in_branch': 'items_in_branch',
      'item_branch': 'items_in_branch',
      'item_location': 'item_location',
      'branch_value': 'branch_table',
      'branch_recieved': 'branch_table',

      // Purchase
      'supplier_id': 'supplier_table',
      'supplier': 'supplier_table',
      'po_header': 'purchase_order_header',
      'po_detail': 'purchase_order_detail',

      // Payment / order type UDC references
      'payment_instrument': 'udc_details',
      'payment_status': 'udc_details',
      'payment_term': 'udc_details',
      'po_receive_status': 'udc_details',
      'order_type': 'udc_details',
      'transaction_type': 'udc_details',
      'transaction_number': 'udc_details',
      'return_status': 'udc_details',
      'return_reason': 'udc_details',
      'prforma_status': 'udc_details',
      'category_code': 'udc_details',

      // Other FKs
      'so_header': 'sales_order_header',
      'quote_order_header_id': 'quote_order_header',
      'invoice_history': 'invoice_history_header',
      'referred_by_salesperson_id': 'salespersons',
      'inventory_planner': 'employees',
      'company_id': 'company_table',
      'subscription_id': 'subscription_management',
      'record_header': 'udc_header',
      'branch_id': 'branch_table',
      'unit_of_meansure_default': 'udc_details',
    };

    for (final entry in fkMappings.entries) {
      final fkColumn = entry.key;
      final parentTable = entry.value;

      if (!data.containsKey(fkColumn) || data[fkColumn] == null) continue;

      final serverValue = data[fkColumn];

      // UDC references (udc_details, udc_header) are locally seeded
      // with the same IDs — no remapping needed
      if (parentTable == 'udc_details' || parentTable == 'udc_header') {
        continue;
      }

      // Privilege table is also locally seeded — no remapping needed
      if (parentTable == 'privilege_table') {
        continue;
      }

      // Try to remap the server ID to local ID
      if (serverValue is int) {
        final localId = idMap[parentTable]?[serverValue];
        if (localId != null) {
          data[fkColumn] = localId;
        }
        // If no mapping found, leave the value as-is
        // (it may already be correct, or the parent wasn't in this batch)
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> _markEventSuccess(Database db, int eventId) async {
    await db.update(
      'sync_event',
      {'sync_status': SyncStatus.success},
      where: 'id = ?',
      whereArgs: [eventId],
    );
  }

  Future<void> _markEventFailed(Database db, int eventId, String error) async {
    await db.update(
      'sync_event',
      {'sync_status': SyncStatus.failed},
      where: 'id = ?',
      whereArgs: [eventId],
    );
  }

  /// Convert table name to a human-readable label for UI display.
  String _humanTableName(String tableName) {
    switch (tableName) {
      case 'company_table':
        return 'Company';
      case 'branch_table':
        return 'Branches';
      case 'employees':
        return 'Employees';
      case 'user_table':
        return 'Users';
      case 'role_table':
        return 'Roles';
      case 'role_privilege':
        return 'Role Permissions';
      case 'user_role':
        return 'User Roles';
      case 'items_table':
        return 'Products';
      case 'item_master':
        return 'Product Master';
      case 'items_in_branch':
        return 'Branch Stock';
      case 'item_uom_conversions':
        return 'Unit Conversions';
      case 'item_cost':
        return 'Product Costs';
      case 'location_master':
        return 'Locations';
      case 'item_location':
        return 'Stock Locations';
      case 'lot_master':
        return 'Lot Records';
      case 'lot_expiration_colors':
        return 'Lot Rules';
      case 'customer_table':
        return 'Customers';
      case 'supplier_table':
        return 'Suppliers';
      case 'purchase_order_header':
        return 'Purchase Orders';
      case 'purchase_order_detail':
        return 'Purchase Details';
      case 'purchase_order_receiver':
        return 'Receiving Records';
      case 'sales_order_header':
        return 'Sales Orders';
      case 'sales_order_details':
        return 'Sales Details';
      case 'sales_return_header':
        return 'Sales Returns';
      case 'sales_return_details':
        return 'Return Details';
      case 'quote_order_header':
        return 'Quotations';
      case 'quote_order_details':
        return 'Quotation Details';
      case 'invoice_history_header':
        return 'Invoices';
      case 'invoice_history_detail':
        return 'Invoice Details';
      case 'item_transactions':
        return 'Transaction History';
      case 'credit_payment_table':
        return 'Credit Payments';
      case 'credit_receipt_table':
        return 'Credit Receipts';
      case 'other_expense_table':
        return 'Expenses';
      case 'other_income_table':
        return 'Income Records';
      case 'system_constant':
        return 'Settings';
      case 'next_number':
        return 'Numbering';
      case 'fs_table':
        return 'Fiscal Setup';
      default:
        return tableName.replaceAll('_', ' ');
    }
  }
}
