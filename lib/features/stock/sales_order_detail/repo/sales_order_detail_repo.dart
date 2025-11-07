// repository/sales_order_details_repository.dart
import 'dart:async';

import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/stock/item_in_branch/models/item_in_branch_model.dart';
import 'package:savvy_stock/features/stock/lot_master/models/lot_master_model.dart';
import 'package:savvy_stock/features/stock/sales_order_detail/model/sales_order_detail.dart';

class SalesOrderDetailRepository {
  final LocalDatabaseService databaseService;

  SalesOrderDetailRepository({required this.databaseService});

  // Create
  Future<int> create(SalesOrderDetail details) async {
    final db = await databaseService.database;
    return await db.insert('sales_order_details', details.toMap());
  }

  // Update
  Future<int> update(SalesOrderDetail details) async {
    final db = await databaseService.database;
    return await db.update(
      'sales_order_details',
      details.toMap(),
      where: 'id = ?',
      whereArgs: [details.id],
    );
  }

  // Delete
  Future<int> delete(int id) async {
    final db = await databaseService.database;
    return await db.delete(
      'sales_order_details',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete collection
  Future<void> deleteCollection(List<SalesOrderDetail> items) async {
    final db = await databaseService.database;
    final batch = db.batch();

    for (final item in items) {
      if (item.id != null) {
        batch.delete(
          'sales_order_details',
          where: 'id = ?',
          whereArgs: [item.id],
        );
      }
    }

    await batch.commit();
  }

  // Get all items
  Future<List<SalesOrderDetail>> getAll(int companyId) async {
    final db = await databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sales_order_details',
      where: 'company = ?',
      whereArgs: [companyId],
    );

    return List.generate(maps.length, (i) {
      return SalesOrderDetail.fromMap(maps[i]);
    });
  }

  // Get by ID
  Future<SalesOrderDetail?> getById(int id) async {
    final db = await databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sales_order_details',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return SalesOrderDetail.fromMap(maps.first);
    }
    return null;
  }

  // Get by Sales Order Header
  Future<List<SalesOrderDetail>> getBySalesOrderHeader(
    int headerId,
    int companyId,
  ) async {
    final db = await databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sales_order_details',
      where: 'sales_order_header_id = ? AND company = ?',
      whereArgs: [headerId, companyId],
    );

    return List.generate(maps.length, (i) {
      return SalesOrderDetail.fromMap(maps[i]);
    });
  }

  // Get available items select one
  Future<List<SalesOrderDetail>> getItemsAvailableSelectOne(
    int companyId,
  ) async {
    return getAll(companyId);
  }

  // Get available items select many
  Future<List<SalesOrderDetail>> getItemsAvailableSelectMany(
    int companyId,
  ) async {
    return getAll(companyId);
  }

  // Complex query with joins for related data
  Future<List<SalesOrderDetail>> getSalesOrderDetailWithRelations(
    int companyId,
  ) async {
    final db = await databaseService.database;

    final query = '''
      SELECT sod.*, 
             it.item_descripton as item_description,
             it.barcode as item_barcode,
             ib.quantity_available as branch_quantity,
             lm.quantity_available as lot_quantity,
             lm.date_expiration as lot_expiration,
             ud.description1 as uom_description
      FROM sales_order_details sod
      LEFT JOIN items_table it ON sod.items_table_id = it.id
      LEFT JOIN items_in_branch ib ON sod.item_in_branch = ib.id
      LEFT JOIN lot_master lm ON sod.lot_number = lm.id
      LEFT JOIN udc_details ud ON sod.unit_of_measure = ud.id
      WHERE sod.company = ?
    ''';

    final List<Map<String, dynamic>> maps = await db.rawQuery(query, [
      companyId,
    ]);

    // Process the results to create SalesOrderDetail with related objects
    // This would need custom mapping based on your specific needs
    return List.generate(maps.length, (i) {
      final data = maps[i];
      return SalesOrderDetail.fromMap(data);
    });
  }

  // Get items by barcode
  Future<List<ItemInBranchModel>> getItemsByBarcode(
    String barcode,
    int branchId,
  ) async {
    final db = await databaseService.database;

    final query = '''
      SELECT ib.*, it.*
      FROM items_in_branch ib
      INNER JOIN items_table it ON ib.item_number = it.id
      WHERE it.barcode = ? AND ib.branch = ?
    ''';

    final List<Map<String, dynamic>> maps = await db.rawQuery(query, [
      barcode,
      branchId,
    ]);

    // Convert to ItemsInBranch objects
    return List.generate(maps.length, (i) {
      final data = maps[i];
      return ItemInBranchModel.fromMap(data);
    });
  }

  // Get lot masters for item and branch
  Future<List<LotMaster>> getLotMastersForItem(
    int itemId,
    int branchId,
    int companyId,
  ) async {
    final db = await databaseService.database;

    final query = '''
      SELECT lm.*
      FROM lot_master lm
      WHERE lm.item_number = ? AND lm.branch = ? AND lm.company = ?
      AND lm.lot_status IN (SELECT id FROM udc_details WHERE detail_code <> 'E')
    ''';

    final List<Map<String, dynamic>> maps = await db.rawQuery(query, [
      itemId,
      branchId,
      companyId,
    ]);

    return List.generate(maps.length, (i) {
      final data = maps[i];
      return LotMaster.fromMap(data);
    });
  }
}
