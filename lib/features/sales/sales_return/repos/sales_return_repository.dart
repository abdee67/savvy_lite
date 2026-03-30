// features/sales/sales_return/repo/sales_return_repository.dart
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/sales/sales_return/models/void_sales_details.dart';
import 'package:savvy_stock/features/sales/sales_return/models/void_sales_header.dart';
import 'package:sqflite/sqflite.dart';

class SalesReturnRepository {
  final LocalDatabaseService databaseService;

  SalesReturnRepository({required this.databaseService});

  // Header Operations
  Future<int> createSalesReturnHeader(SalesReturnHeader header) async {
    final db = await databaseService.database;
    final map = db.insert(
      'sales_return_header',
      header.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return map;
  }

  Future<void> updateSalesReturnHeader(SalesReturnHeader header) async {
    final db = await databaseService.database;
    await db.update(
      'sales_return_header',
      header.toMap(),
      where: 'id = ?',
      whereArgs: [header.id],
    );
  }

  Future<void> deleteSalesReturnHeader(int id) async {
    final db = await databaseService.database;
    await db.delete('sales_return_header', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> voidSalesReturn(int id, String voidIndicator) async {
    final db = await databaseService.database;
    await db.update(
      'sales_return_header',
      {'void_indicator': voidIndicator},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<SalesReturnHeader>> getSalesReturnHeaders(int companyId) async {
    final db = await databaseService.database;
    final maps = await db.rawQuery(
      '''
      SELECT srh.*,
      cu_customer_bill_to.customer_name as customer_bill_to_ref,
      com.company_name as company_name,
      emp.name_first as first_name,
      ud_payment_term.description_1 as payment_term_ref,
      ud_payment_status.description_1 as payment_status_ref,
      ud_payment_instrument.description_1 as payment_instrument_ref,
      ud_return_status.description_1 as return_status_ref
      FROM sales_return_header srh
      LEFT JOIN customer_table cu_customer_bill_to ON srh.customer_bill_to = cu_customer_bill_to.id
      LEFT JOIN employees emp ON srh.employees_id  = emp.id
      LEFT JOIN company_table com ON srh.company = com.id
      LEFT JOIN udc_details ud_payment_term ON srh.payment_term = ud_payment_term.id
      LEFT JOIN udc_details ud_payment_status ON srh.payment_status = ud_payment_status.id
      LEFT JOIN udc_details ud_payment_instrument ON srh.payment_instrument = ud_payment_instrument.id
      LEFT JOIN udc_details ud_return_status ON srh.return_status = ud_return_status.id
      WHERE srh.company = ? ORDER BY srh.fs_number DESC
      ''',
      [companyId],
    );

    return maps.map((map) => SalesReturnHeader.fromMap(map)).toList();
  }

  Future<SalesReturnHeader?> getSalesReturnHeaderById(int id) async {
    final db = await databaseService.database;
    final maps = await db.rawQuery(
      '''
      SELECT srh.*,
      cu_customer_bill_to.customer_name as customer_bill_to_ref,
      com.company_name as company_name,
      emp.name_first as first_name,
      ud_payment_term.description_1 as payment_term_ref,
      ud_payment_status.description_1 as payment_status_ref,
      ud_payment_instrument.description_1 as payment_instrument_ref,
      ud_return_status.description_1 as return_status_ref
      FROM sales_return_header srh
      LEFT JOIN customer_table cu_customer_bill_to ON srh.customer_bill_to = cu_customer_bill_to.id
      LEFT JOIN company_table com ON srh.company = com.id
      LEFT JOIN employees emp ON srh.employees_id  = emp.id
      LEFT JOIN udc_details ud_payment_term ON srh.payment_term = ud_payment_term.id
      LEFT JOIN udc_details ud_payment_status ON srh.payment_status = ud_payment_status.id
      LEFT JOIN udc_details ud_payment_instrument ON srh.payment_instrument = ud_payment_instrument.id
      LEFT JOIN udc_details ud_return_status ON srh.return_status = ud_return_status.id
      WHERE srh.id = ? ORDER BY srh.fs_number DESC
      ''',
      [id],
    );

    if (maps.isNotEmpty) {
      return SalesReturnHeader.fromMap(maps.first);
    }
    return null;
  }

  Future<List<SalesReturnHeader>> filterSalesReturns({
    required int companyId,
    String? fsNumber,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final where = StringBuffer('company = ? ORDER BY fs_number DESC');
    final whereArgs = <dynamic>[companyId];
    final db = await databaseService.database;

    if (fsNumber != null && fsNumber.isNotEmpty) {
      where.write(' AND fs_number = ?');
      whereArgs.add(fsNumber);
    }

    if (startDate != null) {
      where.write(' AND return_date >= ?');
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      where.write(' AND return_date <= ?');
      whereArgs.add(endDate.toIso8601String());
    }

    final maps = await db.query(
      'sales_return_header',
      where: where.toString(),
      whereArgs: whereArgs,
      orderBy: 'return_date DESC',
    );

    return maps.map((map) => SalesReturnHeader.fromMap(map)).toList();
  }

  // Detail Operations
  Future<void> createSalesReturnDetail(SalesReturnDetails detail) async {
    final db = await databaseService.database;
    await db.insert(
      'sales_return_details',
      detail.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> createSalesReturnDetailsBatch(
    List<SalesReturnDetails> details,
  ) async {
    final db = await databaseService.database;
    final batch = db.batch();

    for (final detail in details) {
      batch.insert(
        'sales_return_details',
        detail.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<void> updateSalesReturnDetail(SalesReturnDetails detail) async {
    final db = await databaseService.database;
    await db.update(
      'sales_return_details',
      detail.toMap(),
      where: 'id = ?',
      whereArgs: [detail.id],
    );
  }

  Future<void> deleteSalesReturnDetail(int id) async {
    final db = await databaseService.database;
    await db.delete('sales_return_details', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<SalesReturnDetails>> getSalesReturnDetailsByHeaderId(
    int headerId,
    int companyId,
  ) async {
    final db = await databaseService.database;
    final maps = await db.query(
      'sales_return_details',
      where: 'sales_return_header_id = ? AND company = ?',
      whereArgs: [headerId, companyId],
    );

    return maps.map((map) => SalesReturnDetails.fromMap(map)).toList();
  }

  Future<List<SalesReturnDetails>> getSalesReturnDetails(int companyId) async {
    final db = await databaseService.database;
    final maps = await db.rawQuery(
      '''
      SELECT srd.*,
      srh.fs_number,
      ib.description as branch,
      lm.lot_number as lot_number,
      ud.description_1 as unit_of_measure,
      rs.description_1 as return_status,
      rr.description_1 as return_reason,
      it.item_description as item_description
      FROM sales_return_details srd
      INNER JOIN sales_return_header srh ON srd.sales_return_header_id = srh.id
      INNER JOIN item_in_branch ib ON srd.item_in_branch = ib.id
      INNER JOIN lot_master lm ON srd.lot_number = lm.id
      INNER JOIN udc_details ud ON srd.unit_of_measure = ud.id
      INNER JOIN udc_details rs ON srd.return_status = rs.id
      INNER JOIN udc_details rr ON srd.return_reason = rr.id
      INNER JOIN item_entry it ON srd.items_table_id = it.id
    ''',
      [companyId],
    );

    return maps.map((map) => SalesReturnDetails.fromMap(map)).toList();
  }

  // Utility Methods
  Future<int> getNextOrderNumber(int companyId) async {
    final db = await databaseService.database;
    final maps = await db.rawQuery(
      '''
      SELECT MAX(order_number) as max_number 
      FROM sales_return_header 
      WHERE company = ?
    ''',
      [companyId],
    );

    final maxNumber = maps.first['max_number'] as int?;
    return (maxNumber ?? 0) + 1;
  }

  Future<String> generateNextFsNumber(int companyId, int branchId) async {
    final year = DateTime.now().year;
    final sequence = await getNextOrderNumber(companyId);
    return 'SR-$branchId-$year-${sequence.toString().padLeft(6, '0')}';
  }

  // 🎯 GENERATE REFERENCE NOTE (like Java's generateReferenceNote3)
  Future<String> generateReferenceNote3(int companyId) async {
    final companyName = await _getCompanyName(companyId);
    final prefix = "SR-V-";
    final companyCode = companyName.length >= 2
        ? companyName.substring(0, 2).toUpperCase()
        : companyName.toUpperCase();

    final nextSeq = await _getNextSequenceForCompany(companyId);
    final seqFormatted = nextSeq.toString().padLeft(2, '0');

    return '$prefix$companyCode-$seqFormatted';
  }

  Future<String> _getCompanyName(int companyId) async {
    final db = await databaseService.database;
    final result = await db.query(
      'company_table',
      columns: ['company_name'],
      where: 'id = ?',
      whereArgs: [companyId],
    );

    if (result.isNotEmpty) {
      return result.first['company_name'] as String;
    }
    return '';
  }

  Future<int> _getNextSequenceForCompany(int companyId) async {
    try {
      final references = await getAllReferenceNote3ForCompany(companyId);
      int maxSeq = 0;

      for (final ref in references) {
        if (ref != null && ref.isNotEmpty) {
          // Expected format: SR-V-[COMPANY]-[SEQ]
          // Example: SR-V-TE-01
          final parts = ref.split('-');
          if (parts.isNotEmpty) {
            final seqStr = parts.last;
            final seq = int.tryParse(seqStr) ?? 0;
            if (seq > maxSeq) {
              maxSeq = seq;
            }
          }
        }
      }
      return maxSeq + 1;
    } catch (e) {
      return 1;
    }
  }

  Future<List<String?>> getAllReferenceNote3ForCompany(int companyId) async {
    final db = await databaseService.database;
    final maps = await db.query(
      'sales_return_header',
      columns: ['reference_note3'],
      where: 'company = ?',
      whereArgs: [companyId],
    );

    return maps.map((m) => m['reference_note3'] as String?).toList();
  }
}
