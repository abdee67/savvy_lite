import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/auth/model/remote_login_response.dart';
import 'package:savvy_stock/features/auth/repo/auth_repo.dart';

/// Service that authenticates users against the remote Java server.
///
/// When local credentials are not found, this service calls the Java server's
/// login endpoint to validate credentials and retrieve all company-level data
/// needed to populate the local database.
class RemoteAuthService {
  final http.Client httpClient;
  final AuthRepository authRepository;

  RemoteAuthService({
    required this.httpClient,
    required this.authRepository,
  });

  /// Authenticate against the remote Java server.
  ///
  /// [username] — the username entered by the user
  /// [passwordHash] — the SHA-256 hashed password (same algorithm used by server)
  ///
  /// Returns [RemoteLoginResponse] with all company data on success,
  /// or a failure response with error message.
  Future<RemoteLoginResponse> login(
    String username,
    String passwordHash,
  ) async {
    try {
      // 1. Get the server base URL from system_url_config
      final baseUrl = await authRepository.getServerBaseUrl();
      if (baseUrl == null || baseUrl.isEmpty) {
        developer.log('RemoteAuthService: No server URL configured');
        return RemoteLoginResponse.failure(
          'No server URL configured. Please configure the server URL first.',
        );
      }

      // 2. Call the server's login endpoint
      final url = Uri.parse('$baseUrl/api/auth/login');
      developer.log('RemoteAuthService: Attempting remote login at $url');

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
          .timeout(const Duration(seconds: 15));

      developer.log(
        'RemoteAuthService: Server responded with status ${response.statusCode}',
      );
      List<RemoteLoginResponse> parseBody (String json){
        final data = jsonDecode(response.body) as List;
        return data.map((e) => RemoteLoginResponse.fromJson(e)).toList();
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = await compute (parseBody,response.body) as Map<String, dynamic>;
        final loginResponse = RemoteLoginResponse.fromJson(body);

        if (loginResponse.success) {
          developer.log(
            'RemoteAuthService: Remote login successful for user: $username',
          );
        } else {
          developer.log(
            'RemoteAuthService: Remote login failed: ${loginResponse.message}',
          );
        }

        return loginResponse;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        return RemoteLoginResponse.failure(
          'Invalid credentials',
        );
      } else {
        developer.log(
          'RemoteAuthService: Unexpected status ${response.statusCode}: '
          '${response.body}',
        );
        return RemoteLoginResponse.failure(
          'Server error (${response.statusCode}). Please try again later.',
        );
      }
    } on http.ClientException catch (e) {
      developer.log('RemoteAuthService: Network error: $e');
      return RemoteLoginResponse.failure(
        'Cannot reach server. Please check your internet connection.',
      );
    } catch (e) {
      developer.log('RemoteAuthService: Login error: $e');
      return RemoteLoginResponse.failure(
        'Remote login failed: ${e.toString()}',
      );
    }
  }
}
