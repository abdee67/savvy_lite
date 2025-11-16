import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/admin/privilege/models/privilege_model.dart';
import 'package:savvy_stock/features/admin/role/models/role_model.dart';

enum PrivilegeStatus { initial, loading, success, failure }

class PrivilegeState extends Equatable {
  final PrivilegeStatus status;
  final String? message;

  final List<Privilege> privileges;
  final List<Role> roles;

  final PrivilegeErrorType? errorType;
  final DateTime? occuredAt;

  const PrivilegeState({
    required this.status,
    this.message,
    this.privileges = const [],
    this.roles = const [],
    this.errorType,
    this.occuredAt,
  });

  // --- Helper Getters ---

  bool get isLoading => status == PrivilegeStatus.loading;

  bool get isSuccess => status == PrivilegeStatus.success;

  bool get isFailure => status == PrivilegeStatus.failure;

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

  // --- CopyWith for immutability ---
  PrivilegeState copyWith({
    PrivilegeStatus? status,
    String? message,
    List<Privilege>? privileges,
    PrivilegeErrorType? errorType,
    DateTime? occuredAt,
  }) {
    return PrivilegeState(
      status: status ?? this.status,
      message: message ?? this.message,
      privileges: privileges ?? this.privileges,
      errorType: errorType ?? this.errorType,
      occuredAt: occuredAt ?? this.occuredAt,
    );
  }

  @override
  List<Object?> get props => [
    status,
    message,
    privileges,
    errorType,
    occuredAt,
  ];
}

// Optional enum for error types
enum PrivilegeErrorType { networkError, serverError, unknown }
