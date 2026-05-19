import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;
import 'package:savvy_stock/core/services/sync/models/sync_event_model.dart';

class SyncPullException implements Exception {
  final String message;

  const SyncPullException(this.message);

  @override
  String toString() => message;
}

class _PullPageResult {
  final List<SyncEventModel> events;
  final int offset;
  final int returned;
  final bool hasMore;
  final int nextOffset;
  final String? lastEntity;

  const _PullPageResult({
    required this.events,
    required this.offset,
    required this.returned,
    required this.hasMore,
    required this.nextOffset,
    this.lastEntity,
  });
}

/// Handles receiving (pulling) sync events from remote target servers.
///
/// Supports:
/// - Bootstrap pulls with offset pagination (`id = 0`)
/// - Incremental pulls for authenticated users (`id > 0`)
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
      'ngrok-skip-browser-warning': 'true',
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

  Uri _buildPullUri(
    String targetUrl, {
    required String userName,
    required String sourceAddress,
    int? id,
    int? offset,
  }) {
    final normalizedBaseUrl = _normalizeBaseUrl(targetUrl);
    final normalizedId = id ?? 0;
    final queryParameters = <String, String>{
      'userName': userName,
      'sourceAddress': sourceAddress,
      'id': normalizedId.toString(),
    };

    if (normalizedId == 0) {
      queryParameters['offset'] = (offset ?? 0).toString();
    } else if (offset != null && offset > 0) {
      queryParameters['offset'] = offset.toString();
    }

    final endpoint = '$normalizedBaseUrl/api/sync/pull';
    return Uri.parse(endpoint).replace(queryParameters: queryParameters);
  }

  dynamic _decodeResponseBody(String responseBody) {
    final trimmed = responseBody.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    try {
      return jsonDecode(trimmed);
    } catch (_) {
      throw const SyncPullException(
        'Sync pull returned a non-JSON response body.',
      );
    }
  }

  dynamic _extractEventsNode(dynamic bodyData) {
    if (bodyData is List) {
      return bodyData;
    }

    if (bodyData is! Map<String, dynamic>) {
      return null;
    }

    final directNode =
        bodyData['savedItem'] ??
        bodyData['savedEvent'] ??
        bodyData['saved_item'] ??
        bodyData['saved_event'] ??
        bodyData['events'] ??
        bodyData['sync_events'] ??
        bodyData['syncEvents'];

    if (directNode != null) {
      return directNode;
    }

    final nestedNodes = [
      bodyData['data'],
      bodyData['result'],
      bodyData['payload'],
    ];
    for (final nestedNode in nestedNodes) {
      final extracted = _extractEventsNode(nestedNode);
      if (extracted != null) {
        return extracted;
      }
    }

    return null;
  }

  String? _extractFailureMessage(dynamic bodyData) {
    if (bodyData is! Map<String, dynamic>) {
      return null;
    }

    final status = bodyData['status']?.toString().trim();
    if (status != null && status.isNotEmpty) {
      final normalizedStatus = status.toLowerCase();
      const successStates = {'ok', 'success', 'true'};
      if (!successStates.contains(normalizedStatus)) {
        final message = bodyData['message']?.toString().trim();
        if (message != null && message.isNotEmpty) {
          return message;
        }
        return status;
      }
    }

    final success = bodyData['success'];
    if (success is bool && !success) {
      final message = bodyData['message']?.toString().trim();
      if (message != null && message.isNotEmpty) {
        return message;
      }
      return 'Sync pull failed on the server.';
    }

    return null;
  }

  int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  bool _asBool(dynamic value) {
    if (value is bool) return value;
    final normalized = value?.toString().trim().toLowerCase();
    return normalized == 'true';
  }

  _PullPageResult _parsePullPage(
    http.Response response, {
    required int requestedOffset,
  }) {
    final bodyData = _decodeResponseBody(response.body);
    if (bodyData == null) {
      return _PullPageResult(
        events: const [],
        offset: requestedOffset,
        returned: 0,
        hasMore: false,
        nextOffset: requestedOffset,
      );
    }

    final failureMessage = _extractFailureMessage(bodyData);
    if (failureMessage != null) {
      throw SyncPullException(
        _buildRawResponseDebugMessage(
          response,
          prefix: 'Sync pull returned success=false.',
        ),
      );
    }

    final eventsNode = _extractEventsNode(bodyData);
    List<SyncEventModel> events = const [];

    if (eventsNode == null) {
      events = const [];
    } else if (eventsNode is List) {
      events = eventsNode.whereType<Map>().map((event) {
        return SyncEventModel.fromMap(Map<String, dynamic>.from(event));
      }).toList();
    } else if (eventsNode is Map && eventsNode.isEmpty) {
      events = const [];
    } else {
      throw SyncPullException(
        _buildRawResponseDebugMessage(
          response,
          prefix:
              'Sync pull returned 200 but the event payload was not a list.',
        ),
      );
    }

    if (bodyData is! Map<String, dynamic>) {
      return _PullPageResult(
        events: events,
        offset: requestedOffset,
        returned: events.length,
        hasMore: false,
        nextOffset: requestedOffset + events.length,
      );
    }

    final bootstrapNode =
        bodyData['bootstrap'] ??
        bodyData['bootStrap'] ??
        bodyData['boot_strap'];

    if (bootstrapNode is! Map) {
      return _PullPageResult(
        events: events,
        offset: requestedOffset,
        returned: events.length,
        hasMore: false,
        nextOffset: requestedOffset + events.length,
      );
    }

    final bootstrapMap = Map<String, dynamic>.from(bootstrapNode);
    final offset = _asInt(bootstrapMap['offset']) ?? requestedOffset;
    final returned = _asInt(bootstrapMap['returned']) ?? events.length;
    final hasMore = _asBool(bootstrapMap['hasMore']);
    final nextOffset =
        _asInt(bootstrapMap['nextOffset']) ?? (offset + returned);
    final lastEntity = bootstrapMap['lastEntity']?.toString();

    return _PullPageResult(
      events: events,
      offset: offset,
      returned: returned,
      hasMore: hasMore,
      nextOffset: nextOffset,
      lastEntity: lastEntity,
    );
  }

  List<SyncEventModel> _parsePulledEvents(
    http.Response response, {
    int requestedOffset = 0,
  }) {
    final page = _parsePullPage(response, requestedOffset: requestedOffset);

    developer.log(
      'SyncReceiver: Parsed ${page.events.length} events '
      '(offset=${page.offset}, returned=${page.returned}, hasMore=${page.hasMore}, '
      'nextOffset=${page.nextOffset}${page.lastEntity != null ? ', lastEntity=${page.lastEntity}' : ''})',
    );

    return page.events;
  }

  Future<List<SyncEventModel>> _pullBootstrapEvents(
    String targetUrl, {
    required String userName,
    required String sourceAddress,
  }) async {
    final allEvents = <SyncEventModel>[];
    var offset = 0;
    var pageCount = 0;

    while (true) {
      final url = _buildPullUri(
        targetUrl,
        userName: userName,
        sourceAddress: sourceAddress,
        id: 0,
        offset: offset,
      );

      final response = await httpClient
          .get(url, headers: _buildHeaders())
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final page = _parsePullPage(response, requestedOffset: offset);
        pageCount++;
        allEvents.addAll(page.events);

        developer.log(
          'SyncReceiver: Bootstrap page $pageCount '
          '(offset=${page.offset}, returned=${page.returned}, total=${allEvents.length}, '
          'hasMore=${page.hasMore}, nextOffset=${page.nextOffset}'
          '${page.lastEntity != null ? ', lastEntity=${page.lastEntity}' : ''})',
        );

        if (!page.hasMore) {
          developer.log(
            'SyncReceiver: Pulled ${allEvents.length} bootstrap events '
            'from $targetUrl in $pageCount page(s)',
          );
          return allEvents;
        }

        if (page.nextOffset <= offset) {
          throw SyncPullException(
            'Bootstrap pull did not advance offset. '
            'Current offset=$offset, nextOffset=${page.nextOffset}.',
          );
        }

        offset = page.nextOffset;
        continue;
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        developer.log(
          'SyncReceiver: Bootstrap auth failed '
          '(${response.statusCode}) at $url',
        );
        throw SyncPullException(
          _buildRawResponseDebugMessage(
            response,
            prefix: 'Sync pull denied the request.',
          ),
        );
      }

      developer.log(
        'SyncReceiver: Bootstrap pull failed status=${response.statusCode} '
        'at $url: ${response.body}',
      );
      throw SyncPullException(
        _buildRawResponseDebugMessage(
          response,
          prefix: 'Sync pull returned an unexpected status.',
        ),
      );
    }
  }

  Future<List<SyncEventModel>> _pullIncrementalEvents(
    String targetUrl, {
    required String userName,
    required String sourceAddress,
    int? id,
  }) async {
    final url = _buildPullUri(
      targetUrl,
      userName: userName,
      sourceAddress: sourceAddress,
      id: id,
    );

    final response = await httpClient
        .get(url, headers: _buildHeaders())
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final events = _parsePulledEvents(response);
      developer.log('SyncReceiver: Pulled ${events.length} events from $url');
      return events;
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      developer.log(
        'SyncReceiver: Auth failed (${response.statusCode}) at $url',
      );
      throw SyncPullException(
        _buildRawResponseDebugMessage(
          response,
          prefix: 'Sync pull denied the request.',
        ),
      );
    }

    developer.log(
      'SyncReceiver: Pull failed status=${response.statusCode} at $url: '
      '${response.body}',
    );
    throw SyncPullException(
      _buildRawResponseDebugMessage(
        response,
        prefix: 'Sync pull returned an unexpected status.',
      ),
    );
  }

  /// Pull new sync events from a target server URL.
  ///
  /// Bootstrap mode uses `id = 0` and pages via `offset` until
  /// `bootstrap.hasMore` becomes false. Incremental mode uses the real user id
  /// and typically returns a single page.
  Future<List<SyncEventModel>> pullEvents(
    String targetUrl, {
    required String userName,
    required String sourceAddress,
    int? id,
    List<String>? sourceAddressCandidates,
    bool throwOnError = false,
  }) async {
    if (targetUrl.isEmpty) return [];

    try {
      SyncPullException? lastFailure;
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

        try {
          if ((id ?? 0) == 0) {
            return await _pullBootstrapEvents(
              targetUrl,
              userName: userName,
              sourceAddress: currentSourceAddress,
            );
          }

          return await _pullIncrementalEvents(
            targetUrl,
            userName: userName,
            sourceAddress: currentSourceAddress,
            id: id,
          );
        } on SyncPullException catch (e) {
          lastFailure = e;
          final isLastSourceAddress =
              sourceIndex == candidateSourceAddresses.length - 1;
          if (!isLastSourceAddress) {
            developer.log(
              'SyncReceiver: Retrying pull with alternate sourceAddress '
              '${candidateSourceAddresses[sourceIndex + 1]}',
            );
            continue;
          }

          if (throwOnError) {
            rethrow;
          }
          return [];
        }
      }

      if (throwOnError && lastFailure != null) {
        throw lastFailure;
      }
      return [];
    } on SyncPullException {
      rethrow;
    } catch (e) {
      developer.log('SyncReceiver: Pull error from $targetUrl: $e');
      if (throwOnError) {
        throw SyncPullException('Sync pull error from $targetUrl: $e');
      }
      return [];
    }
  }

  String _buildRawResponseDebugMessage(
    http.Response response, {
    required String prefix,
  }) {
    final status = response.statusCode;
    final requestUrl = response.request?.url.toString() ?? '(unknown)';
    final contentType = response.headers['content-type'] ?? '(missing)';
    final headers = response.headers.entries
        .map((entry) => '${entry.key}: ${entry.value}')
        .join(', ');
    final body = response.body.trim();
    final normalizedBody = body.isEmpty ? '(empty)' : _truncateForDebug(body);

    return '$prefix '
        'status=$status; '
        'url=$requestUrl; '
        'content-type=$contentType; '
        'headers={$headers}; '
        'body=$normalizedBody';
  }

  String _truncateForDebug(String value, {int maxLength = 4000}) {
    final normalized = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= maxLength) {
      return normalized;
    }
    return '${normalized.substring(0, maxLength)}...';
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
