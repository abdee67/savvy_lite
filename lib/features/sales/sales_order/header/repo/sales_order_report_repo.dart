// repositories/sales_order_header_repository.dart
import 'dart:async';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/sales/sales_order/detail/model/sales_order_detail.dart';
import 'package:savvy_stock/features/sales/sales_order/header/model/credit_receipt_model.dart';
import 'package:savvy_stock/features/sales/sales_order/header/model/sales_order_header.dart';
import 'package:sqflite/sqflite.dart';

class SalesOrderReportRepository {
  static final SalesOrderReportRepository _instance =
      SalesOrderReportRepository._internal();
  factory SalesOrderReportRepository() => _instance;
  SalesOrderReportRepository._internal();

  Future<Database> get _db async => LocalDatabaseService().database;
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
          emp.phone_home as employee_phone,
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

  // ============================================================================
  // CREDIT RECEIPT REPORT METHODS
  // ============================================================================

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

      String orderBy = 'soh.order_date DESC, soh.id DESC';

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
          ot.detail_code as order_type_code,
          emp.name_first as employee_name_first,
          emp.name_middle as employee_name_middle,
          emp.name_last as employee_name_last
        FROM sales_order_header soh
        LEFT JOIN customer_table cust ON soh.customer_bill_to = cust.id
        LEFT JOIN udc_details pi ON soh.payment_instrument = pi.id
        LEFT JOIN udc_details ot ON soh.order_type = ot.id
        LEFT JOIN employees emp ON soh.employees_id = emp.id
        WHERE $where
        ORDER BY $orderBy
        LIMIT ? OFFSET ?
      ''';

      final queryArgs = [...whereArgs, pageSize, offset];
      final maps = await db.rawQuery(query, queryArgs);

      final headers = maps.map((map) {
        final header = SalesOrderHeader.fromMap(map);

        // Calculate Aged Credit (Days) as per Java logic
        double calculatedAgedDays = 0.0;
        if (header.orderDate != null) {
          double paymentTermAmount = (header.paymentTerm ?? 0).toDouble();
          DateTime dueDate = header.orderDate!.add(
            Duration(days: paymentTermAmount.toInt()),
          );
          DateTime currentDate = DateTime.now();

          // Java: ChronoUnit.DAYS.between(dueDate, currentDate)
          // Difference in days.
          int diffDays = currentDate.difference(dueDate).inDays;
          calculatedAgedDays = diffDays > 0 ? diffDays.toDouble() : 0.0;
        }

        return header.copyWith(agedDays: calculatedAgedDays);
      }).toList();

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

  Future<Map<String, dynamic>> calculateAgedCreditReceiptTotals({
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
          COUNT(*) as total_count,
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
          'totalAmountprice': (row['total_amount'] as num?)?.toDouble() ?? 0.0,
          'paidpriceAmount': (row['total_paid'] as num?)?.toDouble() ?? 0.0,
          'remainingPriceAmount':
              (row['total_remaining'] as num?)?.toDouble() ?? 0.0,
          'totalCount': (row['total_count'] as int?) ?? 0,
        };
      }
      return {
        'totalAmountprice': 0.0,
        'paidpriceAmount': 0.0,
        'remainingPriceAmount': 0.0,
        'totalCount': 0,
      };
    } catch (e) {
      throw Exception('Failed to calculate aged credit receipt totals: $e');
    }
  }
}
