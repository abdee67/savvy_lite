import 'package:equatable/equatable.dart';
import 'package:savvy_stock/core/constants/privilege_heirarchy.dart';
import 'package:savvy_stock/features/admin/role/models/role_model.dart';
import 'package:savvy_stock/features/admin/users/models/user_model.dart';
import 'package:savvy_stock/features/admin/users/models/user_with_role.dart';
import 'package:savvy_stock/features/auth/blocs/auth_event.dart';
import 'package:savvy_stock/features/admin/privilege/models/privilege_model.dart';

enum AuthStatus {
  initial,
  loading,
  success,
  failure,
  companySelectionRequired,
  tokenRefreshRequired,
  authenticated,
  unauthenticated,
  error,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final String? message;

  final UserModel? userId;
  final String? username;
  final int? companyId;
  final int? branchId;
  final String? password;
  final List<Role> roles;
  final List<Privilege> privileges;
  final UserWithRole? userWithRole;

  final DateTime? authenticatedAt;
  final DateTime? tokenExpiryTime;

  final List<dynamic>? availableCompanies;
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
    this.branchId,
    this.password,
    this.roles = const [],
    this.privileges = const [],
    this.userWithRole,
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

  bool hasPrivilege(String privilegeUri) {
    // Check BOTH sources to avoid null issues
    if (userWithRole != null) {
      return userWithRole!.hasPrivilege(privilegeUri);
    }
    // Fallback to direct privileges list
    return privileges.any((privilege) => privilege.uri == privilegeUri);
  }

  bool hasAnyPrivilege(List<String> privilegeUris) {
    if (userWithRole != null) {
      return userWithRole!.hasAnyPrivilege(privilegeUris);
    }
    return privileges.any((privilege) => privilegeUris.contains(privilege.uri));
  }

  bool hasRole(String roleName) {
    if (userWithRole != null) {
      return userWithRole!.hasRole(roleName);
    }
    return roles.any((role) => role.name == roleName);
  }

  bool hasAnyRole(List<String> roleNames) {
    if (userWithRole != null) {
      return userWithRole!.hasAnyRole(roleNames);
    }
    return roles.any((role) => roleNames.contains(role.name));
  }

  bool get isTokenExpiringSoon {
    if (tokenExpiryTime == null) return false;
    return DateTime.now().isAfter(
      tokenExpiryTime!.subtract(const Duration(minutes: 5)),
    );
  }

  /// Check if user has access to a privilege including hierarchy
  bool hasAccessToPrivilege(String targetPrivilege) {
    if (!isAuthenticated) return false;

    final requiredHierarchy = PrivilegeHierarchy.getRequiredPrivilegeHierarchy(
      targetPrivilege,
    );

    for (final privilege in requiredHierarchy) {
      if (!hasPrivilege(privilege)) {
        return false;
      }
    }

    return true;
  }

  /// Get available dashboards for the user
  List<String> getAvailableDashboards() {
    if (!isAuthenticated) return [];

    return PrivilegeHierarchy.getDashboardPrivileges()
        .where((dashboard) => hasPrivilege(dashboard))
        .toList();
  }

  /// Get features for a specific dashboard - FIXED METHOD
  List<Privilege> getFeaturesForDashboard(String dashboardUri) {
    if (!isAuthenticated) return [];

    final userPrivileges = _getUserPrivileges();
    final featureUris = PrivilegeHierarchy.getFeaturesForDashboard(
      dashboardUri,
      userPrivileges.map((p) => p.uri).toList(),
    );

    return userPrivileges.where((p) => featureUris.contains(p.uri)).toList();
  }

  /// Get user's privileges grouped by dashboard
  Map<String, List<String>> getPrivilegesByDashboard() {
    if (!isAuthenticated) return {};

    final Map<String, List<String>> result = {};
    final userPrivileges = _getUserPrivilegeUris();

    for (final dashboard in PrivilegeHierarchy.getDashboardPrivileges()) {
      if (userPrivileges.contains(dashboard)) {
        final features = PrivilegeHierarchy.getFeaturesForDashboard(
          dashboard,
          userPrivileges,
        );
        result[dashboard] = features;
      }
    }

    return result;
  }

  /// Get all privileges from user (handles both userWithRole and direct privileges)
  List<Privilege> _getUserPrivileges() {
    if (userWithRole != null) {
      return userWithRole!.allPrivileges;
    }
    return privileges;
  }

  /// Helper method to get all privilege URIs from user
  List<String> _getUserPrivilegeUris() {
    return _getUserPrivileges().map((p) => p.uri).toList();
  }

  // --- Factory methods for common states ---
  factory AuthState.initial() {
    return const AuthState(
      status: AuthStatus.initial,
      roles: [],
      privileges: [],
    );
  }

  factory AuthState.loading() {
    return AuthState.initial().copyWith(status: AuthStatus.loading);
  }

  factory AuthState.authenticated({
    required UserModel userId,
    required String username,
    required List<Privilege> privileges,
    required List<Role> roles,
    UserWithRole? userWithRole,
    int? companyId,
    int? branchId,
  }) {
    return AuthState(
      status: AuthStatus.authenticated,
      userId: userId,
      username: username,
      privileges: privileges,
      roles: roles,
      userWithRole: userWithRole,
      companyId: companyId,
      branchId: branchId,
      authenticatedAt: DateTime.now(),
      tokenExpiryTime: DateTime.now().add(const Duration(hours: 2)), // Example
    );
  }

  factory AuthState.unauthenticated({String? message}) {
    return AuthState.initial().copyWith(
      status: AuthStatus.unauthenticated,
      message: message,
      lastLogoutAt: DateTime.now(),
    );
  }

  factory AuthState.error(String message, {AuthErrorType? errorType}) {
    return AuthState.initial().copyWith(
      status: AuthStatus.error,
      message: message,
      errorType: errorType,
      occuredAt: DateTime.now(),
    );
  }

  // --- CopyWith for immutability ---
  AuthState copyWith({
    AuthStatus? status,
    String? message,
    UserModel? userId,
    String? username,
    int? companyId,
    int? branchId,
    List<Role>? roles,
    List<Privilege>? privileges,
    UserWithRole? userWithRole,
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
      branchId: branchId ?? this.branchId,
      roles: roles ?? this.roles,
      privileges: privileges ?? this.privileges,
      userWithRole: userWithRole ?? this.userWithRole,
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
    branchId,
    roles,
    privileges,
    userWithRole,
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
