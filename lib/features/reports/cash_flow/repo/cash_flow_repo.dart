// repositories/sales_order_header_repository.dart
import 'dart:async';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/sales/sales_order/header/model/sales_order_header.dart';
import 'package:savvy_stock/features/reports/cash_flow/models/cash_flow_transaction_DTO.dart';
import 'package:savvy_stock/features/sales/sales_order/header/model/other_income.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/models/purchase_order_header_model.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/models/other_expenses.dart';
import 'package:savvy_stock/features/reports/cash_flow/models/cash_flow_summary_totals.dart';
import 'package:sqflite/sqflite.dart';

class CashFlowRepository {
  static final CashFlowRepository _instance = CashFlowRepository._internal();
  factory CashFlowRepository() => _instance;
  CashFlowRepository._internal();

  Future<Database> get _db async => LocalDatabaseService().database;

  // ============================================================================
  // CASH INFLOW REPORT METHODS
  // ============================================================================

  /// Get cash inflow transactions (Sales + Other Income)
  /// Equivalent to Java's lazyCashInflowTransactions.load()
  Future<Map<String, dynamic>> getCashInflowTransactions({
    required int companyId,
    required int page,
    required int pageSize,
    DateTime? startDate,
    DateTime? endDate,
    String? salesType, // For filtering sales orders
  }) async {
    final db = await _db;

    try {
      final offset = (page - 1) * pageSize;

      // 1. Fetch Sales Orders
      final salesOrders = await _fetchSalesOrdersForCashFlow(
        db,
        companyId,
        limit: pageSize,
        offset: offset,
        startDate: startDate,
        endDate: endDate,
        salesType: salesType,
      );

      // 2. Fetch Other Income
      final otherIncomeList = await _fetchOtherIncomeForCashFlow(
        db,
        companyId,
        limit: pageSize,
        offset: offset,
        startDate: startDate,
        endDate: endDate,
      );

      List<CashflowTransactionReportDTO> data = [];

      // 3. Map Sales Orders to DTO
      for (var sH in salesOrders) {
        data.add(
          CashflowTransactionReportDTO(
            reference: "SO-${sH.fsNumber ?? ''}",
            cashCredit: sH.paymentMethod ?? '',
            date: sH.orderDate ?? DateTime.now(),
            amount: sH.amountTotal ?? 0.0,
            orderType: "Sales",
          ),
        );
      }

      // 4. Map Other Income to DTO
      for (var inc in otherIncomeList) {
        data.add(
          CashflowTransactionReportDTO(
            reference: inc.reasonDescription ?? '',
            cashCredit: "", // Empty as per Java code
            date: inc.dateIncome ?? DateTime.now(),
            amount: inc.incomeAmount ?? 0.0,
            orderType: "Other Income",
          ),
        );
      }

      // 5. Get Total Count
      final totalCount = await _countTotalInflowTransactions(
        db,
        companyId,
        startDate: startDate,
        endDate: endDate,
        salesType: salesType,
      );

      return {
        'items': data,
        'totalCount': totalCount,
        'currentPage': page,
        'totalPages': (totalCount / pageSize).ceil(),
      };
    } catch (e) {
      throw Exception('Failed to get cash inflow transactions: $e');
    }
  }

  // ============================================================================
  // CASH OUTFLOW REPORT METHODS
  // ============================================================================

  /// Get cash outflow transactions (Purchase + Other Expenses)
  Future<Map<String, dynamic>> getCashOutflowTransactions({
    required int companyId,
    required int page,
    required int pageSize,
    DateTime? startDate,
    DateTime? endDate,
    String? purchaseType, // "Cash" or "Credit"
  }) async {
    final db = await _db;

    try {
      final offset = (page - 1) * pageSize;

      // 1. Fetch Purchase Orders
      final purchaseOrders = await _fetchPurchaseOrdersForCashFlow(
        db,
        companyId,
        limit: pageSize,
        offset: offset,
        startDate: startDate,
        endDate: endDate,
        purchaseType: purchaseType,
      );

      // 2. Fetch Other Expenses
      final otherExpenses = await _fetchOtherExpensesForCashFlow(
        db,
        companyId,
        limit: pageSize,
        offset: offset,
        startDate: startDate,
        endDate: endDate,
      );

      List<CashflowTransactionReportDTO> data = [];

      // 3. Map Purchase Orders to DTO
      for (var po in purchaseOrders) {
        data.add(
          CashflowTransactionReportDTO(
            reference: "PO-${po.orderNumber ?? ''}",
            cashCredit: po.paymentTerm != null ? "Credit" : "Cash",
            date: po.dateTransation ?? DateTime.now(),
            amount: po.amountGrandTotalCost ?? 0.0,
            orderType: "Purchase",
          ),
        );
      }

      // 4. Map Other Expenses to DTO
      for (var exp in otherExpenses) {
        data.add(
          CashflowTransactionReportDTO(
            reference: exp.reasonDescription ?? '',
            cashCredit: "", // Empty as per Java code
            date: exp.datePayment ?? DateTime.now(),
            amount: exp.paymentAmount ?? 0.0,
            orderType: "Other Expense",
          ),
        );
      }

      // 5. Get Total Count
      final totalCount = await _countTotalOutflowTransactions(
        db,
        companyId,
        startDate: startDate,
        endDate: endDate,
        purchaseType: purchaseType,
      );

      return {
        'items': data,
        'totalCount': totalCount,
        'currentPage': page,
        'totalPages': (totalCount / pageSize).ceil(),
      };
    } catch (e) {
      throw Exception('Failed to get cash outflow transactions: $e');
    }
  }

  Future<List<PurchaseOrderHeader>> _fetchPurchaseOrdersForCashFlow(
    Database db,
    int companyId, {
    required int limit,
    required int offset,
    DateTime? startDate,
    DateTime? endDate,
    String? purchaseType,
  }) async {
    String where = 'company = ?';
    List<dynamic> whereArgs = [companyId];

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
      where += ' AND date_transation BETWEEN ? AND ?';
      whereArgs.add(start.toIso8601String());
      whereArgs.add(end.toIso8601String());
    }

    if (purchaseType != null && purchaseType.isNotEmpty) {
      if (purchaseType.toLowerCase() == 'credit') {
        where +=
            ' AND payment_term IS NOT NULL AND amount_grand_total_cost <> 0.0';
      } else if (purchaseType.toLowerCase() == 'cash') {
        where += ' AND payment_term IS NULL';
      }
    }

    final query =
        '''
      SELECT * FROM purchase_order_header
      WHERE $where
      ORDER BY date_transation DESC
      LIMIT ? OFFSET ?
    ''';

    final result = await db.rawQuery(query, [...whereArgs, limit, offset]);
    return result.map((map) => PurchaseOrderHeader.fromMap(map)).toList();
  }

  Future<List<OtherExpense>> _fetchOtherExpensesForCashFlow(
    Database db,
    int companyId, {
    required int limit,
    required int offset,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    String where = 'company = ?';
    List<dynamic> whereArgs = [companyId];

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
      where += ' AND date_payment BETWEEN ? AND ?';
      whereArgs.add(start.toIso8601String());
      whereArgs.add(end.toIso8601String());
    }

    final query =
        '''
      SELECT * FROM other_expense_table
      WHERE $where
      ORDER BY date_payment DESC
      LIMIT ? OFFSET ?
    ''';

    final result = await db.rawQuery(query, [...whereArgs, limit, offset]);
    return result.map((map) => OtherExpense.fromMap(map)).toList();
  }

  Future<int> _countTotalOutflowTransactions(
    Database db,
    int companyId, {
    DateTime? startDate,
    DateTime? endDate,
    String? purchaseType,
  }) async {
    // Count Purchase Orders
    String poWhere = 'company = ?';
    List<dynamic> poArgs = [companyId];

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
      poWhere += ' AND date_transation BETWEEN ? AND ?';
      poArgs.add(start.toIso8601String());
      poArgs.add(end.toIso8601String());
    }

    // Status Logic for Count
    if (purchaseType != null && purchaseType.isNotEmpty) {
      if (purchaseType.toLowerCase() == 'credit') {
        poWhere +=
            ' AND payment_term IS NOT NULL AND amount_grand_total_cost <> 0.0';
      } else if (purchaseType.toLowerCase() == 'cash') {
        poWhere += ' AND payment_term IS NULL';
      }
    }

    final poCountResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM purchase_order_header WHERE $poWhere',
      poArgs,
    );
    final poCount = Sqflite.firstIntValue(poCountResult) ?? 0;

    // Count Other Expenses
    String expWhere = 'company = ?';
    List<dynamic> expArgs = [companyId];

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
      expWhere += ' AND date_payment BETWEEN ? AND ?';
      expArgs.add(start.toIso8601String());
      expArgs.add(end.toIso8601String());
    }

    final expCountResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM other_expense_table WHERE $expWhere',
      expArgs,
    );
    final expCount = Sqflite.firstIntValue(expCountResult) ?? 0;

    return poCount + expCount;
  }

  Future<Map<String, dynamic>> calculateCashOutFlowTotals({
    required int companyId,
    DateTime? startDate,
    DateTime? endDate,
    String? purchaseType,
  }) async {
    final db = await _db;
    try {
      // 1. Calculate Purchase Totals
      String poWhere = 'company = ?';
      List<dynamic> poArgs = [companyId];

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
        poWhere += ' AND date_transation BETWEEN ? AND ?';
        poArgs.add(start.toIso8601String());
        poArgs.add(end.toIso8601String());
      }

      if (purchaseType != null && purchaseType.isNotEmpty) {
        if (purchaseType.toLowerCase() == 'credit') {
          poWhere +=
              ' AND payment_term IS NOT NULL AND amount_grand_total_cost <> 0.0';
        } else if (purchaseType.toLowerCase() == 'cash') {
          poWhere += ' AND payment_term IS NULL';
        }
      }

      final poQuery =
          '''
        SELECT 
          COUNT(*) as count,
          COALESCE(SUM(amount_grand_total_cost), 0.0) as total_amount
        FROM purchase_order_header
        WHERE $poWhere
      ''';
      final poResult = await db.rawQuery(poQuery, poArgs);
      final poCount = (poResult.first['count'] as int?) ?? 0;
      final poAmount =
          (poResult.first['total_amount'] as num?)?.toDouble() ?? 0.0;

      // 2. Calculate Other Expense Totals
      String expWhere = 'company = ?';
      List<dynamic> expArgs = [companyId];

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
        expWhere += ' AND date_payment BETWEEN ? AND ?';
        expArgs.add(start.toIso8601String());
        expArgs.add(end.toIso8601String());
      }

      final expQuery =
          '''
        SELECT 
          COUNT(*) as count,
          COALESCE(SUM(payment_amount), 0.0) as total_amount
        FROM other_expense_table
        WHERE $expWhere
      ''';
      final expResult = await db.rawQuery(expQuery, expArgs);
      final expCount = (expResult.first['count'] as int?) ?? 0;
      final expAmount =
          (expResult.first['total_amount'] as num?)?.toDouble() ?? 0.0;

      return {
        'totalCredit': poAmount + expAmount,
        'totalCount': poCount + expCount,
      };
    } catch (e) {
      throw Exception('Failed to calculate cash out flow totals: $e');
    }
  }

  // ============================================================================
  // RESTORED INFLOW HELPER METHODS
  // ============================================================================

  Future<List<SalesOrderHeader>> _fetchSalesOrdersForCashFlow(
    Database db,
    int companyId, {
    required int limit,
    required int offset,
    DateTime? startDate,
    DateTime? endDate,
    String? salesType,
  }) async {
    String where = 'company = ?';
    List<dynamic> whereArgs = [companyId];

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
      where += ' AND order_date BETWEEN ? AND ?';
      whereArgs.add(start.toIso8601String());
      whereArgs.add(end.toIso8601String());
    }

    if (salesType != null && salesType.isNotEmpty) {
      where += ' AND sales_type = ?';
      whereArgs.add(salesType);
    }

    // Default: exclude voided orders (though Java code didn't explicitly show this, it's safer)
    where += ' AND (void_indicator IS NULL OR void_indicator = "")';

    final query =
        '''
      SELECT * FROM sales_order_header
      WHERE $where
      ORDER BY order_date DESC
      LIMIT ? OFFSET ?
    ''';

    final result = await db.rawQuery(query, [...whereArgs, limit, offset]);
    return result.map((map) => SalesOrderHeader.fromMap(map)).toList();
  }

  Future<List<OtherIncome>> _fetchOtherIncomeForCashFlow(
    Database db,
    int companyId, {
    required int limit,
    required int offset,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    String where = 'company = ?';
    List<dynamic> whereArgs = [companyId];

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
      where += ' AND date_income BETWEEN ? AND ?';
      whereArgs.add(start.toIso8601String());
      whereArgs.add(end.toIso8601String());
    }

    final query =
        '''
      SELECT * FROM other_income_table
      WHERE $where
      ORDER BY date_income DESC
      LIMIT ? OFFSET ?
    ''';

    final result = await db.rawQuery(query, [...whereArgs, limit, offset]);
    return result.map((map) => OtherIncome.fromMap(map)).toList();
  }

  Future<int> _countTotalInflowTransactions(
    Database db,
    int companyId, {
    DateTime? startDate,
    DateTime? endDate,
    String? salesType,
  }) async {
    // Count Sales Orders
    String salesWhere = 'company = ?';
    List<dynamic> salesArgs = [companyId];

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
      salesWhere += ' AND order_date BETWEEN ? AND ?';
      salesArgs.add(start.toIso8601String());
      salesArgs.add(end.toIso8601String());
    }
    if (salesType != null && salesType.isNotEmpty) {
      salesWhere += ' AND sales_type = ?';
      salesArgs.add(salesType);
    }
    salesWhere += ' AND (void_indicator IS NULL OR void_indicator = "")';

    final salesCountResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM sales_order_header WHERE $salesWhere',
      salesArgs,
    );
    final salesCount = Sqflite.firstIntValue(salesCountResult) ?? 0;

    // Count Other Income
    String incomeWhere = 'company = ?';
    List<dynamic> incomeArgs = [companyId];

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
      incomeWhere += ' AND date_income BETWEEN ? AND ?';
      incomeArgs.add(start.toIso8601String());
      incomeArgs.add(end.toIso8601String());
    }

    final incomeCountResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM other_income_table WHERE $incomeWhere',
      incomeArgs,
    );
    final incomeCount = Sqflite.firstIntValue(incomeCountResult) ?? 0;

    return salesCount + incomeCount;
  }

  Future<Map<String, dynamic>> calculateCashInFlowTotals({
    required int companyId,
    // Removed customerId as it's not applicable to Other Income and not in getCashInflowTransactions
    DateTime? startDate,
    DateTime? endDate,
    String? salesType,
  }) async {
    final db = await _db;
    try {
      // 1. Calculate Sales Totals
      String salesWhere = 'company = ?';
      List<dynamic> salesArgs = [companyId];

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
        salesWhere += ' AND order_date BETWEEN ? AND ?';
        salesArgs.add(start.toIso8601String());
        salesArgs.add(end.toIso8601String());
      }
      if (salesType != null && salesType.isNotEmpty) {
        salesWhere += ' AND sales_type = ?';
        salesArgs.add(salesType);
      }
      salesWhere += ' AND (void_indicator IS NULL OR void_indicator = "")';

      final salesQuery =
          '''
        SELECT 
          COUNT(*) as count,
          COALESCE(SUM(amount_total), 0.0) as total_amount
        FROM sales_order_header
        WHERE $salesWhere
      ''';
      final salesResult = await db.rawQuery(salesQuery, salesArgs);
      final salesCount = (salesResult.first['count'] as int?) ?? 0;
      final salesAmount =
          (salesResult.first['total_amount'] as num?)?.toDouble() ?? 0.0;

      // 2. Calculate Other Income Totals
      String incomeWhere = 'company = ?';
      List<dynamic> incomeArgs = [companyId];

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
        incomeWhere += ' AND date_income BETWEEN ? AND ?';
        incomeArgs.add(start.toIso8601String());
        incomeArgs.add(end.toIso8601String());
      }

      final incomeQuery =
          '''
        SELECT 
          COUNT(*) as count,
          COALESCE(SUM(income_amount), 0.0) as total_amount
        FROM other_income_table
        WHERE $incomeWhere
      ''';
      final incomeResult = await db.rawQuery(incomeQuery, incomeArgs);
      final incomeCount = (incomeResult.first['count'] as int?) ?? 0;
      final incomeAmount =
          (incomeResult.first['total_amount'] as num?)?.toDouble() ?? 0.0;

      return {
        'totalDebit': salesAmount + incomeAmount,
        'totalCount': salesCount + incomeCount,
      };
    } catch (e) {
      throw Exception('Failed to calculate cash in flow totals: $e');
    }
  }
  // ============================================================================
  // CASH FLOW SUMMARY REPORT METHODS
  // ============================================================================

  /// Get combined cash flow transactions (Sales + Income + Purchase + Expenses)
  /// Following the Java logic of group-based ordering
  Future<Map<String, dynamic>> getCashFlowSummaryTransactions({
    required int companyId,
    required int page,
    required int pageSize,
    DateTime? startDate,
    DateTime? endDate,
    String?
    status, // Can be used for salesType or purchaseType filtering if needed
  }) async {
    final db = await _db;

    try {
      // 1. Fetch Sales (Filtered by company/date)
      final salesOrders = await _fetchSalesOrdersForSummary(
        db,
        companyId,
        startDate,
        endDate,
        status,
      );

      // 2. Fetch Other Income
      final otherIncomeList = await _fetchOtherIncomeForSummary(
        db,
        companyId,
        startDate,
        endDate,
      );

      // 3. Fetch Purchases
      final purchaseOrders = await _fetchPurchaseOrdersForSummary(
        db,
        companyId,
        startDate,
        endDate,
        status,
      );

      // 4. Fetch Other Expenses
      final otherExpenses = await _fetchOtherExpensesForSummary(
        db,
        companyId,
        startDate,
        endDate,
      );

      List<CashflowTransactionReportDTO> allRecords = [];

      // Map and add in Accounting Order
      for (var sH in salesOrders) {
        allRecords.add(
          CashflowTransactionReportDTO(
            reference: "SO-${sH.fsNumber ?? ''}",
            cashCredit: sH.paymentMethod ?? '',
            date: sH.orderDate ?? DateTime.now(),
            amount: sH.amountTotal ?? 0.0,
            orderType: "Sales",
          ),
        );
      }

      for (var inc in otherIncomeList) {
        allRecords.add(
          CashflowTransactionReportDTO(
            reference: inc.reasonDescription ?? '',
            cashCredit: "",
            date: inc.dateIncome ?? DateTime.now(),
            amount: inc.incomeAmount ?? 0.0,
            orderType: "Other Income",
          ),
        );
      }

      for (var po in purchaseOrders) {
        allRecords.add(
          CashflowTransactionReportDTO(
            reference: "PO-${po.orderNumber ?? ''}",
            cashCredit: po.paymentTerm != null ? "Credit" : "Cash",
            date: po.dateTransation ?? DateTime.now(),
            amount: po.amountGrandTotalCost ?? 0.0,
            orderType: "Purchase",
          ),
        );
      }

      for (var exp in otherExpenses) {
        allRecords.add(
          CashflowTransactionReportDTO(
            reference: exp.reasonDescription ?? '',
            cashCredit: "",
            date: exp.datePayment ?? DateTime.now(),
            amount: exp.paymentAmount ?? 0.0,
            orderType: "Other Expense",
          ),
        );
      }

      // Memory-based pagination as per Java LazyDataModel.load()
      final first = (page - 1) * pageSize;
      final totalCount = allRecords.length;

      int toIndex = (first + pageSize).clamp(0, totalCount);
      List<CashflowTransactionReportDTO> pagedData = [];

      if (first < toIndex) {
        pagedData = allRecords.sublist(first, toIndex);
      }

      return {
        'items': pagedData,
        'totalCount': totalCount,
        'currentPage': page,
        'totalPages': (totalCount / pageSize).ceil(),
      };
    } catch (e) {
      throw Exception('Failed to get cash flow summary: $e');
    }
  }

  Future<CashFlowSummaryTotals> calculateCashFlowSummaryTotals({
    required int companyId,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) async {
    try {
      // Reuse existing logic but combine
      final inflowRes = await calculateCashInFlowTotals(
        companyId: companyId,
        startDate: startDate,
        endDate: endDate,
        salesType: status,
      );

      final outflowRes = await calculateCashOutFlowTotals(
        companyId: companyId,
        startDate: startDate,
        endDate: endDate,
        purchaseType: status,
      );

      final totalInflow = (inflowRes['totalDebit'] as num?)?.toDouble() ?? 0.0;
      final totalOutflow =
          (outflowRes['totalCredit'] as num?)?.toDouble() ?? 0.0;

      return CashFlowSummaryTotals(
        totalInflow: totalInflow,
        totalOutflow: totalOutflow,
        netCashFlow: totalInflow - totalOutflow,
        totalCount:
            ((inflowRes['totalCount'] as int?) ?? 0) +
            ((outflowRes['totalCount'] as int?) ?? 0),
      );
    } catch (e) {
      throw Exception('Failed to calculate cash flow summary totals: $e');
    }
  }

  // Helper methods without pagination for summary merging

  Future<List<SalesOrderHeader>> _fetchSalesOrdersForSummary(
    Database db,
    int companyId,
    DateTime? start,
    DateTime? end,
    String? type,
  ) async {
    String where = 'company = ?';
    List<dynamic> args = [companyId];
    if (start != null && end != null) {
      where += ' AND order_date BETWEEN ? AND ?';
      args.addAll([start.toIso8601String(), end.toIso8601String()]);
    }
    if (type != null && type.isNotEmpty) {
      where += ' AND sales_type = ?';
      args.add(type);
    }
    where += ' AND (void_indicator IS NULL OR void_indicator = "")';
    final result = await db.query(
      'sales_order_header',
      where: where,
      whereArgs: args,
      orderBy: 'order_date DESC',
    );
    return result.map((m) => SalesOrderHeader.fromMap(m)).toList();
  }

  Future<List<OtherIncome>> _fetchOtherIncomeForSummary(
    Database db,
    int companyId,
    DateTime? start,
    DateTime? end,
  ) async {
    String where = 'company = ?';
    List<dynamic> args = [companyId];
    if (start != null && end != null) {
      where += ' AND date_income BETWEEN ? AND ?';
      args.addAll([start.toIso8601String(), end.toIso8601String()]);
    }
    final result = await db.query(
      'other_income_table',
      where: where,
      whereArgs: args,
      orderBy: 'date_income DESC',
    );
    return result.map((m) => OtherIncome.fromMap(m)).toList();
  }

  Future<List<PurchaseOrderHeader>> _fetchPurchaseOrdersForSummary(
    Database db,
    int companyId,
    DateTime? start,
    DateTime? end,
    String? type,
  ) async {
    String where = 'company = ?';
    List<dynamic> args = [companyId];
    if (start != null && end != null) {
      where += ' AND date_transation BETWEEN ? AND ?';
      args.addAll([start.toIso8601String(), end.toIso8601String()]);
    }
    if (type != null && type.isNotEmpty) {
      if (type.toLowerCase() == 'credit') {
        where +=
            ' AND payment_term IS NOT NULL AND amount_grand_total_cost <> 0.0';
      } else if (type.toLowerCase() == 'cash') {
        where += ' AND payment_term IS NULL';
      }
    }
    final result = await db.query(
      'purchase_order_header',
      where: where,
      whereArgs: args,
      orderBy: 'date_transation DESC',
    );
    return result.map((m) => PurchaseOrderHeader.fromMap(m)).toList();
  }

  Future<List<OtherExpense>> _fetchOtherExpensesForSummary(
    Database db,
    int companyId,
    DateTime? start,
    DateTime? end,
  ) async {
    String where = 'company = ?';
    List<dynamic> args = [companyId];
    if (start != null && end != null) {
      where += ' AND date_payment BETWEEN ? AND ?';
      args.addAll([start.toIso8601String(), end.toIso8601String()]);
    }
    final result = await db.query(
      'other_expense_table',
      where: where,
      whereArgs: args,
      orderBy: 'date_payment DESC',
    );
    return result.map((m) => OtherExpense.fromMap(m)).toList();
  }
}
