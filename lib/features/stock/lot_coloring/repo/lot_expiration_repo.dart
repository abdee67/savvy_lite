import 'dart:async';
import 'package:savvy_stock/core/repositories/base_repo.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/stock/lot_coloring/model/lot_coloring_model.dart';
import 'package:savvy_stock/features/udc_detail/models/udc_details.dart';

class LotExpirationColorsRepository extends BaseRepository {
  @override
  final LocalDatabaseService databaseService;

  LotExpirationColorsRepository({required this.databaseService});

  // Load all lot expiration colors for a company
  Future<List<LotExpirationColor>> loadLotExpirationColors(
    int companyId,
  ) async {
    final db = await databaseService.database;
    final colors = await db.rawQuery(
      '''
      SELECT lec.*,
             b.description as branch_name,
             it.item_description,
             it.item_description as item_description,
             ud.detail_code as color_type_code,
             ud.description_1 as color_type_name
      FROM lot_expiration_colors lec
      LEFT JOIN branch_table b ON lec.branch = b.id
      LEFT JOIN items_table it ON lec.item_number = it.id
      LEFT JOIN udc_details ud ON lec.color_type = ud.id
      WHERE lec.company = ?
      ORDER BY 
        CASE 
          WHEN lec.lot_exp_level = '1' THEN 1
          WHEN lec.lot_exp_level = '2' THEN 2  
          WHEN lec.lot_exp_level = '3' THEN 3
          WHEN lec.lot_exp_level = '4' THEN 4
          ELSE 5
        END,
        lec.days_minimum
    ''',
      [companyId],
    );

    return colors.map((p) => LotExpirationColor.fromMap(p)).toList();
  }

  // Save new lot expiration color
  Future<int> insertLotExpirationColor(
    LotExpirationColor color,
    int companyId,
  ) async {
    final db = await databaseService.database;
    final colorMap = color.toMap();
    colorMap.remove('id');
    colorMap['company'] = companyId;

    final id = await db.insert('lot_expiration_colors', withSyncKey(colorMap));
    
    captureSync(
      tableName: 'lot_expiration_colors',
      entityMap: colorMap,
      entityId: id.toString(),
      operation: 'INSERT',
      company: companyId.toString(),
    );

    return id;
  }

  // Update existing lot expiration color
  Future<int> updateLotExpirationColor(
    LotExpirationColor color,
    int companyId,
  ) async {
    final db = await databaseService.database;
    final rowsAffected = await db.update(
      'lot_expiration_colors',
      color.toMap(),
      where: 'id = ? AND company = ?',
      whereArgs: [color.id, companyId],
    );
    
    if (rowsAffected > 0) {
      captureSync(
        tableName: 'lot_expiration_colors',
        entityMap: color.toMap(),
        entityId: color.id.toString(),
        operation: 'UPDATE',
        company: companyId.toString(),
      );
    }
    
    return rowsAffected;
  }

  // Delete single lot expiration color
  Future<int> deleteLotExpirationColor(int id, int companyId) async {
    final db = await databaseService.database;
    // Fetch full row data BEFORE deleting
    final colorRows = await db.query(
      'lot_expiration_colors',
      where: 'id = ? AND company = ?',
      whereArgs: [id, companyId],
    );
    final rowsAffected = await db.delete(
      'lot_expiration_colors',
      where: 'id = ? AND company = ?',
      whereArgs: [id, companyId],
    );
    
    if (rowsAffected > 0) {
      for (final row in colorRows) {
      captureSync(
        tableName: 'lot_expiration_colors',
        entityMap: row,
        entityId: id.toString(),
        operation: 'DELETE',
        company: companyId.toString(),
      );
      }
    }
    
    return rowsAffected;
  }

  // Delete multiple lot expiration colors
  Future<void> deleteMultipleLotExpirationColors(
    List<LotExpirationColor> colors,
    int companyId,
  ) async {
    final db = await databaseService.database;
    final batch = db.batch();
    // Fetch full row data BEFORE deleting
    final colorRows = await db.query(
      'lot_expiration_colors',
      where: 'id IN (${colors.map((c) => c.id).join(',')}) AND company = ?',
      whereArgs: [companyId],
    );

    for (final color in colors) {
      batch.delete(
        'lot_expiration_colors',
        where: 'id = ? AND company = ?',
        whereArgs: [color.id, companyId],
      );
      for (final row in colorRows) {
      captureSync(
        tableName: 'lot_expiration_colors',
        entityMap: row,
        entityId: row['id'].toString(),
        operation: 'DELETE',
        company: companyId.toString(),
      );
      }
    }

    await batch.commit();
  }

  // Check for duplicate lot expiration color configuration
  Future<bool> checkForDuplicate(
    LotExpirationColor color,
    int companyId,
  ) async {
    final db = await databaseService.database;

    var whereClause = 'company = ? AND color_type = ?';
    final whereArgs = <dynamic>[companyId, color.colorType];

    switch (color.lotExpLevel) {
      case '1': // Company level
        whereClause += ' AND branch IS NULL AND item_number IS NULL';
        break;
      case '2': // Store level
        whereClause += ' AND branch = ? AND item_number IS NULL';
        whereArgs.add(color.branch);
        break;
      case '3': // Item level
        whereClause += ' AND branch IS NULL AND item_number = ?';
        whereArgs.add(color.itemNumber);
        break;
      case '4': // Item store level
        whereClause += ' AND branch = ? AND item_number = ?';
        whereArgs.addAll([color.branch, color.itemNumber]);
        break;
    }

    // Exclude current record when updating
    if (color.id != null) {
      whereClause += ' AND id != ?';
      whereArgs.add(color.id);
    }

    final result = await db.query(
      'lot_expiration_colors',
      where: whereClause,
      whereArgs: whereArgs,
    );

    return result.isNotEmpty;
  }

  // Get colors for specific scope (used for range validation)
  Future<List<LotExpirationColor>> getColorsForScope(
    LotExpirationColor color,
    int companyId,
  ) async {
    final db = await databaseService.database;

    final whereClause = _buildScopeWhereClause(color);
    final whereArgs = _buildScopeWhereArgs(color, companyId);

    final results = await db.query(
      'lot_expiration_colors',
      where: whereClause,
      whereArgs: whereArgs,
    );

    return results.map((m) => LotExpirationColor.fromMap(m)).toList();
  }

  // Get lot expiration color by details for calculation
  Future<LotExpirationColor?> getLotExpirationColorByDetails({
    required int companyId,
    required int? branchId,
    required int? itemId,
    required int daysDifference,
  }) async {
    final db = await databaseService.database;
    List<Map<String, dynamic>> results = [];

    // Try different levels in order of specificity
    if (branchId != null && itemId != null) {
      // Level 4: Item Store Level
      results = await db.rawQuery(
        '''
        SELECT lec.*, ud.detail_code as color_type_code, ud.description_1 as color_type_name
        FROM lot_expiration_colors lec
        LEFT JOIN udc_details ud ON lec.color_type = ud.id
        WHERE lec.company = ? 
        AND lec.item_number = ? 
        AND lec.branch = ?
        AND ? BETWEEN lec.days_minimum AND lec.days_maximum
        AND lec.active_for_sales_flag = 'Y'
        LIMIT 1
        ''',
        [companyId, itemId, branchId, daysDifference],
      );
    }

    if (results.isEmpty && itemId != null) {
      // Level 3: Item Level
      results = await db.rawQuery(
        '''
        SELECT lec.*, ud.detail_code as color_type_code, ud.description_1 as color_type_name
        FROM lot_expiration_colors lec
        LEFT JOIN udc_details ud ON lec.color_type = ud.id
        WHERE lec.company = ? 
        AND lec.item_number = ? 
        AND lec.branch IS NULL
        AND ? BETWEEN lec.days_minimum AND lec.days_maximum
        AND lec.active_for_sales_flag = 'Y'
        LIMIT 1
        ''',
        [companyId, itemId, daysDifference],
      );
    }

    if (results.isEmpty && branchId != null) {
      // Level 2: Store Level
      results = await db.rawQuery(
        '''
        SELECT lec.*, ud.detail_code as color_type_code, ud.description_1 as color_type_name
        FROM lot_expiration_colors lec
        LEFT JOIN udc_details ud ON lec.color_type = ud.id
        WHERE lec.company = ? 
        AND lec.branch = ?
        AND lec.item_number IS NULL
        AND ? BETWEEN lec.days_minimum AND lec.days_maximum
        AND lec.active_for_sales_flag = 'Y'
        LIMIT 1
        ''',
        [companyId, branchId, daysDifference],
      );
    }

    if (results.isEmpty) {
      // Level 1: Company Level
      results = await db.rawQuery(
        '''
        SELECT lec.*, ud.detail_code as color_type_code, ud.description_1 as color_type_name
        FROM lot_expiration_colors lec
        LEFT JOIN udc_details ud ON lec.color_type = ud.id
        WHERE lec.company = ? 
        AND lec.branch IS NULL
        AND lec.item_number IS NULL
        AND ? BETWEEN lec.days_minimum AND lec.days_maximum
        AND lec.active_for_sales_flag = 'Y'
        LIMIT 1
        ''',
        [companyId, daysDifference],
      );
    }

    if (results.isEmpty) {
      return null;
    }

    return LotExpirationColor.fromMap(results.first);
  }

  // Get UDC detail for lot type
  Future<UdcDetails?> getLotTypeUdcDetail(int? lotTypeId) async {
    if (lotTypeId == null) return null;

    try {
      final db = await databaseService.database;
      final result = await db.rawQuery(
        '''
        SELECT * FROM udc_details 
        WHERE id = ? AND record_header = (SELECT id FROM udc_header WHERE udc_code = 'LT')
        ''',
        [lotTypeId],
      );

      if (result.isNotEmpty) {
        return UdcDetails.fromJson(result.first);
      } else {
        // Try without header constraint as fallback
        final fallbackResult = await db.rawQuery(
          'SELECT * FROM udc_details WHERE id = ?',
          [lotTypeId],
        );
        if (fallbackResult.isNotEmpty) {
          return UdcDetails.fromJson(fallbackResult.first);
        }
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Helper methods for scope-based queries
  String _buildScopeWhereClause(LotExpirationColor color) {
    switch (color.lotExpLevel) {
      case '1':
        return 'company = ? AND branch IS NULL AND item_number IS NULL';
      case '2':
        return 'company = ? AND branch = ? AND item_number IS NULL';
      case '3':
        return 'company = ? AND branch IS NULL AND item_number = ?';
      case '4':
        return 'company = ? AND branch = ? AND item_number = ?';
      default:
        return 'company = ?';
    }
  }

  List<dynamic> _buildScopeWhereArgs(LotExpirationColor color, int companyId) {
    final args = <dynamic>[companyId];
    switch (color.lotExpLevel) {
      case '2':
        args.add(color.branch);
        break;
      case '3':
        args.add(color.itemNumber);
        break;
      case '4':
        args.add(color.branch);
        args.add(color.itemNumber);
        break;
      default:
        break;
    }
    return args;
  }
}
