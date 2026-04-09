// features/stock/item_locations/repositories/item_locations_repository.dart
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:savvy_stock/core/repositories/base_repo.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/sales/sales_order/detail/model/sales_order_detail.dart';
import 'package:savvy_stock/features/stock/item_locations/models/item_location_filters.dart';
import 'package:savvy_stock/features/stock/item_locations/models/item_locations_model.dart';
import 'package:savvy_stock/features/stock/item_locations/models/paginated_item_locations.dart';
import 'package:sqflite/sqflite.dart';

class ItemLocationsRepository extends BaseRepository {
  @override
  final LocalDatabaseService databaseService;
  ItemLocationsRepository({required this.databaseService});

  // Get all item locations for a company
  Future<List<ItemLocation>> getItemLocations(
    int companyId, {
    Transaction? txn,
  }) async {
    final db = txn ?? await databaseService.database;
    final items = await db.query(
      'item_location',
      where: 'company = ?',
      whereArgs: [companyId],
    );
    return items.map((p) => ItemLocation.fromMap(p)).toList();
  }

  // Get item locations by branch and item
  Future<List<ItemLocation>> getItemLocationsByBranchAndItem({
    required int companyId,
    required int branchId,
    required int itemId,
    Transaction? txn,
  }) async {
    final db = txn ?? await databaseService.database;
    final items = await db.rawQuery(
      '''
      SELECT il.*,
             lm.location_description,
             it.item_description,
             it.unit_of_measure,
             b.description as branch_description
      FROM item_location il
      LEFT JOIN location_master lm ON il.location = lm.id
      LEFT JOIN items_table it ON il.item_number = it.id
      LEFT JOIN branch_table b ON il.branch = b.id
      WHERE il.company = ? AND il.branch = ? AND il.item_number = ?
    ''',
      [companyId, branchId, itemId],
    );

    return items.map((p) => ItemLocation.fromMap(p)).toList();
  }

  // Get item locations for branch
  Future<List<ItemLocation>> getItemLocationsForBranch({
    required int companyId,
    required int branchId,
    Transaction? txn,
  }) async {
    final db = txn ?? await databaseService.database;
    final items = await db.rawQuery(
      '''
      SELECT 
        il.*,
        lm.location_description as location_description,
        b.description as branch_description
      FROM item_location il
      LEFT JOIN location_master lm ON il.location = lm.id
      LEFT JOIN branch_table b ON il.branch = b.id
      WHERE il.company = ? AND il.branch = ?
      ''',
      [companyId, branchId],
    );
    return items.map((p) => ItemLocation.fromMap(p)).toList();
  }

  // Get item location by ID
  Future<ItemLocation?> getItemLocationById(
    int id,
    int companyId, {
    Transaction? txn,
  }) async {
    final db = txn ?? await databaseService.database;
    final items = await db.query(
      'item_location',
      where: 'id = ? AND company = ?',
      whereArgs: [id, companyId],
    );
    return items.isNotEmpty ? ItemLocation.fromMap(items.first) : null;
  }

  // Get item location by Item, Branch, Location
  Future<ItemLocation?> getItemLocationByItemBranchLocation({
    required int branchId,
    required int itemNumber,
    required int locationId,
    required int companyId,
    Transaction? txn,
  }) async {
    final db = txn ?? await databaseService.database;
    final items = await db.query(
      'item_location',
      where: 'company = ? AND branch = ? AND item_number = ? AND location = ?',
      whereArgs: [companyId, branchId, itemNumber, locationId],
    );
    return items.isNotEmpty ? ItemLocation.fromMap(items.first) : null;
  }

  // Create new item location
  Future<int> createItemLocation(ItemLocation item, {Transaction? txn}) async {
    final db = txn ?? await databaseService.database;
    final itemMap = item.toMap();
    itemMap.remove('id'); // Remove ID for new insertion
    final id = await db.insert('item_location', withSyncKey(itemMap));
    itemMap['id'] = id;
    captureSync(
      tableName: 'ItemLocations',
      entityMap: itemMap,
      entityId: id.toString(),
      operation: 'INSERT',
      company: item.company?.toString(),
    );
    return id;
  }

  // Update existing item location
  Future<int> updateItemLocation(ItemLocation item, {Transaction? txn}) async {
    final db = txn ?? await databaseService.database;
    final result = await db.update(
      'item_location',
      item.toMap(),
      where: 'id = ? AND company = ?',
      whereArgs: [item.id, item.company],
    );
    captureSync(
      tableName: 'ItemLocations',
      entityMap: item.toMap(),
      entityId: item.id.toString(),
      operation: 'UPDATE',
      company: item.company?.toString(),
    );
    return result;
  }

  // Delete item location
  Future<int> deleteItemLocation(
    int id,
    int companyId, {
    Transaction? txn,
  }) async {
    final db = txn ?? await databaseService.database;
    // Fetch full row data BEFORE deleting
    final itemRows = await db.query(
      'item_location',
      where: 'id = ? AND company = ?',
      whereArgs: [id, companyId],
    );
    final result = await db.delete(
      'item_location',
      where: 'id = ? AND company = ?',
      whereArgs: [id, companyId],
    );
    for (final row in itemRows) {
    captureSync(
      tableName: 'ItemLocations',
      entityMap: row,
      entityId: row['id'].toString(),
      operation: 'DELETE',
      company: companyId.toString(),
    );
    }
    return result;
  }

  // Get lazy paginated item locations with filters and sorting
  Future<PaginatedItemLocationsResult> getLazyItemLocationsPaginated({
    required int companyId,
    required ItemLocationFilters filters,
    required int page,
    required int pageSize,
    String? sortBy,
    bool sortAscending = true,
  }) async {
    final db = await databaseService.database;

    final whereConditions = <String>['il.company = ?'];
    final whereArgs = <dynamic>[companyId];

    if (filters.itemNumber != null) {
      whereConditions.add('il.item_number = ?');
      whereArgs.add(filters.itemNumber);
    }
    if (filters.branchId != null) {
      whereConditions.add('il.branch = ?');
      whereArgs.add(filters.branchId);
    }
    if (filters.locationId != null) {
      whereConditions.add('il.location = ?');
      whereArgs.add(filters.locationId);
    }
    if (filters.noAvailable) {
      whereConditions.add(
        '(il.quantity_on_hand IS NULL OR il.quantity_on_hand = 0.0)',
      );
    }

    final whereClause = whereConditions.join(' AND ');

    // 1. COUNT query
    final countResult = await db.rawQuery('''
      SELECT COUNT(il.id) as count
      FROM item_location il
      WHERE $whereClause
    ''', whereArgs);

    int totalCount = (countResult.first['count'] as int?) ?? 0;

    // 2. DATA query with LEFT JOIN to emulate java's itemCostCache implicitly
    String orderByClause;
    if (sortBy != null && sortBy.isNotEmpty) {
      // Basic protection against SQL injection on order by
      final safeSortBy = sortBy.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
      orderByClause = 'il.$safeSortBy ${sortAscending ? "ASC" : "DESC"}';
    } else {
      orderByClause = 'il.id DESC';
    }

    final query =
        '''
      SELECT il.*,
             lm.location_description,
             it.item_description,
             it.items_id,
             it.unit_of_measure,
             udc.description_1 as unit_of_measure_description,
             udc.detail_code as unit_of_measure_code,
             it.unit_price,
             it.taxable,
             it.barcode,
             it.company as item_company,
             it.margin_rate as item_margin_rate,
             it.margin_type as item_margin_type,
             it.reorder_point as item_reorder_point,
             b.description as branch_description
      FROM item_location il
      LEFT JOIN location_master lm ON il.location = lm.id
      LEFT JOIN items_table it ON il.item_number = it.id
      LEFT JOIN udc_details udc ON it.unit_of_measure = udc.id
      LEFT JOIN branch_table b ON il.branch = b.id
      WHERE $whereClause
      ORDER BY $orderByClause
      LIMIT ? OFFSET ?
    ''';

    final dataArgs = [...whereArgs, pageSize, (page - 1) * pageSize];
    final itemsData = await db.rawQuery(query, dataArgs);

    final items = itemsData.map((map) => ItemLocation.fromMap(map)).toList();

    return PaginatedItemLocationsResult(items: items, count: totalCount);
  }

  // Batch delete multiple item locations
  Future<void> deleteItemLocations(
    List<int> ids,
    int companyId, {
    Transaction? txn,
  }) async {
    final db = txn ?? await databaseService.database;
    final batch = db.batch();

    for (final id in ids) {
      batch.delete(
        'item_location',
        where: 'id = ? AND company = ?',
        whereArgs: [id, companyId],
      );
    }

    await batch.commit();
  }

  // Search item locations
  Future<List<ItemLocation>> searchItemLocations({
    required int companyId,
    required String query,
  }) async {
    final db = await databaseService.database;
    final items = await db.rawQuery(
      '''
      SELECT il.*,
             lm.location_description,
             it.item_description,
             b.description as branch_description
      FROM item_location il
      LEFT JOIN location_master lm ON il.location = lm.id
      LEFT JOIN items_table it ON il.item_number = it.id
      LEFT JOIN branch_table b ON il.branch = b.id
      WHERE il.company = ? 
        AND (il.location LIKE ? OR it.item_description LIKE ? OR b.description LIKE ?)
    ''',
      [companyId, '%$query%', '%$query%', '%$query%'],
    );

    return items.map((p) => ItemLocation.fromMap(p)).toList();
  }

  // Get item locations by location ID
  Future<List<ItemLocation>> getItemLocationsByLocation({
    required int companyId,
    required int locationId,
  }) async {
    final db = await databaseService.database;
    final items = await db.query(
      'item_location',
      where: 'company = ? AND location = ? ',
      whereArgs: [companyId, locationId],
    );
    return items.map((p) => ItemLocation.fromMap(p)).toList();
  }

  // Get all item locations by item number (across all branches/locations)
  Future<List<ItemLocation>> getItemLocationsByItemNumber({
    required int companyId,
    required int itemId,
    Transaction? txn,
  }) async {
    final db = txn ?? await databaseService.database;
    final items = await db.rawQuery(
      '''
      SELECT il.*,
             lm.location_description,
             it.item_description,
             it.unit_of_measure,
             b.description as branch_description
      FROM item_location il
      LEFT JOIN location_master lm ON il.location = lm.id
      LEFT JOIN items_table it ON il.item_number = it.id
      LEFT JOIN branch_table b ON il.branch = b.id
      WHERE il.company = ? AND il.item_number = ?
    ''',
      [companyId, itemId],
    );

    return items.map((p) => ItemLocation.fromMap(p)).toList();
  }

  // Get item locations by item number
  Future<List<ItemLocation>> getItemLocationsByItem({
    required int companyId,
    required int itemNumber,
    required int locationId,
    Transaction? txn,
  }) async {
    final db = txn ?? await databaseService.database;
    final items = await db.query(
      'item_location',
      where: 'company = ? AND item_number = ? AND location = ?',
      whereArgs: [companyId, itemNumber, locationId],
    );
    return items.map((p) => ItemLocation.fromMap(p)).toList();
  }

  // Update quantity on hand
  Future<int> updateQuantityOnHand({
    required int id,
    required int companyId,
    required double quantity,
  }) async {
    final db = await databaseService.database;
    final result = await db.update(
      'item_location',
      {'quantity_on_hand': quantity},
      where: 'id = ? AND company = ?',
      whereArgs: [id, companyId],
    );
    captureSync(
      tableName: 'ItemLocations',
      entityMap: {'quantity_on_hand': quantity},
      entityId: id.toString(),
      operation: 'UPDATE',
      company: companyId.toString(),
    );
    return result;
  }

  /// Saves item location for sales order and cascades to branch
  /// Equivalent to Java's ItemLocationsController.saveRow
  Future<void> saveLocationForSalesOrder({
    required ItemLocation location,
    required String transactionType,
    required int? trNo,
    required String? remark,
    required SalesOrderDetail? soD,
    required int companyId,
  }) async {
    double qtyChange = 0.0;

    if (location.id == null) {
      // New location
      await createItemLocation(location);
      qtyChange = location.quantityOnHand ?? 0.0;
    } else {
      // Existing location - calculate quantity change
      final existingLocation = await getItemLocationById(
        location.id!,
        companyId,
      );
      final oldQty = existingLocation?.quantityOnHand ?? 0.0;
      final newQty = location.quantityOnHand ?? 0.0;

      qtyChange = newQty - oldQty;

      await updateItemLocation(location);
      if (kDebugMode) {
        developer.log('Quantity on hand updated: ${location.quantityOnHand}');
      }
    }

    // Only cascade if quantity changed
    if (qtyChange != 0.0) {
      await updatingItemsInBranchQuantityFromLocation(
        location: location,
        transactionType: transactionType,
        trNo: trNo,
        remark: remark,
        qtyChange: qtyChange,
        soD: soD,
        companyId: companyId,
      );
    }
  }

  /// Updates item in branch from location changes
  /// Equivalent to Java's ItemLocationsController.updatingItemsInBranchQuantity
  Future<void> updatingItemsInBranchQuantityFromLocation({
    required ItemLocation location,
    required String transactionType,
    required int? trNo,
    required String? remark,
    required double qtyChange,
    required SalesOrderDetail? soD,
    required int companyId,
  }) async {
    if (location.itemNumber == null || location.branch == null) {
      throw Exception('Location missing item number or branch');
    }

    final db = await databaseService.database;

    // 1. Query all locations for this branch and item
    final locations = await getItemLocationsByBranchAndItem(
      companyId: companyId,
      branchId: location.branch!,
      itemId: location.itemNumber!,
    );

    // 2. Sum quantities from all locations
    final totalLocationQty = locations.fold(
      0.0,
      (sum, loc) => sum + (loc.quantityOnHand ?? 0.0),
    );

    // 3. Update items in branch
   final result = await db.update(
      'items_in_branch',
      {'quantity_available': totalLocationQty},
      where: 'company = ? AND item_number = ? AND branch = ?',
      whereArgs: [companyId, location.itemNumber, location.branch],
    );
    captureSync(
      tableName: 'ItemsInBranch',
      entityMap: {'quantity_available': totalLocationQty},
      entityId: location.itemNumber.toString(),
      operation: 'UPDATE',
      company: companyId.toString(),
    );

    // 4. Transaction creation will be handled by item_transaction_repo
    // to avoid circular dependency
  }
}
