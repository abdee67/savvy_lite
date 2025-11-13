// features/stock/lot_master/repositories/lot_master_repository.dart
import 'package:savvy_stock/core/repositories/base_repo.dart';
import 'package:savvy_stock/core/repositories/udc_repository.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/sales/sales_order_detail/model/sales_order_detail.dart';
import 'package:savvy_stock/features/sales/sales_order_header/bloc/sales_order_header_state.dart';
import 'package:savvy_stock/features/stock/item_in_branch/repo/item_in_branch_repo.dart';
import 'package:savvy_stock/features/stock/item_transactions/repo/item_transaction_repo.dart';
import 'package:savvy_stock/features/stock/lot_coloring/model/lot_coloring_model.dart';
import 'package:savvy_stock/features/stock/lot_coloring/repo/lot_expiration_repo.dart';
import 'package:savvy_stock/features/stock/lot_master/models/lot_master_model.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_bloc.dart';
import 'package:savvy_stock/features/system_constant/models/system_constant.dart';
import 'package:sqflite/sqflite.dart';

class LotMasterRepository extends BaseRepository {
  @override
  final LocalDatabaseService databaseService;
  final LotExpirationColorsRepository expirationColorsRepository;
  final StockItemInBranchRepository itemInBranchRepository;
  final ItemTransactionRepository itemTransactionRepository;
  final SystemConstantBloc systemContantBloc;
  final UdcRepository udcDetailsRepository;

  LotMasterRepository({
    required this.databaseService,
    required this.expirationColorsRepository,
    required this.itemInBranchRepository,
    required this.itemTransactionRepository,
    required this.systemContantBloc,
    required this.udcDetailsRepository,
  });

  // Get all lot masters for a company
  Future<List<LotMaster>> getLotMasters(
    int companyId, {
    Transaction? txn,
  }) async {
    final db = txn ?? await databaseService.database;
    final lots = await db.rawQuery(
      '''
      SELECT lm.*,
             it.items_id as item_id,
             it.item_description,
             it.unit_of_measure,
             b.description,
             loc.location_description,
             ud.detail_code as status_code,
             ud.description_1 as status_description
      FROM lot_master lm
      LEFT JOIN items_table it ON lm.item_number = it.id
      LEFT JOIN branch_table b ON lm.branch = b.id
      LEFT JOIN location_master loc ON lm.location = loc.id
      LEFT JOIN udc_details ud ON lm.lot_status = ud.id
      WHERE lm.company = ?
      ORDER BY it.item_description, lm.lot_number
    ''',
      [companyId],
    );

    return lots.map((p) => LotMaster.fromMap(p)).toList();
  }

  // Get lot master by ID
  Future<LotMaster?> getLotMasterById(
    int id,
    int companyId, {
    Transaction? txn,
  }) async {
    final db = txn ?? await databaseService.database;
    final lots = await db.rawQuery(
      '''
      SELECT lm.*,
             it.items_id as item_id,
             it.item_description,
             b.description as branch_name,
             loc.location_description,
             ud.detail_code as status_code,
             ud.description_1 as status_description
      FROM lot_master lm
      LEFT JOIN items_table it ON lm.item_number = it.id
      LEFT JOIN branch_table b ON lm.branch = b.id
      LEFT JOIN location_master loc ON lm.location = loc.id
      LEFT JOIN udc_details ud ON lm.lot_status = ud.id
      WHERE lm.id = ? AND lm.company = ?
    ''',
      [id, companyId],
    );

    return lots.isNotEmpty ? LotMaster.fromMap(lots.first) : null;
  }

  //find lot by item, location
  Future<LotMaster?> getLotMasterByItemAndLocation(
    int itemId,
    int locationId,
    int companyId, {
    Transaction? txn,
  }) async {
    final db = txn ?? await databaseService.database;
    final lots = await db.rawQuery(
      '''
      SELECT lm.*,
             it.items_id as item_id,
             it.item_description,
             b.description as branch_name,
             loc.location_description,
             ud.detail_code as status_code,
             ud.description_1 as status_description
      FROM lot_master lm
      LEFT JOIN items_table it ON lm.item_number = it.id
      LEFT JOIN branch_table b ON lm.branch = b.id
      LEFT JOIN location_master loc ON lm.location = loc.id
      LEFT JOIN udc_details ud ON lm.lot_status = ud.id
      WHERE lm.item_number = ? AND lm.location = ? AND lm.company = ?
    ''',
      [itemId, locationId, companyId],
    );

    return lots.isNotEmpty ? LotMaster.fromMap(lots.first) : null;
  }

  // Get filtered lot masters
  Future<List<LotMaster>> getFilteredLotMasters({
    required int companyId,
    int? itemId,
    DateTime? expStart,
    DateTime? expEnd,
    int? locationId,
    int? statusId,
  }) async {
    final db = await databaseService.database;

    var whereClause = 'WHERE lm.company = ?';
    final whereArgs = <dynamic>[companyId];

    if (itemId != null) {
      whereClause += ' AND lm.item_number = ?';
      whereArgs.add(itemId);
    }

    if (expStart != null && expEnd != null) {
      whereClause += ' AND lm.date_expiration BETWEEN ? AND ?';
      whereArgs.add(expStart.toIso8601String());
      whereArgs.add(expEnd.toIso8601String());
    }

    if (locationId != null) {
      whereClause += ' AND lm.location = ?';
      whereArgs.add(locationId);
    }

    if (statusId != null) {
      whereClause += ' AND lm.lot_status = ?';
      whereArgs.add(statusId);
    }

    final lots = await db.rawQuery('''
      SELECT lm.*,
             i.item_description as item_description,
             b.description as branch_name,
             loc.location_description,
             ls.detail_code as status_code,
             ls.description_1 as status_description
      FROM lot_master lm
      LEFT JOIN items_table i ON lm.item_number = i.id
      LEFT JOIN branch_table b ON lm.branch = b.id
      LEFT JOIN location_master loc ON lm.location = loc.id
      LEFT JOIN udc_details ls ON lm.lot_status = ls.id
      $whereClause
      ORDER BY i.item_description, lm.lot_number
    ''', whereArgs);

    return lots.map((p) => LotMaster.fromMap(p)).toList();
  }

  // Get lot masters by item and branch
  Future<List<LotMaster>> getLotMastersByItemAndBranch({
    required int companyId,
    required int itemNumber,
    int? location,
    required int branch,
  }) async {
    final db = await databaseService.database;
    final lots = await db.rawQuery(
      '''
      SELECT lm.*,
             it.item_description,
             b.description as branch_name,
             loc.location_description,
             ud.detail_code as status_code,
             ud.description_1 as status_description
      FROM lot_master lm
      LEFT JOIN items_table it ON lm.item_number = it.id
      LEFT JOIN branch_table b ON lm.branch = b.id
      LEFT JOIN location_master loc ON lm.location = loc.id
      LEFT JOIN udc_details ud ON lm.lot_status = ud.id
      WHERE lm.company = ? AND lm.item_number = ? AND lm.branch = ?
      ORDER BY lm.date_expiration, lm.lot_number
    ''',
      [companyId, itemNumber, branch],
    );

    return lots.map((p) => LotMaster.fromMap(p)).toList();
  }

  Future<List<LotMaster>> getLotMastersByItem({
    required int companyId,
    required int itemNumber,
  }) async {
    final db = await databaseService.database;
    final lots = await db.rawQuery(
      '''
      SELECT lm.*,
             it.item_description,
             ud.detail_code as status_code,
             ud.description_1 as status_description
      FROM lot_master lm
      LEFT JOIN items_table it ON lm.item_number = it.id
      LEFT JOIN udc_details ud ON lm.lot_status = ud.id
      WHERE lm.company = ? AND lm.item_number = ?
      ORDER BY lm.date_expiration, lm.lot_number
    ''',
      [companyId, itemNumber],
    );

    return lots.map((p) => LotMaster.fromMap(p)).toList();
  }

  // Create new lot master
  Future<int> createLotMaster(LotMaster lot, {Transaction? txn}) async {
    final db = txn ?? await databaseService.database;
    final lotMap = lot.toMap();
    lotMap.remove('id'); // Remove ID for new insertion
    return await db.insert('lot_master', lotMap);
  }

  // Update existing lot master
  Future<int> updateLotMaster(LotMaster lot, {Transaction? txn}) async {
    final db = txn ?? await databaseService.database;
    return await db.update(
      'lot_master',
      lot.toMap(),
      where: 'id = ? AND company = ?',
      whereArgs: [lot.id, lot.company],
    );
  }

  // Delete lot master
  Future<int> deleteLotMaster(int id, int companyId, {Transaction? txn}) async {
    final db = txn ?? await databaseService.database;
    return await db.delete(
      'lot_master',
      where: 'id = ? AND company = ?',
      whereArgs: [id, companyId],
    );
  }

  // Batch delete multiple lot masters
  Future<void> deleteMultipleLotMasters(
    List<int> ids,
    int companyId, {
    Transaction? txn,
  }) async {
    final db = txn ?? await databaseService.database;
    final batch = db.batch();

    for (final id in ids) {
      batch.delete(
        'lot_master',
        where: 'id = ? AND company = ?',
        whereArgs: [id, companyId],
      );
    }

    await batch.commit();
  }

  // Update item location quantity
  Future<void> updateItemLocationQuantity({
    required int companyId,
    required int itemNumber,
    required int branch,
    required int location,
    required double quantity,
    Transaction? txn,
  }) async {
    final db = txn ?? await databaseService.database;

    // Update item_location table
    await db.update(
      'item_location',
      {'quantity_on_hand': quantity},
      where: 'company = ? AND item_number = ? AND branch = ? AND location = ?',
      whereArgs: [companyId, itemNumber, branch, location],
    );

    // Update items_in_branch table
    final branchQuantities = await db.rawQuery(
      '''
      SELECT SUM(quantity_on_hand) as total_qty 
      FROM item_location 
      WHERE company = ? AND item_number = ? AND branch = ?
    ''',
      [companyId, itemNumber, branch],
    );

    final branchQty =
        (branchQuantities.first['total_qty'] as num?)?.toDouble() ?? 0.0;

    await db.update(
      'items_in_branch',
      {'quantity_available': branchQty},
      where: 'company = ? AND item_number = ? AND branch = ?',
      whereArgs: [companyId, itemNumber, branch],
    );
  }

  // Create item transaction
  Future<int> createItemTransaction(
    Map<String, dynamic> transaction, {
    Transaction? txn,
  }) async {
    final db = txn ?? await databaseService.database;
    return await db.insert('item_transactions', transaction);
  }

  // Get total quantity for item-branch-location
  Future<double> getTotalQuantityForLocation(
    int companyId,
    int itemNumber,
    int branch,
    int location, {
    Transaction? txn,
  }) async {
    final db = txn ?? await databaseService.database;
    final result = await db.rawQuery(
      '''
      SELECT SUM(quantity_available) as total_qty 
      FROM lot_master 
      WHERE company = ? AND item_number = ? AND branch = ? AND location = ?
    ''',
      [companyId, itemNumber, branch, location],
    );

    return (result.first['total_qty'] as num?)?.toDouble() ?? 0.0;
  }

  // Get item branch UoM
  Future<int?> getItemBranchUoM(
    int itemNumber,
    int branch,
    int companyId, {
    Transaction? txn,
  }) async {
    final db = txn ?? await databaseService.database;
    final result = await db.rawQuery(
      '''
      SELECT unit_of_measure FROM items_in_branch 
      WHERE company = ? AND item_number = ? AND branch = ?
    ''',
      [companyId, itemNumber, branch],
    );

    return result.isNotEmpty ? result.first['unit_of_measure'] as int? : null;
  }

  // Get UoM conversion factor
  Future<double> getUoMConversionFactor({
    required int companyId,
    required int itemNumber,
    required int fromUom,
    required int toUom,
  }) async {
    if (fromUom == toUom) return 1.0;

    final db = await databaseService.database;
    final result = await db.rawQuery(
      '''
      SELECT conversion_factor FROM item_uom_conversions 
      WHERE company = ? AND item_number = ? AND from_uom = ? AND to_uom = ?
    ''',
      [companyId, itemNumber, fromUom, toUom],
    );

    return result.isNotEmpty
        ? (result.first['conversion_factor'] as double?) ?? 1.0
        : 1.0;
  }

  // Get item branch unit price
  Future<double> getItemBranchUnitPrice(
    int itemNumber,
    int branch,
    int companyId,
  ) async {
    final db = await databaseService.database;
    final result = await db.rawQuery(
      '''
      SELECT unit_price FROM items_in_branch 
      WHERE company = ? AND item_number = ? AND branch = ?
    ''',
      [companyId, itemNumber, branch],
    );

    return result.isNotEmpty
        ? (result.first['unit_price'] as double?) ?? 0.0
        : 0.0;
  }

  // Search lot masters
  Future<List<LotMaster>> searchLotMasters({
    required int companyId,
    required String query,
  }) async {
    final db = await databaseService.database;
    final lots = await db.rawQuery(
      '''
      SELECT lm.*,
             it.item_description,
             b.description as branch_name,
             loc.location_description,
             ud.detail_code as status_code,
             ud.description_1 as status_description
      FROM lot_master lm
      LEFT JOIN items_table it ON lm.item_number = it.id
      LEFT JOIN branch_table b ON lm.branch = b.id
      LEFT JOIN location_master loc ON lm.location = loc.id
      LEFT JOIN udc_details ud ON lm.lot_status = ud.id
      WHERE lm.company = ? 
        AND (lm.lot_number LIKE ? OR lm.batch_number_supplier LIKE ? OR it.item_description LIKE ?)
      ORDER BY it.item_description, lm.lot_number
    ''',
      [companyId, '%$query%', '%$query%', '%$query%'],
    );

    return lots.map((p) => LotMaster.fromMap(p)).toList();
  }

  // Check for lot number duplication
  Future<bool> checkLotNumberDuplication({
    required int companyId,
    required int lotNumber,
    int? excludeId,
  }) async {
    final db = await databaseService.database;

    final whereClause = excludeId != null
        ? 'company = ? AND lot_number = ? AND id != ?'
        : 'company = ? AND lot_number = ?';

    final whereArgs = excludeId != null
        ? [companyId, lotNumber, excludeId]
        : [companyId, lotNumber];

    final existing = await db.query(
      'lot_master',
      where: whereClause,
      whereArgs: whereArgs,
    );

    return existing.isNotEmpty;
  }

  // Get lot masters expiring soon
  Future<List<LotMaster>> getExpiringLotMasters({
    required int companyId,
    required int daysThreshold,
  }) async {
    final db = await databaseService.database;
    final thresholdDate = DateTime.now().add(Duration(days: daysThreshold));

    final lots = await db.rawQuery(
      '''
      SELECT lm.*,
             it.item_description,
             b.description as branch_name,
             loc.location_description,
             ud.detail_code as status_code,
             ud.description_1 as status_description
      FROM lot_master lm
      LEFT JOIN items_table it ON lm.item_number = it.id
      LEFT JOIN branch_table b ON lm.branch = b.id
      LEFT JOIN location_master loc ON lm.location = loc.id
      LEFT JOIN udc_details ud ON lm.lot_status = ud.id
      WHERE lm.company = ? 
        AND lm.date_expiration IS NOT NULL
        AND lm.date_expiration BETWEEN ? AND ?
        AND lm.quantity_available > 0
      ORDER BY lm.date_expiration
    ''',
      [
        companyId,
        DateTime.now().toIso8601String(),
        thresholdDate.toIso8601String(),
      ],
    );

    return lots.map((p) => LotMaster.fromMap(p)).toList();
  }

  // Get lot quantity summary by item
  Future<Map<int, double>> getLotQuantitySummaryByItem(int companyId) async {
    final db = await databaseService.database;
    final result = await db.rawQuery(
      '''
      SELECT item_number, SUM(quantity_available) as total_qty
      FROM lot_master
      WHERE company = ?
      GROUP BY item_number
    ''',
      [companyId],
    );

    final summary = <int, double>{};
    for (final row in result) {
      summary[row['item_number'] as int] = (row['total_qty'] as num).toDouble();
    }
    return summary;
  }

  Future<void> restoreLotQuantity(
    int lotNumber,
    double quantity,
    int companyId,
  ) async {
    final db = await databaseService.database;
    await db.update(
      'lot_master',
      {'quantity_available': quantity},
      where: 'lot_number = ? AND company = ?',
      whereArgs: [lotNumber, companyId, quantity],
    );
    return;
  }

  // Get expired lot masters from specific branch and location
  Future<List<LotMaster>> getExpiredLotMastersFromBranchAndLocation({
    required int itemId,
    required int branchId,
    required int companyId,
    int? locationId,
  }) async {
    final db = await databaseService.database;

    var whereClause = '''
      WHERE lm.company = ? 
        AND lm.item_number = ? 
        AND lm.branch = ?
        AND lm.date_expiration IS NOT NULL
        AND lm.date_expiration < ?
        AND lm.quantity_available > 0
    ''';

    final whereArgs = <dynamic>[
      companyId,
      itemId,
      branchId,
      DateTime.now().toIso8601String(),
    ];

    if (locationId != null) {
      whereClause += ' AND lm.location = ?';
      whereArgs.add(locationId);
    }

    final lots = await db.rawQuery('''
      SELECT lm.*,
             it.item_description,
             b.description as branch_name,
             loc.location_description,
             ud.detail_code as status_code,
             ud.description_1 as status_description
      FROM lot_master lm
      LEFT JOIN items_table it ON lm.item_number = it.id
      LEFT JOIN branch_table b ON lm.branch = b.id
      LEFT JOIN location_master loc ON lm.location = loc.id
      LEFT JOIN udc_details ud ON lm.lot_status = ud.id
      $whereClause
      ORDER BY lm.date_expiration
    ''', whereArgs);

    return lots.map((p) => LotMaster.fromMap(p)).toList();
  }

  // Helper method for lot-level validation
  Future<({double availableQty, String message, bool isValid})>
  validateLotLevelAvailability(SalesOrderDetail soD, int companyId) async {
    try {
      // Get available lots for this item and branch
      List<LotMaster> availableLots = await getLotMastersByItemAndBranch(
        itemNumber: soD.itemsTableId!,
        branch: soD.itemBranch!.branch,
        companyId: companyId,
      );

      // Filter lots based on system configuration (like Java logic)
      final systemConstant = systemContantBloc.state.selected;
      final lotType = systemConstant?.lotType;
      final lotTypeCode = await udcDetailsRepository.getUdcDetailById(lotType);
      final lotTypeCodeId = lotTypeCode?.detailCode;

      // Apply filtering similar to Java implementation
      availableLots = availableLots
          .where((lot) => lot.statusCode != 'E') // Exclude expired
          .where(
            (lot) =>
                lot.quantityAvailable != null && lot.quantityAvailable! > 0,
          )
          .toList();

      // Apply additional filtering based on lot type and expiration colors
      availableLots = await _filterAndSortLotsForSales(
        availableLots,
        soD,
        companyId,
        lotTypeCodeId,
      );

      // Calculate total available quantity from valid lots
      double totalAvailable = availableLots.fold(
        0.0,
        (sum, lot) => sum + (lot.quantityAvailable ?? 0.0),
      );

      // Check if specific lot is selected (manual lot selection)
      if (!(systemConstant?.lotQtyAutoForSalesBoolean ?? true) &&
          soD.lotNumber != null) {
        final selectedLot = availableLots.firstWhere(
          (lot) => lot.id == soD.lot!.id,
          orElse: () => LotMaster(),
        );

        if (selectedLot.id == null) {
          return (
            availableQty: 0.0,
            message: 'Selected lot not available for sales',
            isValid: false,
          );
        }

        final lotQty = selectedLot.quantityAvailable ?? 0.0;
        return (
          availableQty: lotQty,
          message:
              'Lot-level: ${lotQty.toStringAsFixed(2)} available in selected lot',
          isValid: lotQty > 0,
        );
      }

      return (
        availableQty: totalAvailable,
        message:
            'Lot-level: ${totalAvailable.toStringAsFixed(2)} available across ${availableLots.length} lots',
        isValid: totalAvailable > 0,
      );
    } catch (e) {
      return (
        availableQty: 0.0,
        message: 'Error checking lot availability: $e',
        isValid: false,
      );
    }
  }

  Future<LotValidationResult> _autoSelectLot(
    List<LotMaster> validLots,
    double requestedQuantity,
    SystemConstant systemConstants,
  ) async {
    double remainingQuantity = requestedQuantity;
    final List<LotMaster> allocatedLots = [];

    for (final lot in validLots) {
      if (remainingQuantity <= 0) break;

      final quantityFromThisLot = lot.quantityAvailable! >= remainingQuantity
          ? remainingQuantity
          : lot.quantityAvailable!;

      allocatedLots.add(lot.copyWith(quantityAvailable: quantityFromThisLot));
      remainingQuantity -= quantityFromThisLot;
    }

    if (remainingQuantity > 0) {
      return LotValidationResult(
        isValid: false,
        availableQuantity: requestedQuantity - remainingQuantity,
        message: 'Insufficient quantity across all lots',
        availableLots: validLots,
      );
    }

    return LotValidationResult(
      isValid: true,
      recommendedLot: allocatedLots.first, // Use first allocated lot
      availableQuantity: requestedQuantity,
      message: 'Auto-lot allocation successful',
      availableLots: validLots,
    );
  }

  // Update lot quantities after sale
  Future<void> updateLotQuantitiesAfterSale({
    required List<SalesOrderDetail> soldItems,
    required int companyId,
  }) async {
    for (final item in soldItems) {
      if (item.lotNumber != null && item.quantity != null) {
        await updateLotMaster(item.lot!);
      }
    }
  }

  // Case 3: Both location and lot management
  Future<void> handleLotStockUpdate(
    SalesOrderDetail soD,
    double factor,
    int companyId,
  ) async {
    final systemConstant = systemContantBloc.state.selected;
    final lotType = systemConstant?.lotType;
    final lotTypeCode = await udcDetailsRepository.getUdcDetailById(lotType);
    final lotTypeCodeId = lotTypeCode?.detailCode;
    List<LotMaster> lotMasterList = [];

    // Check if manual lot selection is enabled and lot is provided
    if (!(systemConstant?.lotQtyAutoForSalesBoolean ?? true) &&
        soD.lotNumber != null) {
      lotMasterList.add(soD.lot!);
    } else {
      // Automatic lot selection - get all available lots
      lotMasterList = await getLotMastersByItemAndBranch(
        itemNumber: soD.itemsTableId!,
        branch: soD.itemBranch!.branch,
        companyId: companyId,
      );

      // Filter out expired lots and those with no quantity
      lotMasterList = lotMasterList
          .where(
            (lot) =>
                lot.statusCode != 'E' && // Exclude expired
                lot.quantityAvailable != null &&
                lot.quantityAvailable! > 0,
          )
          .toList();

      // Apply additional filtering and sorting based on lot type
      lotMasterList = await _filterAndSortLotsForSales(
        lotMasterList,
        soD,
        companyId,
        lotTypeCodeId,
      );
    }

    double remainingQty = factor * soD.quantity!;

    for (final lot in lotMasterList) {
      if (remainingQty <= 0) break;

      final currentLot = await getLotMasterById(lot.id!, companyId);
      final availableQty = currentLot?.quantityAvailable ?? 0.0;

      if (availableQty >= remainingQty) {
        // This lot has enough stock
        final newQty = availableQty - remainingQty;
        final updatedLot = currentLot?.copyWith(quantityAvailable: newQty);

        await updateLotMaster(updatedLot!);

        // Create transaction for this lot
        await itemTransactionRepository.stockCardCreation(
          ib: null,
          loc: null,
          lm: updatedLot,
          transactionType: 'I',
          trNo: soD.orderHeader?.orderNumber,
          remark: 'Sales',
          qty: -remainingQty,
          por: null,
          soD: soD,
        );

        remainingQty = 0;
      } else {
        // Take all available from this lot
        final updatedLot = currentLot?.copyWith(quantityAvailable: 0.0);
        await updateLotMaster(updatedLot!);

        // Create transaction for this lot
        await itemTransactionRepository.stockCardCreation(
          ib: null,
          loc: null,
          lm: updatedLot,
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
        'Insufficient stock across lots. Remaining: $remainingQty',
      );
    }

    // Update the main item branch quantity
    await itemInBranchRepository.updateItemBranchQuantity(
      soD,
      factor,
      companyId,
    );
  }

  // Helper method to filter and sort lots for sales
  Future<List<LotMaster>> _filterAndSortLotsForSales(
    List<LotMaster> lots,
    SalesOrderDetail soD,
    int companyId,
    String? lotTypeCodeId,
  ) async {
    final systemConstant = systemContantBloc.state.selected;
    final lotType = systemConstant?.lotType;
    final lotTypeCode = await udcDetailsRepository.getUdcDetailById(lotType);
    final lotTypeCodeId = lotTypeCode?.detailCode;
    List<LotMaster> filteredLots = [];

    for (final lot in lots) {
      bool isActiveForSales = await _isLotActiveForSales(
        soD,
        lot,
        lotTypeCodeId,
        companyId,
      );
      if (isActiveForSales) {
        filteredLots.add(lot);
      }
    }

    // Sort based on lot type
    if (lotTypeCodeId == null || lotTypeCodeId == 'X') {
      // Sort by expiration date
      filteredLots.sort(
        (a, b) => (a.dateExpiration ?? DateTime.now()).compareTo(
          b.dateExpiration ?? DateTime.now(),
        ),
      );
    } else if (lotTypeCodeId == 'F') {
      // Sort by effective date
      filteredLots.sort(
        (a, b) => (a.dateEffective ?? DateTime.now()).compareTo(
          b.dateEffective ?? DateTime.now(),
        ),
      );
    } else if (lotTypeCodeId == 'R') {
      // Sort by received date
      filteredLots.sort(
        (a, b) => (a.dateReceived ?? DateTime.now()).compareTo(
          b.dateReceived ?? DateTime.now(),
        ),
      );
    }

    return filteredLots;
  }

  // Helper method to check if lot is active for sales
  Future<bool> _isLotActiveForSales(
    SalesOrderDetail soD,
    LotMaster lot,
    String? lotType,
    int companyId,
  ) async {
    try {
      LotExpirationColor? expirationColor;

      if (lotType == null || lotType == 'X') {
        expirationColor = await expirationColorsRepository
            .getLotExpirationColorByDetails(
              branchId: soD.itemBranch!.branch,
              itemId: soD.itemsTableId!,
              companyId: companyId,
              daysDifference: int.parse(
                lot.dateExpiration!
                    .difference(DateTime.now())
                    .inDays
                    .toString(),
              ),
            );
      } else if (lotType == 'F') {
        expirationColor = await expirationColorsRepository
            .getLotExpirationColorByDetails(
              branchId: soD.itemBranch!.branch,
              itemId: soD.itemsTableId!,
              daysDifference: int.parse(
                lot.dateEffective!.difference(DateTime.now()).inDays.toString(),
              ),
              companyId: companyId,
            );
      } else if (lotType == 'R') {
        expirationColor = await expirationColorsRepository
            .getLotExpirationColorByDetails(
              branchId: soD.itemBranch!.branch,
              itemId: soD.itemsTableId!,
              daysDifference: int.parse(
                lot.dateReceived!.difference(DateTime.now()).inDays.toString(),
              ),
              companyId: companyId,
            );
      }

      // If no expiration color rule exists, or if it exists and allows sales
      return expirationColor == null ||
          expirationColor.activeForSalesFlag == 'Y';
    } catch (e) {
      // If there's an error checking, assume it's active for sales
      return true;
    }
  }

  // Restore lot quantities for voided sales
  Future<void> restoreLotQuantitiesForVoid({
    required List<SalesOrderDetail> voidedItems,
    required int companyId,
  }) async {
    for (final item in voidedItems) {
      if (item.lotNumber != null && item.quantity != null) {
        await restoreLotQuantity(item.lotNumber!, item.quantity!, companyId);
      }
    }
  }

  Future<double> calculateExpiredLotQuantity(
    SalesOrderDetail soD,
    int companyId,
  ) async {
    try {
      final lots = await getLotMastersByItemAndBranch(
        itemNumber: soD.itemsTableId!,
        branch: soD.itemBranch!.branch,
        companyId: companyId,
      );

      // Calculate total quantity in expired lots
      double totalAvailable = lots
          .where((lot) => lot.statusCode == 'E') // Expired lots
          .fold(0.0, (sum, lot) => sum + (lot.quantityAvailable ?? 0.0));
      return totalAvailable;
    } catch (e) {
      return 0.0;
    }
  }
}
