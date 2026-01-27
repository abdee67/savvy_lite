// features/stock/item_uom_conversions/repositories/item_uom_conversions_repository.dart
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/stock/item_uom_conversions/models/item_uom_conversions_model.dart';
import 'package:savvy_stock/features/udc_detail/models/udc_details.dart';
import 'package:sqflite/sqflite.dart';

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
             uom_from.description_1 as from_uom_description,
             uom_to.description_1 as to_uom_description
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
             uom_from.description_1 as from_uom_description,
             uom_to.description_1 as to_uom_description
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

  // Get all conversion records for an item
  Future<List<UdcDetails>> getUomsForItem(int itemId, int companyId) async {
    final db = await databaseService.database;

    try {
      // Get all unique UoM IDs used for this item
      final uomIdsResult = await db.rawQuery(
        '''
      -- Get item's primary UoM, resolving either id, detail_code, or description_1
      SELECT ud.id as uom_id
      FROM items_table it
      LEFT JOIN udc_details ud
        ON ud.id = it.unit_of_measure
        OR ud.detail_code = it.unit_of_measure
        OR ud.description_1 = it.unit_of_measure
      WHERE it.id = ? AND it.company = ? AND it.unit_of_measure IS NOT NULL
      
      UNION
      
      -- Get from_uom from conversions
      SELECT from_uom as uom_id FROM item_uom_conversions 
      WHERE item_number = ? AND company = ? AND from_uom IS NOT NULL
      
      UNION
      
      -- Get to_uom from conversions  
      SELECT to_uom as uom_id FROM item_uom_conversions 
      WHERE item_number = ? AND company = ? AND to_uom IS NOT NULL
      ''',
        [itemId, companyId, itemId, companyId, itemId, companyId],
      );

      if (uomIdsResult.isEmpty) {
        return [];
      }

      int? asInt(dynamic v) {
        if (v == null) return null;
        if (v is int) return v;
        if (v is String) return int.tryParse(v);
        return null;
      }

      // Extract UoM IDs (handle both int and string values)
      final uomIds = uomIdsResult
          .map((row) => asInt(row['uom_id']))
          .whereType<int>()
          .toSet()
          .toList();

      if (uomIds.isEmpty) {
        return [];
      }

      // Get UdcDetails for all unique IDs
      final placeholders = List.filled(uomIds.length, '?').join(',');
      final uomDetailsResult = await db.rawQuery('''
      SELECT * FROM udc_details 
      WHERE id IN ($placeholders) 
      ORDER BY description_1
      ''', uomIds);

      return uomDetailsResult.map((row) => UdcDetails.fromJson(row)).toList();
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error getting UoMs for item: $e');
      }
      return [];
    }
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

    // Check for bidirectional duplication: (from=A AND to=B) OR (from=B AND to=A)
    if (item.fromUom != null && item.toUom != null) {
      whereParts.add(
        '((from_uom = ? AND to_uom = ?) OR (from_uom = ? AND to_uom = ?))',
      );
      whereArgs.add(item.fromUom);
      whereArgs.add(item.toUom);
      whereArgs.add(item.toUom); // Reverse check
      whereArgs.add(item.fromUom); // Reverse check
    } else {
      // Fallback for partial data (though unlikely for valid conversion)
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
    int companyId, {
    Transaction? txn,
  }) async {
    final db = txn ?? await databaseService.database;

    // First, try the specified column (from_uom or to_uom)
    final column = fromTo.toLowerCase() == 'to' ? 'to_uom' : 'from_uom';

    var result = await db.rawQuery(
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

    // If not found, check the other column as well
    // This handles cases where UOM is in the opposite column
    final otherColumn = column == 'from_uom' ? 'to_uom' : 'from_uom';
    result = await db.rawQuery(
      '''
      SELECT uom_structure_level 
      FROM item_uom_conversions 
      WHERE item_number = ? AND $otherColumn = ? AND company = ?
      ''',
      [itemId, uomId, companyId],
    );

    if (result.isNotEmpty) {
      // Found in opposite column - return adjusted structure level
      // If found in to_uom, it's one level lower than the record's structure
      if (kDebugMode) {
        developer.log(
          '  → Found UOM $uomId in $otherColumn column at structure level ${result.first['uom_structure_level']}',
        );
      }
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
    int companyId, {
    Transaction? txn,
  }) async {
    if (fromUomId == toUomId) {
      return 1.0;
    }

    try {
      // Get item primary UoM
      final primaryUomId = await getItemPrimaryUom(itemId, companyId);
      if (kDebugMode) {
        developer.log(
          '🔄 UOM Conversion: item=$itemId, from=$fromUomId, to=$toUomId, primary=$primaryUomId',
        );
      }

      // Check if one of the UoMs is primary like Java does
      if (primaryUomId != null) {
        if (primaryUomId == fromUomId) {
          if (kDebugMode) {
            developer.log('  → fromUom is primary, calling fromPrimaryToOther');
          }
          return await fromPrimaryToOther(itemId, toUomId, companyId);
        } else if (primaryUomId == toUomId) {
          if (kDebugMode) {
            developer.log('  → toUom is primary, calling fromOtherToPrimary');
          }
          return await fromOtherToPrimary(itemId, fromUomId, companyId);
        }
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

      if (kDebugMode) {
        developer.log('  → Structure levels: from=$strFrom, to=$strTo');
      }

      if (strFrom != null && strTo != null) {
        // Use structured conversion like Java
        return await _structuredConversion(itemId, strFrom, strTo, companyId);
      }

      // Fallback to unstructured conversion
      if (kDebugMode) {
        developer.log('  → Falling back to unstructured conversion');
      }
      return await getUnstructuredUomConversion(
        itemId,
        fromUomId,
        toUomId,
        companyId,
      );
    } catch (e) {
      if (kDebugMode) {
        developer.log('❌ UOM Conversion error: $e');
      }
      return 1.0;
    }
  }

  Future<double> fromPrimaryToOther(
    int itemId,
    int toUomId,
    int companyId,
  ) async {
    final factor = await fromOtherToPrimary(itemId, toUomId, companyId);
    return factor != 0.0 ? 1.0 / factor : 1.0;
  }

  Future<double> fromOtherToPrimary(
    int itemId,
    int fromUomId,
    int companyId, {
    Transaction? txn,
  }) async {
    try {
      final db = txn ?? await databaseService.database;

      // First check if this UOM is in the from_uom column (regular structure)
      var result = await db.rawQuery(
        '''
        SELECT uom_structure_level, conversion_factor 
        FROM item_uom_conversions 
        WHERE item_number = ? AND from_uom = ? AND company = ?
        ''',
        [itemId, fromUomId, companyId],
      );

      if (result.isNotEmpty) {
        // UOM is in from_uom column - multiply factors from this level upward
        final str = result.first['uom_structure_level'] as int?;
        if (kDebugMode) {
          developer.log(
            '  → fromOtherToPrimary: fromUomId=$fromUomId found in from_uom at level $str',
          );
        }

        if (str == null) return 1.0;

        final conversions = await db.rawQuery(
          '''
          SELECT conversion_factor, uom_structure_level 
          FROM item_uom_conversions 
          WHERE item_number = ? AND company = ? 
            AND uom_structure_level >= ?
          ORDER BY uom_structure_level ASC
          ''',
          [itemId, companyId, str],
        );

        double factor = 1.0;
        for (final conversion in conversions) {
          final conversionFactor = conversion['conversion_factor'] as double?;
          if (conversionFactor != null) {
            factor *= conversionFactor;
          }
        }

        if (kDebugMode) {
          developer.log(
            '  → Found ${conversions.length} records, final factor: $factor',
          );
        }
        return factor;
      }

      // Check if UOM is in to_uom column - this means it's a derived UOM
      // and we need to calculate the INVERSE to get back to primary
      result = await db.rawQuery(
        '''
        SELECT uom_structure_level, conversion_factor 
        FROM item_uom_conversions 
        WHERE item_number = ? AND to_uom = ? AND company = ?
        ''',
        [itemId, fromUomId, companyId],
      );

      if (result.isNotEmpty) {
        // UOM is in to_uom column - need to take inverse of factor
        final conversionFactor = result.first['conversion_factor'] as double?;
        final str = result.first['uom_structure_level'] as int?;

        if (kDebugMode) {
          developer.log(
            '  → fromOtherToPrimary: fromUomId=$fromUomId found in to_uom at level $str',
          );
          developer.log(
            '  → Base conversion factor: $conversionFactor, taking inverse',
          );
        }

        if (conversionFactor == null || conversionFactor == 0.0) return 1.0;

        // For UOM in to_uom, we divide by factor (inverse)
        // e.g., if from_uom=1(pieces), to_uom=2(kg), factor=5 means 1 piece = 5 kg
        // To convert kg → pieces, we need 1/5 = 0.2
        final inverseFactor = 1.0 / conversionFactor;

        if (kDebugMode) {
          developer.log('  → Final inverse factor: $inverseFactor');
        }

        return inverseFactor;
      }

      if (kDebugMode) {
        developer.log(
          '  ⚠️ UOM $fromUomId not found in any conversion, returning 1.0',
        );
      }
      return 1.0;
    } catch (e) {
      if (kDebugMode) {
        developer.log('  ❌ fromOtherToPrimary error: $e');
      }
      return 1.0;
    }
  }

  Future<double> _structuredConversion(
    int itemId,
    int fromLevel,
    int toLevel,
    int companyId,
  ) async {
    final db = await databaseService.database;

    // Determine the conversion direction and levels
    final isAscending = fromLevel <= toLevel;
    final startLevel = isAscending ? fromLevel : toLevel;
    final endLevel = isAscending ? toLevel : fromLevel;

    final conversions = await db.rawQuery(
      '''
      SELECT conversion_factor, uom_structure_level 
      FROM item_uom_conversions 
      WHERE item_number = ? AND company = ? 
        AND uom_structure_level BETWEEN ? AND ?
      ORDER BY uom_structure_level ${isAscending ? 'ASC' : 'DESC'}
      ''',
      [itemId, companyId, startLevel, endLevel],
    );

    double factor = 1.0;
    for (final conversion in conversions) {
      final conversionFactor = conversion['conversion_factor'] as double?;
      if (conversionFactor != null) {
        factor *= conversionFactor;
      }
    }

    // If converting in reverse direction, take reciprocal
    return !isAscending ? (1.0 / factor) : factor;
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

  // Batch Operations (replicating Java bulk operations)
  Future<bool> createBatch(List<ItemUomConversion> items) async {
    final db = await databaseService.database;
    final batch = db.batch();

    try {
      for (final item in items) {
        final itemMap = item.toMap();
        itemMap.remove('id');
        batch.insert('item_uom_conversions', itemMap);
      }

      await batch.commit(noResult: true);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateBatch(List<ItemUomConversion> items) async {
    final db = await databaseService.database;
    final batch = db.batch();

    try {
      for (final item in items) {
        batch.update(
          'item_uom_conversions',
          item.toMap(),
          where: 'id = ? AND company = ?',
          whereArgs: [item.id, item.company],
        );
      }

      await batch.commit(noResult: true);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> removeBatch(List<ItemUomConversion> items) async {
    final db = await databaseService.database;
    final batch = db.batch();

    try {
      for (final item in items) {
        batch.delete(
          'item_uom_conversions',
          where: 'id = ? AND company = ?',
          whereArgs: [item.id, item.company],
        );
      }

      await batch.commit(noResult: true);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Enhanced validation replicating Java duplicate checking
  Future<Map<String, dynamic>> validateItemUomConversion(
    ItemUomConversion item,
  ) async {
    final hasDuplication = await checkDuplication(item);
    final isStructureValid = await checkStructureValidation(item);

    // Additional validation: check structure level consecutiveness
    final isConsecutive = await _validateConsecutiveStructureLevels(item);

    return {
      'hasDuplication': hasDuplication,
      'isStructureValid': isStructureValid,
      'isConsecutive': isConsecutive,
      'isValid': !hasDuplication && isStructureValid && isConsecutive,
    };
  }

  Future<bool> _validateConsecutiveStructureLevels(
    ItemUomConversion item,
  ) async {
    if (item.itemNumber == null) return true;

    final db = await databaseService.database;
    final existingLevels = await db.rawQuery(
      '''
      SELECT uom_structure_level 
      FROM item_uom_conversions 
      WHERE item_number = ? AND company = ?
      ORDER BY uom_structure_level
      ''',
      [item.itemNumber, item.company],
    );

    final levels = existingLevels
        .map((row) => row['uom_structure_level'] as int)
        .toList();

    // Add the current item's level for validation
    if (item.uomStructureLevel != null) {
      levels.add(item.uomStructureLevel!);
    }

    levels.sort();

    // Check if levels are consecutive (1, 2, 3...)
    for (int i = 0; i < levels.length; i++) {
      if (levels[i] != i + 1) {
        return false;
      }
    }

    return true;
  }
}
