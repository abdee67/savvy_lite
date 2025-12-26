// repositories/sales_order_header_repository.dart
import 'dart:async';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/models/purchase_order_header_model.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/models/purchase_order_receiver_model.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/models/purchase_order_detail_model.dart';
import 'package:sqflite/sqflite.dart';

class PurchaseOrderReportRepository {
  static final PurchaseOrderReportRepository _instance =
      PurchaseOrderReportRepository._internal();
  factory PurchaseOrderReportRepository() => _instance;
  PurchaseOrderReportRepository._internal();

  Future<Database> get _db async => LocalDatabaseService().database;
  // ============================================================================
  // SALES TRANSACTION REPORT METHODS
  // ============================================================================

  /// Get sales transaction report (header-level) with pagination
  /// Equivalent to Java's getLazyItemsSales
  Future<Map<String, dynamic>> getPurchaseTransactionReport({
    required int companyId,
    required int page,
    required int pageSize,
    int? supplierId,
    DateTime? startDate,
    DateTime? endDate,
    String? purchaseType,
  }) async {
    final db = await _db;

    try {
      // Build dynamic SQL query matching Java's JPQL logic
      final whereClauses = <String>[];
      final whereArgs = <dynamic>[];

      // Company filter (always required)
      whereClauses.add('poh.company = ?');
      whereArgs.add(companyId);

      // Date range filter
      if (startDate != null && endDate != null) {
        whereClauses.add('poh.date_transaction BETWEEN ? AND ?');
        whereArgs.add(startDate.toIso8601String());
        whereArgs.add(endDate.toIso8601String());
      }

      // Purchase type filter - matches Java logic exactly
      if (purchaseType != null) {
        if (purchaseType.toLowerCase() == 'cash') {
          whereClauses.add('poh.payment_term IS NULL');
        } else if (purchaseType.toLowerCase() == 'credit') {
          whereClauses.add('poh.payment_term IS NOT NULL');
        } else if (purchaseType.toLowerCase() == 'advance') {
          whereClauses.add("poh.payment_term = '0'");
        }
      }

      // Supplier filter
      if (supplierId != null) {
        whereClauses.add('poh.supplier_id = ?');
        whereArgs.add(supplierId);
      }

      final whereClause = whereClauses.join(' AND ');

      // Get total count for pagination
      final countResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM purchase_order_header poh WHERE $whereClause',
        whereArgs,
      );
      final totalCount = countResult.first['count'] as int;
      final totalPages = (totalCount / pageSize).ceil();

      // Get paginated data with sorting (default: date_transaction DESC)
      final offset = (page - 1) * pageSize;
      final dataQuery =
          '''
        SELECT 
          poh.*,
          su.supplier_name as supplier_name,
          ps.detail_code as payment_status_code,
          ps.description_1 as payment_status_description,
          pi.description_1 as payment_instrument_description,
          pi.detail_code as payment_instrument_code,
          ot.description_1 as order_type_description,
          ot.detail_code as order_type_code
        FROM purchase_order_header poh
        LEFT JOIN supplier_table su ON poh.supplier_id = su.id
        LEFT JOIN udc_details ps ON poh.payment_status = ps.id
        LEFT JOIN udc_details pi ON poh.payment_instrument = pi.id
        LEFT JOIN udc_details ot ON poh.order_type = ot.id
        WHERE $whereClause
        ORDER BY poh.date_transaction DESC, poh.id DESC
        LIMIT ? OFFSET ?
      ''';

      final dataResult = await db.rawQuery(dataQuery, [
        ...whereArgs,
        pageSize,
        offset,
      ]);

      final headers = dataResult
          .map((map) => PurchaseOrderHeader.fromMap(map))
          .toList();

      return {
        'headers': headers,
        'totalCount': totalCount,
        'currentPage': page,
        'totalPages': totalPages,
        'pageSize': pageSize,
      };
    } catch (e) {
      throw Exception('Failed to get purchase order transaction report: $e');
    }
  }

  /// Calculate totals for purchase order transaction report
  /// Equivalent to Java's total calculation logic in resetTotals() and loop
  Future<Map<String, dynamic>> calculatePurchaseOrderTransactionTotals({
    required int companyId,
    int? supplierId,
    DateTime? startDate,
    DateTime? endDate,
    String? purchaseType,
  }) async {
    final db = await _db;

    try {
      // Build WHERE clause (same as above methods)
      String where = 'poh.company = ?';
      List<dynamic> whereArgs = [companyId];

      if (supplierId != null) {
        where += ' AND poh.supplier_id = ?';
        whereArgs.add(supplierId);
      }

      if (purchaseType != null) {
        if (purchaseType.toLowerCase() == 'cash') {
          where += ' AND payment_term IS NULL';
        } else if (purchaseType.toLowerCase() == 'credit') {
          where += ' AND payment_term IS NOT NULL';
        } else if (purchaseType.toLowerCase() == 'advance') {
          where += " AND payment_term = '0'";
        }
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
        where += ' AND poh.date_transaction BETWEEN ? AND ?';
        whereArgs.add(start.toIso8601String());
        whereArgs.add(end.toIso8601String());
      }

      String query =
          '''
          SELECT 
            COUNT(*) as total_count,
            COALESCE(SUM(poh.amount_gross), 0.0) as total_amount_gross,
            COALESCE(SUM(poh.amount_grand_total_cost), 0.0) as total_grand_amount_gross
          FROM purchase_order_header poh
          WHERE $where
        ''';

      final result = await db.rawQuery(query, whereArgs);
      final row = result.first;

      return {
        'totalAmountGross':
            (row['total_amount_gross'] as num?)?.toDouble() ?? 0.0,
        'totalGrandAmountGross':
            (row['total_grand_amount_gross'] as num?)?.toDouble() ?? 0.0,
        'totalCount': (row['total_count'] as int?) ?? 0,
      };
    } catch (e) {
      throw Exception(
        'Failed to calculate purchase order transaction totals: $e',
      );
    }
  }

  // ============================================================================
  // PURCHASE ORDER RECEIVER REPORT METHODS
  // ============================================================================

  /// Get purchase order receiver report with pagination
  Future<Map<String, dynamic>> getPurchaseOrderReceiverReport({
    required int companyId,
    required int page,
    required int pageSize,
    int? supplierId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _db;

    try {
      final whereClauses = <String>[];
      final whereArgs = <dynamic>[];

      // Company filter using table alias 'por' for receiver table
      whereClauses.add('por.company = ?');
      whereArgs.add(companyId);

      // Date range filter on date_received
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
        whereClauses.add('por.date_received BETWEEN ? AND ?');
        whereArgs.add(start.toIso8601String());
        whereArgs.add(end.toIso8601String());
      }

      // Supplier filter requires join with header through detail
      if (supplierId != null) {
        whereClauses.add('poh.supplier_id = ?');
        whereArgs.add(supplierId);
      }

      final whereClause = whereClauses.join(' AND ');

      // Base joins needed for both count and data queries
      // We need these joins for the WHERE clause (e.g. supplier_id is in header)
      final baseJoins = '''
        LEFT JOIN purchase_order_detail pod ON por.po_detail = pod.id
        LEFT JOIN purchase_order_header poh ON pod.po_header = poh.id
      ''';

      // Get total count
      final countQuery =
          '''
        SELECT COUNT(*) as count 
        FROM purchase_order_receiver por 
        $baseJoins
        WHERE $whereClause
      ''';

      final countResult = await db.rawQuery(countQuery, whereArgs);
      final totalCount = countResult.first['count'] as int;
      final totalPages = (totalCount / pageSize).ceil();

      // Get paginated data
      final offset = (page - 1) * pageSize;

      // Full query with all joins for description fields
      final dataQuery =
          '''
        SELECT 
          por.*,
          it.item_description as item_description,
          br.description as branch_recieved_description,
          il.location as location,
          lm.id as location_id,
          lm.location_description as location_description,
          um.description_1 as unit_of_measure_description,
          um.detail_code as unit_of_measure_code,
          poh.invoice_number as invoice_number,
          poh.payment_term as payment_term,
          poh.supplier_id as supplier_id,
          poh.order_number as order_number,
          poh.id as po_header,
          sup.supplier_name as supplier_name,
          ut.user_name as user_name,
          ut.id as user_id
        FROM purchase_order_receiver por
        LEFT JOIN purchase_order_detail pod ON por.po_detail = pod.id
        LEFT JOIN purchase_order_header poh ON pod.po_header = poh.id
        LEFT JOIN supplier_table sup ON poh.supplier_id = sup.id
        LEFT JOIN items_table it ON por.item_number = it.id
        LEFT JOIN branch_table br ON por.branch_recieved = br.id
        LEFT JOIN item_location il ON por.location = il.id
        LEFT JOIN location_master lm ON il.location = lm.id
        LEFT JOIN udc_details um ON por.unit_of_measure = um.id
        LEFT JOIN user_table ut ON por.user_id = ut.id
        WHERE $whereClause
        ORDER BY por.date_received DESC, por.id DESC
        LIMIT ? OFFSET ?
      ''';

      final dataResult = await db.rawQuery(dataQuery, [
        ...whereArgs,
        pageSize,
        offset,
      ]);

      final receivers = dataResult
          .map((map) => PurchaseOrderReceiver.fromMap(map))
          .toList();

      return {
        'receivers': receivers,
        'total_count': totalCount,
        'current_page': page,
        'total_pages': totalPages,
        'page_size': pageSize,
      };
    } catch (e) {
      if (e is DatabaseException) {
        // Log the specific database error
        print('Database Exception: ${e.toString()}');
      }
      print('Stack Trace: ${StackTrace.current}');
      throw Exception('Failed to get purchase order receiver report: $e');
    }
  }

  /// Calculate totals for purchase order receiver report
  Future<Map<String, dynamic>> calculatePurchaseOrderReceiverTotals({
    required int companyId,
    int? supplierId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _db;

    try {
      final whereClauses = <String>[];
      final whereArgs = <dynamic>[];

      whereClauses.add('por.company = ?');
      whereArgs.add(companyId);

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
        whereClauses.add('por.date_received BETWEEN ? AND ?');
        whereArgs.add(start.toIso8601String());
        whereArgs.add(end.toIso8601String());
      }

      if (supplierId != null) {
        whereClauses.add('poh.supplier_id = ?');
        whereArgs.add(supplierId);
      }

      final whereClause = whereClauses.join(' AND ');

      final query =
          '''
        SELECT 
          COUNT(*) as total_count,
          COALESCE(SUM(por.quantity_recieved), 0.0) as total_received_quantity,
          COALESCE(SUM(por.amount_received), 0.0) as total_received_amount
        FROM purchase_order_receiver por
        LEFT JOIN purchase_order_detail pod ON por.po_detail = pod.id
        LEFT JOIN purchase_order_header poh ON pod.po_header = poh.id
        WHERE $whereClause
      ''';

      final result = await db.rawQuery(query, whereArgs);
      final row = result.first;

      return {
        'total_received_quantity':
            (row['total_received_quantity'] as num?)?.toDouble() ?? 0.0,
        'total_received_amount':
            (row['total_received_amount'] as num?)?.toDouble() ?? 0.0,
        'total_count': (row['total_count'] as int?) ?? 0,
      };
    } catch (e) {
      throw Exception('Failed to calculate purchase order receiver totals: $e');
    }
  }

  // ============================================================================
  // PENDING PURCHASE ORDER REPORT METHODS
  // ============================================================================

  /// Get pending purchase order report (details with quantity open)
  /// Equivalent to Java's getLazyPendingToReceive
  Future<Map<String, dynamic>> getPendingPurchaseOrderReport({
    required int companyId,
    required int page,
    required int pageSize,
    int? supplierId,
    int? itemId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _db;

    try {
      final whereClauses = <String>[];
      final whereArgs = <dynamic>[];

      // Company filter using table alias 'pod'
      whereClauses.add('pod.company = ?');
      whereArgs.add(companyId);

      // Quantity Open filter (Java: o.quantityOpen IS NOT NULL AND o.quantityOpen <> 0.0)
      whereClauses.add('pod.quantity_open IS NOT NULL');
      whereClauses.add('pod.quantity_open <> 0.0');

      // Date range filter on header date_transaction
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
        whereClauses.add('poh.date_transaction BETWEEN ? AND ?');
        whereArgs.add(start.toIso8601String());
        whereArgs.add(end.toIso8601String());
      }

      // Supplier filter (on header)
      if (supplierId != null) {
        whereClauses.add('poh.supplier_id = ?');
        whereArgs.add(supplierId);
      }

      // Item filter
      if (itemId != null) {
        whereClauses.add('pod.item_number = ?');
        whereArgs.add(itemId);
      }

      final whereClause = whereClauses.join(' AND ');

      // Base joins
      final baseJoins = '''
        LEFT JOIN purchase_order_header poh ON pod.po_header = poh.id
      ''';

      // Get total count
      final countQuery =
          '''
        SELECT COUNT(*) as count 
        FROM purchase_order_detail pod 
        $baseJoins
        WHERE $whereClause
      ''';

      final countResult = await db.rawQuery(countQuery, whereArgs);
      final totalCount = countResult.first['count'] as int;
      final totalPages = (totalCount / pageSize).ceil();

      // Get paginated data
      final offset = (page - 1) * pageSize;

      // Full query with all joins for description fields needed by PurchaseOrderDetail.fromMap
      final dataQuery =
          '''
        SELECT 
          pod.*,
          it.item_description as item_description,
          poh.order_number as order_number,
          poh.date_transaction as date_transaction,
          poh.invoice_number as invoice_number,
          poh.payment_term as payment_term,
          poh.supplier_id as supplier_id,
          sup.supplier_name as supplier_name,
          um.description_1 as unit_of_measure_description,
          um.detail_code as unit_of_measure_code
        FROM purchase_order_detail pod
        LEFT JOIN purchase_order_header poh ON pod.po_header = poh.id
        LEFT JOIN supplier_table sup ON poh.supplier_id = sup.id
        LEFT JOIN items_table it ON pod.item_number = it.id
        LEFT JOIN udc_details um ON pod.unit_of_measure = um.id
        WHERE $whereClause
        ORDER BY poh.date_transaction DESC, pod.id DESC
        LIMIT ? OFFSET ?
      ''';

      final dataResult = await db.rawQuery(dataQuery, [
        ...whereArgs,
        pageSize,
        offset,
      ]);

      final details = dataResult
          .map((map) => PurchaseOrderDetail.fromMap(map))
          .toList();

      return {
        'details': details,
        'total_count': totalCount,
        'current_page': page,
        'total_pages': totalPages,
        'page_size': pageSize,
      };
    } catch (e) {
      if (e is DatabaseException) {
        print('Database Exception: ${e.toString()}');
      }
      print('Stack Trace: ${StackTrace.current}');
      throw Exception('Failed to get pending purchase order report: $e');
    }
  }

  /// Calculate totals for pending purchase order report
  Future<Map<String, dynamic>> calculatePendingPurchaseOrderTotals({
    required int companyId,
    int? supplierId,
    int? itemId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _db;

    try {
      final whereClauses = <String>[];
      final whereArgs = <dynamic>[];

      whereClauses.add('pod.company = ?');
      whereArgs.add(companyId);

      whereClauses.add('pod.quantity_open IS NOT NULL');
      whereClauses.add('pod.quantity_open <> 0.0');

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
        whereClauses.add('poh.date_transaction BETWEEN ? AND ?');
        whereArgs.add(start.toIso8601String());
        whereArgs.add(end.toIso8601String());
      }

      if (supplierId != null) {
        whereClauses.add('poh.supplier_id = ?');
        whereArgs.add(supplierId);
      }

      if (itemId != null) {
        whereClauses.add('pod.item_number = ?');
        whereArgs.add(itemId);
      }

      final whereClause = whereClauses.join(' AND ');

      final query =
          '''
        SELECT 
          COUNT(*) as total_count,
          COALESCE(SUM(pod.quantity_open), 0.0) as total_quantity_open,
          COALESCE(SUM(pod.quantity_transaction), 0.0) as total_quantity_transaction,
          COALESCE(SUM(pod.quantity_recieved), 0.0) as total_quantity_recieved
        FROM purchase_order_detail pod
        LEFT JOIN purchase_order_header poh ON pod.po_header = poh.id
        WHERE $whereClause
      ''';

      final result = await db.rawQuery(query, whereArgs);
      final row = result.first;
      return {
        'total_quantity_open':
            (row['total_quantity_open'] as num?)?.toDouble() ?? 0.0,
        'total_quantity_recieved':
            (row['total_quantity_recieved'] as num?)?.toDouble() ?? 0.0,
        'total_count': (row['total_count'] as int?) ?? 0,
        'total_quantity_transaction':
            (row['total_quantity_transaction'] as num?)?.toDouble() ?? 0.0,
      };
    } catch (e) {
      throw Exception('Failed to calculate pending purchase order totals: $e');
    }
  }
}
