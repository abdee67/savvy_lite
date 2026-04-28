import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:savvy_stock/core/constants/api_constants.dart';
import 'package:savvy_stock/core/repositories/base_repo.dart';
import 'package:savvy_stock/core/repositories/udc_repository.dart';
import 'package:savvy_stock/features/system_constant/models/system_constant.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/errors/exceptions.dart';

class SystemConstantRepository extends BaseRepository {
  @override
  final LocalDatabaseService databaseService;
  final String baseUrl;
  // final AuthService authService;
  final http.Client httpClient;
  final AuthBloc authBloc;
  final UdcRepository udcRepository;

  SystemConstantRepository({
    this.baseUrl = ApiConstants.baseUrl,
    required this.databaseService,
    required this.authBloc,
    required this.httpClient,
    required this.udcRepository,
  }) : localDatabaseService = databaseService;

  final LocalDatabaseService localDatabaseService;

  // Get system constant by ID with offline-first approach
  Future<SystemConstant> getSystemConstant(int id) async {
    try {
      final localConstant = await _getLocalSystemConstant(id);
      if (localConstant != null) {
        developer.log('Successfully retrieved system constant from database');
        return localConstant;
      }
      throw NetworkException('Failed to fetch system constant');
    } catch (e) {
      throw NetworkException('Failed to fetch system constant: $e');
    }
  }

  // In your SystemConstantRepository, add debug output:
  Future<SystemConstant> getCurrentCompanySystemConstants() async {
    developer.log('Loading current company system constants from database...');

    try {
      final db = await databaseService.database;
      final companyId = authBloc.state.companyId;

      // Try to get company-specific constants first
      final companyMaps = await db.query(
        'system_constant',
        where: 'company = ?',
        whereArgs: [companyId],
      );

      developer.log('Found ${companyMaps.length} company-specific constants');

      if (companyMaps.isNotEmpty) {
        final constant = SystemConstant.fromDatabaseMap(companyMaps.first);
        //  developer.log('Using company constant: ${constant.toJson()}');
        return constant;
      }

      // Fallback to default constants
      final defaultMaps = await db.query(
        'system_constant',
        where:
            'company IS NULL OR company = 1', // Checking default company 1 as inserted by DB service
      );

      developer.log('Found ${defaultMaps.length} default constants');

      if (defaultMaps.isNotEmpty) {
        final constant = SystemConstant.fromDatabaseMap(defaultMaps.first);
        developer.log('Using default constant: ${constant.toJson()}');
        return constant;
      }

      // If no constants found, throwing logic or return empty/default empty object?
      // Since DB service inserts it, this should rarely happen unless DB is fresh and not migrated properly
      throw Exception(
        "System Constants not found and default creation is handled by DatabaseService.",
      );
    } catch (e) {
      developer.log('Error loading system constants: $e');
      rethrow;
    }
  }

  Future<List<SystemConstant>> getSystemConstants() async {
    final db = await databaseService.database;
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
    final db = await databaseService.database;
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

  Future<int> insertLocalSystemConstant(SystemConstant systemConstant) async {
    final db = await databaseService.database;
    try {
      return await db.transaction((txn) async {
        final map = systemConstant.toDatabaseMap();
        map.remove('id');
        final mapWithSyncKey = withSyncKey(map);
        final id = await txn.insert(
          'system_constant',
          mapWithSyncKey,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        mapWithSyncKey['id'] = id;
        await captureSync(
          tableName: 'system_constant',
          entityMap: mapWithSyncKey,
          entityId: id.toString(),
          operation: 'INSERT',
          company: systemConstant.company?.toString(),
          txn: txn,
        );
        developer.log('Inserted system constant with ID: $id');
        return id;
      });
    } catch (e) {
      developer.log('Error inserting system constant: $e');
      rethrow;
    }
  }

  Future<int> _updateLocalSystemConstant(SystemConstant systemConstant) async {
    final db = await databaseService.database;
    try {
      return await db.transaction((txn) async {
        // Fetch existing sync_key before updating
        final existingRows = await txn.query(
          'system_constant',
          columns: ['sync_key'],
          where: 'id = ?',
          whereArgs: [systemConstant.id],
        );
        final syncKey = existingRows.isNotEmpty
            ? existingRows.first['sync_key']
            : null;

        final map = systemConstant.toDatabaseMap();

        final count = await txn.update(
          'system_constant',
          map,
          where: 'id = ?',
          whereArgs: [systemConstant.id],
        );
        developer.log('Updated $count system constant(s)');

        if (syncKey != null) {
          map['sync_key'] = syncKey;
        }

        await captureSync(
          tableName: 'system_constant',
          entityMap: map,
          entityId: systemConstant.id.toString(),
          operation: 'UPDATE',
          company: systemConstant.company?.toString(),
          txn: txn,
        );
        return count;
      });
    } catch (e) {
      developer.log('Error updating system constant: $e');
      rethrow;
    }
  }

  Future<int> _deleteLocalSystemConstant(int id) async {
    final db = await databaseService.database;
    try {
      return await db.transaction((txn) async {
        // Fetch full row data BEFORE deleting
        final constantRows = await txn.query(
          'system_constant',
          where: 'id = ?',
          whereArgs: [id],
        );
        final count = await txn.delete(
          'system_constant',
          where: 'id = ?',
          whereArgs: [id],
        );
        for (final row in constantRows) {
          await captureSync(
            tableName: 'system_constant',
            entityMap: row,
            entityId: row['id'].toString(),
            operation: 'DELETE',
            txn: txn,
          );
        }
        return count;
      });
    } catch (e) {
      developer.log('Error deleting local system constant: $e');
      rethrow;
    }
  }

  // Create system constant (offline-first)
  Future<void> createSystemConstant(SystemConstant systemConstant) async {
    final companyId = authBloc.state.companyId;
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
      await insertLocalSystemConstant(systemConstant.copyWith(isSynced: false));
    } catch (e) {
      developer.log('Error saving system constant: $e');
      rethrow;
    }
  }

  // Update system constant (offline-first)
  Future<void> updateSystemConstant(SystemConstant systemConstant) async {
    try {
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
      // Delete from local database
      await _deleteLocalSystemConstant(id);
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
      final mapWithSyncKey = withSyncKey(
        constant.copyWith(isSynced: true).toDatabaseMap(),
      );
      batch.insert(
        'system_constant',
        mapWithSyncKey,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await captureSync(
        tableName: 'system_constant',
        entityMap: mapWithSyncKey,
        entityId: constant.id.toString(),
        operation: 'INSERT',
        company: constant.company?.toString(),
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
