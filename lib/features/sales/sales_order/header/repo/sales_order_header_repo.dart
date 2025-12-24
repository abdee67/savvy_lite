// repositories/sales_order_header_repository.dart
import 'dart:async';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/sales/sales_order/detail/model/sales_order_detail.dart';
import 'package:savvy_stock/features/sales/sales_order/header/model/credit_receipt_model.dart';
import 'package:savvy_stock/features/sales/sales_order/header/model/sales_order_header.dart';
import 'package:sqflite/sqflite.dart';

class SalesOrderHeaderRepository {
  static final SalesOrderHeaderRepository _instance =
      SalesOrderHeaderRepository._internal();
  factory SalesOrderHeaderRepository() => _instance;
  SalesOrderHeaderRepository._internal();

  Future<Database> get _db async => LocalDatabaseService().database;

  // Create

  Future<int> createSalesOrderHeader(SalesOrderHeader header) async {
    final db = await _db;
    try {
      final headerMap = header.toMap();

      // Log the data being inserted for debugging
      print('DEBUG: Creating sales order header with data: $headerMap');

      final id = await db.insert(
        'sales_order_header',
        headerMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      print('DEBUG: Sales order header created successfully with ID: $id');
      return id;
    } catch (e, stackTrace) {
      print('ERROR: Failed to create sales order header: $e');
      print('ERROR: Stack trace: $stackTrace');
      print('ERROR: Header data: ${header.toMap()}');
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
          udc.description_1 as payment_status_description,
          udc.detail_code as payment_status_code ,
          pi.description_1 as payment_instrument_description,
          pi.detail_code as payment_instrument_code,
          ot.description_1 as order_type_description,
          ot.detail_code as order_type_code
        FROM sales_order_header soh
        LEFT JOIN customer_table cu ON soh.customer_bill_to = cu.id
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

  // Update
  Future<int> updateSalesOrderHeader(SalesOrderHeader header) async {
    final db = await _db;
    try {
      return await db.update(
        'sales_order_header',
        header.toMap(),
        where: 'id = ?',
        whereArgs: [header.id],
      );
    } catch (e) {
      throw Exception('Failed to update sales order: $e');
    }
  }

  // Delete
  Future<int> deleteSalesOrderHeader(int id) async {
    final db = await _db;
    return await db.delete(
      'sales_order_header',
      where: 'id = ?',
      whereArgs: [id],
    );
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
          udc.detail_code as payment_status_code ,
          udc.description_1 as payment_instrument_description,
          pi.detail_code as payment_instrument_code,
          pi.description_1 as payment_instrument_description,
          ot.detail_code as order_type_code,
          ot.description_1 as order_type_description
        FROM sales_order_header soh
        LEFT JOIN customer_table cu ON soh.customer_bill_to = cu.id
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
          ps.detail_code as payment_status_code ,
          ps.description_1 as payment_status_description,
          ot.detail_code as order_type_code,
          ot.description_1 as order_type_description,
          pi.description_1 as payment_instrument_description,
          pi.detail_code as payment_instrument_code
        FROM sales_order_header soh
        LEFT JOIN customer_table cu ON soh.customer_bill_to = cu.id
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
  Future<int> voidSalesOrder(int id, String voidIndicator) async {
    final db = await _db;
    return await db.update(
      'sales_order_header',
      {'void_indicator': voidIndicator},
      where: 'id = ?',
      whereArgs: [id],
    );
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
  Future<void> reverseStockQuantity(int itemInBranchId, double quantity) async {
    final db = await _db;

    // Get current quantity
    final currentResult = await db.query(
      'items_in_branch',
      where: 'id = ?',
      whereArgs: [itemInBranchId],
    );

    if (currentResult.isNotEmpty) {
      final currentQty = currentResult.first['quantity_available'] as double;
      final newQty = currentQty + quantity; // Add back the quantity
      await db.update(
        'items_in_branch',
        {'quantity_available': newQty},
        where: 'id = ?',
        whereArgs: [itemInBranchId],
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
      return await db.insert('sales_order_header', header.toMap());
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
      return await db.update(
        'sales_order_header',
        header.toMap(),
        where: 'id = ?',
        whereArgs: [header.id],
      );
    } catch (e) {
      throw Exception('Failed to update sales order: $e');
    }
  }

  Future<int> delete(int id) async {
    final db = await _db;
    return await db.delete(
      'sales_order_header',
      where: 'id = ?',
      whereArgs: [id],
    );
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
  Future<SalesOrderHeader?> getSalesOrderByFsNumber(
    String fsNumber,
    int companyId,
  ) async {
    final db = await _db;
    final maps = await db.query(
      'sales_order_header',
      where: 'fs_number = ? AND void_indicator IS NULL AND company = ?',
      whereArgs: [fsNumber, companyId],
    );
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
          pi.description_1 as payment_instrument_description
        FROM credit_receipt_table crt
        LEFT JOIN sales_order_header soh ON crt.so_header = soh.id
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
      return await db.insert('credit_receipt_table', receipt.toMap());
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
    } catch (e) {
      throw Exception('Failed to update credit receipt: $e');
    }
  }

  Future<void> deleteCreditReceipt(int receiptId) async {
    final db = await _db;
    try {
      await db.delete(
        'credit_receipt_table',
        where: 'id = ?',
        whereArgs: [receiptId],
      );
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
          soh.fs_number as fs_number ,
          pi.description_1 as payment_instrument_description
        FROM credit_receipt_table crt
        LEFT JOIN sales_order_header soh ON crt.so_header = soh.id
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

  // ============================================================================
  // SALES TRANSACTION REPORT METHODS
  // ============================================================================

  /// Get sales transaction report (header-level) with pagination
  /// Equivalent to Java's getLazyItemsSales
  Future<Map<String, dynamic>> getSalesTransactionReport({
    required int companyId,
    required int page,
    required int pageSize,
    int? customerId,
    int? itemId,
    String? fsNumber,
    String? proformaReference,
    DateTime? startDate,
    DateTime? endDate,
    String? salesType,
    bool? voidIndicator,
  }) async {
    final db = await _db;

    try {
      // Build WHERE clause
      String where = 'soh.company = ?';
      List<dynamic> whereArgs = [companyId];

      if (customerId != null) {
        where += ' AND soh.customer_bill_to = ?';
        whereArgs.add(customerId);
      }

      if (itemId != null) {
        // For item filter, we need to check if any detail has this item
        where +=
            ' AND EXISTS (SELECT 1 FROM sales_order_details sod '
            'WHERE sod.sales_order_header_id = soh.id AND sod.items_table_id = ?)';
        whereArgs.add(itemId);
      }

      if (fsNumber != null && fsNumber.isNotEmpty) {
        where += ' AND soh.fs_number = ?';
        whereArgs.add(fsNumber);
      }

      if (proformaReference != null && proformaReference.isNotEmpty) {
        where += ' AND soh.proforma_reference = ?';
        whereArgs.add(proformaReference);
      }

      if (startDate != null && endDate != null) {
        where += ' AND soh.order_date BETWEEN ? AND ?';
        whereArgs.add(startDate.toIso8601String());
        whereArgs.add(endDate.toIso8601String());
      } else if (startDate != null) {
        where += ' AND soh.order_date >= ?';
        whereArgs.add(startDate.toIso8601String());
      } else if (endDate != null) {
        where += ' AND soh.order_date <= ?';
        whereArgs.add(endDate.toIso8601String());
      }

      if (salesType != null && salesType.isNotEmpty) {
        where += ' AND soh.sales_type = ?';
        whereArgs.add(salesType);
      }

      if (voidIndicator != null) {
        if (voidIndicator) {
          where +=
              ' AND soh.void_indicator IS NOT NULL AND soh.void_indicator != ""';
        } else {
          where +=
              ' AND (soh.void_indicator IS NULL OR soh.void_indicator = "")';
        }
      } else {
        // Default: exclude voided orders
        where += ' AND (soh.void_indicator IS NULL OR soh.void_indicator = "")';
      }

      // Get total count
      final countQuery =
          '''
        SELECT COUNT(*) as total
        FROM sales_order_header soh
        WHERE $where
      ''';
      final countResult = await db.rawQuery(countQuery, whereArgs);
      final totalCount = countResult.first['total'] as int;

      // Get paginated data
      final offset = (page - 1) * pageSize;
      final dataQuery =
          '''
        SELECT 
          soh.*,
          cu.customer_name as customer_bill_to_name,
          cu.phone_number as customer_bill_to_phone,
          cu.tin_number as customer_bill_to_tin,
          emp.name_first as employee_name_first,
          emp.name_middle as employee_name_middle,
          emp.name_last as employee_name_last,
          emp.phone as employee_phone,
          emp.email as employee_email,
          ps.detail_code as payment_status_code,
          ps.description_1 as payment_status_description,
          (soh.amount_total - soh.amount_cost) as item_wise_gross_profit,
          pi.description_1 as payment_instrument_description,
          pi.detail_code as payment_instrument_code,
          ot.description_1 as order_type_description,
          ot.detail_code as order_type_code
        FROM sales_order_header soh
        LEFT JOIN customer_table cu ON soh.customer_bill_to = cu.id
        LEFT JOIN employees emp ON soh.employees_id = emp.id
        LEFT JOIN udc_details ps ON soh.payment_status = ps.id
        LEFT JOIN udc_details pi ON soh.payment_instrument = pi.id
        LEFT JOIN udc_details ot ON soh.order_type = ot.id
        WHERE $where
        ORDER BY soh.order_date DESC, soh.id DESC
        LIMIT ? OFFSET ?
      ''';

      final dataResult = await db.rawQuery(dataQuery, [
        ...whereArgs,
        pageSize,
        offset,
      ]);

      final headers = dataResult
          .map((map) => SalesOrderHeader.fromMap(map))
          .toList();

      return {
        'headers': headers,
        'totalCount': totalCount,
        'currentPage': page,
        'totalPages': (totalCount / pageSize).ceil(),
      };
    } catch (e) {
      throw Exception('Failed to get sales transaction report: $e');
    }
  }

  /// Get sales transaction detail report with pagination
  /// Equivalent to Java's getLazyItemsSalesDetails
  Future<Map<String, dynamic>> getSalesTransactionDetailReport({
    required int companyId,
    required int page,
    required int pageSize,
    int? customerId,
    int? itemId,
    String? fsNumber,
    String? proformaReference,
    DateTime? startDate,
    DateTime? endDate,
    String? salesType,
    bool? voidIndicator,
  }) async {
    final db = await _db;

    try {
      // Build WHERE clause
      String where = 'soh.company = ?';
      List<dynamic> whereArgs = [companyId];

      if (customerId != null) {
        where += ' AND soh.customer_bill_to = ?';
        whereArgs.add(customerId);
      }

      if (itemId != null) {
        where += ' AND sod.items_table_id = ?';
        whereArgs.add(itemId);
      }

      if (fsNumber != null && fsNumber.isNotEmpty) {
        where += ' AND soh.fs_number = ?';
        whereArgs.add(fsNumber);
      }

      if (proformaReference != null && proformaReference.isNotEmpty) {
        where += ' AND soh.proforma_reference = ?';
        whereArgs.add(proformaReference);
      }

      if (startDate != null && endDate != null) {
        // Use full day range (00:00:00 to 23:59:59)
        final start = DateTime(
          startDate.year,
          startDate.month,
          startDate.day,
          0,
          0,
          0,
        );
        final end = DateTime(
          endDate.year,
          endDate.month,
          endDate.day,
          23,
          59,
          59,
        );
        where += ' AND soh.order_date BETWEEN ? AND ?';
        whereArgs.add(start.toIso8601String());
        whereArgs.add(end.toIso8601String());
      } else if (startDate != null) {
        final start = DateTime(
          startDate.year,
          startDate.month,
          startDate.day,
          0,
          0,
          0,
        );
        where += ' AND soh.order_date >= ?';
        whereArgs.add(start.toIso8601String());
      } else if (endDate != null) {
        final end = DateTime(
          endDate.year,
          endDate.month,
          endDate.day,
          23,
          59,
          59,
        );
        where += ' AND soh.order_date <= ?';
        whereArgs.add(end.toIso8601String());
      }

      if (salesType != null && salesType.isNotEmpty) {
        where += ' AND soh.sales_type = ?';
        whereArgs.add(salesType);
      }

      if (voidIndicator != null) {
        if (voidIndicator) {
          where +=
              ' AND soh.void_indicator IS NOT NULL AND soh.void_indicator != ""';
        } else {
          where +=
              ' AND (soh.void_indicator IS NULL OR soh.void_indicator = "")';
        }
      } else {
        // Default: exclude voided orders
        where += ' AND (soh.void_indicator IS NULL OR soh.void_indicator = "")';
      }

      // Get total count
      final countQuery =
          '''
        SELECT COUNT(*) as total
        FROM sales_order_details sod
        INNER JOIN sales_order_header soh ON sod.sales_order_header_id = soh.id
        WHERE $where
      ''';
      final countResult = await db.rawQuery(countQuery, whereArgs);
      final totalCount = countResult.first['total'] as int;

      // Get paginated data
      final offset = (page - 1) * pageSize;
      final dataQuery =
          '''
        SELECT 
          sod.*,
          soh.order_date,
          soh.fs_number,
          soh.order_number,
          soh.order_type,
          soh.proforma_reference,
          soh.payment_term,
          soh.sales_type,
          soh.customer_bill_to,
          cu.customer_name as customer_name,
          cu.phone_number as customer_bill_to_phone,
          cu.tin_number as customer_bill_to_tin,
          it.items_id as item_number_string,
          it.item_description as item_description,
          uom.description_1 as unit_of_measure_description,
          uom.detail_code as unit_of_measure_code,
          emp.name_first as employee_name_first,
          emp.name_middle as employee_name_middle,
          emp.name_last as employee_name_last,
          emp.phone as employee_phone,
          emp.email as employee_email,
          (sod.extended_price - sod.amount_cost) as gross_profit_detail,
          it.id as items_table_id,
          it.unit_price as unit_price,
          it.taxable as taxable,
          it.barcode as barcode,
          it.company as item_company,
          ib.id as item_in_branch_id,
          ib.branch as branch,
          ib.quantity_available as quantity_available,
          ib.quantity_available as quantity_available,
          ib.company as item_in_branch_company,
          (CASE WHEN it.taxable = 'Y' THEN (sod.extended_price * (SELECT rate_vat_percentage FROM system_constant LIMIT 1) / 100.0) ELSE 0 END) as tax_amount
        FROM sales_order_details sod
        INNER JOIN sales_order_header soh ON sod.sales_order_header_id = soh.id
        LEFT JOIN customer_table cu ON soh.customer_bill_to = cu.id
        LEFT JOIN items_table it ON sod.items_table_id = it.id
        LEFT JOIN udc_details uom ON sod.unit_of_measure = uom.id
        LEFT JOIN employees emp ON soh.employees_id = emp.id
        LEFT JOIN items_in_branch ib ON sod.items_table_id = ib.item_number
        WHERE $where
        ORDER BY soh.order_date DESC, soh.id DESC, sod.id ASC
        LIMIT ? OFFSET ?
      ''';

      final dataResult = await db.rawQuery(dataQuery, [
        ...whereArgs,
        pageSize,
        offset,
      ]);

      final details = dataResult
          .map((map) => SalesOrderDetail.fromMap(map))
          .toList();

      return {
        'details': details,
        'totalCount': totalCount,
        'currentPage': page,
        'totalPages': (totalCount / pageSize).ceil(),
      };
    } catch (e) {
      throw Exception('Failed to get sales transaction detail report: $e');
    }
  }

  /// Calculate totals for sales transaction report
  /// Equivalent to Java's total calculation logic in resetTotals() and loop
  Future<Map<String, dynamic>> calculateSalesTransactionTotals({
    required int companyId,
    int? customerId,
    int? itemId,
    String? fsNumber,
    String? proformaReference,
    DateTime? startDate,
    DateTime? endDate,
    String? salesType,
    bool? voidIndicator,
    required bool isDetailView,
  }) async {
    final db = await _db;

    try {
      // Build WHERE clause (same as above methods)
      String where = 'soh.company = ?';
      List<dynamic> whereArgs = [companyId];

      if (customerId != null) {
        where += ' AND soh.customer_bill_to = ?';
        whereArgs.add(customerId);
      }

      if (itemId != null && !isDetailView) {
        where +=
            ' AND EXISTS (SELECT 1 FROM sales_order_details sod '
            'WHERE sod.sales_order_header_id = soh.id AND sod.items_table_id = ?)';
        whereArgs.add(itemId);
      }

      if (fsNumber != null && fsNumber.isNotEmpty) {
        where += ' AND soh.fs_number = ?';
        whereArgs.add(fsNumber);
      }

      if (proformaReference != null && proformaReference.isNotEmpty) {
        where += ' AND soh.proforma_reference = ?';
        whereArgs.add(proformaReference);
      }

      if (startDate != null && endDate != null) {
        final start = DateTime(
          startDate.year,
          startDate.month,
          startDate.day,
          0,
          0,
          0,
        );
        final end = DateTime(
          endDate.year,
          endDate.month,
          endDate.day,
          23,
          59,
          59,
        );
        where += ' AND soh.order_date BETWEEN ? AND ?';
        whereArgs.add(start.toIso8601String());
        whereArgs.add(end.toIso8601String());
      } else if (startDate != null) {
        final start = DateTime(
          startDate.year,
          startDate.month,
          startDate.day,
          0,
          0,
          0,
        );
        where += ' AND soh.order_date >= ?';
        whereArgs.add(start.toIso8601String());
      } else if (endDate != null) {
        final end = DateTime(
          endDate.year,
          endDate.month,
          endDate.day,
          23,
          59,
          59,
        );
        where += ' AND soh.order_date <= ?';
        whereArgs.add(end.toIso8601String());
      }

      if (salesType != null && salesType.isNotEmpty) {
        where += ' AND soh.sales_type = ?';
        whereArgs.add(salesType);
      }

      if (voidIndicator != null) {
        if (voidIndicator) {
          where +=
              ' AND soh.void_indicator IS NOT NULL AND soh.void_indicator != ""';
        } else {
          where +=
              ' AND (soh.void_indicator IS NULL OR soh.void_indicator = "")';
        }
      } else {
        where += ' AND (soh.void_indicator IS NULL OR soh.void_indicator = "")';
      }

      String query;
      if (isDetailView) {
        // For detail view, sum from sales_order_details
        String detailWhere = where;
        if (itemId != null) {
          detailWhere += ' AND sod.items_table_id = ?';
          whereArgs.add(itemId);
        }

        query =
            '''
          SELECT 
            COUNT(DISTINCT sod.id) as total_count,
            COALESCE(SUM(sod.extended_price), 0.0) as revenue_total,
            COALESCE(SUM(sod.amount_cost), 0.0) as cogs_total,
            COALESCE(SUM(sod.extended_price - sod.amount_cost), 0.0) as gross_profit_total,
            (SELECT COALESCE(SUM(tax), 0.0) FROM sales_order_header WHERE id IN (SELECT DISTINCT sales_order_header_id FROM sales_order_details sod INNER JOIN sales_order_header soh ON sod.sales_order_header_id = soh.id WHERE $detailWhere)) as vat_total,
            (SELECT COALESCE(SUM(discount_amount), 0.0) FROM sales_order_header WHERE id IN (SELECT DISTINCT sales_order_header_id FROM sales_order_details sod INNER JOIN sales_order_header soh ON sod.sales_order_header_id = soh.id WHERE $detailWhere)) as discount_total,
            (SELECT COALESCE(SUM(withhold_amount), 0.0) FROM sales_order_header WHERE id IN (SELECT DISTINCT sales_order_header_id FROM sales_order_details sod INNER JOIN sales_order_header soh ON sod.sales_order_header_id = soh.id WHERE $detailWhere)) as withhold_total
          FROM sales_order_details sod
          INNER JOIN sales_order_header soh ON sod.sales_order_header_id = soh.id
          WHERE $detailWhere
        ''';
        // Need to duplicate whereArgs for the subqueries
        whereArgs = [...whereArgs, ...whereArgs, ...whereArgs, ...whereArgs];
      } else {
        // For header view, sum from sales_order_header
        query =
            '''
          SELECT 
            COUNT(*) as total_count,
            COALESCE(SUM(soh.withhold_amount), 0.0) as withhold_total,
            COALESCE(SUM(soh.tax), 0.0) as vat_total,
            COALESCE(SUM(soh.discount_amount), 0.0) as discount_total,
            COALESCE(SUM(soh.amount_total), 0.0) as revenue_total,
            COALESCE(SUM(soh.amount_cost), 0.0) as cogs_total,
            COALESCE(SUM(soh.amount_total - soh.amount_cost), 0.0) as gross_profit_total
          FROM sales_order_header soh
          WHERE $where
        ''';
      }

      final result = await db.rawQuery(query, whereArgs);
      final row = result.first;

      return {
        'withholdTotal': (row['withhold_total'] as num?)?.toDouble() ?? 0.0,
        'vatTotal': (row['vat_total'] as num?)?.toDouble() ?? 0.0,
        'discountTotal': (row['discount_total'] as num?)?.toDouble() ?? 0.0,
        'revenueTotal': (row['revenue_total'] as num?)?.toDouble() ?? 0.0,
        'cogsTotal': (row['cogs_total'] as num?)?.toDouble() ?? 0.0,
        'grossProfitTotal':
            (row['gross_profit_total'] as num?)?.toDouble() ?? 0.0,
        'totalCount': (row['total_count'] as int?) ?? 0,
      };
    } catch (e) {
      throw Exception('Failed to calculate sales transaction totals: $e');
    }
  }

  Future<List<CreditReceipt>> getCreditReceiptsReport({
    required int companyId,
    int? customerBillTo,
    String? fsNumber,
    String? sortBy,
    int? limit,
    int? offset,
  }) async {
    final db = await _db;

    try {
      String where = 'crt.company = ?';
      List<dynamic> whereArgs = [companyId];

      if (customerBillTo != null) {
        where += ' AND soh.customer_bill_to = ?';
        whereArgs.add(customerBillTo);
      }

      if (fsNumber != null && fsNumber.isNotEmpty) {
        where += ' AND soh.fs_number = ?';
        whereArgs.add(fsNumber);
      }

      String orderBy = 'soh.order_date DESC';
      if (sortBy != null && sortBy.isNotEmpty) {
        orderBy = sortBy;
      }

      String query =
          '''
        SELECT 
          crt.*,
          soh.fs_number as fs_number,
          soh.amount_total as total_amount,
          soh.customer_bill_to as customer_bill_to,
          soh.order_date as order_date,
          cust.customer_name as customer_bill_to_name,
          pi.description_1 as payment_instrument_description,
          pi.detail_code as payment_instrument_code,
          soh.order_type as order_type,
          ot.description_1 as order_type_description,
          ot.detail_code as order_type_code
        FROM credit_receipt_table crt
        LEFT JOIN sales_order_header soh ON crt.so_header = soh.id
        LEFT JOIN customer_table cust ON soh.customer_bill_to = cust.id
        LEFT JOIN udc_details pi ON crt.payment_instrument = pi.id
        LEFT JOIN udc_details ot ON soh.order_type = ot.id
        WHERE $where
        ORDER BY $orderBy
      ''';

      if (limit != null) {
        query += ' LIMIT $limit';
      }
      if (offset != null) {
        query += ' OFFSET $offset';
      }

      final maps = await db.rawQuery(query, whereArgs);
      return maps.map((map) => CreditReceipt.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get credit receipts report: $e');
    }
  }

  // Aged Credit Receipt Report
  Future<Map<String, dynamic>> getAgedCreditReceiptReport({
    required int companyId,
    int page = 1,
    int pageSize = 20,
    int? customerId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _db;

    try {
      String where =
          'soh.company = ? AND soh.amount_open <> 0.0 AND soh.payment_term IS NOT NULL';
      List<dynamic> whereArgs = [companyId];

      if (customerId != null) {
        where += ' AND soh.customer_bill_to = ?';
        whereArgs.add(customerId);
      }

      if (startDate != null) {
        where += ' AND soh.order_date >= ?';
        whereArgs.add(startDate.toIso8601String());
      }

      if (endDate != null) {
        where += ' AND soh.order_date <= ?';
        whereArgs.add(endDate.toIso8601String());
      }

      where += ' AND (soh.void_indicator IS NULL OR soh.void_indicator = "")';

      // Count total queries
      final countQuery =
          'SELECT COUNT(*) as count FROM sales_order_header soh WHERE $where';
      final countResult = await db.rawQuery(countQuery, whereArgs);
      final totalCount = Sqflite.firstIntValue(countResult) ?? 0;

      // Calculate pagination
      final totalPages = (totalCount / pageSize).ceil();
      final offset = (page - 1) * pageSize;

      String orderBy = 'soh.id DESC';

      final query =
          '''
        SELECT 
          soh.*,
          soh.fs_number as fs_number,
          soh.amount_total as total_amount,
          soh.customer_bill_to as customer_bill_to,
          soh.order_date as order_date,
          cust.customer_name as customer_bill_to_name,
          pi.description_1 as payment_instrument_description,
          pi.detail_code as payment_instrument_code,
          soh.order_type as order_type,
          ot.description_1 as order_type_description,
          ot.detail_code as order_type_code
        FROM credit_receipt_table crt
        LEFT JOIN sales_order_header soh ON crt.so_header = soh.id
        LEFT JOIN customer_table cust ON soh.customer_bill_to = cust.id
        LEFT JOIN udc_details pi ON crt.payment_instrument = pi.id
        LEFT JOIN udc_details ot ON soh.order_type = ot.id
        WHERE $where
        ORDER BY $orderBy
        LIMIT ? OFFSET ?
      ''';

      final queryArgs = [...whereArgs, pageSize, offset];
      final maps = await db.rawQuery(query, queryArgs);
      final headers = maps.map((map) => SalesOrderHeader.fromMap(map)).toList();

      return {
        'headers': headers,
        'totalCount': totalCount,
        'totalPages': totalPages,
        'currentPage': page,
      };
    } catch (e) {
      throw Exception('Failed to get aged credit receipt report: $e');
    }
  }

  Future<Map<String, double>> calculateAgedCreditReceiptTotals({
    required int companyId,
    int? customerId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _db;
    try {
      String where =
          'company = ? AND amount_open <> 0.0 AND payment_term IS NOT NULL';
      List<dynamic> whereArgs = [companyId];

      if (customerId != null) {
        where += ' AND customer_bill_to = ?';
        whereArgs.add(customerId);
      }

      if (startDate != null) {
        where += ' AND order_date >= ?';
        whereArgs.add(startDate.toIso8601String());
      }

      if (endDate != null) {
        where += ' AND order_date <= ?';
        whereArgs.add(endDate.toIso8601String());
      }

      where += ' AND (void_indicator IS NULL OR void_indicator = "")';

      final query =
          '''
        SELECT 
          SUM(amount_total) as total_amount,
          SUM(amount_total - CASE WHEN amount_open IS NULL THEN 0 ELSE amount_open END) as total_paid,
          SUM(CASE WHEN amount_open IS NULL THEN 0 ELSE amount_open END) as total_remaining
        FROM sales_order_header
        WHERE $where
      ''';

      final result = await db.rawQuery(query, whereArgs);

      if (result.isNotEmpty) {
        final row = result.first;
        return {
          'totalAmountprice': (row['total_amount'] as double?) ?? 0.0,
          'paidpriceAmount': (row['total_paid'] as double?) ?? 0.0,
          'remainingPriceAmount': (row['total_remaining'] as double?) ?? 0.0,
        };
      }
      return {
        'totalAmountprice': 0.0,
        'paidpriceAmount': 0.0,
        'remainingPriceAmount': 0.0,
      };
    } catch (e) {
      throw Exception('Failed to calculate aged credit receipt totals: $e');
    }
  }
}
