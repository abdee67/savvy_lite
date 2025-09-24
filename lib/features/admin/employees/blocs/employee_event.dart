import 'package:meta/meta.dart';
import 'package:savvy_stock/features/admin/employees/models/employee_model.dart';

@immutable
abstract class EmployeeEvent {}

class LoadEmployees extends EmployeeEvent {}

class CreateEmployee extends EmployeeEvent {
  final Employee employee;
  CreateEmployee(this.employee);
}

class UpdateEmployee extends EmployeeEvent {
  final Employee employee;
  UpdateEmployee(this.employee);
}

class DeleteEmployee extends EmployeeEvent {
  final int employeeId;
  DeleteEmployee(this.employeeId);
}
