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
  final int companyId;
  DeleteEmployee(this.employeeId, this.companyId);
}
