// features/Employee/blocs/Employee_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/admin/employees/blocs/employee_event.dart';
import 'package:savvy_stock/features/admin/employees/blocs/employee_state.dart';
import 'package:savvy_stock/features/admin/employees/models/employee_model.dart';

class EmployeeBloc extends Bloc<EmployeeEvent, EmployeeState> {
  final LocalDatabaseService databaseService;

  EmployeeBloc({required this.databaseService})
    : super(EmployeeState(status: EmployeeStatus.initial)) {
    on<LoadEmployees>(_onLoadEmployees);
    on<CreateEmployee>(_onCreateEmployee);
    on<UpdateEmployee>(_onUpdateEmployee);
    on<DeleteEmployee>(_onDeleteEmployee);
  }

  Future<void> _onLoadEmployees(
    LoadEmployees event,
    Emitter<EmployeeState> emit,
  ) async {
    emit(EmployeeState(status: EmployeeStatus.loading));
    try {
      final db = await databaseService.database;
      final employees = await db.query('employees');

      final employeeList = employees.map((p) => Employee.fromMap(p)).toList();

      emit(
        EmployeeState(status: EmployeeStatus.success, employees: employeeList),
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
    try {
      final db = await databaseService.database;
      await db.insert('employees', event.employee.toMap());

      add(LoadEmployees()); // Reload the list
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
    try {
      final db = await databaseService.database;
      await db.update(
        'employees',
        event.employee.toMap(),
        where: 'id = ?',
        whereArgs: [event.employee.id],
      );

      add(LoadEmployees()); // Reload the list
    } catch (e) {
      emit(
        EmployeeState(
          status: EmployeeStatus.failure,
          message: 'Failed to update Employee: $e',
        ),
      );
    }
  }

  Future<void> _onDeleteEmployee(
    DeleteEmployee event,
    Emitter<EmployeeState> emit,
  ) async {
    try {
      final db = await databaseService.database;
      await db.delete(
        'employees',
        where: 'id = ?',
        whereArgs: [event.employeeId],
      );

      add(LoadEmployees()); // Reload the list
    } catch (e) {
      emit(
        EmployeeState(
          status: EmployeeStatus.failure,
          message: 'Failed to delete Employee: $e',
        ),
      );
    }
  }
}
