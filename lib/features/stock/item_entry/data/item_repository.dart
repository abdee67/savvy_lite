// features/stock/items_table/repositories/items_table_repository.dart
import 'dart:math';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/stock/item_entry/models/item_entry_model.dart';

class StockItemsEntryRepository {
  final LocalDatabaseService databaseService;
  final Random _random = Random();

  StockItemsEntryRepository({required this.databaseService});

  // Create new item
  Future<int> create(ItemEntryModel item) async {
    final db = await databaseService.database;
    final itemMap = item.toMap();
    itemMap.remove('id');
    return await db.insert('items_table', itemMap);
  }

  // Update existing item
  Future<int> update(ItemEntryModel item) async {
    final db = await databaseService.database;
    return await db.update(
      'items_table',
      item.toMap(),
      where: 'id = ? AND company = ?',
      whereArgs: [item.id, item.company],
    );
  }

  // Delete item
  Future<int> delete(int id, int companyId) async {
    final db = await databaseService.database;
    return await db.delete(
      'items_table',
      where: 'id = ? AND company = ?',
      whereArgs: [id, companyId],
    );
  }

  // Delete multiple items
  Future<void> deleteMultiple(List<int> ids, int companyId) async {
    final db = await databaseService.database;
    final batch = db.batch();

    for (final id in ids) {
      batch.delete(
        'items_table',
        where: 'id = ? AND company = ?',
        whereArgs: [id, companyId],
      );
    }

    await batch.commit();
  }

  // Find item by ID
  Future<ItemEntryModel?> findById(int id, int companyId) async {
    final db = await databaseService.database;
    final maps = await db.rawQuery(
      '''
      SELECT it.*,ud.description_1 as unit_of_measure_description
      FROM items_table it
      LEFT JOIN udc_details ud ON it.unit_of_measure = ud.id
      WHERE it.id = ? AND it.company = ?
    ''',
      [id, companyId],
    );

    if (maps.isNotEmpty) {
      return ItemEntryModel.fromMap(maps.first);
    }
    return null;
  }

  // Find all items for company
  Future<List<ItemEntryModel>> findAll(int companyId) async {
    final db = await databaseService.database;
    final maps = await db.rawQuery(
      '''
      SELECT it.*,ud.description_1 as unit_of_measure_description
      FROM items_table it
      LEFT JOIN udc_details ud ON it.unit_of_measure = ud.id
      WHERE it.company = ?
      ORDER BY it.item_description ASC
    ''',
      [companyId],
    );

    return maps.map((map) => ItemEntryModel.fromMap(map)).toList();
  }

  // Find item by items ID
  Future<ItemEntryModel?> findByItemsId(String itemsId, int companyId) async {
    final db = await databaseService.database;
    final maps = await db.rawQuery(
      '''
      SELECT it.*,ud.description_1 as unit_of_measure_description
      FROM items_table it
      LEFT JOIN udc_details ud ON it.unit_of_measure = ud.id
      WHERE it.items_id = ? AND it.company = ?
    ''',
      [itemsId, companyId],
    );

    if (maps.isNotEmpty) {
      return ItemEntryModel.fromMap(maps.first);
    }
    return null;
  }

  // Find item by barcode
  Future<ItemEntryModel?> findByBarcode(String barcode, int companyId) async {
    final db = await databaseService.database;
    final maps = await db.rawQuery(
      '''
      SELECT it.*,ud.description_1 as unit_of_measure_description
      FROM items_table it
      LEFT JOIN udc_details ud ON it.unit_of_measure = ud.id
      WHERE it.barcode = ? AND it.company = ?
    ''',
      [barcode, companyId],
    );

    if (maps.isNotEmpty) {
      return ItemEntryModel.fromMap(maps.first);
    }
    return null;
  }

  // Check for duplicate items (itemsId or barcode)
  Future<bool> checkDuplicate({
    required int companyId,
    String? itemsId,
    String? barcode,
    int? excludeId,
  }) async {
    final db = await databaseService.database;

    String whereClause = 'company = ? AND (items_id = ? OR barcode = ?)';
    List<dynamic> whereArgs = [companyId, itemsId, barcode];

    if (excludeId != null) {
      whereClause += ' AND id != ?';
      whereArgs.add(excludeId);
    }

    final maps = await db.query(
      'items_table',
      where: whereClause,
      whereArgs: whereArgs,
      limit: 1,
    );

    return maps.isNotEmpty;
  }

  // Search items
  Future<List<ItemEntryModel>> search(String query, int companyId) async {
    final db = await databaseService.database;
    final maps = await db.rawQuery(
      '''
      SELECT it.*,ud.description_1 as unit_of_measure_description
      FROM items_table it
      LEFT JOIN udc_details ud ON it.unit_of_measure = ud.id
      WHERE it.company = ? AND (
        it.items_id LIKE ? OR 
        it.item_description LIKE ? OR 
        it.barcode LIKE ? OR
        it.reference_id LIKE ?
      )
      ORDER BY it.item_description ASC
    ''',
      [companyId, '%$query%', '%$query%', '%$query%', '%$query%'],
    );

    return maps.map((map) => ItemEntryModel.fromMap(map)).toList();
  }

  // Filter items by multiple criteria
  Future<List<ItemEntryModel>> filter({
    required int companyId,
    String? itemsId,
    String? itemDescription,
    String? barcode,
  }) async {
    final db = await databaseService.database;

    String whereClause = 'WHERE it.company = ?';
    List<dynamic> whereArgs = [companyId];

    if (itemsId != null && itemsId.isNotEmpty) {
      whereClause += ' AND it.items_id LIKE ?';
      whereArgs.add('$itemsId%');
    }

    if (itemDescription != null && itemDescription.isNotEmpty) {
      whereClause += ' AND it.item_description LIKE ?';
      whereArgs.add('$itemDescription%');
    }

    if (barcode != null && barcode.isNotEmpty) {
      whereClause += ' AND it.barcode LIKE ?';
      whereArgs.add('$barcode%');
    }

    final maps = await db.rawQuery('''
      SELECT it.*, ud.description_1 as unit_of_measure_description
      FROM items_table it
      LEFT JOIN udc_details ud ON it.unit_of_measure = ud.id
      $whereClause
      ORDER BY it.item_description ASC
    ''', whereArgs);

    return maps.map((map) => ItemEntryModel.fromMap(map)).toList();
  }

  // Get items with barcodes
  Future<List<ItemEntryModel>> getItemsWithBarcodes(int companyId) async {
    final db = await databaseService.database;
    final maps = await db.rawQuery(
      '''
      SELECT it.*,ud.description_1 as unit_of_measure_description
      FROM items_table it
      LEFT JOIN udc_details ud ON it.unit_of_measure = ud.id
      WHERE it.company = ? AND LENGTH(TRIM(it.barcode)) > 0
      ORDER BY it.item_description ASC
    ''',
      [companyId],
    );

    return maps.map((map) => ItemEntryModel.fromMap(map)).toList();
  }

  // Generate unique EAN13 barcode
  Future<String> generateUniqueBarcode(int companyId) async {
    String barcode;
    bool exists;

    do {
      barcode = _generateEAN13();
      final existingItem = await findByBarcode(barcode, companyId);
      exists = existingItem != null;
    } while (exists);

    return barcode;
  }

  // Generate EAN13 barcode
  String _generateEAN13() {
    final buffer = StringBuffer();

    // Generate first 12 random digits
    for (int i = 0; i < 12; i++) {
      buffer.write(_random.nextInt(10));
    }

    // Calculate and append check digit
    final barcode12 = buffer.toString();
    final checkDigit = _calculateEAN13CheckDigit(barcode12);
    buffer.write(checkDigit);

    return buffer.toString();
  }

  // Calculate EAN13 check digit
  int _calculateEAN13CheckDigit(String barcode) {
    int sum = 0;

    for (int i = 0; i < barcode.length; i++) {
      final digit = int.parse(barcode[i]);
      sum += (i % 2 == 0) ? digit : digit * 3;
    }

    return (10 - (sum % 10)) % 10;
  }

  // Update multiple items in batch
  Future<void> updateBatch(List<ItemEntryModel> items) async {
    final db = await databaseService.database;
    final batch = db.batch();

    for (final item in items) {
      batch.update(
        'items_table',
        item.toMap(),
        where: 'id = ? AND company = ?',
        whereArgs: [item.id, item.company],
      );
    }

    await batch.commit();
  }

  // Get items for select many (with company filter)
  Future<List<ItemEntryModel>> getItemsForSelectMany(int companyId) async {
    final db = await databaseService.database;
    final maps = await db.rawQuery(
      '''
      SELECT it.*,ud.description_1 as unit_of_measure_description
      FROM items_table it
      LEFT JOIN udc_details ud ON it.unit_of_measure = ud.id
      WHERE it.company = ?
      ORDER BY it.item_description ASC
    ''',
      [companyId],
    );

    return maps.map((map) => ItemEntryModel.fromMap(map)).toList();
  }

  // Get items for select one (with company filter)
  Future<List<ItemEntryModel>> getItemsForSelectOne(int companyId) async {
    return await getItemsForSelectMany(companyId);
  }

  // Check if barcode exists
  Future<bool> barcodeExists(
    String barcode,
    int companyId, {
    int? excludeId,
  }) async {
    final db = await databaseService.database;

    String whereClause = 'barcode = ? AND company = ?';
    List<dynamic> whereArgs = [barcode, companyId];

    if (excludeId != null) {
      whereClause += ' AND id != ?';
      whereArgs.add(excludeId);
    }

    final maps = await db.query(
      'items_table',
      where: whereClause,
      whereArgs: whereArgs,
      limit: 1,
    );

    return maps.isNotEmpty;
  }

  // Check if itemsId exists
  Future<bool> itemsIdExists(
    String itemsId,
    int companyId, {
    int? excludeId,
  }) async {
    final db = await databaseService.database;

    String whereClause = 'items_id = ? AND company = ?';
    List<dynamic> whereArgs = [itemsId, companyId];

    if (excludeId != null) {
      whereClause += ' AND id != ?';
      whereArgs.add(excludeId);
    }

    final maps = await db.query(
      'items_table',
      where: whereClause,
      whereArgs: whereArgs,
      limit: 1,
    );

    return maps.isNotEmpty;
  }
}
