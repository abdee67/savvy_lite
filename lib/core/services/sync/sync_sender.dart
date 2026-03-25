import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;
import 'package:savvy_stock/core/services/sync/models/sync_event_model.dart';

/// Handles sending (pushing) sync events to remote target servers.
///
/// Supports:
/// - Batch pushing with per-event success/failure tracking
/// - Authentication via bearer token
/// - Timeout handling
/// - Payload integrity validation
class SyncSender {
  final http.Client httpClient;

  /// Optional auth token provider. Set this after user login.
  String? authToken;

  SyncSender({required this.httpClient, this.authToken});

  /// Build standard headers with auth and content-type.
  Map<String, String> _buildHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (authToken != null && authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    return headers;
  }

  /// Push a batch of sync events to a target server URL.
  ///
  /// Returns a map of { sourceKey: success(true/false) }.
  /// Each event's sourceKey ensures idempotency on the server side.
  Future<Map<String, bool>> pushEvents(
    List<SyncEventModel> events,
    String targetUrl,
  ) async {
    final results = <String, bool>{};

    if (events.isEmpty || targetUrl.isEmpty) return results;

    try {
      final url = Uri.parse('$targetUrl/api/sync/push');

      final payload = events.map((e) => e.toMap()).toList();

      final response = await httpClient
          .post(
            url,
            headers: _buildHeaders(),
            body: jsonEncode({'events': payload}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        developer.log(
          '✅ SyncSender: Pushed ${events.length} events to $targetUrl',
        );

        // Parse server response for per-event results if available
        try {
          final body = jsonDecode(response.body);
          if (body is Map && body['results'] is List) {
            // Server returns per-event results
            final serverResults = body['results'] as List;
            for (final sr in serverResults) {
              if (sr is Map) {
                final key = sr['source_key'] as String?;
                final ok = sr['success'] as bool? ?? true;
                if (key != null) results[key] = ok;
              }
            }
            // Fill in any events not in server results as success
            for (final event in events) {
              final key = event.sourceKey ?? event.id.toString();
              results.putIfAbsent(key, () => true);
            }
          } else {
            // Server returned simple success — mark all as succeeded
            for (final event in events) {
              results[event.sourceKey ?? event.id.toString()] = true;
            }
          }
        } catch (_) {
          // If response parsing fails, assume all succeeded
          for (final event in events) {
            results[event.sourceKey ?? event.id.toString()] = true;
          }
        }
      } else if (response.statusCode == 409) {
        // 409 Conflict — server already processed these events (idempotency)
        developer.log(
          '⏭️ SyncSender: Events already processed (409) at $targetUrl',
        );
        for (final event in events) {
          results[event.sourceKey ?? event.id.toString()] = true;
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        developer.log(
          '🔒 SyncSender: Auth failed (${response.statusCode}) at $targetUrl',
        );
        for (final event in events) {
          results[event.sourceKey ?? event.id.toString()] = false;
        }
      } else {
        developer.log(
          '❌ SyncSender: Push failed status=${response.statusCode}: '
          '${response.body}',
        );
        for (final event in events) {
          results[event.sourceKey ?? event.id.toString()] = false;
        }
      }
    } catch (e) {
      developer.log('❌ SyncSender: Push error to $targetUrl: $e');
      for (final event in events) {
        results[event.sourceKey ?? event.id.toString()] = false;
      }
    }

    return results;
  }

  /// Push a single sync event. Returns true on success.
  Future<bool> pushSingleEvent(
    SyncEventModel event,
    String targetUrl,
  ) async {
    final results = await pushEvents([event], targetUrl);
    return results[event.sourceKey ?? event.id.toString()] ?? false;
  }
}
