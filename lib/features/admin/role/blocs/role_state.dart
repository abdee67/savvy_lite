import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/admin/role/models/role_model.dart';

enum RoleStatus {
  initial,
  loading,
  updating,
  success,
  failure,
  searching,
  deleting,
}

class RoleState extends Equatable {
  final RoleStatus status;
  final String? message;

  final List<Role> roles;
  final List<Role> selectedRoles;
  final List<Role> recentlyDeleted;

  final RoleErrorType? errorType;
  final DateTime? occuredAt;

  final String searchQuery;
  final List<Role> filteredRoles;

  const RoleState({
    required this.status,
    this.message,
    this.roles = const [],
    this.selectedRoles = const [],
    this.recentlyDeleted = const [],
    this.errorType,
    this.occuredAt,
    this.searchQuery = '',
    this.filteredRoles = const [],
  });

  // --- Helper Getters ---

  bool get isLoading => status == RoleStatus.loading;

  bool get isSuccess => status == RoleStatus.success;

  bool get isFailure => status == RoleStatus.failure;
  bool get hasFilteredRoles => filteredRoles.isNotEmpty;
  bool get hasSelection => selectedRoles.isNotEmpty;
  bool get canEdit => selectedRoles.length == 1;
  bool get canDelete => selectedRoles.isNotEmpty;
  bool get canExport => filteredRoles.isNotEmpty;

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
    List<Role>? selectedRoles,
    List<Role>? recentlyDeleted,
    RoleErrorType? errorType,
    DateTime? occuredAt,
    String? searchQuery,
    List<Role>? filteredRoles,
  }) {
    return RoleState(
      status: status ?? this.status,
      message: message ?? this.message,
      roles: roles ?? this.roles,
      selectedRoles: selectedRoles ?? this.selectedRoles,
      recentlyDeleted: recentlyDeleted ?? this.recentlyDeleted,
      errorType: errorType ?? this.errorType,
      occuredAt: occuredAt ?? this.occuredAt,
      searchQuery: searchQuery ?? this.searchQuery,
      filteredRoles: filteredRoles ?? this.filteredRoles,
    );
  }

  @override
  List<Object?> get props => [
    status,
    message,
    roles,
    selectedRoles,
    recentlyDeleted,
    errorType,
    occuredAt,
    searchQuery,
    filteredRoles,
  ];
}

// Optional enum for error types
enum RoleErrorType { networkError, serverError, unknown }
