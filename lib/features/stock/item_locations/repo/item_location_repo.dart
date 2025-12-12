// features/stock/item_locations/repositories/item_locations_repository.dart
import 'package:savvy_stock/core/repositories/base_repo.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/sales/sales_order/detail/model/sales_order_detail.dart';
import 'package:savvy_stock/features/stock/item_locations/models/item_locations_model.dart';
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
        lm.location_description as location_description
      FROM item_location il
      LEFT JOIN location_master lm ON il.location = lm.id
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

  // Create new item location
  Future<int> createItemLocation(ItemLocation item, {Transaction? txn}) async {
    final db = txn ?? await databaseService.database;
    final itemMap = item.toMap();
    itemMap.remove('id'); // Remove ID for new insertion
    return await db.insert('item_location', itemMap);
  }

  // Update existing item location
  Future<int> updateItemLocation(ItemLocation item, {Transaction? txn}) async {
    final db = txn ?? await databaseService.database;
    return await db.update(
      'item_location',
      item.toMap(),
      where: 'id = ? AND company = ?',
      whereArgs: [item.id, item.company],
    );
  }

  // Delete item location
  Future<int> deleteItemLocation(
    int id,
    int companyId, {
    Transaction? txn,
  }) async {
    final db = txn ?? await databaseService.database;
    return await db.delete(
      'item_location',
      where: 'id = ? AND company = ?',
      whereArgs: [id, companyId],
    );
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
      where: 'company = ? AND location = ? ',
      whereArgs: [companyId, locationId],
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
    return await db.update(
      'item_location',
      {'quantity_on_hand': quantity},
      where: 'id = ? AND company = ?',
      whereArgs: [id, companyId],
    );
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
      print('Quantity on hand updated: ${location.quantityOnHand}');
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
    await db.update(
      'items_in_branch',
      {'quantity_available': totalLocationQty},
      where: 'company = ? AND item_number = ? AND branch = ?',
      whereArgs: [companyId, location.itemNumber, location.branch],
    );

    // 4. Transaction creation will be handled by item_transaction_repo
    // to avoid circular dependency
  }
}
