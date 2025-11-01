// features/stock/item_locations/repositories/item_locations_repository.dart
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/stock/item_locations/models/item_locations_model.dart';

class ItemLocationsRepository {
  final LocalDatabaseService databaseService;

  ItemLocationsRepository({required this.databaseService});

  // Get all item locations for a company
  Future<List<ItemLocation>> getItemLocations(int companyId) async {
    final db = await databaseService.database;
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
  }) async {
    final db = await databaseService.database;
    final items = await db.rawQuery(
      '''
      SELECT il.*,
             lm.location_description,
             it.item_description,
             it.unit_of_measure,
             b.description as branch_name
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

  // Get item location by ID
  Future<ItemLocation?> getItemLocationById(int id, int companyId) async {
    final db = await databaseService.database;
    final items = await db.query(
      'item_location',
      where: 'id = ? AND company = ?',
      whereArgs: [id, companyId],
    );
    return items.isNotEmpty ? ItemLocation.fromMap(items.first) : null;
  }

  // Create new item location
  Future<int> createItemLocation(ItemLocation item) async {
    final db = await databaseService.database;
    final itemMap = item.toMap();
    itemMap.remove('id'); // Remove ID for new insertion
    return await db.insert('item_location', itemMap);
  }

  // Update existing item location
  Future<int> updateItemLocation(ItemLocation item) async {
    final db = await databaseService.database;
    return await db.update(
      'item_location',
      item.toMap(),
      where: 'id = ? AND company = ?',
      whereArgs: [item.id, item.company],
    );
  }

  // Delete item location
  Future<int> deleteItemLocation(int id, int companyId) async {
    final db = await databaseService.database;
    return await db.delete(
      'item_location',
      where: 'id = ? AND company = ?',
      whereArgs: [id, companyId],
    );
  }

  // Batch delete multiple item locations
  Future<void> deleteItemLocations(List<int> ids, int companyId) async {
    final db = await databaseService.database;
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
             b.description as branch_name
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
      where: 'company = ? AND location = ?',
      whereArgs: [companyId, locationId],
    );
    return items.map((p) => ItemLocation.fromMap(p)).toList();
  }

  // Get item locations by item number
  Future<List<ItemLocation>> getItemLocationsByItem({
    required int companyId,
    required int itemNumber,
  }) async {
    final db = await databaseService.database;
    final items = await db.query(
      'item_location',
      where: 'company = ? AND item_number = ?',
      whereArgs: [companyId, itemNumber],
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
    return await db.update(
      'item_location',
      {'quantity_on_hand': quantity},
      where: 'id = ? AND company = ?',
      whereArgs: [id, companyId],
    );
  }
}
