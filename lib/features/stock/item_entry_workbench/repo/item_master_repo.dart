// features/stock/item_master/repositories/item_master_repository.dart
import 'package:savvy_stock/core/repositories/base_repo.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/stock/item_entry_workbench/models/item_master_model.dart';

class ItemMasterRepository extends BaseRepository {
  @override
  final LocalDatabaseService databaseService;

  ItemMasterRepository({required this.databaseService});

  // Create new item master
  Future<int> create(ItemMaster item) async {
    final db = await databaseService.database;
    final itemMap = item.toMap();
    itemMap.remove('id');
    final id = await db.insert('item_master', withSyncKey(itemMap));
    itemMap['id'] = id;
    captureSync(
      tableName: 'item_master',
      entityMap: itemMap,
      entityId: id.toString(),
      operation: 'INSERT',
      company: item.companyCategory?.toString(), // Use category as company id is not directly available, but it's okay for now
    );
    return id;
  }

  // Update existing item master
  Future<int> update(ItemMaster item) async {
    final db = await databaseService.database;
    final result = await db.update(
      'item_master',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
    captureSync(
      tableName: 'item_master',
      entityMap: item.toMap(),
      entityId: item.id.toString(),
      operation: 'UPDATE',
      company: item.companyCategory?.toString(),
    );
    return result;
  }

  // Delete item master
  Future<int> delete(int id) async {
    final db = await databaseService.database;
    // Fetch full row data BEFORE deleting
    final itemRows = await db.query(
      'item_master',
      where: 'id = ?',
      whereArgs: [id],
    );
    final result = await db.delete('item_master', where: 'id = ?', whereArgs: [id]);
    for (final row in itemRows) {
    captureSync(
      tableName: 'item_master',
      entityMap: row,
      entityId: row['id'].toString(),
      operation: 'DELETE',
    );
    }
    return result;
  }

  // Delete multiple item masters
  Future<void> deleteMultiple(List<int> ids) async {
    final db = await databaseService.database;
    final batch = db.batch();

    for (final id in ids) {
      batch.delete('item_master', where: 'id = ?', whereArgs: [id]);
    }

    await batch.commit();
  }

  // Find item master by ID
  Future<ItemMaster?> findById(int id) async {
    final db = await databaseService.database;
    final maps = await db.rawQuery(
      '''
      SELECT im.*,
             b.description as branch_description, 
             cc.description_1 as company_category_description,
             uom.description_1 as defualt_uom_description,
             c01.description_1 as category_code_01_description,
             c02.description_1 as category_code_02_description,
             c03.description_1 as category_code_03_description,
             c04.description_1 as category_code_04_description,
             c05.description_1 as category_code_05_description,
             c06.description_1 as category_code_06_description,
             c07.description_1 as category_code_07_description,
             c08.description_1 as category_code_08_description,
             c09.description_1 as category_code_09_description,
             c10.description_1 as category_code_10_description
      FROM item_master im
      LEFT JOIN branch_table b ON im.branch = b.id
      LEFT JOIN udc_details cc ON im.company_category = cc.id
      LEFT JOIN udc_details uom ON im.defualt_uom = uom.id
      LEFT JOIN udc_details c01 ON im.category_code_01 = c01.id
      LEFT JOIN udc_details c02 ON im.category_code_02 = c02.id
      LEFT JOIN udc_details c03 ON im.category_code_03 = c03.id
      LEFT JOIN udc_details c04 ON im.category_code_04 = c04.id
      LEFT JOIN udc_details c05 ON im.category_code_05 = c05.id
      LEFT JOIN udc_details c06 ON im.category_code_06 = c06.id
      LEFT JOIN udc_details c07 ON im.category_code_07 = c07.id
      LEFT JOIN udc_details c08 ON im.category_code_08 = c08.id
      LEFT JOIN udc_details c09 ON im.category_code_09 = c09.id
      LEFT JOIN udc_details c10 ON im.category_code_10 = c10.id
      WHERE im.id = ?
    ''',
      [id],
    );

    if (maps.isNotEmpty) {
      return ItemMaster.fromMap(maps.first);
    }
    return null;
  }

  // Find all item masters
  Future<List<ItemMaster>> findAll({int? companyCategoryId}) async {
    final db = await databaseService.database;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (companyCategoryId != null) {
      whereClause = 'WHERE im.company_category = ?';
      whereArgs = [companyCategoryId];
    }

    final maps = await db.rawQuery('''
      SELECT im.*,
             cc.description_1 as company_category_description,
             uom.description_1 as defualt_uom_description,
             c01.description_1 as category_code_01_description,
             c02.description_1 as category_code_02_description,
             c03.description_1 as category_code_03_description,
             c04.description_1 as category_code_04_description,
             c05.description_1 as category_code_05_description,
             c06.description_1 as category_code_06_description,
             c07.description_1 as category_code_07_description,
             c08.description_1 as category_code_08_description,
             c09.description_1 as category_code_09_description,
             c10.description_1 as category_code_10_description
      FROM item_master im
      LEFT JOIN udc_details cc ON im.company_category = cc.id
      LEFT JOIN udc_details uom ON im.defualt_uom = uom.id
      LEFT JOIN udc_details c01 ON im.category_code_01 = c01.id
      LEFT JOIN udc_details c02 ON im.category_code_02 = c02.id
      LEFT JOIN udc_details c03 ON im.category_code_03 = c03.id
      LEFT JOIN udc_details c04 ON im.category_code_04 = c04.id
      LEFT JOIN udc_details c05 ON im.category_code_05 = c05.id
      LEFT JOIN udc_details c06 ON im.category_code_06 = c06.id
      LEFT JOIN udc_details c07 ON im.category_code_07 = c07.id
      LEFT JOIN udc_details c08 ON im.category_code_08 = c08.id
      LEFT JOIN udc_details c09 ON im.category_code_09 = c09.id
      LEFT JOIN udc_details c10 ON im.category_code_10 = c10.id
      $whereClause
      ORDER BY im.item_description ASC
    ''', whereArgs);

    return maps.map((map) => ItemMaster.fromMap(map)).toList();
  }

  // Find item master by description and company category
  Future<ItemMaster?> findByDescriptionAndCategory(
    String description,
    int companyCategoryId,
  ) async {
    final db = await databaseService.database;
    final maps = await db.rawQuery(
      '''
      SELECT im.*,
             --b.description as branch_description,
             cc.description_1 as company_category_description,
             uom.description_1 as defualt_uom_description,
             c01.description_1 as category_code_01_description,
             c02.description_1 as category_code_02_description,
             c03.description_1 as category_code_03_description,
             c04.description_1 as category_code_04_description,
             c05.description_1 as category_code_05_description,
             c06.description_1 as category_code_06_description,
             c07.description_1 as category_code_07_description,
             c08.description_1 as category_code_08_description,
             c09.description_1 as category_code_09_description,
             c10.description_1 as category_code_10_description
      FROM item_master im
      --LEFT JOIN branch_table b ON im.branch = b.id
      LEFT JOIN udc_details cc ON im.company_category = cc.id
      LEFT JOIN udc_details uom ON im.defualt_uom = uom.id
      LEFT JOIN udc_details c01 ON im.category_code_01 = c01.id
      LEFT JOIN udc_details c02 ON im.category_code_02 = c02.id
      LEFT JOIN udc_details c03 ON im.category_code_03 = c03.id
      LEFT JOIN udc_details c04 ON im.category_code_04 = c04.id
      LEFT JOIN udc_details c05 ON im.category_code_05 = c05.id
      LEFT JOIN udc_details c06 ON im.category_code_06 = c06.id
      LEFT JOIN udc_details c07 ON im.category_code_07 = c07.id
      LEFT JOIN udc_details c08 ON im.category_code_08 = c08.id
      LEFT JOIN udc_details c09 ON im.category_code_09 = c09.id
      LEFT JOIN udc_details c10 ON im.category_code_10 = c10.id
      WHERE im.item_description = ? AND im.company_category = ?
    ''',
      [description, companyCategoryId],
    );

    if (maps.isNotEmpty) {
      return ItemMaster.fromMap(maps.first);
    }
    return null;
  }

  // Check for duplicate item master
  Future<bool> checkDuplicate({
    required String itemDescription,
    required int companyCategoryId,
    int? excludeId,
  }) async {
    final db = await databaseService.database;

    String whereClause = 'item_description = ? AND company_category = ?';
    List<dynamic> whereArgs = [itemDescription, companyCategoryId];

    if (excludeId != null) {
      whereClause += ' AND id != ?';
      whereArgs.add(excludeId);
    }

    final maps = await db.query(
      'item_master',
      where: whereClause,
      whereArgs: whereArgs,
      limit: 1,
    );

    return maps.isNotEmpty;
  }

  // Get item masters by company category
  Future<List<ItemMaster>> findByCompanyCategory(int companyCategoryId) async {
    final db = await databaseService.database;
    final maps = await db.rawQuery(
      '''
      SELECT im.*,
             --b.description as branch_description,
             cc.description_1 as company_category_description,
             uom.description_1 as defualt_uom_description,
             c01.description_1 as category_code_01_description,
             c02.description_1 as category_code_02_description,
             c03.description_1 as category_code_03_description,
             c04.description_1 as category_code_04_description,
             c05.description_1 as category_code_05_description,
             c06.description_1 as category_code_06_description,
             c07.description_1 as category_code_07_description,
             c08.description_1 as category_code_08_description,
             c09.description_1 as category_code_09_description,
             c10.description_1 as category_code_10_description
      FROM item_master im
      -- LEFT JOIN branch_table b ON im.branch = b.id
      LEFT JOIN udc_details cc ON im.company_category = cc.id
      LEFT JOIN udc_details uom ON im.defualt_uom = uom.id
      LEFT JOIN udc_details c01 ON im.category_code_01 = c01.id
      LEFT JOIN udc_details c02 ON im.category_code_02 = c02.id
      LEFT JOIN udc_details c03 ON im.category_code_03 = c03.id
      LEFT JOIN udc_details c04 ON im.category_code_04 = c04.id
      LEFT JOIN udc_details c05 ON im.category_code_05 = c05.id
      LEFT JOIN udc_details c06 ON im.category_code_06 = c06.id
      LEFT JOIN udc_details c07 ON im.category_code_07 = c07.id
      LEFT JOIN udc_details c08 ON im.category_code_08 = c08.id
      LEFT JOIN udc_details c09 ON im.category_code_09 = c09.id
      LEFT JOIN udc_details c10 ON im.category_code_10 = c10.id
      WHERE im.company_category = ?
      ORDER BY im.item_description ASC
    ''',
      [companyCategoryId],
    );

    return maps.map((map) => ItemMaster.fromMap(map)).toList();
  }

  // Search item masters
  Future<List<ItemMaster>> search(
    String query, {
    int? companyCategoryId,
  }) async {
    final db = await databaseService.database;

    String whereClause = 'im.item_description LIKE ?';
    List<dynamic> whereArgs = ['%$query%'];

    if (companyCategoryId != null) {
      whereClause += ' AND im.company_category = ?';
      whereArgs.add(companyCategoryId);
    }

    final maps = await db.rawQuery('''
      SELECT im.*,
             --b.description as branch_description,
             cc.description_1 as company_category_description,
             uom.description_1 as defualt_uom_description,
             c01.description_1 as category_code_01_description,
             c02.description_1 as category_code_02_description,
             c03.description_1 as category_code_03_description,
             c04.description_1 as category_code_04_description,
             c05.description_1 as category_code_05_description,
             c06.description_1 as category_code_06_description,
             c07.description_1 as category_code_07_description,
             c08.description_1 as category_code_08_description,
             c09.description_1 as category_code_09_description,
             c10.description_1 as category_code_10_description
      FROM item_master im
      --LEFT JOIN branch_table b ON im.branch = b.id
      LEFT JOIN udc_details cc ON im.company_category = cc.id
      LEFT JOIN udc_details uom ON im.defualt_uom = uom.id
      LEFT JOIN udc_details c01 ON im.category_code_01 = c01.id
      LEFT JOIN udc_details c02 ON im.category_code_02 = c02.id
      LEFT JOIN udc_details c03 ON im.category_code_03 = c03.id
      LEFT JOIN udc_details c04 ON im.category_code_04 = c04.id
      LEFT JOIN udc_details c05 ON im.category_code_05 = c05.id
      LEFT JOIN udc_details c06 ON im.category_code_06 = c06.id
      LEFT JOIN udc_details c07 ON im.category_code_07 = c07.id
      LEFT JOIN udc_details c08 ON im.category_code_08 = c08.id
      LEFT JOIN udc_details c09 ON im.category_code_09 = c09.id
      LEFT JOIN udc_details c10 ON im.category_code_10 = c10.id
      WHERE $whereClause
      ORDER BY im.item_description ASC
    ''', whereArgs);

    return maps.map((map) => ItemMaster.fromMap(map)).toList();
  }

  // Get item descriptions list
  Future<List<String>> getItemDescriptions(int companyCategoryId) async {
    final db = await databaseService.database;
    final maps = await db.rawQuery(
      '''
      SELECT DISTINCT item_description 
      FROM item_master 
      LEFT JOIN branch_table b ON im.branch = b.id
      WHERE company_category = ?
      ORDER BY item_description ASC
    ''',
      [companyCategoryId],
    );

    return maps.map((map) => map['item_description'] as String).toList();
  }

  // Update multiple item masters in batch
  Future<void> updateBatch(List<ItemMaster> items) async {
    final db = await databaseService.database;
    final batch = db.batch();

    for (final item in items) {
      if (item.id != null) {
        batch.update(
          'item_master',
          item.toMap(),
          where: 'id = ?',
          whereArgs: [item.id],
        );
      }
    }

    await batch.commit();
  }

  // Get item masters for select many
  Future<List<ItemMaster>> getItemsForSelectMany(int companyCategoryId) async {
    return await findByCompanyCategory(companyCategoryId);
  }

  // Get item masters for select one
  Future<List<ItemMaster>> getItemsForSelectOne() async {
    final db = await databaseService.database;
    final maps = await db.rawQuery('''
      SELECT im.*,
             b.description as branch_description,
             cc.description_1 as company_category_description,
             uom.description_1 as defualt_uom_description
      FROM item_master im
      LEFT JOIN branch_table b ON im.branch = b.id
      LEFT JOIN udc_details cc ON im.company_category = cc.id
      LEFT JOIN udc_details uom ON im.defualt_uom = uom.id
      ORDER BY im.item_description ASC
    ''');

    return maps.map((map) => ItemMaster.fromMap(map)).toList();
  }

  // Get item master by description
  Future<ItemMaster?> findByDescription(
    String description,
    int companyCategoryId,
  ) async {
    final db = await databaseService.database;
    final maps = await db.rawQuery(
      '''
      SELECT im.*,
             b.description as branch_description,
             cc.description_1 as company_category_description,
             uom.description_1 as defualt_uom_description,
             c01.description_1 as category_code_01_description,
             c02.description_1 as category_code_02_description,
             c03.description_1 as category_code_03_description,
             c04.description_1 as category_code_04_description,
             c05.description_1 as category_code_05_description,
             c06.description_1 as category_code_06_description,
             c07.description_1 as category_code_07_description,
             c08.description_1 as category_code_08_description,
             c09.description_1 as category_code_09_description,
             c10.description_1 as category_code_10_description
      FROM item_master im
      LEFT JOIN branch_table b ON im.branch = b.id
      LEFT JOIN udc_details cc ON im.company_category = cc.id
      LEFT JOIN udc_details uom ON im.defualt_uom = uom.id
      LEFT JOIN udc_details c01 ON im.category_code_01 = c01.id
      LEFT JOIN udc_details c02 ON im.category_code_02 = c02.id
      LEFT JOIN udc_details c03 ON im.category_code_03 = c03.id
      LEFT JOIN udc_details c04 ON im.category_code_04 = c04.id
      LEFT JOIN udc_details c05 ON im.category_code_05 = c05.id
      LEFT JOIN udc_details c06 ON im.category_code_06 = c06.id
      LEFT JOIN udc_details c07 ON im.category_code_07 = c07.id
      LEFT JOIN udc_details c08 ON im.category_code_08 = c08.id
      LEFT JOIN udc_details c09 ON im.category_code_09 = c09.id
      LEFT JOIN udc_details c10 ON im.category_code_10 = c10.id
      WHERE im.item_description = ? AND im.company_category = ?
    ''',
      [description, companyCategoryId],
    );

    if (maps.isNotEmpty) {
      return ItemMaster.fromMap(maps.first);
    }
    return null;
  }
}
