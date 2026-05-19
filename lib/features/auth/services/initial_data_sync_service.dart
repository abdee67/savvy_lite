import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;
import 'package:savvy_stock/core/services/sync/sync_service.dart';
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

class InitialDataSyncResult {
  final int? localUserId;
  final String? errorMessage;

  const InitialDataSyncResult._({this.localUserId, this.errorMessage});

  const InitialDataSyncResult.success(int userId) : this._(localUserId: userId);

  const InitialDataSyncResult.failure(String message)
    : this._(errorMessage: message);

  bool get isSuccess => localUserId != null;
}

class _BootstrapFetchResult {
  final String companyServerBaseUrl;

  const _BootstrapFetchResult({required this.companyServerBaseUrl});
}

class _InitialSyncException implements Exception {
  final String message;

  const _InitialSyncException(this.message);

  @override
  String toString() => message;
}

/// Handles first-time remote bootstrap for a user that is not yet on this
/// device.
///
/// Flow:
/// 1. Call the default server's `/url` endpoint with the entered username
/// 2. Read the returned company URL and replace the current default URL
/// 3. Pull the user's sync data from that company URL using the shared sync engine
/// 4. Re-query the local DB for the inserted user
class InitialDataSyncService {
  final AuthRepository authRepository;
  final SyncService syncService;
  final http.Client httpClient;

  InitialDataSyncService({
    required this.authRepository,
    required this.syncService,
    required this.httpClient,
  });

  Future<InitialDataSyncResult> downloadAndApply({
    required String serverBaseUrl,
    required String username,
    required void Function(InitialSyncProgress) onProgress,
  }) async {
    try {
      onProgress(
        const InitialSyncProgress(
          totalEvents: 3,
          processedEvents: 0,
          currentTable: '',
          message: 'Resolving company server...',
        ),
      );

      final bootstrapResult = await _fetchBootstrapConfig(
        defaultServerBaseUrl: serverBaseUrl,
        username: username,
      );

      developer.log(
        'InitialDataSync: Bootstrap resolved company URL: '
        '${bootstrapResult.companyServerBaseUrl}',
      );

      await authRepository.updateDefaultServerBaseUrl(
        bootstrapResult.companyServerBaseUrl,
      );

      final persistedServerBaseUrl = await authRepository.getServerBaseUrl();
      if (persistedServerBaseUrl == null || persistedServerBaseUrl.isEmpty) {
        throw const _InitialSyncException(
          'Company URL was resolved but could not be loaded from system_url_config after update.',
        );
      }

      final pullTargetUrl = _normalizeBaseUrl(persistedServerBaseUrl);
      developer.log(
        'InitialDataSync: Pulling initial user data from saved URL: '
        '$pullTargetUrl',
      );

      onProgress(
        const InitialSyncProgress(
          totalEvents: 3,
          processedEvents: 1,
          currentTable: 'system_url_config',
          message: 'Downloading account data...',
        ),
      );

      final appliedCount = await syncService.pullFromServerForBootstrap(
        targetUrl: pullTargetUrl,
        username: username,
      );

      onProgress(
        const InitialSyncProgress(
          totalEvents: 3,
          processedEvents: 2,
          currentTable: 'user_table',
          message: 'Finishing account setup...',
        ),
      );

      final localUser = await authRepository.findActiveUserByUsername(username);
      final localUserId = localUser?.id;

      if (localUserId == null) {
        throw _InitialSyncException(
          appliedCount == 0
              ? 'Company server pull completed but returned no sync data for this user.'
              : 'Account data downloaded, but the user record could not be created locally.',
        );
      }

      developer.log(
        'InitialDataSync: Applied $appliedCount events from '
        '$pullTargetUrl. '
        'Local user ID: $localUserId',
      );

      return InitialDataSyncResult.success(localUserId);
    } on _InitialSyncException catch (e, stackTrace) {
      developer.log('InitialDataSync: Failed: $e', stackTrace: stackTrace);
      return InitialDataSyncResult.failure(e.message);
    } catch (e, stackTrace) {
      developer.log('InitialDataSync: Failed: $e', stackTrace: stackTrace);
      return InitialDataSyncResult.failure(e.toString());
    }
  }

  String _normalizeBaseUrl(String targetUrl) {
    return targetUrl.endsWith('/')
        ? targetUrl.substring(0, targetUrl.length - 1)
        : targetUrl;
  }

  List<Uri> _buildBootstrapUris(String baseUrl, {required String username}) {
    final normalizedBaseUrl = _normalizeBaseUrl(baseUrl);

    return [
      Uri.parse(
        '$normalizedBaseUrl/api/sync/url',
      ).replace(queryParameters: {'userName': username}),
    ];
  }

  Future<_BootstrapFetchResult> _fetchBootstrapConfig({
    required String defaultServerBaseUrl,
    required String username,
  }) async {
    final requestUris = _buildBootstrapUris(
      defaultServerBaseUrl,
      username: username,
    );

    _InitialSyncException? lastFailure;

    for (final url in requestUris) {
      try {
        developer.log('InitialDataSync: Requesting remote bootstrap via $url');

        final response = await httpClient
            .get(
              url,
              headers: const {
                'Accept': 'application/json',
                'ngrok-skip-browser-warning': 'true',
              },
            )
            .timeout(const Duration(seconds: 120));

        if (_looksLikeHtmlBootstrapResponse(response)) {
          developer.log(
            'InitialDataSync: /url returned HTML instead of JSON. '
            'Final URL: ${response.request?.url}',
          );
          throw _InitialSyncException(
            _buildRawResponseDebugMessage(
              response,
              prefix: 'Bootstrap endpoint returned HTML instead of JSON.',
            ),
          );
        }

        if (response.statusCode == 200 || response.statusCode == 201) {
          developer.log(
            'InitialDataSync: Bootstrap raw response body: '
            '${_truncateForDebug(response.body)}',
          );

          final body = _decodeResponseBody(response.body);

          final failureMessage = _extractFailureMessage(body);
          if (failureMessage != null) {
            throw _InitialSyncException(
              _buildRawResponseDebugMessage(
                response,
                prefix: 'Bootstrap endpoint returned success=false.',
              ),
            );
          }

          final companyServerBaseUrl = _extractCompanyServerBaseUrl(body);
          if (companyServerBaseUrl == null || companyServerBaseUrl.isEmpty) {
            throw _InitialSyncException(
              _buildRawResponseDebugMessage(
                response,
                prefix:
                    'Bootstrap endpoint returned 200/201 but no company URL was parsed.',
              ),
            );
          }

          return _BootstrapFetchResult(
            companyServerBaseUrl: companyServerBaseUrl,
          );
        }

        if (response.statusCode == 401 || response.statusCode == 403) {
          developer.log(
            'InitialDataSync: Bootstrap endpoint denied request '
            'status=${response.statusCode} at $url',
          );
          throw _InitialSyncException(
            _buildRawResponseDebugMessage(
              response,
              prefix: 'Bootstrap endpoint denied the request.',
            ),
          );
        }

        if (response.statusCode == 404) {
          lastFailure = _InitialSyncException(
            _buildRawResponseDebugMessage(
              response,
              prefix: 'Bootstrap endpoint was not found.',
            ),
          );
          continue;
        }

        throw _InitialSyncException(
          _buildRawResponseDebugMessage(
            response,
            prefix: 'Bootstrap endpoint returned an unexpected status.',
          ),
        );
      } on _InitialSyncException catch (e) {
        lastFailure = e;
      } catch (e) {
        developer.log('InitialDataSync: Bootstrap request error at $url: $e');
      }
    }

    throw lastFailure ??
        const _InitialSyncException(
          'Failed to request account data from the default server.',
        );
  }

  bool _looksLikeHtmlBootstrapResponse(http.Response response) {
    final contentType = response.headers['content-type']?.toLowerCase() ?? '';
    final finalPath = response.request?.url.path.toLowerCase() ?? '';
    final bodyPrefix = response.body.trimLeft().toLowerCase();

    return contentType.contains('text/html') ||
        finalPath.endsWith('/signin.xhtml') ||
        bodyPrefix.startsWith('<!doctype html') ||
        bodyPrefix.startsWith('<html');
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

  dynamic _decodeResponseBody(String responseBody) {
    final trimmed = responseBody.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    try {
      return jsonDecode(trimmed);
    } catch (_) {
      return trimmed;
    }
  }

  String? _extractCompanyServerBaseUrl(dynamic body) {
    if (body is List || body == null) {
      return null;
    }

    if (body is String) {
      final trimmed = body.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    if (body is! Map<String, dynamic>) {
      return null;
    }

    const directUrlKeys = [
      'company_url',
      'companyUrl',
      'url',
      'server_url',
      'serverUrl',
      'base_url',
      'baseUrl',
      'config_value',
      'configValue',
    ];

    for (final key in directUrlKeys) {
      final resolvedUrl = _extractCompanyServerBaseUrl(body[key]);
      if (resolvedUrl != null && resolvedUrl.isNotEmpty) {
        return resolvedUrl;
      }
    }

    final nestedValues = [
      body['savedItem'],
      body['saved_item'],
      body['data'],
      body['result'],
      body['payload'],
    ];
    for (final nestedValue in nestedValues) {
      final resolvedUrl = _extractCompanyServerBaseUrl(nestedValue);
      if (resolvedUrl != null && resolvedUrl.isNotEmpty) {
        return resolvedUrl;
      }
    }

    return null;
  }

  String? _extractFailureMessage(dynamic body) {
    if (body is Map<String, dynamic>) {
      final success = body['success'];
      if (success is bool && !success) {
        final message = body['message']?.toString().trim();
        if (message != null && message.isNotEmpty) {
          return message;
        }
        return 'Unable to load account data for this user.';
      }

      final status = body['status']?.toString().trim();
      if (status != null && status.isNotEmpty) {
        final normalizedStatus = status.toLowerCase();
        const successStates = {'ok', 'success', 'true'};
        if (!successStates.contains(normalizedStatus)) {
          final message = body['message']?.toString().trim();
          if (message != null && message.isNotEmpty) {
            return message;
          }
          return status;
        }
      }
    }

    return null;
  }
}
