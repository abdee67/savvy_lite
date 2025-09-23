// features/auth/blocs/auth_bloc.dart
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';
import 'dart:typed_data';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:argon2/argon2.dart';
import 'package:savvy_stock/core/errors/failures.dart';
import 'package:savvy_stock/core/models/company.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/auth/blocs/auth_event.dart';
import 'package:savvy_stock/features/auth/blocs/auth_state.dart';
import 'package:savvy_stock/features/auth/models/privilege_model.dart';
import 'package:savvy_stock/features/auth/models/role_model';
import 'package:savvy_stock/features/auth/models/user_model.dart';
import 'package:sqflite/sqflite.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LocalDatabaseService databaseService;
  final FlutterSecureStorage secureStorage;

  static const _tokenKey = 'jwt_token';
  static const _companyKey = 'company_id';
  static const _userIdKey = 'user_id';
  static const _passwordKey = 'password';

  UserModel? _currentUser;
  Company? _currentCompany;

  UserModel? get currentUser => _currentUser;
  Company? get currentCompany => _currentCompany;
  Future<String?> get authToken => secureStorage.read(key: _tokenKey);

  AuthBloc({required this.databaseService, required this.secureStorage})
    : super(AuthState(status: AuthStatus.initial)) {
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<TokenRefreshRequested>(_onTokenRefreshRequested);
    on<AuthFailureEvent>(_onAuthFailure);
    on<CompanyContextChanged>(_onCompanyContextChanged);
  }

  Future<void> _debugUserTable(Database db) async {
    try {
      final allUsers = await db.query('user_table');
      developer.log('=== USER TABLE DEBUG INFO ===');
      for (final user in allUsers) {
        developer.log(
          'User: ${user['user_name']}, Password: ${user['password']}, Status: ${user['status']}',
        );
      }
      developer.log('=== END DEBUG INFO ===');
    } catch (e) {
      developer.log('Debug error: $e');
    }
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthState(status: AuthStatus.loading, message: 'Logging in...'));
    try {
      final db = await databaseService.database;
      await _debugUserTable(db);
      // Hash the password using Argon
      final password = event.password;
      final salt = 'somesalt'.toBytesLatin1();

      final parameters = Argon2Parameters(
        Argon2Parameters.ARGON2_i,
        salt,
        version: Argon2Parameters.ARGON2_VERSION_10,
        iterations: 2,
        memoryPowerOf2: 16,
      );

      final argon2 = Argon2BytesGenerator();

      argon2.init(parameters);

      final passwordBytes = parameters.converter.convert(password);

      developer.log('Generating key from password...');

      final result = Uint8List(32);
      argon2.generateBytes(passwordBytes, result, 0, result.length);

      final resultHex = result.toHexString();
      developer.log('Result: $resultHex');
      developer.log('Username entered: ${event.username}');
      developer.log('Password entered: ${event.password}');
      developer.log('Hashed password: $resultHex');

      // Debug: Check what the query is actually doing
      developer.log(
        'Executing query: user_name = ? AND password = ? AND status = "active"',
      );
      developer.log('With args: [${event.username}, $resultHex]');

      // Check user credentials
      final users = await db.query(
        'user_table',
        where: 'user_name = ? AND password = ? AND status = "active"',
        whereArgs: [event.username, resultHex],
      );
      developer.log('Found ${users.length} users matching credentials');

      if (users.isEmpty) {
        developer.log('No users found matching credentials');
        emit(
          AuthState(
            status: AuthStatus.failure,
            message: 'Invalid credentials or inactive account',
            errorType: AuthErrorType.invalidCredentials,
            occuredAt: DateTime.now(),
          ),
        );
        return;
      }
      // If user exists in multiple companies, handle accordingly
      if (users.length > 1) {
        // Get company details for each user record
        final companies = await _getCompaniesForUsers(users);
        emit(
          AuthState(
            status: AuthStatus.companySelectionRequired,
            message: 'Multiple companies found for user',
            companySelectionRequired: CompanySelectionRequired(
              availableCompanies: companies,
              username: event.username,
            ),
          ),
        );
        return;
      }

      final userData = users.first;
      final user = UserModel.fromMap(userData);

      // Get user roles and privileges
      final rolesResult = await db.rawQuery(
        '''
        SELECT r.* FROM role_table r
        INNER JOIN user_role ur ON ur.role_table_id = r.id
          WHERE ur.user_id = ? AND r.company = ?
        ''',
        [user.id, user.company],
      );

      final roles = rolesResult.map((r) => Role.fromMap(r)).toList();

      final privilegesResult = await db.rawQuery(
        '''
         SELECT DISTINCT p.* FROM previlage_table p
      INNER JOIN role_previlage rp ON rp.previlage_table_id = p.id
      INNER JOIN user_role ur ON ur.role_table_id = rp.role_table_id
      WHERE ur.user_id = ?
    ''',
        [user.id],
      );

      final privileges = privilegesResult
          .map((p) => Privilege.fromMap(p))
          .toList();

      // Create mock JWT token
      final token = _createToken(user, privileges, roles);
      await secureStorage.write(key: _tokenKey, value: token);
      await secureStorage.write(
        key: _companyKey,
        value: user.company.toString(),
      );
      await secureStorage.write(key: _userIdKey, value: user.id.toString());
      await secureStorage.write(
        key: _passwordKey,
        value: user.password.toString(),
      );

      emit(
        AuthState(
          status: AuthStatus.authenticated,
          userId: user.id,
          username: user.userName,
          companyId: user.company,
          roles: roles,
          privileges: privileges
              .map(
                (p) => Privilege(
                  id: p.id,
                  name: p.name,
                  type: p.type,
                  linkLabel: p.linkLabel,
                  description: p.description,
                  vendorOnly: p.vendorOnly,
                ),
              )
              .toList(),
        ),
      );
      developer.log(
        '🎯 EMITTED AUTHENTICATED STATE - Router should detect this automatically',
      );
    } catch (e) {
      developer.log('Login Failedd: $e');
      emit(
        AuthState(
          status: AuthStatus.failure,
          message: 'Login failed: $e',
          errorType: AuthErrorType.loginFailed,
          occuredAt: DateTime.now(),
        ),
      );
    }
  }

  Future<List<Company>> _getCompaniesForUsers(
    List<Map<String, dynamic>> users,
  ) async {
    final db = await databaseService.database;
    final companyIds = users.map((u) => u['company'] as int).toList();

    final placeholders = List.generate(companyIds.length, (_) => '?').join(',');
    final results = await db.rawQuery('''
    SELECT * FROM company_table 
    WHERE id IN ($placeholders)
  ''', companyIds);

    return results.map((c) => Company.fromMap(c)).toList();
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _clearStorage();
    emit(
      AuthState(status: AuthStatus.initial, message: 'Logged out successfully'),
    );
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      AuthState(
        status: AuthStatus.loading,
        message: 'Checking authentication status...',
      ),
    );
    final token = await secureStorage.read(key: 'jwt_token');
    if (token != null) {
      try {
        // Decode the mock JWT token
        final tokenData = _decodeToken(token);
        if (tokenData == null) {
          await _clearStorage();
          emit(
            AuthState(status: AuthStatus.initial, message: 'Token is invalid'),
          );
          return;
        }
        // Check if token is expired
        final expiry = DateTime.fromMillisecondsSinceEpoch(
          tokenData['exp'] as int,
        );
        if (expiry.isBefore(DateTime.now())) {
          emit(
            AuthState(
              status: AuthStatus.tokenRefreshRequired,
              userId: tokenData['user_id'],
              username: tokenData['username'],
              companyId: tokenData['company_id'],
              roles: List<Role>.from(
                tokenData['roles'].map((r) => Role.fromMap(r)),
              ),
              privileges: List<Privilege>.from(
                tokenData['privileges'].map((p) => Privilege.fromMap(p)),
              ),
              tokenExpiryTime: expiry,
            ),
          );
          return;
        }

        // Reconstruct user and privileges from token data
        final user = UserModel.fromMap(tokenData['user']);
        final privileges = (tokenData['privileges'] as List)
            .map((p) => Privilege.fromMap(p))
            .toList();
        final roles = (tokenData['roles'] as List)
            .map((r) => Role.fromMap(r))
            .toList();

        emit(
          AuthState(
            status: AuthStatus.authenticated,
            userId: user.id,
            username: user.userName,
            companyId: user.company,
            roles: roles,
            privileges: privileges,
            authenticatedAt: DateTime.fromMillisecondsSinceEpoch(
              tokenData['auth_time'] as int,
            ),
            tokenExpiryTime: expiry,
          ),
        );
      } catch (e) {
        await _clearStorage();
        emit(
          AuthState(
            status: AuthStatus.failure,
            message: 'Failed to check authentication status: $e',
          ),
        );
      }
    } else {
      //No token stored:clear state
      emit(
        AuthState(
          status: AuthStatus.unauthenticated,
          message: 'No token stored',
        ),
      );
    }
  }

  Future<void> _onTokenRefreshRequested(
    TokenRefreshRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state.status != AuthStatus.tokenRefreshRequired) {
      emit(
        AuthState(
          status: AuthStatus.failure,
          message: 'Token refresh not required',
          errorType: AuthErrorType.unknown,
          occuredAt: DateTime.now(),
        ),
      );
      return;
    }

    emit(
      const AuthState(
        status: AuthStatus.loading,
        message: 'Refreshing token...',
      ),
    );

    // In a real app, you'd call a refresh token endpoint
    // For local implementation, we'll recreate the token
    try {
      final oldState = state;
      final newToken = _createToken(
        UserModel(
          id: oldState.userId!,
          userName: oldState.username!,
          company: oldState.companyId!,
          password: oldState.password!,
        ),
        oldState.privileges,
        oldState.roles,
      );

      await secureStorage.write(key: _tokenKey, value: newToken);

      emit(
        AuthState(
          status: AuthStatus.authenticated,
          userId: oldState.userId,
          username: oldState.username,
          companyId: oldState.companyId,
          roles: oldState.roles,
          privileges: oldState.privileges,
          authenticatedAt: DateTime.now(),
        ),
      );
    } catch (e) {
      emit(
        AuthState(
          status: AuthStatus.failure,
          message: 'Token refresh failed: $e',
          errorType: AuthErrorType.tokenExpired,
          occuredAt: DateTime.now(),
        ),
      );
    }
  }

  Future<void> _onAuthFailure(
    AuthFailureEvent event,
    Emitter<AuthState> emit,
  ) async {
    await _clearStorage();
    emit(
      AuthState(
        status: AuthStatus.failure,
        message: event.errorMessage,
        errorType: AuthErrorType.unknown,
        occuredAt: DateTime.now(),
      ),
    );
  }

  Future<void> _onCompanyContextChanged(
    CompanyContextChanged event,
    Emitter<AuthState> emit,
  ) async {
    if (state.status == AuthStatus.authenticated) {
      // Update company context in storage
      await secureStorage.write(
        key: _companyKey,
        value: event.companyId.toString(),
      );

      // In a real app, you might need to reload user data for the new company
      // For now, we'll just acknowledge the change
      final currentState = state;
      emit(
        currentState.copyWith(companyId: event.companyId),
      ); // State remains the same, but company name and id changed
    }
  }

  String _createToken(
    UserModel user,
    List<Privilege> privileges,
    List<Role> roles,
  ) {
    final tokenData = {
      'user': user.toMap(),
      'privileges': privileges.map((p) => p.toMap()).toList(),
      'roles': roles.map((r) => r.toMap()).toList(),
      'auth_time': DateTime.now().millisecondsSinceEpoch,
      'exp': DateTime.now()
          .add(const Duration(hours: 24))
          .millisecondsSinceEpoch,
      'jti': Random().nextInt(1000000), // Mock JWT ID
    };

    return base64Url.encode(utf8.encode(json.encode(tokenData)));
  }

  Map<String, dynamic>? _decodeToken(String token) {
    try {
      final decoded = utf8.decode(base64Url.decode(token));
      return json.decode(decoded) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  Future<void> _clearStorage() async {
    await secureStorage.delete(key: _tokenKey);
    await secureStorage.delete(key: _companyKey);
    await secureStorage.delete(key: _userIdKey);
  }

  /// Public method to check if current user has a privilege
  bool hasPrivilege(String privilegeUri) {
    return state.hasPrivilege(privilegeUri);
  }

  /// Public method to check if current user has a role
  bool hasRole(String roleName) {
    return state.hasRole(roleName);
  }
}
