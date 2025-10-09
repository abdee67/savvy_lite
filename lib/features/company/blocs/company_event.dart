import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:savvy_stock/features/admin/employees/models/employee_model.dart';
import 'package:savvy_stock/features/admin/role/models/role_model.dart';

@immutable
abstract class EmployeeEvent extends Equatable {
  const EmployeeEvent();

  @override
  List<Object> get props => [];
}

class LoadEmployees extends EmployeeEvent {
  final int companyId;
  const LoadEmployees(this.companyId);

  @override
  List<Object> get props => [companyId];
}

class CreateEmployee extends EmployeeEvent {
  final Employee employee;
  const CreateEmployee(this.employee);

  @override
  List<Object> get props => [employee];
}

class UpdateEmployee extends EmployeeEvent {
  final Employee employee;
  const UpdateEmployee(this.employee);

  @override
  List<Object> get props => [employee];
}

class DeleteEmployee extends EmployeeEvent {
  final int employeeId;
  final Employee deletedEmployee;
  final int deletedIndex;

  const DeleteEmployee({
    required this.employeeId,
    required this.deletedEmployee,
    required this.deletedIndex,
  });

  @override
  List<Object> get props => [employeeId, deletedEmployee, deletedIndex];
}

class SearchEmployees extends EmployeeEvent {
  final String query;
  const SearchEmployees(this.query);

  @override
  List<Object> get props => [query];
}

class SelectEmployee extends EmployeeEvent {
  final Employee employee;
  final bool isSelected;
  const SelectEmployee(this.employee, this.isSelected);

  @override
  List<Object> get props => [employee, isSelected];
}

class SelectAllEmployees extends EmployeeEvent {
  final List<Employee> employees;
  const SelectAllEmployees(this.employees);

  @override
  List<Object> get props => [employees];
}

class DeleteSelectedEmployees extends EmployeeEvent {
  final List<int> selectedEmployees;
  final List<Employee> deletedEmployees;
  final List<int> deletedIndexes;

  const DeleteSelectedEmployees({
    required this.selectedEmployees,
    required this.deletedEmployees,
    required this.deletedIndexes,
  });

  @override
  List<Object> get props => [
    selectedEmployees,
    deletedEmployees,
    deletedIndexes,
  ];
}

class UndoDelete extends EmployeeEvent {
  final List<Employee> deletedItems;
  final List<int> deletedIndexes;

  const UndoDelete({required this.deletedItems, required this.deletedIndexes});

  @override
  List<Object> get props => [deletedItems, deletedIndexes];
}

class ShowEmployeeDetail extends EmployeeEvent {
  final Employee employee;
  const ShowEmployeeDetail(this.employee);

  @override
  List<Object> get props => [employee];
}

class HideEmployeeDetail extends EmployeeEvent {
  const HideEmployeeDetail();
}

class ExportEmployee extends EmployeeEvent {
  final List<Employee> employeesToExport;
  const ExportEmployee(this.employeesToExport);

  @override
  List<Object> get props => [employeesToExport];
}

class ExportSingleEmployee extends EmployeeEvent {
  final Employee employeeToExport;
  const ExportSingleEmployee(this.employeeToExport);

  @override
  List<Object> get props => [employeeToExport];
}

class ClearSelection extends EmployeeEvent {
  const ClearSelection();
}

class SetEmployeeForm extends EmployeeEvent {
  final Employee employee;
  const SetEmployeeForm(this.employee);

  @override
  List<Object> get props => [employee];
}

class ResetEmployeeForm extends EmployeeEvent {
  const ResetEmployeeForm();
}

class ChangeEmployeePage extends EmployeeEvent {
  final int pageIndex;
  const ChangeEmployeePage(this.pageIndex);

  @override
  List<Object> get props => [pageIndex];
}

class UpdateEmployeeFormField extends EmployeeEvent {
  final String field;
  final dynamic value;
  const UpdateEmployeeFormField(this.field, this.value);

  @override
  List<Object> get props => [field, value];
}

class ToggleRoleManagement extends EmployeeEvent {
  final int employeeId;
  const ToggleRoleManagement(this.employeeId);

  @override
  List<Object> get props => [employeeId];
}
// Add to your existing EmployeeEvent classes

class SelectRoleForAssignment extends EmployeeEvent {
  final Role role;
  const SelectRoleForAssignment(this.role);

  @override
  List<Object> get props => [role];
}

class DeselectRoleForAssignment extends EmployeeEvent {
  final Role role;
  const DeselectRoleForAssignment(this.role);

  @override
  List<Object> get props => [role];
}

class ClearRoleSelection extends EmployeeEvent {
  const ClearRoleSelection();
}

class SaveRoleChanges extends EmployeeEvent {
  final int employeeId;
  final List<int> roleIds;
  const SaveRoleChanges(this.employeeId, this.roleIds);

  @override
  List<Object> get props => [employeeId, roleIds];
}
