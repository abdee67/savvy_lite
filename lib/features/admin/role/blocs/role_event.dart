import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:savvy_stock/features/admin/role/models/role_model.dart';

@immutable
abstract class RoleEvent extends Equatable {
  const RoleEvent();

  @override
  List<Object> get props => [];
}

class LoadRoles extends RoleEvent {
  final int companyId;
  const LoadRoles(this.companyId);
}

class CreateRole extends RoleEvent {
  final String name;
  final String description;
  final List<int> privilegeIds;
  const CreateRole(this.name, this.description, this.privilegeIds);
}

class UpdateRole extends RoleEvent {
  final Role role;
  const UpdateRole(this.role);
}

class DeleteRole extends RoleEvent {
  final Role role;
  const DeleteRole(this.role);
}

class DeleteMultipleRoles extends RoleEvent {
  final List<Role> roles;
  const DeleteMultipleRoles(this.roles);
}

class AssignPrivilegesToRole extends RoleEvent {
  final Role role;
  final List<int> privilegeIds;
  const AssignPrivilegesToRole(this.role, this.privilegeIds);
}

class SearchRoles extends RoleEvent {
  final String query;
  const SearchRoles(this.query);
}

class SelectRole extends RoleEvent {
  final Role role;
  final bool isSelected;
  const SelectRole(this.role, this.isSelected);

  @override
  List<Object> get props => [role, isSelected];
}

class SelectAllRoles extends RoleEvent {
  final List<Role> roles;
  const SelectAllRoles(this.roles);

  @override
  List<Object> get props => [roles];
}

class ClearSelection extends RoleEvent {}
