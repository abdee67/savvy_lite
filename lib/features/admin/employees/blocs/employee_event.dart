import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:savvy_stock/features/admin/employees/models/employee_model.dart';

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
  const SelectAllEmployees();
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
  const ExportEmployee();
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
