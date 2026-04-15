import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Retryable server exception for HTTP 5xx errors
class RetryableServerException implements Exception {
  final String message;
  RetryableServerException(this.message);
  @override
  String toString() => message;
}

/// A robust HTTP client utility matching the Java HttpClientUtil implementation.
///
/// Handles:
/// - Connection & Request Timeouts
/// - Retries for network errors and 5xx Server Errors (excluding 4xx Client Errors)
/// - Auto-injection of Bearer tokens
/// - Exponential/progressive backoff
class SyncSender {
  static const Duration _requestTimeout = Duration(seconds: 10);
  static const int _maxRetries = 3;
  static const int _baseRetryDelayMs = 500;

  final http.Client httpClient;

  /// Optional auth token provider. Set this after user login.
  String? authToken;

  SyncSender({required this.httpClient, this.authToken});

  // =====================================================
  // PUBLIC API
  // =====================================================

  Future<String> postJson(String url, String jsonBody) async {
    return _executeWithRetry(() => _sendPost(url, jsonBody, authToken));
  }

  Future<String> getWithBearer(String url) async {
    return _executeWithRetry(() => _sendGet(url, authToken));
  }

  // =====================================================
  // INTERNAL SEND METHODS
  // =====================================================

  Future<String> _sendPost(
    String url,
    String jsonBody,
    String? bearerToken,
  ) async {
    final uri = Uri.parse(url);
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (bearerToken != null && bearerToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $bearerToken';
    }

    final response = await httpClient
        .post(uri, headers: headers, body: jsonBody)
        .timeout(_requestTimeout);

    /* if (kDebugMode) {
      developer.log('SyncSender: Response: ${response.body}');
    }*/

    _validateResponse(response);
    return response.body;
  }

  Future<String> _sendGet(String url, String? bearerToken) async {
    final uri = Uri.parse(url);
    final headers = <String, String>{'Accept': 'application/json'};
    if (bearerToken != null && bearerToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $bearerToken';
    }

    final response = await httpClient
        .get(uri, headers: headers)
        .timeout(_requestTimeout);

    _validateResponse(response);
    return response.body;
  }

  // =====================================================
  // RETRY HANDLING (NETWORK + 5xx ONLY)
  // =====================================================

  Future<String> _executeWithRetry(Future<String> Function() action) async {
    int attempt = 0;

    while (true) {
      try {
        return await action();
      } catch (ex) {
        attempt++;

        if (attempt >= _maxRetries || !_isRetryable(ex)) {
          rethrow;
        }

        await Future.delayed(
          Duration(milliseconds: _baseRetryDelayMs * attempt),
        );
      }
    }
  }

  bool _isRetryable(Object ex) {
    return ex is SocketException ||
        ex is TimeoutException ||
        ex is http.ClientException ||
        ex is RetryableServerException;
  }

  // =====================================================
  // RESPONSE VALIDATION
  // =====================================================

  void _validateResponse(http.Response response) {
    int status = response.statusCode;

    if (status >= 200 && status < 300) {
      return;
    }

    if (status >= 500) {
      throw RetryableServerException('HTTP $status server error');
    }

    // Treat 409 Conflict as success (Idempotency — already saved)
    if (status == 409) {
      return;
    }

    developer.log('🚨 SyncSender HTTP $status ERROR!');
    developer.log('🚨 Server Response Body: ${response.body}');
    throw StateError('HTTP $status client error. See logs above for details.');
  }
}
