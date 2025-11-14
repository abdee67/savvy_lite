// features/stock/item_uom_conversions/repositories/item_uom_conversions_repository.dart
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/stock/item_uom_conversions/models/item_uom_conversions_model.dart';
import 'package:savvy_stock/features/udc_detail/models/udc_details.dart';

class ItemUomConversionsRepository {
  final LocalDatabaseService databaseService;

  ItemUomConversionsRepository({required this.databaseService});

  // Get all UoM conversions for a company
  Future<List<ItemUomConversion>> getItemUomConversions(int companyId) async {
    final db = await databaseService.database;
    final items = await db.rawQuery(
      '''
      SELECT iuc.*,
             it.item_description,
             uom_from.description_1 as from_uom_description,
             uom_to.description_1 as to_uom_description
      FROM item_uom_conversions iuc
      LEFT JOIN items_table it ON iuc.item_number = it.id
      LEFT JOIN udc_details uom_from ON iuc.from_uom = uom_from.id
      LEFT JOIN udc_details uom_to ON iuc.to_uom = uom_to.id
      WHERE iuc.company = ?
      ORDER BY iuc.item_number, iuc.uom_structure_level
      ''',
      [companyId],
    );
    return items.map((p) => ItemUomConversion.fromMap(p)).toList();
  }

  // Get UoM conversion by ID
  Future<ItemUomConversion?> getItemUomConversionById(
    int id,
    int companyId,
  ) async {
    final db = await databaseService.database;
    final items = await db.rawQuery(
      '''
      SELECT iuc.*,
             it.item_description,
             uom_from.description as from_uom_description,
             uom_to.description as to_uom_description
      FROM item_uom_conversions iuc
      LEFT JOIN items_table it ON iuc.item_number = it.id
      LEFT JOIN udc_details uom_from ON iuc.from_uom = uom_from.id
      LEFT JOIN udc_details uom_to ON iuc.to_uom = uom_to.id
      WHERE iuc.id = ? AND iuc.company = ?
      ''',
      [id, companyId],
    );
    return items.isNotEmpty ? ItemUomConversion.fromMap(items.first) : null;
  }

  // Get UoM conversions by item number
  Future<List<ItemUomConversion>> getItemUomConversionsByItem(
    int itemNumber,
    int companyId,
  ) async {
    final db = await databaseService.database;
    final items = await db.rawQuery(
      '''
      SELECT iuc.*,
             it.item_description,
             uom_from.description as from_uom_description,
             uom_to.description as to_uom_description
      FROM item_uom_conversions iuc
      LEFT JOIN items_table it ON iuc.item_number = it.id
      LEFT JOIN udc_details uom_from ON iuc.from_uom = uom_from.id
      LEFT JOIN udc_details uom_to ON iuc.to_uom = uom_to.id
      WHERE iuc.item_number = ? AND iuc.company = ?
      ORDER BY iuc.uom_structure_level
      ''',
      [itemNumber, companyId],
    );
    return items.map((p) => ItemUomConversion.fromMap(p)).toList();
  }

  // Create new UoM conversion
  Future<int> createItemUomConversion(ItemUomConversion item) async {
    final db = await databaseService.database;
    final itemMap = item.toMap();
    itemMap.remove('id'); // Remove ID for new insertion
    return await db.insert('item_uom_conversions', itemMap);
  }

  // Update existing UoM conversion
  Future<int> updateItemUomConversion(ItemUomConversion item) async {
    final db = await databaseService.database;
    return await db.update(
      'item_uom_conversions',
      item.toMap(),
      where: 'id = ? AND company = ?',
      whereArgs: [item.id, item.company],
    );
  }

  // Delete UoM conversion
  Future<int> deleteItemUomConversion(int id, int companyId) async {
    final db = await databaseService.database;
    return await db.delete(
      'item_uom_conversions',
      where: 'id = ? AND company = ?',
      whereArgs: [id, companyId],
    );
  }

  // Check for duplication
  Future<bool> checkDuplication(ItemUomConversion item) async {
    final db = await databaseService.database;

    final whereParts = <String>[];
    final whereArgs = <dynamic>[];

    if (item.itemNumber != null) {
      whereParts.add('item_number = ?');
      whereArgs.add(item.itemNumber);
    } else {
      whereParts.add('item_number IS NULL');
    }

    if (item.fromUom != null) {
      whereParts.add('from_uom = ?');
      whereArgs.add(item.fromUom);
    } else {
      whereParts.add('from_uom IS NULL');
    }

    if (item.toUom != null) {
      whereParts.add('to_uom = ?');
      whereArgs.add(item.toUom);
    } else {
      whereParts.add('to_uom IS NULL');
    }

    if (item.company != null) {
      whereParts.add('company = ?');
      whereArgs.add(item.company);
    } else {
      whereParts.add('company IS NULL');
    }

    if (item.id != null) {
      whereParts.add('id != ?');
      whereArgs.add(item.id);
    }

    final whereClause = whereParts.join(' AND ');

    final existing = await db.query(
      'item_uom_conversions',
      where: whereClause,
      whereArgs: whereArgs,
    );

    return existing.isNotEmpty;
  }

  // Check structure validation
  Future<bool> checkStructureValidation(ItemUomConversion item) async {
    final db = await databaseService.database;

    // Check for duplicate structure level in database
    final existingStructure = await db.query(
      'item_uom_conversions',
      where:
          'item_number = ? AND uom_structure_level = ? AND company = ? AND id != ?',
      whereArgs: [
        item.itemNumber,
        item.uomStructureLevel,
        item.company,
        item.id ?? 0,
      ],
    );

    return existingStructure.isEmpty;
  }

  // Get UoM by structure level
  Future<int?> getUomByStructure(
    int itemId,
    int structureLevel,
    int companyId,
  ) async {
    final db = await databaseService.database;
    final result = await db.rawQuery(
      '''
      SELECT from_uom 
      FROM item_uom_conversions 
      WHERE item_number = ? AND uom_structure_level = ? AND company = ?
      ''',
      [itemId, structureLevel, companyId],
    );

    if (result.isNotEmpty) {
      return result.first['from_uom'] as int?;
    }
    return null;
  }

  // Get unstructured UoM conversion
  Future<double> getUnstructuredUomConversion(
    int itemId,
    int fromUomId,
    int toUomId,
    int companyId,
  ) async {
    final db = await databaseService.database;
    final result = await db.rawQuery(
      '''
      SELECT conversion_factor 
      FROM item_uom_conversions 
      WHERE item_number = ? AND from_uom = ? AND to_uom = ? AND company = ?
      ''',
      [itemId, fromUomId, toUomId, companyId],
    );

    if (result.isNotEmpty && result.first['conversion_factor'] != null) {
      return result.first['conversion_factor'] as double;
    }
    return 1.0;
  }

  // Get item UoM structure code
  Future<int?> getItemUomStructureCode(
    int itemId,
    int uomId,
    String fromTo,
    int companyId,
  ) async {
    final db = await databaseService.database;
    final column = fromTo.toLowerCase() == 'to' ? 'to_uom' : 'from_uom';

    final result = await db.rawQuery(
      '''
      SELECT uom_structure_level 
      FROM item_uom_conversions 
      WHERE item_number = ? AND $column = ? AND company = ?
      ''',
      [itemId, uomId, companyId],
    );

    if (result.isNotEmpty) {
      return result.first['uom_structure_level'] as int?;
    }
    return null;
  }

  // Get conversions between structure levels
  Future<List<Map<String, dynamic>>> getConversionsBetweenLevels(
    int itemId,
    int fromLevel,
    int toLevel,
    int companyId,
  ) async {
    final db = await databaseService.database;
    return await db.rawQuery(
      '''
      SELECT conversion_factor 
      FROM item_uom_conversions 
      WHERE item_number = ? AND company = ? 
        AND uom_structure_level BETWEEN ? AND ?
      ORDER BY uom_structure_level
      ''',
      [itemId, companyId, fromLevel, toLevel],
    );
  }

  // Get item primary UoM
  Future<int?> getItemPrimaryUom(int itemId, int companyId) async {
    final db = await databaseService.database;
    final result = await db.rawQuery(
      '''
      SELECT unit_of_measure FROM items_table 
      WHERE id = ? AND company = ?
      ''',
      [itemId, companyId],
    );

    if (result.isNotEmpty) {
      return result.first['unit_of_measure'] as int?;
    }
    return null;
  }

  // UoM Conversion Methods
  Future<double> fromOtherToAnother(
    int itemId,
    int fromUomId,
    int toUomId,
    int companyId,
  ) async {
    if (fromUomId == toUomId) {
      return 1.0;
    }

    try {
      // Get item primary UoM
      final primaryUomId = await getItemPrimaryUom(itemId, companyId);
      if (primaryUomId == null) {
        // Use unstructured conversion when no primary UOM
        return await getUnstructuredUomConversion(
          itemId,
          fromUomId,
          toUomId,
          companyId,
        );
      }

      // Check if one of the UoMs is primary
      if (primaryUomId == fromUomId) {
        return await fromPrimaryToOther(itemId, toUomId, companyId);
      } else if (primaryUomId == toUomId) {
        return await fromOtherToPrimary(itemId, fromUomId, companyId);
      }

      // Get structure levels for both UoMs
      final strFrom = await getItemUomStructureCode(
        itemId,
        fromUomId,
        'from',
        companyId,
      );
      final strTo = await getItemUomStructureCode(
        itemId,
        toUomId,
        'to',
        companyId,
      );

      if (strFrom == null || strTo == null) {
        // Use unstructured conversion when no structure levels found
        return await getUnstructuredUomConversion(
          itemId,
          fromUomId,
          toUomId,
          companyId,
        );
      }

      // Get conversions between the two structure levels
      final conversions = await getConversionsBetweenLevels(
        itemId,
        strFrom,
        strTo,
        companyId,
      );

      // If no structured conversions found, use unstructured
      if (conversions.isEmpty) {
        return await getUnstructuredUomConversion(
          itemId,
          fromUomId,
          toUomId,
          companyId,
        );
      }

      double factor = 1.0;
      for (final conversion in conversions) {
        final conversionFactor = conversion['conversion_factor'] as double?;
        if (conversionFactor != null) {
          factor *= conversionFactor;
        }
      }

      return factor;
    } catch (e) {
      // Fallback to unstructured conversion on error
      return await getUnstructuredUomConversion(
        itemId,
        fromUomId,
        toUomId,
        companyId,
      );
    }
  }

  Future<double> fromPrimaryToOther(
    int itemId,
    int toUomId,
    int companyId,
  ) async {
    final factor = await fromOtherToPrimary(itemId, toUomId, companyId);
    return factor != 1.0 ? 1.0 / factor : 1.0;
  }

  Future<double> fromOtherToPrimary(
    int itemId,
    int fromUomId,
    int companyId,
  ) async {
    try {
      final str = await getItemUomStructureCode(
        itemId,
        fromUomId,
        'from',
        companyId,
      );

      if (str == null) return 1.0;

      final conversions = await getConversionsBetweenLevels(
        itemId,
        str,
        100,
        companyId, // Use high number to get all levels above
      );

      double factor = 1.0;
      for (final conversion in conversions) {
        final conversionFactor = conversion['conversion_factor'] as double?;
        if (conversionFactor != null) {
          factor *= conversionFactor;
        }
      }

      return factor;
    } catch (e) {
      return 1.0;
    }
  }

  // Get conversion factor
  Future<double> getConversionFactor(
    int itemId,
    int fromUomId,
    int toUomId,
    int companyId,
  ) async {
    final db = await databaseService.database;
    final result = await db.rawQuery(
      '''
      SELECT conversion_factor 
      FROM item_uom_conversions 
      WHERE item_number = ? AND from_uom = ? AND to_uom = ? AND company = ?
      ''',
      [itemId, fromUomId, toUomId, companyId],
    );

    if (result.isNotEmpty && result.first['conversion_factor'] != null) {
      return result.first['conversion_factor'] as double;
    }
    return 1.0;
  }

  Future<double> convertQuantity({
    required int itemId,
    required double quantity,
    required UdcDetails fromUOM,
    required UdcDetails toUOM,
    required int companyId,
  }) async {
    try {
      // Same UOM - no conversion needed
      if (fromUOM.id == toUOM.id) {
        return quantity;
      }

      // Get conversion factor from database
      final conversion = await getConversionFactor(
        itemId,
        fromUOM.id,
        toUOM.id,
        companyId,
      );

      final convertedQuantity = quantity * conversion;

      return convertedQuantity;
    } catch (e) {
      // Return error result
      return quantity;
    }
  }

  // Convert price based on UOM
  Future<double> convertPrice({
    required int itemId,
    required double price,
    required int fromUomId,
    required int toUomId,
    required int companyId,
  }) async {
    try {
      if (fromUomId == toUomId) return price;

      final conversion = await getConversionFactor(
        itemId,
        fromUomId,
        toUomId,
        companyId,
      );

      return price * conversion;
    } catch (e) {
      return price;
    }
  }

  // Get all available UOMs for an item
  Future<List<ItemUomConversion>> getAvailableUOMsForItem(
    int itemId,
    int companyId,
  ) async {
    return await getItemUomConversionsByItem(itemId, companyId);
  }

  // Validate if conversion is possible
  Future<bool> validateUOMConversion({
    required int itemId,
    required int fromUomId,
    required int toUomId,
    required int companyId,
  }) async {
    if (fromUomId == toUomId) return true;

    final conversion = await getConversionFactor(
      itemId,
      fromUomId,
      toUomId,
      companyId,
    );

    return conversion != null;
  }
}
