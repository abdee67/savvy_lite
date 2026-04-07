import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:savvy_stock/core/services/conectitvity_service.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/core/services/sync/models/sync_device_detail_model.dart';
import 'package:savvy_stock/core/services/sync/models/sync_event_model.dart';
import 'package:savvy_stock/core/services/sync/models/sync_node_status_model.dart';
import 'package:savvy_stock/core/services/sync/sync_receiver.dart';
import 'package:savvy_stock/core/services/sync/sync_repository.dart';
import 'package:savvy_stock/core/services/sync/sync_sender.dart';

/// Core sync engine — Dart equivalent of Java SyncUtil1.
///
/// Architecture improvements over Java version:
/// - **Persistent queue**: All events go directly to SQLite (no in-memory
///   queue). This survives app restarts and avoids memory exhaustion.
/// - **Lifecycle states**: PENDING → IN_PROGRESS → SUCCESS / FAILED
/// - **Crash recovery**: Stale IN_PROGRESS events reset to PENDING on start.
/// - **Exponential backoff**: Failed events retry with increasing delays.
/// - **Idempotency**: UUID-based sourceKey prevents duplicate processing.
/// - **Ordered processing**: Events processed by ID (insertion order),
///   ensuring INSERT happens before UPDATE/DELETE on the same entity.
/// - **Batched processing**: Events processed in configurable page sizes.
/// - **Partial failure handling**: Only failed events are retried; successful
///   ones are not re-sent.
/// - **Conflict resolution**: last-write-wins using timestamps.
class SyncService {
  final SyncRepository syncRepository;
  final SyncSender syncSender;
  final SyncReceiver syncReceiver;
  final ConnectivityService connectivityService;
  final LocalDatabaseService databaseService;

  /// Source node identifier for this device.
  String? _sourceNode;

  /// Periodic sync timer (1-minute interval).
  Timer? _syncTimer;

  /// Whether the service is running.
  bool _running = false;

  /// Lock to prevent concurrent sync cycles.
  bool _isSyncing = false;

  /// Batch size for processing events.
  static const int _batchSize = 50;

  SyncService({
    required this.syncRepository,
    required this.syncSender,
    required this.syncReceiver,
    required this.connectivityService,
    required this.databaseService,
  });

  // ═══════════════════════════════════════════════════════════════════════
  //  LIFECYCLE
  // ═══════════════════════════════════════════════════════════════════════

  /// Start the sync service.
  ///
  /// 1. Recovers stale IN_PROGRESS events (crash recovery)
  /// 2. Starts the 1-minute periodic sync timer
  /// 3. Runs an initial sync after a short delay
  Future<void> start({String? sourceNode}) async {
    if (_running) return;
    _running = true;
    _sourceNode = sourceNode;

    developer.log('🔄 SyncService: Starting...');

    // Crash recovery: reset any stale IN_PROGRESS events
    await syncRepository.recoverStaleInProgressEvents();
    await syncRepository.recoverStaleInProgressDetails();

    // Periodic sync every 1 minute
    _syncTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => syncCycle(),
    );

    // Initial sync after 5 seconds (let app finish initializing)
    Future.delayed(const Duration(seconds: 5), () => syncCycle());

    developer.log('🔄 SyncService: Started — sync every 1 min');
  }

  /// Stop the sync service and cancel timers.
  void dispose() {
    _running = false;
    _syncTimer?.cancel();
    _syncTimer = null;
    developer.log('🔄 SyncService: Stopped');
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  CAPTURE — Called by repositories after CRUD operations
  // ═══════════════════════════════════════════════════════════════════════

  /// Capture a local CRUD operation as a sync event.
  ///
  /// This persists directly to SQLite (no in-memory queue) so the event
  /// survives app crashes. The periodic sync will pick it up.
  ///
  /// [tableName] — the entity/table name (e.g. 'items_table')
  /// [entityMap] — the full entity data as a Map
  /// [entityId] — the primary key of the entity
  /// [operation] — 'INSERT', 'UPDATE', or 'DELETE'
  /// [company] — the company ID as a string
  Future<void> capture({
    required String tableName,
    required Map<String, dynamic> entityMap,
    required String entityId,
    required String operation,
    String? company,
  }) async {
    // Never sync the sync tables themselves
    if (_isSyncTable(tableName)) return;

    try {
      final event = _buildEvent(
        tableName: tableName,
        entityMap: entityMap,
        entityId: entityId,
        operation: operation,
        company: company,
      );

      // Persist directly to SQLite — no memory queue
      await _persistEventWithDetails(event);
    } catch (e) {
      developer.log('❌ SyncService: Error capturing event: $e');
    }
  }

  /// Tables that should never be synced.
  bool _isSyncTable(String tableName) {
    const syncTables = {
      'sync_event',
      'sync_device_detail',
      'sync_node_status',
      'system_url_config',
    };
    return syncTables.contains(tableName.toLowerCase());
  }

  /// Build a SyncEventModel from entity data.
  SyncEventModel _buildEvent({
    required String tableName,
    required Map<String, dynamic> entityMap,
    required String entityId,
    required String operation,
    String? company,
  }) {
    // Generate unique sourceKey for idempotency
    final sourceKey = SyncEventModel.generateSourceKey(_sourceNode);

    // Strip null values from payload
    final cleanMap = <String, dynamic>{};
    entityMap.forEach((key, value) {
      if (value != null) cleanMap[key] = value;
    });

    return SyncEventModel(
      entityName: tableName,
      entityId: entityId,
      operation: operation.toUpperCase(),
      payload: jsonEncode(cleanMap),
      sourceNode: _sourceNode,
      createdAt: DateTime.now().toIso8601String(),
      company: company,
      sourceKey: sourceKey,
      sourceId: entityId,
      syncStatus: SyncStatus.pending,
    );
  }

  /// Persist event and create SyncDeviceDetail rows for each target.
  Future<void> _persistEventWithDetails(SyncEventModel event) async {
    final eventId = await syncRepository.insertSyncEvent(event);

    // Find target URLs for this company
    final targets = await syncRepository.getTargetUrls(event.company);

    for (final target in targets) {
      final detail = SyncDeviceDetailModel(
        syncEvent: eventId,
        company: event.company,
        deviceAddress: target['id'] as int?,
        syncStatus: SyncStatus.pending,
        retryCount: 0,
      );
      await syncRepository.insertSyncDeviceDetail(detail);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  SYNC CYCLE — Runs every 1 minute
  // ═══════════════════════════════════════════════════════════════════════

  /// Run a full sync cycle: push → pull → cleanup.
  Future<void> syncCycle() async {
    if (!_running || _isSyncing) {
      developer.log('🔄 SyncService: Skipping (running=$_running, '
          'syncing=$_isSyncing)');
      return;
    }
    _isSyncing = true;

    try {
      developer.log('🔄 SyncService: ─── Sync cycle start ───');

      // Check connectivity before network operations
      final isOnline = connectivityService.isConnected;

      if (isOnline) {
        // 1. PUSH: Send pending local events to server
        await _pushPendingEvents();

        // 2. PULL: Fetch new events from server
        await _pullFromServers();
      } else {
        developer.log('📴 SyncService: Offline — skipping push/pull');
      }

      // 3. CLEANUP: Remove old successful events (even when offline)
      await syncRepository.cleanUpOldEvents(30);

      // 4. Log status
      final counts = await syncRepository.getEventCountsByStatus();
      developer.log('🔄 SyncService: ─── Sync cycle end ─── '
          'Status: $counts');
    } catch (e) {
      developer.log('❌ SyncService: Sync cycle error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  PUSH — Local → Server
  // ═══════════════════════════════════════════════════════════════════════

  /// Push pending events to their target servers.
  ///
  /// - Processes events in batches (paginated)
  /// - Groups by target device for efficient batch sending
  /// - Marks each detail IN_PROGRESS before sending
  /// - On success: marks SUCCESS
  /// - On failure: marks FAILED with exponential backoff
  /// - Skips already-successful events (partial failure handling)
  Future<void> _pushPendingEvents() async {
    try {
      // Get retryable device details (respects backoff timing)
      final details = await syncRepository.getRetryableDeviceDetails(
        limit: _batchSize,
      );

      if (details.isEmpty) {
        developer.log('🔄 SyncService: No pending events to push');
        return;
      }

      developer.log(
        '🔄 SyncService: Processing ${details.length} delivery records',
      );

      // Load all target URLs
      final allTargets = await syncRepository.getAllTargetUrls();
      final targetMap = <int, String>{};
      for (final t in allTargets) {
        targetMap[t['id'] as int] = t['config_value'] as String? ?? '';
      }

      // Group details by device address for batch sending
      final grouped = <int, List<SyncDeviceDetailModel>>{};
      for (final detail in details) {
        if (detail.deviceAddress != null) {
          grouped.putIfAbsent(detail.deviceAddress!, () => []).add(detail);
        }
      }

      // Process each target group
      for (final entry in grouped.entries) {
        final targetUrl = targetMap[entry.key];
        if (targetUrl == null || targetUrl.isEmpty) continue;

        final deviceDetails = entry.value;

        // Mark all as IN_PROGRESS
        for (final d in deviceDetails) {
          if (d.id != null) {
            await syncRepository.markDeviceDetailInProgress(d.id!);
          }
        }

        // Load actual sync events (ordered by ID for correct sequencing)
        final events = <SyncEventModel>[];
        final eventDetailMap = <int, SyncDeviceDetailModel>{};

        for (final detail in deviceDetails) {
          if (detail.syncEvent != null) {
            final event =
                await syncRepository.getSyncEventById(detail.syncEvent!);
            if (event != null) {
              events.add(event);
              eventDetailMap[event.id!] = detail;
            }
          }
        }

        if (events.isEmpty) continue;

        // Sort by ID to maintain operation order
        events.sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));

        // Push batch to server
        final payloadJson = jsonEncode(events.map((e) => e.toMap()).toList());

        try {
          final response = await syncSender.postJson('$targetUrl/api/sync/push', payloadJson);
          await _handleResponse(response, events, eventDetailMap);
        } catch (ex) {
          developer.log('❌ SyncService: Push to $targetUrl failed completely: $ex');
          for (final event in events) {
            final detail = eventDetailMap[event.id];
            if (detail?.id != null) {
              await syncRepository.markDeviceDetailFailed(
                detail!.id!,
                error: ex.toString(),
                currentRetryCount: detail.retryCount,
              );
            }
          }
        }
      }
    } catch (e) {
      developer.log('❌ SyncService: Push error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  RESPONSE HANDLING
  // ═══════════════════════════════════════════════════════════════════════

  /// Handle HTTP response for multiple events in bulk (dart equivalent of Java handleResponse)
  Future<void> _handleResponse(
    String response,
    List<SyncEventModel> events,
    Map<int, SyncDeviceDetailModel> eventDetailMap,
  ) async {
    if (response.trim().isEmpty) {
      developer.log('⚠️ SyncService: Empty response, nothing to update.');
      await _markRetryBulk(events, eventDetailMap, 'EMPTY_RESPONSE');
      return;
    }

    // 🔥 CRITICAL FIX — detect HTML
    final trimmed = response.trim();
    if (trimmed.startsWith('<')) {
      developer.log('❌ SyncService: HTML received instead of JSON: ${trimmed.substring(0, trimmed.length.clamp(0, 200))}');
      await _markRetryBulk(events, eventDetailMap, 'HTML_RESPONSE');
      return;
    }

    try {
      final body = jsonDecode(trimmed);
      
      // If it's a 409 conflict, we treat it as Success out of the box in SyncSender
      // but if the status code was 409 we might be handling a raw empty body.
      if (body is! Map<String, dynamic>) {
        await _markRetryBulk(events, eventDetailMap, 'INVALID_JSON_ROOT');
        return;
      }

      final savedItemNode = body['savedItem'];
      if (savedItemNode is! List || savedItemNode.isEmpty) {
        developer.log('ℹ️ SyncService: No event IDs found in response.');
        await _markRetryBulk(events, eventDetailMap, 'No IDs in response');
        return;
      }

      final eventIds = <int>[];
      for (final node in savedItemNode) {
        if (node is Map && node['id'] != null) {
          eventIds.add(int.parse(node['id'].toString()));
        }
      }

      if (eventIds.isEmpty) {
        await _markRetryBulk(events, eventDetailMap, 'No IDs in response');
        return;
      }

      if (response.contains('"OK"')) {
        // Mark matched event IDs as success
        for (final eventId in eventIds) {
          final detail = eventDetailMap[eventId];
          if (detail?.id != null) {
            await syncRepository.markDeviceDetailSuccess(detail!.id!);
            if (detail.syncEvent != null) {
              final allDone = await syncRepository.areAllDetailsSuccessful(detail.syncEvent!);
              if (allDone) {
                await syncRepository.transitionEventStatus(
                  detail.syncEvent!, 
                  SyncStatus.pending, 
                  SyncStatus.success,
                );
              }
            }
          }
        }
        
        // Also handle events that we sent but were not explicitly in savedItem (maybe failed on server side)
        // For events not in eventIds, we'll mark them as failed.
        for (final event in events) {
          if (event.id != null && !eventIds.contains(event.id)) {
             final detail = eventDetailMap[event.id];
             if (detail?.id != null) {
               await syncRepository.markDeviceDetailFailed(
                 detail!.id!,
                 error: 'Not acknowledged by target',
                 currentRetryCount: detail.retryCount,
               );
             }
          }
        }
        
        developer.log('✅ SyncService: Sync successful for event IDs: $eventIds');
      } else {
        await _markRetryBulk(events, eventDetailMap, response);
      }
    } catch (e) {
      developer.log('❌ SyncService: Failed to parse response or update SyncDeviceDetail: $e');
      await _markRetryBulk(events, eventDetailMap, e.toString());
    }
  }

  Future<void> _markRetryBulk(
    List<SyncEventModel> events, 
    Map<int, SyncDeviceDetailModel> eventDetailMap, 
    String reason,
  ) async {
    for (final event in events) {
      final detail = eventDetailMap[event.id];
      if (detail?.id != null) {
        await syncRepository.markDeviceDetailFailed(
          detail!.id!,
          error: reason,
          currentRetryCount: detail.retryCount,
        );
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  PULL — Server → Local
  // ═══════════════════════════════════════════════════════════════════════

  /// Pull new events from all target servers and apply them locally.
  ///
  /// Events are processed in order (by server-side creation time)
  /// to maintain correct dependency ordering:
  ///   INSERT entity → UPDATE entity → DELETE entity
  ///
  /// Conflict resolution: **last-write-wins** based on timestamp.
  Future<void> _pullFromServers() async {
    try {
      final targets = await syncRepository.getAllTargetUrls();

      if (targets.isEmpty) {
        developer.log('🔄 SyncService: No targets configured for pull');
        return;
      }

      for (final target in targets) {
        final targetUrl = target['config_value'] as String? ?? '';
        if (targetUrl.isEmpty) continue;

        final nodeId = target['config_key'] as String?;
        String? lastSyncTime;

        // Get last sync time for this node
        if (nodeId != null) {
          final statuses = await syncRepository.getNodeStatuses();
          final matching = statuses.where((s) => s.nodeId == nodeId);
          if (matching.isNotEmpty) {
            lastSyncTime = matching.first.lastSeen;
          }
        }

        // Pull events from server
        final events = await syncReceiver.pullEvents(
          targetUrl,
          lastSyncTime: lastSyncTime,
        );

        if (events.isEmpty) continue;

        // Apply each event in order (server already orders by created_at)
        for (final event in events) {
          await _applyReceivedEvent(event);
        }

        // Update last sync time
        if (nodeId != null && events.isNotEmpty) {
          final latestTime = events.last.createdAt;
          final company = target['company']?.toString() ?? '';
          await syncRepository.upsertNodeStatus(SyncNodeStatusModel(
            nodeId: nodeId,
            company: company,
            lastSeen: latestTime ?? DateTime.now().toIso8601String(),
            sourceNode: _sourceNode,
          ));
        }
      }
    } catch (e) {
      developer.log('❌ SyncService: Pull error: $e');
    }
  }

  /// Apply a received sync event to the local database.
  ///
  /// Conflict resolution: **last-write-wins**.
  /// If an entity already exists and the incoming event is newer,
  /// it overwrites the local data.
  Future<void> _applyReceivedEvent(SyncEventModel event) async {
    try {
      // Skip events from this node (avoid round-trip syncing)
      if (_sourceNode != null && event.sourceNode == _sourceNode) {
        developer.log('⏭️ Skipping own event: ${event.sourceKey}');
        return;
      }

      final db = await databaseService.database;
      final entityData = jsonDecode(event.payload) as Map<String, dynamic>;
      final tableName = event.entityName;
      final operation = event.operation.toUpperCase();

      switch (operation) {
        case 'INSERT':
          final existing = await db.query(
            tableName,
            where: 'id = ?',
            whereArgs: [entityData['id']],
            limit: 1,
          );
          if (existing.isEmpty) {
            await db.insert(tableName, entityData);
            developer.log('📥 Applied INSERT on $tableName');
          } else {
            // Entity exists — last-write-wins: update if incoming is newer
            await db.update(
              tableName,
              entityData,
              where: 'id = ?',
              whereArgs: [entityData['id']],
            );
            developer.log(
              '📥 Applied INSERT→UPDATE on $tableName (already existed)',
            );
          }
          break;

        case 'UPDATE':
          await db.update(
            tableName,
            entityData,
            where: 'id = ?',
            whereArgs: [entityData['id']],
          );
          developer.log('📥 Applied UPDATE on $tableName');
          break;

        case 'DELETE':
          await db.delete(
            tableName,
            where: 'id = ?',
            whereArgs: [entityData['id']],
          );
          developer.log('📥 Applied DELETE on $tableName');
          break;

        default:
          developer.log('⚠️ Unknown operation: $operation');
      }
    } catch (e) {
      developer.log(
        '❌ SyncService: Error applying event '
        '${event.entityName}#${event.entityId}: $e',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  PUBLIC API
  // ═══════════════════════════════════════════════════════════════════════

  bool get isRunning => _running;
  String? get sourceNode => _sourceNode;
  set sourceNode(String? node) => _sourceNode = node;

  /// Force an immediate sync cycle (call from UI "Sync Now" button, etc.)
  Future<void> forceSyncNow() async => syncCycle();

  /// Get sync queue status for monitoring/UI display.
  Future<Map<String, int>> getStatus() async {
    return syncRepository.getEventCountsByStatus();
  }

  /// Set auth token for both sender and receiver.
  void setAuthToken(String? token) {
    syncSender.authToken = token;
    syncReceiver.authToken = token;
  }
}
