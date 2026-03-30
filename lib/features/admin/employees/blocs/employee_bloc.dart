import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:savvy_stock/features/admin/employees/blocs/employee_event.dart';
import 'package:savvy_stock/features/admin/employees/blocs/employee_state.dart';
import 'package:savvy_stock/features/admin/employees/models/employee_model.dart';
import 'package:savvy_stock/features/admin/employees/repo/employees_repo.dart';
import 'package:savvy_stock/features/admin/role/models/role_model.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';

class EmployeeBloc extends Bloc<EmployeeEvent, EmployeeState> {
  final EmployeeRepository repository;
  final AuthBloc authBloc;
  StreamSubscription? _authSubscription;

  EmployeeBloc({required this.repository, required this.authBloc})
    : super(const EmployeeState()) {
    // Listen to auth state changes
    _authSubscription = authBloc.stream.listen((authState) {
      if (authState.isAuthenticated && authState.companyId != null) {
        add(LoadEmployees(authState.companyId!));
      }
    });

    on<LoadEmployees>(_onLoadEmployees);
    on<CreateEmployee>(_onCreateEmployee);
    on<UpdateEmployee>(_onUpdateEmployee);
    on<DeleteEmployee>(_onDeleteEmployee);
    on<SearchEmployees>(_onSearchEmployees);
    on<SelectEmployee>(_onSelectEmployee);
    on<SelectAllEmployees>(_onSelectAllEmployees);
    on<DeleteSelectedEmployees>(_onDeleteSelectedEmployees);
    on<UndoDelete>(_onUndoDelete);
    on<ShowEmployeeDetail>(_onShowEmployeeDetail);
    on<HideEmployeeDetail>(_onHideEmployeeDetail);
    on<ExportEmployee>(_onExportEmployee);
    on<ExportSingleEmployee>(_onExportSingleEmployee);
    on<ClearSelection>(_onClearSelection);
    on<SetEmployeeForm>(_onSetEmployeeForm);
    on<ResetEmployeeForm>(_onResetEmployeeForm);
    on<ChangeEmployeePage>(_onChangeEmployeePage);
    on<UpdateEmployeeFormField>(_onUpdateEmployeeFormField);
    on<ToggleRoleManagement>(_onToggleRoleManagement);
    on<SelectRoleForAssignment>(_onSelectRoleForAssignment);
    on<DeselectRoleForAssignment>(_onDeselectRoleForAssignment);
    on<ClearRoleSelection>(_onClearRoleSelection);
    on<SaveRoleChanges>(_onSaveRoleChanges);
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadEmployees(
    LoadEmployees event,
    Emitter<EmployeeState> emit,
  ) async {
    emit(state.copyWith(status: EmployeeStatus.loading));
    try {
      final employees = await repository.loadEmployees(event.companyId);

      emit(
        state.copyWith(
          status: EmployeeStatus.success,
          employees: employees,
          filteredEmployees: employees,
          searchQuery: '',
          detailStatus: EmployeeDetailStatus.hidden,
          companyId: event.companyId,
          selectedEmployees: [],
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: EmployeeStatus.failure,
          message: 'Failed to load Employees: $e',
        ),
      );
    }
  }

  Future<void> _onCreateEmployee(
    CreateEmployee event,
    Emitter<EmployeeState> emit,
  ) async {
    emit(
      state.copyWith(
        status: EmployeeStatus.creating,
        message: 'Creating Employee...',
      ),
    );
    try {
      await repository.insertEmployee(
        event.employee,
        authBloc.state.companyId!,
      );

      add(LoadEmployees(authBloc.state.companyId!));
      emit(
        state.copyWith(
          status: EmployeeStatus.created,
          message: 'Employee created successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: EmployeeStatus.creatingFailed,
          message: 'Failed to create Employee: $e',
        ),
      );
    }
  }

  Future<void> _onUpdateEmployee(
    UpdateEmployee event,
    Emitter<EmployeeState> emit,
  ) async {
    emit(
      state.copyWith(
        status: EmployeeStatus.updating,
        message: 'Updating Employee...',
      ),
    );
    try {
      await repository.updateEmployee(
        event.employee,
        authBloc.state.companyId!,
      );

      add(LoadEmployees(authBloc.state.companyId!));
      emit(
        state.copyWith(
          status: EmployeeStatus.success,
          message: 'Employee updated successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: EmployeeStatus.failure,
          message: 'Failed to update Employee: $e',
        ),
      );
    }
  }

  void _onSetEmployeeForm(SetEmployeeForm event, Emitter<EmployeeState> emit) {
    emit(state.copyWith(employeeForm: event.employee));
  }

  void _onResetEmployeeForm(
    ResetEmployeeForm event,
    Emitter<EmployeeState> emit,
  ) {
    emit(state.copyWith(employeeForm: Employee.empty()));
  }

  void _onChangeEmployeePage(
    ChangeEmployeePage event,
    Emitter<EmployeeState> emit,
  ) {
    emit(state.copyWith(currentPage: event.pageIndex));
  }

  void _onUpdateEmployeeFormField(
    UpdateEmployeeFormField event,
    Emitter<EmployeeState> emit,
  ) {
    final updatedEmployee = state.employeeForm!.copyWithField(
      event.field,
      event.value,
    );
    emit(state.copyWith(employeeForm: updatedEmployee));
  }

  Future<void> _onDeleteEmployee(
    DeleteEmployee event,
    Emitter<EmployeeState> emit,
  ) async {
    emit(
      state.copyWith(status: EmployeeStatus.deleting, message: 'Deleting..'),
    );
    try {
      await repository.deleteEmployee(
        event.employeeId,
        authBloc.state.companyId!,
      );

      final updateEmployees = List<Employee>.from(state.employees)
        ..removeWhere((p) => p.id == event.employeeId);
      final updateFilteredEmployees = List<Employee>.from(
        state.filteredEmployees,
      )..removeWhere((p) => p.id == event.employeeId);

      emit(
        state.copyWith(
          employees: updateEmployees,
          filteredEmployees: updateFilteredEmployees,
          recentlyDeleted: [...state.recentlyDeleted, event.deletedEmployee],
          recentlyDeletedIndexes: [
            ...state.recentlyDeletedIndexes,
            event.deletedIndex,
          ],
          message: 'Employee deleted successfully',
        ),
      );

      add(LoadEmployees(authBloc.state.companyId!));
    } catch (e) {
      emit(
        state.copyWith(
          status: EmployeeStatus.failure,
          message: 'Failed to delete Employee: $e',
        ),
      );
    }
  }

  void _onClearSelection(ClearSelection event, Emitter<EmployeeState> emit) {
    emit(state.copyWith(selectedEmployees: []));
  }

  Future<void> _onSearchEmployees(
    SearchEmployees event,
    Emitter<EmployeeState> emit,
  ) async {
    final query = event.query.toLowerCase().trim();

    if (query.isEmpty) {
      emit(
        state.copyWith(
          filteredEmployees: state.employees,
          selectedEmployees: [],
          searchQuery: '',
          status: EmployeeStatus.success,
        ),
      );
      return;
    }

    try {
      // Use repository for search to handle large datasets efficiently
      final filtered = await repository.searchEmployees(
        query,
        authBloc.state.companyId!,
      );

      emit(
        state.copyWith(
          filteredEmployees: filtered,
          searchQuery: query,
          selectedEmployees: [],
          status: EmployeeStatus.searching,
        ),
      );
    } catch (e) {
      // Fallback to client-side search if repository search fails
      final filtered = state.employees.where((employee) {
        return employee.nameFirst.toLowerCase().contains(query) ||
            employee.nameLast.toLowerCase().contains(query) ||
            employee.phoneHome.toLowerCase().contains(query) ||
            employee.email.toLowerCase().contains(query);
      }).toList();

      emit(
        state.copyWith(
          filteredEmployees: filtered,
          searchQuery: query,
          selectedEmployees: [],
          status: EmployeeStatus.searching,
        ),
      );
    }
  }

  void _onSelectEmployee(SelectEmployee event, Emitter<EmployeeState> emit) {
    final selectedEmployees = List<Employee>.from(state.selectedEmployees);
    if (event.isSelected) {
      selectedEmployees.add(event.employee);
    } else {
      selectedEmployees.removeWhere(
        (employee) => employee.id == event.employee.id,
      );
    }
    emit(state.copyWith(selectedEmployees: selectedEmployees));
  }

  void _onSelectAllEmployees(
    SelectAllEmployees event,
    Emitter<EmployeeState> emit,
  ) {
    if (state.selectedEmployees.length == event.employees.length) {
      // If all are selected, clear selection
      emit(state.copyWith(selectedEmployees: []));
    } else {
      // Select all
      emit(state.copyWith(selectedEmployees: List.from(event.employees)));
    }
  }

  Future<void> _onDeleteSelectedEmployees(
    DeleteSelectedEmployees event,
    Emitter<EmployeeState> emit,
  ) async {
    try {
      final employeeIds = event.selectedEmployees;

      await repository.deleteMultipleEmployees(
        employeeIds,
        authBloc.state.companyId!,
      );

      final updatedEmployees = state.employees
          .where((e) => !employeeIds.contains(e.id))
          .toList();
      final updatedFiltered = state.filteredEmployees
          .where((e) => !employeeIds.contains(e.id))
          .toList();

      emit(
        state.copyWith(
          employees: updatedEmployees,
          filteredEmployees: updatedFiltered,
          selectedEmployees: [],
          recentlyDeleted: [
            ...state.recentlyDeleted,
            ...event.deletedEmployees,
          ],
          recentlyDeletedIndexes: [
            ...state.recentlyDeletedIndexes,
            ...event.deletedIndexes,
          ],
          message:
              '${event.selectedEmployees.length} employees deleted successfully',
        ),
      );

      add(LoadEmployees(authBloc.state.companyId!));
    } catch (e) {
      emit(
        state.copyWith(
          status: EmployeeStatus.failure,
          message: 'Failed to delete selected Employees: $e',
        ),
      );
    }
  }

  Future<void> _onUndoDelete(
    UndoDelete event,
    Emitter<EmployeeState> emit,
  ) async {
    try {
      // Restore to database
      await repository.batchInsertEmployees(event.deletedItems);

      // Reinsert at original positions in memory
      final updatedEmployees = List<Employee>.from(state.employees);

      // Restore items at their original positions
      for (int i = 0; i < event.deletedItems.length; i++) {
        final item = event.deletedItems[i];
        final index = event.deletedIndexes[i];

        if (index >= 0 && index <= updatedEmployees.length) {
          updatedEmployees.insert(index, item);
        } else {
          updatedEmployees.add(item); // fallback if index is invalid
        }
      }

      emit(
        state.copyWith(
          employees: updatedEmployees,
          filteredEmployees: updatedEmployees,
          recentlyDeleted: [],
          recentlyDeletedIndexes: [],
          message:
              '${event.deletedItems.length} employees restored successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: EmployeeStatus.failure,
          message: 'Failed to undo delete: $e',
        ),
      );
    }
  }

  void _onShowEmployeeDetail(
    ShowEmployeeDetail event,
    Emitter<EmployeeState> emit,
  ) {
    emit(
      state.copyWith(
        employeeDetail: event.employee,
        detailStatus: EmployeeDetailStatus.showing,
      ),
    );
  }

  void _onHideEmployeeDetail(
    HideEmployeeDetail event,
    Emitter<EmployeeState> emit,
  ) {
    emit(
      state.copyWith(
        detailStatus: EmployeeDetailStatus.hidden,
        employeeDetail: null,
      ),
    );
  }

  void _onExportEmployee(ExportEmployee event, Emitter<EmployeeState> emit) {
    emit(state.copyWith(status: EmployeeStatus.exporting, isExporting: true));

    // Simulate export process
    Future.delayed(const Duration(seconds: 2), () {
      emit(
        state.copyWith(
          status: EmployeeStatus.success,
          isExporting: false,
          exportedEmployees: event.employeesToExport,
          message:
              'Exported ${event.employeesToExport.length} employees successfully',
        ),
      );
    });
  }

  void _onExportSingleEmployee(
    ExportSingleEmployee event,
    Emitter<EmployeeState> emit,
  ) {
    emit(state.copyWith(status: EmployeeStatus.exporting, isExporting: true));

    // Simulate export process
    Future.delayed(const Duration(seconds: 2), () {
      emit(
        state.copyWith(
          status: EmployeeStatus.success,
          isExporting: false,
          exportedEmployee: event.employeeToExport,
          message: 'Exported employee successfully',
        ),
      );
    });
  }

  Future<void> _onToggleRoleManagement(
    ToggleRoleManagement event,
    Emitter<EmployeeState> emit,
  ) async {
    if (state.isRoleManagementMode) {
      emit(
        state.copyWith(
          isRoleManagementMode: false,
          employeeInRoleManagement: null,
          selectedRolesForAssignment: [],
          roleSearchQuery: '',
          hasRoleChanges: false,
        ),
      );
    } else {
      // Entering role management mode - only if employee has user account
      final employee = await repository.getEmployeeById(
        event.employeeId,
        authBloc.state.companyId!,
      );

      if (employee == null) {
        // Employee not found, don't enter role management
        emit(state);
        return;
      }

      // Check if this employee has a user account
      final hasUserAccount = await repository.checkIfEmployeeHasUserAccount(
        event.employeeId,
      );

      if (!hasUserAccount) {
        // Employee doesn't have user account, don't enter role management
        emit(state);
        return;
      }

      emit(
        state.copyWith(
          isRoleManagementMode: true,
          employeeInRoleManagement: event.employeeId,
          selectedRolesForAssignment: [],
          roleSearchQuery: '',
          hasRoleChanges: false,
        ),
      );
    }
  }

  void _onSelectRoleForAssignment(
    SelectRoleForAssignment event,
    Emitter<EmployeeState> emit,
  ) {
    final selectedRoles = List<Role>.from(state.selectedRolesForAssignment);

    if (selectedRoles.any((role) => role.id == event.role.id)) {
      selectedRoles.removeWhere((role) => role.id == event.role.id);
    } else {
      selectedRoles.add(event.role);
    }

    emit(
      state.copyWith(
        selectedRolesForAssignment: selectedRoles,
        hasRoleChanges: selectedRoles.isNotEmpty,
      ),
    );
  }

  void _onDeselectRoleForAssignment(
    DeselectRoleForAssignment event,
    Emitter<EmployeeState> emit,
  ) {
    final selectedRoles = List<Role>.from(state.selectedRolesForAssignment);
    selectedRoles.removeWhere((role) => role.id == event.role.id);

    emit(
      state.copyWith(
        selectedRolesForAssignment: selectedRoles,
        hasRoleChanges: selectedRoles.isNotEmpty,
      ),
    );
  }

  void _onClearRoleSelection(
    ClearRoleSelection event,
    Emitter<EmployeeState> emit,
  ) {
    emit(state.copyWith(selectedRolesForAssignment: [], hasRoleChanges: false));
  }

  void _onSaveRoleChanges(SaveRoleChanges event, Emitter<EmployeeState> emit) {
    // This will be handled by the UI using UserBloc directly
    // We just reset the state
    emit(
      state.copyWith(
        selectedRolesForAssignment: [],
        hasRoleChanges: false,
        isRoleManagementMode: false,
        employeeInRoleManagement: null,
      ),
    );
  }

  // Public helper methods
  Future<Employee?> getEmployeeById(int employeeId) async {
    return await repository.getEmployeeById(
      employeeId,
      authBloc.state.companyId!,
    );
  }

  Future<List<Employee>> getEmployeesByIds(List<int> employeeIds) async {
    return await repository.getEmployeesByIds(
      employeeIds,
      authBloc.state.companyId!,
    );
  }
}
