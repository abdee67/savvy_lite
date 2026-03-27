// features/sales/invoice_history/repo/invoice_history_header_repo.dart
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/sales/sales_order/invoice/header/model/invoice_header_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:savvy_stock/core/repositories/base_repo.dart';

class InvoiceHistoryHeaderRepository  extends BaseRepository{
  @override
  final LocalDatabaseService databaseService;

  InvoiceHistoryHeaderRepository({required this.databaseService});

  // Table name
  static const String tableName = 'invoice_history_header';

  // Get all invoice history headers by company - equivalent to Java's getItems()
  Future<List<InvoiceHistoryHeader>> getInvoiceHistoryHeadersByCompany(
    int companyId,
  ) async {
    final db = await databaseService.database;

    try {
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'company = ?',
        whereArgs: [companyId],
        orderBy: 'date_transaction DESC, id DESC',
      );

      return maps.map((map) => InvoiceHistoryHeader.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get invoice history headers by company: $e');
    }
  }

  // Get invoice history header by ID - equivalent to Java's getInvoiceHistoryHeader()
  Future<InvoiceHistoryHeader?> getInvoiceHistoryHeaderById(int id) async {
    final db = await databaseService.database;

    try {
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isNotEmpty) {
        return InvoiceHistoryHeader.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get invoice history header by ID: $e');
    }
  }

  // Get invoice history header by FS number
  Future<InvoiceHistoryHeader?> getInvoiceHistoryHeaderByFsNumber(
    String fsNumber,
    int companyId,
  ) async {
    final db = await databaseService.database;

    try {
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'fs_number = ? AND company = ?',
        whereArgs: [fsNumber, companyId],
      );

      if (maps.isNotEmpty) {
        return InvoiceHistoryHeader.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get invoice history header by FS number: $e');
    }
  }

  // Get last FS number for sequential generation
  Future<String?> getLastFsNumber(int companyId) async {
    final db = await databaseService.database;

    try {
      final result = await db.rawQuery(
        '''
        SELECT fs_number 
        FROM $tableName 
        WHERE company = ? 
        AND fs_number IS NOT NULL 
        AND fs_number != ''
        ORDER BY 
          CAST(SUBSTR(fs_number, 1) AS INTEGER) DESC,
          fs_number DESC 
        LIMIT 1
      ''',
        [companyId],
      );

      if (result.isNotEmpty) {
        return result.first['fs_number'] as String?;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get last FS number: $e');
    }
  }

  // Create invoice history header - equivalent to Java's getFacade().create()
  Future<int> createInvoiceHistoryHeader(InvoiceHistoryHeader header) async {
    final db = await databaseService.database;

    try {
      final id = await db.insert(
        tableName, withSyncKey(header.toMap()),
        conflictAlgorithm: ConflictAlgorithm.fail,
      );

      captureSync(
        tableName: tableName,
        entityMap: header.toMap(),
        entityId: id.toString(),
        operation: 'INSERT',
        company: header.company?.toString(),
      );

      return id;
    } catch (e) {
      throw Exception('Failed to create invoice history header: $e');
    }
  }

  // Update invoice history header - equivalent to Java's getFacade().edit()
  Future<int> updateInvoiceHistoryHeader(InvoiceHistoryHeader header) async {
    final db = await databaseService.database;

    try {
      if (header.id == null) {
        throw Exception('Cannot update invoice history header without ID');
      }

      final count = await db.update(
        tableName,
        header.toMap(),
        where: 'id = ?',
        whereArgs: [header.id],
      );

      if (count == 0) {
        throw Exception(
          'No invoice history header found with ID: ${header.id}',
        );
      }

      captureSync(
        tableName: tableName,
        entityMap: header.toMap(),
        entityId: header.id.toString(),
        operation: 'UPDATE',
        company: header.company?.toString(),
      );

      return count;
    } catch (e) {
      throw Exception('Failed to update invoice history header: $e');
    }
  }

  // Delete invoice history header - equivalent to Java's getFacade().remove()
  Future<int> deleteInvoiceHistoryHeader(int id) async {
    final db = await databaseService.database;

    try {
      final count = await db.delete(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (count == 0) {
        throw Exception('No invoice history header found with ID: $id');
      }

      captureSync(
        tableName: tableName,
        entityMap: {'id': id},
        entityId: id.toString(),
        operation: 'DELETE',
      );

      return count;
    } catch (e) {
      throw Exception('Failed to delete invoice history header: $e');
    }
  }

  // Delete multiple invoice history headers - equivalent to Java's removeCollection()
  Future<int> deleteMultipleInvoiceHistoryHeaders(List<int> ids, int companyId) async {
    final db = await databaseService.database;

    try {
      final placeholders = List.filled(ids.length, '?').join(',');

      final count = await db.rawDelete('''
        DELETE FROM $tableName 
        WHERE id IN ($placeholders)
      ''', ids);

      captureSync(
        tableName: tableName,
        entityMap: {'id': ids},
        entityId: ids.toString(),
        operation: 'DELETE',
        company: companyId.toString(),
      );

      return count;
    } catch (e) {
      throw Exception('Failed to delete multiple invoice history headers: $e');
    }
  }

  // Filter invoice history headers with comprehensive filtering
  Future<List<InvoiceHistoryHeader>> filterInvoiceHistoryHeaders({
    required int companyId,
    String? customerName,
    String? fsNumber,
    String? tinNumber,
    DateTime? startDate,
    DateTime? endDate,
    String? salesPerson,
    String? mrcNumber,
    double? minTotalAmount,
    double? maxTotalAmount,
  }) async {
    final db = await databaseService.database;

    try {
      final where = StringBuffer('company = ?');
      final whereArgs = <dynamic>[companyId];

      if (customerName != null && customerName.isNotEmpty) {
        where.write(' AND customer_name LIKE ?');
        whereArgs.add('%$customerName%');
      }

      if (fsNumber != null && fsNumber.isNotEmpty) {
        where.write(' AND fs_number LIKE ?');
        whereArgs.add('%$fsNumber%');
      }

      if (tinNumber != null && tinNumber.isNotEmpty) {
        where.write(' AND tin_number LIKE ?');
        whereArgs.add('%$tinNumber%');
      }

      if (startDate != null) {
        where.write(' AND date_transaction >= ?');
        whereArgs.add(startDate.toIso8601String());
      }

      if (endDate != null) {
        where.write(' AND date_transaction <= ?');
        whereArgs.add(endDate.toIso8601String());
      }

      if (salesPerson != null && salesPerson.isNotEmpty) {
        where.write(' AND sales_person LIKE ?');
        whereArgs.add('%$salesPerson%');
      }

      if (mrcNumber != null && mrcNumber.isNotEmpty) {
        where.write(' AND mrc_number LIKE ?');
        whereArgs.add('%$mrcNumber%');
      }

      if (minTotalAmount != null) {
        where.write(' AND total_amount >= ?');
        whereArgs.add(minTotalAmount);
      }

      if (maxTotalAmount != null) {
        where.write(' AND total_amount <= ?');
        whereArgs.add(maxTotalAmount);
      }

      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: where.toString(),
        whereArgs: whereArgs,
        orderBy: 'date_transaction DESC, id DESC',
      );

      return maps.map((map) => InvoiceHistoryHeader.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to filter invoice history headers: $e');
    }
  }

  // Get invoice history headers with date range
  Future<List<InvoiceHistoryHeader>> getInvoiceHistoryHeadersWithDateRange({
    required int companyId,
    required DateTime startDate,
    required DateTime endDate,
    int? limit,
    int? offset,
  }) async {
    final db = await databaseService.database;

    try {
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'company = ? AND date_transaction BETWEEN ? AND ?',
        whereArgs: [
          companyId,
          startDate.toIso8601String(),
          endDate.toIso8601String(),
        ],
        orderBy: 'date_transaction DESC, id DESC',
        limit: limit,
        offset: offset,
      );

      return maps.map((map) => InvoiceHistoryHeader.fromMap(map)).toList();
    } catch (e) {
      throw Exception(
        'Failed to get invoice history headers with date range: $e',
      );
    }
  }

  // Count invoice history headers
  Future<int> countInvoiceHistoryHeaders({
    required int companyId,
    String? customerName,
    String? fsNumber,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await databaseService.database;

    try {
      final where = StringBuffer('company = ?');
      final whereArgs = <dynamic>[companyId];

      if (customerName != null && customerName.isNotEmpty) {
        where.write(' AND customer_name LIKE ?');
        whereArgs.add('%$customerName%');
      }

      if (fsNumber != null && fsNumber.isNotEmpty) {
        where.write(' AND fs_number LIKE ?');
        whereArgs.add('%$fsNumber%');
      }

      if (startDate != null) {
        where.write(' AND date_transaction >= ?');
        whereArgs.add(startDate.toIso8601String());
      }

      if (endDate != null) {
        where.write(' AND date_transaction <= ?');
        whereArgs.add(endDate.toIso8601String());
      }

      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $tableName WHERE ${where.toString()}',
        whereArgs,
      );

      return result.first['count'] as int;
    } catch (e) {
      throw Exception('Failed to count invoice history headers: $e');
    }
  }

  // Get all invoice history headers (for super users)
  Future<List<InvoiceHistoryHeader>> getAllInvoiceHistoryHeaders() async {
    final db = await databaseService.database;

    try {
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        orderBy: 'date_transaction DESC, id DESC',
      );

      return maps.map((map) => InvoiceHistoryHeader.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get all invoice history headers: $e');
    }
  }

  // Get items available for select many
  Future<List<InvoiceHistoryHeader>> getItemsAvailableSelectMany(
    int companyId,
  ) async {
    final db = await databaseService.database;

    try {
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'company = ?',
        whereArgs: [companyId],
        orderBy: 'customer_name, date_transaction DESC',
      );

      return maps.map((map) => InvoiceHistoryHeader.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get items available for select many: $e');
    }
  }

  // Get items available for select one
  Future<List<InvoiceHistoryHeader>> getItemsAvailableSelectOne(
    int companyId,
  ) async {
    final db = await databaseService.database;

    try {
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'company = ?',
        whereArgs: [companyId],
        orderBy: 'customer_name, date_transaction DESC',
        limit: 100,
      );

      return maps.map((map) => InvoiceHistoryHeader.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get items available for select one: $e');
    }
  }

  // Batch operations for multiple creates/updates/deletes
  Future<void> batchOperations({
    required List<InvoiceHistoryHeader> itemsToCreate,
    required List<InvoiceHistoryHeader> itemsToUpdate,
    required List<int> itemsToDelete,
  }) async {
    final db = await databaseService.database;

    final batch = db.batch();

    try {
      // Create operations
      for (final header in itemsToCreate) {
        batch.insert(tableName, header.toMap());
      }

      // Update operations
      for (final header in itemsToUpdate) {
        if (header.id != null) {
          batch.update(
            tableName,
            header.toMap(),
            where: 'id = ?',
            whereArgs: [header.id],
          );
        }
      }

      // Delete operations
      for (final id in itemsToDelete) {
        batch.delete(tableName, where: 'id = ?', whereArgs: [id]);
      }

      await batch.commit(noResult: true);
    } catch (e) {
      throw Exception('Failed to perform batch operations: $e');
    }
  }

  // Search invoice history headers
  Future<List<InvoiceHistoryHeader>> searchInvoiceHistoryHeaders({
    required int companyId,
    required String query,
    int limit = 50,
  }) async {
    final db = await databaseService.database;

    try {
      final searchQuery = '%$query%';

      final List<Map<String, dynamic>> maps = await db.rawQuery(
        '''
        SELECT * FROM $tableName 
        WHERE company = ? 
        AND (
          fs_number LIKE ? 
          OR customer_name LIKE ? 
          OR tin_number LIKE ?
          OR sales_person LIKE ?
          OR mrc_number LIKE ?
        )
        ORDER BY 
          CASE 
            WHEN fs_number LIKE ? THEN 1
            WHEN customer_name LIKE ? THEN 2
            WHEN tin_number LIKE ? THEN 3
            ELSE 4
          END,
          date_transaction DESC
        LIMIT ?
      ''',
        [
          companyId,
          searchQuery,
          searchQuery,
          searchQuery,
          searchQuery,
          searchQuery,
          searchQuery,
          searchQuery,
          searchQuery,
          limit,
        ],
      );

      return maps.map((map) => InvoiceHistoryHeader.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to search invoice history headers: $e');
    }
  }

  // Get recent invoice history headers
  Future<List<InvoiceHistoryHeader>> getRecentInvoiceHistoryHeaders({
    required int companyId,
    int limit = 10,
  }) async {
    final db = await databaseService.database;

    try {
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'company = ?',
        whereArgs: [companyId],
        orderBy: 'date_transaction DESC, id DESC',
        limit: limit,
      );

      return maps.map((map) => InvoiceHistoryHeader.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get recent invoice history headers: $e');
    }
  }

  // Check if FS number exists
  Future<bool> doesFsNumberExist({
    required String fsNumber,
    required int companyId,
    int? excludeId,
  }) async {
    final db = await databaseService.database;

    try {
      final where = StringBuffer('fs_number = ? AND company = ?');
      final whereArgs = <dynamic>[fsNumber, companyId];

      if (excludeId != null) {
        where.write(' AND id != ?');
        whereArgs.add(excludeId);
      }

      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: where.toString(),
        whereArgs: whereArgs,
        limit: 1,
      );

      return maps.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check if FS number exists: $e');
    }
  }

  // Get invoice statistics for dashboard
  Future<Map<String, dynamic>> getInvoiceStatistics({
    required int companyId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await databaseService.database;

    try {
      final result = await db.rawQuery(
        '''
        SELECT 
          COUNT(*) as total_invoices,
          SUM(total_amount) as total_revenue,
          SUM(tax_amount) as total_tax,
          SUM(withhold_amount) as total_withholding,
          SUM(discount_amount) as total_discount,
          AVG(total_amount) as average_invoice_amount,
          MAX(total_amount) as largest_invoice,
          MIN(total_amount) as smallest_invoice
        FROM $tableName 
        WHERE company = ? 
        AND date_transaction BETWEEN ? AND ?
      ''',
        [companyId, startDate.toIso8601String(), endDate.toIso8601String()],
      );

      if (result.isNotEmpty) {
        return {
          'totalInvoices': result.first['total_invoices'] as int? ?? 0,
          'totalRevenue': result.first['total_revenue'] as double? ?? 0.0,
          'totalTax': result.first['total_tax'] as double? ?? 0.0,
          'totalWithholding':
              result.first['total_withholding'] as double? ?? 0.0,
          'totalDiscount': result.first['total_discount'] as double? ?? 0.0,
          'averageInvoiceAmount':
              result.first['average_invoice_amount'] as double? ?? 0.0,
          'largestInvoice': result.first['largest_invoice'] as double? ?? 0.0,
          'smallestInvoice': result.first['smallest_invoice'] as double? ?? 0.0,
        };
      }

      return {
        'totalInvoices': 0,
        'totalRevenue': 0.0,
        'totalTax': 0.0,
        'totalWithholding': 0.0,
        'totalDiscount': 0.0,
        'averageInvoiceAmount': 0.0,
        'largestInvoice': 0.0,
        'smallestInvoice': 0.0,
      };
    } catch (e) {
      throw Exception('Failed to get invoice statistics: $e');
    }
  }

  // Get top customers by revenue
  Future<List<Map<String, dynamic>>> getTopCustomersByRevenue({
    required int companyId,
    required DateTime startDate,
    required DateTime endDate,
    int limit = 10,
  }) async {
    final db = await databaseService.database;

    try {
      final result = await db.rawQuery(
        '''
        SELECT 
          customer_name,
          COUNT(*) as invoice_count,
          SUM(total_amount) as total_revenue,
          AVG(total_amount) as average_revenue
        FROM $tableName 
        WHERE company = ? 
        AND date_transaction BETWEEN ? AND ?
        AND customer_name IS NOT NULL 
        AND customer_name != ''
        GROUP BY customer_name
        ORDER BY total_revenue DESC
        LIMIT ?
      ''',
        [
          companyId,
          startDate.toIso8601String(),
          endDate.toIso8601String(),
          limit,
        ],
      );

      return result.map((map) {
        return {
          'customerName': map['customer_name'],
          'invoiceCount': map['invoice_count'] as int,
          'totalRevenue': map['total_revenue'] as double? ?? 0.0,
          'averageRevenue': map['average_revenue'] as double? ?? 0.0,
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to get top customers by revenue: $e');
    }
  }

  // Generate next FS number sequentially
  Future<String> generateNextFsNumber(int companyId) async {
    final lastFsNumber = await getLastFsNumber(companyId);

    if (lastFsNumber == null || lastFsNumber.isEmpty) {
      return '00000001';
    }

    try {
      // Extract numeric part and increment
      final numericPart = int.tryParse(lastFsNumber) ?? 0;
      final nextNumber = numericPart + 1;

      return nextNumber.toString().padLeft(8, '0');
    } catch (e) {
      throw Exception('Failed to generate next FS number: $e');
    }
  }
}
