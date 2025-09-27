// features/Employee/blocs/Employee_bloc.dart

import 'package:bloc/bloc.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/admin/employees/blocs/employee_event.dart';
import 'package:savvy_stock/features/admin/employees/blocs/employee_state.dart';
import 'package:savvy_stock/features/admin/employees/models/employee_model.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:sqflite/sqflite.dart';

class EmployeeBloc extends Bloc<EmployeeEvent, EmployeeState> {
  final LocalDatabaseService databaseService;
  final AuthBloc authBloc;

  EmployeeBloc({required this.databaseService, required this.authBloc})
    : super(EmployeeState(status: EmployeeStatus.initial)) {
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
    on<ClearSelection>(_onClearSelection);
    on<SetEmployeeForm>(_onSetEmployeeForm);
    on<ResetEmployeeForm>(_onResetEmployeeForm);
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
      );

      final employeeList = employees.map((p) => Employee.fromMap(p)).toList();

      emit(
        EmployeeState(
          status: EmployeeStatus.success,
          employees: employeeList,
          filteredEmployees: employeeList,
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
        status: EmployeeStatus.loading,
        message: 'Creating Employee...',
      ),
    );
    try {
      final db = await databaseService.database;
      final employeeMap = event.employee.toMap();

      //remove id for new employee insrtion
      employeeMap.remove('id');

      await db.insert('employees', employeeMap);
      emit(
        state.copyWith(
          status: EmployeeStatus.success,
          message: 'Employee created successfully',
        ),
      );
      add(LoadEmployees(authBloc.state.companyId!)); // Reload the list
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
        status: EmployeeStatus.loading,
        message: 'Updating Employee...',
      ),
    );
    try {
      final db = await databaseService.database;
      await db.update(
        'employees',
        event.employee.toMap(),
        where: 'id = ?',
        whereArgs: [event.employee.id],
      );
      emit(
        state.copyWith(
          status: EmployeeStatus.success,
          message: 'Employee updated successfully',
        ),
      );
      add(LoadEmployees(authBloc.state.companyId!)); // Reload the list
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

  Future<void> _onDeleteEmployee(
    DeleteEmployee event,
    Emitter<EmployeeState> emit,
  ) async {
    emit(EmployeeState(status: EmployeeStatus.loading, message: 'Deleting..'));
    try {
      final db = await databaseService.database;
      await db.delete(
        'employees',
        where: 'id = ? AND company = ?',
        whereArgs: [event.employeeId, authBloc.state.companyId],
      );
      final updateEmployees = List<Employee>.from(state.employees)
        ..removeWhere((p) => p.id == event.employeeId);
      emit(
        state.copyWith(
          employees: updateEmployees,
          filteredEmployees: updateEmployees,
          recentlyDeleted: [event.deletedEmployee],
          recentlyDeletedIndexes: [event.deletedIndex],
        ),
      );
      add(LoadEmployees(authBloc.state.companyId!)); // Reload the list
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
    final query = event.query.toLowerCase();

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
        selectedEmployees: [],

        searchQuery: query,
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
    final selectedEmployees = List<Employee>.from(state.filteredEmployees);
    emit(state.copyWith(selectedEmployees: selectedEmployees));
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

      emit(
        state.copyWith(
          employees: updatedEmployees,
          filteredEmployees: updatedEmployees,
          selectedEmployees: [],
          recentlyDeleted: event.deletedEmployees,
          recentlyDeletedIndexes: event.deletedIndexes,
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
    emit(state.copyWith(employeeDetail: event.employee, showDetailPanel: true));
  }

  void _onHideEmployeeDetail(
    HideEmployeeDetail event,
    Emitter<EmployeeState> emit,
  ) {
    emit(state.copyWith(showDetailPanel: false));
  }

  void _onExportEmployee(ExportEmployee event, Emitter<EmployeeState> emit) {
    emit(state.copyWith(filteredEmployees: state.filteredEmployees));
  }
}
