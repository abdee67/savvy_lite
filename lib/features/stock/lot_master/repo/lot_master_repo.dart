// features/stock/lot_master/repositories/lot_master_repository.dart
import 'package:savvy_stock/core/repositories/base_repo.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/stock/lot_master/models/lot_master_model.dart';
import 'package:sqflite/sqflite.dart';

class LotMasterRepository extends BaseRepository {
  @override
  final LocalDatabaseService databaseService;

  LotMasterRepository({required this.databaseService});

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
}
