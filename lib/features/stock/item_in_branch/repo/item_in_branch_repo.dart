// features/stock/item_in_branch/repositories/item_in_branch_repository.dart
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/stock/item_in_branch/models/item_in_branch_model.dart';

class StockItemInBranchRepository {
  final LocalDatabaseService databaseService;

  StockItemInBranchRepository({required this.databaseService});

  // Create new item in branch
  Future<int> create(ItemInBranchModel item) async {
    final db = await databaseService.database;
    final itemMap = item.toMap();
    itemMap.remove('id'); // Remove id for new insertion
    return await db.insert('items_in_branch', itemMap);
  }

  // Update existing item in branch
  Future<int> update(ItemInBranchModel item) async {
    final db = await databaseService.database;
    return await db.update(
      'items_in_branch',
      item.toMap(),
      where: 'id = ? AND company = ?',
      whereArgs: [item.id, item.company],
    );
  }

  // Delete item from branch
  Future<int> delete(int id, int companyId) async {
    final db = await databaseService.database;
    return await db.delete(
      'items_in_branch',
      where: 'id = ? AND company = ?',
      whereArgs: [id, companyId],
    );
  }

  // Delete multiple items from branch
  Future<void> deleteMultiple(List<int> ids, int companyId) async {
    final db = await databaseService.database;
    final placeholders = List.filled(ids.length, '?').join(',');
    final whereArgs = [...ids, companyId];
    
    await db.delete(
      'items_in_branch',
      where: 'id IN ($placeholders) AND company = ?',
      whereArgs: whereArgs,
    );
  }

  // Find item in branch by ID
  Future<ItemInBranchModel?> findById(int id) async {
    final db = await databaseService.database;
    final maps = await db.rawQuery('''
      SELECT ib.*, 
             i.item_description, i.barcode, i.items_id,
             b.description as branch_description, b.reference_id as branch_reference
      FROM items_in_branch ib
      LEFT JOIN items_table i ON ib.item_number = i.id
      LEFT JOIN branch_table b ON ib.branch = b.id
      WHERE ib.id = ? AND ib.company = ?
    ''', [id]);
    
    if (maps.isNotEmpty) {
      return ItemInBranchModel.fromMap(maps.first);
    }
    return null;
  }

  // Find all items in branch for company
  Future<List<ItemInBranchModel>> findAll(int companyId, {int? branchId, int? itemNumber}) async {
    final db = await databaseService.database;
    
    String whereClause = 'WHERE ib.company = ?';
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
      $whereClause
      ORDER BY i.item_description ASC
    ''', whereArgs);
    
    return maps.map((map) => ItemInBranchModel.fromMap(map)).toList();
  }

  // Find item in branch by item number and branch
  Future<ItemInBranchModel?> findByItemAndBranch(int itemNumber, int branchId, int companyId) async {
    final db = await databaseService.database;
    final maps = await db.rawQuery('''
      SELECT ib.*, 
             i.item_description, i.barcode, i.items_id,
             b.description as branch_description, b.reference_id as branch_reference
      FROM items_in_branch ib
      LEFT JOIN items_table i ON ib.item_number = i.id
      LEFT JOIN branch_table b ON ib.branch = b.id
      WHERE ib.item_number = ? AND ib.branch = ? AND ib.company = ?
    ''', [itemNumber, branchId, companyId]);
    
    if (maps.isNotEmpty) {
      return ItemInBranchModel.fromMap(maps.first);
    }
    return null;
  }

  // Find all items in branch for a specific item
  Future<List<ItemInBranchModel>> findByItem(int itemNumber, int companyId) async {
    final db = await databaseService.database;
    final maps = await db.rawQuery('''
      SELECT ib.*, 
             i.item_description, i.barcode, i.items_id,
             b.description as branch_description, b.reference_id as branch_reference
      FROM items_in_branch ib
      LEFT JOIN items_table i ON ib.item_number = i.id
      LEFT JOIN branch_table b ON ib.branch = b.id
      WHERE ib.item_number = ? AND ib.company = ?
    ''', [itemNumber, companyId]);
    
    return maps.map((map) => ItemInBranchModel.fromMap(map)).toList();
  }

  // Find all items in branch for a specific branch
  Future<List<ItemInBranchModel>> findByBranch(int branchId, int companyId) async {
    final db = await databaseService.database;
    final maps = await db.rawQuery('''
      SELECT ib.*, 
             i.item_description, i.barcode, i.items_id,
             b.description as branch_description, b.reference_id as branch_reference
      FROM items_in_branch ib
      LEFT JOIN items_table i ON ib.item_number = i.id
      LEFT JOIN branch_table b ON ib.branch = b.id
      WHERE ib.branch = ? AND ib.company = ?
    ''', [branchId, companyId]);
    
    return maps.map((map) => ItemInBranchModel.fromMap(map)).toList();
  }

  // Check if item exists in branch (duplication check)
  Future<bool> existsByItemAndBranch(int itemNumber, int branchId, int companyId, {int? excludeId}) async {
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
    return await db.update(
      'items_in_branch',
      {'unit_price': unitPrice},
      where: 'id = ? AND company = ?',
      whereArgs: [id, companyId],
    );
  }

  // Update quantity on hand for item in branch
  Future<int> updateQuantity(int id, double quantity, int companyId) async {
    final db = await databaseService.database;
    return await db.update(
      'items_in_branch',
      {'quantity_on_hand': quantity},
      where: 'id = ? AND company = ?',
      whereArgs: [id, companyId],
    );
  }

  // Update margin for item in branch
  Future<int> updateMargin(int id, String marginType, double marginRate, int companyId) async {
    final db = await databaseService.database;
    return await db.update(
      'items_in_branch',
      {
        'margin_type': marginType,
        'margin_rate': marginRate,
      },
      where: 'id = ? AND company = ?',
      whereArgs: [id, companyId],
    );
  }

  // Search items in branch
  Future<List<ItemInBranchModel>> search(String query, int companyId, {int? branchId}) async {
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

  // Get total quantity of an item across all branches
  Future<double> getTotalQuantityByItem(int itemNumber, int companyId) async {
    final db = await databaseService.database;
    final result = await db.rawQuery('''
      SELECT SUM(quantity_available) as total_quantity
      FROM items_in_branch
      WHERE item_number = ? AND company = ?
    ''', [itemNumber, companyId]);
    
    if (result.isNotEmpty) {
      return result.first['total_quantity'] as double? ?? 0.0;
    }
    return 0.0;
  }

  // Get items with low stock (below reorder level)
  Future<List<ItemInBranchModel>> getLowStockItems(int companyId, {int? branchId}) async {
    final db = await databaseService.database;
    
    String whereClause = 'ib.quantity_on_hand <= ib.reorder_level AND ib.company = ?';
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
      ORDER BY ib.quantity_on_hand ASC
    ''', whereArgs);
    
    return maps.map((map) => ItemInBranchModel.fromMap(map)).toList();
  }

  // Get items with zero stock
  Future<List<ItemInBranchModel>> getOutOfStockItems(int companyId, {int? branchId}) async {
    final db = await databaseService.database;
    
    String whereClause = 'ib.quantity_on_hand <= 0 AND ib.company = ?';
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
  Future<List<ItemInBranchModel>> getReorderPointItems(int companyId, {int? branchId, int? itemNumber}) async {
    final db = await databaseService.database;
    
    String whereClause = 'ib.quantity_available <= ib.reorder_point AND ib.company = ?';
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
}