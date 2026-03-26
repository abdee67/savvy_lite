// features/sales/invoice_history/repo/invoice_history_detail_repo.dart
import 'package:savvy_stock/core/repositories/base_repo.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/sales/sales_order/invoice/detail/model/invoice_detail_model.dart';
import 'package:sqflite/sqflite.dart';

class InvoiceHistoryDetailRepository extends BaseRepository {
  @override
  final LocalDatabaseService databaseService;

  InvoiceHistoryDetailRepository({required this.databaseService});

  // Table name
  static const String tableName = 'invoice_history_detail';
  // Get all invoice history details by company - equivalent to Java's getItems()
  Future<List<InvoiceHistoryDetail>> getInvoiceHistoryDetailsByCompany(
    int companyId,
  ) async {
    final db = await databaseService.database;

    try {
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'company = ?',
        whereArgs: [companyId],
        orderBy: 'id DESC',
      );

      return maps.map((map) => InvoiceHistoryDetail.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get invoice history details by company: $e');
    }
  }

  // Get invoice history detail by ID - equivalent to Java's getInvoiceHistoryDetail()
  Future<InvoiceHistoryDetail?> getInvoiceHistoryDetailById(int id) async {
    final db = await databaseService.database;

    try {
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isNotEmpty) {
        return InvoiceHistoryDetail.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get invoice history detail by ID: $e');
    }
  }

  // Get invoice history details by invoice header ID
  Future<List<InvoiceHistoryDetail>> getInvoiceHistoryDetailsByHeaderId(
    int invoiceHistoryId,
    int companyId,
  ) async {
    final db = await databaseService.database;

    try {
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'invoice_history = ? AND company = ?',
        whereArgs: [invoiceHistoryId, companyId],
        orderBy: 'id ASC',
      );

      return maps.map((map) => InvoiceHistoryDetail.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get invoice history details by header ID: $e');
    }
  }

  // Get invoice history details by multiple header IDs
  Future<List<InvoiceHistoryDetail>> getInvoiceHistoryDetailsByHeaderIds(
    List<int> invoiceHistoryIds,
    int companyId,
  ) async {
    final db = await databaseService.database;

    try {
      if (invoiceHistoryIds.isEmpty) return [];

      final placeholders = List.filled(invoiceHistoryIds.length, '?').join(',');

      final List<Map<String, dynamic>> maps = await db.rawQuery(
        '''
        SELECT * FROM $tableName 
        WHERE invoice_history IN ($placeholders) 
        AND company = ?
        ORDER BY invoice_history, id ASC
      ''',
        [...invoiceHistoryIds, companyId],
      );

      return maps.map((map) => InvoiceHistoryDetail.fromMap(map)).toList();
    } catch (e) {
      throw Exception(
        'Failed to get invoice history details by header IDs: $e',
      );
    }
  }

  // Create invoice history detail - equivalent to Java's getFacade().create()
  Future<int> createInvoiceHistoryDetail(InvoiceHistoryDetail detail) async {
    final db = await databaseService.database;

    try {
      // Ensure extended price is calculated
      final detailToSave = detail.calculateExtendedPrice();
      final mapToSave = detailToSave.toMap();
      mapToSave.remove('id');

      final id = await db.insert(
        tableName,
        mapToSave,
        conflictAlgorithm: ConflictAlgorithm.fail,
      );

      mapToSave['id'] = id;
      captureSync(
        tableName: tableName,
        entityMap: mapToSave,
        entityId: id.toString(),
        operation: 'INSERT',
        company: detail.company?.toString(),
      );

      return id;
    } catch (e) {
      throw Exception('Failed to create invoice history detail: $e');
    }
  }

  // Create multiple invoice history details in batch
  Future<List<int>> createMultipleInvoiceHistoryDetails(
    List<InvoiceHistoryDetail> details,
  ) async {
    final db = await databaseService.database;
    final batch = db.batch();
    final ids = <int>[];

    try {
      for (final detail in details) {
        final detailToSave = detail.calculateExtendedPrice();
        batch.insert(tableName, detailToSave.toMap());
      }

      final results = await batch.commit();

      for (final result in results) {
        if (result is int) {
          ids.add(result);
        }
      }

      return ids;
    } catch (e) {
      throw Exception('Failed to create multiple invoice history details: $e');
    }
  }

  // Update invoice history detail - equivalent to Java's getFacade().edit()
  Future<int> updateInvoiceHistoryDetail(InvoiceHistoryDetail detail) async {
    final db = await databaseService.database;

    try {
      if (detail.id == null) {
        throw Exception('Cannot update invoice history detail without ID');
      }

      // Ensure extended price is calculated
      final detailToSave = detail.calculateExtendedPrice();
      final mapToSave = detailToSave.toMap();

      final count = await db.update(
        tableName,
        mapToSave,
        where: 'id = ?',
        whereArgs: [detail.id],
      );
      captureSync(
        tableName: tableName,
        entityMap: mapToSave,
        entityId: detail.id.toString(),
        operation: 'UPDATE',
        company: detail.company?.toString(),
      );

      if (count == 0) {
        throw Exception(
          'No invoice history detail found with ID: ${detail.id}',
        );
      }

      captureSync(
        tableName: tableName,
        entityMap: mapToSave,
        entityId: detail.id.toString(),
        operation: 'UPDATE',
        company: detail.company?.toString(),
      );

      return count;
    } catch (e) {
      throw Exception('Failed to update invoice history detail: $e');
    }
  }

  // Delete invoice history detail - equivalent to Java's getFacade().remove()
  Future<int> deleteInvoiceHistoryDetail(int id) async {
    final db = await databaseService.database;

    try {
      final detailToDelete = await getInvoiceHistoryDetailById(id);
      final count = await db.delete(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (count == 0) {
        throw Exception('No invoice history detail found with ID: $id');
      }

      if (detailToDelete != null) {
        captureSync(
          tableName: tableName,
          entityMap: {'id': id, 'company': detailToDelete.company},
          entityId: id.toString(),
          operation: 'DELETE',
          company: detailToDelete.company?.toString(),
        );
      }

      return count;
    } catch (e) {
      throw Exception('Failed to delete invoice history detail: $e');
    }
  }

  // Delete multiple invoice history details - equivalent to Java's removeCollection()
  Future<int> deleteMultipleInvoiceHistoryDetails(List<int> ids, int companyId) async {
    final db = await databaseService.database;

    try {
      if (ids.isEmpty) return 0;

      final placeholders = List.filled(ids.length, '?').join(',');

      final count = await db.rawDelete('''
        DELETE FROM $tableName 
        WHERE id IN ($placeholders)
      ''', ids);

      captureSync(
        tableName: tableName,
        entityMap: {'id': ids, 'company': companyId},
        entityId: ids.toString(),
        operation: 'DELETE',
        company: companyId.toString(),
      );

      return count;
    } catch (e) {
      throw Exception('Failed to delete multiple invoice history details: $e');
    }
  }

  // Delete invoice history details by header ID
  Future<int> deleteInvoiceHistoryDetailsByHeaderId(
    int invoiceHistoryId,
    int companyId,
  ) async {
    final db = await databaseService.database;

    try {
      final count = await db.delete(
        tableName,
        where: 'invoice_history = ? AND company = ?',
        whereArgs: [invoiceHistoryId, companyId],
      );

      captureSync(
        tableName: tableName,
        entityMap: {'invoice_history': invoiceHistoryId, 'company': companyId},
        entityId: invoiceHistoryId.toString(),
        operation: 'DELETE',
        company: companyId.toString(),
      );

      return count;
    } catch (e) {
      throw Exception(
        'Failed to delete invoice history details by header ID: $e',
      );
    }
  }

  // Filter invoice history details
  Future<List<InvoiceHistoryDetail>> filterInvoiceHistoryDetails({
    required int companyId,
    int? invoiceHistoryId,
    String? item,
    String? unitOfMeasure,
    double? minQuantity,
    double? maxQuantity,
    double? minUnitPrice,
    double? maxUnitPrice,
    double? minExtendedPrice,
    double? maxExtendedPrice,
  }) async {
    final db = await databaseService.database;

    try {
      final where = StringBuffer('company = ?');
      final whereArgs = <dynamic>[companyId];

      if (invoiceHistoryId != null) {
        where.write(' AND invoice_history = ?');
        whereArgs.add(invoiceHistoryId);
      }

      if (item != null && item.isNotEmpty) {
        where.write(' AND item LIKE ?');
        whereArgs.add('%$item%');
      }

      if (unitOfMeasure != null && unitOfMeasure.isNotEmpty) {
        where.write(' AND unit_of_measure LIKE ?');
        whereArgs.add('%$unitOfMeasure%');
      }

      if (minQuantity != null) {
        where.write(' AND quantity_transaction >= ?');
        whereArgs.add(minQuantity);
      }

      if (maxQuantity != null) {
        where.write(' AND quantity_transaction <= ?');
        whereArgs.add(maxQuantity);
      }

      if (minUnitPrice != null) {
        where.write(' AND amount_unit_price >= ?');
        whereArgs.add(minUnitPrice);
      }

      if (maxUnitPrice != null) {
        where.write(' AND amount_unit_price <= ?');
        whereArgs.add(maxUnitPrice);
      }

      if (minExtendedPrice != null) {
        where.write(' AND amount_extended_price >= ?');
        whereArgs.add(minExtendedPrice);
      }

      if (maxExtendedPrice != null) {
        where.write(' AND amount_extended_price <= ?');
        whereArgs.add(maxExtendedPrice);
      }

      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: where.toString(),
        whereArgs: whereArgs,
        orderBy: 'id DESC',
      );

      return maps.map((map) => InvoiceHistoryDetail.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to filter invoice history details: $e');
    }
  }

  // Count invoice history details
  Future<int> countInvoiceHistoryDetails({
    required int companyId,
    int? invoiceHistoryId,
    String? item,
  }) async {
    final db = await databaseService.database;

    try {
      final where = StringBuffer('company = ?');
      final whereArgs = <dynamic>[companyId];

      if (invoiceHistoryId != null) {
        where.write(' AND invoice_history = ?');
        whereArgs.add(invoiceHistoryId);
      }

      if (item != null && item.isNotEmpty) {
        where.write(' AND item LIKE ?');
        whereArgs.add('%$item%');
      }

      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $tableName WHERE ${where.toString()}',
        whereArgs,
      );

      return result.first['count'] as int;
    } catch (e) {
      throw Exception('Failed to count invoice history details: $e');
    }
  }

  // Get all invoice history details (for super users)
  Future<List<InvoiceHistoryDetail>> getAllInvoiceHistoryDetails() async {
    final db = await databaseService.database;

    try {
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        orderBy: 'id DESC',
      );

      return maps.map((map) => InvoiceHistoryDetail.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get all invoice history details: $e');
    }
  }

  // Get items available for select many
  Future<List<InvoiceHistoryDetail>> getItemsAvailableSelectMany(
    int companyId,
  ) async {
    final db = await databaseService.database;

    try {
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'company = ?',
        whereArgs: [companyId],
        orderBy: 'item, id DESC',
      );

      return maps.map((map) => InvoiceHistoryDetail.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get items available for select many: $e');
    }
  }

  // Get items available for select one
  Future<List<InvoiceHistoryDetail>> getItemsAvailableSelectOne(
    int companyId,
  ) async {
    final db = await databaseService.database;

    try {
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'company = ?',
        whereArgs: [companyId],
        orderBy: 'item, id DESC',
        limit: 100,
      );

      return maps.map((map) => InvoiceHistoryDetail.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get items available for select one: $e');
    }
  }

  // Batch operations for multiple creates/updates/deletes
  Future<void> batchOperations({
    required List<InvoiceHistoryDetail> itemsToCreate,
    required List<InvoiceHistoryDetail> itemsToUpdate,
    required List<int> itemsToDelete,
  }) async {
    final db = await databaseService.database;
    final batch = db.batch();

    try {
      // Create operations
      for (final detail in itemsToCreate) {
        final detailToSave = detail.calculateExtendedPrice();
        batch.insert(tableName, detailToSave.toMap());
      }

      // Update operations
      for (final detail in itemsToUpdate) {
        if (detail.id != null) {
          final detailToSave = detail.calculateExtendedPrice();
          batch.update(
            tableName,
            detailToSave.toMap(),
            where: 'id = ?',
            whereArgs: [detail.id],
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

  // Search invoice history details
  Future<List<InvoiceHistoryDetail>> searchInvoiceHistoryDetails({
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
          item LIKE ? 
          OR unit_of_measure LIKE ?
        )
        ORDER BY 
          CASE 
            WHEN item LIKE ? THEN 1
            ELSE 2
          END,
          id DESC
        LIMIT ?
      ''',
        [companyId, searchQuery, searchQuery, searchQuery, limit],
      );

      return maps.map((map) => InvoiceHistoryDetail.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to search invoice history details: $e');
    }
  }

  // Get invoice history details with extended price calculation
  Future<List<InvoiceHistoryDetail>> getDetailsWithCalculatedExtendedPrice(
    int invoiceHistoryId,
    int companyId,
  ) async {
    final details = await getInvoiceHistoryDetailsByHeaderId(
      invoiceHistoryId,
      companyId,
    );

    return details.map((detail) => detail.calculateExtendedPrice()).toList();
  }

  // Calculate totals for an invoice
  Future<Map<String, double>> calculateInvoiceTotals(
    int invoiceHistoryId,
    int companyId,
  ) async {
    final db = await databaseService.database;

    try {
      final result = await db.rawQuery(
        '''
        SELECT 
          SUM(quantity_transaction) as total_quantity,
          SUM(amount_extended_price) as total_amount,
          COUNT(*) as item_count
        FROM $tableName 
        WHERE invoice_history = ? AND company = ?
      ''',
        [invoiceHistoryId, companyId],
      );

      if (result.isNotEmpty) {
        return {
          'totalQuantity': result.first['total_quantity'] as double? ?? 0.0,
          'totalAmount': result.first['total_amount'] as double? ?? 0.0,
          'itemCount': (result.first['item_count'] as int? ?? 0).toDouble(),
        };
      }

      return {'totalQuantity': 0.0, 'totalAmount': 0.0, 'itemCount': 0.0};
    } catch (e) {
      throw Exception('Failed to calculate invoice totals: $e');
    }
  }

  // Get most sold items (for reporting)
  Future<List<Map<String, dynamic>>> getMostSoldItems({
    required int companyId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 10,
  }) async {
    final db = await databaseService.database;

    try {
      // This requires joining with invoice_history_header for date filtering
      final dateWhere = StringBuffer();
      final whereArgs = <dynamic>[companyId];

      if (startDate != null && endDate != null) {
        dateWhere.write('''
          AND ih.date_transaction BETWEEN ? AND ?
        ''');
        whereArgs.addAll([
          startDate.toIso8601String(),
          endDate.toIso8601String(),
        ]);
      }

      final result = await db.rawQuery(
        '''
        SELECT 
          ihd.item,
          SUM(ihd.quantity_transaction) as total_quantity,
          SUM(ihd.amount_extended_price) as total_revenue,
          COUNT(DISTINCT ihd.invoice_history) as invoice_count
        FROM $tableName ihd
        INNER JOIN invoice_history_header ih ON ihd.invoice_history = ih.id
        WHERE ihd.company = ? 
        $dateWhere
        AND ihd.item IS NOT NULL 
        AND ihd.item != ''
        GROUP BY ihd.item
        ORDER BY total_quantity DESC, total_revenue DESC
        LIMIT ?
      ''',
        [...whereArgs, limit],
      );

      return result.map((map) {
        return {
          'item': map['item'],
          'totalQuantity': map['total_quantity'] as double? ?? 0.0,
          'totalRevenue': map['total_revenue'] as double? ?? 0.0,
          'invoiceCount': map['invoice_count'] as int? ?? 0,
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to get most sold items: $e');
    }
  }

  // Check if item exists in any invoice
  Future<bool> doesItemExistInInvoices({
    required String item,
    required int companyId,
    int? excludeDetailId,
  }) async {
    final db = await databaseService.database;

    try {
      final where = StringBuffer('item = ? AND company = ?');
      final whereArgs = <dynamic>[item, companyId];

      if (excludeDetailId != null) {
        where.write(' AND id != ?');
        whereArgs.add(excludeDetailId);
      }

      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: where.toString(),
        whereArgs: whereArgs,
        limit: 1,
      );

      return maps.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check if item exists in invoices: $e');
    }
  }

  // Get duplicate items across invoices (for data cleaning)
  Future<List<Map<String, dynamic>>> getDuplicateItems(int companyId) async {
    final db = await databaseService.database;

    try {
      final result = await db.rawQuery(
        '''
        SELECT 
          item,
          COUNT(*) as occurrence_count,
          COUNT(DISTINCT invoice_history) as invoice_count
        FROM $tableName 
        WHERE company = ? 
        AND item IS NOT NULL 
        AND item != ''
        GROUP BY item
        HAVING COUNT(*) > 1
        ORDER BY occurrence_count DESC
      ''',
        [companyId],
      );

      return result.map((map) {
        return {
          'item': map['item'],
          'occurrenceCount': map['occurrence_count'] as int? ?? 0,
          'invoiceCount': map['invoice_count'] as int? ?? 0,
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to get duplicate items: $e');
    }
  }

  // Update multiple details with new invoice history ID (for merging/consolidation)
  Future<int> updateDetailsInvoiceHistory({
    required List<int> detailIds,
    required int newInvoiceHistoryId,
    required int companyId,
  }) async {
    final db = await databaseService.database;

    try {
      if (detailIds.isEmpty) return 0;

      final placeholders = List.filled(detailIds.length, '?').join(',');

      final count = await db.rawUpdate(
        '''
        UPDATE $tableName 
        SET invoice_history = ?
        WHERE id IN ($placeholders) 
        AND company = ?
      ''',
        [newInvoiceHistoryId, ...detailIds, companyId],
      );

      captureSync(
        tableName: tableName,
        entityMap: {'id': detailIds, 'company': companyId},
        entityId: detailIds.toString(),
        operation: 'UPDATE',
        company: companyId.toString(),
      );

      return count;
    } catch (e) {
      throw Exception('Failed to update details invoice history: $e');
    }
  }

  // Truncate item names to 45 characters (like Java implementation)
  Future<int> truncateItemNames(int companyId) async {
    final db = await databaseService.database;

    try {
      final result = await db.rawUpdate(
        '''
        UPDATE $tableName 
        SET item = SUBSTR(item, 1, 45)
        WHERE company = ? 
        AND LENGTH(item) > 45
      ''',
        [companyId],
      );

      captureSync(
        tableName: tableName,
        entityMap: {'company': companyId},
        entityId: companyId.toString(),
        operation: 'UPDATE',
        company: companyId.toString(),
      );

      return result;
    } catch (e) {
      throw Exception('Failed to truncate item names: $e');
    }
  }
}
