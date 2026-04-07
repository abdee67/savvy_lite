import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:savvy_stock/core/services/sync/models/sync_event_model.dart';

/// Handles receiving (pulling) sync events from remote target servers.
///
/// Supports:
/// - Incremental pulls using lastSyncTime
/// - Authentication via bearer token
/// - Node status reporting
class SyncReceiver {
  final http.Client httpClient;

  /// Optional auth token provider. Set this after user login.
  String? authToken;

  SyncReceiver({required this.httpClient, this.authToken});

  /// Build standard headers.
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

  /// Pull new sync events from a target server URL since [lastSyncTime].
  ///
  /// Returns a list of [SyncEventModel] received from the server.
  /// Events are ordered by creation time, so processing them in order
  /// maintains correct sequencing (INSERT before UPDATE/DELETE).
  Future<List<SyncEventModel>> pullEvents(
    String targetUrl, {
    String? lastSyncTime,
  }) async {
    if (targetUrl.isEmpty) return [];

    try {
      final queryParams = <String, String>{};
      if (lastSyncTime != null && lastSyncTime.isNotEmpty) {
        queryParams['since'] = lastSyncTime;
      }

      final url = Uri.parse(
        '$targetUrl/api/sync/pull',
      ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await httpClient
          .get(url, headers: _buildHeaders())
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        List<dynamic> eventsList = [];
        if (body is List) {
          eventsList = body;
        } else if (body is Map<String, dynamic>) {
          eventsList = body['events'] ?? [];
        }

        developer.log(
          '📥 SyncReceiver: Pulled ${eventsList.length} events from $targetUrl',
        );

        return eventsList.map((e) {
          return SyncEventModel.fromMap(e as Map<String, dynamic>);
        }).toList();
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        developer.log(
          '🔒 SyncReceiver: Auth failed (${response.statusCode}) at $targetUrl',
        );
        return [];
      } else {
        developer.log(
          '❌ SyncReceiver: Pull failed status=${response.statusCode}: '
          '${response.body}',
        );
        return [];
      }
    } catch (e) {
      developer.log('❌ SyncReceiver: Pull error from $targetUrl: $e');
      return [];
    }
  }

  /// Report this node's status to the server.
  Future<bool> reportNodeStatus(
    String targetUrl,
    String nodeId,
    String company,
  ) async {
    if (targetUrl.isEmpty) return false;

    try {
      final url = Uri.parse('$targetUrl/api/sync/node-status');

      final response = await httpClient
          .post(
            url,
            headers: _buildHeaders(),
            body: jsonEncode({
              'node_id': nodeId,
              'company': company,
              'last_seen': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      developer.log('❌ SyncReceiver: Node status report error: $e');
      return false;
    }
  }
}
