// repositories/sales_order_header_repository.dart
import 'dart:async';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/models/purchase_order_header_model.dart';
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
}
