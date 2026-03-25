// features/purchase/other_expenses/repo/other_expense_repository.dart

import 'package:savvy_stock/core/repositories/base_repo.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/models/other_expenses.dart';
import 'package:sqflite/sqflite.dart';

/// Paginated result for other expenses
class PaginatedOtherExpenseResult  {
  final List<OtherExpense> items;
  final int totalCount;

  PaginatedOtherExpenseResult({required this.items, required this.totalCount});
}

class OtherExpenseRepository extends BaseRepository {
  @override
  final LocalDatabaseService databaseService;

  OtherExpenseRepository({required this.databaseService});

  static const String _tableName = 'other_expense_table';

  /// Create a new expense record
  Future<int> create(OtherExpense expense, {Transaction? txn}) async {
    final db = txn ?? await databaseService.database;
    final map = expense.toMap();
    map.remove('id'); // Remove id for new insertion
    final id = await db.insert(_tableName, map);
    map['id'] = id;
    captureSync(
      tableName: _tableName,
      entityMap: map,
      entityId: id.toString(),
      operation: 'INSERT',
      company: expense.company?.toString(),
    );
    return id;
  }

  /// Update an existing expense
  Future<int> update(OtherExpense expense, {Transaction? txn}) async {
    final db = txn ?? await databaseService.database;
    final result = await db.update(
      _tableName,
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
    captureSync(
      tableName: _tableName,
      entityMap: expense.toMap(),
      entityId: expense.id.toString(),
      operation: 'UPDATE',
      company: expense.company?.toString(),
    );
    return result;
  }

  /// Delete an expense by ID
  Future<int> delete(int id, {Transaction? txn}) async {
    final db = txn ?? await databaseService.database;
    final result = await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
    captureSync(
      tableName: _tableName,
      entityMap: {'id': id},
      entityId: id.toString(),
      operation: 'DELETE',
    );
    return result;
  }

  /// Delete multiple expenses
  Future<void> deleteMultiple(List<int> ids, {Transaction? txn}) async {
    final db = txn ?? await databaseService.database;
    final batch = db.batch();

    for (final id in ids) {
      batch.delete(_tableName, where: 'id = ?', whereArgs: [id]);
    }

    await batch.commit(noResult: true);
  }

  /// Find expense by ID with joins
  Future<OtherExpense?> findById(int id) async {
    final db = await databaseService.database;
    final maps = await db.rawQuery(
      '''
      SELECT oet.*,
             udc.description_1 as payment_instrument_description,
             udc.detail_code as payment_instrument_code
      FROM $_tableName oet
      LEFT JOIN udc_details udc ON oet.payment_instrument = udc.id
      WHERE oet.id = ?
      ''',
      [id],
    );

    if (maps.isNotEmpty) {
      return OtherExpense.fromMap(maps.first);
    }
    return null;
  }

  /// Find all expenses for a company
  Future<List<OtherExpense>> findAll(int companyId) async {
    final db = await databaseService.database;
    final maps = await db.rawQuery(
      '''
      SELECT oet.*,
             udc.description_1 as payment_instrument_description,
             udc.detail_code as payment_instrument_code
      FROM $_tableName oet
      LEFT JOIN udc_details udc ON oet.payment_instrument = udc.id
      WHERE oet.company = ?
      ORDER BY oet.date_payment DESC
      ''',
      [companyId],
    );
    return maps.map((map) => OtherExpense.fromMap(map)).toList();
  }

  /// Paginated expenses with date range filtering (equivalent to Java getLazyItems)
  Future<PaginatedOtherExpenseResult> getPaginatedExpenses({
    required int companyId,
    required int page,
    required int pageSize,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? sortField,
    bool ascending = false,
  }) async {
    final db = await databaseService.database;

    final params = <dynamic>[companyId];
    var whereClause = 'oet.company = ?';

    // Add date range filter
    if (dateFrom != null && dateTo != null) {
      whereClause += ' AND oet.date_payment BETWEEN ? AND ?';
      params.add(dateFrom.toIso8601String());
      params.add(dateTo.toIso8601String());
    }

    // Build ORDER BY clause
    final orderBy = sortField != null
        ? 'oet.$sortField ${ascending ? 'ASC' : 'DESC'}'
        : 'oet.id DESC';

    // Count query
    final countResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableName oet WHERE $whereClause',
      params,
    );
    final totalCount = (countResult.first['count'] as int?) ?? 0;

    // Data query with pagination
    final offset = (page - 1) * pageSize;
    params.addAll([pageSize, offset]);

    final maps = await db.rawQuery('''
      SELECT oet.*,
             udc.description_1 as payment_instrument_description,
             udc.detail_code as payment_instrument_code
      FROM $_tableName oet
      LEFT JOIN udc_details udc ON oet.payment_instrument = udc.id
      WHERE $whereClause
      ORDER BY $orderBy
      LIMIT ? OFFSET ?
      ''', params);

    final items = maps.map((map) => OtherExpense.fromMap(map)).toList();

    return PaginatedOtherExpenseResult(items: items, totalCount: totalCount);
  }

  /// Get total monthly expenses for overhead cost calculation
  /// Used by overHeadPerUnit calculation
  Future<double> getMonthlyExpensesTotal({
    required int companyId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await databaseService.database;

    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(payment_amount), 0.0) as total
      FROM $_tableName
      WHERE company = ?
        AND date_payment BETWEEN ? AND ?
      ''',
      [companyId, startDate.toIso8601String(), endDate.toIso8601String()],
    );

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Get month boundaries for a given date
  /// Returns [startOfMonth, endOfMonth]
  List<DateTime> getMonthBoundaries(DateTime date) {
    final startOfMonth = DateTime(date.year, date.month, 1);
    final endOfMonth = DateTime(date.year, date.month + 1, 0, 23, 59, 59);
    return [startOfMonth, endOfMonth];
  }

  /// Get expenses by date range (for reports)
  Future<List<OtherExpense>> getExpensesByDateRange({
    required int companyId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await databaseService.database;
    final maps = await db.rawQuery(
      '''
      SELECT oet.*,
             udc.description_1 as payment_instrument_description,
             udc.detail_code as payment_instrument_code
      FROM $_tableName oet
      LEFT JOIN udc_details udc ON oet.payment_instrument = udc.id
      WHERE oet.company = ?
        AND oet.date_payment BETWEEN ? AND ?
      ORDER BY oet.date_payment DESC
      ''',
      [companyId, startDate.toIso8601String(), endDate.toIso8601String()],
    );
    return maps.map((map) => OtherExpense.fromMap(map)).toList();
  }

  /// Save multiple expenses (batch create/update)
  Future<void> saveMultiple(List<OtherExpense> expenses) async {
    final db = await databaseService.database;
    final batch = db.batch();

    for (final expense in expenses) {
      final map = expense.toMap();
      if (expense.id == null) {
        map.remove('id');
        batch.insert(_tableName, map);
      } else {
        batch.update(_tableName, map, where: 'id = ?', whereArgs: [expense.id]);
      }
    }

    await batch.commit(noResult: true);
  }

  /// Check if expense exists
  Future<bool> exists(int id) async {
    final db = await databaseService.database;
    final result = await db.query(
      _tableName,
      columns: ['id'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return result.isNotEmpty;
  }
}
