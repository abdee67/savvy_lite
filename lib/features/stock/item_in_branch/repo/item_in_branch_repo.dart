// features/stock/item_in_branch/repositories/item_in_branch_repository.dart
import 'package:savvy_stock/core/repositories/base_repo.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/sales/sales_order/detail/model/sales_order_detail.dart';
import 'package:savvy_stock/features/stock/item_in_branch/models/available_items_in_branch_filter.dart';
import 'package:savvy_stock/features/stock/item_in_branch/models/item_in_branch_model.dart';
import 'package:savvy_stock/features/stock/item_in_branch/models/paginated_aval_item_in_branch_result.dart';
import 'package:savvy_stock/features/stock/item_transactions/model/paginated_item_transaction_result.dart';
import 'package:sqflite/sqflite.dart';

class StockItemInBranchRepository extends BaseRepository {
  @override
  final LocalDatabaseService databaseService;

  StockItemInBranchRepository({required this.databaseService});

  // Create new item in branch
  Future<int> create(ItemInBranchModel item, {Transaction? txn}) async {
    final db = txn ?? await databaseService.database;
    final itemMap = item.toMap();
    itemMap.remove('id'); // Remove id for new insertion
    final id = await db.insert('items_in_branch', withSyncKey(itemMap));
    itemMap['id'] = id;
    captureSync(
      tableName: 'items_in_branch',
      entityMap: itemMap,
      entityId: id.toString(),
      operation: 'INSERT',
      company: item.company?.toString(),
    );
    return id;
  }

  // Update existing item in branch
  Future<int> update(ItemInBranchModel item, {Transaction? txn}) async {
    final db = txn ?? await databaseService.database;

    // Sync lot prices if unit price is present
    if (item.unitPrice != null && item.company != null) {
      await db.update(
        'lot_master',
        {'unit_price': item.unitPrice},
        where: 'item_number = ? AND branch = ? AND company = ?',
        whereArgs: [item.itemNumber, item.branch, item.company],
      );
      captureSync(
        tableName: 'lot_master',
        entityMap: {'unit_price': item.unitPrice},
        entityId: item.itemNumber.toString(),
        operation: 'UPDATE',
        company: item.company?.toString(),
      );
    }

    final result = await db.update(
      'items_in_branch',
      item.toMap(),
      where: 'id = ? AND company = ? AND branch = ? ',
      whereArgs: [item.id, item.company, item.branch],
    );
    captureSync(
      tableName: 'items_in_branch',
      entityMap: item.toMap(),
      entityId: item.id.toString(),
      operation: 'UPDATE',
      company: item.company?.toString(),
    );
    return result;
  }

  // Delete item from branch
  Future<int> delete(int id, int companyId, {Transaction? txn}) async {
    final db = txn ?? await databaseService.database;
    // Fetch full row data BEFORE deleting
    final itemRows = await db.query(
      'items_in_branch',
      where: 'id = ? AND company = ? AND branch = ?',
      whereArgs: [id, companyId],
    );
    final result = await db.delete(
      'items_in_branch',
      where: 'id = ? AND company = ? AND branch = ?',
      whereArgs: [id, companyId],
    );
    for (final row in itemRows) {
    captureSync(
      tableName: 'items_in_branch',
      entityMap: row,
      entityId: row['id'].toString(),
      operation: 'DELETE',
      company: companyId.toString(),
    );
    }
    return result;
  }

  // Delete multiple items from branch
  Future<void> deleteMultiple(
    List<int> ids,
    int companyId, {
    Transaction? txn,
  }) async {
    final db = txn ?? await databaseService.database;
    final placeholders = List.filled(ids.length, '?').join(',');
    final whereArgs = [...ids, companyId];
    final itemRows = await db.query(
      'items_in_branch',
      where: 'id IN ($placeholders) AND company = ?',
      whereArgs: whereArgs,
    );
    await db.delete(
      'items_in_branch',
      where: 'id IN ($placeholders) AND company = ?',
      whereArgs: whereArgs,
    );
    for (final row in itemRows) {
    captureSync(
      tableName: 'items_in_branch',
      entityMap: row,
      entityId: row['id'].toString(),
      operation: 'DELETE',
      company: companyId.toString(),
    );
    }
  }

  // Find item in branch by ID
  Future<ItemInBranchModel?> findById(
    int id,
    int companyId, {
    Transaction? txn,
  }) async {
    final db = txn ?? await databaseService.database;
    final maps = await db.rawQuery(
      '''
      SELECT ib.*, 
             i.item_description, i.barcode, i.items_id,
             b.description as branch_description, b.reference_id as branch_reference
      FROM items_in_branch ib
      LEFT JOIN items_table i ON ib.item_number = i.id
      LEFT JOIN branch_table b ON ib.branch = b.id
      WHERE ib.id = ? AND ib.company = ?
    ''',
      [id],
    );

    if (maps.isNotEmpty) {
      return ItemInBranchModel.fromMap(maps.first);
    }
    return null;
  }

  // Find all items in branch for company
  Future<List<ItemInBranchModel>> findAll(
    int companyId, {
    int? branchId,
    int? itemNumber,
  }) async {
    final db = await databaseService.database;

    String whereClause = 'WHERE ib.company = ?';
    List<dynamic> whereArgs = [companyId];

    if (branchId != null) {
      whereClause += ' AND ib.branch = ?';
      whereArgs.add(branchId);
    }

    final maps = await db.rawQuery('''
      SELECT ib.*, 
             i.item_description,
             i.barcode,
             i.items_id,
             b.description as branch_description,
             b.reference_id as branch_reference,
             u.description_1 as unit_of_measure_description,
             u.detail_code as unit_of_measure_code
      FROM items_in_branch ib
      LEFT JOIN items_table i ON ib.item_number = i.id
      LEFT JOIN branch_table b ON ib.branch = b.id
      LEFT JOIN udc_details u ON ib.unit_of_measure = u.id
      $whereClause
      ORDER BY i.item_description ASC
    ''', whereArgs);

    return maps.map((map) => ItemInBranchModel.fromMap(map)).toList();
  }

  // Find item in branch by item number and branch
  Future<ItemInBranchModel?> findByItemAndBranch(
    int itemNumber,
    int branchId,
    int companyId, {
    Transaction? txn,
  }) async {
    final db = txn ?? await databaseService.database;
    final maps = await db.rawQuery(
      '''
      SELECT ib.*, 
             i.item_description,
             i.barcode,
             i.items_id,
             b.description as branch_description,
             b.reference_id as branch_reference,
             u.description_1 as unit_of_measure_description,
             u.detail_code as unit_of_measure_code
      FROM items_in_branch ib
      LEFT JOIN items_table i ON ib.item_number = i.id
      LEFT JOIN branch_table b ON ib.branch = b.id
      LEFT JOIN udc_details u ON ib.unit_of_measure = u.id
      WHERE ib.item_number = ? AND ib.branch = ? AND ib.company = ?
    ''',
      [itemNumber, branchId, companyId],
    );

    if (maps.isNotEmpty) {
      return ItemInBranchModel.fromMap(maps.first);
    }
    return null;
  }

  // Find all items in branch for a specific item
  Future<List<ItemInBranchModel>> findByItem(
    int itemNumber,
    int companyId, {
    Transaction? txn,
  }) async {
    final db = txn ?? await databaseService.database;
    final maps = await db.rawQuery(
      '''
      SELECT ib.*, 
             i.item_description,
             i.barcode,
             i.items_id,
             b.description as branch_description,
             b.reference_id as branch_reference,
             u.description_1 as unit_of_measure_description,
             u.detail_code as unit_of_measure_code
      FROM items_in_branch ib
      LEFT JOIN items_table i ON ib.item_number = i.id
      LEFT JOIN branch_table b ON ib.branch = b.id
      LEFT JOIN udc_details u ON ib.unit_of_measure = u.id
      WHERE ib.item_number = ? AND ib.company = ?
    ''',
      [itemNumber, companyId],
    );

    return maps.map((map) => ItemInBranchModel.fromMap(map)).toList();
  }

  // Find all items in branch for a specific branch
  Future<List<ItemInBranchModel>> findByBranch(
    int branchId,
    int companyId,
  ) async {
    final db = await databaseService.database;
    final maps = await db.rawQuery(
      '''
      SELECT ib.*, 
             i.item_description,
             i.barcode,
             i.items_id,
             b.description as branch_description,
             b.reference_id as branch_reference,
             u.description_1 as unit_of_measure_description,
             u.detail_code as unit_of_measure_code
      FROM items_in_branch ib
      LEFT JOIN items_table i ON ib.item_number = i.id
      LEFT JOIN branch_table b ON ib.branch = b.id
      LEFT JOIN udc_details u ON ib.unit_of_measure = u.id
      WHERE ib.branch = ? AND ib.company = ?
    ''',
      [branchId, companyId],
    );

    return maps.map((map) => ItemInBranchModel.fromMap(map)).toList();
  }

  //find item from branch by barcode
  Future<List<ItemInBranchModel>> findByBarcode(
    String barcode,
    int companyId,
  ) async {
    final db = await databaseService.database;
    final maps = await db.rawQuery(
      '''
      SELECT ib.*, 
             i.item_description,
             i.barcode,
             i.items_id,
             b.description as branch_description,
             b.reference_id as branch_reference,
             u.description_1 as unit_of_measure_description,
             u.detail_code as unit_of_measure_code
      FROM items_in_branch ib
      LEFT JOIN items_table i ON ib.item_number = i.id
      LEFT JOIN branch_table b ON ib.branch = b.id
      LEFT JOIN udc_details u ON ib.unit_of_measure = u.id
      WHERE i.barcode = ? AND ib.company = ?
    ''',
      [barcode, companyId],
    );

    return maps.map((map) => ItemInBranchModel.fromMap(map)).toList();
  }

  // Check if item exists in branch (duplication check)
  Future<bool> existsByItemAndBranch(
    int itemNumber,
    int branchId,
    int companyId, {
    int? excludeId,
  }) async {
    final db = await databaseService.database;

    String whereClause = 'item_number = ? AND branch = ? AND company = ?';
    List<dynamic> whereArgs = [itemNumber, branchId, companyId];

    if (excludeId != null) {
      whereClause += ' AND id != ?';
      whereArgs.add(excludeId);
    }

    final maps = await db.query(
      'items_in_branch',
      where: whereClause,
      whereArgs: whereArgs,
      limit: 1,
    );

    return maps.isNotEmpty;
  }

  // Update unit price for item in branch
  Future<int> updateUnitPrice(int id, double unitPrice, int companyId) async {
    final db = await databaseService.database;

    // Get item and branch for this record
    final itemBranch = await db.query(
      'items_in_branch',
      columns: ['item_number', 'branch'],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (itemBranch.isNotEmpty) {
      final itemNumber = itemBranch.first['item_number'] as int;
      final branch = itemBranch.first['branch'] as int;

      // Update lots for this item+branch
      await db.update(
        'lot_master',
        {'unit_price': unitPrice},
        where: 'item_number = ? AND branch = ? AND company = ?',
        whereArgs: [itemNumber, branch, companyId],
      );
      captureSync(
        tableName: 'lot_master',
        entityMap: {'unit_price': unitPrice},
        entityId: itemNumber.toString(),
        operation: 'UPDATE',
        company: companyId.toString(),
      );
    }

    final result = await db.update(
      'items_in_branch',
      {'unit_price': unitPrice},
      where: 'id = ? AND company = ?',
      whereArgs: [id, companyId],
    );
    captureSync(
      tableName: 'items_in_branch',
      entityMap: {'unit_price': unitPrice},
      entityId: id.toString(),
      operation: 'UPDATE',
      company: companyId.toString(),
    );
    return result;
  }

  // Update quantity on hand for item in branch
  Future<int> updateQuantity(int id, double quantity, int companyId) async {
    final db = await databaseService.database;
    final result = await db.update(
      'items_in_branch',
      {
        // Keep both on-hand and available quantities in sync so that
        // UI (which reads quantity_available) reflects stock changes.
        //  'quantity_on_hand': quantity,
        'quantity_available': quantity,
      },
      where: 'id = ? AND company = ?',
      whereArgs: [id, companyId],
    );
    captureSync(
      tableName: 'items_in_branch',
      entityMap: {'quantity_available': quantity},
      entityId: id.toString(),
      operation: 'UPDATE',
      company: companyId.toString(),
    );
    return result;
  }

  // Update margin for item in branch
  Future<int> updateMargin(
    int id,
    String marginType,
    double marginRate,
    int companyId,
  ) async {
    final db = await databaseService.database;
    final result = await db.update(
      'items_in_branch',
      {'margin_type': marginType, 'margin_rate': marginRate},
      where: 'id = ? AND company = ?',
      whereArgs: [id, companyId],
    );
    captureSync(
      tableName: 'items_in_branch',
      entityMap: {'margin_type': marginType, 'margin_rate': marginRate},
      entityId: id.toString(),
      operation: 'UPDATE',
      company: companyId.toString(),
    );
    return result;
  }

  // Search items in branch
  Future<List<ItemInBranchModel>> search(
    String query,
    int companyId, {
    int? branchId,
  }) async {
    final db = await databaseService.database;

    String whereClause = '''
      (i.item_description LIKE ? OR i.barcode LIKE ? OR i.items_id LIKE ?) 
      AND ib.company = ?
    ''';
    List<dynamic> whereArgs = ['%$query%', '%$query%', '%$query%', companyId];

    if (branchId != null) {
      whereClause += ' AND ib.branch = ?';
      whereArgs.add(branchId);
    }

    final maps = await db.rawQuery('''
      SELECT ib.*, 
             i.item_description,
             i.barcode,
             i.items_id,
             b.description as branch_description,
             b.reference_id as branch_reference,
             u.description_1 as unit_of_measure_description,
             u.detail_code as unit_of_measure_code
      FROM items_in_branch ib
      LEFT JOIN items_table i ON ib.item_number = i.id
      LEFT JOIN branch_table b ON ib.branch = b.id
      LEFT JOIN udc_details u ON ib.unit_of_measure = u.id
      WHERE $whereClause
      ORDER BY i.item_description ASC
    ''', whereArgs);

    return maps.map((map) => ItemInBranchModel.fromMap(map)).toList();
  }

  // Get total quantity of an item across all branches
  Future<double> getTotalQuantityByItem(int itemNumber, int companyId) async {
    final db = await databaseService.database;
    final result = await db.rawQuery(
      '''
      SELECT SUM(quantity_available) as total_quantity
      FROM items_in_branch
      WHERE item_number = ? AND company = ?
    ''',
      [itemNumber, companyId],
    );

    if (result.isNotEmpty) {
      return result.first['total_quantity'] as double? ?? 0.0;
    }
    return 0.0;
  }

  // Get items with low stock (below reorder level)
  Future<List<ItemInBranchModel>> getLowStockItems(
    int companyId, {
    int? branchId,
  }) async {
    final db = await databaseService.database;

    String whereClause =
        'ib.quantity_available <= ib.reorder_level AND ib.company = ?';
    List<dynamic> whereArgs = [companyId];

    if (branchId != null) {
      whereClause += ' AND ib.branch = ?';
      whereArgs.add(branchId);
    }

    final maps = await db.rawQuery('''
      SELECT ib.*, 
             i.item_description, i.barcode, i.items_id,
             b.description as branch_description, b.reference_id as branch_reference
      FROM items_in_branch ib
      LEFT JOIN items_table i ON ib.item_number = i.id
      LEFT JOIN branch_table b ON ib.branch = b.id
      WHERE $whereClause
      ORDER BY ib.quantity_available ASC
    ''', whereArgs);

    return maps.map((map) => ItemInBranchModel.fromMap(map)).toList();
  }

  // Get items with zero stock
  Future<List<ItemInBranchModel>> getOutOfStockItems(
    int companyId, {
    int? branchId,
  }) async {
    final db = await databaseService.database;

    String whereClause = 'ib.quantity_available <= 0 AND ib.company = ?';
    List<dynamic> whereArgs = [companyId];

    if (branchId != null) {
      whereClause += ' AND ib.branch = ?';
      whereArgs.add(branchId);
    }

    final maps = await db.rawQuery('''
      SELECT ib.*, 
             i.item_description, i.barcode, i.items_id,
             b.description as branch_description, b.reference_id as branch_reference
      FROM items_in_branch ib
      LEFT JOIN items_table i ON ib.item_number = i.id
      LEFT JOIN branch_table b ON ib.branch = b.id
      WHERE $whereClause
      ORDER BY i.item_description ASC
    ''', whereArgs);

    return maps.map((map) => ItemInBranchModel.fromMap(map)).toList();
  }

  // Get items that reach reorder points or under
  Future<List<ItemInBranchModel>> getReorderPointItems(
    int companyId, {
    int? branchId,
    int? itemNumber,
  }) async {
    final db = await databaseService.database;

    String whereClause =
        'ib.quantity_available <= ib.reorder_point AND ib.company = ?';
    List<dynamic> whereArgs = [companyId];

    if (branchId != null) {
      whereClause += ' AND ib.branch = ?';
      whereArgs.add(branchId);
    }

    if (itemNumber != null) {
      whereClause += ' AND ib.item_number = ?';
      whereArgs.add(itemNumber);
    }

    final maps = await db.rawQuery('''
      SELECT ib.*, 
             i.item_description, i.barcode, i.items_id,
             b.description as branch_description, b.reference_id as branch_reference
      FROM items_in_branch ib
      LEFT JOIN items_table i ON ib.item_number = i.id
      LEFT JOIN branch_table b ON ib.branch = b.id
      WHERE $whereClause
      ORDER BY ib.quantity_available ASC
    ''', whereArgs);

    return maps.map((map) => ItemInBranchModel.fromMap(map)).toList();
  }

  // Update multiple items in batch
  Future<void> updateBatch(List<ItemInBranchModel> items) async {
    final db = await databaseService.database;
    final batch = db.batch();

    for (final item in items) {
      batch.update(
        'items_in_branch',
        item.toMap(),
        where: 'id = ? AND company = ?',
        whereArgs: [item.id, item.company],
      );
    }

    await batch.commit();
  }

  // Filter items by custom criteria (like the Java controller's filterItemsInBranch)
  Future<List<ItemInBranchModel>> filterItems({
    required int companyId,
    int? branchId,
    int? itemNumber,
    bool? reachesReorderPointsOrUnder,
    bool? noAvailability,
  }) async {
    final db = await databaseService.database;

    String whereClause = 'WHERE ib.company = ?';
    List<dynamic> whereArgs = [companyId];

    if (branchId != null) {
      whereClause += ' AND ib.branch = ?';
      whereArgs.add(branchId);
    }

    if (itemNumber != null) {
      whereClause += ' AND ib.item_number = ?';
      whereArgs.add(itemNumber);
    }

    final maps = await db.rawQuery('''
      SELECT ib.*, 
             i.item_description, i.barcode, i.items_id,
             b.description as branch_description, b.reference_id as branch_reference
      FROM items_in_branch ib
      LEFT JOIN items_table i ON ib.item_number = i.id
      LEFT JOIN branch_table b ON ib.branch = b.id
      $whereClause
      ORDER BY i.item_description ASC
    ''', whereArgs);

    var items = maps.map((map) => ItemInBranchModel.fromMap(map)).toList();

    // Apply additional filters like in Java controller
    if (reachesReorderPointsOrUnder == true) {
      items = items.where((item) {
        final availability = _calculateAvailability(item);
        final reorderPoint = _calculateReorderPoint(item);
        return availability <= reorderPoint;
      }).toList();
    }

    if (noAvailability == true) {
      items = items.where((item) {
        final availability = _calculateAvailability(item);
        return availability == 0.0;
      }).toList();
    }

    return items;
  }

  // Helper methods for complex calculations
  double _calculateAvailability(ItemInBranchModel item) {
    // This would need integration with LotMaster for expiration logic
    // For now, just return quantity available
    return item.quantityAvailable ?? 0.0;
  }

  double _calculateReorderPoint(ItemInBranchModel item) {
    // This would need integration with item, branch, and company reorder points
    // For now, just return the item's reorder point
    return item.reorderPoint ?? 0.0;
  }

  // Restore stock quantities for voided sales
  Future<void> restoreStockQuantitiesForVoid({
    required List<SalesOrderDetail> voidedItems,
    required int companyId,
  }) async {
    for (final item in voidedItems) {
      if (item.itemInBranch != null && item.quantity != null) {
        await updateQuantity(
          item.itemInBranch!.toInt(),
          item.quantity!,
          companyId,
        );
      }
    }
  }

  Future<PaginatedItemTransactionResult> getPaginatedItemsInBranch({
    ///for reorder point report
    required int companyId,
    required int page,
    required int pageSize,
    String? sortField,
    bool ascending = true,
  }) async {
    final db = await databaseService.database;

    // Build WHERE clause dynamically
    final whereConditions = <String>['company = ?'];
    final whereArgs = <dynamic>[companyId];
    // Build base query
    var query = '''
          SELECT ib.*,
             i.item_description,
             i.barcode,
             i.items_id,
             b.description as branch_description,
             b.reference_id as branch_reference,
             i.unit_of_measure,
             umd.description_1 as unit_of_measure_description,
             umd.detail_code as unit_of_measure_code
      FROM items_in_branch ib
      LEFT JOIN items_table i ON ib.item_number = i.id
      LEFT JOIN branch_table b ON ib.branch = b.id
      LEFT JOIN udc_details umd ON i.unit_of_measure = umd.id
      WHERE ib.company = ?
    ''';

    final params = whereArgs;

    // Add sorting
    if (sortField != null) {
      query += ' ORDER BY $sortField ${ascending ? 'ASC' : 'DESC'}';
    }

    // Add pagination
    query += ' LIMIT ? OFFSET ?';
    params.add(pageSize);
    params.add((page - 1) * pageSize);

    // Execute main query
    final itemsData = await db.rawQuery(query, params);

    // Count total records
    final countResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM branch_table WHERE company = ?',
      [companyId],
    );

    final totalCount = (countResult.first['count'] as int?) ?? 0;

    // Parse results
    final items = itemsData.map((row) {
      return ItemInBranchModel.fromMap(row);
    }).toList();

    return PaginatedItemTransactionResult(
      itemInBranch: items,
      totalCount: totalCount,
    );
  }

  // Get lazy paginated item locations with filters and sorting
  Future<PaginatedItemInBranchResult> getLazyItemInBranchPaginated({
    required int companyId,
    required AvailableItemsInBranchFilter filters,
    required int page,
    required int pageSize,
    String? sortBy,
    bool sortAscending = true,
  }) async {
    final db = await databaseService.database;

    final whereConditions = <String>['ib.company = ?'];
    final whereArgs = <dynamic>[companyId];

    if (filters.itemNumber != null) {
      whereConditions.add('ib.item_number = ?');
      whereArgs.add(filters.itemNumber);
    }
    if (filters.branchId != null) {
      whereConditions.add('ib.branch = ?');
      whereArgs.add(filters.branchId);
    }

    if (filters.noAvailable) {
      whereConditions.add(
        '(ib.quantity_available IS NULL OR ib.quantity_available = 0.0)',
      );
    }

    final whereClause = whereConditions.join(' AND ');

    // 1. COUNT query
    final countResult = await db.rawQuery('''
      SELECT COUNT(ib.id) as count
      FROM items_in_branch ib
      WHERE $whereClause
    ''', whereArgs);

    int totalCount = (countResult.first['count'] as int?) ?? 0;

    // 2. DATA query with LEFT JOIN to emulate java's itemCostCache implicitly
    String orderByClause;
    if (sortBy != null && sortBy.isNotEmpty) {
      // Basic protection against SQL injection on order by
      final safeSortBy = sortBy.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
      orderByClause = 'ib.$safeSortBy ${sortAscending ? "ASC" : "DESC"}';
    } else {
      orderByClause = 'ib.id DESC';
    }

    final query =
        '''
      SELECT ib.*,
             it.item_description,
             ib.unit_of_measure,
             udc.description_1 as unit_of_measure_description,
             udc.detail_code as unit_of_measure_code,
             it.unit_price,
             b.description as branch_description
      FROM items_in_branch ib
      LEFT JOIN items_table it ON ib.item_number = it.id
      LEFT JOIN udc_details udc ON ib.unit_of_measure = udc.id
      LEFT JOIN branch_table b ON ib.branch = b.id
      WHERE $whereClause
      ORDER BY $orderByClause
      LIMIT ? OFFSET ?
    ''';

    final dataArgs = [...whereArgs, pageSize, (page - 1) * pageSize];
    final itemsData = await db.rawQuery(query, dataArgs);

    final items = itemsData
        .map((map) => ItemInBranchModel.fromMap(map))
        .toList();

    return PaginatedItemInBranchResult(
      itemInBranch: items,
      totalCount: totalCount,
    );
  }

  /// Returns the total quantity of expired lots for a given item+branch.
  /// Mirrors the Java `getExpirationQuantity()` logic:
  ///   SELECT SUM(quantity_available)
  ///   FROM lot_master
  ///   WHERE company = :company AND item_number = :itemNumber
  ///         AND branch = :branch AND lot_status detail_code = 'E'
  Future<double> getExpirationQuantity({
    required int itemNumber,
    required int branchId,
    required int companyId,
  }) async {
    final db = await databaseService.database;
    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(lm.quantity_available), 0.0) as expiration_qty
      FROM lot_master lm
      INNER JOIN udc_details ls ON lm.lot_status = ls.id
      WHERE lm.company = ?
        AND lm.item_number = ?
        AND lm.branch = ?
        AND ls.detail_code = 'E'
    ''',
      [companyId, itemNumber, branchId],
    );

    if (result.isNotEmpty) {
      final val = result.first['expiration_qty'];
      if (val is num) return val.toDouble();
    }
    return 0.0;
  }
}
