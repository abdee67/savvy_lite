/// features/sales/sales_order_details/repositories/sales_order_details_repository.dart
library;

import 'package:savvy_stock/core/repositories/udc_repository.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/sales/sales_order/detail/model/sales_order_detail.dart';
import 'package:savvy_stock/features/stock/item_entry/data/item_repository.dart';
import 'package:savvy_stock/features/stock/item_in_branch/repo/item_in_branch_repo.dart';
import 'package:savvy_stock/features/stock/lot_master/repo/lot_master_repo.dart';
import 'package:sqflite/sqflite.dart';

class SalesOrderDetailRepository {
  final LocalDatabaseService databaseService;
  final StockItemsEntryRepository itemEntryRepository;
  final StockItemInBranchRepository itemInBranchRepository;
  final LotMasterRepository lotMasterRepository;
  final UdcRepository udcDetailsRepository;
  final AuthBloc authBloc;

  SalesOrderDetailRepository({
    required this.databaseService,
    required this.itemEntryRepository,
    required this.itemInBranchRepository,
    required this.lotMasterRepository,
    required this.udcDetailsRepository,
    required this.authBloc,
  });

  // Create
  Future<int> createSalesOrderDetail(SalesOrderDetail details) async {
    final db = await databaseService.database;
    final id = await db.insert(
      'sales_order_details',
      details.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return id;
  }

  // Batch create for multiple items
  Future<void> createSalesOrderDetailBatch(
    List<SalesOrderDetail> detailsList,
  ) async {
    final db = await databaseService.database;
    final batch = db.batch();

    for (final details in detailsList) {
      batch.insert(
        'sales_order_details',
        details.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print(
        '🎯 DEBUG: Inserting detail - Lot: ${details.lotNumber}, Taxable: ${details.taxable}',
      );
    }

    await batch.commit(noResult: true);
  }

  // Read
  Future<SalesOrderDetail?> getSalesOrderDetailById(int id) async {
    final db = await databaseService.database;

    final maps = await db.query(
      'sales_order_details',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return SalesOrderDetail.fromMap(maps.first);
    }
    return null;
  }

  // Get by Sales Order Header ID
  Future<List<SalesOrderDetail>> getSalesOrderDetailsByHeaderId(
    int headerId,
    int companyId,
  ) async {
    final db = await databaseService.database;
    final maps = await db.query(
      'sales_order_details',
      where: 'sales_order_header_id = ? AND company = ?',
      whereArgs: [headerId, companyId],
    );

    return maps.map((map) => SalesOrderDetail.fromMap(map)).toList();
  }

  // Get with relations by Header ID
  Future<List<SalesOrderDetail>> getSalesOrderDetailsWithRelationsByHeaderId(
    int headerId,
    int companyId,
  ) async {
    final details = await getSalesOrderDetailsByHeaderId(headerId, companyId);
    final result = <SalesOrderDetail>[];

    for (final detail in details) {
      // Get related data
      final itemsTable = await itemEntryRepository.findById(
        detail.itemsTableId!,
        companyId,
      );
      var itemsInBranch = detail.itemInBranch != null
          ? await itemInBranchRepository.findById(
              detail.itemInBranch!.toInt(),
              companyId,
            )
          : null;

      // Fallback if not found by ID (data integrity issue)
      if (itemsInBranch == null && detail.itemsTableId != null) {
        final matches = await itemInBranchRepository.findByItem(
          detail.itemsTableId!,
          companyId,
        );
        if (matches.isNotEmpty) {
          itemsInBranch = matches.first;
        }
      }
      final lotMaster = detail.lotNumber != null
          ? await lotMasterRepository.getLotMasterById(
              detail.lotNumber!,
              companyId,
            )
          : null;
      final unitOfMeasure = detail.unitOfMeasure != null
          ? await udcDetailsRepository.getUdcDetailById(detail.unitOfMeasure)
          : null;

      result.add(
        detail.copyWith(
          item: itemsTable,
          itemBranch: itemsInBranch,
          lot: lotMaster,
          uom: unitOfMeasure,
        ),
      );
    }

    return result;
  }

  // Update
  Future<void> updateSalesOrderDetail(SalesOrderDetail details) async {
    final db = await databaseService.database;
    await db.update(
      'sales_order_details',
      details.toMap(),
      where: 'id = ?',
      whereArgs: [details.id],
    );
  }

  // Delete
  Future<void> deleteSalesOrderDetail(int id) async {
    final db = await databaseService.database;
    await db.delete('sales_order_details', where: 'id = ?', whereArgs: [id]);
  }

  // Batch delete
  Future<void> deleteSalesOrderDetailBatch(List<int> ids) async {
    final db = await databaseService.database;
    final batch = db.batch();

    for (final id in ids) {
      batch.delete('sales_order_details', where: 'id = ?', whereArgs: [id]);
    }

    await batch.commit(noResult: true);
  }

  // Delete by Sales Order Header ID
  Future<void> deleteSalesOrderDetailByHeaderId(int headerId) async {
    final db = await databaseService.database;
    await db.delete(
      'sales_order_details',
      where: 'sales_order_header_id = ?',
      whereArgs: [headerId],
    );
  }

  // Count details with complex filtering (equivalent to Java's countDetail method)
  Future<int> countSalesOrderDetail({
    required int companyId,
    int? customerTableId,
    int? itemsTableId,
    String? fsNumber,
    String? proformaNumber,
    DateTime? startDate,
    DateTime? endDate,
    String? orderStatus,
    bool? voidIndicator,
    bool? detailTransaction,
    String? salesRepresent,
  }) async {
    var whereClause = 'sd.company = ?';
    final whereArgs = <dynamic>[companyId];

    // Join with sales_order_header for filtering
    var query =
        '''
      SELECT COUNT(sd.id) as count
      FROM sales_order_details sd
      INNER JOIN sales_order_header soh ON sd.sales_order_header_id = soh.id
      WHERE $whereClause
    ''';

    if (customerTableId != null) {
      query += ' AND soh.customer_bill_to = ?';
      whereArgs.add(customerTableId);
    }

    if (itemsTableId != null) {
      query += ' AND sd.items_table_id = ?';
      whereArgs.add(itemsTableId);
    }

    if (fsNumber != null && fsNumber.isNotEmpty) {
      query += ' AND soh.fs_number = ?';
      whereArgs.add(fsNumber);
    }

    if (proformaNumber != null && proformaNumber.isNotEmpty) {
      query += ' AND soh.proforma_reference = ?';
      whereArgs.add(proformaNumber);
    }

    if (startDate != null && endDate != null) {
      query += ' AND soh.order_date BETWEEN ? AND ?';
      whereArgs.add(startDate.toIso8601String());
      whereArgs.add(endDate.toIso8601String());
    } else if (startDate != null) {
      query += ' AND soh.order_date >= ?';
      whereArgs.add(startDate.toIso8601String());
    } else if (endDate != null) {
      query += ' AND soh.order_date <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    if (orderStatus != null) {
      query += ' AND soh.sales_type = ?';
      whereArgs.add(orderStatus);
    }

    if (voidIndicator == true) {
      query += ' AND soh.void_indicator = "V"';
    } else {
      query += ' AND soh.void_indicator IS NULL';
    }

    if (salesRepresent != null && salesRepresent.isNotEmpty) {
      query += ' AND soh.sales_represent = ?';
      whereArgs.add(salesRepresent);
    }

    final maps = await databaseService.database;
    final result = await maps.rawQuery(query, whereArgs);
    return result.first['count'] as int;
  }

  // Find ranged details with complex filtering (equivalent to Java's findRangedetail method)
  Future<List<SalesOrderDetail>> findRangedSalesOrderDetail({
    required int first,
    required int pageSize,
    required int companyId,
    int? customerTableId,
    int? itemsTableId,
    String? fsNumber,
    String? proformaNumber,
    DateTime? startDate,
    DateTime? endDate,
    String? orderStatus,
    bool? voidIndicator,
    bool? detailTransaction,
    String? salesRepresent,
  }) async {
    var whereClause = 'sd.company = ?';
    final whereArgs = <dynamic>[companyId];

    var query =
        '''
      SELECT sd.*
      FROM sales_order_details sd
      
      INNER JOIN sales_order_header soh ON sd.sales_order_header_id = soh.id
      WHERE $whereClause
    ''';

    if (customerTableId != null) {
      query += ' AND soh.customer_bill_to = ?';
      whereArgs.add(customerTableId);
    }

    if (itemsTableId != null) {
      query += ' AND sd.items_table_id = ?';
      whereArgs.add(itemsTableId);
    }

    if (fsNumber != null && fsNumber.isNotEmpty) {
      query += ' AND soh.fs_number = ?';
      whereArgs.add(fsNumber);
    }

    if (proformaNumber != null && proformaNumber.isNotEmpty) {
      query += ' AND soh.proforma_reference = ?';
      whereArgs.add(proformaNumber);
    }

    if (startDate != null && endDate != null) {
      query += ' AND soh.order_date BETWEEN ? AND ?';
      whereArgs.add(startDate.toIso8601String());
      whereArgs.add(endDate.toIso8601String());
    } else if (startDate != null) {
      query += ' AND soh.order_date >= ?';
      whereArgs.add(startDate.toIso8601String());
    } else if (endDate != null) {
      query += ' AND soh.order_date <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    if (orderStatus != null) {
      query += ' AND soh.sales_type = ?';
      whereArgs.add(orderStatus);
    }

    if (voidIndicator == true) {
      query += ' AND soh.void_indicator = "V"';
    } else {
      query += ' AND soh.void_indicator IS NULL';
    }

    if (salesRepresent != null && salesRepresent.isNotEmpty) {
      query += ' AND soh.sales_represent = ?';
      whereArgs.add(salesRepresent);
    }

    query += ' ORDER BY sd.id DESC LIMIT ? OFFSET ?';
    whereArgs.add(pageSize);
    whereArgs.add(first);

    final maps = await databaseService.database;
    final result = await maps.rawQuery(query, whereArgs);
    final details = result.map((map) => SalesOrderDetail.fromMap(map)).toList();

    // Get relations for each detail
    final detailsList = <SalesOrderDetail>[];
    for (final detail in details) {
      final itemsTable = await itemEntryRepository.findById(
        detail.itemsTableId!,
        authBloc.state.companyId!,
      );
      final itemsInBranch = detail.itemInBranch != null
          ? await itemInBranchRepository.findById(
              detail.itemInBranch!.toInt(),
              authBloc.state.companyId!,
            )
          : null;
      final lotMaster = detail.lotNumber != null
          ? await lotMasterRepository.getLotMasterById(
              detail.lotNumber!.toInt(),
              authBloc.state.companyId!,
            )
          : null;
      final unitOfMeasure = detail.unitOfMeasure != null
          ? await udcDetailsRepository.getUdcDetailById(
              detail.unitOfMeasure!.toInt(),
            )
          : null;

      detailsList.add(
        SalesOrderDetail(
          orderHeader: detail.orderHeader,
          item: itemsTable,
          itemBranch: itemsInBranch,
          lot: lotMaster,
          uom: unitOfMeasure,
        ),
      );
    }

    return detailsList;
  }

  // Get extended price sum for a sales order header
  Future<double> getExtendedPriceSumByHeaderId(int headerId) async {
    final db = await databaseService.database;
    final result = await db.rawQuery(
      'SELECT SUM(extended_price) as total FROM sales_order_details WHERE sales_order_header_id = ?',
      [headerId],
    );

    final total = result.first['total'] as double?;
    return total ?? 0.0;
  }

  // Get quantity sum by item and branch (for stock validation)
  Future<double> getQuantitySumByItemAndBranch(
    int itemsTableId,
    int branchId,
  ) async {
    final db = await databaseService.database;
    final result = await db.rawQuery(
      '''
      SELECT SUM(sod.quantity) as total_quantity
      FROM sales_order_details sod
      INNER JOIN sales_order_header soh ON sod.sales_order_header_id = soh.id
      INNER JOIN items_in_branch iib ON sod.item_in_branch = iib.id
      WHERE sod.items_table_id = ? AND iib.branch = ?
        AND soh.void_indicator IS NULL
    ''',
      [itemsTableId, branchId],
    );

    final total = result.first['total_quantity'] as double?;
    return total ?? 0.0;
  }

  // Complex query with joins for related data
  Future<List<SalesOrderDetail>> getSalesOrderDetailByCompany(
    int companyId,
  ) async {
    final query = '''
    SELECT sod.*, 
           it.item_description as item_description,
           it.barcode as barcode,
           ib.quantity_available as quantity_available,
           lm.quantity_available as lot_quantity_available,
           lm.date_expiration as lot_expiration,
           u.description_1 as unit_of_measure_description
    FROM sales_order_details sod
    LEFT JOIN items_table it ON sod.items_table_id = it.id
    LEFT JOIN items_in_branch ib ON sod.item_in_branch = ib.id
    LEFT JOIN lot_master lm ON sod.lot_number = lm.id
    LEFT JOIN udc_details u ON sod.unit_of_measure = u.id
    WHERE sod.company = ?
  ''';

    final db = await databaseService.database;
    final maps = await db.rawQuery(query, [companyId]);

    // Process the results to create SalesOrderDetail with related objects
    // This would need custom mapping based on your specific needs
    return List.generate(maps.length, (i) {
      final data = maps[i];
      return SalesOrderDetail.fromMap(data);
    });
  }
}
