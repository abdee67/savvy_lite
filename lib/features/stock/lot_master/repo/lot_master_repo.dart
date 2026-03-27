// features/stock/lot_master/repositories/lot_master_repository.dart

import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:savvy_stock/core/repositories/base_repo.dart';
import 'package:savvy_stock/core/repositories/udc_repository.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/sales/sales_order/detail/model/sales_order_detail.dart';
import 'package:savvy_stock/features/stock/lot_master/models/expiration_report_filters.dart';
import 'package:savvy_stock/features/stock/lot_master/models/lot_availability_filters.dart';
import 'package:savvy_stock/features/stock/lot_master/models/lot_master_model.dart';
import 'package:savvy_stock/features/stock/lot_master/models/paginated_expiration_result.dart';
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

  // Get all lot masters for a company with pagination
  Future<List<LotMaster>> getLotMasters(
    int companyId, {
    int limit = 20,
    int offset = 0,
    Transaction? txn,
  }) async {
    final db = txn ?? await databaseService.database;
    final lots = await db.rawQuery(
      '''
      SELECT lm.*,
          it.items_id as item_id,
        it.item_description,
        it.unit_of_measure,
        uom.description_1 as unit_of_measure_description,
        uom.detail_code as unit_of_measure_detail_code,
        b.description as description,
        il.location as location,
        loc.id as location_id,
        loc.location_description,
        ls.detail_code as status_code,
        ls.description_1 as status_description
      
      FROM lot_master lm
      LEFT JOIN items_table it ON lm.item_number = it.id
      LEFT JOIN branch_table b ON lm.branch = b.id
      LEFT JOIN item_location il ON lm.location = il.id
      LEFT JOIN location_master loc ON il.location = loc.id
      LEFT JOIN udc_details ls ON lm.lot_status = ls.id
      LEFT JOIN udc_details uom ON it.unit_of_measure = uom.id
      WHERE lm.company = ?
      ORDER BY it.item_description, lm.lot_number
      LIMIT ? OFFSET ?
    ''',
      [companyId, limit, offset],
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
        it.unit_of_measure,
        uom.description_1 as unit_of_measure_description,
        uom.detail_code as unit_of_measure_detail_code,
        b.description as description,
        il.location as location,
        loc.id as location_id,
        loc.location_description,
        ls.detail_code as status_code,
        ls.description_1 as status_description
      
      FROM lot_master lm
      LEFT JOIN items_table it ON lm.item_number = it.id
      LEFT JOIN branch_table b ON lm.branch = b.id
      LEFT JOIN item_location il ON lm.location = il.id
      LEFT JOIN location_master loc ON il.location = loc.id
      LEFT JOIN udc_details ls ON lm.lot_status = ls.id
      LEFT JOIN udc_details uom ON it.unit_of_measure = uom.id
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
        it.unit_of_measure,
        uom.description_1 as unit_of_measure_description,
        uom.detail_code as unit_of_measure_detail_code,
        b.description as description,
        il.location as location,
        loc.id as location_id,
        loc.location_description,
        ls.detail_code as status_code,
        ls.description_1 as status_description
      
      FROM lot_master lm
      LEFT JOIN items_table it ON lm.item_number = it.id
      LEFT JOIN branch_table b ON lm.branch = b.id
      LEFT JOIN item_location il ON lm.location = il.id
      LEFT JOIN location_master loc ON il.location = loc.id
      LEFT JOIN udc_details ls ON lm.lot_status = ls.id
      LEFT JOIN udc_details uom ON it.unit_of_measure = uom.id
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
       it.items_id as item_id,
        it.item_description,
        it.unit_of_measure,
        uom.description_1 as unit_of_measure_description,
        uom.detail_code as unit_of_measure_detail_code,
        b.description as description,
        il.location as location,
        loc.id as location_id,
        loc.location_description,
        ls.detail_code as status_code,
        ls.description_1 as status_description
      
      FROM lot_master lm
      LEFT JOIN items_table it ON lm.item_number = it.id
      LEFT JOIN branch_table b ON lm.branch = b.id
      LEFT JOIN item_location il ON lm.location = il.id
      LEFT JOIN location_master loc ON il.location = loc.id
      LEFT JOIN udc_details ls ON lm.lot_status = ls.id
      LEFT JOIN udc_details uom ON it.unit_of_measure = uom.id
      $whereClause
      ORDER BY it.item_description, lm.lot_number
    ''', whereArgs);

    return lots.map((p) => LotMaster.fromMap(p)).toList();
  }

  // Get lot masters by item and branch
  Future<List<LotMaster>> getLotMastersByItemAndBranch({
    required int companyId,
    required int itemNumber,
    int? location,
    required int branch,
    Transaction? txn,
  }) async {
    final db = txn ?? await databaseService.database;
    final lots = await db.rawQuery(
      '''
      SELECT lm.*,
        it.items_id as item_id,
        it.item_description,
        it.unit_of_measure,
        uom.description_1 as unit_of_measure_description,
        uom.detail_code as unit_of_measure_detail_code,
        b.description as description,
        il.location as location,
        loc.id as location_id,
        loc.location_description,
        ls.detail_code as status_code,
        ls.description_1 as status_description
      
      FROM lot_master lm
      LEFT JOIN items_table it ON lm.item_number = it.id
      LEFT JOIN branch_table b ON lm.branch = b.id
      LEFT JOIN item_location il ON lm.location = il.id
      LEFT JOIN location_master loc ON il.location = loc.id
      LEFT JOIN udc_details ls ON lm.lot_status = ls.id
      LEFT JOIN udc_details uom ON it.unit_of_measure = uom.id
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
              it.items_id as item_id,
        it.item_description,
        it.unit_of_measure,
        uom.description_1 as unit_of_measure_description,
        uom.detail_code as unit_of_measure_detail_code,
        b.description as description,
        il.location as location,
        loc.id as location_id,
        loc.location_description,
        ls.detail_code as status_code,
        ls.description_1 as status_description
      
      FROM lot_master lm
      LEFT JOIN items_table it ON lm.item_number = it.id
      LEFT JOIN branch_table b ON lm.branch = b.id
      LEFT JOIN item_location il ON lm.location = il.id
      LEFT JOIN location_master loc ON il.location = loc.id
      LEFT JOIN udc_details ls ON lm.lot_status = ls.id
      LEFT JOIN udc_details uom ON it.unit_of_measure = uom.id
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
    final id = await db.insert('lot_master', withSyncKey(lotMap));
    lotMap['id'] = id;
    captureSync(
      tableName: 'lot_master',
      entityMap: lotMap,
      entityId: id.toString(),
      operation: 'INSERT',
      company: lot.company?.toString(),
    );
    return id;
  }

  // Update existing lot master
  Future<int> updateLotMaster(LotMaster lot, {Transaction? txn}) async {
    final db = txn ?? await databaseService.database;
    final result = await db.update(
      'lot_master',
      lot.toMap(),
      where: 'id = ? AND company = ?',
      whereArgs: [lot.id, lot.company],
    );
    captureSync(
      tableName: 'lot_master',
      entityMap: lot.toMap(),
      entityId: lot.id.toString(),
      operation: 'UPDATE',
      company: lot.company?.toString(),
    );
    return result;
  }

  // Update unit price for all lots matching item and branch
  Future<int> updateUnitPriceByItemAndBranch({
    required int itemNumber,
    required int branch,
    required double unitPrice,
    required int companyId,
  }) async {
    final db = await databaseService.database;
    final result = await db.update(
      'lot_master',
      {'unit_price': unitPrice},
      where: 'item_number = ? AND branch = ? AND company = ?',
      whereArgs: [itemNumber, branch, companyId],
    );
    captureSync(
      tableName: 'lot_master',
      entityMap: {
        'item_number': itemNumber,
        'branch': branch,
        'company': companyId,
        'unit_price': unitPrice,
      },
      entityId: result.toString(),
      operation: 'UPDATE',
      company: companyId.toString(),
    );
    return result;
  }

  // Update unit price for all lots of an item (all branches)
  Future<int> updateUnitPriceByItem({
    required int itemNumber,
    required double unitPrice,
    required int companyId,
  }) async {
    final db = await databaseService.database;
    final result = await db.update(
      'lot_master',
      {'unit_price': unitPrice},
      where: 'item_number = ? AND company = ?',
      whereArgs: [itemNumber, companyId],
    );
    captureSync(
      tableName: 'lot_master',
      entityMap: {
        'item_number': itemNumber,
        'company': companyId,
        'unit_price': unitPrice,
      },
      entityId: result.toString(),
      operation: 'UPDATE',
      company: companyId.toString(),
    );
    return result;
  }

  // Delete lot master
  Future<int> deleteLotMaster(int id, int companyId, {Transaction? txn}) async {
    final db = txn ?? await databaseService.database;
    final result = await db.delete(
      'lot_master',
      where: 'id = ? AND company = ?',
      whereArgs: [id, companyId],
    );
    captureSync(
      tableName: 'lot_master',
      entityMap: {'id': id, 'company': companyId},
      entityId: id.toString(),
      operation: 'DELETE',
      company: companyId.toString(),
    );
    return result;
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
      captureSync(
        tableName: 'lot_master',
        entityMap: {'id': id, 'company': companyId},
        entityId: id.toString(),
        operation: 'DELETE',
        company: companyId.toString(),
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
    captureSync(
      tableName: 'item_location',
      entityMap: {
        'company': companyId,
        'item_number': itemNumber,
        'branch': branch,
        'location': location,
        'quantity_on_hand': quantity,
      },
      entityId: location.toString(),
      operation: 'UPDATE',
      company: companyId.toString(),
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
    captureSync(
      tableName: 'items_in_branch',
      entityMap: {
        'company': companyId,
        'item_number': itemNumber,
        'branch': branch,
        'quantity_available': branchQty,
      },
      entityId: branch.toString(),
      operation: 'UPDATE',
      company: companyId.toString(),
    );
  }

  // Create item transaction
  Future<int> createItemTransaction(
    Map<String, dynamic> transaction, {
    Transaction? txn,
  }) async {
    final db = txn ?? await databaseService.database;
    final id = await db.insert('item_transactions', withSyncKey(transaction));
    captureSync(
      tableName: 'item_transactions',
      entityMap: transaction,
      entityId: id.toString(),
      operation: 'INSERT',
      company: transaction['company']?.toString(),
    );
    return id;
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
              it.items_id as item_id,
        it.item_description,
        it.unit_of_measure,
        uom.description_1 as unit_of_measure_description,
        uom.detail_code as unit_of_measure_detail_code,
        b.description as description,
        il.location as location,
        loc.location_description,
        loc.id as location_id,
        ls.detail_code as status_code,
        ls.description_1 as status_description
      
      FROM lot_master lm
      LEFT JOIN items_table it ON lm.item_number = it.id
      LEFT JOIN branch_table b ON lm.branch = b.id
      LEFT JOIN item_location il ON lm.location = il.id
      LEFT JOIN location_master loc ON il.location = loc.id
      LEFT JOIN udc_details ls ON lm.lot_status = ls.id
      LEFT JOIN udc_details uom ON it.unit_of_measure = uom.id
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
              it.items_id as item_id,
        it.item_description,
        it.unit_of_measure,
        uom.description_1 as unit_of_measure_description,
        uom.detail_code as unit_of_measure_detail_code,
        b.description as description,
        il.
        loc.location_description,
        ls.detail_code as status_code,
        ls.description_1 as status_description
      
      FROM lot_master lm
      LEFT JOIN items_table it ON lm.item_number = it.id
      LEFT JOIN branch_table b ON lm.branch = b.id
      LEFT JOIN location_master loc ON lm.location = loc.id
      LEFT JOIN udc_details ls ON lm.lot_status = ls.id
      LEFT JOIN udc_details uom ON it.unit_of_measure = uom.id
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
              it.items_id as item_id,
        it.item_description,
        it.unit_of_measure,
        uom.description_1 as unit_of_measure_description,
        uom.detail_code as unit_of_measure_detail_code,
        b.description as description,
        loc.location_description,
        ls.detail_code as status_code,
        ls.description_1 as status_description
      
      FROM lot_master lm
      LEFT JOIN items_table it ON lm.item_number = it.id
      LEFT JOIN branch_table b ON lm.branch = b.id
      LEFT JOIN location_master loc ON lm.location = loc.id
      LEFT JOIN udc_details ls ON lm.lot_status = ls.id
      LEFT JOIN udc_details uom ON it.unit_of_measure = uom.id
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
              'E',
              'LS',
            );
          } else {
            // Active - preserve existing status unless it's expired
            if (item.lotStatus == null || item.statusCode == 'E') {
              lotStatus = await udcRepository.getSingleUdcDetailsByCode(
                'A',
                'LS',
              );
            } else {
              // Preserve existing status
              if (item.statusCode != null) {
                lotStatus = await udcRepository.getSingleUdcDetailsByCode(
                  item.statusCode!,
                  'LS',
                );
              }
            }
          }
        } else {
          // For 'R' (Received) type, always set to Active if null
          lotStatus = item.statusCode != null
              ? await udcRepository.getSingleUdcDetailsByCode('A', 'LS')
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
    captureSync(
      tableName: 'lot_master',
      entityMap: {
        'lot_number': lotNumber,
        'company': companyId,
        'quantity_available': quantity,
      },
      entityId: lotNumber.toString(),
      operation: 'UPDATE',
      company: companyId.toString(),
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
           it.items_id as item_id,
        it.item_description,
        it.unit_of_measure,
        uom.description_1 as unit_of_measure_description,
        uom.detail_code as unit_of_measure_detail_code,
        b.description as description,
        loc.location_description,
        ls.detail_code as status_code,
        ls.description_1 as status_description
      
      FROM lot_master lm
      LEFT JOIN items_table it ON lm.item_number = it.id
      LEFT JOIN branch_table b ON lm.branch = b.id
      LEFT JOIN location_master loc ON lm.location = loc.id
      LEFT JOIN udc_details ls ON lm.lot_status = ls.id
      LEFT JOIN udc_details uom ON it.unit_of_measure = uom.id
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
    captureSync(
      tableName: 'item_location',
      entityMap: {
        'company': companyId,
        'item_number': lot.itemNumber,
        'branch': lot.branch,
        'location': lot.location,
        'quantity_on_hand': lotQtySum,
      },
      entityId: lot.id.toString(),
      operation: 'UPDATE',
      company: companyId.toString(),
    );

    // 3. Create transaction for lot (this is done HERE, not in handleLotStockUpdate)
    // This will be called from item_transaction_repo, so we skip it here to avoid circular dependency
    // The transaction creation will be handled by the calling code

    // HOWEVER, if we are calling this from _autoCreateLotForPurchaseOrder, we need to manually trigger the transaction if needed
    // But since _autoCreateLotForPurchaseOrder calls _updateItemLocationQuantity which then calls this...
    // Let's stick to the separation of concerns. The caller handles the transaction.

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
    captureSync(
      tableName: 'items_in_branch',
      entityMap: {
        'company': companyId,
        'item_number': lot.itemNumber,
        'branch': lot.branch,
        'quantity_available': branchQtySum,
      },
      entityId: lot.id.toString(),
      operation: 'UPDATE',
      company: companyId.toString(),
    );
  }

  //get lot maser by expiration date
  Future<List<LotMaster>> getLotMastersByExpirationDate({
    required int companyId,
    required DateTime dateExpiration,
  }) async {
    final db = await databaseService.database;
    final lots = await db.rawQuery(
      '''
      SELECT lm.*,
         it.items_id as item_id,
        it.item_description,
        it.unit_of_measure,
        uom.description_1 as unit_of_measure_description,
        uom.detail_code as unit_of_measure_detail_code,
        b.description as description,
        loc.location_description,
        ls.detail_code as status_code,
        ls.description_1 as status_description
      
      FROM lot_master lm
      LEFT JOIN items_table it ON lm.item_number = it.id
      LEFT JOIN branch_table b ON lm.branch = b.id
      LEFT JOIN location_master loc ON lm.location = loc.id
      LEFT JOIN udc_details ls ON lm.lot_status = ls.id
      LEFT JOIN udc_details uom ON it.unit_of_measure = uom.id
      WHERE lm.date_expiration = ? AND lm.company = ?
      ORDER BY it.item_description, lm.lot_number
    ''',
      [dateExpiration.toIso8601String(), companyId],
    );

    return lots.map((p) => LotMaster.fromMap(p)).toList();
  }

  //get lot maser by effective date
  Future<List<LotMaster>> getLotMastersByEffectiveDate({
    required int companyId,
    required DateTime dateEffective,
  }) async {
    final db = await databaseService.database;
    final lots = await db.rawQuery(
      '''
      SELECT lm.*,
         it.items_id as item_id,
        it.item_description,
        it.unit_of_measure,
        uom.description_1 as unit_of_measure_description,
        uom.detail_code as unit_of_measure_detail_code,
        b.description as description,
        loc.location_description,
        ls.detail_code as status_code,
        ls.description_1 as status_description
      
      FROM lot_master lm
      LEFT JOIN items_table it ON lm.item_number = it.id
      LEFT JOIN branch_table b ON lm.branch = b.id
      LEFT JOIN location_master loc ON lm.location = loc.id
      LEFT JOIN udc_details ls ON lm.lot_status = ls.id
      LEFT JOIN udc_details uom ON it.unit_of_measure = uom.id
      WHERE lm.date_effective = ? AND lm.company = ?
      ORDER BY it.item_description, lm.lot_number
    ''',
      [dateEffective.toIso8601String(), companyId],
    );

    return lots.map((p) => LotMaster.fromMap(p)).toList();
  }

  //get lot maser by received date
  Future<List<LotMaster>> getLotMastersByReceivedDate({
    required int companyId,
    required DateTime dateReceived,
  }) async {
    final db = await databaseService.database;
    final lots = await db.rawQuery(
      '''
      SELECT lm.*,
              it.items_id as item_id,
        it.item_description,
        it.unit_of_measure,
        uom.description_1 as unit_of_measure_description,
        uom.detail_code as unit_of_measure_detail_code,
        b.description as description,
        loc.location_description,
        ls.detail_code as status_code,
        ls.description_1 as status_description
      
      FROM lot_master lm
      LEFT JOIN items_table it ON lm.item_number = it.id
      LEFT JOIN branch_table b ON lm.branch = b.id
      LEFT JOIN location_master loc ON lm.location = loc.id
      LEFT JOIN udc_details ls ON lm.lot_status = ls.id
      LEFT JOIN udc_details uom ON it.unit_of_measure = uom.id
      WHERE lm.date_received = ? AND lm.company = ?
      ORDER BY it.item_description, lm.lot_number
    ''',
      [dateReceived.toIso8601String(), companyId],
    );

    return lots.map((p) => LotMaster.fromMap(p)).toList();
  }

  //get next lot number
  Future<int?> getNextLotNumber({required int companyId}) async {
    final db = await databaseService.database;
    final result = await db.rawQuery(
      'SELECT MAX(lot_number) as next_lot_number FROM lot_master WHERE company = ?',
      [companyId],
    );
    final nextLotNumber = result.first['next_lot_number'] as int?;
    return nextLotNumber != null ? nextLotNumber + 1 : 1;
  }

  Future<PaginatedExpirationResult> getExpirationReport({
    required int companyId,
    required ExpirationReportFilters filters,
    required int page,
    required int pageSize,
  }) async {
    final db = await databaseService.database;

    // Build WHERE clause dynamically
    final whereConditions = <String>['lm.company = ?'];
    final whereArgs = <dynamic>[companyId];

    // Base condition: expired or expiring today
    final today = DateTime.now();
    whereConditions.add(
      '(lm.date_expiration IS NOT NULL AND lm.date_expiration <= ?)',
    );
    whereArgs.add(today.toIso8601String());

    // Apply filters
    if (filters.itemId != null) {
      whereConditions.add('lm.item_number = ?');
      whereArgs.add(filters.itemId);
    }

    if (filters.branchId != null) {
      whereConditions.add('lm.branch = ?');
      whereArgs.add(filters.branchId);
    }

    if (filters.locationId != null) {
      whereConditions.add('lm.location = ?');
      whereArgs.add(filters.locationId);
    }

    if (!filters.showZeroAvailability) {
      whereConditions.add('lm.quantity_available > 0');
    }

    if (filters.dateFrom != null) {
      whereConditions.add('lm.date_expiration >= ?');
      whereArgs.add(filters.dateFrom!.toIso8601String());
    }

    if (filters.dateTo != null) {
      whereConditions.add('lm.date_expiration <= ?');
      whereArgs.add(filters.dateTo!.toIso8601String());
    }

    final whereClause = whereConditions.join(' AND ');

    // Count query
    final countResult = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM lot_master lm
      WHERE $whereClause
    ''', whereArgs);

    final totalCount = (countResult.first['count'] as int?) ?? 0;

    // Data query with joins
    final dataQuery =
        '''
      SELECT 
        lm.*,
        it.items_id as item_id,
        it.item_description,
        it.unit_of_measure,
        uom.description_1 as unit_of_measure_description,
        uom.detail_code as unit_of_measure_detail_code,
        b.description as description,
        loc.location_description,
        ls.detail_code as status_code,
        ls.description_1 as status_description,
        COALESCE(
          (SELECT unit_of_measure 
           FROM items_in_branch iib 
           WHERE iib.company = lm.company 
             AND iib.item_number = lm.item_number 
             AND iib.branch = lm.branch
           LIMIT 1),
          it.unit_of_measure
        ) as branch_uom,
        COALESCE(
          (SELECT amount_unit_cost 
           FROM item_cost ict 
           WHERE ict.company = lm.company 
             AND ict.item_number = lm.item_number
           LIMIT 1),
          0.0
        ) as unit_cost
      FROM lot_master lm
      LEFT JOIN items_table it ON lm.item_number = it.id
      LEFT JOIN branch_table b ON lm.branch = b.id
      LEFT JOIN location_master loc ON lm.location = loc.id
      LEFT JOIN udc_details ls ON lm.lot_status = ls.id
      LEFT JOIN udc_details uom ON it.unit_of_measure = uom.id
      WHERE $whereClause
      ORDER BY lm.date_expiration ASC
      LIMIT ? OFFSET ?
    ''';

    final paginatedArgs = List<dynamic>.from(whereArgs)
      ..add(pageSize)
      ..add((page - 1) * pageSize);

    final lotsData = await db.rawQuery(dataQuery, paginatedArgs);
    final lots = lotsData.map((p) => LotMaster.fromMap(p)).toList();

    // Calculate total cost
    double totalCost = 0.0;
    for (final lot in lots) {
      final quantity = lot.quantityAvailable ?? 0.0;
      final unitCost =
          (lotsData.firstWhere(
                    (row) => row['id'] == lot.id,
                    orElse: () => {'unit_cost': 0.0},
                  )['unit_cost']
                  as num?)
              ?.toDouble() ??
          0.0;

      // Calculate UoM conversion if needed
      final branchUom =
          (lotsData.firstWhere(
                (row) => row['id'] == lot.id,
                orElse: () => {'branch_uom': null},
              )['branch_uom']
              as int?);

      double conversionFactor = 1.0;
      if (branchUom != null && lot.itemRef?.unitOfMeasure != null) {
        conversionFactor = await getUoMConversionFactor(
          companyId: companyId,
          itemNumber: lot.itemNumber!,
          fromUom: branchUom,
          toUom: int.parse(lot.itemRef!.unitOfMeasure!),
        );
      }

      totalCost += quantity * conversionFactor * unitCost;
    }

    return PaginatedExpirationResult(
      lots: lots,
      totalCount: totalCount,
      totalCost: totalCost,
    );
  }

  Future<PaginatedExpirationResult> getUpComingExpirationReport({
    required int companyId,
    required ExpirationReportFilters filters,
    required int daysThreshold,
    required int page,
    required int pageSize,
  }) async {
    final db = await databaseService.database;

    // Build WHERE clause dynamically
    final whereConditions = <String>['lm.company = ?'];
    final whereArgs = <dynamic>[companyId];

    // Base condition: expired or expiring today
    final today = DateTime.now();
    final thresholdDate = today.add(Duration(days: daysThreshold));
    whereConditions.add('''(lm.date_expiration IS NOT NULL
       AND lm.date_expiration >= ?
       AND lm.date_expiration <= ?
       )''');
    whereArgs.add(today.toIso8601String());
    whereArgs.add(thresholdDate.toIso8601String());

    // Apply filters
    if (filters.itemId != null) {
      whereConditions.add('lm.item_number = ?');
      whereArgs.add(filters.itemId);
    }

    if (filters.branchId != null) {
      whereConditions.add('lm.branch = ?');
      whereArgs.add(filters.branchId);
    }

    if (filters.locationId != null) {
      whereConditions.add('lm.location = ?');
      whereArgs.add(filters.locationId);
    }

    if (!filters.showZeroAvailability) {
      whereConditions.add('lm.quantity_available > 0');
    }
    if (filters.batchNumber != null && filters.batchNumber!.isNotEmpty) {
      whereConditions.add('lm.batch_number_supplier LIKE ?');
      whereArgs.add('%${filters.batchNumber}%');
    }

    final whereClause = whereConditions.join(' AND ');

    // Count query
    final countResult = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM lot_master lm
      WHERE $whereClause
    ''', whereArgs);

    final totalCount = (countResult.first['count'] as int?) ?? 0;

    // Data query with joins
    final dataQuery =
        '''
      SELECT 
        lm.*,
        it.items_id as item_id,
        it.item_description,
        it.unit_of_measure,
        uom.description_1 as unit_of_measure_description,
        uom.detail_code as unit_of_measure_detail_code,
        b.description as description,
        loc.location_description,
        ls.detail_code as status_code,
        ls.description_1 as status_description,
        COALESCE(
          (SELECT unit_of_measure 
           FROM items_in_branch iib 
           WHERE iib.company = lm.company 
             AND iib.item_number = lm.item_number 
             AND iib.branch = lm.branch
           LIMIT 1),
          it.unit_of_measure
        ) as branch_uom,
        COALESCE(
          (SELECT amount_unit_cost 
           FROM item_cost ict 
           WHERE ict.company = lm.company 
             AND ict.item_number = lm.item_number
           LIMIT 1),
          0.0
        ) as unit_cost
      FROM lot_master lm
      LEFT JOIN items_table it ON lm.item_number = it.id
      LEFT JOIN branch_table b ON lm.branch = b.id
      LEFT JOIN location_master loc ON lm.location = loc.id
      LEFT JOIN udc_details ls ON lm.lot_status = ls.id
      LEFT JOIN udc_details uom ON it.unit_of_measure = uom.id
      WHERE $whereClause
      ORDER BY lm.date_expiration ASC
      LIMIT ? OFFSET ?
    ''';

    final paginatedArgs = List<dynamic>.from(whereArgs)
      ..add(pageSize)
      ..add((page - 1) * pageSize);

    final lotsData = await db.rawQuery(dataQuery, paginatedArgs);
    final lots = lotsData.map((p) => LotMaster.fromMap(p)).toList();

    // Calculate total cost
    double totalCost = 0.0;
    for (final lot in lots) {
      final quantity = lot.quantityAvailable ?? 0.0;
      final unitCost =
          (lotsData.firstWhere(
                    (row) => row['id'] == lot.id,
                    orElse: () => {'unit_cost': 0.0},
                  )['unit_cost']
                  as num?)
              ?.toDouble() ??
          0.0;

      // Calculate UoM conversion if needed
      final branchUom =
          (lotsData.firstWhere(
                (row) => row['id'] == lot.id,
                orElse: () => {'branch_uom': null},
              )['branch_uom']
              as int?);

      double conversionFactor = 1.0;
      if (branchUom != null && lot.itemRef?.unitOfMeasure != null) {
        conversionFactor = await getUoMConversionFactor(
          companyId: companyId,
          itemNumber: lot.itemNumber!,
          fromUom: branchUom,
          toUom: int.parse(lot.itemRef!.unitOfMeasure!),
        );
      }

      totalCost += quantity * conversionFactor * unitCost;
    }

    return PaginatedExpirationResult(
      lots: lots,
      totalCount: totalCount,
      totalCost: totalCost,
    );
  }

  Future<double> calculateLotTotalCost(LotMaster lot) async {
    try {
      final unitCost = await databaseService.database;
      final unitCostResult = await unitCost.rawQuery(
        '''
        SELECT amount_unit_cost 
        FROM item_cost 
        WHERE company = ? AND item_number = ?
        LIMIT 1
      ''',
        [lot.company, lot.itemNumber],
      );

      final cost =
          (unitCostResult.first['amount_unit_cost'] as num?)?.toDouble() ?? 0.0;
      final quantity = lot.quantityAvailable ?? 0.0;

      // Apply UoM conversion if needed
      final branchUom = await getItemBranchUoM(
        lot.itemNumber!,
        lot.branch!,
        lot.company!,
      );

      double conversionFactor = 1.0;
      if (branchUom != null && lot.itemRef?.unitOfMeasure != null) {
        conversionFactor = await getUoMConversionFactor(
          companyId: lot.company!,
          itemNumber: lot.itemNumber!,
          fromUom: branchUom,
          toUom: int.parse(lot.itemRef!.unitOfMeasure!),
        );
      }

      return quantity * conversionFactor * cost;
    } catch (e) {
      return 0.0;
    }
  }

  int calculateDaysUntilExpiry(DateTime? expirationDate) {
    if (expirationDate == null) return 0;
    final now = DateTime.now();
    final difference = expirationDate.difference(now).inDays;
    return difference > 0 ? difference : 0; // Only positive values
  }

  Future<({List<LotMaster> items, int count})> getLotAvailabilityPaginated({
    required int companyId,
    required LotAvailabilityFilters filters,
    required int page,
    required int pageSize,
    String? lotTypeCode,
  }) async {
    final db = await databaseService.database;

    var whereConditions = <String>['lm.company = ?'];
    var whereArgs = <dynamic>[companyId];

    if (filters.itemNumber != null) {
      whereConditions.add('lm.item_number = ?');
      whereArgs.add(filters.itemNumber);
    }
    if (filters.branch != null) {
      whereConditions.add('lm.branch = ?');
      whereArgs.add(filters.branch);
    }
    if (filters.batchNumberSupplier != null &&
        filters.batchNumberSupplier!.isNotEmpty) {
      whereConditions.add('lm.batch_number_supplier LIKE ?');
      whereArgs.add('%${filters.batchNumberSupplier}%');
    }
    if (filters.locationId != null) {
      whereConditions.add('lm.location = ?');
      whereArgs.add(filters.locationId);
    }

    if (filters.noAvailability) {
      whereConditions.add('lm.quantity_available = 0.0');
    }

    if (filters.selectFilterDates != null &&
        filters.selectFilterDates != 'ALL') {
      String dateColumn = 'lm.date_expiration';
      if (lotTypeCode == 'F') {
        dateColumn = 'lm.date_effective';
      } else if (lotTypeCode == 'R') {
        dateColumn = 'lm.date_received';
      }

      final filterType = filters.selectFilterDates!.toUpperCase();
      if (filterType == 'RANGE' &&
          filters.startDateForFilter != null &&
          filters.endDateForFilter != null) {
        whereConditions.add('$dateColumn BETWEEN ? AND ?');
        whereArgs.add(filters.startDateForFilter!.toIso8601String());
        whereArgs.add(filters.endDateForFilter!.toIso8601String());
      } else if (filterType == 'YEARS' && filters.yearsPut != null) {
        final startOfYear = DateTime(filters.yearsPut!, 1, 1);
        final endOfYear = DateTime(filters.yearsPut!, 12, 31, 23, 59, 59);
        whereConditions.add('$dateColumn BETWEEN ? AND ?');
        whereArgs.add(startOfYear.toIso8601String());
        whereArgs.add(endOfYear.toIso8601String());
      } else if (filterType == 'DAYS' &&
          filters.minDays != null &&
          filters.maxDays != null) {
        final today = DateTime.now();
        final minDateOrig = today.add(Duration(days: filters.minDays!));
        final minDate = DateTime(
          minDateOrig.year,
          minDateOrig.month,
          minDateOrig.day,
        ); // Start of day
        final maxDateOrig = today.add(Duration(days: filters.maxDays!));
        final maxDate = DateTime(
          maxDateOrig.year,
          maxDateOrig.month,
          maxDateOrig.day,
          23,
          59,
          59,
        ); // End of day
        whereConditions.add('$dateColumn BETWEEN ? AND ?');
        whereArgs.add(minDate.toIso8601String());
        whereArgs.add(maxDate.toIso8601String());
      }

      if (filterType == 'EXPIRED') {
        final today = DateTime.now();
        var todayEnd = DateTime(today.year, today.month, today.day, 23, 59, 59);
        whereConditions.add('$dateColumn <= ?');
        whereArgs.add(todayEnd.toIso8601String());
      }
    }

    final whereClause = whereConditions.join(' AND ');

    if (kDebugMode) {
      developer.log('getLotAvailabilityPaginated WHERE: $whereClause');
      developer.log('getLotAvailabilityPaginated ARGS: $whereArgs');
    }

    // 1. COUNT
    final countResult = await db.rawQuery('''
      SELECT COUNT(lm.id) as count
      FROM lot_master lm
      WHERE $whereClause
    ''', whereArgs);
    int totalCount = (countResult.first['count'] as int?) ?? 0;

    // 2. SELECT
    final dataQuery =
        '''
      SELECT lm.*,
        it.items_id as item_id,
        it.item_description,
        it.unit_of_measure,
        uom.description_1 as unit_of_measure_description,
        uom.detail_code as unit_of_measure_detail_code,
        b.description as description,
        loc.id as location_id,
        loc.location_description as location_description,
        ls.detail_code as status_code,
        ls.description_1 as status_description
      FROM lot_master lm
      LEFT JOIN items_table it ON lm.item_number = it.id
      LEFT JOIN branch_table b ON lm.branch = b.id
      LEFT JOIN item_location il ON lm.location = il.id
      LEFT JOIN location_master loc ON COALESCE(il.location, lm.location) = loc.id
      LEFT JOIN udc_details ls ON lm.lot_status = ls.id
      LEFT JOIN udc_details uom ON it.unit_of_measure = uom.id
      WHERE $whereClause
      ORDER BY lm.id DESC
      LIMIT ? OFFSET ?
    ''';

    final paginatedArgs = List<dynamic>.from(whereArgs)
      ..add(pageSize)
      ..add((page - 1) * pageSize);

    final lotsData = await db.rawQuery(dataQuery, paginatedArgs);
    List<LotMaster> lots = lotsData.map((p) => LotMaster.fromMap(p)).toList();

    // The Java post-query filter for NO AVAILABILITY
    if (filters.noAvailability) {
      final noAvailLots = lots
          .where((lot) => (lot.quantityAvailable ?? 0.0) == 0.0)
          .toList();
      if (noAvailLots.isNotEmpty) {
        lots = noAvailLots;
      }
    }

    return (items: lots, count: totalCount);
  }
}
