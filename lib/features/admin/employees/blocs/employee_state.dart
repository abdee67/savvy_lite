import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/admin/employees/models/employee_model.dart';
import 'package:savvy_stock/features/admin/role/models/role_model.dart';

enum EmployeeStatus {
  initial,
  loading,
  searching,
  success,
  failure,
  creating,
  updating,
  deleting,
  exporting,
}

enum EmployeeDetailStatus { hidden, showing, editing }

class EmployeeState extends Equatable {
  final EmployeeStatus status;
  final String? message;
  final int? employeeId;
  final int? companyId;
  final List<Employee> employees;
  final List<Employee> filteredEmployees;
  final String searchQuery;
  final List<Employee> selectedEmployees;
  final List<Role> selectedRolesForAssignment;
  final bool hasRoleChanges;

  final EmployeeDetailStatus detailStatus;
  final Employee? employeeDetail;
  final Employee? employeeForm;

  final List<Employee> recentlyDeleted;
  final List<int> recentlyDeletedIndexes;

  final int currentPage;
  final bool isExporting;
  final List<Employee> exportedEmployees; //export multiple employees
  final Employee? exportedEmployee; //export single employee

  // Role management state
  final bool isRoleManagementMode;
  final String roleSearchQuery;
  final int? employeeInRoleManagement;

  const EmployeeState({
    this.status = EmployeeStatus.initial,
    this.message,
    this.employeeId,
    this.companyId,
    this.employees = const [],
    this.filteredEmployees = const [],
    this.searchQuery = '',
    this.selectedEmployees = const [],
    this.detailStatus = EmployeeDetailStatus.hidden,
    this.employeeDetail,
    this.employeeForm,
    this.recentlyDeleted = const [],
    this.recentlyDeletedIndexes = const [],
    this.currentPage = 0,
    this.isExporting = false,
    this.exportedEmployees = const [],
    this.exportedEmployee,
    this.isRoleManagementMode = false,
    this.roleSearchQuery = '',
    this.employeeInRoleManagement,
    this.selectedRolesForAssignment = const [],
    this.hasRoleChanges = false,
  });

  // --- Helper Getters ---
  bool get isLoading => status == EmployeeStatus.loading;
  bool get isSuccess => status == EmployeeStatus.success;
  bool get isFailure => status == EmployeeStatus.failure;
  bool get isCreating => status == EmployeeStatus.creating;
  bool get isUpdating => status == EmployeeStatus.updating;
  bool get isDeleting => status == EmployeeStatus.deleting;
  bool get isExportingData => status == EmployeeStatus.exporting;

  bool get isDetailVisible => detailStatus != EmployeeDetailStatus.hidden;
  bool get isDetailEditing => detailStatus == EmployeeDetailStatus.editing;

  bool get hasEmployees => employees.isNotEmpty;
  bool get hasFilteredEmployees => filteredEmployees.isNotEmpty;
  bool get hasSelection => selectedEmployees.isNotEmpty;
  bool get canEdit => selectedEmployees.length == 1;
  bool get canDelete => selectedEmployees.isNotEmpty;
  bool get canExport => filteredEmployees.isNotEmpty;

  bool get hasRecentDeletions => recentlyDeleted.isNotEmpty;

  bool get isRoleManagementModeActive =>
      isRoleManagementMode && employeeInRoleManagement != null;

  Employee get currentEmployeeForm => employeeForm!;

  // --- CopyWith for immutability ---
  EmployeeState copyWith({
    EmployeeStatus? status,
    String? message,
    int? employeeId,
    int? companyId,
    List<Employee>? employees,
    List<Employee>? filteredEmployees,
    String? searchQuery,
    List<Employee>? selectedEmployees,
    EmployeeDetailStatus? detailStatus,
    Employee? employeeDetail,
    Employee? employeeForm,
    List<Employee>? recentlyDeleted,
    List<int>? recentlyDeletedIndexes,
    int? currentPage,
    bool? isExporting,
    List<Employee>? exportedEmployees,
    Employee? exportedEmployee,
    bool? isRoleManagementMode,
    String? roleSearchQuery,
    int? employeeInRoleManagement,
    List<Role>? selectedRolesForAssignment,
    bool? hasRoleChanges,
  }) {
    return EmployeeState(
      status: status ?? this.status,
      message: message ?? this.message,
      employeeId: employeeId ?? this.employeeId,
      companyId: companyId ?? this.companyId,
      employees: employees ?? this.employees,
      filteredEmployees: filteredEmployees ?? this.filteredEmployees,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedEmployees: selectedEmployees ?? this.selectedEmployees,
      detailStatus: detailStatus ?? this.detailStatus,
      employeeDetail: employeeDetail ?? this.employeeDetail,
      employeeForm: employeeForm ?? this.employeeForm,
      recentlyDeleted: recentlyDeleted ?? this.recentlyDeleted,
      recentlyDeletedIndexes:
          recentlyDeletedIndexes ?? this.recentlyDeletedIndexes,
      currentPage: currentPage ?? this.currentPage,
      isExporting: isExporting ?? this.isExporting,
      exportedEmployees: exportedEmployees ?? this.exportedEmployees,
      exportedEmployee: exportedEmployee ?? this.exportedEmployee,
      isRoleManagementMode: isRoleManagementMode ?? this.isRoleManagementMode,
      roleSearchQuery: roleSearchQuery ?? this.roleSearchQuery,
      employeeInRoleManagement:
          employeeInRoleManagement ?? this.employeeInRoleManagement,
      selectedRolesForAssignment:
          selectedRolesForAssignment ?? this.selectedRolesForAssignment,
      hasRoleChanges: hasRoleChanges ?? this.hasRoleChanges,
    );
  }

  @override
  List<Object?> get props => [
    status,
    message,
    employeeId,
    companyId,
    employees,
    filteredEmployees,
    searchQuery,
    selectedEmployees,
    detailStatus,
    employeeDetail,
    employeeForm,
    recentlyDeleted,
    recentlyDeletedIndexes,
    currentPage,
    isExporting,
    exportedEmployees,
    exportedEmployee,
    isRoleManagementMode,
    roleSearchQuery,
    employeeInRoleManagement,
    selectedRolesForAssignment,
    hasRoleChanges,
  ];
}
