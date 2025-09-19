import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as httpClient;
import 'package:savvy_stock/core/constants/api_constants.dart';
import 'package:savvy_stock/core/models/system_constant.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:sqflite/sqflite.dart';

import '../errors/exceptions.dart';

class SystemConstantRepository {
  final LocalDatabaseService localDatabaseService;
  final String baseUrl;

  SystemConstantRepository({
    this.baseUrl = ApiConstants.baseUrl,
    required this.localDatabaseService,
  });

  // Get system constants with offline-first approach
  Future<List<SystemConstant>> getSystemConstants() async {
    try {
      // First try to get from API
      final remoteConstants = await _getRemoteSystemConstants();

      // Save to local database
      await _saveSystemConstantsToLocal(remoteConstants);

      return remoteConstants;
    } on NetworkException catch (e) {
      // If API fails, try to get from local database

      try {
        final localConstants = await _getLocalSystemConstants();
        if (localConstants.isNotEmpty) {
          return localConstants;
        }
        throw e; // Re-throw if no local data
      } catch (dbError) {
        throw NetworkException('Failed to fetch system constants: $dbError');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get system constant by ID with offline-first approach
  Future<SystemConstant> getSystemConstant(int id) async {
    try {
      // First try to get from API
      final remoteConstant = await _getRemoteSystemConstant(id);

      // Save to local database
      await _saveSystemConstantToLocal(remoteConstant);

      return remoteConstant;
    } on NetworkException catch (e) {
      // If API fails, try to get from local database
      try {
        final localConstant = await _getLocalSystemConstant(id);
        if (localConstant != null) {
          return localConstant;
        }
        throw e; // Re-throw if no local data
      } catch (dbError) {
        throw NetworkException('Failed to fetch system constant: $dbError');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get system constants for current company
  Future<SystemConstant> getCurrentCompanySystemConstants() async {
    try {
      // First try to get from API
      final remoteConstants = await _getRemoteSystemConstants();
      final companyConstants = remoteConstants
          .where((sc) => sc.company != null)
          .toList();

      if (companyConstants.isNotEmpty) {
        // Save to local database
        await _saveSystemConstantsToLocal(companyConstants);
        return companyConstants.first;
      }

      // If no company-specific constants, try to get default ones
      final defaultConstants = remoteConstants
          .where((sc) => sc.company == null)
          .toList();
      if (defaultConstants.isNotEmpty) {
        await _saveSystemConstantsToLocal(defaultConstants);
        return defaultConstants.first;
      }

      throw const NetworkException('No system constants found');
    } on NetworkException catch (e) {
      // If API fails, try to get from local database
      try {
        final localConstants = await _getLocalSystemConstants();
        final companyConstants = localConstants
            .where((sc) => sc.company != null)
            .toList();

        if (companyConstants.isNotEmpty) {
          return companyConstants.first;
        }

        final defaultConstants = localConstants
            .where((sc) => sc.company == null)
            .toList();
        if (defaultConstants.isNotEmpty) {
          return defaultConstants.first;
        }

        throw e; // Re-throw if no local data
      } catch (dbError) {
        throw NetworkException('Failed to fetch system constants: $dbError');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Local database operations
  Future<List<SystemConstant>> _getLocalSystemConstants() async {
    final db = await localDatabaseService.database;
    final List<Map<String, dynamic>> maps = await db.query('system_constant');
    return maps.map((map) => SystemConstant.fromDatabaseMap(map)).toList();
  }

  Future<SystemConstant?> _getLocalSystemConstant(int id) async {
    final db = await localDatabaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'system_constant',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return SystemConstant.fromDatabaseMap(maps.first);
    }
    return null;
  }

  Future<SystemConstant> _getLocalCompanySystemConstants() async {
    final db = await localDatabaseService.database;
    try {
      // Try to get company-specific constants first
      final companyMaps = await db.query(
        'system_constant',
        where: 'company IS NOT NULL',
      );

      if (companyMaps.isNotEmpty) {
        developer.log('Found company system constants in local database');
        return SystemConstant.fromDatabaseMap(companyMaps.first);
      }

      // Fallback to default constants
      final defaultMaps = await db.query(
        'system_constant',
        where: 'company IS NULL',
      );

      if (defaultMaps.isNotEmpty) {
        developer.log('Found default system constants in local database');
        return SystemConstant.fromDatabaseMap(defaultMaps.first);
      }

      // If no constants found, create a default one
      developer.log('No system constants found, creating default');
      final defaultConstant = SystemConstant(
        applyLotMgm: 'N',
        applyLocationMgm: 'Y',
        decimalPlaces: 2,
        generateBarcodeForItem: 'N',
        rateVatPercentage: 15.0,
        rateWithPercentage: 2.0,
        withHoldInitials: 1000.0,
        autoSalesPrice: 'N',
        lotQtyAutoForSales: 'Y',
        locationCategoryLevel: 1,
        isSynced: false,
      );

      final id = await insertLocalSystemConstant(defaultConstant);
      return defaultConstant.copyWith(id: id);
    } catch (e) {
      developer.log('Error getting local company system constants: $e');
      // Return a hardcoded default as last resort
      return SystemConstant(
        applyLotMgm: 'N',
        applyLocationMgm: 'Y',
        decimalPlaces: 2,
        generateBarcodeForItem: 'N',
        rateVatPercentage: 15.0,
        rateWithPercentage: 2.0,
        withHoldInitials: 1000.0,
        autoSalesPrice: 'N',
        lotQtyAutoForSales: 'Y',
        locationCategoryLevel: 1,
        isSynced: false,
      );
    }
  }

  Future<int> insertLocalSystemConstant(SystemConstant systemConstant) async {
    final db = await localDatabaseService.database;
    try {
      return await db.insert(
        'system_constant',
        systemConstant.toDatabaseMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      developer.log('Error inserting local system constant: $e');
      rethrow;
    }
  }

  Future<int> _updateLocalSystemConstant(SystemConstant systemConstant) async {
    final db = await localDatabaseService.database;
    try {
      return await db.update(
        'system_constant',
        systemConstant.toDatabaseMap(),
        where: 'id = ?',
        whereArgs: [systemConstant.id],
      );
    } catch (e) {
      developer.log('Error updating local system constant: $e');
      rethrow;
    }
  }

  Future<int> _deleteLocalSystemConstant(int id) async {
    final db = await localDatabaseService.database;
    try {
      return await db.delete(
        'system_constant',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      developer.log('Error deleting local system constant: $e');
      rethrow;
    }
  }

  // Remote API operations
  Future<List<SystemConstant>> _getRemoteSystemConstants() async {
    try {
      final response = await httpClient
          .get(
            Uri.parse('$baseUrl/system-constants'),
            headers: await _getAuthHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        developer.log(
          'Loaded system constants from API: ${data.length} constants',
        );
        return data.map((json) => SystemConstant.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        return []; // No system constants found
      } else {
        throw ServerException(
          'Failed to load system constants: ${response.statusCode}',
          response.statusCode,
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw NetworkException('Network error: $e');
    }
  }

  Future<SystemConstant> _getRemoteSystemConstant(int id) async {
    try {
      final response = await httpClient
          .get(
            Uri.parse('$baseUrl/system-constants/$id'),
            headers: await _getAuthHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return SystemConstant.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        throw NotFoundException('System constant not found');
      } else {
        throw ServerException(
          'Failed to load system constant: ${response.statusCode}',
          response.statusCode,
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw NetworkException('Network error: $e');
    }
  }

  Future<void> createSystemConstant(SystemConstant systemConstant) async {
    try {
      // First try to create via API
      final response = await httpClient
          .post(
            Uri.parse('$baseUrl/system-constants'),
            headers: await _getAuthHeaders(),
            body: json.encode(systemConstant.toJson()),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 201) {
        final createdConstant = SystemConstant.fromJson(
          json.decode(response.body),
        );
        // Save to local database
        await insertLocalSystemConstant(createdConstant);
      } else {
        throw ServerException(
          'Failed to create system constant: ${response.statusCode}',
          response.statusCode,
        );
      }
    } on NetworkException catch (e) {
      // If API fails, save to local database and mark as not synced
      await insertLocalSystemConstant(
        systemConstant.copyWith(isSynced: false, lastSyncTime: null),
      );
      throw NetworkException('Created locally (will sync later): ${e.message}');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateSystemConstant(SystemConstant systemConstant) async {
    try {
      // First try to update via API
      final response = await httpClient
          .put(
            Uri.parse('$baseUrl/system-constants/${systemConstant.id}'),
            headers: await _getAuthHeaders(),
            body: json.encode(systemConstant.toJson()),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final updatedConstant = SystemConstant.fromJson(
          json.decode(response.body),
        );
        // Update local database
        await _updateLocalSystemConstant(
          updatedConstant.copyWith(isSynced: true),
        );
      } else {
        throw ServerException(
          'Failed to update system constant: ${response.statusCode}',
          response.statusCode,
        );
      }
    } on NetworkException catch (e) {
      // If API fails, update local database and mark as not synced
      await _updateLocalSystemConstant(
        systemConstant.copyWith(isSynced: false, lastSyncTime: null),
      );
      throw NetworkException('Updated locally (will sync later): ${e.message}');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteSystemConstant(int id) async {
    try {
      // First try to delete via API
      final response = await httpClient
          .delete(
            Uri.parse('$baseUrl/system-constants/$id'),
            headers: await _getAuthHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 204) {
        // Delete from local database
        await _deleteLocalSystemConstant(id);
      } else {
        throw ServerException(
          'Failed to delete system constant: ${response.statusCode}',
          response.statusCode,
        );
      }
    } on NetworkException catch (e) {
      // If API fails, mark for deletion in local database
      await _addToSyncQueue('system_constant', id, 'delete', null);
      throw NetworkException(
        'Marked for deletion (will sync later): ${e.message}',
      );
    } catch (e) {
      rethrow;
    }
  }

  // Helper methods
  Future<void> _saveSystemConstantsToLocal(
    List<SystemConstant> constants,
  ) async {
    final db = await localDatabaseService.database;
    final batch = db.batch();

    for (final constant in constants) {
      batch.insert(
        'system_constant',
        constant.copyWith(isSynced: true).toDatabaseMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit();
    developer.log(
      'Saved system constants to local database: ${constants.length} constants',
    );
  }

  Future<void> _saveSystemConstantToLocal(SystemConstant constant) async {
    await insertLocalSystemConstant(constant.copyWith(isSynced: true));
    developer.log(
      'Saved system constant to local database: ${constant.id} constant',
    );
  }

  Future<void> _addToSyncQueue(
    String tableName,
    int? recordId,
    String operation,
    Map<String, dynamic>? data,
  ) async {
    final db = await localDatabaseService.database;
    await db.insert('sync_queue', {
      'table_name': tableName,
      'record_id': recordId,
      'operation': operation,
      'data': data != null ? json.encode(data) : null,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    // Implement your auth token retrieval
    final token = await _getAuthToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<void> pullLatestSystemConstants() async {
    try {
      final remoteSystemConstants = await getSystemConstants();
      final db = await localDatabaseService.database;

      for (final remoteConstant in remoteSystemConstants) {
        // Check if exists locally
        final existing = await getSystemConstant(remoteConstant.id!);

        if (existing == null) {
          // Insert new record
          await db.insert(
            'system_constant',
            remoteConstant.copyWith(isSynced: true).toDatabaseMap(),
          );
        } else if (existing.lastSyncTime == null ||
            remoteConstant.lastSyncTime != null &&
                remoteConstant.lastSyncTime!.isAfter(existing.lastSyncTime!)) {
          // Update existing record if remote is newer
          await db.update(
            'system_constant',
            remoteConstant.copyWith(isSynced: true).toDatabaseMap(),
            where: 'id = ?',
            whereArgs: [remoteConstant.id],
          );
        }
      }
    } catch (e) {
      print('Failed to pull latest system constants: $e');
    }
  }

  // Sync operations
  Future<void> syncSystemConstants() async {
    final db = await localDatabaseService.database;

    // Get unsynced changes
    final List<Map<String, dynamic>> unsyncedItems = await db.query(
      'system_constant',
      where: 'is_synced = ?',
      whereArgs: [0],
    );
    developer.log('Found ${unsyncedItems.length} unsynced system constants');

    for (final item in unsyncedItems) {
      final systemConstant = SystemConstant.fromDatabaseMap(item);

      try {
        if (systemConstant.id == null) {
          // Create new record
          await createSystemConstant(systemConstant);
        } else {
          // Update existing record
          await updateSystemConstant(systemConstant);
        }

        // Mark as synced
        await db.update(
          'system_constant',
          {
            'is_synced': 1,
            'last_sync_time': DateTime.now().millisecondsSinceEpoch,
          },
          where: 'id = ?',
          whereArgs: [systemConstant.id],
        );
      } catch (e) {
        // Log error but continue with other items
        print('Failed to sync system constant ${systemConstant.id}: $e');
      }
    }
    // Process sync queue (for deleted items)
    final List<Map<String, dynamic>> syncQueue = await db.query(
      'sync_queue',
      where: 'table_name = ?',
      whereArgs: ['system_constant'],
    );
    developer.log('Found ${syncQueue.length} items in sync queue');
    for (final queueItem in syncQueue) {
      try {
        if (queueItem['operation'] == 'delete') {
          await deleteSystemConstant(queueItem['record_id']);
        }
        // Remove from sync queue
        await db.delete(
          'sync_queue',
          where: 'id = ?',
          whereArgs: [queueItem['id']],
        );
      } catch (e) {
        // Update attempt count
        await db.update(
          'sync_queue',
          {
            'attempts': (queueItem['attempts'] ?? 0) + 1,
            'last_attempt': DateTime.now().millisecondsSinceEpoch,
          },
          where: 'id = ?',
          whereArgs: [queueItem['id']],
        );
      }
    }
  }

  Future<String> _getAuthToken() async {
    // Implement your auth token retrieval logic
    return 'your-auth-token';
  }
}
