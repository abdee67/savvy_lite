// features/stock/item_locations/repositories/item_locations_repository.dart
import 'package:savvy_stock/core/repositories/base_repo.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/sales/sales_order_detail/model/sales_order_detail.dart';
import 'package:savvy_stock/features/stock/item_in_branch/repo/item_in_branch_repo.dart';
import 'package:savvy_stock/features/stock/item_locations/models/item_locations_model.dart';
import 'package:savvy_stock/features/stock/item_transactions/repo/item_transaction_repo.dart';
import 'package:sqflite/sqflite.dart';

class ItemLocationsRepository extends BaseRepository {
  @override
  final LocalDatabaseService databaseService;
  final StockItemInBranchRepository stockItemInBranchRepository;
  final ItemTransactionRepository itemTransactionsRepository;

  ItemLocationsRepository({
    required this.databaseService,
    required this.stockItemInBranchRepository,
    required this.itemTransactionsRepository,
  });

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

  // Case 2: Location management only
  Future<void> handleLocationStockUpdate(
    SalesOrderDetail soD,
    double factor,
    int companyId,
  ) async {
    // Get all item locations for this item and branch
    final itemLocationsList = await getItemLocationsByBranchAndItem(
      companyId: companyId,
      branchId: soD.itemBranch!.branch,
      itemId: soD.itemsTableId!,
    );

    // Filter locations with available stock
    final availableLocations = itemLocationsList
        .where((il) => il.quantityOnHand != null && il.quantityOnHand! > 0)
        .toList();

    double remainingQty = factor * soD.quantity!;

    for (final location in availableLocations) {
      if (remainingQty <= 0) break;

      final currentLocation = await getItemLocationById(
        location.id!,
        companyId,
      );
      final availableQty = currentLocation?.quantityOnHand ?? 0.0;

      if (availableQty >= remainingQty) {
        // This location has enough stock
        final newQty = availableQty - remainingQty;
        final updatedLocation = currentLocation?.copyWith(
          quantityOnHand: newQty,
        );

        await updateItemLocation(updatedLocation!);

        // Create transaction for this location
        await itemTransactionsRepository.stockCardCreation(
          ib: null,
          loc: updatedLocation,
          lm: null,
          transactionType: 'I',
          trNo: soD.orderHeader?.orderNumber,
          remark: 'Sales',
          qty: -remainingQty,
          por: null,
          soD: soD,
        );

        remainingQty = 0;
      } else {
        // Take all available from this location
        final updatedLocation = currentLocation?.copyWith(quantityOnHand: 0.0);
        await updateItemLocation(updatedLocation!);

        // Create transaction for this location
        await itemTransactionsRepository.stockCardCreation(
          ib: null,
          loc: updatedLocation,
          lm: null,
          transactionType: 'I',
          trNo: soD.orderHeader?.orderNumber,
          remark: 'Sales',
          qty: -availableQty,
          por: null,
          soD: soD,
        );

        remainingQty -= availableQty;
      }
    }

    if (remainingQty > 0) {
      throw Exception(
        'Insufficient stock across locations. Remaining: $remainingQty',
      );
    }

    // Update the main item branch quantity
    await stockItemInBranchRepository.updateItemBranchQuantity(
      soD,
      factor,
      companyId,
    );
  }
}
