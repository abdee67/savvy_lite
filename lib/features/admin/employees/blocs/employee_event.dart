import 'package:meta/meta.dart';
import 'package:savvy_stock/features/admin/employees/models/employee_model.dart';

@immutable
abstract class EmployeeEvent {}

class LoadEmployees extends EmployeeEvent {
  final int companyId;
  LoadEmployees(this.companyId);
}

class CreateEmployee extends EmployeeEvent {
  final int id;
  final String nameFirst;
  final String nameLast;
  final String title;
  final String email;
  final String phone;
  final String address;
  final String city;
  final String state;
  final String zip;
  final String country;
  final String? notes;
  final int companyId;
  CreateEmployee(
    this.id,
    this.nameFirst,
    this.nameLast,
    this.title,
    this.email,
    this.phone,
    this.address,
    this.city,
    this.state,
    this.zip,
    this.country,
    this.notes,
    this.companyId,
  );
}

class UpdateEmployee extends EmployeeEvent {
  final int id;
  final String nameFirst;
  final String nameLast;
  final String title;
  final String email;
  final String phone;
  final String address;
  final String city;
  final String state;
  final String zip;
  final String country;
  final String? notes;
  final int companyId;
  UpdateEmployee(
    this.id,
    this.nameFirst,
    this.nameLast,
    this.title,
    this.email,
    this.phone,
    this.address,
    this.city,
    this.state,
    this.zip,
    this.country,
    this.notes,
    this.companyId,
  );
}

class DeleteEmployee extends EmployeeEvent {
  final int employeeId;
  final int deletedIndex;
  final int companyId;
  final Employee deletedEmployee;
  DeleteEmployee(
    this.employeeId,
    this.deletedIndex,
    this.companyId,
    this.deletedEmployee,
  );
}

class DeleteSelectedEmployees extends EmployeeEvent {
  final List<int> selectedEmployees;
  final List<Employee> deletedEmployees;
  final List<int> deletedIndexes;
  final int companyId;
  DeleteSelectedEmployees(
    this.selectedEmployees,
    this.deletedEmployees,
    this.deletedIndexes,
    this.companyId,
  );
}

class SearchEmployees extends EmployeeEvent {
  final String query;
  SearchEmployees(this.query);
}

class SelectEmployee extends EmployeeEvent {
  final Employee employee;
  final bool isSelected;
  SelectEmployee(this.employee, {this.isSelected = true});

  List<Object> get props => [employee, isSelected];
}

class SelectAllEmployees extends EmployeeEvent {
  final bool selectAll;
  SelectAllEmployees(this.selectAll);

  List<Object> get props => [selectAll];
}

class ClearSelection extends EmployeeEvent {}

class UndoDelete extends EmployeeEvent {
  final List<Employee> deletedItems;
  final List<int> deletedIndexes;

  UndoDelete({required this.deletedItems, required this.deletedIndexes});
}

class ShowEmployeeDetail extends EmployeeEvent {
  final Employee employee;
  ShowEmployeeDetail(this.employee);

  List<Object> get props => [employee];
}

class HideEmployeeDetail extends EmployeeEvent {}

class ExportEmployee extends EmployeeEvent {
  final Employee employee;
  ExportEmployee(this.employee);

  List<Object> get props => [employee];
}
