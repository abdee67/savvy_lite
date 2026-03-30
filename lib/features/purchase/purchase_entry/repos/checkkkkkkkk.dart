import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/models/purchase_order_header_model.dart';

class PurchaseOrderReportRepository {
  final LocalDatabaseService _dbService;

  PurchaseOrderReportRepository(this._dbService);

  /// Get paginated purchase transaction report with filters
  /// Matches Java's load() method in LazyDataModel
  Future<Map<String, dynamic>> getPurchaseTransactionReport({
    required int companyId,
    required int page,
    required int pageSize,
    int? customerId, // Supplier ID
    DateTime? startDate,
    DateTime? endDate,
    String? purchaseType, // 'Cash', 'Credit', 'Advance'
    bool? voidIndicator,
  }) async {
    try {
      final db = await _dbService.database;

      // Build dynamic SQL query matching Java's JPQL logic
      final whereClauses = <String>[];
      final whereArgs = <dynamic>[];

      // Company filter (always required)
      whereClauses.add('company = ?');
      whereArgs.add(companyId);

      // Date range filter
      if (startDate != null && endDate != null) {
        whereClauses.add('date_transation BETWEEN ? AND ?');
        whereArgs.add(startDate.toIso8601String());
        whereArgs.add(endDate.toIso8601String());
      }

      // Purchase type filter - matches Java logic exactly
      if (purchaseType != null) {
        if (purchaseType.toLowerCase() == 'cash') {
          whereClauses.add('payment_term IS NULL');
        } else if (purchaseType.toLowerCase() == 'credit') {
          whereClauses.add('payment_term IS NOT NULL');
        } else if (purchaseType.toLowerCase() == 'advance') {
          whereClauses.add("payment_term = '0'");
        }
      }

      // Supplier filter
      if (customerId != null) {
        whereClauses.add('supplier_id = ?');
        whereArgs.add(customerId);
      }

      // Void indicator filter
      if (voidIndicator != null && !voidIndicator) {
        whereClauses.add('(void_indicator IS NULL OR void_indicator = 0)');
      }

      final whereClause = whereClauses.join(' AND ');

      // Get total count for pagination
      final countResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM purchase_order_header WHERE $whereClause',
        whereArgs,
      );
      final totalCount = countResult.first['count'] as int;
      final totalPages = (totalCount / pageSize).ceil();

      // Get paginated data with sorting (default: date_transaction DESC)
      final offset = (page - 1) * pageSize;
      final results = await db.query(
        'purchase_order_header',
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'date_transation DESC',
        limit: pageSize,
        offset: offset,
      );

      // Convert to PurchaseOrderHeader objects
      final headers = results
          .map((map) => PurchaseOrderHeader.fromMap(map))
          .toList();

      return {
        'headers': headers,
        'currentPage': page,
        'totalPages': totalPages,
        'totalCount': totalCount,
        'pageSize': pageSize,
      };
    } catch (e) {
      throw Exception('Failed to load purchase transaction report: $e');
    }
  }

  /// Calculate totals across ALL matching records (not just current page)
  /// Matches Java's totals calculation in load() method
  Future<Map<String, dynamic>> calculatePurchaseOrderTransactionTotals({
    required int companyId,
    int? customerId,
    DateTime? startDate,
    DateTime? endDate,
    String? purchaseType,
    bool? voidIndicator,
  }) async {
    try {
      final db = await _dbService.database;

      // Build same WHERE clause as main query
      final whereClauses = <String>[];
      final whereArgs = <dynamic>[];

      whereClauses.add('company = ?');
      whereArgs.add(companyId);

      if (startDate != null && endDate != null) {
        whereClauses.add('date_transation BETWEEN ? AND ?');
        whereArgs.add(startDate.toIso8601String());
        whereArgs.add(endDate.toIso8601String());
      }

      if (purchaseType != null) {
        if (purchaseType.toLowerCase() == 'cash') {
          whereClauses.add('payment_term IS NULL');
        } else if (purchaseType.toLowerCase() == 'credit') {
          whereClauses.add('payment_term IS NOT NULL');
        } else if (purchaseType.toLowerCase() == 'advance') {
          whereClauses.add("payment_term = '0'");
        }
      }

      if (customerId != null) {
        whereClauses.add('supplier_id = ?');
        whereArgs.add(customerId);
      }

      if (voidIndicator != null && !voidIndicator) {
        whereClauses.add('(void_indicator IS NULL OR void_indicator = 0)');
      }

      final whereClause = whereClauses.join(' AND ');

      // Calculate totals - matches Java's loop calculation
      final totalsResult = await db.rawQuery('''
        SELECT 
          COALESCE(SUM(amount_gross), 0.0) as totalAmountGross,
          COALESCE(SUM(amount_grand_total_cost), 0.0) as totalGrandAmountGross,
          COUNT(*) as totalCount
        FROM purchase_order_header 
        WHERE $whereClause
        ''', whereArgs);

      final result = totalsResult.first;
      return {
        'totalAmountGross': (result['totalAmountGross'] as num).toDouble(),
        'totalGrandAmountGross': (result['totalGrandAmountGross'] as num)
            .toDouble(),
        'totalCount': result['totalCount'] as int,
      };
    } catch (e) {
      throw Exception('Failed to calculate purchase order totals: $e');
    }
  }

  /// Get purchase order header by ID
  /// Matches Java's getRowData() method
  Future<PurchaseOrderHeader?> getPurchaseOrderHeaderById(int id) async {
    try {
      final db = await _dbService.database;
      final results = await db.query(
        'purchase_order_header',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (results.isEmpty) return null;
      return PurchaseOrderHeader.fromMap(results.first);
    } catch (e) {
      throw Exception('Failed to get purchase order header: $e');
    }
  }
}
