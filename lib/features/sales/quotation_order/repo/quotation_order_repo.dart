// features/sales/quotation_order/repo/quotation_order_repository.dart
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/sales/quotation_order/model/quotation_order_detail.dart';
import 'package:savvy_stock/features/sales/quotation_order/model/quotation_order_header.dart';
import 'package:sqflite/sqflite.dart';

class QuotationOrderRepository {
  final LocalDatabaseService _databaseService;

  QuotationOrderRepository({required LocalDatabaseService databaseService})
    : _databaseService = databaseService;

  Future<Database> get _db async => _databaseService.database;

  // ============ HEADER CRUD OPERATIONS ============

  Future<int> createQuotationOrderHeader(QuotationOrderHeader header) async {
    final db = await _db;
    try {
      return await db.insert('quote_order_header', header.toMap());
    } catch (e) {
      throw Exception('Failed to create quotation order header: $e');
    }
  }

  Future<List<QuotationOrderHeader>> getQuotationOrderHeaders({
    int? companyId,
    int? customerBillTo,
    String? fsNumber,
    DateTime? startDate,
    DateTime? endDate,
    bool? voidIndicator,
    bool includeVoided = false,
  }) async {
    final db = await _db;

    String where = '1=1';
    List<dynamic> whereArgs = [];

    if (companyId != null) {
      where += ' AND qoh.company = ?';
      whereArgs.add(companyId);
    }
    if (customerBillTo != null) {
      where += ' AND qoh.customer_bill_to = ?';
      whereArgs.add(customerBillTo);
    }
    if (fsNumber != null) {
      where += ' AND qoh.fs_number = ?';
      whereArgs.add(fsNumber);
    }
    if (voidIndicator != null) {
      where += ' AND qoh.void_indicator = ?';
      whereArgs.add(voidIndicator);
    }
    if (startDate != null) {
      where += ' AND qoh.order_date >= ?';
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      where += ' AND qoh.order_date <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    if (!includeVoided) {
      where += ' AND (qoh.void_indicator IS NULL OR qoh.void_indicator = "")';
    } else if (voidIndicator != null) {
      if (voidIndicator) {
        where +=
            ' AND qoh.void_indicator IS NOT NULL AND qoh.void_indicator != ""';
      } else {
        where += ' AND (qoh.void_indicator IS NULL OR qoh.void_indicator = "")';
      }
    }

    // Build comprehensive query with all JOINs
    final query =
        '''
      SELECT 
        qoh.*,
        cb.customer_name as customer_bill_to_name,
        ct.customer_name as customer_table_name,
        e.name_first as employee_first_name,
        e.name_middle as employee_middle_name,
        e.name_last as employee_last_name,
        e.email as employee_email,
        e.phone as employee_phone,
        e.address as employee_address,
        e.city as employee_city,
        pi.description_1 as payment_instrument_description,
        pi.detail_code as payment_instrument_detail_code,
        pt.description_1 as payment_term_description,
        pt.detail_code as payment_term_detail_code,
        ps.description_1 as payment_status_description,
        ps.detail_code as payment_status_detail_code,
        pm.description_1 as payment_method_description,
        pm.detail_code as payment_method_detail_code,
        ot.description_1 as order_type_description,
        ot.detail_code as order_type_detail_code,
        b.description as branch_name
      FROM quote_order_header qoh
      LEFT JOIN customer_table cb ON qoh.customer_bill_to = cb.id
      LEFT JOIN customer_table ct ON qoh.customer_table_id = ct.id
      LEFT JOIN employees e ON qoh.employees_id = e.id
      LEFT JOIN udc_details pi ON qoh.payment_instrument = pi.id
      LEFT JOIN udc_details pt ON qoh.payment_term = pt.id
      LEFT JOIN udc_details ps ON qoh.payment_status = ps.id
      LEFT JOIN udc_details pm ON qoh.payment_method = pm.id
      LEFT JOIN udc_details ot ON qoh.order_type = ot.id
      LEFT JOIN branch_table b ON qoh.branch_id = b.id
      WHERE $where
      ORDER BY qoh.id DESC
    ''';

    final maps = await db.rawQuery(query, whereArgs);

    return maps.map((map) => QuotationOrderHeader.fromMap(map)).toList();
  }

  Future<int> updateQuotationOrderHeader(QuotationOrderHeader header) async {
    final db = await _db;
    try {
      return await db.update(
        'quote_order_header',
        header.toMap(),
        where: 'id = ?',
        whereArgs: [header.id],
      );
    } catch (e) {
      throw Exception('Failed to update quotation order: $e');
    }
  }

  Future<int> deleteQuotationOrderHeader(int id) async {
    final db = await _db;
    return await db.delete(
      'quote_order_header',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ✅ ADDING MISSING: Get quotation header by ID
  Future<QuotationOrderHeader?> getQuotationOrderHeaderById(int id) async {
    final db = await _db;
    final maps = await db.query(
      'quote_order_header',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return QuotationOrderHeader.fromMap(maps.first);
    }
    return null;
  }

  Future<int> getNextOrderNumber(int companyId) async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT MAX(order_number) as max_order FROM quote_order_header WHERE company = ?',
      [companyId],
    );

    final maxOrder = result.first['max_order'] as int?;
    return (maxOrder ?? 0) + 1;
  }

  Future<String> generateNextFsNumber(int companyId, int branchId) async {
    final db = await _db;

    // ✅ Get the maximum fs_number by extracting numeric part from 'P00000000001'
    final result = await db.rawQuery(
      '''SELECT fs_number 
         FROM quote_order_header 
         WHERE company = ? AND fs_number IS NOT NULL 
         ORDER BY CAST(SUBSTR(fs_number, 2) AS INTEGER) DESC 
         LIMIT 1''',
      [companyId],
    );

    int nextNumber = 1;
    if (result.isNotEmpty && result.first['fs_number'] != null) {
      final currentFs = result.first['fs_number'] as String;
      // Extract numeric part (remove 'P' prefix)
      final numericPart = currentFs.substring(1);
      nextNumber = (int.tryParse(numericPart) ?? 0) + 1;
    }

    return 'P${nextNumber.toString().padLeft(11, '0')}';
  }

  // ============ BATCH HEADER OPERATIONS ============

  // ✅ ADDING MISSING: Batch delete headers
  Future<int> deleteQuotationOrderHeadersBatch(List<int> ids) async {
    if (ids.isEmpty) return 0;

    final db = await _db;
    final placeholders = List.generate(ids.length, (_) => '?').join(',');

    return await db.delete(
      'quote_order_header',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
  }

  // ✅ ADDING MISSING: Batch update headers
  Future<int> updateQuotationOrderHeadersBatch(
    List<QuotationOrderHeader> headers,
  ) async {
    final db = await _db;
    final batch = db.batch();

    for (final header in headers) {
      batch.update(
        'quote_order_header',
        header.toMap(),
        where: 'id = ?',
        whereArgs: [header.id],
      );
    }

    final results = await batch.commit();
    return results.length;
  }

  // ✅ ADDING MISSING: Batch create headers
  Future<void> createQuotationOrderHeadersBatch(
    List<QuotationOrderHeader> headers,
  ) async {
    final db = await _db;
    final batch = db.batch();

    for (final header in headers) {
      batch.insert('quote_order_header', header.toMap());
    }

    await batch.commit(noResult: true);
  }

  // ============ DETAIL OPERATIONS ============

  Future<int> createQuotationOrderDetail(QuotationOrderDetail detail) async {
    final db = await _db;
    try {
      return await db.insert('quote_order_detail', detail.toMap());
    } catch (e) {
      throw Exception('Failed to create quotation order detail: $e');
    }
  }

  Future<List<QuotationOrderDetail>> getQuotationOrderDetailsByHeaderId(
    int headerId,
    int companyId,
  ) async {
    final db = await _db;
    final maps = await db.rawQuery(
      '''
      SELECT 
        qod.*,
        it.item_description as item_description,
        ib.branch as branch,
        ib.item_number as item_number,
        ps.description_1 as prforma_status_description,
        ps.detail_code as prforma_status_code,
        uom.description_1 as unit_of_measure_description,
        uom.detail_code as unit_of_measure_code
      FROM quote_order_detail qod
      LEFT JOIN items_table it ON qod.items_table_id = it.id
      LEFT JOIN items_in_branch ib ON qod.item_in_branch = ib.id
      LEFT JOIN udc_details ps ON qod.prforma_status = ps.id
      LEFT JOIN udc_details uom ON qod.unit_of_measure = uom.id
      WHERE qod.quote_order_header_id = ? AND qod.company = ?
      ORDER BY qod.id DESC
    ''',
      [headerId, companyId],
    );
    if (maps.isNotEmpty) {
      return maps.map((map) => QuotationOrderDetail.fromMap(map)).toList();
    }
    return [];
  }

  // ✅ ADDING MISSING: Get quotation detail by ID
  Future<QuotationOrderDetail?> getQuotationOrderDetailById(int id) async {
    final db = await _db;
    final maps = await db.rawQuery(
      '''
      SELECT 
        qod.*,
        it.item_description as item_description,
        ib.branch as branch,
        ps.description_1 as prforma_status_description,
        ps.detail_code as prforma_status_code,
        uom.description_1 as unit_of_measure_description,
        uom.detail_code as unit_of_measure_code
      FROM quote_order_detail qod
      LEFT JOIN items_table it ON qod.items_table_id = it.id
      LEFT JOIN items_in_branch ib ON qod.item_in_branch = ib.id
      LEFT JOIN udc_details ps ON qod.prforma_status = ps.id
      LEFT JOIN udc_details uom ON qod.unit_of_measure = uom.id
      WHERE qod.id = ? AND qod.company = ?
      ORDER BY qod.id DESC
    ''',
      [id],
    );
    if (maps.isNotEmpty) {
      return QuotationOrderDetail.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateQuotationOrderDetail(QuotationOrderDetail detail) async {
    final db = await _db;
    try {
      return await db.update(
        'quote_order_detail',
        detail.toMap(),
        where: 'id = ?',
        whereArgs: [detail.id],
      );
    } catch (e) {
      throw Exception('Failed to update quotation order detail: $e');
    }
  }

  Future<int> deleteQuotationOrderDetail(int id) async {
    final db = await _db;
    return await db.delete(
      'quote_order_detail',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============ BATCH DETAIL OPERATIONS ============

  Future<void> createQuotationOrderDetailBatch(
    List<QuotationOrderDetail> details,
  ) async {
    final db = await _db;
    final batch = db.batch();

    for (final detail in details) {
      batch.insert('quote_order_detail', detail.toMap());
    }

    await batch.commit(noResult: true);
  }

  // ✅ ADDING MISSING: Batch update details
  Future<void> updateQuotationOrderDetailBatch(
    List<QuotationOrderDetail> details,
  ) async {
    final db = await _db;
    final batch = db.batch();

    for (final detail in details) {
      batch.update(
        'quote_order_detail',
        detail.toMap(),
        where: 'id = ?',
        whereArgs: [detail.id],
      );
    }

    await batch.commit(noResult: true);
  }

  // ✅ ADDING MISSING: Batch delete details by IDs
  Future<int> deleteQuotationOrderDetailBatch(List<int> ids) async {
    if (ids.isEmpty) return 0;

    final db = await _db;
    final placeholders = List.generate(ids.length, (_) => '?').join(',');

    return await db.delete(
      'quote_order_detail',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
  }

  Future<int> deleteQuotationOrderDetailByHeaderId(int headerId) async {
    final db = await _db;
    return await db.delete(
      'quote_order_detail',
      where: 'quote_order_header_id = ?',
      whereArgs: [headerId],
    );
  }

  // ============ FILTER & SEARCH OPERATIONS ============

  Future<List<QuotationOrderHeader>> filterQuotationOrders({
    required int companyId,
    int? customerBillTo,
    String? fsNumber,
    String? conversionStatus,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _db;

    String where = 'company = ?';
    List<dynamic> whereArgs = [companyId];

    if (customerBillTo != null) {
      where += ' AND customer_bill_to = ?';
      whereArgs.add(customerBillTo);
    }

    if (fsNumber != null && fsNumber.isNotEmpty) {
      where += ' AND fs_number = ?';
      whereArgs.add(fsNumber);
    }

    if (conversionStatus != null && conversionStatus.isNotEmpty) {
      where += ' AND conversion_status = ?';
      whereArgs.add(conversionStatus);
    }

    if (startDate != null && endDate != null) {
      where += ' AND order_date BETWEEN ? AND ?';
      whereArgs.add(startDate.toIso8601String());
      whereArgs.add(endDate.toIso8601String());
    }

    where += ' ORDER BY id DESC';

    final maps = await db.query(
      'quote_order_header',
      where: where,
      whereArgs: whereArgs,
    );

    return maps.map((map) => QuotationOrderHeader.fromMap(map)).toList();
  }

  // ✅ ADDING MISSING: Search quotation orders with text query
  Future<List<QuotationOrderHeader>> searchQuotationOrders({
    required int companyId,
    required String query,
  }) async {
    final db = await _db;

    final searchQuery = '''
      SELECT * FROM quote_order_header 
      WHERE company = ? 
        AND (
          fs_number LIKE ? 
          OR reference_note1 LIKE ? 
          OR reference_note2 LIKE ? 
          OR reference_note3 LIKE ?
          OR order_number LIKE ?
        )
      ORDER BY id DESC
    ''';

    final searchPattern = '%$query%';
    final maps = await db.rawQuery(searchQuery, [
      companyId,
      searchPattern,
      searchPattern,
      searchPattern,
      searchPattern,
      searchPattern,
    ]);

    return maps.map((map) => QuotationOrderHeader.fromMap(map)).toList();
  }

  // ✅ ADDING MISSING: Get quotations by customer
  Future<List<QuotationOrderHeader>> getQuotationsByCustomer({
    required int companyId,
    required int customerId,
  }) async {
    final db = await _db;
    final maps = await db.query(
      'quote_order_header',
      where: 'company = ? AND customer_bill_to = ?',
      whereArgs: [companyId, customerId],
      orderBy: 'id DESC',
    );

    return maps.map((map) => QuotationOrderHeader.fromMap(map)).toList();
  }

  // ✅ ADDING MISSING: Get quotations by status
  Future<List<QuotationOrderHeader>> getQuotationsByStatus({
    required int companyId,
    required String status,
  }) async {
    final db = await _db;
    final maps = await db.query(
      'quote_order_header',
      where: 'company = ? AND conversion_status = ?',
      whereArgs: [companyId, status],
      orderBy: 'id DESC',
    );

    return maps.map((map) => QuotationOrderHeader.fromMap(map)).toList();
  }

  // ============ STATISTICS & ANALYTICS ============

  // ✅ ADDING MISSING: Get quotation statistics
  Future<Map<String, dynamic>> getQuotationStatistics({
    required int companyId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await _db;

    final result = await db.rawQuery(
      '''
      SELECT 
        COUNT(*) as total_quotations,
        SUM(amount_total) as total_amount,
        AVG(amount_total) as average_quotation,
        COUNT(CASE WHEN conversion_status = 'Converted' THEN 1 END) as converted_count,
        COUNT(CASE WHEN conversion_status = 'Cancelled' THEN 1 END) as cancelled_count,
        COUNT(CASE WHEN conversion_status = 'Draft' THEN 1 END) as draft_count
      FROM quote_order_header 
      WHERE company = ? 
        AND order_date BETWEEN ? AND ?
        AND (void_indicator IS NULL OR void_indicator = "")
    ''',
      [companyId, startDate.toIso8601String(), endDate.toIso8601String()],
    );

    return result.isNotEmpty ? result.first.cast<String, dynamic>() : {};
  }

  // ✅ ADDING MISSING: Get extended price sum for header
  Future<double> getExtendedPriceSumByHeaderId(int headerId) async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT SUM(extended_price) as total FROM quote_order_detail WHERE quote_order_header_id = ?',
      [headerId],
    );

    final total = result.first['total'] as double?;
    return total ?? 0.0;
  }

  // ✅ ADDING MISSING: Get quotation count
  Future<int> getQuotationCount({
    required int companyId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _db;

    String where = 'company = ?';
    List<dynamic> whereArgs = [companyId];

    if (startDate != null) {
      where += ' AND order_date >= ?';
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      where += ' AND order_date <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM quote_order_header WHERE $where',
      whereArgs,
    );

    return result.first['count'] as int? ?? 0;
  }

  // ============ COMPLEX QUERIES ============

  // ✅ ADDING MISSING: Get quotations with details (joined query)
  Future<List<QuotationOrderHeader>> getQuotationsWithDetails({
    required int companyId,
    int? customerBillTo,
    String? conversionStatus,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _db;

    // Build the base query with joins
    var query = '''
      SELECT qoh.*,
             COUNT(qod.id) as detail_count,
             SUM(qod.extended_price) as total_extended_price
      FROM quote_order_header qoh
      LEFT JOIN quote_order_detail qod ON qoh.id = qod.quote_order_header_id
      WHERE qoh.company = ?
    ''';

    final whereArgs = <dynamic>[companyId];

    if (customerBillTo != null) {
      query += ' AND qoh.customer_bill_to = ?';
      whereArgs.add(customerBillTo);
    }

    if (conversionStatus != null && conversionStatus.isNotEmpty) {
      query += ' AND qoh.conversion_status = ?';
      whereArgs.add(conversionStatus);
    }

    if (startDate != null && endDate != null) {
      query += ' AND qoh.order_date BETWEEN ? AND ?';
      whereArgs.add(startDate.toIso8601String());
      whereArgs.add(endDate.toIso8601String());
    }

    query += ' GROUP BY qoh.id ORDER BY qoh.id DESC';

    final maps = await db.rawQuery(query, whereArgs);

    return maps.map((map) => QuotationOrderHeader.fromMap(map)).toList();
  }

  // ✅ ADDING MISSING: Get quotation details with item information
  Future<List<QuotationOrderDetail>> getQuotationDetailsWithItems(
    int headerId,
    int companyId,
  ) async {
    final db = await _db;

    final query = '''
      SELECT qod.*,
             it.item_description as item_description,
             it.barcode as barcode,
             uom.detail_code as unit_of_measure_detail_code,
             uom.description_1 as unit_of_measure_description
      FROM quote_order_detail qod
      LEFT JOIN items_table it ON qod.items_table_id = it.id
      LEFT JOIN udc_details uom ON qod.unit_of_measure = uom.id
      WHERE qod.quote_order_header_id = ? AND qod.company = ?
    ''';

    final maps = await db.rawQuery(query, [headerId, companyId]);

    return maps.map((map) => QuotationOrderDetail.fromMap(map)).toList();
  }

  // ============ VALIDATION & BUSINESS LOGIC ============

  // ✅ ADDING MISSING: Check if FS number exists
  Future<bool> doesFsNumberExist(String fsNumber, int companyId) async {
    final db = await _db;
    final result = await db.query(
      'quote_order_header',
      where: 'fs_number = ? AND company = ?',
      whereArgs: [fsNumber, companyId],
    );
    return result.isNotEmpty;
  }

  // ✅ ADDING MISSING: Get next available order number with validation
  Future<int> getValidNextOrderNumber(int companyId) async {
    final db = await _db;

    // Get the maximum order number
    final result = await db.rawQuery(
      'SELECT MAX(order_number) as max_order FROM quote_order_header WHERE company = ?',
      [companyId],
    );

    final maxOrder = result.first['max_order'] as int?;
    var nextOrderNumber = (maxOrder ?? 0) + 1;

    // Check if the next order number already exists (for edge cases)
    var exists = true;
    var attempts = 0;

    while (exists && attempts < 100) {
      final checkResult = await db.query(
        'quote_order_header',
        where: 'order_number = ? AND company = ?',
        whereArgs: [nextOrderNumber, companyId],
      );

      exists = checkResult.isNotEmpty;
      if (exists) {
        nextOrderNumber++;
        attempts++;
      }
    }

    return nextOrderNumber;
  }
}
