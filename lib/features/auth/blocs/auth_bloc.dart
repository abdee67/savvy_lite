// features/auth/blocs/auth_bloc.dart
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:savvy_stock/core/constants/app_routes.dart';
import 'package:savvy_stock/core/di/injection_container.dart';
import 'package:savvy_stock/core/services/conectitvity_service.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/core/services/sync/sync_service.dart';
import 'package:savvy_stock/features/admin/users/models/user_with_role.dart';
import 'package:savvy_stock/features/auth/blocs/auth_event.dart';
import 'package:savvy_stock/features/auth/blocs/auth_state.dart';
import 'package:savvy_stock/features/admin/privilege/models/privilege_model.dart';
import 'package:savvy_stock/features/admin/role/models/role_model.dart';
import 'package:savvy_stock/features/admin/users/models/user_model.dart';
import 'package:savvy_stock/features/auth/repo/auth_repo.dart';
import 'package:savvy_stock/features/auth/services/initial_data_sync_service.dart';
import 'package:savvy_stock/features/company/models/company_model.dart';
import 'package:savvy_stock/features/licensing/model/license_validation_result_model.dart';
import 'package:savvy_stock/features/licensing/services/license_service.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository repository;
  final FlutterSecureStorage secureStorage;
  final LicenseService licenseService;
  final InitialDataSyncService initialDataSyncService;
  final ConnectivityService connectivityService;

  // Keep databaseService accessor for hasAnyCompany check
  LocalDatabaseService get databaseService => repository.databaseService;

  static const _tokenKey = 'jwt_token';
  static const _companyKey = 'company';
  static const _userIdKey = 'user_id';
  static const _passwordKey = 'password';

  UserModel? _currentUser;
  Company? _currentCompany;

  UserModel? get currentUser => _currentUser;
  Company? get currentCompany => _currentCompany;
  Future<String?> get authToken => secureStorage.read(key: _tokenKey);

  AuthBloc({
    required this.repository,
    required this.secureStorage,
    required this.licenseService,
    required this.initialDataSyncService,
    required this.connectivityService,
  }) : super(AuthState(status: AuthStatus.initial)) {
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<TokenRefreshRequested>(_onTokenRefreshRequested);
    on<AuthFailureEvent>(_onAuthFailure);
    on<CompanyContextChanged>(_onCompanyContextChanged);
  }

  // features/auth/blocs/auth_bloc.dart - Updated LoginRequested handler
  // Now with remote server fallback when local credentials not found
  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthState(status: AuthStatus.loading, message: 'Logging in...'));

    try {
      // Use compute to run hashing in a separate isolate
      final hashedPassword = await repository.hashPassword(event.password);

      developer.log('Username entered: ${event.username}');
      developer.log('Hashed password: $hashedPassword');

      // ─── Step 1: Try local credentials first ──────────────────────
      UserModel? user = await repository.findUserByCredentials(
        event.username,
        hashedPassword,
      );

      // ─── Step 2: If local fails, try remote server ────────────────
      if (user == null) {
        developer.log('No local user found. Attempting remote login...');

        // Check connectivity before making network call
        if (!connectivityService.isConnected) {
          developer.log('Device is offline — cannot verify with server');
          emit(
            AuthState(
              status: AuthStatus.failure,
              message:
                  'Invalid credentials locally. '
                  'Connect to the internet to verify with server.',
              errorType: AuthErrorType.networkError,
              occuredAt: DateTime.now(),
            ),
          );
          return;
        }

        // Get server base URL
        final serverBaseUrl = await repository.getServerBaseUrl();

        if (serverBaseUrl == null || serverBaseUrl.isEmpty) {
          emit(
            AuthState(
              status: AuthStatus.failure,
              message:
                  'No server URL configured. '
                  'Please configure the server URL first.',
              errorType: AuthErrorType.networkError,
              occuredAt: DateTime.now(),
            ),
          );
          return;
        }

        // ─── Step 3: Download & sync ALL company data ────────────────
        emit(
          AuthState(
            status: AuthStatus.initialSyncInProgress,
            message: 'Connecting to server...',
            syncProgress: 0,
            syncTable: '',
          ),
        );

        final localUserId = await initialDataSyncService.downloadAndApply(
          serverBaseUrl: serverBaseUrl,
          username: event.username,
          passwordHash: hashedPassword,
          onProgress: (progress) {
            emit(
              AuthState(
                status: AuthStatus.initialSyncInProgress,
                message: progress.message,
                syncProgress: progress.percentage,
                syncTable: progress.currentTable,
              ),
            );
          },
        );

        if (localUserId == null) {
          developer.log('Initial data sync failed or returned no user');
          emit(
            AuthState(
              status: AuthStatus.failure,
              message: 'Failed to set up account data. Please try again.',
              errorType: AuthErrorType.unknown,
              occuredAt: DateTime.now(),
            ),
          );
          return;
        }

        // ─── Step 4: Re-query local DB for the newly inserted user ──
        user = await repository.findUserById(localUserId);

        if (user == null) {
          developer.log('User not found after sync (id=$localUserId)');
          emit(
            AuthState(
              status: AuthStatus.failure,
              message:
                  'Account setup completed but login failed. '
                  'Please try logging in again.',
              errorType: AuthErrorType.unknown,
              occuredAt: DateTime.now(),
            ),
          );
          return;
        }

        developer.log(
          'Initial data sync successful — local user ID: ${user.id}',
        );
      }

      // ─── Step 5: Continue normal login flow ───────────────────────
      // (works for both local-found and remote-populated users)

      // Get user roles with their privileges through proper joins
      final userWithRoles = await repository.getUserWithRolesAndPrivileges(
        user,
      );

      // Validate License
      final licenseResult = await licenseService.loadAndValidateLicense();
      if (!licenseResult.isValid) {
        developer.log(
          'License validation failed: ${licenseResult.errorMessage}',
        );

        // If it's a tampering error, show it as a login failure (stay on page)
        // instead of redirecting to activation
        if (licenseResult.errorMessage?.contains('System clock rollback') ==
            true) {
          emit(
            AuthState(
              status: AuthStatus.failure,
              message: licenseResult.errorMessage,
              errorType: AuthErrorType.unknown,
              occuredAt: DateTime.now(),
            ),
          );
          return;
        }

        emit(
          AuthState(
            status: AuthStatus.licenseActivationRequired,
            message:
                licenseResult.errorMessage ?? 'License activation required',
          ),
        );
        return;
      }
      if (kDebugMode) {
        developer.log('License validation successful: $licenseResult');
      }

      // Create mock JWT token
      final token = _createToken(
        userWithRoles,
        userWithRoles.allPrivileges,
        userWithRoles.roles,
      );

      await secureStorage.write(key: _tokenKey, value: token);
      await secureStorage.write(
        key: _companyKey,
        value: user.company.toString(),
      );
      await secureStorage.write(key: _userIdKey, value: user.id.toString());

      // Inject credentials into SyncService for background pull cycles
      final syncService = getIt<SyncService>();
      syncService.setCredentials(username: user.userName!);
      // Use a lightweight token for sync to avoid exceeding Apache's
      // header size limit (the full token contains all privileges/roles).
      final syncToken = _createSyncToken(user);
      syncService.setAuthToken(syncToken);

      emit(
        AuthState(
          status: AuthStatus.authenticated,
          userId: user,
          username: user.userName,
          companyId: user.company,
          companyLogo: user.companyRef?.logoCompany,
          branchId: user.branch,
          roles: userWithRoles.roles,
          privileges: userWithRoles.allPrivileges,
          hasExistingCompany: true,
        ),
      );
    } catch (e) {
      developer.log('Login Failed: $e');
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

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    // Navigate first, then clear storage and emit state
    if (event.context != null && event.context!.mounted) {
      event.context!.push(AppRoutes.login);
    }
    await _clearStorage();

    // Add a small delay to ensure navigation completes
    await Future.delayed(const Duration(milliseconds: 100));

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

    try {
      // Check if any company exists on the device
      // Add timeout to prevent hanging on DB lock
      final hasCompany = await databaseService.hasAnyCompany().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          developer.log('CheckAuthStatus: hasAnyCompany timed out');
          return false;
        },
      );

      final token = await secureStorage
          .read(key: 'jwt_token')
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              developer.log('CheckAuthStatus: secureStorage read timed out');
              return null;
            },
          );
      if (token != null) {
        // Decode the mock JWT token
        final tokenData = _decodeToken(token);
        if (tokenData == null) {
          await _clearStorage();
          emit(
            AuthState(
              status: AuthStatus.initial,
              message: 'Token is invalid',
              hasExistingCompany: hasCompany,
            ),
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
              companyId: tokenData['company'],
              roles: List<Role>.from(
                tokenData['roles'].map((r) => Role.fromMap(r)),
              ),
              privileges: List<Privilege>.from(
                tokenData['privileges'].map((p) => Privilege.fromMap(p)),
              ),
              tokenExpiryTime: expiry,
              hasExistingCompany: hasCompany,
            ),
          );
          return;
        }

        // Validate License on App Start
        // Add timeout to ensure we don't hang indefinitely
        final licenseResult = await licenseService
            .loadAndValidateLicense()
            .timeout(
              const Duration(seconds: 50),
              onTimeout: () {
                return LicenseValidationResult.invalid('Validation timed out');
              },
            );

        if (!licenseResult.isValid) {
          developer.log(
            'License validation failed on startup: ${licenseResult.errorMessage}',
          );

          // If it's a tampering error, show it as a login failure (stay on page)
          if (licenseResult.errorMessage?.contains('System clock rollback') ==
              true) {
            // Clear partial session to force re-login
            await _clearStorage();
            emit(
              AuthState(
                status: AuthStatus.unauthenticated, // Show login form
                message: licenseResult.errorMessage,
                hasExistingCompany: hasCompany,
              ),
            );
            return;
          }

          emit(
            AuthState(
              status: AuthStatus.licenseActivationRequired,
              message:
                  licenseResult.errorMessage ?? 'License activation required',
            ),
          );
          return;
        }
        if (kDebugMode) {
          developer.log('License validation successful: $licenseResult');
        }

        // Reconstruct user and privileges from token data
        final user = UserModel.fromMap(tokenData['user']);
        final privileges = (tokenData['privileges'] as List)
            .map((p) => Privilege.fromMap(p))
            .toList();
        final roles = (tokenData['roles'] as List)
            .map((r) => Role.fromMap(r))
            .toList();

        final syncService = getIt<SyncService>();
        if (user.userName != null) {
          syncService.setCredentials(username: user.userName!);
        }
        // Use a lightweight token for sync to avoid exceeding Apache's
        // header size limit (the full token contains all privileges/roles).
        final syncToken = _createSyncToken(user);
        syncService.setAuthToken(syncToken);

        emit(
          AuthState(
            status: AuthStatus.authenticated,
            userId: user,
            username: user.userName,
            companyId: user.company,
            companyLogo: user.companyRef?.logoCompany,
            roles: roles,
            privileges: privileges,
            authenticatedAt: DateTime.fromMillisecondsSinceEpoch(
              tokenData['auth_time'] as int,
            ),
            tokenExpiryTime: expiry,
            hasExistingCompany: hasCompany,
          ),
        );
      } else {
        //No token stored:clear state
        emit(
          AuthState(
            status: AuthStatus.unauthenticated,
            message: 'No token stored',
            hasExistingCompany: hasCompany,
          ),
        );
      }
    } catch (e) {
      developer.log('Auth Check Failed: $e');
      // Ensure we clear loading state even on catastrophic error
      await _clearStorage();
      emit(
        AuthState.unauthenticated(
          message: 'Session check failed: $e',
        ).copyWith(hasExistingCompany: false), // Safest default
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
        UserWithRole(
          user: UserModel(
            id: oldState.userId!.id,
            userName: oldState.username!,
            company: oldState.companyId!,
            password: oldState.password!,
          ),
          roles: oldState.roles,
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
          companyLogo: oldState.companyLogo,
          branchId: oldState.branchId,
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
    UserWithRole user,
    List<Privilege> privileges,
    List<Role> roles,
  ) {
    final userMap = user.user.toMap();
    // developer.log('Creating Token with User Map: $userMap');

    final tokenData = {
      'user': userMap,
      'privileges': privileges.map((p) => p.toMap()).toList(),
      'roles': roles.map((r) => r.toMap()).toList(),
      'auth_time': DateTime.now().millisecondsSinceEpoch,
      'exp': DateTime.now()
          .add(const Duration(hours: 2))
          .millisecondsSinceEpoch,
      'jti': Random().nextInt(1000000), // Mock JWT ID
    };

    return base64Url.encode(utf8.encode(json.encode(tokenData)));
  }

  /// Creates a minimal token for sync HTTP requests.
  ///
  /// The full [_createToken] embeds the entire user object, all privileges,
  /// and all roles — which can easily exceed Apache's default 8 KB header
  /// size limit (`LimitRequestFieldSize`). This lightweight variant only
  /// includes the fields the server actually needs to authenticate the
  /// sync request.
  String _createSyncToken(UserModel user) {
    final tokenData = {
      'user_id': user.id,
      'username': user.userName,
      'company': user.company,
      'auth_time': DateTime.now().millisecondsSinceEpoch,
      'exp': DateTime.now()
          .add(const Duration(hours: 2))
          .millisecondsSinceEpoch,
      'jti': Random().nextInt(1000000),
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
