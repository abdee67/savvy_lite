import 'dart:convert';
import 'dart:developer' as developer;

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
    final headers = <String, String>{};
    headers.addAll({
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    });
    if (authToken != null && authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    return headers;
  }

  String _normalizeBaseUrl(String targetUrl) {
    return targetUrl.endsWith('/')
        ? targetUrl.substring(0, targetUrl.length - 1)
        : targetUrl;
  }

  List<Uri> _buildPullUris(
    String targetUrl, {
    required String userName,
    required String sourceAddress,
  }) {
    final normalizedBaseUrl = _normalizeBaseUrl(targetUrl);
    final queryParameters = {
      'userName': userName,
      'sourceAddress': sourceAddress,
    };

    final endpoints = <String>{'$normalizedBaseUrl/api/sync/pull'};

    return endpoints
        .map(
          (endpoint) =>
              Uri.parse(endpoint).replace(queryParameters: queryParameters),
        )
        .toList();
  }

  List<SyncEventModel> _parsePulledEvents(String responseBody) {
    final bodyData = jsonDecode(responseBody);
    List<dynamic> eventsList = [];
    if (bodyData is List) {
      eventsList = bodyData;
    } else if (bodyData is Map<String, dynamic>) {
      // Server may return events under different keys depending on endpoint
      eventsList =
          bodyData['savedItem'] ??
          bodyData['saved_item'] ??
          bodyData['events'] ??
          [];
    }

    developer.log(
      'SyncReceiver: Parsed ${eventsList.length} events from response',
    );

    return eventsList.map((e) {
      return SyncEventModel.fromMap(e as Map<String, dynamic>);
    }).toList();
  }

  /// Pull new sync events from a target server URL since [lastSyncTime].
  ///
  /// Returns a list of [SyncEventModel] received from the server.
  /// Events are ordered by creation time, so processing them in order
  /// maintains correct sequencing (INSERT before UPDATE/DELETE).
  Future<List<SyncEventModel>> pullEvents(
    String targetUrl, {
    required String userName,
    required String sourceAddress,
    List<String>? sourceAddressCandidates,
  }) async {
    if (targetUrl.isEmpty) return [];

    try {
      final attemptedSourceAddresses = <String>{};
      final candidateSourceAddresses = <String>[
        sourceAddress,
        ...?sourceAddressCandidates,
      ].where((candidate) => attemptedSourceAddresses.add(candidate)).toList();

      for (
        var sourceIndex = 0;
        sourceIndex < candidateSourceAddresses.length;
        sourceIndex++
      ) {
        final currentSourceAddress = candidateSourceAddresses[sourceIndex];
        final pullUris = _buildPullUris(
          targetUrl,
          userName: userName,
          sourceAddress: currentSourceAddress,
        );

        for (var index = 0; index < pullUris.length; index++) {
          final url = pullUris[index];
          final response = await httpClient
              .get(url, headers: _buildHeaders())
              .timeout(const Duration(seconds: 30));

          if (response.statusCode == 200) {
            final events = _parsePulledEvents(response.body);
            developer.log(
              'SyncReceiver: Pulled ${events.length} events from $url',
            );
            return events;
          }

          if (response.statusCode == 401 || response.statusCode == 403) {
            developer.log(
              'SyncReceiver: Auth failed (${response.statusCode}) at $url',
            );
            return [];
          }

          developer.log(
            'SyncReceiver: Pull failed status=${response.statusCode} at $url: '
            '${response.body}',
          );

          final isLastEndpointAttempt = index == pullUris.length - 1;
          final shouldRetryLegacyEndpoint =
              !isLastEndpointAttempt &&
              (response.statusCode >= 500 ||
                  response.statusCode == 400 ||
                  response.statusCode == 404 ||
                  response.statusCode == 405);

          if (shouldRetryLegacyEndpoint) {
            developer.log(
              'SyncReceiver: Retrying pull with legacy endpoint for $targetUrl',
            );
            continue;
          }

          final isLastSourceAddress =
              sourceIndex == candidateSourceAddresses.length - 1;
          final shouldRetryNextSourceAddress =
              isLastEndpointAttempt &&
              !isLastSourceAddress &&
              (response.statusCode >= 500 ||
                  response.statusCode == 400 ||
                  response.statusCode == 404 ||
                  response.statusCode == 405);

          if (shouldRetryNextSourceAddress) {
            developer.log(
              'SyncReceiver: Retrying pull with alternate sourceAddress '
              '${candidateSourceAddresses[sourceIndex + 1]}',
            );
            break;
          }

          return [];
        }
      }

      return [];
    } catch (e) {
      developer.log('SyncReceiver: Pull error from $targetUrl: $e');
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
      developer.log('SyncReceiver: Node status report error: $e');
      return false;
    }
  }

  /// Notify the server that the given sync events were successfully received
  /// and applied locally. Uses the server's own sync event IDs (source_id).
  ///
  /// Endpoint: POST /updateSyncEvent
  Future<bool> updateSyncEvent(
    String targetUrl,
    List<String> serverSyncEventIds,
  ) async {
    if (targetUrl.isEmpty || serverSyncEventIds.isEmpty) return false;

    try {
      final url = Uri.parse('$targetUrl/api/sync/updateSyncEvent');

      final response = await httpClient
          .post(
            url,
            headers: _buildHeaders(),
            body: jsonEncode(serverSyncEventIds),
          )
          .timeout(const Duration(seconds: 15));

      developer.log(
        'SyncReceiver: Acknowledged ${serverSyncEventIds.length} events '
        'status=${response.statusCode}',
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      developer.log('SyncReceiver: updateSyncEvent error: $e');
      return false;
    }
  }
}
