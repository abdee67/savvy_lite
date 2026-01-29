// features/stock/location_entry/repositories/location_master_repository.dart
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/stock/location_entry/models/location_master_model.dart';
import 'package:savvy_stock/features/stock/item_in_branch/models/item_in_branch_model.dart';
import 'package:savvy_stock/features/stock/item_locations/models/item_locations_model.dart';
import 'package:sqflite/sqflite.dart';

class LocationMasterRepository {
  final LocalDatabaseService databaseService;

  LocationMasterRepository({required this.databaseService});

  // ========== CRUD Operations ==========

  /// Load all location masters for a company
  Future<List<LocationMaster>> getLocationMasters(int companyId) async {
    final db = await databaseService.database;
    final locations = await db.rawQuery(
      '''
      SELECT
        lm.*,
        b.description as branch_name
      FROM location_master lm
      LEFT JOIN branch_table b ON lm.branch = b.id
      WHERE lm.company = ?
      ORDER BY lm.location_description
      ''',
      [companyId],
    );

    return locations.map((p) => LocationMaster.fromMap(p)).toList();
  }

  /// Load location masters by branch
  Future<List<LocationMaster>> getLocationsByBranch(
    String locationDescription,
    int branchId,
    int companyId, {
    Transaction? txn,
  }) async {
    final db = txn ?? await databaseService.database;
    final locations = await db.rawQuery(
      '''
      SELECT lm.*,
             b.description as branch_name
      FROM location_master lm
      LEFT JOIN branch_table b ON lm.branch = b.id
      WHERE lm.branch = ? AND lm.company = ? AND lm.location_description = ?
      ORDER BY lm.location_description
      ''',
      [branchId, companyId, locationDescription],
    );

    return locations.map((e) => LocationMaster.fromMap(e)).toList();
  }

  /// Get a single location master by ID
  Future<LocationMaster?> getLocationMasterById(
    int id,
    int companyId, {
    Transaction? txn,
  }) async {
    final db = txn ?? await databaseService.database;
    final locations = await db.rawQuery(
      '''
      SELECT lm.*,
             b.description as branch_name
      FROM location_master lm
      LEFT JOIN branch_table b ON lm.branch = b.id
      WHERE lm.id = ? AND lm.company = ?
      ''',
      [id, companyId],
    );

    return locations.isNotEmpty
        ? LocationMaster.fromMap(locations.first)
        : null;
  }

  /// get location by location description
  Future<LocationMaster?> getLocationMasterByLocationDescription(
    String locationDescription,
    int companyId, {
    Transaction? txn,
  }) async {
    final db = txn ?? await databaseService.database;
    final locations = await db.rawQuery(
      '''
      SELECT lm.*,
             b.description as branch_name
      FROM location_master lm
      LEFT JOIN branch_table b ON lm.branch = b.id
      WHERE lm.location_description = ? AND lm.company = ?
      ''',
      [locationDescription, companyId],
    );

    return locations.isNotEmpty
        ? LocationMaster.fromMap(locations.first)
        : null;
  }

  /// Create a new location master
  Future<int> createLocationMaster(
    LocationMaster location,
    int userId,
    int companyId, {
    Transaction? txn,
  }) async {
    final db = txn ?? await databaseService.database;
    final locationMap = _prepareLocationMap(location, false, userId, companyId);
    locationMap.remove('id');

    return await db.insert('location_master', locationMap);
  }

  /// Update an existing location master
  Future<int> updateLocationMaster(
    LocationMaster location,
    int userId,
    int companyId, {
    Transaction? txn,
  }) async {
    final db = txn ?? await databaseService.database;
    final locationMap = _prepareLocationMap(location, true, userId, companyId);

    return await db.update(
      'location_master',
      locationMap,
      where: 'id = ? AND company = ?',
      whereArgs: [location.id, companyId],
    );
  }

  /// Delete a location master
  Future<int> deleteLocationMaster(
    int locationId,
    int companyId, {
    Transaction? txn,
  }) async {
    final db = txn ?? await databaseService.database;

    // First delete related item locations
    await db.delete(
      'item_location',
      where: 'location = ? AND company = ?',
      whereArgs: [locationId, companyId],
    );

    // Then delete the location
    return await db.delete(
      'location_master',
      where: 'id = ? AND company = ?',
      whereArgs: [locationId, companyId],
    );
  }

  /// Delete multiple location masters
  Future<int> deleteMultipleLocationMasters(
    List<int> locationIds,
    int companyId, {
    Transaction? txn,
  }) async {
    final db = txn ?? await databaseService.database;
    final batch = db.batch();

    for (final locationId in locationIds) {
      // Delete related item locations
      batch.delete(
        'item_location',
        where: 'location = ? AND company = ?',
        whereArgs: [locationId, companyId],
      );

      // Delete the location
      batch.delete(
        'location_master',
        where: 'id = ? AND company = ?',
        whereArgs: [locationId, companyId],
      );
    }

    final results = await batch.commit();
    return results.length;
  }

  // ========== Item Location Assignments ==========

  /// Get all items for a branch (for dual list source)
  Future<List<ItemInBranchModel>> getItemsForBranch(
    int branchId,
    int companyId, {
    Transaction? txn,
  }) async {
    final db = txn ?? await databaseService.database;
    final items = await db.rawQuery(
      '''
      SELECT ib.*,
             it.item_description,
             it.items_id,
             uom.detail_code as unit_of_measure_code,
             uom.description_1 as unit_of_measure_description
      FROM items_in_branch ib
      LEFT JOIN items_table it ON ib.item_number = it.id
      LEFT JOIN udc_details uom ON ib.unit_of_measure = uom.id
      WHERE ib.branch = ? AND ib.company = ?
      ORDER BY it.item_description
      ''',
      [branchId, companyId],
    );

    return items.map((e) => ItemInBranchModel.fromMap(e)).toList();
  }

  /// Get assigned items for a location (for dual list target)
  Future<List<ItemInBranchModel>> getAssignedItemsForLocation(
    int locationId,
    int companyId, {
    Transaction? txn,
  }) async {
    final db = txn ?? await databaseService.database;
    final assignedItems = await db.rawQuery(
      '''
      SELECT ib.*,
             it.item_description,
             it.items_id,
             uom.detail_code as unit_of_measure_code,
             uom.description_1 as unit_of_measure_description,
             il.quantity_on_hand
      FROM item_location il
      JOIN items_in_branch ib ON il.item_number = ib.item_number AND il.branch = ib.branch
      LEFT JOIN items_table it ON ib.item_number = it.id
      LEFT JOIN udc_details uom ON ib.unit_of_measure = uom.id
      WHERE il.location = ? AND il.company = ?
      ORDER BY it.item_description
      ''',
      [locationId, companyId],
    );

    return assignedItems.map((e) => ItemInBranchModel.fromMap(e)).toList();
  }

  /// Save item location assignments (for new location)
  Future<void> saveItemLocations(
    int locationId,
    List<ItemInBranchModel> assignedItems,
    int userId,
    int companyId, {
    Transaction? txn,
  }) async {
    final db = txn ?? await databaseService.database;
    final batch = db.batch();

    for (final item in assignedItems) {
      // Check if item location already exists
      final existing = await db.rawQuery(
        '''
        SELECT COUNT(*) as count FROM item_location
        WHERE branch = ? AND item_number = ? AND location = ? AND company = ?
        ''',
        [item.branch, item.itemNumber, locationId, companyId],
      );

      final count = (existing.first['count'] as int?) ?? 0;
      if (count == 0) {
        final itemLocation = ItemLocation(
          branch: item.branch,
          itemNumber: item.itemNumber,
          location: locationId,
          quantityOnHand: item.quantityAvailable ?? 0.0,
          dateUpdated: DateTime.now(),
          dateCreated: DateTime.now(),
          updatedBy: userId,
          createdBy: userId,
          company: companyId,
        );

        batch.insert('item_location', itemLocation.toMap());
      }
    }

    await batch.commit();
  }

  /// Update item location assignments (for existing location)
  Future<void> updateItemLocations(
    int locationId,
    List<ItemInBranchModel> assignedItems,
    int userId,
    int companyId, {
    Transaction? txn,
  }) async {
    final db = txn ?? await databaseService.database;

    // Remove all existing assignments for this location
    await db.delete(
      'item_location',
      where: 'location = ? AND company = ?',
      whereArgs: [locationId, companyId],
    );

    // Add new assignments
    final batch = db.batch();
    for (final item in assignedItems) {
      final itemLocation = ItemLocation(
        branch: item.branch,
        itemNumber: item.itemNumber,
        location: locationId,
        quantityOnHand: item.quantityAvailable ?? 0.0,
        dateUpdated: DateTime.now(),
        dateCreated: DateTime.now(),
        updatedBy: userId,
        createdBy: userId,
        company: companyId,
      );

      batch.insert('item_location', itemLocation.toMap());
    }

    await batch.commit();
  }

  /// Get item location by composite key
  Future<ItemLocation?> getItemLocation(
    int branchId,
    int itemNumber,
    int locationId,
    int companyId, {
    Transaction? txn,
  }) async {
    final db = txn ?? await databaseService.database;
    final results = await db.rawQuery(
      '''
      SELECT * FROM item_location
      WHERE branch = ? AND item_number = ? AND location = ? AND company = ?
      ''',
      [branchId, itemNumber, locationId, companyId],
    );

    return results.isNotEmpty ? ItemLocation.fromMap(results.first) : null;
  }

  // ========== Validation and Business Logic ==========

  /// Check for duplicate location (same description and branch)
  Future<bool> checkDuplicateLocation(
    LocationMaster location,
    int companyId, {
    Transaction? txn,
  }) async {
    final db = txn ?? await databaseService.database;
    final generatedDescription = _generateLocationDescription(location);

    final idCondition = location.id != null ? 'AND id != ?' : '';
    final whereArgs = location.id != null
        ? [generatedDescription, location.branch, companyId, location.id]
        : [generatedDescription, location.branch, companyId];

    final existing = await db.rawQuery('''
      SELECT COUNT(*) as count FROM location_master 
      WHERE location_description = ? AND branch = ? AND company = ? $idCondition
      ''', whereArgs);

    final count = (existing.first['count'] as int?) ?? 0;
    return count > 0;
  }

  /// Check if location has any item assignments
  Future<bool> hasItemAssignments(int locationId, int companyId) async {
    final db = await databaseService.database;
    final results = await db.rawQuery(
      '''
      SELECT COUNT(*) as count FROM item_location
      WHERE location = ? AND company = ?
      ''',
      [locationId, companyId],
    );

    final count = (results.first['count'] as int?) ?? 0;
    return count > 0;
  }

  /// Check if location has any inventory (quantity on hand)
  Future<bool> hasInventory(int locationId, int companyId) async {
    final db = await databaseService.database;
    final results = await db.rawQuery(
      '''
      SELECT COUNT(*) as count FROM item_location
      WHERE location = ? AND company = ? AND quantity_on_hand > 0
      ''',
      [locationId, companyId],
    );

    final count = (results.first['count'] as int?) ?? 0;
    return count > 0;
  }

  /// Get total inventory value for a location
  Future<double> getLocationInventoryValue(
    int locationId,
    int companyId,
  ) async {
    final db = await databaseService.database;
    final results = await db.rawQuery(
      '''
      SELECT SUM(il.quantity_on_hand * ib.unit_price) as total_value
      FROM item_location il
      JOIN items_in_branch ib ON il.item_number = ib.item_number AND il.branch = ib.branch
      WHERE il.location = ? AND il.company = ?
      ''',
      [locationId, companyId],
    );

    return (results.first['total_value'] as num?)?.toDouble() ?? 0.0;
  }

  // ========== Search and Filter Operations ==========

  /// Search locations by description, branch name, or codes
  Future<List<LocationMaster>> searchLocations(
    String query,
    int companyId,
  ) async {
    final db = await databaseService.database;
    final searchTerm = '%$query%';

    final locations = await db.rawQuery(
      '''
      SELECT lm.*,
             b.description as branch_name
      FROM location_master lm
      LEFT JOIN branch_table b ON lm.branch = b.id
      WHERE lm.company = ? AND (
        lm.location_description LIKE ? OR
        b.description LIKE ? OR
        lm.code_01 LIKE ? OR
        lm.code_02 LIKE ? OR
        lm.code_03 LIKE ? OR
        lm.code_04 LIKE ? OR
        lm.code_05 LIKE ? OR
        lm.code_06 LIKE ? OR
        lm.code_07 LIKE ? OR
        lm.code_08 LIKE ? OR
        lm.code_09 LIKE ? OR
        lm.code_10 LIKE ?
      )
      ORDER BY lm.location_description
      ''',
      [
        companyId,
        searchTerm,
        searchTerm,
        searchTerm,
        searchTerm,
        searchTerm,
        searchTerm,
        searchTerm,
        searchTerm,
        searchTerm,
        searchTerm,
        searchTerm,
      ],
    );

    return locations.map((p) => LocationMaster.fromMap(p)).toList();
  }

  /// Filter locations by branch
  Future<List<LocationMaster>> filterLocationsByBranch(
    int? branchId,
    int companyId,
  ) async {
    if (branchId == null) {
      return getLocationMasters(companyId);
    }

    final db = await databaseService.database;
    final locations = await db.rawQuery(
      '''
      SELECT lm.*,
             b.description as branch_name
      FROM location_master lm
      LEFT JOIN branch_table b ON lm.branch = b.id
      WHERE lm.company = ? AND lm.branch = ?
      ORDER BY lm.location_description
      ''',
      [companyId, branchId],
    );

    return locations.map((p) => LocationMaster.fromMap(p)).toList();
  }

  /// Filter locations by location codes
  Future<List<LocationMaster>> filterLocationsByCodes(
    Map<String, String> codeFilters,
    int companyId,
  ) async {
    final db = await databaseService.database;

    var whereClause = 'WHERE lm.company = ?';
    final whereArgs = <dynamic>[companyId];

    for (final entry in codeFilters.entries) {
      if (entry.value.isNotEmpty) {
        whereClause += ' AND lm.${entry.key} = ?';
        whereArgs.add(entry.value);
      }
    }

    final locations = await db.rawQuery('''
      SELECT lm.*,
             b.description as branch_name
      FROM location_master lm
      LEFT JOIN branch_table b ON lm.branch = b.id
      $whereClause
      ORDER BY lm.location_description
      ''', whereArgs);

    return locations.map((p) => LocationMaster.fromMap(p)).toList();
  }

  // ========== Bulk Operations ==========

  /// Create multiple location masters in batch
  Future<void> createMultipleLocationMasters(
    List<LocationMaster> locations,
    int userId,
    int companyId,
  ) async {
    final db = await databaseService.database;
    final batch = db.batch();

    for (final location in locations) {
      final locationMap = _prepareLocationMap(
        location,
        false,
        userId,
        companyId,
      );
      locationMap.remove('id');
      batch.insert('location_master', locationMap);
    }

    await batch.commit();
  }

  /// Update multiple location masters in batch
  Future<void> updateMultipleLocationMasters(
    List<LocationMaster> locations,
    int userId,
    int companyId,
  ) async {
    final db = await databaseService.database;
    final batch = db.batch();

    for (final location in locations) {
      final locationMap = _prepareLocationMap(
        location,
        true,
        userId,
        companyId,
      );
      batch.update(
        'location_master',
        locationMap,
        where: 'id = ? AND company = ?',
        whereArgs: [location.id, companyId],
      );
    }

    await batch.commit();
  }

  // ========== Statistics and Reporting ==========

  /// Get location usage statistics
  Future<Map<String, dynamic>> getLocationStatistics(int companyId) async {
    final db = await databaseService.database;

    final totalLocations = await db.rawQuery(
      'SELECT COUNT(*) as count FROM location_master WHERE company = ?',
      [companyId],
    );

    final usedLocations = await db.rawQuery(
      'SELECT COUNT(DISTINCT location) as count FROM item_location WHERE company = ?',
      [companyId],
    );

    final itemsPerLocation = await db.rawQuery(
      '''
      SELECT lm.location_description, COUNT(il.item_number) as item_count
      FROM location_master lm
      LEFT JOIN item_location il ON lm.id = il.location AND il.company = ?
      WHERE lm.company = ?
      GROUP BY lm.id, lm.location_description
      ORDER BY item_count DESC
      ''',
      [companyId, companyId],
    );

    return {
      'total_locations': (totalLocations.first['count'] as int?) ?? 0,
      'used_locations': (usedLocations.first['count'] as int?) ?? 0,
      'unused_locations':
          ((totalLocations.first['count'] as int?) ?? 0) -
          ((usedLocations.first['count'] as int?) ?? 0),
      'items_per_location': itemsPerLocation
          .map(
            (row) => {
              'location_description': row['location_description'] as String?,
              'item_count': row['item_count'] as int? ?? 0,
            },
          )
          .toList(),
    };
  }

  /// Get branch-wise location count
  Future<List<Map<String, dynamic>>> getBranchLocationStats(
    int companyId,
  ) async {
    final db = await databaseService.database;

    final stats = await db.rawQuery(
      '''
      SELECT b.id, b.description, COUNT(lm.id) as location_count
      FROM branch_table b
      LEFT JOIN location_master lm ON b.id = lm.branch AND lm.company = ?
      WHERE b.company = ?
      GROUP BY b.id, b.description
      ORDER BY location_count DESC
      ''',
      [companyId, companyId],
    );

    return stats
        .map(
          (row) => {
            'branch_id': row['id'] as int?,
            'branch_description': row['description'] as String?,
            'location_count': row['location_count'] as int? ?? 0,
          },
        )
        .toList();
  }

  // ========== Helper Methods ==========

  /// Prepare location map for database operations
  Map<String, dynamic> _prepareLocationMap(
    LocationMaster location,
    bool isUpdate,
    int userId,
    int companyId,
  ) {
    final locationDescription = _generateLocationDescription(location);

    final map = location.toMap();
    map['location_description'] = locationDescription;
    map['company'] = companyId;

    if (isUpdate) {
      map['updated_by'] = userId;
      map['date_updated'] = DateTime.now().toIso8601String();
    } else {
      map['created_by'] = userId;
      map['date_created'] = DateTime.now().toIso8601String();
      map['updated_by'] = userId;
      map['date_updated'] = DateTime.now().toIso8601String();
    }

    return map;
  }

  /// Generate location description from codes
  String _generateLocationDescription(LocationMaster location) {
    final codes = [
      location.code01,
      location.code02,
      location.code03,
      location.code04,
      location.code05,
      location.code06,
      location.code07,
      location.code08,
      location.code09,
      location.code10,
    ];

    final nonEmptyCodes = codes
        .where((code) => code != null && code.isNotEmpty)
        .toList();
    return nonEmptyCodes.join('-');
  }

  /// Validate location data before save
  List<String> validateLocation(LocationMaster location) {
    final errors = <String>[];

    if (location.branch == null) {
      errors.add('Branch is required');
    }

    if (location.code01 == null || location.code01!.isEmpty) {
      errors.add('Code 01 is required');
    }

    final description = _generateLocationDescription(location);
    if (description.isEmpty) {
      errors.add('At least one location code is required');
    }

    return errors;
  }

  /// Get next available location code suggestion
  Future<String> getNextLocationCodeSuggestion(
    int branchId,
    String codeField,
    int companyId,
  ) async {
    final db = await databaseService.database;

    final existingCodes = await db.rawQuery(
      '''
      SELECT $codeField FROM location_master 
      WHERE branch = ? AND company = ? AND $codeField IS NOT NULL AND $codeField != ''
      ORDER BY $codeField DESC
      LIMIT 1
      ''',
      [branchId, companyId],
    );

    if (existingCodes.isEmpty) {
      return '001';
    }

    final lastCode = existingCodes.first[codeField] as String;
    final lastNumber = int.tryParse(lastCode) ?? 0;
    return (lastNumber + 1).toString().padLeft(3, '0');
  }

  // ========== Advanced Queries ==========

  /// Get locations with item count and inventory value
  Future<List<Map<String, dynamic>>> getLocationsWithDetails(
    int companyId,
  ) async {
    final db = await databaseService.database;

    final locations = await db.rawQuery(
      '''
      SELECT 
        lm.*,
        b.description as branch_name,
        COUNT(DISTINCT il.item_number) as item_count,
        SUM(il.quantity_on_hand) as total_quantity,
        SUM(il.quantity_on_hand * ib.unit_price) as total_value
      FROM location_master lm
      LEFT JOIN branch_table b ON lm.branch = b.id
      LEFT JOIN item_location il ON lm.id = il.location AND il.company = ?
      LEFT JOIN items_in_branch ib ON il.item_number = ib.item_number AND il.branch = ib.branch
      WHERE lm.company = ?
      GROUP BY lm.id, lm.location_description, b.description
      ORDER BY lm.location_description
      ''',
      [companyId, companyId],
    );

    return locations.map((row) {
      return {
        'location': LocationMaster.fromMap(row),
        'branch_name': row['branch_name'] as String?,
        'item_count': row['item_count'] as int? ?? 0,
        'total_quantity': (row['total_quantity'] as num?)?.toDouble() ?? 0.0,
        'total_value': (row['total_value'] as num?)?.toDouble() ?? 0.0,
      };
    }).toList();
  }

  /// Get locations that are not assigned to any item
  Future<List<LocationMaster>> getUnassignedLocations(int companyId) async {
    final db = await databaseService.database;

    final locations = await db.rawQuery(
      '''
      SELECT lm.*, b.description as branch_name
      FROM location_master lm
      LEFT JOIN branch_table b ON lm.branch = b.id
      LEFT JOIN item_location il ON lm.id = il.location AND il.company = ?
      WHERE lm.company = ? AND il.location IS NULL
      ORDER BY lm.location_description
      ''',
      [companyId, companyId],
    );

    return locations.map((p) => LocationMaster.fromMap(p)).toList();
  }

  /// Get locations with low inventory (below threshold)
  Future<List<Map<String, dynamic>>> getLocationsWithLowInventory(
    double threshold,
    int companyId,
  ) async {
    final db = await databaseService.database;

    final locations = await db.rawQuery(
      '''
      SELECT 
        lm.*,
        b.description as branch_name,
        it.item_description,
        il.quantity_on_hand,
        ib.unit_price,
        (il.quantity_on_hand * ib.unit_price) as item_value
      FROM location_master lm
      LEFT JOIN branch_table b ON lm.branch = b.id
      LEFT JOIN item_location il ON lm.id = il.location AND il.company = ?
      LEFT JOIN items_in_branch ib ON il.item_number = ib.item_number AND il.branch = ib.branch
      LEFT JOIN items_table it ON ib.item_number = it.id
      WHERE lm.company = ? AND il.quantity_on_hand < ?
      ORDER BY lm.location_description, it.item_description
      ''',
      [companyId, companyId, threshold],
    );

    return locations.map((row) {
      return {
        'location': LocationMaster.fromMap(row),
        'branch_name': row['branch_name'] as String?,
        'item_description': row['item_description'] as String?,
        'quantity_on_hand':
            (row['quantity_on_hand'] as num?)?.toDouble() ?? 0.0,
        'unit_price': (row['unit_price'] as num?)?.toDouble() ?? 0.0,
        'item_value': (row['item_value'] as num?)?.toDouble() ?? 0.0,
      };
    }).toList();
  }

  // ========== Data Export ==========

  /// Export location data for reporting
  Future<List<Map<String, dynamic>>> exportLocationData(int companyId) async {
    final db = await databaseService.database;

    final data = await db.rawQuery(
      '''
      SELECT 
        lm.id,
        lm.location_description,
        b.description as branch_name,
        lm.code_01,
        lm.code_02,
        lm.code_03,
        lm.code_04,
        lm.code_05,
        lm.code_06,
        lm.code_07,
        lm.code_08,
        lm.code_09,
        lm.code_10,
        lm.date_created,
        lm.date_updated,
        COUNT(DISTINCT il.item_number) as total_items,
        SUM(il.quantity_on_hand) as total_quantity,
        SUM(il.quantity_on_hand * ib.unit_price) as total_value
      FROM location_master lm
      LEFT JOIN branch_table b ON lm.branch = b.id
      LEFT JOIN item_location il ON lm.id = il.location AND il.company = ?
      LEFT JOIN items_in_branch ib ON il.item_number = ib.item_number AND il.branch = ib.branch
      WHERE lm.company = ?
      GROUP BY 
        lm.id, lm.location_description, b.description, 
        lm.code_01, lm.code_02, lm.code_03, lm.code_04, lm.code_05,
        lm.code_06, lm.code_07, lm.code_08, lm.code_09, lm.code_10,
        lm.date_created, lm.date_updated
      ORDER BY lm.location_description
      ''',
      [companyId, companyId],
    );

    return data.map((row) => Map<String, dynamic>.from(row)).toList();
  }
}
