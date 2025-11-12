// features/stock/item_in_branch/repositories/item_in_branch_repository.dart
import 'package:savvy_stock/core/repositories/base_repo.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/sales/customer/models/customer_model.dart';
import 'package:savvy_stock/features/sales/sales_order_detail/model/sales_order_detail.dart';
import 'package:savvy_stock/features/sales/sales_order_header/bloc/sales_order_header_state.dart';
import 'package:savvy_stock/features/stock/item_UoM_conversions/repo/item_uom_conv_repo.dart';
import 'package:savvy_stock/features/stock/item_in_branch/blocs/item_in_branch_state.dart';
import 'package:savvy_stock/features/stock/item_in_branch/models/item_in_branch_model.dart';
import 'package:savvy_stock/features/stock/item_locations/repo/item_location_repo.dart';
import 'package:savvy_stock/features/stock/item_transactions/repo/item_transaction_repo.dart';
import 'package:savvy_stock/features/stock/lot_master/repo/lot_master_repo.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_bloc.dart';
import 'package:savvy_stock/features/system_constant/models/system_constant.dart';
import 'package:sqflite/sqflite.dart';

class StockItemInBranchRepository extends BaseRepository {
  @override
  final LocalDatabaseService databaseService;
  final ItemTransactionRepository itemTransactionsRepository;
  final ItemLocationsRepository itemLocationsRepository;
  final ItemUomConversionsRepository itemUomConversionsRepository;
  final LotMasterRepository lotMasterRepository;
  final SystemConstantBloc systemConstantBloc;

  StockItemInBranchRepository({
    required this.databaseService,
    required this.itemTransactionsRepository,
    required this.itemLocationsRepository,
    required this.itemUomConversionsRepository,
    required this.lotMasterRepository,
    required this.systemConstantBloc,
  });

  // Create new item in branch
  Future<int> create(ItemInBranchModel item, {Transaction? txn}) async {
    final db = txn ?? await databaseService.database;
    final itemMap = item.toMap();
    itemMap.remove('id'); // Remove id for new insertion
    return await db.insert('items_in_branch', itemMap);
  }

  // Update existing item in branch
  Future<int> update(ItemInBranchModel item, {Transaction? txn}) async {
    final db = txn ?? await databaseService.database;
    return await db.update(
      'items_in_branch',
      item.toMap(),
      where: 'id = ? AND company = ? AND branch = ? ',
      whereArgs: [item.id, item.company, item.branch],
    );
  }

  // Delete item from branch
  Future<int> delete(int id, int companyId, {Transaction? txn}) async {
    final db = txn ?? await databaseService.database;
    return await db.delete(
      'items_in_branch',
      where: 'id = ? AND company = ? AND branch = ?',
      whereArgs: [id, companyId],
    );
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

    await db.delete(
      'items_in_branch',
      where: 'id IN ($placeholders) AND company = ?',
      whereArgs: whereArgs,
    );
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
             i.item_description, i.barcode, i.items_id,
             b.description as branch_description, b.reference_id as branch_reference
      FROM items_in_branch ib
      LEFT JOIN items_table i ON ib.item_number = i.id
      LEFT JOIN branch_table b ON ib.branch = b.id
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
             i.item_description, i.barcode, i.items_id,
             b.description as branch_description, b.reference_id as branch_reference
      FROM items_in_branch ib
      LEFT JOIN items_table i ON ib.item_number = i.id
      LEFT JOIN branch_table b ON ib.branch = b.id
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
             i.item_description, i.barcode, i.items_id,
             b.description as branch_description, b.reference_id as branch_reference
      FROM items_in_branch ib
      LEFT JOIN items_table i ON ib.item_number = i.id
      LEFT JOIN branch_table b ON ib.branch = b.id
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
             i.item_description, i.barcode, i.items_id,
             b.description as branch_description, b.reference_id as branch_reference
      FROM items_in_branch ib
      LEFT JOIN items_table i ON ib.item_number = i.id
      LEFT JOIN branch_table b ON ib.branch = b.id
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
  Future<int> updateMargin(
    int id,
    String marginType,
    double marginRate,
    int companyId,
  ) async {
    final db = await databaseService.database;
    return await db.update(
      'items_in_branch',
      {'margin_type': marginType, 'margin_rate': marginRate},
      where: 'id = ? AND company = ?',
      whereArgs: [id, companyId],
    );
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
        'ib.quantity_on_hand <= ib.reorder_level AND ib.company = ?';
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
  Future<List<ItemInBranchModel>> getOutOfStockItems(
    int companyId, {
    int? branchId,
  }) async {
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

  Future<double> validateItemInBranchForSalesOrder({
    required List<SalesOrderDetail> items,
    required ItemInBranchModel itemBranch,
    required Map<int, double> currentAvailableValidator,
    required SystemConstant systemConstants,
  }) async {
    final errors = <String>[];
    double itemValidation = 0;
    // 2. Validate items
    if (items.isEmpty) {
      errors.add('At least one item is required');
    }

    // 3. Validate each item
    for (final item in items) {
      itemValidation = await _validateSalesOrderItem(
        item,
        itemBranch,
        currentAvailableValidator,
        systemConstants,
      );
    }

    return itemValidation;
  }

  Future<double> _validateSalesOrderItem(
    SalesOrderDetail item,
    ItemInBranchModel itemBranch,
    Map<int, double> currentAvailableValidator,
    SystemConstant? systemConstants,
  ) async {
    final errors = <String>[];

    // Validate basic item information
    if (item.itemsTableId == null || item.itemsTableId == 0) {
      errors.add('Item is required');
      return 0;
    }

    if (item.quantity == null || item.quantity! <= 0) {
      errors.add('Quantity must be greater than 0');
      return 0;
    }

    if (item.unitPrice == null || item.unitPrice! < 0) {
      errors.add('Unit price cannot be negative');
    }

    // Validate stock availability
    if (item.itemInBranch != null) {
      return await _validateStockAvailability(
        item,
        itemBranch,
        currentAvailableValidator,
      );
    }
    return 0;
  }

  // Case 1: Simple stock update without location/lot management
  Future<void> handleSimpleStockUpdate(
    SalesOrderDetail soD,
    double factor,
    int companyId,
  ) async {
    final itemsInBranch = await findByItemAndBranch(
      soD.itemsTableId!,
      soD.itemBranch!.branch,
      companyId,
    );

    if (itemsInBranch != null) {
      final qtyToSubtract = factor * soD.quantity!;
      final newQty = (itemsInBranch.quantityAvailable ?? 0.0) - qtyToSubtract;

      // Update item branch quantity
      await updateQuantity(itemsInBranch.id, newQty, companyId);

      // Create stock card entry - equivalent to Java's stockCARDCreation
      await itemTransactionsRepository.stockCardCreation(
        ib: itemsInBranch,
        loc: null,
        lm: null,
        transactionType: 'I', // 'I' for Issue/Sales
        trNo: soD.orderHeader?.orderNumber,
        remark: 'Sales',
        qty: -soD.quantity!, // Negative quantity for sales
        por: null,
        soD: soD,
      );
    } else {
      throw Exception(
        'Item branch not found for item: ${soD.itemsTableId}, branch: ${soD.itemBranch!.branch}',
      );
    }
  }

  Future<double> _validateStockAvailability(
    SalesOrderDetail item,
    ItemInBranchModel itemBranch,
    Map<int, double> currentAvailableValidator,
  ) async {
    final errors = <String>[];
    final availableQuantities = <int, double>{};

    final availableQty = itemBranch.quantityAvailable ?? 0;
    final requestedQty = item.quantity ?? 0;

    availableQuantities[item.itemInBranch!] = availableQty;

    if (requestedQty > availableQty) {
      final beyondQty = requestedQty - availableQty;
      errors.add(
        'Quantity beyond available for ${item.item?.itemDescription}. '
        'Available: $availableQty, Requested: $requestedQty, '
        'Beyond: $beyondQty',
      );
    }

    // Check if quantity is below minimum stock level
    final minStockLevel = itemBranch.reorderPoint ?? 0;
    if (availableQty - requestedQty < minStockLevel) {
      errors.add(
        'Stock for ${item.item?.itemDescription} will be below minimum level after this sale',
      );
    }

    return availableQty;
  }

  // Helper method to update item branch quantity after location/lot updates
  Future<void> updateItemBranchQuantity(
    SalesOrderDetail soD,
    double factor,
    int companyId,
  ) async {
    final itemsInBranch = await findByItemAndBranch(
      soD.itemsTableId!,
      soD.itemBranch!.branch,
      companyId,
    );

    if (itemsInBranch != null) {
      // Recalculate total available quantity from locations/lots
      double totalAvailable = 0.0;

      if (systemConstantBloc.state.selected?.applyLocationMgmBoolean ?? false) {
        final locations = await itemLocationsRepository
            .getItemLocationsByBranchAndItem(
              branchId: soD.itemBranch!.branch,
              itemId: soD.itemsTableId!,
              companyId: companyId,
            );
        totalAvailable = locations.fold(
          0.0,
          (sum, location) => sum + (location.quantityOnHand ?? 0.0),
        );
      } else if (systemConstantBloc.state.selected?.applyLotMgmBoolean ??
          false) {
        final lots = await lotMasterRepository.getLotMastersByItemAndBranch(
          branch: soD.itemBranch!.branch,
          itemNumber: soD.itemsTableId!,
          companyId: companyId,
        );
        totalAvailable = lots.fold(
          0.0,
          (sum, lot) => sum + (lot.quantityAvailable ?? 0.0),
        );
      }

      // Convert back to primary UoM if needed
      final reverseFactor = await itemUomConversionsRepository
          .fromPrimaryToOther(
            soD.itemsTableId!,
            soD.unitOfMeasure ?? soD.itemBranch!.unitOfMeasure!,
            companyId,
          );

      final convertedQty = totalAvailable * reverseFactor;

      // Update item branch
      await updateQuantity(itemsInBranch.id, convertedQty, companyId);
    }
  }

  double _validateLotManagement(SalesOrderDetail item) {
    final errors = <String>[];

    if (item.lotNumber == null) {
      errors.add('Lot number is required for ${item.item?.itemDescription}');
    } else if (item.lot?.quantityAvailable != null &&
        item.quantity != null &&
        item.lot!.quantityAvailable! < item.quantity!) {
      errors.add(
        'Insufficient quantity in selected lot for ${item.item?.itemDescription}',
      );
    }

    // Check lot expiration
    if (item.lot?.dateExpiration != null) {
      final daysToExpiry = item.lot!.dateExpiration!
          .difference(DateTime.now())
          .inDays;
      if (daysToExpiry < 30) {
        errors.add(
          'Lot for ${item.item?.itemDescription} expires in $daysToExpiry days',
        );
      }
    }

    return 0;
  }

  List<String> _validateBusinessRules(
    List<SalesOrderDetail> items,
    ItemInBranchModel itemBranch,
  ) {
    final errors = <String>[];

    // Validate minimum order amount
    final totalQuantity = items.fold(
      0.0,
      (sum, item) => sum + (item.quantity ?? 0),
    );
    final minOrderQuantity = itemBranch.reorderPoint ?? 0;

    if (totalQuantity < minOrderQuantity) {
      errors.add(
        'Order amount ($totalQuantity) is below minimum order amount ($minOrderQuantity)',
      );
    }

    return errors;
  }

  // Restore stock quantities for voided sales
  Future<void> restoreStockQuantitiesForVoid({
    required List<SalesOrderDetail> voidedItems,
    required int companyId,
  }) async {
    for (final item in voidedItems) {
      if (item.itemInBranch != null && item.quantity != null) {
        await updateQuantity(item.itemInBranch!, item.quantity!, companyId);
      }
    }
  }
}
