import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/admin/employees/models/employee_model.dart';
import 'package:savvy_stock/features/admin/role/models/role_model.dart';

enum EmployeeStatus { initial, loading, searching, success, failure }

class EmployeeState extends Equatable {
  final EmployeeStatus status;
  final String? message;
  final int? employeeId;
  final int? companyId;
  final List<Employee> filteredEmployees;
  final String searchQuery;
  final List<Employee> selectedEmployees;
  final bool showDetailPanel;
  final Employee? employeeDetail;
  final Employee? employeeForm;

  final List<Employee> employees;
  final List<Role> roles;

  final EmployeeErrorType? errorType;
  final DateTime? occuredAt;

  // new
  final List<Employee> recentlyDeleted;
  final List<int> recentlyDeletedIndexes;

  const EmployeeState({
    required this.status,
    this.message,
    this.employees = const [],
    this.roles = const [],
    this.errorType,
    this.occuredAt,
    this.employeeId,
    this.companyId,
    this.filteredEmployees = const [],
    this.searchQuery = '',
    this.selectedEmployees = const [],
    this.showDetailPanel = false,
    this.employeeDetail,
    this.employeeForm,
    this.recentlyDeleted = const [],
    this.recentlyDeletedIndexes = const [],
  });
  // --- Helper Getters ---

  bool get isLoading => status == EmployeeStatus.loading;

  bool get isSuccess => status == EmployeeStatus.success;

  bool get isFailure => status == EmployeeStatus.failure;

  bool hasEmployee(String uri) {
    return employees.any((p) => p.employeeId == uri);
  }

  bool hasAnyEmployee(List<String> uris) {
    return employees.any((p) => uris.contains(p.employeeId));
  }

  bool hasRole(String roleName) {
    return roles.any((r) => r.name == roleName);
  }

  bool hasAnyRole(List<String> roleNames) {
    return roles.any((r) => roleNames.contains(r.name));
  }

  bool get isSelectionMode => selectedEmployees.isNotEmpty;
  bool get canEdit => selectedEmployees.length == 1;
  bool get canDelete => selectedEmployees.isNotEmpty;

  // --- CopyWith for immutability ---
  EmployeeState copyWith({
    EmployeeStatus? status,
    String? message,
    List<Employee>? employees,
    List<Role>? roles,
    EmployeeErrorType? errorType,
    DateTime? occuredAt,
    int? employeeId,
    int? companyId,
    List<Employee>? filteredEmployees,
    String? searchQuery,
    List<Employee>? selectedEmployees,
    bool? showDetailPanel,
    Employee? employeeDetail,
    Employee? employeeForm,
    List<Employee>? recentlyDeleted,
    List<int>? recentlyDeletedIndexes,
  }) {
    return EmployeeState(
      status: status ?? this.status,
      message: message ?? this.message,
      employees: employees ?? this.employees,
      roles: roles ?? this.roles,
      errorType: errorType ?? this.errorType,
      occuredAt: occuredAt ?? this.occuredAt,
      employeeId: employeeId ?? this.employeeId,
      companyId: companyId ?? this.companyId,
      filteredEmployees: filteredEmployees ?? this.filteredEmployees,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedEmployees: selectedEmployees ?? this.selectedEmployees,
      showDetailPanel: showDetailPanel ?? this.showDetailPanel,
      employeeDetail: employeeDetail ?? this.employeeDetail,
      employeeForm: employeeForm ?? this.employeeForm,
      recentlyDeleted: recentlyDeleted ?? this.recentlyDeleted,
      recentlyDeletedIndexes:
          recentlyDeletedIndexes ?? this.recentlyDeletedIndexes,
    );
  }

  @override
  List<Object?> get props => [
    status,
    message,
    employees,
    roles,
    errorType,
    occuredAt,
    employeeId,
    companyId,
    filteredEmployees,
    searchQuery,
    selectedEmployees,
    showDetailPanel,
    employeeDetail,
    employeeForm,
    recentlyDeleted,
    recentlyDeletedIndexes,
  ];
}

// Optional enum for error types
enum EmployeeErrorType { networkError, serverError, unknown }
