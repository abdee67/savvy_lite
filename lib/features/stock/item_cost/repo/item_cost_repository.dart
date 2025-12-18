// features/stock/item_cost/repositories/item_cost_repository.dart
import 'package:savvy_stock/core/repositories/base_repo.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/sales/sales_order/detail/model/sales_order_detail.dart';
import 'package:savvy_stock/features/stock/item_cost/models/item_cost_model.dart';
import 'package:savvy_stock/features/stock/item_cost/models/paginated_item_cost.dart';
import 'package:savvy_stock/features/stock/item_uom_conversions/repo/item_uom_conv_repo.dart';
import 'package:sqflite/sqflite.dart';

class ItemCostRepository extends BaseRepository {
  @override
  final LocalDatabaseService databaseService;
  final ItemUomConversionsRepository uomConversionRepository;

  ItemCostRepository({
    required this.databaseService,
    required this.uomConversionRepository,
  });

  // Create new item cost
  Future<int> create(ItemCost itemCost, {Transaction? txn}) async {
    final db = txn ?? await databaseService.database;
    final itemMap = itemCost.toMap();
    itemMap.remove('id'); // Remove id for new insertion
    return await db.insert('item_cost', itemMap);
  }

  // Update existing item cost
  Future<int> update(ItemCost itemCost, {Transaction? txn}) async {
    final db = txn ?? await databaseService.database;
    return await db.update(
      'item_cost',
      itemCost.toMap(),
      where: 'id = ?',
      whereArgs: [itemCost.id],
    );
  }

  // Delete item cost
  Future<int> delete(int id, {Transaction? txn}) async {
    final db = txn ?? await databaseService.database;
    return await db.delete('item_cost', where: 'id = ?', whereArgs: [id]);
  }

  // Delete multiple item costs
  Future<void> deleteMultiple(List<ItemCost> items, {Transaction? txn}) async {
    final db = txn ?? await databaseService.database;
    final batch = db.batch();

    for (final item in items) {
      if (item.id != null) {
        batch.delete('item_cost', where: 'id = ?', whereArgs: [item.id]);
      }
    }

    await batch.commit();
  }

  // Find item cost by ID
  Future<ItemCost?> findById(int id) async {
    final db = await databaseService.database;
    final maps = await db.query('item_cost', where: 'id = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      return ItemCost.fromMap(maps.first);
    }
    return null;
  }

  // Find all item costs
  Future<List<ItemCost>> findAll(int companyId) async {
    final db = await databaseService.database;
    final maps = await db.rawQuery(
      '''SELECT ic.*,
    i.item_description,
    i.barcode,
    u.user_name as user_name,
    c.company_name as company_name,
    udc.description_1 as unit_of_measure_description,
    udc.detail_code as unit_of_measure_code
    FROM item_cost ic
    LEFT JOIN items_table i ON ic.item_number = i.id
    LEFT JOIN user_table u ON ic.user_id = u.id
    LEFT JOIN company_table c ON ic.company = c.id
    LEFT JOIN udc_details udc ON i.unit_of_measure = udc.id
    WHERE ic.company = ?''',
      [companyId],
    );
    return maps.map((map) => ItemCost.fromMap(map)).toList();
  }

  // Find item costs by item number and company
  Future<List<ItemCost>> findByItemNumberAndCompany(
    int itemNumber,
    int companyId, {
    Transaction? txn,
  }) async {
    final db = txn ?? await databaseService.database;
    final maps = await db.query(
      'item_cost',
      where: 'item_number = ? AND company = ?',
      whereArgs: [itemNumber, companyId],
    );
    return maps.map((map) => ItemCost.fromMap(map)).toList();
  }

  // Find item cost by item
  Future<ItemCost?> findByItem(int itemNumber, int companyId) async {
    final db = await databaseService.database;
    final maps = await db.rawQuery(
      '''SELECT ic.*,
    i.item_description,
    i.barcode,
    u.user_name as user_name,
    c.company_name as company_name,
    udc.description_1 as unit_of_measure_description,
    udc.detail_code as unit_of_measure_code
    FROM item_cost ic
    LEFT JOIN items_table i ON ic.item_number = i.id
    LEFT JOIN user_table u ON ic.user_id = u.id
    LEFT JOIN company_table c ON ic.company = c.id
    LEFT JOIN udc_details udc ON i.unit_of_measure = udc.id
    WHERE ic.item_number = ? AND ic.company = ?''',
      [itemNumber, companyId],
    );

    if (maps.isNotEmpty) {
      return ItemCost.fromMap(maps.first);
    }
    return null;
  }

  // Execute custom query
  Future<List<ItemCost>> executeCustomQuery(
    String whereClause,
    List<dynamic> whereArgs,
  ) async {
    final db = await databaseService.database;
    final maps = await db.rawQuery('''SELECT ic.*,
    i.item_description,
    i.barcode,
    u.user_name as user_name,
    c.company_name as company_name,
    udc.description_1 as unit_of_measure_description,
    udc.detail_code as unit_of_measure_code
    FROM item_cost ic
    LEFT JOIN items_table i ON ic.item_number = i.id
    LEFT JOIN user_table u ON ic.user_id = u.id
    LEFT JOIN company_table c ON ic.company = c.id
    LEFT JOIN udc_details udc ON i.unit_of_measure = udc.id
    WHERE $whereClause''', whereArgs);
    return maps.map((map) => ItemCost.fromMap(map)).toList();
  }

  // Get items with joins for detailed information
  Future<List<Map<String, dynamic>>> findDetailedItemCosts(
    int companyId,
  ) async {
    final db = await databaseService.database;
    return await db.rawQuery(
      '''
      SELECT ic.*, 
             i.item_description, i.barcode,
             u.user_name as user_name,
             c.company_name as company_name,
             udc.description_1 as unit_of_measure_description,
             udc.detail_code as unit_of_measure_code
      FROM item_cost ic
      LEFT JOIN items_table i ON ic.item_number = i.id
      LEFT JOIN user_table u ON ic.user_id = u.id
      LEFT JOIN company_table c ON ic.company = c.id
      LEFT JOIN udc_details udc ON i.unit_of_measure = udc.id
      WHERE ic.company = ?
      ORDER BY ic.date_updated DESC
    ''',
      [companyId],
    );
  }

  // Get purchase history for item
  Future<List<ItemCost>> getPurchaseHistory(int itemId, int companyId) async {
    final db = await databaseService.database;
    final maps = await db.query(
      'item_cost',
      where: 'item_number = ? AND company = ?',
      whereArgs: [itemId, companyId],
    );
    return maps.map((map) => ItemCost.fromMap(map)).toList();
  }

  // Update multiple item costs in batch
  Future<void> updateBatch(List<ItemCost> items) async {
    final db = await databaseService.database;
    final batch = db.batch();

    for (final item in items) {
      if (item.id != null) {
        batch.update(
          'item_cost',
          item.toMap(),
          where: 'id = ?',
          whereArgs: [item.id],
        );
      }
    }

    await batch.commit();
  }

  // Check if item cost exists for item and company
  Future<bool> existsByItemAndCompany(int itemNumber, int companyId) async {
    final db = await databaseService.database;
    final maps = await db.query(
      'item_cost',
      where: 'item_number = ? AND company = ?',
      whereArgs: [itemNumber, companyId],
      limit: 1,
    );
    return maps.isNotEmpty;
  }

  Future<double> calculateItemCost({
    required SalesOrderDetail item,
    required int companyId,
  }) async {
    try {
      // Get standard cost from item cost table
      final itemCost = await findByItemNumberAndCompany(
        item.itemsTableId!,
        companyId,
      );

      double unitCost = 0.0;
      String costSource = 'Standard Cost';

      if (itemCost.isNotEmpty) {
        unitCost = itemCost.first.amountUnitCost ?? 0.0;
      } else {
        // Fallback: Use last purchase price or average cost
        final avgCost = await _getAverageCost(item.itemsTableId!, companyId);
        unitCost = avgCost;
        costSource = 'Average Cost';
      }

      // Apply UOM conversion if needed
      if (item.unitOfMeasure != null &&
          item.itemBranch?.unitOfMeasure != item.unitOfMeasure) {
        unitCost = await _convertCostUOM(
          unitCost,
          item.itemsTableId!,
          item.itemBranch!.unitOfMeasure!,
          item.unitOfMeasure!,
          companyId,
        );
      }

      final amountCost = unitCost * (item.quantity ?? 0);

      return amountCost;
    } catch (e) {
      // Fallback to zero cost with error tracking
      return 0.0;
    }
  }

  Future<double> _getAverageCost(int itemId, int companyId) async {
    // Implement average cost calculation based on purchase history
    final purchaseHistory = await getPurchaseHistory(itemId, companyId);

    if (purchaseHistory.isEmpty) return 0.0;

    final totalValue = purchaseHistory.fold(
      0.0,
      (sum, record) =>
          sum + (record.amountUnitCost! * record.fromUOM!.quantityAvailable!),
    );
    final totalQuantity = purchaseHistory.fold(
      0.0,
      (sum, record) => sum + record.fromUOM!.quantityAvailable!,
    );

    return totalQuantity > 0 ? totalValue / totalQuantity : 0.0;
  }

  Future<double> _convertCostUOM(
    double cost,
    int itemId,
    int fromUomId,
    int toUomId,
    int companyId,
  ) async {
    // Get UOM conversion factor and adjust cost
    final conversion = await uomConversionRepository.getConversionFactor(
      itemId,
      fromUomId,
      toUomId,
      companyId,
    );

    return cost * conversion;
  }

  // Calculate total cost for all items in order
  Future<double> calculateTotalOrderCost(List<SalesOrderDetail> items) async {
    double totalCost = 0.0;

    for (final item in items) {
      final costResult = await calculateItemCost(
        item: item,
        companyId: item.company!,
      );
      totalCost += costResult;
    }

    return totalCost;
  }

  //item cost report method
  Future<PaginatedItemCostResult> getPaginatedItemCosts({
    required int companyId,
    required int page,
    required int pageSize,
    String? sortField,
    bool ascending = true,
  }) async {
    final db = await databaseService.database;

    // Build base query
    var query = '''
      SELECT ic.*,
          i.item_description,
          i.items_id as item_id,
          i.unit_of_measure,
          u.user_name as user_name,
          c.company_name as company_name,
          udc.description_1 as unit_of_measure_description,
          udc.detail_code as unit_of_measure_code
      FROM item_cost ic
      LEFT JOIN items_table i ON ic.item_number = i.id
      LEFT JOIN user_table u ON ic.user_id = u.id
      LEFT JOIN company_table c ON ic.company = c.id
      LEFT JOIN udc_details udc ON i.unit_of_measure = udc.id
      WHERE ic.company = ?
    ''';

    final params = <dynamic>[companyId];

    // Add sorting
    if (sortField != null) {
      query += ' ORDER BY $sortField ${ascending ? 'ASC' : 'DESC'}';
    }

    // Add pagination
    query += ' LIMIT ? OFFSET ?';
    params.add(pageSize);
    params.add((page - 1) * pageSize);

    // Execute main query
    final itemsData = await db.rawQuery(query, params);

    // Count total records
    final countResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM item_cost WHERE company = ?',
      [companyId],
    );

    final totalCount = (countResult.first['count'] as int?) ?? 0;

    // Parse results
    final items = itemsData.map((row) {
      return ItemCost.fromMap(row);
    }).toList();

    return PaginatedItemCostResult(items: items, totalCount: totalCount);
  }
}
