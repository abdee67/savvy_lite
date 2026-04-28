// lib/features/purchase/supplier/repository/supplier_repository.dart
import 'package:savvy_stock/core/repositories/base_repo.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/purchase/supplier_entry/models/supplier_model.dart';

abstract class SupplierRepository {
  // CRUD Operations
  Future<List<SupplierModel>> getAllSuppliers(int companyId);
  Future<SupplierModel?> getSupplierById(int id, int companyId);
  Future<int> createSupplier(SupplierModel supplier);
  Future<int> updateSupplier(SupplierModel supplier);
  Future<int> deleteSupplier(int id, int companyId);
  Future<void> deleteMultipleSuppliers(List<int> ids, int companyId);

  // Batch Operations
  Future<void> batchCreateSuppliers(List<SupplierModel> suppliers);
  Future<void> batchUpdateSuppliers(List<SupplierModel> suppliers);

  // Filtering & Searching
  Future<List<SupplierModel>> searchSuppliers(String query, int companyId);
  Future<List<SupplierModel>> filterSuppliers({
    required int companyId,
    String? city,
    String? region,
    String? state,
    String? country,
  });

  // Selection Methods
  Future<List<SupplierModel>> getSuppliersAvailableSelectOne(int companyId);
  Future<List<SupplierModel>> getSuppliersAvailableSelectMany(int companyId);

  // Data Validation
  Future<bool> validateSupplierExists(String supplierName, int companyId);
}

// Implementation
class SupplierRepositoryImpl extends BaseRepository implements SupplierRepository {
  @override
  final LocalDatabaseService databaseService;

  SupplierRepositoryImpl({required this.databaseService});

  @override
  Future<List<SupplierModel>> getAllSuppliers(int companyId) async {
    final db = await databaseService.database;
    final suppliers = await db.query(
      'supplier_table',
      where: 'company = ?',
      whereArgs: [companyId],
      orderBy: 'supplier_name ASC',
    );
    return suppliers.map((e) => SupplierModel.fromMap(e)).toList();
  }

  @override
  Future<SupplierModel?> getSupplierById(int id, int companyId) async {
    final db = await databaseService.database;
    final suppliers = await db.query(
      'supplier_table',
      where: 'id = ? AND company = ?',
      whereArgs: [id, companyId],
    );
    return suppliers.isNotEmpty ? SupplierModel.fromMap(suppliers.first) : null;
  }

  @override
  Future<int> createSupplier(SupplierModel supplier) async {
    final db = await databaseService.database;
    final supplierMap = supplier.toMap()
      ..remove('id')
      ..['date_created'] = DateTime.now().toIso8601String()
      ..['date_updated'] = DateTime.now().toIso8601String();

    final payload = withSyncKey(supplierMap);
    final id = await db.insert('supplier_table', payload);
    payload['id'] = id;
    captureSync(
      tableName: 'supplier_table',
      entityMap: payload,
      entityId: id.toString(),
      operation: 'INSERT',
      company: supplier.company?.toString(),
    );
    return id;
  }

  @override
  Future<int> updateSupplier(SupplierModel supplier) async {
    final db = await databaseService.database;

    // Fetch existing sync_key before updating
    final existingRows = await db.query(
      'supplier_table',
      columns: ['sync_key'],
      where: 'id = ? AND company = ?',
      whereArgs: [supplier.id, supplier.company],
    );
    final syncKey = existingRows.isNotEmpty ? existingRows.first['sync_key'] : null;

    final supplierMap = supplier.toMap()
      ..['date_updated'] = DateTime.now().toIso8601String();

    final result = await db.update(
      'supplier_table',
      supplierMap,
      where: 'id = ? AND company = ?',
      whereArgs: [supplier.id, supplier.company],
    );

    if (syncKey != null) {
      supplierMap['sync_key'] = syncKey;
    }

    captureSync(
      tableName: 'supplier_table',
      entityMap: supplierMap,
      entityId: supplier.id.toString(),
      operation: 'UPDATE',
      company: supplier.company?.toString(),
    );
    return result;
  }

  @override
  Future<int> deleteSupplier(int id, int companyId) async {
    final db = await databaseService.database;
    final existingSupplier = await db.query(
      'supplier_table',
      where: 'id = ? AND company = ?',
      whereArgs: [id, companyId],
    );
    final result = await db.delete(
      'supplier_table',
      where: 'id = ? AND company = ?',
      whereArgs: [id, companyId],
    );
    for(final row in existingSupplier){
    captureSync(
      tableName: 'supplier_table',
      entityMap: row,
      entityId: row['id'].toString(),
      operation: 'DELETE',
      company: companyId.toString(),
    );
    }
    return result;
  }

  @override
  Future<void> deleteMultipleSuppliers(List<int> ids, int companyId) async {
    final db = await databaseService.database;
    final placeholders = List.filled(ids.length, '?').join(',');
    final whereArgs = [...ids, companyId];

    // Fetch full row data BEFORE deleting
    final itemRows = await db.query(
      'supplier_table',
      where: 'id IN ($placeholders) AND company = ?',
      whereArgs: whereArgs,
    );

    await db.delete(
      'supplier_table',
      where: 'id IN ($placeholders) AND company = ?',
      whereArgs: whereArgs,
    );

    for (final row in itemRows) {
      captureSync(
        tableName: 'supplier_table',
        entityMap: row,
        entityId: row['id'].toString(),
        operation: 'DELETE',
        company: companyId.toString(),
      );
    }
  }

  @override
  Future<void> batchCreateSuppliers(List<SupplierModel> suppliers) async {
    final db = await databaseService.database;
    final batch = db.batch();

    for (final supplier in suppliers) {
      final supplierMap = supplier.toMap()
        ..remove('id')
        ..['date_created'] = DateTime.now().toIso8601String()
        ..['date_updated'] = DateTime.now().toIso8601String();

      final payload = withSyncKey(supplierMap);
      batch.insert('supplier_table', payload);

      captureSync(
        tableName: 'supplier_table',
        entityMap: payload,
        entityId: supplier.id.toString(),
        operation: 'INSERT',
        company: supplier.company?.toString(),
      );
    }

    await batch.commit(noResult: true);
  }

  @override
  Future<void> batchUpdateSuppliers(List<SupplierModel> suppliers) async {
    final db = await databaseService.database;
    final batch = db.batch();

    for (final supplier in suppliers) {
      // Fetch existing sync_key
      final existingRows = await db.query(
        'supplier_table',
        columns: ['sync_key'],
        where: 'id = ? AND company = ?',
        whereArgs: [supplier.id, supplier.company],
      );
      final syncKey = existingRows.isNotEmpty ? existingRows.first['sync_key'] : null;

      final supplierMap = supplier.toMap()
        ..['date_updated'] = DateTime.now().toIso8601String();

      batch.update(
        'supplier_table',
        supplierMap,
        where: 'id = ?',
        whereArgs: [supplier.id],
      );

      if (syncKey != null) {
        supplierMap['sync_key'] = syncKey;
      }

      captureSync(
        tableName: 'supplier_table',
        entityMap: supplierMap,
        entityId: supplier.id.toString(),
        operation: 'UPDATE',
        company: supplier.company?.toString(),
      );
    }

    await batch.commit(noResult: true);
  }

  @override
  Future<List<SupplierModel>> searchSuppliers(
    String query,
    int companyId,
  ) async {
    final db = await databaseService.database;
    final suppliers = await db.rawQuery(
      '''
      SELECT * FROM supplier_table 
      WHERE company = ? 
      AND (
        supplier_name LIKE ? 
        OR contact_person LIKE ? 
        OR email LIKE ? 
        OR phone_no_1 LIKE ? 
        OR phone_no_2 LIKE ?
      )
      ORDER BY supplier_name ASC
    ''',
      [companyId, '%$query%', '%$query%', '%$query%', '%$query%', '%$query%'],
    );

    return suppliers.map((e) => SupplierModel.fromMap(e)).toList();
  }

  @override
  Future<List<SupplierModel>> filterSuppliers({
    required int companyId,
    String? city,
    String? region,
    String? state,
    String? country,
  }) async {
    final db = await databaseService.database;

    final whereClauses = <String>['company = ?'];
    final whereArgs = <dynamic>[companyId];

    if (city != null && city.isNotEmpty) {
      whereClauses.add('city = ?');
      whereArgs.add(city);
    }
    if (region != null && region.isNotEmpty) {
      whereClauses.add('region = ?');
      whereArgs.add(region);
    }
    if (state != null && state.isNotEmpty) {
      whereClauses.add('state = ?');
      whereArgs.add(state);
    }
    if (country != null && country.isNotEmpty) {
      whereClauses.add('country = ?');
      whereArgs.add(country);
    }

    final suppliers = await db.query(
      'supplier_table',
      where: whereClauses.join(' AND '),
      whereArgs: whereArgs,
      orderBy: 'supplier_name ASC',
    );

    return suppliers.map((e) => SupplierModel.fromMap(e)).toList();
  }

  @override
  Future<List<SupplierModel>> getSuppliersAvailableSelectOne(
    int companyId,
  ) async {
    return getAllSuppliers(companyId);
  }

  @override
  Future<List<SupplierModel>> getSuppliersAvailableSelectMany(
    int companyId,
  ) async {
    return getAllSuppliers(companyId);
  }

  @override
  Future<bool> validateSupplierExists(
    String supplierName,
    int companyId,
  ) async {
    final db = await databaseService.database;
    final suppliers = await db.query(
      'supplier_table',
      where: 'supplier_name = ? AND company = ?',
      whereArgs: [supplierName.trim(), companyId],
    );
    return suppliers.isNotEmpty;
  }
}
