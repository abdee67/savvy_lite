import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as httpClient;
import 'package:http/http.dart' as http;
import 'package:savvy_stock/core/constants/api_constants.dart';
import 'package:savvy_stock/core/models/system_constant.dart';
import 'package:savvy_stock/core/services/auth/auth_service.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:sqflite/sqflite.dart';

import '../errors/exceptions.dart';

class SystemConstantRepository {
  final LocalDatabaseService localDatabaseService;
  final String baseUrl;
  final AuthService authService;
  final http.Client httpClient;

  SystemConstantRepository({
    this.baseUrl = ApiConstants.baseUrl,
    required this.localDatabaseService,
    required this.authService,
    required this.httpClient,
  });

  // Offline-first: Try API first, fallback to local database
  Future<List<SystemConstant>> getSystemConstants() async {
    try {
      // First try to get from API
      developer.log(
        'Attemptinggggggggggggg to fetch system constants from API...',
      );
      final remoteConstants = await _getRemoteSystemConstants();

      // Save to local database
      await _saveSystemConstantsToLocal(remoteConstants);

      developer.log(
        'Successfully retrieved ${remoteConstants.length} system constants from API',
      );
      return remoteConstants;
    } catch (e) {
      // If API fails, try to get from local database
      developer.log('API failed, falling back to local database: $e');
      return await getLocalSystemConstants();
    }
  }

  // Get system constant by ID with offline-first approach
  Future<SystemConstant> getSystemConstant(int id) async {
    try {
      // First try to get from API
      developer.log('Attempting to fetch system constant from API...');
      final remoteConstant = await _getRemoteSystemConstant(id);

      // Save to local database
      await _saveSystemConstantToLocal(remoteConstant);
      developer.log('Successfully retrieved system constant from API');
      return remoteConstant;
    } on NetworkException catch (e) {
      // If API fails, try to get from local database
      try {
        final localConstant = await _getLocalSystemConstant(id);
        if (localConstant != null) {
          developer.log(
            'Successfully retrieved system constant from local database',
          );
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

  // In your SystemConstantRepository, add debug output:
  Future<SystemConstant> getCurrentCompanySystemConstants() async {
    developer.log('Loading current company system constants from database...');

    try {
      final db = await localDatabaseService.database;
      final companyId = authService.currentCompany?.id;

      // Try to get company-specific constants first
      final companyMaps = await db.query(
        'system_constant',
        where: 'company = ?',
        whereArgs: [companyId],
      );

      developer.log('Found ${companyMaps.length} company-specific constants');

      if (companyMaps.isNotEmpty) {
        final constant = SystemConstant.fromDatabaseMap(companyMaps.first);
        developer.log('Using company constant: ${constant.toJson()}');
        return constant;
      }

      // Fallback to default constants
      final defaultMaps = await db.query(
        'system_constant',
        where: 'company IS NULL',
      );

      developer.log('Found ${defaultMaps.length} default constants');

      if (defaultMaps.isNotEmpty) {
        final constant = SystemConstant.fromDatabaseMap(defaultMaps.first);
        developer.log('Using default constant: ${constant.toJson()}');
        return constant;
      }

      // If no constants found, create a default one
      developer.log('No constants found, creating default');
      return _createDefaultSystemConstant(companyId);
    } catch (e) {
      developer.log('Error loading system constants: $e');
      rethrow;
    }
  }

  SystemConstant _createDefaultSystemConstant(int? companyId) {
    developer.log('Creating default system constants for company: $companyId');

    return SystemConstant(
      applyLotMgm: 'N',
      applyLocationMgm: 'Y',
      decimalPlaces: 2,
      generateBarcodeForItem: 'N',
      company: companyId,
      rateVatPercentage: 15.0,
      rateWithholdingPercentage: 2.0,
      withHoldInitials: 1000.0,
      autoSalesPrice: 'N',
      lotQtyAutoForSales: 'Y',
      locationCategoryLevel: 1,
      isSynced: false, // Mark as not synced since it's local
    );
  }

  // Local database operations
  // Local database operations
  Future<List<SystemConstant>> getLocalSystemConstants() async {
    final db = await localDatabaseService.database;
    try {
      final List<Map<String, dynamic>> maps = await db.query('system_constant');
      developer.log('Found ${maps.length} system constants in local database');
      return maps.map((map) => SystemConstant.fromDatabaseMap(map)).toList();
    } catch (e) {
      developer.log('Error getting local system constants: $e');
      return [];
    }
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
    final companyId = authService.currentCompany?.id;

    try {
      // Try to get company-specific constants first
      final companyMaps = await db.query(
        'system_constant',
        where: 'company = ?',
        whereArgs: [companyId],
      );

      if (companyMaps.isNotEmpty) {
        developer.log('Found company system constants in local database');
        return SystemConstant.fromDatabaseMap(companyMaps.first);
      }

      // Fallback to default constants (company = null)
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
      return _createDefaultSystemConstant(companyId);
    } catch (e) {
      developer.log('Error getting local company system constants: $e');
      // Return a hardcoded default as last resort
      return _createDefaultSystemConstant(companyId);
    }
  }

  Future<int> insertLocalSystemConstant(SystemConstant systemConstant) async {
    final db = await localDatabaseService.database;
    try {
      final id = await db.insert(
        'system_constant',
        systemConstant.toDatabaseMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      developer.log('Inserted system constant with ID: $id');
      return id;
    } catch (e) {
      developer.log('Error inserting system constant: $e');
      rethrow;
    }
  }

  Future<int> _updateLocalSystemConstant(SystemConstant systemConstant) async {
    final db = await localDatabaseService.database;
    try {
      final count = await db.update(
        'system_constant',
        systemConstant.toDatabaseMap(),
        where: 'id = ?',
        whereArgs: [systemConstant.id],
      );
      developer.log('Updated $count system constant(s)');
      return count;
    } catch (e) {
      developer.log('Error updating system constant: $e');
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

  // Remote API operations - Modified to handle offline scenarios gracefully
  Future<List<SystemConstant>> _getRemoteSystemConstants() async {
    // For testing, we'll simulate API failure to force offline mode
    developer.log('Simulating API failure for testing purposes');
    throw NetworkException('API not available in testing mode');

    // If you want to actually try the API, use this code instead:
    /*
    try {
      final response = await httpClient.get(
        Uri.parse('$baseUrl/system-constants'),
        headers: await _getAuthHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        developer.log('Retrieved ${data.length} system constants from API');
        return data.map((json) => SystemConstant.fromJson(json)).toList();
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
    */
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

  // Create system constant (offline-first)
  Future<void> createSystemConstant(SystemConstant systemConstant) async {
    final db = await localDatabaseService.database;
    final companyId = authService.currentCompany?.id;
    try {
      if (companyId != null) {
        final existingSystemConstant = await getSystemConstantByCompany(
          companyId,
        );
        if (existingSystemConstant != null) {
          developer.log(
            'System constant already exists for company $companyId',
          );
          await updateSystemConstant(
            systemConstant.copyWith(
              id: existingSystemConstant.id,
              isSynced: false,
            ),
          );
          return;
        }
      }
      // For testing, we'll skip API and go directly to local database
      developer.log('Bypassing API - saving directly to local database');
      await insertLocalSystemConstant(systemConstant.copyWith(isSynced: false));
    } catch (e) {
      developer.log('Error saving system constant: $e');
      rethrow;
    }
  }

  // Update system constant (offline-first)
  Future<void> updateSystemConstant(SystemConstant systemConstant) async {
    try {
      // For testing, we'll skip API and go directly to local database
      developer.log('Bypassing API - updating directly in local database');
      await _updateLocalSystemConstant(
        systemConstant.copyWith(isSynced: false),
      );
    } catch (e) {
      developer.log('Error updating system constant: $e');
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
      'Saved ${constants.length} system constants to local database',
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

  // Sync operations - Modified for testing
  Future<void> syncSystemConstants() async {
    developer.log('Sync called - but bypassing for testing');
    // For testing, we won't actually try to sync since there's no API
    return;

    /*
    // Actual sync implementation would go here
    final db = await localDatabaseService.database;
    
    try {
      // Get unsynced changes
      final unsyncedItems = await db.query(
        'system_constant',
        where: 'is_synced = ?',
        whereArgs: [0],
      );
      
      developer.log('Found ${unsyncedItems.length} unsynced system constants');
      
      for (final item in unsyncedItems) {
        final systemConstant = SystemConstant.fromDatabaseMap(item);
        
        try {
          if (systemConstant.id == null) {
            await createSystemConstant(systemConstant);
          } else {
            await updateSystemConstant(systemConstant);
          }
        } catch (e) {
          developer.log('Failed to sync system constant ${systemConstant.id}: $e');
        }
      }
    } catch (e) {
      developer.log('Error during system constants sync: $e');
    }
    */
  }

  Future<String> _getAuthToken() async {
    // Implement your auth token retrieval logic
    return 'your-auth-token';
  }

  //check if a system constant exists for a company
  Future<SystemConstant?> getSystemConstantByCompany(int companyId) async {
    final db = await localDatabaseService.database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'system_constant',
        where: 'company = ?',
        whereArgs: [companyId],
        orderBy: 'id DESC',
        limit: 1,
      );

      if (maps.isNotEmpty) {
        developer.log('System constant found for company $companyId');
        return SystemConstant.fromDatabaseMap(maps.first);
      }
      developer.log('System constant not found for company $companyId');
      return null;
    } catch (e) {
      developer.log('Error getting system constant by company: $e');
      return null;
    }
  }

  Future<void> debugSystemConstants() async {
    final db = await localDatabaseService.database;
    try {
      final constants = await db.query('system_constant');
      developer.log('=== SYSTEM CONSTANTS IN DATABASE ===');
      for (final constant in constants) {
        developer.log(
          'ID: ${constant['id']}, Company: ${constant['company']}, '
          'VAT: ${constant['rate_vat_percentage']}, Withholding: ${constant['rate_with_percentage']}',
        );
      }
      developer.log('Total: ${constants.length} system constants');
      developer.log('=====================================');
    } catch (e) {
      developer.log('Error debugging system constants: $e');
    }
  }
}
