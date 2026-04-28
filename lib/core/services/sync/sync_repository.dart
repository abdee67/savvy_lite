import 'dart:developer' as developer;

import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/core/services/sync/models/sync_device_detail_model.dart';
import 'package:savvy_stock/core/services/sync/models/sync_event_model.dart';
import 'package:savvy_stock/core/services/sync/models/sync_node_status_model.dart';
import 'package:sqflite/sqflite.dart';

/// Repository handling all local SQLite CRUD operations for sync tables.
///
/// Provides:
/// - Persistent event queue (no in-memory queue — survives app restarts)
/// - Lifecycle state transitions (PENDING → IN_PROGRESS → SUCCESS / FAILED)
/// - Batched & paginated queries for efficient processing
/// - Idempotency checks via sourceKey
/// - Cleanup/archiving of old events
class SyncRepository {
  final LocalDatabaseService databaseService;

  SyncRepository({required this.databaseService});

  // ═══════════════════════════════════════════════════════════════════════
  //  SYNC EVENT
  // ═══════════════════════════════════════════════════════════════════════

  /// Insert a new sync event. Returns the inserted row ID.
  /// Checks for idempotency: if [sourceKey] already exists, skips.
  Future<int> insertSyncEvent(SyncEventModel event) async {
    final db = await databaseService.database;

    // Idempotency check — skip if sourceKey already exists
    if (event.sourceKey != null && event.sourceKey!.isNotEmpty) {
      final existing = await db.query(
        'sync_event',
        where: 'source_key = ?',
        whereArgs: [event.sourceKey],
        limit: 1,
      );
      if (existing.isNotEmpty) {
        developer.log(
          '⏭️ SyncRepo: Skipping duplicate event '
          'sourceKey=${event.sourceKey}',
        );
        return existing.first['id'] as int;
      }
    }

    final map = event.toMap();
    map.remove('id');
    final id = await db.insert('sync_event', map);
    developer.log(
      '📦 SyncRepo: Inserted sync_event id=$id '
      'entity=${event.entityName} op=${event.operation}',
    );
    return id;
  }

  /// Get PENDING events in batches, ordered by ID (preserves ordering).
  Future<List<SyncEventModel>> getPendingEvents({
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await databaseService.database;
    final rows = await db.query(
      'sync_event',
      where: "sync_status = ?",
      whereArgs: [SyncStatus.pending],
      orderBy: 'id ASC',
      limit: limit,
      offset: offset,
    );
    return rows.map((r) => SyncEventModel.fromMap(r)).toList();
  }

  /// Get a sync event by ID.
  Future<SyncEventModel?> getSyncEventById(int id) async {
    final db = await databaseService.database;
    final rows = await db.query(
      'sync_event',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return SyncEventModel.fromMap(rows.first);
  }

  /// Transition event status. This is the only way to change event state.
  Future<void> transitionEventStatus(
    int eventId,
    String fromStatus,
    String toStatus,
  ) async {
    final db = await databaseService.database;
    final updated = await db.update(
      'sync_event',
      {'sync_status': toStatus},
      where: 'id = ? AND sync_status = ?',
      whereArgs: [eventId, fromStatus],
    );
    if (updated == 0) {
      developer.log(
        '⚠️ SyncRepo: Status transition failed for event $eventId '
        '($fromStatus → $toStatus) — event may have been modified',
      );
    }
  }

  /// Reset any IN_PROGRESS events back to PENDING.
  /// Call this on app start to recover from crashes mid-sync.
  Future<int> recoverStaleInProgressEvents() async {
    final db = await databaseService.database;
    final count = await db.update(
      'sync_event',
      {'sync_status': SyncStatus.pending},
      where: "sync_status = ?",
      whereArgs: [SyncStatus.inProgress],
    );
    if (count > 0) {
      developer.log('🔄 SyncRepo: Recovered $count stale IN_PROGRESS events');
    }
    return count;
  }

  /// Count events by status.
  Future<Map<String, int>> getEventCountsByStatus() async {
    final db = await databaseService.database;
    final result = await db.rawQuery(
      'SELECT sync_status, COUNT(*) as count FROM sync_event GROUP BY sync_status',
    );
    final counts = <String, int>{};
    for (final row in result) {
      counts[row['sync_status'] as String? ?? 'UNKNOWN'] =
          (row['count'] as int?) ?? 0;
    }
    return counts;
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  SYNC DEVICE DETAIL
  // ═══════════════════════════════════════════════════════════════════════

  /// Insert a sync device detail row.
  Future<int> insertSyncDeviceDetail(SyncDeviceDetailModel detail) async {
    final db = await databaseService.database;
    final map = detail.toMap();
    map.remove('id');
    return await db.insert('sync_device_detail', map);
  }

  /// Get PENDING device details for a given sync event.
  Future<List<SyncDeviceDetailModel>> getPendingDeviceDetails(
    int syncEventId,
  ) async {
    final db = await databaseService.database;
    final rows = await db.query(
      'sync_device_detail',
      where: "sync_event = ? AND sync_status IN (?, ?)",
      whereArgs: [syncEventId, SyncStatus.pending, SyncStatus.failed],
    );
    return rows.map((r) => SyncDeviceDetailModel.fromMap(r)).toList();
  }

  /// Get retryable device details: PENDING or FAILED, within retry limit,
  /// and whose backoff period has elapsed.
  Future<List<SyncDeviceDetailModel>> getRetryableDeviceDetails({
    int limit = 50,
  }) async {
    final db = await databaseService.database;
    final now = DateTime.now().toIso8601String();

    // We filter in Dart for the backoff timing since SQLite date handling
    // is limited. Query gets all candidates, then filter.
    final rows = await db.rawQuery(
      '''
      SELECT sdd.* FROM sync_device_detail sdd
      INNER JOIN sync_event se ON sdd.sync_event = se.id
      WHERE sdd.sync_status IN (?, ?)
        AND sdd.retry_count < ?
      ORDER BY se.id ASC
      LIMIT ?
    ''',
      [
        SyncStatus.pending,
        SyncStatus.failed,
        SyncDeviceDetailModel.maxRetries,
        limit * 2, // Fetch extra to account for backoff filtering
      ],
    );

    final details = rows.map((r) => SyncDeviceDetailModel.fromMap(r)).toList();

    // Filter by backoff timing
    return details.where((d) => d.isReadyForRetry).take(limit).toList();
  }

  /// Mark a device detail as IN_PROGRESS (being sent).
  Future<void> markDeviceDetailInProgress(int detailId) async {
    final db = await databaseService.database;
    await db.update(
      'sync_device_detail',
      {
        'sync_status': SyncStatus.inProgress,
        'last_attempt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [detailId],
    );
  }

  /// Mark a device detail as SUCCESS.
  Future<void> markDeviceDetailSuccess(int detailId) async {
    final db = await databaseService.database;
    await db.update(
      'sync_device_detail',
      {
        'sync_status': SyncStatus.success,
        'last_attempt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [detailId],
    );
  }

  /// Mark a device detail as FAILED with error and exponential backoff.
  Future<void> markDeviceDetailFailed(
    int detailId, {
    String? error,
    required int currentRetryCount,
  }) async {
    final db = await databaseService.database;
    final backoff = SyncDeviceDetailModel.calculateBackoff(currentRetryCount);
    final nextRetry = DateTime.now().add(backoff).toIso8601String();

    await db.rawUpdate(
      '''
      UPDATE sync_device_detail
      SET sync_status = ?,
          last_attempt = ?,
          last_error = ?,
          retry_count = retry_count + 1
      WHERE id = ?
    ''',
      [
        SyncStatus.failed,
        DateTime.now().toIso8601String(),
        (error ?? 'Unknown error').length > 1000
            ? (error ?? 'Unknown error').substring(0, 1000)
            : (error ?? 'Unknown error'),
        detailId,
      ],
    );

    developer.log(
      '⏳ SyncRepo: Detail $detailId failed, retry '
      '${currentRetryCount + 1}/${SyncDeviceDetailModel.maxRetries}, '
      'next retry after ${backoff.inSeconds}s',
    );
  }

  /// Reset stale IN_PROGRESS device details to PENDING (crash recovery).
  Future<int> recoverStaleInProgressDetails() async {
    final db = await databaseService.database;
    return await db.update(
      'sync_device_detail',
      {'sync_status': SyncStatus.pending},
      where: "sync_status = ?",
      whereArgs: [SyncStatus.inProgress],
    );
  }

  /// Check if all device details for an event are SUCCESS.
  Future<bool> areAllDetailsSuccessful(int syncEventId) async {
    final db = await databaseService.database;
    final pending = await db.rawQuery(
      '''
      SELECT COUNT(*) as count FROM sync_device_detail
      WHERE sync_event = ? AND sync_status != ?
    ''',
      [syncEventId, SyncStatus.success],
    );
    return ((pending.first['count'] as int?) ?? 0) == 0;
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  SYSTEM URL CONFIG (target servers)
  // ═══════════════════════════════════════════════════════════════════════

  /// Get active target server URLs, optionally filtered by company.
  /// Also includes globally configured URLs where `company IS NULL`.
  Future<List<Map<String, dynamic>>> getTargetUrls(
    String? company, {
    Transaction? txn,
  }) async {
    final db = await databaseService.database;
    final executor = txn ?? db;

    if (company == null || company.isEmpty) {
      return await executor.query(
        'system_url_config',
        where: "active = ? AND company IS NULL",
        whereArgs: ['Y'],
      );
    }
    return await executor.query(
      'system_url_config',
      where: "active = ? AND (company = ? OR company IS NULL)",
      whereArgs: ['Y', company],
    );
  }

  /// Get all system_url_config entries.
  Future<List<Map<String, dynamic>>> getAllTargetUrls() async {
    final db = await databaseService.database;
    return await db.query('system_url_config');
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  SYNC NODE STATUS
  // ═══════════════════════════════════════════════════════════════════════

  /// Get all node statuses.
  Future<List<SyncNodeStatusModel>> getNodeStatuses() async {
    final db = await databaseService.database;
    final rows = await db.query('sync_node_status');
    return rows.map((r) => SyncNodeStatusModel.fromMap(r)).toList();
  }

  /// Insert or update a node status by node_id.
  Future<void> upsertNodeStatus(SyncNodeStatusModel status) async {
    final db = await databaseService.database;
    final existing = await db.query(
      'sync_node_status',
      where: 'node_id = ?',
      whereArgs: [status.nodeId],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      await db.update(
        'sync_node_status',
        {
          'last_seen': status.lastSeen,
          'company': status.company,
          'source_node': status.sourceNode,
        },
        where: 'node_id = ?',
        whereArgs: [status.nodeId],
      );
    } else {
      final map = status.toMap();
      map.remove('id');
      await db.insert('sync_node_status', map);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  CLEANUP & ARCHIVING
  // ═══════════════════════════════════════════════════════════════════════

  /// Delete successfully synced events older than [daysOld] days.
  /// This prevents database bloat.
  Future<int> cleanUpOldEvents(int daysOld) async {
    final db = await databaseService.database;
    final cutoff = DateTime.now()
        .subtract(Duration(days: daysOld))
        .toIso8601String();

    // First delete associated device details
    await db.rawDelete(
      '''
      DELETE FROM sync_device_detail WHERE sync_event IN
      (SELECT id FROM sync_event WHERE sync_status = ? AND created_at < ?)
    ''',
      [SyncStatus.success, cutoff],
    );

    // Then delete the events
    return await db.delete(
      'sync_event',
      where: "sync_status = ? AND created_at < ?",
      whereArgs: [SyncStatus.success, cutoff],
    );
  }

  /// Count pending events (for monitoring).
  Future<int> countPendingEvents() async {
    final db = await databaseService.database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as count FROM sync_event WHERE sync_status IN (?, ?)",
      [SyncStatus.pending, SyncStatus.failed],
    );
    return (result.first['count'] as int?) ?? 0;
  }
}
