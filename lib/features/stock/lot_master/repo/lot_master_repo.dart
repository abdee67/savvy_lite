// features/stock/lot_master/repositories/lot_master_repository.dart
import 'package:savvy_stock/core/repositories/base_repo.dart';
import 'package:savvy_stock/core/repositories/udc_repository.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/sales/sales_order/detail/model/sales_order_detail.dart';
import 'package:savvy_stock/features/stock/lot_master/models/lot_master_model.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_bloc.dart';
import 'package:savvy_stock/features/udc_detail/models/udc_details.dart';
import 'package:sqflite/sqflite.dart';

class LotMasterRepository extends BaseRepository {
  @override
  final LocalDatabaseService databaseService;
  final UdcRepository udcRepository;
  final SystemConstantBloc systemConstantBloc;

  LotMasterRepository({
    required this.databaseService,
    required this.udcRepository,
    required this.systemConstantBloc,
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

  //get active lots('A')
  Future<List<LotMaster>> getActiveLotMasters(int companyId) async {
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
        AND lm.status_code = 'A'
      ORDER BY it.item_description, lm.lot_number
    ''',
      [companyId],
    );

    return lots.map((p) => LotMaster.fromMap(p)).toList();
  }

  Future<String?> identifyLotStatus(LotMaster item) async {
    UdcDetails? lotStatus;

    if (item.branch != null && item.itemNumber != null) {
      // Get system constant and lot type
      final systemConstant = systemConstantBloc.state.selected;
      final lotTypeDetail = await udcRepository.getUdcDetailById(
        systemConstant?.lotType,
      );
      final lotType = lotTypeDetail?.detailCode;

      bool valid = false;
      DateTime? targetDate;

      // Determine which date to use based on lot type (EXACT Java logic)
      if (lotType == 'X' && item.dateExpiration != null) {
        valid = true;
        targetDate = item.dateExpiration;
      } else if (lotType == 'F' && item.dateEffective != null) {
        valid = true;
        targetDate = item.dateEffective;
      } else if (lotType == 'R' && item.dateReceived != null) {
        valid = true;
        targetDate = item.dateReceived;
      }

      if (valid && targetDate != null) {
        final currentDate = DateTime.now();

        // Calculate days difference (same as Java's ChronoUnit.DAYS.between)
        final difference = targetDate.difference(currentDate);
        final days = difference.inDays;

        // Apply the same business rules as Java
        if (lotType != 'R') {
          if (days <= 0) {
            // Expired or past effective date
            lotStatus = await udcRepository.getSingleUdcDetailsByCode(
              'LS',
              'E',
            );
          } else {
            // Active - preserve existing status unless it's expired
            if (item.lotStatus == null || item.statusCode == 'E') {
              lotStatus = await udcRepository.getSingleUdcDetailsByCode(
                'LS',
                'A',
              );
            } else {
              // Preserve existing status
              if (item.statusCode != null) {
                lotStatus = await udcRepository.getSingleUdcDetailsByCode(
                  'LS',
                  item.statusCode!,
                );
              }
            }
          }
        } else {
          // For 'R' (Received) type, always set to Active if null
          lotStatus = item.statusCode != null
              ? await udcRepository.getSingleUdcDetailsByCode('LS', 'A')
              : null;
        }
      }
    }

    return lotStatus?.detailCode;
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

  /// Saves lot master for sales order and cascades updates to location and branch
  /// Equivalent to Java's LotMasterController.saveRow
  Future<void> saveLotForSalesOrder({
    required LotMaster lot,
    required String transactionType,
    required int? trNo,
    required String? remark,
    required SalesOrderDetail? soD,
    required int companyId,
  }) async {
    if (lot.lotNumber == null) {
      throw Exception('Lot number should not be empty!');
    }

    // Validate lot dates based on lot type
    final systemConstant = systemConstantBloc.state.selected;
    final lotTypeDetail = await udcRepository.getUdcDetailById(
      systemConstant?.lotType,
    );
    final lotTypeCode = lotTypeDetail?.detailCode;

    bool hasValidDate = false;
    if (lotTypeCode == 'X' && lot.dateExpiration != null) {
      hasValidDate = true;
    } else if (lotTypeCode == 'F' && lot.dateEffective != null) {
      hasValidDate = true;
    } else if (lotTypeCode == 'R' && lot.dateReceived != null) {
      hasValidDate = true;
    }

    if (!hasValidDate) {
      throw Exception('The Effective Date & Expiration Date not Correct!');
    }

    // Identify lot status
    final lotStatus = await identifyLotStatus(lot);
    final updatedLot = lot.statusCode != null
        ? lot.copyWith(statusCode: lotStatus)
        : lot;

    double qtyChange = 0.0;

    if (lot.id == null) {
      // New lot
      final newId = await createLotMaster(updatedLot);
      qtyChange = lot.quantityAvailable ?? 0.0;

      if (systemConstantBloc.state.selected?.applyLotMgmBoolean == true) {
        await updatingItemLocationQuantityFromLot(
          lot: lot.copyWith(id: newId),
          transactionType: transactionType,
          trNo: trNo,
          remark: remark,
          qtyChange: qtyChange,
          soD: soD,
          companyId: companyId,
        );
      }
    } else {
      // Existing lot - calculate quantity change
      final existingLot = await getLotMasterById(lot.id!, companyId);
      final oldQty = existingLot?.quantityAvailable ?? 0.0;
      final newQty = lot.quantityAvailable ?? 0.0;

      qtyChange = newQty - oldQty;

      await updateLotMaster(updatedLot);

      if (systemConstantBloc.state.selected?.applyLotMgmBoolean == true &&
          qtyChange != 0.0) {
        await updatingItemLocationQuantityFromLot(
          lot: updatedLot,
          transactionType: transactionType,
          trNo: trNo,
          remark: remark,
          qtyChange: qtyChange,
          soD: soD,
          companyId: companyId,
        );
      }
    }
  }

  /// Updates item location and branch from lot changes
  /// Equivalent to Java's LotMasterController.updatingItemLocationQuantity
  Future<void> updatingItemLocationQuantityFromLot({
    required LotMaster lot,
    required String transactionType,
    required int? trNo,
    required String? remark,
    required double qtyChange,
    required SalesOrderDetail? soD,
    required int companyId,
  }) async {
    if (lot.itemNumber == null || lot.branch == null || lot.location == null) {
      throw Exception('Lot missing required fields: item, branch, or location');
    }

    final db = await databaseService.database;

    // 1. Sum all lots for this location
    final lotQtySum = await getTotalQuantityForLocation(
      companyId,
      lot.itemNumber!,
      lot.branch!,
      lot.location!,
    );

    // 2. Update item location quantity
    await db.update(
      'item_location',
      {'quantity_on_hand': lotQtySum},
      where: 'company = ? AND item_number = ? AND branch = ? AND location = ?',
      whereArgs: [companyId, lot.itemNumber, lot.branch, lot.location],
    );

    // 3. Create transaction for lot (this is done HERE, not in handleLotStockUpdate)
    // This will be called from item_transaction_repo, so we skip it here to avoid circular dependency
    // The transaction creation will be handled by the calling code

    // 4. Query all locations for this branch
    final locationResults = await db.rawQuery(
      '''
      SELECT SUM(quantity_on_hand) as total_qty 
      FROM item_location 
      WHERE company = ? AND item_number = ? AND branch = ?
    ''',
      [companyId, lot.itemNumber, lot.branch],
    );

    final branchQtySum =
        (locationResults.first['total_qty'] as num?)?.toDouble() ?? 0.0;

    // 5. Update items in branch
    await db.update(
      'items_in_branch',
      {'quantity_available': branchQtySum},
      where: 'company = ? AND item_number = ? AND branch = ?',
      whereArgs: [companyId, lot.itemNumber, lot.branch],
    );
  }
}
