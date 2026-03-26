// core/repositories/base_repository.dart
import 'dart:developer' as developer;

import 'package:get_it/get_it.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/core/services/sync/sync_service.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

abstract class BaseRepository {
  Future<dynamic> getDatabaseExecutor({Transaction? txn}) async {
    return txn ?? await databaseService.database;
  }

  // This should be implemented by each repository
  LocalDatabaseService get databaseService;

  /// Helper to auto-inject a unique sync_key (UUID) into a payload before inserting.
  Map<String, dynamic> withSyncKey(Map<String, dynamic> data) {
    final map = Map<String, dynamic>.from(data);
    if (!map.containsKey('sync_key') || map['sync_key'] == null) {
      map['sync_key'] = const Uuid().v4();
    }
    return map;
  }

  /// Lazily resolved SyncService from the DI container.
  /// All repositories that extend BaseRepository get sync for free.
  SyncService? get syncService {
    try {
      return GetIt.instance<SyncService>();
    } catch (_) {
      return null;
    }
  }

  /// Capture a CRUD operation for syncing to the server.
  ///
  /// Call this after every INSERT, UPDATE, or DELETE in your repository.
  /// [tableName] — the DB table name (e.g. 'items_table')
  /// [entityMap] — the entity data as a Map
  /// [entityId] — the primary key of the entity (as string)
  /// [operation] — 'INSERT', 'UPDATE', or 'DELETE'
  /// [company] — the company ID (as string, nullable)
  void captureSync({
    required String tableName,
    required Map<String, dynamic> entityMap,
    required String entityId,
    required String operation,
    String? company,
  }) {
    try {
      syncService?.capture(
        tableName: tableName,
        entityMap: entityMap,
        entityId: entityId,
        operation: operation,
        company: company,
      );
    } catch (e) {
      developer.log('⚠️ BaseRepo: captureSync error (non-fatal): $e');
    }
  }
}
