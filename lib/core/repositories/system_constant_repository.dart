import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:sqflite/sqflite.dart';

import '../models/system_constant.dart';
import '../constants/api_constants.dart';

class SystemConstantRepository {
  final String baseUrl;
  final LocalDatabaseService localDatabaseService;

  SystemConstantRepository({
    this.baseUrl = ApiConstants.baseUrl,
    required this.localDatabaseService,
  });

  // Local database operations
  Future<List<SystemConstant>> getLocalSystemConstants() async {
    final db = await localDatabaseService.database;
    final List<Map<String, dynamic>> maps = await db.query('system_constants');
    return maps.map((map) => SystemConstant.fromDatabaseMap(map)).toList();
  }

  Future<SystemConstant?> getLocalSystemConstant(int id) async {
    final db = await localDatabaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'system_constants',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return SystemConstant.fromDatabaseMap(maps.first);
    }
    return null;
  }

  Future<int> insertLocalSystemConstant(SystemConstant systemConstant) async {
    final db = await localDatabaseService.database;
    final id = await db.insert(
      'system_constants',
      systemConstant.copyWith(isSynced: false).toDatabaseMap(),
    );

    // Add to sync queue
    await _addToSyncQueue(
      'system_constants',
      id,
      'create',
      systemConstant.toJson(),
    );

    return id;
  }

  Future<int> updateLocalSystemConstant(SystemConstant systemConstant) async {
    final db = await localDatabaseService.database;
    final count = await db.update(
      'system_constants',
      systemConstant.copyWith(isSynced: false).toDatabaseMap(),
      where: 'id = ?',
      whereArgs: [systemConstant.id],
    );

    // Add to sync queue
    if (count > 0) {
      await _addToSyncQueue(
        'system_constants',
        systemConstant.id,
        'update',
        systemConstant.toJson(),
      );
    }

    return count;
  }

  Future<int> deleteLocalSystemConstant(int id) async {
    final db = await localDatabaseService.database;
    final count = await db.delete(
      'system_constants',
      where: 'id = ?',
      whereArgs: [id],
    );

    // Add to sync queue
    if (count > 0) {
      await _addToSyncQueue('system_constants', id, 'delete', null);
    }

    return count;
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
    });
  }

  // Remote API operations
  Future<List<SystemConstant>> getRemoteSystemConstants() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/system-constants'),
            headers: {'Authorization': 'Bearer ${await _getAuthToken()}'},
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => SystemConstant.fromJson(json)).toList();
      } else {
        throw Exception(
          'Failed to load system constants: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<SystemConstant> getRemoteSystemConstant(int id) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/system-constants/$id'),
            headers: {'Authorization': 'Bearer ${await _getAuthToken()}'},
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return SystemConstant.fromJson(json.decode(response.body));
      } else {
        throw Exception(
          'Failed to load system constant: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> createRemoteSystemConstant(SystemConstant systemConstant) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/system-constants'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${await _getAuthToken()}',
            },
            body: json.encode(systemConstant.toJson()),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 201) {
        throw Exception(
          'Failed to create system constant: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> updateRemoteSystemConstant(SystemConstant systemConstant) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl/system-constants/${systemConstant.id}'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${await _getAuthToken()}',
            },
            body: json.encode(systemConstant.toJson()),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to update system constant: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> deleteRemoteSystemConstant(int id) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl/system-constants/$id'),
            headers: {'Authorization': 'Bearer ${await _getAuthToken()}'},
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 204) {
        throw Exception(
          'Failed to delete system constant: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Sync operations
  Future<void> syncSystemConstants() async {
    final db = await localDatabaseService.database;

    // Get unsynced changes
    final List<Map<String, dynamic>> unsyncedItems = await db.query(
      'system_constants',
      where: 'is_synced = ?',
      whereArgs: [0],
    );

    for (final item in unsyncedItems) {
      final systemConstant = SystemConstant.fromDatabaseMap(item);

      try {
        if (systemConstant.id == null) {
          // Create new record
          await createRemoteSystemConstant(systemConstant);
        } else {
          // Update existing record
          await updateRemoteSystemConstant(systemConstant);
        }

        // Mark as synced
        await db.update(
          'system_constants',
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
      whereArgs: ['system_constants'],
    );

    for (final queueItem in syncQueue) {
      try {
        if (queueItem['operation'] == 'delete') {
          await deleteRemoteSystemConstant(queueItem['record_id']);
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

  Future<void> pullLatestSystemConstants() async {
    try {
      final remoteSystemConstants = await getRemoteSystemConstants();
      final db = await localDatabaseService.database;

      for (final remoteConstant in remoteSystemConstants) {
        // Check if exists locally
        final existing = await getLocalSystemConstant(remoteConstant.id!);

        if (existing == null) {
          // Insert new record
          await db.insert(
            'system_constants',
            remoteConstant.copyWith(isSynced: true).toDatabaseMap(),
          );
        } else if (existing.lastSyncTime == null ||
            remoteConstant.lastSyncTime != null &&
                remoteConstant.lastSyncTime!.isAfter(existing.lastSyncTime!)) {
          // Update existing record if remote is newer
          await db.update(
            'system_constants',
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

  Future<String> _getAuthToken() async {
    // Implement your auth token retrieval logic here
    // This should return the current user's authentication token
    return 'your-auth-token';
  }
}
