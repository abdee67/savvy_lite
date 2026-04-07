import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;
import 'package:savvy_stock/core/services/sync/sync_repository.dart';
import 'package:savvy_stock/features/auth/repo/auth_repo.dart';

/// Progress info emitted during initial data sync.
class InitialSyncProgress {
  final int totalEvents;
  final int processedEvents;
  final String currentTable;
  final String message;

  const InitialSyncProgress({
    required this.totalEvents,
    required this.processedEvents,
    required this.currentTable,
    required this.message,
  });

  double get percentage =>
      totalEvents > 0 ? (processedEvents / totalEvents * 100) : 0;

  @override
  String toString() =>
      'InitialSyncProgress($processedEvents/$totalEvents, table=$currentTable)';
}

/// Dependency-ordered list of tables the server may send.
/// The server assigns sequence numbers following this order, but this list
/// is also used for logging and progress reporting.

/// Service that handles the one-time bulk download of ALL company data
/// during a first-time remote login.
///
/// Flow:
/// 1. Call the Java server's login/initial-data endpoint
/// 2. Store all returned events in `sync_event` table (crash-safe)
/// 3. Process events in `sequence_number` order
/// 4. For each event: decode payload → upsert into target table via sync_key
/// 5. Mark processed events as SUCCESS
///
/// The UI is blocked during this entire process with progress updates.
class InitialDataSyncService {
  final AuthRepository authRepository;
  final SyncRepository syncRepository;
  final http.Client httpClient;

  InitialDataSyncService({
    required this.authRepository,
    required this.syncRepository,
    required this.httpClient,
  });

  /// Main entry point: download all company data and populate local DB.
  ///
  /// [serverBaseUrl] — Java server base URL
  /// [username] — the login username
  /// [passwordHash] — the hashed password
  /// [onProgress] — callback for UI progress updates
  ///
  /// Returns the local user ID on success, or null on failure.
  Future<int?> downloadAndApply({
    required String serverBaseUrl,
    required String username,
    required String passwordHash,
    required void Function(InitialSyncProgress) onProgress,
  }) async {
    try {
      // ─── Step 1: Download sync events from server ──────────────────
      onProgress(
        const InitialSyncProgress(
          totalEvents: 0,
          processedEvents: 0,
          currentTable: '',
          message: 'Connecting to server...',
        ),
      );

      final events = await _fetchEventsFromServer(
        serverBaseUrl: serverBaseUrl,
        username: username,
        passwordHash: passwordHash,
      );

      if (events.isEmpty) {
        developer.log('InitialDataSync: Server returned no events');
        return null;
      }

      developer.log(
        'InitialDataSync: Received ${events.length} events from server',
      );

      // ─── Step 2: Store all events in sync_event table ──────────────
      onProgress(
        InitialSyncProgress(
          totalEvents: events.length,
          processedEvents: 0,
          currentTable: '',
          message: 'Saving ${events.length} records...',
        ),
      );

      await authRepository.storeEventsLocally(events);

      developer.log('InitialDataSync: All events stored in sync_event table');

      // ─── Step 3: Process events in sequence order ──────────────────
      final localUserId = await authRepository.processStoredEvents(
        totalEvents: events.length,
        onProgress: onProgress,
      );

      developer.log('✅ InitialDataSync: Complete. Local user ID: $localUserId');

      return localUserId;
    } catch (e, stackTrace) {
      developer.log('❌ InitialDataSync: Failed: $e', stackTrace: stackTrace);
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  STEP 1: FETCH FROM SERVER
  // ═══════════════════════════════════════════════════════════════════════

  /// Call the Java server login endpoint which returns ALL company data
  /// as sync events with sequence numbers.
  Future<List<Map<String, dynamic>>> _fetchEventsFromServer({
    required String serverBaseUrl,
    required String username,
    required String passwordHash,
  }) async {
    final url = Uri.parse('$serverBaseUrl/api/auth/login');

    developer.log('InitialDataSync: Calling $url');

    final response = await httpClient
        .post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'username': username,
            'password_hash': passwordHash,
          }),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = jsonDecode(response.body);

      // Support both { "success": true, "events": [...] } and raw List [...]
      if (body is List) {
        return body.whereType<Map<String, dynamic>>().toList();
      } else if (body is Map<String, dynamic>) {
        final success = body['success'] as bool? ?? false;
        if (!success) {
          developer.log(
            'InitialDataSync: Server returned success=false: '
            '${body['message']}',
          );
          return [];
        }

        final eventsList = body['events'] as List<dynamic>? ?? [];
        return eventsList.whereType<Map<String, dynamic>>().toList();
      }
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      developer.log('InitialDataSync: Auth failed (${response.statusCode})');
    } else {
      developer.log(
        'InitialDataSync: Server error ${response.statusCode}: '
        '${response.body}',
      );
    }

    return [];
  }



}
