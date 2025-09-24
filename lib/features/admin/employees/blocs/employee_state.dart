import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/admin/employees/models/employee_model.dart';
import 'package:savvy_stock/features/admin/privilege/models/privilege_model.dart';
import 'package:savvy_stock/features/admin/role/models/role_model.dart';

enum EmployeeStatus { initial, loading, success, failure }

class EmployeeState extends Equatable {
  final EmployeeStatus status;
  final String? message;

  final List<Employee> employees;
  final List<Role> roles;

  final EmployeeErrorType? errorType;
  final DateTime? occuredAt;

  const EmployeeState({
    required this.status,
    this.message,
    this.employees = const [],
    this.roles = const [],
    this.errorType,
    this.occuredAt,
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

  // --- CopyWith for immutability ---
  EmployeeState copyWith({
    EmployeeStatus? status,
    String? message,
    List<Employee>? Employees,
    EmployeeErrorType? errorType,
    DateTime? occuredAt,
  }) {
    return EmployeeState(
      status: status ?? this.status,
      message: message ?? this.message,
      employees: employees ?? this.employees,
      errorType: errorType ?? this.errorType,
      occuredAt: occuredAt ?? this.occuredAt,
    );
  }

  @override
  List<Object?> get props => [status, message, employees, errorType, occuredAt];
}

// Optional enum for error types
enum EmployeeErrorType { networkError, serverError, unknown }
