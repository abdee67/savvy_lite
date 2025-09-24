import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/admin/role/models/role_model.dart';

enum RoleStatus { initial, loading, success, failure }

class RoleState extends Equatable {
  final RoleStatus status;
  final String? message;

  final List<Role> roles;

  final RoleErrorType? errorType;
  final DateTime? occuredAt;

  const RoleState({
    required this.status,
    this.message,
    this.roles = const [],
    this.errorType,
    this.occuredAt,
  });

  // --- Helper Getters ---

  bool get isLoading => status == RoleStatus.loading;

  bool get isSuccess => status == RoleStatus.success;

  bool get isFailure => status == RoleStatus.failure;

  bool hasRole(String roleName) {
    return roles.any((r) => r.name == roleName);
  }

  bool hasAnyRole(List<String> roleNames) {
    return roles.any((r) => roleNames.contains(r.name));
  }

  // --- CopyWith for immutability ---
  RoleState copyWith({
    RoleStatus? status,
    String? message,
    List<Role>? roles,
    RoleErrorType? errorType,
    DateTime? occuredAt,
  }) {
    return RoleState(
      status: status ?? this.status,
      message: message ?? this.message,
      roles: roles ?? this.roles,
      errorType: errorType ?? this.errorType,
      occuredAt: occuredAt ?? this.occuredAt,
    );
  }

  @override
  List<Object?> get props => [status, message, roles, errorType, occuredAt];
}

// Optional enum for error types
enum RoleErrorType { networkError, serverError, unknown }
