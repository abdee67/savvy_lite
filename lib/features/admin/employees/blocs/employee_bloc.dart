// features/Employee/blocs/Employee_bloc.dart

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/admin/employees/blocs/employee_event.dart';
import 'package:savvy_stock/features/admin/employees/blocs/employee_state.dart';
import 'package:savvy_stock/features/admin/employees/models/employee_model.dart';
import 'package:savvy_stock/features/admin/role/models/role_model.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:sqflite/sqflite.dart';

class EmployeeBloc extends Bloc<EmployeeEvent, EmployeeState> {
  final LocalDatabaseService databaseService;
  final AuthBloc authBloc;
  StreamSubscription? _authSubscription;

  EmployeeBloc({required this.databaseService, required this.authBloc})
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
    emit(EmployeeState(status: EmployeeStatus.loading));
    try {
      final db = await databaseService.database;
      final employees = await db.query(
        'employees',
        where: 'company = ?',
        whereArgs: [event.companyId],
        orderBy: 'name_first ASC, name_last ASC',
      );

      final employeeList = employees.map((p) => Employee.fromMap(p)).toList();

      emit(
        EmployeeState(
          status: EmployeeStatus.success,
          employees: employeeList,
          filteredEmployees: employeeList,
          searchQuery: '',
          detailStatus: EmployeeDetailStatus.hidden,
          companyId: event.companyId,
          selectedEmployees: [],
        ),
      );
    } catch (e) {
      emit(
        EmployeeState(
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
      final db = await databaseService.database;
      final employeeMap = event.employee.toMap();

      //remove id for new employee insrtion
      employeeMap.remove('id');

      //add creation metadata
      employeeMap['company'] = authBloc.state.companyId!;

      await db.insert('employees', employeeMap);
      add(LoadEmployees(authBloc.state.companyId!));
      emit(
        state.copyWith(
          status: EmployeeStatus.success,
          message: 'Employee created successfully',
        ),
      );
    } catch (e) {
      emit(
        EmployeeState(
          status: EmployeeStatus.failure,
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
      final db = await databaseService.database;
      final employeeMap = event.employee.toMap();

      //add update metadata
      await db.update(
        'employees',
        employeeMap,
        where: 'id = ?',
        whereArgs: [event.employee.id, authBloc.state.companyId!],
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
        EmployeeState(
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
      final db = await databaseService.database;
      await db.delete(
        'employees',
        where: 'id = ? AND company = ?',
        whereArgs: [event.employeeId, authBloc.state.companyId!],
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
        EmployeeState(
          status: EmployeeStatus.failure,
          message: 'Failed to delete Employee: $e',
        ),
      );
    }
  }

  void _onClearSelection(ClearSelection event, Emitter<EmployeeState> emit) {
    emit(state.copyWith(selectedEmployees: []));
  }

  void _onSearchEmployees(SearchEmployees event, Emitter<EmployeeState> emit) {
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

    final filtered = state.employees.where((employee) {
      return employee.nameFirst.toLowerCase().contains(query) ||
          employee.nameLast.toLowerCase().contains(query) ||
          employee.phone.toLowerCase().contains(query) ||
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

  void _onDeleteSelectedEmployees(
    DeleteSelectedEmployees event,
    Emitter<EmployeeState> emit,
  ) async {
    try {
      final db = await databaseService.database;
      final placeholders = List.filled(
        event.selectedEmployees.length,
        '?',
      ).join(',');
      final whereArgs = [...event.selectedEmployees, authBloc.state.companyId];
      await db.delete(
        'employees',
        where: 'id IN ($placeholders) AND company = ?',
        whereArgs: whereArgs,
      );
      final updatedEmployees = state.employees
          .where((e) => !event.selectedEmployees.contains(e.id))
          .toList();
      final updatedFiltered = state.filteredEmployees
          .where((e) => !event.selectedEmployees.contains(e.id))
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
        EmployeeState(
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
      final db = await databaseService.database;

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

        // Also restore to DB
        await db.insert(
          'employees',
          item.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        emit(
          state.copyWith(
            employees: updatedEmployees,
            filteredEmployees: updatedEmployees,
            recentlyDeleted: [],
            recentlyDeletedIndexes: [],
          ),
        );
      }
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
          message: 'Exported ${event.employeeToExport} employees successfully',
        ),
      );
    });
  }

  void _onToggleRoleManagement(
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
      final employee = state.employees.firstWhere(
        (e) => e.id == event.employeeId,
        orElse: () => Employee.empty(),
      );

      if (employee.id == 0) {
        // Employee not found, don't enter role management
        emit(state);
        return;
      }

      // Check if this employee has a user account (you'll need to implement this check)
      final hasUserAccount = await _checkIfEmployeeHasUserAccount(
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

  // Helper method to check if employee has user account
  Future<bool> _checkIfEmployeeHasUserAccount(int employeeId) async {
    try {
      final db = await databaseService.database;
      final users = await db.query(
        'user_table',
        where: 'employees_id = ?',
        whereArgs: [employeeId],
      );
      return users.isNotEmpty;
    } catch (e) {
      return false;
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
    emit(state.copyWith(selectedRolesForAssignment: [], hasRoleChanges: false));
  }
}
