// repositories/sales_order_header_repository.dart
import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:savvy_stock/core/repositories/base_repo.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/sales/sales_order/detail/model/sales_order_detail.dart';
import 'package:savvy_stock/features/sales/sales_order/header/model/credit_receipt_model.dart';
import 'package:savvy_stock/features/sales/sales_order/header/model/sales_order_header.dart';
import 'package:sqflite/sqflite.dart';

class SalesOrderHeaderRepository  extends BaseRepository{
  @override
  final LocalDatabaseService databaseService;
  SalesOrderHeaderRepository({required this.databaseService});

  Future<Database> get _db async => LocalDatabaseService().database;

  // Create

  Future<int> createSalesOrderHeader(SalesOrderHeader header) async {
    final db = await _db;
    try {
      final headerMap = header.toMap();

      // Log the data being inserted for debugging
      if (kDebugMode) {
        developer.log(
          'DEBUG: Creating sales order header with data: $headerMap',
        );
      }

      final id = await db.insert(
        'sales_order_header', withSyncKey(headerMap),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      headerMap['id'] = id;
      captureSync(
        tableName: 'sales_order_header',
        entityMap: headerMap,
        entityId: id.toString(),
        operation: 'INSERT',
        company: header.company?.toString(),
      );

      if (kDebugMode) {
        developer.log(
          'DEBUG: Sales order header created successfully with ID: $id',
        );
      }
      return id;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        developer.log('ERROR: Failed to create sales order header: $e');
        developer.log('ERROR: Stack trace: $stackTrace');
        developer.log('ERROR: Header data: ${header.toMap()}');
      }
      throw Exception('Failed to create sales order header: $e');
    }
  }

  // Read
  Future<SalesOrderHeader?> getSalesOrderHeaderById(int id) async {
    final db = await _db;
    final query = '''
        SELECT 
          soh.*,
          cu.customer_name as customer_bill_to_name,
          ct.customer_name as customer_table_name,
          udc.description_1 as payment_status_description,
          udc.detail_code as payment_status_code ,
          pi.description_1 as payment_instrument_description,
          pi.detail_code as payment_instrument_code,
          ot.description_1 as order_type_description,
          ot.detail_code as order_type_code
        FROM sales_order_header soh
        LEFT JOIN customer_table cu ON soh.customer_bill_to = cu.id
        LEFT JOIN customer_table ct ON soh.customer_table_id = ct.id
        LEFT JOIN udc_details pi ON soh.payment_instrument = pi.id
        LEFT JOIN udc_details udc ON soh.payment_status = udc.id
        LEFT JOIN udc_details ot ON soh.order_type = ot.id
        WHERE soh.id = ?
      ''';
    final maps = await db.rawQuery(query, [id]);
    if (maps.isNotEmpty) {
      return SalesOrderHeader.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateSalesOrderHeader(SalesOrderHeader header) async {
    final db = await _db;
    try {
      final result = await db.update(
        'sales_order_header',
        header.toMap(),
        where: 'id = ?',
        whereArgs: [header.id],
      );
      captureSync(
        tableName: 'sales_order_header',
        entityMap: header.toMap(),
        entityId: header.id.toString(),
        operation: 'UPDATE',
        company: header.company?.toString(),
      );
      return result;
    } catch (e) {
      throw Exception('Failed to update sales order: $e');
    }
  }

  // Delete
  Future<int> deleteSalesOrderHeader(int id) async {
    final db = await _db;
    // Fetch full row data BEFORE deleting
    final headerRows = await db.query(
      'sales_order_header',
      where: 'id = ?',
      whereArgs: [id],
    );
    final result = await db.delete(
      'sales_order_header',
      where: 'id = ?',
      whereArgs: [id],
    );
    // Capture sync with full row data
    for (final row in headerRows) {
    captureSync(
      tableName: 'sales_order_header',
      entityMap: row,
      entityId: row['id'].toString(),
      operation: 'DELETE',
      company: row['company'].toString(),
    );
    }
    return result;
  }

  // Get all with filters
  Future<List<SalesOrderHeader>> getSalesOrderHeaders({
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
      where += ' AND soh.company = ?';
      whereArgs.add(companyId);
    }

    if (customerBillTo != null) {
      where += ' AND soh.customer_bill_to = ?';
      whereArgs.add(customerBillTo);
    }

    if (fsNumber != null && fsNumber.isNotEmpty) {
      where += ' AND soh.fs_number = ?';
      whereArgs.add(fsNumber);
    }

    if (startDate != null) {
      where += ' AND soh.order_date >= ?';
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      where += ' AND soh.order_date <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    if (!includeVoided) {
      where += ' AND (soh.void_indicator IS NULL OR soh.void_indicator = "")';
    } else if (voidIndicator != null) {
      if (voidIndicator) {
        where +=
            ' AND soh.void_indicator IS NOT NULL AND soh.void_indicator != ""';
      } else {
        where += ' AND (soh.void_indicator IS NULL OR soh.void_indicator = "")';
      }
    }
    final query =
        '''
        SELECT 
          soh.*,
          cu.customer_name as customer_bill_to_name,
          ct.customer_name as customer_table_name,
          udc.detail_code as payment_status_code ,
          udc.description_1 as payment_instrument_description,
          pi.detail_code as payment_instrument_code,
          pi.description_1 as payment_instrument_description,
          ot.detail_code as order_type_code,
          ot.description_1 as order_type_description
        FROM sales_order_header soh
        LEFT JOIN customer_table cu ON soh.customer_bill_to = cu.id
        LEFT JOIN customer_table ct ON soh.customer_table_id = ct.id
        LEFT JOIN udc_details pi ON soh.payment_instrument = pi.id
        LEFT JOIN udc_details udc ON soh.payment_status = udc.id
        LEFT JOIN udc_details ot ON soh.order_type = ot.id
        WHERE  $where
        ORDER BY soh.id DESC
      ''';

    final maps = await db.rawQuery(query, whereArgs);

    return maps.map((map) => SalesOrderHeader.fromMap(map)).toList();
  }

  // Get next order number
  Future<int> getNextOrderNumber(int companyId) async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT MAX(order_number) as max_order FROM sales_order_header WHERE company = ?',
      [companyId],
    );

    final maxOrder = result.first['max_order'] as int?;
    return (maxOrder ?? 0) + 1;
  }

  // Get credit sales orders
  Future<List<SalesOrderHeader>> getCreditSalesOrders(int companyId) async {
    final db = await _db;
    final query = '''
        SELECT 
          soh.*,
          cu.customer_name as customer_bill_to_name,
          ct.customer_name as customer_table_name,
          ps.detail_code as payment_status_code ,
          ps.description_1 as payment_status_description,
          ot.detail_code as order_type_code,
          ot.description_1 as order_type_description,
          pi.description_1 as payment_instrument_description,
          pi.detail_code as payment_instrument_code
        FROM sales_order_header soh
        LEFT JOIN customer_table cu ON soh.customer_bill_to = cu.id
        LEFT JOIN customer_table ct ON soh.customer_table_id = ct.id
        LEFT JOIN udc_details pi ON soh.payment_instrument = pi.id
        LEFT JOIN udc_details ot ON soh.order_type = ot.id
        LEFT JOIN udc_details ps ON soh.payment_status = ps.id
        WHERE soh.company = ? AND soh.payment_term IS NOT NULL AND soh.payment_method = 'Credit' AND (soh.void_indicator IS NULL OR soh.void_indicator = "")
        ORDER BY soh.id DESC
      ''';
    final maps = await db.rawQuery(query, [companyId]);

    return maps.map((map) => SalesOrderHeader.fromMap(map)).toList();
  }

  // Void sales order
  Future<int> voidSalesOrder(
    int id,
    String voidIndicator, {
    String? commentIfVoid,
  }) async {
    final db = await _db;
    final result = await db.update(
      'sales_order_header',
      {
        'void_indicator': voidIndicator,
        if (commentIfVoid != null) 'comment_ifVoid': commentIfVoid,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    final header = await getById(id);
    if (header != null) {
      captureSync(
        tableName: 'sales_order_header',
        entityMap: header.toMap(),
        entityId: id.toString(),
        operation: 'UPDATE',
        company: header.company?.toString(),
      );
    }
    return result;
  }

  // Get voided sales orders
  Future<List<SalesOrderHeader>> getVoidedSalesOrders(int companyId) async {
    final db = await _db;
    final maps = await db.query(
      'sales_order_header',
      where:
          'company = ? AND void_indicator IS NOT NULL AND void_indicator != ""',
      whereArgs: [companyId],
      orderBy: 'id DESC',
    );

    return maps.map((map) => SalesOrderHeader.fromMap(map)).toList();
  }

  // Complex Query Builder (replacing Java's dynamicQueryGeneral)
  Future<List<SalesOrderHeader>> _buildDynamicQuery({
    required Map<String, dynamic> queryParams,
    required Map<String, dynamic> parameterQueries,
    required int companyId,
    String orderBy = 'id DESC',
  }) async {
    final db = await _db;

    String whereClause = 'company = ?';
    List<dynamic> whereArgs = [companyId];

    // Build WHERE clause dynamically like Java controller
    for (final entry in queryParams.entries) {
      if (entry.value != null) {
        whereClause += ' AND ${entry.key}';
        if (parameterQueries.containsKey(entry.key)) {
          whereArgs.add(parameterQueries[entry.key]);
        }
      }
    }

    final maps = await db.query(
      'sales_order_header',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: orderBy,
    );

    return maps.map((map) => SalesOrderHeader.fromMap(map)).toList();
  }

  // Complex filtering like Java's filterList method
  Future<List<SalesOrderHeader>> filterSalesOrders({
    required int companyId,
    int? customerBillTo,
    String? fsNumber,
    DateTime? orderDate,
    bool includeVoided = false,
  }) async {
    final queryParams = <String, dynamic>{};
    final parameterQueries = <String, dynamic>{};

    if (customerBillTo != null) {
      queryParams['customer_bill_to = ?'] = customerBillTo;
      parameterQueries['customer_bill_to = ?'] = customerBillTo;
    }

    if (fsNumber != null && fsNumber.isNotEmpty) {
      queryParams['fs_number = ?'] = fsNumber;
      parameterQueries['fs_number = ?'] = fsNumber;
    }

    if (orderDate != null) {
      queryParams['order_date = ?'] = orderDate.toIso8601String();
      parameterQueries['order_date = ?'] = orderDate.toIso8601String();
    }

    if (!includeVoided) {
      queryParams['(void_indicator IS NULL OR void_indicator = "")'] = null;
    }

    return await _buildDynamicQuery(
      queryParams: queryParams,
      parameterQueries: parameterQueries,
      companyId: companyId,
    );
  }

  // Complex filtering for voided orders like Java's filterListForVoid
  Future<List<SalesOrderHeader>> filterVoidedSalesOrders({
    required int companyId,
    int? customerBillTo,
    String? referenceNote3,
    String? fsNumber,
    DateTime? orderDate,
  }) async {
    final queryParams = <String, dynamic>{};
    final parameterQueries = <String, dynamic>{};

    if (customerBillTo != null) {
      queryParams['customer_bill_to = ?'] = customerBillTo;
      parameterQueries['customer_bill_to = ?'] = customerBillTo;
    }

    if (referenceNote3 != null && referenceNote3.isNotEmpty) {
      queryParams['reference_note3 = ?'] = referenceNote3;
      parameterQueries['reference_note3 = ?'] = referenceNote3;
    }

    if (fsNumber != null && fsNumber.isNotEmpty) {
      queryParams['fs_number = ?'] = fsNumber;
      parameterQueries['fs_number = ?'] = fsNumber;
    }

    if (orderDate != null) {
      queryParams['order_date = ?'] = orderDate.toIso8601String();
      parameterQueries['order_date = ?'] = orderDate.toIso8601String();
    }

    queryParams['void_indicator IS NOT NULL AND void_indicator != ""'] = null;

    return await _buildDynamicQuery(
      queryParams: queryParams,
      parameterQueries: parameterQueries,
      companyId: companyId,
    );
  }

  // Complex date range query like Java's getItems method
  Future<List<SalesOrderHeader>> getSalesOrdersWithDateRange({
    required int companyId,
    int? customerBillTo,
    String? fsNumber,
    String? proformaReference,
    DateTime? startDate,
    DateTime? endDate,
    bool includeVoided = false,
  }) async {
    final db = await _db;

    String where = 'company = ?';
    List<dynamic> whereArgs = [companyId];

    if (!includeVoided) {
      where += ' AND (void_indicator IS NULL OR void_indicator = "")';
    }

    if (customerBillTo != null) {
      where += ' AND customer_bill_to = ?';
      whereArgs.add(customerBillTo);
    }

    if (fsNumber != null && fsNumber.isNotEmpty) {
      where += ' AND fs_number = ?';
      whereArgs.add(fsNumber);
    }

    if (proformaReference != null && proformaReference.isNotEmpty) {
      where += ' AND proforma_reference = ?';
      whereArgs.add(proformaReference);
    }

    if (startDate != null && endDate != null) {
      where += ' AND order_date BETWEEN ? AND ?';
      whereArgs.add(startDate.toIso8601String());
      whereArgs.add(endDate.toIso8601String());
    } else if (startDate != null) {
      where += ' AND order_date >= ?';
      whereArgs.add(startDate.toIso8601String());
    } else if (endDate != null) {
      where += ' AND order_date <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    where += ' ORDER BY id DESC';

    final maps = await db.query(
      'sales_order_header',
      where: where,
      whereArgs: whereArgs,
    );

    return maps.map((map) => SalesOrderHeader.fromMap(map)).toList();
  }

  // FS Number Generation
  Future<String> generateNextFsNumber(int companyId, int branchId) async {
    final db = await _db;

    final result = await db.rawQuery(
      '''
      SELECT MAX(CAST(fs_number AS INTEGER)) as max_fs 
      FROM sales_order_header 
      WHERE company = ? 
    ''',
      [companyId],
    );

    final maxFs = result.first['max_fs'] as int?;
    final nextFs = (maxFs ?? 0) + 1;

    return nextFs.toString().padLeft(8, '0');
  }

  /// Generate invoice number using the Java generateReference pattern.
  /// Format: PREFIX-00000001-POSTFIX
  /// Queries fs_table for prefix/postfix by branch + company,
  /// then finds MAX(invoice_number) matching the pattern in the given [tableName].
  Future<String> generateInvoiceNumber(
    int companyId,
    int branchId,
    String tableName,
  ) async {
    final db = await _db;

    // Step 1: Query fs_table for prefix/postfix
    final fsResult = await db.query(
      'fs_table',
      where: 'company = ? AND branch = ?',
      whereArgs: [companyId, branchId],
      limit: 1,
    );

    if (fsResult.isEmpty) {
      // User requested no fallback checking, but if fs_table is empty, we must return something.
      // We'll return an empty string or a generic error-like string.
      // However, usually prefix/postfix are mandatory for this logic.
      return "";
    }

    final fsRow = fsResult.first;
    final prefix = fsRow['prefix_up_to_three'] as String? ?? "";
    final postfix = fsRow['postfix_up_to_four'] as String? ?? "";

    // Step 2: Query MAX(invoice_number) matching pattern PREFIX-%-POSTFIX
    final pattern = '$prefix-%-$postfix';
    final maxResult = await db.rawQuery(
      '''
      SELECT MAX(invoice_number) as last_invoice
      FROM $tableName
      WHERE invoice_number LIKE ? AND company = ?
    ''',
      [pattern, companyId],
    );

    int nextNumber = 1;
    final lastInvoice = maxResult.first['last_invoice'] as String?;
    if (lastInvoice != null && lastInvoice.isNotEmpty) {
      final parts = lastInvoice.split('-');
      if (parts.length >= 2) {
        // parts[1] is the sequential number part
        nextNumber = (int.tryParse(parts[1]) ?? 0) + 1;
      }
    }

    // Step 3: Format as PREFIX-00000001-POSTFIX
    return '$prefix-${nextNumber.toString().padLeft(8, '0')}-$postfix';
  }

  // Sales Order Details for Void Processing
  Future<List<SalesOrderDetail>> getSalesOrderDetailsByHeaderId(
    int headerId,
  ) async {
    final db = await _db;

    final maps = await db.query(
      'sales_order_details',
      where: 'sales_order_header_id = ?',
      whereArgs: [headerId],
    );

    return maps.map((map) => SalesOrderDetail.fromMap(map)).toList();
  }

  // Find by order number and type (complex business logic)
  Future<SalesOrderHeader?> findByOrderNumberAndType({
    required int orderNumber,
    required int orderType,
    required int companyId,
  }) async {
    final db = await _db;

    final maps = await db.query(
      'sales_order_header',
      where:
          'company = ? AND order_number = ? AND order_type = ? AND (void_indicator IS NULL OR void_indicator = "")',
      whereArgs: [companyId, orderNumber, orderType],
    );

    return maps.isNotEmpty ? SalesOrderHeader.fromMap(maps.first) : null;
  }

  // Get sales orders for specific employee with void status
  Future<List<SalesOrderHeader>> getSalesOrdersByEmployee({
    required int companyId,
    required int employeeId,
    bool? voided,
  }) async {
    final db = await _db;

    String where = 'company = ? AND employees_id = ?';
    List<dynamic> whereArgs = [companyId, employeeId];

    if (voided != null) {
      if (voided) {
        where += ' AND void_indicator IS NOT NULL AND void_indicator != ""';
      } else {
        where += ' AND (void_indicator IS NULL OR void_indicator = "")';
      }
    }

    final maps = await db.query(
      'sales_order_header',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'id DESC',
    );

    return maps.map((map) => SalesOrderHeader.fromMap(map)).toList();
  }

  // Complex credit sales query
  Future<List<SalesOrderHeader>> getCreditSalesWithOpenAmount({
    required int companyId,
    double? minOpenAmount,
  }) async {
    final db = await _db;

    String where =
        'company = ? AND payment_term IS NOT NULL AND amount_open > 0 AND (void_indicator IS NULL OR void_indicator = "")';
    List<dynamic> whereArgs = [companyId];

    if (minOpenAmount != null) {
      where += ' AND amount_open >= ?';
      whereArgs.add(minOpenAmount);
    }

    final maps = await db.query(
      'sales_order_header',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'credit_date_topay ASC',
    );

    return maps.map((map) => SalesOrderHeader.fromMap(map)).toList();
  }

  // Stock Reversal for Voided Orders
  Future<void> reverseStockQuantity(int itemInBranchId, double quantity, int companyId) async {
    final db = await _db;

    // Get current quantity
    final currentResult = await db.query(
      'items_in_branch',
      where: 'id = ? AND company = ?',
      whereArgs: [itemInBranchId, companyId],
    );

    if (currentResult.isNotEmpty) {
      final currentQty = currentResult.first['quantity_available'] as double;
      final newQty = currentQty + quantity; // Add back the quantity
      await db.update(
        'items_in_branch',
        {'quantity_available': newQty},
        where: 'id = ? AND company = ?',
        whereArgs: [itemInBranchId, companyId],
      );
      captureSync(
        tableName: 'items_in_branch',
        entityMap: {'id': itemInBranchId, 'company': companyId, 'quantity_available': newQty},
        entityId: itemInBranchId.toString(),
        operation: 'UPDATE',
        company: companyId.toString(),
      );
    }
  }

  // Bulk operations like Java's removeList
  Future<int> deleteMultiple(List<int> ids) async {
    if (ids.isEmpty) return 0;

    final db = await _db;
    final placeholders = List.generate(ids.length, (_) => '?').join(',');

    return await db.delete(
      'sales_order_header',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
  }

  // Update multiple records
  Future<int> updateMultiple(List<SalesOrderHeader> headers) async {
    final db = await _db;
    final batch = db.batch();

    for (final header in headers) {
      batch.update(
        'sales_order_header',
        header.toMap(),
        where: 'id = ?',
        whereArgs: [header.id],
      );
    }

    final results = await batch.commit();
    return results.length;
  }

  // Get sales statistics - complex aggregation like Java would do
  Future<Map<String, dynamic>> getSalesStatistics({
    required int companyId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await _db;

    final result = await db.rawQuery(
      '''
      SELECT 
        COUNT(*) as total_orders,
        SUM(amount_total) as total_amount,
        AVG(amount_total) as average_order,
        SUM(tax) as total_tax,
        SUM(withhold_amount) as total_withholding,
        SUM(discount_amount) as total_discount,
        COUNT(CASE WHEN payment_term IS NOT NULL THEN 1 END) as credit_orders,
        SUM(CASE WHEN payment_term IS NOT NULL THEN amount_open ELSE 0 END) as total_credit_open
      FROM sales_order_header 
      WHERE company = ? 
        AND order_date BETWEEN ? AND ?
        AND (void_indicator IS NULL OR void_indicator = "")
    ''',
      [companyId, startDate.toIso8601String(), endDate.toIso8601String()],
    );

    return result.isNotEmpty ? result.first : {};
  }

  // Original CRUD methods
  Future<int> create(SalesOrderHeader header) async {
    final db = await _db;
    try {
      final id = await db.insert('sales_order_header', withSyncKey(header.toMap()));
      captureSync(
        tableName: 'sales_order_header',
        entityMap: header.toMap(),
        entityId: id.toString(),
        operation: 'INSERT',
        company: header.company?.toString(),
      );
      return id;
    } catch (e) {
      throw Exception('Failed to create sales order header: $e');
    }
  }

  Future<SalesOrderHeader?> getById(int id) async {
    final db = await _db;
    final maps = await db.query(
      'sales_order_header',
      where: 'id = ?',
      whereArgs: [id],
    );
    return maps.isNotEmpty ? SalesOrderHeader.fromMap(maps.first) : null;
  }

  Future<int> update(SalesOrderHeader header) async {
    final db = await _db;
    try {
      final result = await db.update(
        'sales_order_header',
        header.toMap(),
        where: 'id = ?',
        whereArgs: [header.id],
      );
      captureSync(
        tableName: 'sales_order_header',
        entityMap: header.toMap(),
        entityId: header.id.toString(),
        operation: 'UPDATE',
        company: header.company?.toString(),
      );
      return result;
    } catch (e) {
      throw Exception('Failed to update sales order: $e');
    }
  }

  Future<int> delete(int id, int companyId) async {
    final db = await _db;
    // Fetch full row data BEFORE deleting
    final headerRows = await db.query(
      'sales_order_header',
      where: 'id = ? AND company = ?',
      whereArgs: [id, companyId],
    );
    final result = await db.delete(
      'sales_order_header',
      where: 'id = ? AND company = ?',
      whereArgs: [id, companyId],
    );
    // Capture sync with full row data
    for (final row in headerRows) {
    captureSync(
      tableName: 'sales_order_header',
      entityMap: row,
      entityId: row['id'].toString(),
      operation: 'DELETE',
      company: companyId.toString(),
    );
    }
    return result;
  }

  Future<List<SalesOrderHeader>> getAll({required int companyId}) async {
    final db = await _db;
    final maps = await db.query(
      'sales_order_header',
      where: 'company = ?',
      whereArgs: [companyId],
      orderBy: 'id DESC',
    );
    return maps.map((map) => SalesOrderHeader.fromMap(map)).toList();
  }

  //get sales order by fs number which it doesnt have void indicator
  Future<SalesOrderHeader?> getSalesOrderByFsNumberAndInvoiceNumber(
    String fsNumber,
    int companyId, {
    String? invoiceNumber,
  }) async {
    final db = await _db;

    String whereClause = 'soh.company = ? AND soh.void_indicator IS NULL';
    List<dynamic> whereArgs = [companyId];

    if (fsNumber.isNotEmpty) {
      whereClause += ' AND soh.fs_number = ?';
      whereArgs.add(fsNumber);
    }

    if (invoiceNumber != null && invoiceNumber.isNotEmpty) {
      whereClause += ' AND soh.invoice_number = ?';
      whereArgs.add(invoiceNumber);
    }

    final query =
        '''
      SELECT 
        soh.*,
        cu.customer_name as customer_bill_to_name,
        ct.customer_name as customer_table_name
      FROM sales_order_header soh
      INNER JOIN customer_table cu ON soh.customer_bill_to = cu.id
      INNER JOIN customer_table ct ON soh.customer_table_id = ct.id
      WHERE $whereClause
    ''';

    final maps = await db.rawQuery(query, whereArgs);
    return maps.isNotEmpty ? SalesOrderHeader.fromMap(maps.first) : null;
  }

  // In your SalesOrderHeaderRepository implementation, add:
  Future<List<CreditReceipt>> getCreditReceipts({
    required int companyId,
    int? soHeaderId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _db;

    try {
      String where = 'crt.company = ?';
      List<dynamic> whereArgs = [companyId];

      if (soHeaderId != null) {
        where += ' AND crt.so_header = ?';
        whereArgs.add(soHeaderId);
      }

      if (startDate != null) {
        where += ' AND crt.date_receipt >= ?';
        whereArgs.add(startDate.toIso8601String());
      }

      if (endDate != null) {
        where += ' AND crt.date_receipt <= ?';
        whereArgs.add(endDate.toIso8601String());
      }

      final query =
          '''
        SELECT 
          crt.*,
          soh.fs_number as fs_number ,
          cb.customer_name as customer_bill_to_name,
          ct.customer_name as customer_table_name,
          pi.description_1 as payment_instrument_description
        FROM credit_receipt_table crt
        LEFT JOIN sales_order_header soh ON crt.so_header = soh.id
        LEFT JOIN customer_table ct ON soh.customer_table_id = ct.id
        LEFT JOIN customer_table cb ON soh.customer_bill_to = cb.id
        LEFT JOIN udc_details pi ON crt.payment_instrument = pi.id
        WHERE $where
        ORDER BY crt.date_receipt DESC
      ''';

      final maps = await db.rawQuery(query, whereArgs);
      return maps.map((map) => CreditReceipt.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get credit receipts: $e');
    }
  }

  Future<int> createCreditReceipt(CreditReceipt receipt) async {
    final db = await _db;
    try {
      final id = await db.insert('credit_receipt_table', withSyncKey(receipt.toMap()));
      captureSync(
        tableName: 'credit_receipt_table',
        entityMap: receipt.toMap(),
        entityId: id.toString(),
        operation: 'INSERT',
        company: receipt.company?.toString(),
      );
      return id;
    } catch (e) {
      throw Exception('Failed to create credit receipt: $e');
    }
  }

  Future<void> updateCreditReceipt(CreditReceipt receipt) async {
    final db = await _db;
    try {
      await db.update(
        'credit_receipt_table',
        receipt.toMap(),
        where: 'id = ?',
        whereArgs: [receipt.id],
      );
      captureSync(
        tableName: 'credit_receipt_table',
        entityMap: receipt.toMap(),
        entityId: receipt.id.toString(),
        operation: 'UPDATE',
        company: receipt.company?.toString(),
      );
    } catch (e) {
      throw Exception('Failed to update credit receipt: $e');
    }
  }

  Future<void> deleteCreditReceipt(int receiptId, int companyId) async {
    final db = await _db;
    final receiptRows = await db.query(
      'credit_receipt_table',
      where: 'id = ? AND company = ?',
      whereArgs: [receiptId, companyId],
    );
    try {
      await db.delete(
        'credit_receipt_table',
        where: 'id = ?',
        whereArgs: [receiptId],
      );
      // Capture sync with full row data
      for (final row in receiptRows) {
      captureSync(
        tableName: 'credit_receipt_table',
        entityMap: row,
        entityId: row['id'].toString(),
        operation: 'DELETE',
        company: companyId.toString(),
      );
      }
    } catch (e) {
      throw Exception('Failed to delete credit receipt: $e');
    }
  }

  Future<List<CreditReceipt>> filterCreditReceipts({
    required int companyId,
    int? customerId,
    String? fsNumber,
  }) async {
    final db = await _db;

    try {
      String where = 'crt.company = ?';
      List<dynamic> whereArgs = [companyId];

      if (customerId != null) {
        where += ' AND soh.customer_table_id = ?';
        whereArgs.add(customerId);
      }

      if (fsNumber != null) {
        where += ' AND soh.fs_number = ?';
        whereArgs.add(fsNumber);
      }

      final query =
          '''
        SELECT 
          crt.*,
           soh.order_number as order_number,
           cb.customer_name as customer_bill_to_name,
           ct.customer_name as customer_table_name,
          soh.fs_number as fs_number ,
          pi.description_1 as payment_instrument_description
        FROM credit_receipt_table crt
        LEFT JOIN sales_order_header soh ON crt.so_header = soh.id
        LEFT JOIN customer_table ct ON soh.customer_table_id = ct.id
        LEFT JOIN customer_table cb ON soh.customer_bill_to = cb.id
        LEFT JOIN udc_details pi ON crt.payment_instrument = pi.id
        WHERE $where
        ORDER BY crt.date_receipt DESC
      ''';

      final maps = await db.rawQuery(query, whereArgs);
      return maps.map((map) => CreditReceipt.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to filter credit receipts: $e');
    }
  }

  Future<double> getTotalCreditReceiptsForHeader(int soHeaderId) async {
    final db = await _db;

    try {
      final result = await db.rawQuery(
        '''
        SELECT SUM(receipt_amount) as total_received
        FROM credit_receipt_table
        WHERE so_header = ?
        ''',
        [soHeaderId],
      );

      final total = result.first['total_received'] as double?;
      return total ?? 0.0;
    } catch (e) {
      throw Exception('Failed to get total credit receipts: $e');
    }
  }
}
