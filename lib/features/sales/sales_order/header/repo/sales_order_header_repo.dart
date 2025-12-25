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
}
