import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:savvy_stock/core/services/conectitvity_service.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/core/services/sync/models/sync_device_detail_model.dart';
import 'package:savvy_stock/features/company/models/company_model.dart';
import 'package:savvy_stock/features/system_constant/models/system_constant.dart';
import 'package:sqflite/sqflite.dart';
import 'package:savvy_stock/core/services/sync/models/sync_event_model.dart';
import 'package:savvy_stock/core/services/sync/models/sync_node_status_model.dart';
import 'package:savvy_stock/core/services/sync/sync_receiver.dart';
import 'package:savvy_stock/core/services/sync/sync_repository.dart';
import 'package:savvy_stock/core/services/sync/sync_sender.dart';

class _DbColumnInfo {
  final String name;
  final String type;

  const _DbColumnInfo({required this.name, required this.type});

  String get normalizedType => type.toUpperCase();
  bool get isInteger => normalizedType.contains('INT');
  bool get isReal =>
      normalizedType.contains('REAL') ||
      normalizedType.contains('FLOA') ||
      normalizedType.contains('DOUB');
  bool get isText =>
      normalizedType.contains('CHAR') ||
      normalizedType.contains('CLOB') ||
      normalizedType.contains('TEXT');
}

class _OrderedSyncEvent {
  final SyncEventModel event;
  final int sequence;
  final int originalIndex;

  const _OrderedSyncEvent({
    required this.event,
    required this.sequence,
    required this.originalIndex,
  });
}

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

  /// Username for pull requests.
  String? _username;

  /// Periodic sync timer (1-minute interval).
  Timer? _syncTimer;

  /// Whether the service is running.
  bool _running = false;

  /// Lock to prevent concurrent sync cycles.
  bool _isSyncing = false;

  /// Batch size for processing events.
  static const int _batchSize = 500;

  final Map<String, Map<String, _DbColumnInfo>> _tableSchemaCache = {};

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
  Future<void> start({String? sourceNode, String? username}) async {
    if (_running) return;
    _running = true;
    _sourceNode = 'ANDROID';
    _username = username;

    developer.log('🔄 SyncService: Starting...');

    // Crash recovery: reset any stale IN_PROGRESS events
    await syncRepository.recoverStaleInProgressEvents();
    await syncRepository.recoverStaleInProgressDetails();

    // Periodic sync every 1 minute
    _syncTimer = Timer.periodic(const Duration(minutes: 1), (_) => syncCycle());

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
    Transaction? txn,
  }) async {
    // Never sync the sync tables themselves
    if (_isSyncTable(tableName)) return;

    try {
      final event = await _buildEvent(
        tableName: tableName,
        entityMap: entityMap,
        entityId: entityId,
        operation: operation,
        company: company,
      );

      // Persist directly to SQLite — no memory queue
      await _persistEventWithDetails(event, txn: txn);
    } catch (e) {
      developer.log('❌ SyncService: Error capturing event: $e');
    }
  }

  /// Cache for entity sequence numbers loaded from JSON
  static final Map<String, int> _entitySequenceCache = {};

  /// Cache to map snake_case local SQLite table names to PascalCase Java Entity Names
  static final Map<String, String> _tableToEntityCache = {};

  /// Cache to map PascalCase Java Entity Names back to snake_case local SQLite table names
  static final Map<String, String> _entityToTableCache = {};

  Future<void> _loadEntitySequencesIfNeeded() async {
    if (_entitySequenceCache.isNotEmpty) return;
    try {
      final jsonString = await rootBundle.loadString(
        'lib/core/constants/sync_sequence.json',
      );
      final sequenceEntries = jsonDecode(jsonString) as List<dynamic>;

      final exp = RegExp(r'(?<=[a-z])([A-Z])');

      for (final entry in sequenceEntries) {
        if (entry is Map<String, dynamic>) {
          final entityName = entry['entity']?.toString();
          final sequence = entry['sequence'];
          if (entityName != null && sequence != null) {
            _entitySequenceCache[entityName] =
                int.tryParse(sequence.toString()) ?? 0;

            // Map EntityName to snake_case table name for bi-directional resolution
            final tableName = entityName
                .replaceAllMapped(exp, (m) => '_${m.group(1)}')
                .toLowerCase();
            _entityToTableCache[entityName] = tableName;
            _tableToEntityCache[tableName] = entityName;
          }
        }
      }

      // Explicit manual mappings for typos or irregular names in JSON
      _tableToEntityCache['user_role'] = 'UserRole';
      _entityToTableCache['UserRole'] = 'user_role';

      _tableToEntityCache['role_privilege'] = 'RolePrevilage';
      _entityToTableCache['RolePrevilage'] = 'role_privilege';

      _tableToEntityCache['privilege_table'] = 'PrevilageTable';
      _entityToTableCache['PrevilageTable'] = 'privilege_table';

      _tableToEntityCache['item_cost'] = 'ItemCostTable';
      _entityToTableCache['ItemCostTable'] = 'item_cost';

      _tableToEntityCache['item_location'] = 'ItemLocations';
      _entityToTableCache['ItemLocations'] = 'item_location';
    } catch (e) {
      developer.log('❌ SyncService: Failed to load sync sequences: $e');
    }
  }

  /// Maps a snake_case SQLite table name to the Java Entity name from JSON.
  Future<String> resolveEntityName(String tableName) async {
    await _loadEntitySequencesIfNeeded();
    return _tableToEntityCache[tableName] ??
        tableName; // Fallback if not mapped
  }

  /// Maps a Java Entity name from JSON back to a snake_case SQLite table name.
  Future<String> resolveTableName(String entityName) async {
    await _loadEntitySequencesIfNeeded();
    return _entityToTableCache[entityName] ??
        entityName; // Fallback if not mapped
  }

  Future<int?> resolveSequenceNumber(String entityName) async {
    await _loadEntitySequencesIfNeeded();
    final seq = _entitySequenceCache[entityName];
    if (seq == null) {
      developer.log(
        '⚠️ SyncService: Failed to resolve sequence number for entity $entityName',
      );
    }
    return seq;
  }

  String? _cachedMachineId;

  Future<String> _getMachineId() async {
    if (_cachedMachineId != null) return _cachedMachineId!;
    final deviceInfoPlugin = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        _cachedMachineId = androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        _cachedMachineId = iosInfo.identifierForVendor ?? 'Unknown_IOS';
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfoPlugin.windowsInfo;
        _cachedMachineId = windowsInfo.deviceId;
      } else {
        _cachedMachineId = 'Unknown_Device';
      }
    } catch (e) {
      _cachedMachineId = 'Unknown_Device';
    }
    return _cachedMachineId!;
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
  Future<SyncEventModel> _buildEvent({
    required String tableName,
    required Map<String, dynamic> entityMap,
    required String entityId,
    required String operation,
    String? company,
  }) async {
    // Generate unique sourceKey for idempotency
    final sourceKey = SyncEventModel.generateSourceKey(_sourceNode);

    // Strip null values from payload
    final cleanMap = <String, dynamic>{};
    entityMap.forEach((key, value) {
      if (value != null) cleanMap[key] = value;
    });
    final entityName = await resolveEntityName(tableName);
    final sequenceNumber = await resolveSequenceNumber(entityName);
    final deviceId = await _getMachineId();

    return SyncEventModel(
      entityName: entityName,
      entityId: entityId,
      operation: operation.toUpperCase(),
      payload: jsonEncode(cleanMap),
      sourceNode: 'ANDROID',
      createdAt: DateTime.now().toIso8601String(),
      company: company,
      sourceKey: sourceKey,
      sourceAddress: deviceId,
      // sourceId is reserved for numeric server-side identifiers.
      syncStatus: SyncStatus.pending,
      sequenceNumber: sequenceNumber,
    );
  }

  /// Persist event and create SyncDeviceDetail rows for each target.
  /// When [txn] is provided, inserts use the same transaction for atomicity.
  Future<void> _persistEventWithDetails(
    SyncEventModel event, {
    Transaction? txn,
  }) async {
    if (txn != null) {
      // Use transaction directly for atomic operations
      final map = event.toMap();
      map.remove('id');
      final eventId = await txn.insert('sync_event', map);

      final targets = await syncRepository.getTargetUrls(
        event.company,
        txn: txn,
      );
      for (final target in targets) {
        final detailMap = SyncDeviceDetailModel(
          syncEvent: eventId,
          company: event.company,
          deviceAddress: target['id'] as int?,
          syncStatus: SyncStatus.pending,
          retryCount: 0,
        ).toMap();
        detailMap.remove('id');
        await txn.insert('sync_device_detail', detailMap);
      }
    } else {
      // Original path — outside transaction
      final eventId = await syncRepository.insertSyncEvent(event);
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
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  SYNC CYCLE — Runs every 1 minute
  // ═══════════════════════════════════════════════════════════════════════

  /// Run a full sync cycle: push → pull → cleanup.
  Future<void> syncCycle() async {
    if (!_running || _isSyncing) {
      developer.log(
        '🔄 SyncService: Skipping (running=$_running, '
        'syncing=$_isSyncing)',
      );
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
      developer.log(
        '🔄 SyncService: ─── Sync cycle end ─── '
        'Status: $counts',
      );
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
            final event = await syncRepository.getSyncEventById(
              detail.syncEvent!,
            );
            if (event != null) {
              events.add(event);
              eventDetailMap[event.id!] = detail;
            }
          }
        }

        if (events.isEmpty) continue;

        // Sort by sequence number and creation order to ensure dependency-safe pushing
        final orderedEvents = await _orderEventsByDependency(events);
 
        final sequenceSummary = orderedEvents
            .map((e) => '${e.entityName}(${e.sequenceNumber ?? '?'})')
            .join(' -> ');
        developer.log('📤 SyncService: Pushing sequence to $targetUrl: $sequenceSummary');
 
        try {
          final response = await _pushBatchWithFallback(targetUrl, orderedEvents);
          await _handleResponse(response, orderedEvents, eventDetailMap);
        } catch (ex) {
          developer.log(
            '❌ SyncService: Push to $targetUrl failed completely: $ex',
          );
          for (final event in orderedEvents) {
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
  Future<String> _pushBatchWithFallback(
    String targetUrl,
    List<SyncEventModel> events,
  ) async {
    final normalizedTargetUrl = targetUrl.endsWith('/')
        ? targetUrl.substring(0, targetUrl.length - 1)
        : targetUrl;
    final pushUrl = '$normalizedTargetUrl/api/sync/push';
    final primaryPayloadJson = _buildPushPayloadJson(
      events,
      useCamelCase: true,
    );
    final primaryPayloadSchemaJson = _buildPushPayloadSchemaJson(
      events,
      useCamelCase: true,
    );

    developer.log(
      '🔍 SyncService: Push diagnostics (primary) finalUrl=$pushUrl',
    );
    developer.log(
      '🔍 SyncService: Push diagnostics (primary) payloadSchema=$primaryPayloadSchemaJson',
    );
    developer.log('SyncService: Pushing payload to $pushUrl');

    try {
      return await syncSender.postJson(pushUrl, primaryPayloadJson);
    } on SyncHttpException catch (ex) {
      if (ex.statusCode != 400) rethrow;

      final fallbackPayloadJson = _buildPushPayloadJson(
        events,
        useCamelCase: false,
      );
      final fallbackPayloadSchemaJson = _buildPushPayloadSchemaJson(
        events,
        useCamelCase: false,
      );

      if (fallbackPayloadJson == primaryPayloadJson) {
        rethrow;
      }

      developer.log(
        'SyncService: HTTP 400 on camelCase push, retrying snake_case payload.',
      );
      developer.log(
        '🔍 SyncService: Push diagnostics (fallback) finalUrl=$pushUrl',
      );
      developer.log(
        '🔍 SyncService: Push diagnostics (fallback) payloadSchema=$fallbackPayloadSchemaJson',
      );
      developer.log('SyncService: Retry payload to $pushUrl');

      return syncSender.postJson(pushUrl, fallbackPayloadJson);
    }
  }

  String _buildPushPayloadJson(
    List<SyncEventModel> events, {
    required bool useCamelCase,
  }) {
    return jsonEncode(
      events.map((e) => e.toServerMap(useCamelCase: useCamelCase)).toList(),
    );
  }

  String _buildPushPayloadSchemaJson(
    List<SyncEventModel> events, {
    required bool useCamelCase,
  }) {
    final topLevelFieldTypes = <String, String>{};
    final payloadFieldTypes = <String, String>{};
    final operations = <String>{};
    final entities = <String>{};
    var payloadFieldLimitReached = false;

    for (final event in events) {
      operations.add(event.operation);
      entities.add(event.entityName);

      final serverMap = event.toServerMap(useCamelCase: useCamelCase);
      serverMap.forEach((key, value) {
        topLevelFieldTypes.putIfAbsent(key, () => _schemaTypeOf(value));
      });

      try {
        final decodedPayload = jsonDecode(event.payload);
        if (decodedPayload is Map) {
          decodedPayload.forEach((key, value) {
            final keyString = key.toString();
            if (payloadFieldTypes.containsKey(keyString)) {
              return;
            }
            if (payloadFieldTypes.length >= 40) {
              payloadFieldLimitReached = true;
              return;
            }
            payloadFieldTypes[keyString] = _schemaTypeOf(value);
          });
        } else {
          payloadFieldTypes.putIfAbsent('__payload__', () => 'non_map_json');
        }
      } catch (_) {
        payloadFieldTypes.putIfAbsent('__payload__', () => 'non_json_string');
      }
    }

    final sortedTopLevel = Map<String, String>.fromEntries(
      topLevelFieldTypes.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key)),
    );
    final sortedPayload = Map<String, String>.fromEntries(
      payloadFieldTypes.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key)),
    );
    final sortedOperations = operations.toList()..sort();
    final sortedEntities = entities.toList()..sort();

    return jsonEncode({
      'rootType': 'List<Map<String,dynamic>>',
      'eventCount': events.length,
      'keyStyle': useCamelCase ? 'camelCase' : 'snake_case',
      'topLevelFieldTypes': sortedTopLevel,
      'payloadFieldTypesSample': sortedPayload,
      'payloadFieldLimitReached': payloadFieldLimitReached,
      'operations': sortedOperations,
      'entitiesSample': sortedEntities.take(10).toList(),
    });
  }

  String _schemaTypeOf(dynamic value) {
    if (value == null) return 'null';
    if (value is String) return 'string';
    if (value is int) return 'int';
    if (value is double) return 'double';
    if (value is bool) return 'bool';
    if (value is List) return 'list';
    if (value is Map) return 'map';
    return value.runtimeType.toString();
  }

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
      developer.log(
        '❌ SyncService: HTML received instead of JSON: ${trimmed.substring(0, trimmed.length.clamp(0, 200))}',
      );
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

      final status = body['status']?.toString().toUpperCase();
      final savedItemNode = body['savedItem'] ?? body['saved_item'];
      if (savedItemNode is! List || savedItemNode.isEmpty) {
        developer.log('ℹ️ SyncService: No event IDs found in response. Server returned: $body');
        await _markRetryBulk(events, eventDetailMap, 'No IDs in response');
        return;
      }

      final eventKeys = <String>[];
      for (final node in savedItemNode) {
        if (node is Map) {
          final key =
              node['sourceKey']?.toString() ??
              node['sourceId']?.toString() ??
              node['source_key']?.toString() ??
              node['source_id']?.toString();
          if (key != null && key.isNotEmpty) {
            eventKeys.add(key);
          }
        }
      }

      if (eventKeys.isEmpty) {
        await _markRetryBulk(
          events,
          eventDetailMap,
          'No sourceKeys in response',
        );
        return;
      }

      if (response.contains('"OK"')) {
        // Mark matched events as success
        for (final event in events) {
          if (event.sourceKey != null && eventKeys.contains(event.sourceKey)) {
            final detail = eventDetailMap[event.id!];
            if (detail?.id != null) {
              await syncRepository.markDeviceDetailSuccess(detail!.id!);
              if (detail.syncEvent != null) {
                final allDone = await syncRepository.areAllDetailsSuccessful(
                  detail.syncEvent!,
                );
                if (allDone) {
                  await syncRepository.transitionEventStatus(
                    detail.syncEvent!,
                    SyncStatus.pending,
                    SyncStatus.success,
                  );
                }
              }
            }
          } else {
            // Also handle events that we sent but were not explicitly in savedItem
            final detail = eventDetailMap[event.id!];
            if (detail?.id != null) {
              await syncRepository.markDeviceDetailFailed(
                detail!.id!,
                error: 'Not acknowledged by target',
                currentRetryCount: detail.retryCount,
              );
            }
          }
        }

        developer.log(
          '✅ SyncService: Sync successful for event sourceKeys: $eventKeys',
        );
      } else {
        await _markRetryBulk(events, eventDetailMap, response);
      }
    } catch (e) {
      developer.log(
        '❌ SyncService: Failed to parse response or update SyncDeviceDetail: $e',
      );
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
  

  Future<List<SyncEventModel>> _orderEventsByDependency(
    List<SyncEventModel> events,
  ) async {
    final ordered = <_OrderedSyncEvent>[];
    final sequenceByEntity = <String, int?>{};

    for (var i = 0; i < events.length; i++) {
      final event = events[i];
      var sequence = event.sequenceNumber;
      if (sequence == null) {
        if (sequenceByEntity.containsKey(event.entityName)) {
          sequence = sequenceByEntity[event.entityName];
        } else {
          sequence = await resolveSequenceNumber(event.entityName);
          sequenceByEntity[event.entityName] = sequence;
        }
      }
      sequence ??= 1 << 30;

      ordered.add(
        _OrderedSyncEvent(event: event, sequence: sequence, originalIndex: i),
      );
    }

    ordered.sort((a, b) {
      final sequenceCompare = a.sequence.compareTo(b.sequence);
      if (sequenceCompare != 0) return sequenceCompare;

      final createdCompare = _compareCreatedAt(
        a.event.createdAt,
        b.event.createdAt,
      );
      if (createdCompare != 0) return createdCompare;

      final idCompare = (a.event.id ?? 0).compareTo(b.event.id ?? 0);
      if (idCompare != 0) return idCompare;

      return a.originalIndex.compareTo(b.originalIndex);
    });

    return ordered.map((entry) => entry.event).toList();
  }

  int _compareCreatedAt(String? left, String? right) {
    final leftDate = left == null ? null : DateTime.tryParse(left);
    final rightDate = right == null ? null : DateTime.tryParse(right);

    if (leftDate != null && rightDate != null) {
      return leftDate.compareTo(rightDate);
    }
    if (leftDate != null) return -1;
    if (rightDate != null) return 1;

    return (left ?? '').compareTo(right ?? '');
  }

  String? _latestCreatedAt(List<SyncEventModel> events) {
    DateTime? latestDate;
    String? latestRaw;

    for (final event in events) {
      final raw = event.createdAt;
      if (raw == null || raw.isEmpty) continue;

      final parsed = DateTime.tryParse(raw);
      if (parsed == null) {
        latestRaw ??= raw;
        continue;
      }

      if (latestDate == null || parsed.isAfter(latestDate)) {
        latestDate = parsed;
        latestRaw = raw;
      }
    }

    return latestRaw;
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
    if (_username == null) {
      developer.log('🔄 SyncService: No username set — skipping pull');
      return;
    }

    try {
      final targets = await syncRepository.getAllTargetUrls();

      if (targets.isEmpty) {
        developer.log('🔄 SyncService: No targets configured for pull');
        return;
      }

      final db = await databaseService.database;

      for (final target in targets) {
        final targetUrl = target['config_value'] as String? ?? '';
        if (targetUrl.isEmpty) continue;

        final nodeId = target['config_key'] as String?;

        // Pull events from server
        final deviceId = await _getMachineId();
        final events = await syncReceiver.pullEvents(
          targetUrl,
          userName: _username ?? '',
          sourceAddress: deviceId,
        );

        if (events.isEmpty) continue;

        // Filter out already-synced events by checking source_id in local sync_event table.
        // The server sends its own sync_event ID which we store as source_id locally.
        // If source_id already exists, this event was already pulled — skip it.
        final List<SyncEventModel> newEvents = [];
        for (final event in events) {
          final serverId = event.id?.toString();
          if (serverId == null || serverId.isEmpty) {
            newEvents.add(event);
            continue;
          }

          final existing = await db.query(
            'sync_event',
            where: 'source_id = ?',
            whereArgs: [serverId],
            limit: 1,
          );

          if (existing.isEmpty) {
            newEvents.add(event);
          } else {
            developer.log(
              '⏭️ Skipping already-synced event source_id=$serverId',
            );
          }
        }

        if (newEvents.isEmpty) {
          developer.log(
            '🔄 SyncService: All events from $targetUrl already synced',
          );
          continue;
        }

        // Apply each new event and track successfully processed server IDs
        final List<String> acknowledgedIds = [];
        final orderedEvents = await _orderEventsByDependency(newEvents);

        for (final event in orderedEvents) {
          try {
            await _applyReceivedEvent(event);

            // Store the pulled event in local sync_event table with server ID as source_id
            final localEvent = SyncEventModel(
              entityName: event.entityName,
              entityId: event.entityId,
              operation: event.operation,
              payload: event.payload,
              sourceNode: event.sourceNode,
              createdAt: event.createdAt,
              company: event.company,
              sourceKey: event.sourceKey,
              sourceAddress: deviceId,
              sourceId: event.id?.toString(), // Server's sync_event ID
              syncStatus: SyncStatus.success,
              sequenceNumber: event.sequenceNumber,
            );
            await db.insert('sync_event', localEvent.toMap());

            if (event.id != null) {
              acknowledgedIds.add(event.id.toString());
            }
          } catch (e) {
            developer.log(
              '❌ SyncService: Failed to apply event ${event.entityName}#${event.entityId}: $e',
            );
          }
        }

        // Acknowledge successfully received events to the server
        if (acknowledgedIds.isNotEmpty) {
          await syncReceiver.updateSyncEvent(targetUrl, acknowledgedIds);
        }

        // Update last sync time
        if (nodeId != null && newEvents.isNotEmpty) {
          final latestTime = _latestCreatedAt(newEvents);
          final company = target['company']?.toString() ?? '';
          await syncRepository.upsertNodeStatus(
            SyncNodeStatusModel(
              nodeId: nodeId,
              company: company,
              lastSeen: latestTime ?? DateTime.now().toIso8601String(),
              sourceNode: _sourceNode,
            ),
          );
        }
      }
    } catch (e) {
      developer.log('❌ SyncService: Pull error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  PAYLOAD CONVERSION — Model-aware deserialization
  // ═══════════════════════════════════════════════════════════════════════

  /// Convert a camelCase string to snake_case (fallback for unmapped entities).
  String _camelToSnake(String input) {
    final normalized = input.trim().replaceAll('-', '_');
    return normalized
        .replaceAllMapped(
          RegExp(r'([A-Z]+)([A-Z][a-z])'),
          (match) => '${match.group(1)}_${match.group(2)}',
        )
        .replaceAllMapped(
          RegExp(r'([a-z0-9])([A-Z])'),
          (match) => '${match.group(1)}_${match.group(2)}',
        )
        .toLowerCase();
  }

  /// Registry for complex entities that require strict model validation
  /// or specialized mapping logic. Most of the 40+ tables do not need to be here.
  static final Map<String, Map<String, dynamic> Function(Map<String, dynamic>)>
  _payloadMappers = {
    'SystemConstant': (data) =>
        SystemConstant.fromServerMap(data).toDatabaseMap(),
    'CompanyTable': (data) => Company.fromServerMap(data).toMap(),
  };

  bool _isSafeSqlIdentifier(String value) {
    return RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(value);
  }

  Future<Map<String, _DbColumnInfo>> _getTableSchema(
    Database db,
    String tableName,
  ) async {
    final cached = _tableSchemaCache[tableName];
    if (cached != null) return cached;

    if (!_isSafeSqlIdentifier(tableName)) {
      throw StateError('Unsafe table name received from sync: $tableName');
    }

    final rows = await db.rawQuery('PRAGMA table_info($tableName)');
    if (rows.isEmpty) {
      throw StateError(
        'Unknown local table "$tableName" for received sync entity',
      );
    }

    final schema = <String, _DbColumnInfo>{};
    for (final row in rows) {
      final columnName = row['name']?.toString();
      if (columnName == null || columnName.isEmpty) continue;

      schema[columnName] = _DbColumnInfo(
        name: columnName,
        type: row['type']?.toString() ?? '',
      );
    }

    _tableSchemaCache[tableName] = schema;
    return schema;
  }

  Map<String, dynamic> _normalizeServerPayloadKeys(
    Map<String, dynamic> serverPayload,
  ) {
    final result = <String, dynamic>{};
    for (final entry in serverPayload.entries) {
      result[_camelToSnake(entry.key)] = entry.value;
    }
    return result;
  }

  dynamic _coerceValueForColumn(dynamic value, _DbColumnInfo column) {
    if (value == null) return null;
    if (value is bool) return value ? 1 : 0;

    if (value is DateTime) {
      return column.isInteger
          ? value.millisecondsSinceEpoch
          : value.toIso8601String();
    }

    if (value is Map || value is List) {
      return jsonEncode(value);
    }

    if (column.isInteger) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) {
        final trimmed = value.trim();
        if (trimmed.isEmpty) return null;
        return int.tryParse(trimmed) ??
            double.tryParse(trimmed)?.toInt() ??
            DateTime.tryParse(trimmed)?.millisecondsSinceEpoch ??
            value;
      }
    }

    if (column.isReal) {
      if (value is num) return value.toDouble();
      if (value is String) {
        final trimmed = value.trim();
        if (trimmed.isEmpty) return null;
        return double.tryParse(trimmed) ?? value;
      }
    }

    if (column.isText && value is! String) {
      return value.toString();
    }

    return value;
  }

  Map<String, dynamic> _filterAndCoercePayloadForTable({
    required String tableName,
    required Map<String, _DbColumnInfo> tableSchema,
    required Map<String, dynamic> mappedPayload,
  }) {
    final result = <String, dynamic>{};
    final ignoredFields = <String>[];

    for (final entry in mappedPayload.entries) {
      final exactColumn = tableSchema[entry.key];
      final normalizedColumn = tableSchema[_camelToSnake(entry.key)];
      final column = exactColumn ?? normalizedColumn;

      if (column == null) {
        ignoredFields.add(entry.key);
        continue;
      }

      result[column.name] = _coerceValueForColumn(entry.value, column);
    }

    if (ignoredFields.isNotEmpty) {
      developer.log(
        'SyncService: Ignored ${ignoredFields.length} unknown field(s) '
        'for $tableName: ${ignoredFields.take(8).join(', ')}',
      );
    }

    return result;
  }

  /// Converts a server payload into a SQLite-ready row.
  ///
  /// Dart/Flutter cannot safely use Java-style runtime class reflection in
  /// production builds, so this uses a small explicit mapper registry for
  /// complex entities and cached SQLite schema metadata for every other table.
  Future<Map<String, dynamic>> _convertServerPayloadToDbMap({
    required Database db,
    required String entityName,
    required String tableName,
    required Map<String, dynamic> serverPayload,
    Map<String, _DbColumnInfo>? tableSchema,
  }) async {
    final mapper = _payloadMappers[entityName];
    final mappedPayload = mapper != null
        ? mapper(serverPayload)
        : _normalizeServerPayloadKeys(serverPayload);
    final schema = tableSchema ?? await _getTableSchema(db, tableName);

    return _filterAndCoercePayloadForTable(
      tableName: tableName,
      tableSchema: schema,
      mappedPayload: mappedPayload,
    );
  }

  /// Apply a received sync event to the local database.
  ///
  /// Uses model-aware deserialization for known entities (fromServerMap → toDatabaseMap)
  /// and wraps the DB operation + sync event log in a transaction for atomicity.
  ///
  /// Conflict resolution: **last-write-wins**.
  Future<void> _applyReceivedEvent(SyncEventModel event) async {
    try {
      // Skip events from this node (avoid round-trip syncing)
      if (_sourceNode != null && event.sourceNode == _sourceNode) {
        developer.log('⏭️ Skipping own event: ${event.sourceKey}');
        return;
      }

      final db = await databaseService.database;
      final rawPayload = jsonDecode(event.payload) as Map<String, dynamic>;

      // Map incoming PascalCase entity name back to local SQLite snake_case table
      final tableName = await resolveTableName(event.entityName);
      final operation = event.operation.toUpperCase();
      final tableSchema = await _getTableSchema(db, tableName);

      // Convert payload using model-aware pipeline (or fallback)
      final entityData = await _convertServerPayloadToDbMap(
        db: db,
        entityName: event.entityName,
        tableName: tableName,
        serverPayload: rawPayload,
        tableSchema: tableSchema,
      );

      // Extract sync_key — also check camelCase key from server payload
      final syncKey =
          entityData['sync_key']?.toString() ??
          rawPayload['syncKey']?.toString();

      // Ensure sync_key is in the DB map
      if (syncKey != null) {
        entityData['sync_key'] = syncKey;
      }

      // Remove remote ID so local SQLite auto-increments
      entityData.remove('id');

      developer.log(
        '📥 Applying $operation on $tableName (syncKey=$syncKey, '
        'entity=${event.entityName})',
      );

      // Wrap in transaction for atomicity
      await db.transaction((txn) async {
        List<Map<String, Object?>> existing = [];
        if (syncKey != null && tableSchema.containsKey('sync_key')) {
          existing = await txn.query(
            tableName,
            where: 'sync_key = ?',
            whereArgs: [syncKey],
            limit: 1,
          );
        }

        // Fallback matching for singleton tables that may not have a local
        // sync_key yet from older installs.
        if (existing.isEmpty) {
          if (tableName == 'company_table' && tableSchema.containsKey('id')) {
            final remoteId = rawPayload['id'];
            if (remoteId != null) {
              existing = await txn.query(
                tableName,
                where: 'id = ?',
                whereArgs: [remoteId],
                limit: 1,
              );
            }
          } else if (tableName == 'system_constant' &&
              tableSchema.containsKey('company')) {
            final companyId = entityData['company'] ?? rawPayload['company'];
            if (companyId != null) {
              existing = await txn.query(
                tableName,
                where: 'company = ?',
                whereArgs: [companyId],
                limit: 1,
              );
            }
          }
        }

        switch (operation) {
          case 'INSERT':
            if (existing.isEmpty) {
              await txn.insert(
                tableName,
                entityData,
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
              developer.log('📥 Applied INSERT on $tableName');
            } else {
              final localId = existing.first['id'];
              await txn.update(
                tableName,
                entityData,
                where: 'id = ?',
                whereArgs: [localId],
              );
              developer.log(
                '📥 Applied INSERT→UPDATE on $tableName (already existed)',
              );
            }
            break;

          case 'UPDATE':
            if (existing.isNotEmpty) {
              final localId = existing.first['id'];
              await txn.update(
                tableName,
                entityData,
                where: 'id = ?',
                whereArgs: [localId],
              );
              developer.log('📥 Applied UPDATE on $tableName');
            } else {
              await txn.insert(
                tableName,
                entityData,
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
              developer.log('📥 Applied UPDATE→INSERT on $tableName');
            }
            break;

          case 'DELETE':
            if (existing.isNotEmpty) {
              final localId = existing.first['id'];
              await txn.delete(
                tableName,
                where: 'id = ?',
                whereArgs: [localId],
              );
              developer.log('📥 Applied DELETE on $tableName');
            }
            break;

          default:
            developer.log('⚠️ Unknown operation: $operation');
        }
      });
    } catch (e) {
      developer.log(
        '❌ SyncService: Error applying event '
        '${event.entityName}#${event.entityId}: $e',
      );
      rethrow;
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

  /// Set user credentials for pull requests.
  void setCredentials({required String username}) {
    _username = username;
    developer.log('🔄 SyncService: Credentials set for user: $username');
  }
}
