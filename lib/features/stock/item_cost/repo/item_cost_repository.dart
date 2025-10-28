// features/stock/item_cost/repositories/item_cost_repository.dart
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/stock/item_cost/models/item_cost_model.dart';

class ItemCostRepository {
  final LocalDatabaseService databaseService;

  ItemCostRepository({required this.databaseService});

  // Create new item cost
  Future<int> create(ItemCost itemCost) async {
    final db = await databaseService.database;
    final itemMap = itemCost.toMap();
    itemMap.remove('id'); // Remove id for new insertion
    return await db.insert('item_cost', itemMap);
  }

  // Update existing item cost
  Future<int> update(ItemCost itemCost) async {
    final db = await databaseService.database;
    return await db.update(
      'item_cost',
      itemCost.toMap(),
      where: 'id = ?',
      whereArgs: [itemCost.id],
    );
  }

  // Delete item cost
  Future<int> delete(int id) async {
    final db = await databaseService.database;
    return await db.delete(
      'item_cost',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete multiple item costs
  Future<void> deleteMultiple(List<ItemCost> items) async {
    final db = await databaseService.database;
    final batch = db.batch();
    
    for (final item in items) {
      if (item.id != null) {
        batch.delete(
          'item_cost',
          where: 'id = ?',
          whereArgs: [item.id],
        );
      }
    }
    
    await batch.commit();
  }

  // Find item cost by ID
  Future<ItemCost?> findById(int id) async {
    final db = await databaseService.database;
    final maps = await db.query(
      'item_cost',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return ItemCost.fromMap(maps.first);
    }
    return null;
  }

  // Find all item costs
  Future<List<ItemCost>> findAll() async {
    final db = await databaseService.database;
    final maps = await db.query('item_cost');
    return maps.map((map) => ItemCost.fromMap(map)).toList();
  }

  // Find item costs by item number and company
  Future<List<ItemCost>> findByItemNumberAndCompany(int itemNumber, int companyId) async {
    final db = await databaseService.database;
    final maps = await db.query(
      'item_cost',
      where: 'item_number = ? AND company = ?',
      whereArgs: [itemNumber, companyId],
    );
    return maps.map((map) => ItemCost.fromMap(map)).toList();
  }

  // Find item cost by item
  Future<ItemCost?> findByItem(int itemNumber, int companyId) async {
    final db = await databaseService.database;
    final maps = await db.query(
      'item_cost',
      where: 'item_number = ? AND company = ?',
      whereArgs: [itemNumber, companyId],
    );
    
    if (maps.isNotEmpty) {
      return ItemCost.fromMap(maps.first);
    }
    return null;
  }

  // Execute custom query
  Future<List<ItemCost>> executeCustomQuery(
    String whereClause, 
    List<dynamic> whereArgs,
  ) async {
    final db = await databaseService.database;
    final maps = await db.query(
      'item_cost',
      where: whereClause,
      whereArgs: whereArgs,
    );
    return maps.map((map) => ItemCost.fromMap(map)).toList();
  }

  // Get items with joins for detailed information
  Future<List<Map<String, dynamic>>> findDetailedItemCosts(int companyId) async {
    final db = await databaseService.database;
    return await db.rawQuery('''
      SELECT ic.*, 
             i.item_description, i.barcode,
             u.username as user_name,
             c.name as company_name
      FROM item_cost ic
      LEFT JOIN items_table i ON ic.item_number = i.id
      LEFT JOIN user_table u ON ic.user_id = u.id
      LEFT JOIN company_table c ON ic.company = c.id
      WHERE ic.company = ?
      ORDER BY ic.date_updated DESC
    ''', [companyId]);
  }

  // Update multiple item costs in batch
  Future<void> updateBatch(List<ItemCost> items) async {
    final db = await databaseService.database;
    final batch = db.batch();
    
    for (final item in items) {
      if (item.id != null) {
        batch.update(
          'item_cost',
          item.toMap(),
          where: 'id = ?',
          whereArgs: [item.id],
        );
      }
    }
    
    await batch.commit();
  }

  // Check if item cost exists for item and company
  Future<bool> existsByItemAndCompany(int itemNumber, int companyId) async {
    final db = await databaseService.database;
    final maps = await db.query(
      'item_cost',
      where: 'item_number = ? AND company = ?',
      whereArgs: [itemNumber, companyId],
      limit: 1,
    );
    return maps.isNotEmpty;
  }
}