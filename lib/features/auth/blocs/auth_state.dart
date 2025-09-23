import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/auth/blocs/auth_event.dart';
import 'package:savvy_stock/features/auth/models/privilege_model.dart';
import 'package:savvy_stock/features/auth/models/role_model';

enum AuthStatus {
  initial,
  loading,
  success,
  failure,
  companySelectionRequired,
  tokenRefreshRequired,
  authenticated,
  unauthenticated,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final String? message;

  final int? userId;
  final String? username;
  final int? companyId;
  final String? password;
  final List<Role> roles;
  final List<Privilege> privileges;

  final DateTime? authenticatedAt;
  final DateTime? tokenExpiryTime;

  final List<dynamic>? availableCompanies; // can be List<Company> if defined
  final AuthErrorType? errorType;
  final DateTime? lastLoginAt;
  final DateTime? lastLogoutAt;
  final DateTime? occuredAt;
  final String? tokenRefreshRequiredAt;
  final CompanySelectionRequired? companySelectionRequired;

  const AuthState({
    required this.status,
    this.message,
    this.userId,
    this.username,
    this.companyId,
    this.password,
    this.roles = const [],
    this.privileges = const [],
    this.authenticatedAt,
    this.tokenExpiryTime,
    this.availableCompanies,
    this.errorType,
    this.lastLoginAt,
    this.lastLogoutAt,
    this.occuredAt,
    this.tokenRefreshRequiredAt,
    this.companySelectionRequired,
  });

  // --- Helper Getters ---

  bool get isAuthenticated => status == AuthStatus.authenticated;

  bool hasPrivilege(String uri) {
    return privileges.any((p) => p.linkLabel == uri);
  }

  bool hasAnyPrivilege(List<String> uris) {
    return privileges.any((p) => uris.contains(p.linkLabel));
  }

  bool hasRole(String roleName) {
    return roles.any((r) => r.name == roleName);
  }

  bool hasAnyRole(List<String> roleNames) {
    return roles.any((r) => roleNames.contains(r.name));
  }

  bool get isTokenExpiringSoon {
    if (tokenExpiryTime == null) return false;
    return DateTime.now().isAfter(
      tokenExpiryTime!.subtract(const Duration(minutes: 5)),
    );
  }

  // --- CopyWith for immutability ---
  AuthState copyWith({
    AuthStatus? status,
    String? message,
    int? userId,
    String? username,
    int? companyId,
    List<Role>? roles,
    List<Privilege>? privileges,
    DateTime? authenticatedAt,
    DateTime? tokenExpiryTime,
    List<dynamic>? availableCompanies,
    AuthErrorType? errorType,
    DateTime? lastLoginAt,
    DateTime? lastLogoutAt,
    DateTime? occuredAt,
    String? tokenRefreshRequiredAt,
    String? password,
    CompanySelectionRequired? companySelectionRequired,
  }) {
    return AuthState(
      status: status ?? this.status,
      message: message ?? this.message,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      companyId: companyId ?? this.companyId,
      roles: roles ?? this.roles,
      privileges: privileges ?? this.privileges,
      authenticatedAt: authenticatedAt ?? this.authenticatedAt,
      tokenExpiryTime: tokenExpiryTime ?? this.tokenExpiryTime,
      availableCompanies: availableCompanies ?? this.availableCompanies,
      errorType: errorType ?? this.errorType,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      lastLogoutAt: lastLogoutAt ?? this.lastLogoutAt,
      occuredAt: occuredAt ?? this.occuredAt,
      tokenRefreshRequiredAt:
          tokenRefreshRequiredAt ?? this.tokenRefreshRequiredAt,
      password: password ?? this.password,
      companySelectionRequired:
          companySelectionRequired ?? this.companySelectionRequired,
    );
  }

  @override
  List<Object?> get props => [
    status,
    message,
    userId,
    username,
    companyId,
    roles,
    privileges,
    authenticatedAt,
    tokenExpiryTime,
    availableCompanies,
    errorType,
    lastLoginAt,
    lastLogoutAt,
    occuredAt,
    tokenRefreshRequiredAt,
    password,
    companySelectionRequired,
  ];
}

// Optional enum for error types
enum AuthErrorType {
  invalidCredentials,
  accountLocked,
  companyNotFound,
  tokenExpired,
  networkError,
  serverError,
  unknown,
  loginFailed,
}
