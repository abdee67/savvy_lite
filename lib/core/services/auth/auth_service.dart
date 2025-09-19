import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:savvy_stock/core/constants/api_constants.dart';
import 'package:savvy_stock/core/errors/exceptions.dart';
import 'package:savvy_stock/features/auth/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class AuthService with ChangeNotifier {
  UserModel? _currentUser;
  String? _authToken;
  DateTime? _tokenExpiry;

  UserModel? get currentUser => _currentUser;
  String? get authToken => _authToken;
  bool get isAuthenticated =>
      _authToken != null &&
      _tokenExpiry != null &&
      _tokenExpiry!.isAfter(DateTime.now());

  final SharedPreferences _prefs;
  final http.Client _client;

  AuthService(this._prefs, this._client) {
    _loadStoredAuthData();
  }

  Future<void> _loadStoredAuthData() async {
    try {
      final token = _prefs.getString('auth_token');
      final expiry = _prefs.getInt('token_expiry');
      final userJson = _prefs.getString('current_user');

      if (token != null && expiry != null && userJson != null) {
        _authToken = token;
        _tokenExpiry = DateTime.fromMillisecondsSinceEpoch(expiry);
        _currentUser = UserModel.fromJson(json.decode(userJson));

        // Check if token is still valid
        if (_tokenExpiry!.isBefore(DateTime.now())) {
          await _refreshToken();
        }
      }
    } catch (e) {
      await logout();
    }
  }

  Future<UserModel> login(String email, String password) async {
    try {
      final response = await _client
          .post(
            Uri.parse(ApiConstants.login),
            headers: {
              ApiConstants.contentTypeHeader: ApiConstants.contentTypeJson,
              ApiConstants.acceptHeader: ApiConstants.acceptJson,
            },
            body: json.encode({'email': email, 'password': password}),
          )
          .timeout(ApiConstants.connectTimeout);

      if (response.statusCode == ApiConstants.success) {
        final responseData = json.decode(response.body);
        await _saveAuthData(responseData);
        return _currentUser!;
      } else if (response.statusCode == ApiConstants.unauthorized) {
        throw AuthException('Invalid email or password');
      } else {
        throw ServerException('Login failed: ', response.statusCode);
      }
    } on ServerException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw NetworkException('Network error during login: $e');
    }
  }

  Future<UserModel> register(UserModel user, String password) async {
    try {
      final response = await _client
          .post(
            Uri.parse(ApiConstants.register),
            headers: {
              ApiConstants.contentTypeHeader: ApiConstants.contentTypeJson,
              ApiConstants.acceptHeader: ApiConstants.acceptJson,
            },
            body: json.encode({'user': user.toJson(), 'password': password}),
          )
          .timeout(ApiConstants.connectTimeout);

      if (response.statusCode == ApiConstants.created) {
        final responseData = json.decode(response.body);
        await _saveAuthData(responseData);
        return _currentUser!;
      } else if (response.statusCode == ApiConstants.badRequest) {
        throw AuthException('Registration failed: Invalid data');
      } else {
        throw ServerException('Registration failed: ', response.statusCode);
      }
    } on ServerException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw NetworkException('Network error during registration: $e');
    }
  }

  Future<void> logout() async {
    try {
      if (_authToken != null) {
        await _client
            .post(
              Uri.parse(ApiConstants.logout),
              headers: {ApiConstants.authorizationHeader: 'Bearer $_authToken'},
            )
            .timeout(ApiConstants.connectTimeout);
      }
    } catch (e) {
      // Logout even if API call fails
      print('Logout API call failed: $e');
    } finally {
      _clearAuthData();
      notifyListeners();
    }
  }

  Future<void> _refreshToken() async {
    try {
      final response = await _client
          .post(
            Uri.parse(ApiConstants.refreshToken),
            headers: {ApiConstants.authorizationHeader: 'Bearer $_authToken'},
          )
          .timeout(ApiConstants.connectTimeout);

      if (response.statusCode == ApiConstants.success) {
        final responseData = json.decode(response.body);
        await _saveAuthData(responseData);
      } else {
        throw AuthException('Token refresh failed');
      }
    } catch (e) {
      await logout();
      throw AuthException('Token refresh failed: $e');
    }
  }

  Future<void> _saveAuthData(Map<String, dynamic> responseData) async {
    _authToken = responseData['token'];
    _tokenExpiry = DateTime.now().add(
      Duration(seconds: responseData['expires_in'] ?? 3600),
    );
    _currentUser = UserModel.fromJson(responseData['user']);

    await _prefs.setString('auth_token', _authToken!);
    await _prefs.setInt('token_expiry', _tokenExpiry!.millisecondsSinceEpoch);
    await _prefs.setString('current_user', json.encode(_currentUser!.toJson()));

    notifyListeners();
  }

  Future<void> _clearAuthData() async {
    _authToken = null;
    _tokenExpiry = null;
    _currentUser = null;

    await _prefs.remove('auth_token');
    await _prefs.remove('token_expiry');
    await _prefs.remove('current_user');
  }

  Future<String> getAuthToken() async {
    if (!isAuthenticated) {
      throw AuthException('Not authenticated');
    }

    // Refresh token if it's about to expire (within 5 minutes)
    if (_tokenExpiry!.difference(DateTime.now()).inMinutes < 5) {
      await _refreshToken();
    }

    return _authToken!;
  }

  Future<void> updateUserProfile(UserModel updatedUser) async {
    try {
      final token = await getAuthToken();
      final response = await _client
          .put(
            Uri.parse(ApiConstants.userProfile),
            headers: {
              ApiConstants.contentTypeHeader: ApiConstants.contentTypeJson,
              ApiConstants.authorizationHeader: 'Bearer $token',
            },
            body: json.encode(updatedUser.toJson()),
          )
          .timeout(ApiConstants.connectTimeout);

      if (response.statusCode == ApiConstants.success) {
        final responseData = json.decode(response.body);
        _currentUser = UserModel.fromJson(responseData);
        await _prefs.setString(
          'current_user',
          json.encode(_currentUser!.toJson()),
        );
        notifyListeners();
      } else {
        throw ServerException('Profile update failed:', response.statusCode);
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw NetworkException('Network error during profile update: $e');
    }
  }
}
