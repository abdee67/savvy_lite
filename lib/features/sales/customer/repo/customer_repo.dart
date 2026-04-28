// features/sales/customer/repositories/customer_repository.dart
import 'package:savvy_stock/core/repositories/base_repo.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/sales/customer/models/customer_model.dart';

class CustomerRepository extends BaseRepository {
  @override
  final LocalDatabaseService databaseService;

  CustomerRepository({required this.databaseService});

  // Get all customers for a company
  Future<List<Customer>> getCustomers(int companyId) async {
    final db = await databaseService.database;
    final customers = await db.query(
      'customer_table',
      where: 'company = ?',
      whereArgs: [companyId],
    );
    return customers.map((e) => Customer.fromMap(e)).toList();
  }

  // Get customer by ID
  Future<Customer?> getCustomerById(int id, int companyId) async {
    final db = await databaseService.database;
    final customers = await db.query(
      'customer_table',
      where: 'id = ? AND company = ?',
      whereArgs: [id, companyId],
    );
    return customers.isNotEmpty ? Customer.fromMap(customers.first) : null;
  }

  // Get default customer (where defaults_value = 'Y')
  Future<Customer?> getDefaultCustomer(int companyId) async {
    final db = await databaseService.database;
    final customers = await db.rawQuery(
      '''
      SELECT * FROM customer_table 
      WHERE company = ? AND defaults_value = 'Y'
      ''',
      [companyId],
    );
    return customers.isNotEmpty ? Customer.fromMap(customers.first) : null;
  }

  // Create new customer
  Future<int> createCustomer(Customer customer) async {
    final db = await databaseService.database;
    final customerMap = customer.toMap();
    customerMap.remove('id');
    final payload = withSyncKey(customerMap);
    final id = await db.insert('customer_table', payload);
    payload['id'] = id;
    captureSync(
      tableName: 'customer_table',
      entityMap: payload,
      entityId: id.toString(),
      operation: 'INSERT',
      company: customer.company?.toString(),
    );
    return id;
  }

  // Update existing customer
  Future<int> updateCustomer(Customer customer) async {
    final db = await databaseService.database;

    // Fetch existing sync_key before updating
    final existingRows = await db.query(
      'customer_table',
      columns: ['sync_key'],
      where: 'id = ? AND company = ?',
      whereArgs: [customer.id, customer.company],
    );
    final syncKey = existingRows.isNotEmpty ? existingRows.first['sync_key'] : null;

    final payload = customer.toMap();
    final result = await db.update(
      'customer_table',
      payload,
      where: 'id = ? AND company = ?',
      whereArgs: [customer.id, customer.company],
    );

    if (syncKey != null) {
      payload['sync_key'] = syncKey;
    }

    captureSync(
      tableName: 'customer_table',
      entityMap: payload,
      entityId: customer.id.toString(),
      operation: 'UPDATE',
      company: customer.company?.toString(),
    );
    return result;
  }

  // Delete customer
  Future<int> deleteCustomer(int id, int companyId) async {
    final db = await databaseService.database;
    // Fetch full row data BEFORE deleting
    final customerRows = await db.query(
      'customer_table',
      where: 'id = ? AND company = ?',
      whereArgs: [id, companyId],
    );
    final result = await db.delete(
      'customer_table',
      where: 'id = ? AND company = ?',
      whereArgs: [id, companyId],
    );
    // Capture sync with full row data
    for (final row in customerRows) {
      captureSync(
        tableName: 'customer_table',
        entityMap: row,
        entityId: row['id'].toString(),
        operation: 'DELETE',
      company: companyId.toString(),
    );
    }
    return result;
  }

  // Batch delete multiple customers
  Future<void> deleteMultipleCustomers(List<int> ids, int companyId) async {
    final db = await databaseService.database;
    final placeholders = List.filled(ids.length, '?').join(',');
    final whereArgs = [...ids, companyId];

    // Fetch full row data BEFORE deleting
    final itemRows = await db.query(
      'customer_table',
      where: 'id IN ($placeholders) AND company = ?',
      whereArgs: whereArgs,
    );

    await db.delete(
      'customer_table',
      where: 'id IN ($placeholders) AND company = ?',
      whereArgs: whereArgs,
    );

    for (final row in itemRows) {
      captureSync(
        tableName: 'customer_table',
        entityMap: row,
        entityId: row['id'].toString(),
        operation: 'DELETE',
        company: companyId.toString(),
      );
    }
  }

  // Search customers by name
  Future<List<Customer>> searchCustomers({
    required int companyId,
    required String query,
  }) async {
    final db = await databaseService.database;
    final customers = await db.rawQuery(
      '''
      SELECT * FROM customer_table 
      WHERE company = ? AND customer_name LIKE ?
      ''',
      [companyId, '%$query%'],
    );
    return customers.map((e) => Customer.fromMap(e)).toList();
  }

  // Filter customers with dynamic queries (equivalent to Java's customerFilter)
  Future<List<Customer>> filterCustomers({
    required int companyId,
    required String customerName,
  }) async {
    final db = await databaseService.database;
    final customers = await db.rawQuery(
      '''
      SELECT * FROM customer_table 
      WHERE company = ? AND customer_name LIKE ?
      ''',
      [companyId, '$customerName%'],
    );
    return customers.map((e) => Customer.fromMap(e)).toList();
  }

  // Check if default customer exists and update if needed
  Future<void> handleDefaultCustomer(
    Customer newCustomer,
    int companyId,
  ) async {
    final db = await databaseService.database;

    // If setting as default, unset previous default
    if (newCustomer.defaultsValue == 'Y') {
      final currentDefault = await getDefaultCustomer(companyId);
      if (currentDefault != null && currentDefault.isNotEmpty) {
        await db.update(
          'customer_table',
          {'defaults_value': 'N'},
          where: 'id = ? AND company = ?',
          whereArgs: [currentDefault.id, companyId],
        );
      }
    }
  }

  // Get customers available for selection
  Future<List<Customer>> getCustomersAvailableSelectOne(int companyId) async {
    final db = await databaseService.database;
    final customers = await db.query(
      'customer_table',
      where: 'company = ?',
      whereArgs: [companyId],
    );
    return customers.map((e) => Customer.fromMap(e)).toList();
  }

  // Get customers for multi-select
  Future<List<Customer>> getCustomersAvailableSelectMany(int companyId) async {
    final db = await databaseService.database;
    final customers = await db.query(
      'customer_table',
      where: 'company = ?',
      whereArgs: [companyId],
    );
    return customers.map((e) => Customer.fromMap(e)).toList();
  }

  // Check if default customer setting is valid
  Future<bool> isDefaultCustomerSettingValid(
    Customer customer,
    int companyId,
  ) async {
    if (customer.defaultsValue != 'Y') return true;

    final currentDefault = await getDefaultCustomer(companyId);
    return currentDefault == null || currentDefault.isNotEmpty;
  }
}
