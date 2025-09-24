import 'package:flutter/widgets.dart';
import 'package:savvy_stock/features/admin/role/models/role_model.dart';

@immutable
abstract class RoleEvent {}

class LoadRoles extends RoleEvent {
  final int companyId;
  LoadRoles(this.companyId);
}

class CreateRole extends RoleEvent {
  final String name;
  final String description;
  final int companyId;
  final int createdBy;
  final List<int> privilegeIds;
  CreateRole(
    this.name,
    this.description,
    this.companyId,
    this.createdBy,
    this.privilegeIds,
  );
}

class UpdateRole extends RoleEvent {
  final Role role;
  final List<int> privilegeIds;
  UpdateRole(this.role, this.privilegeIds);
}

class DeleteRole extends RoleEvent {
  final Role role;
  DeleteRole(this.role);
}

class AssignPrivilegesToRole extends RoleEvent {
  final Role role;
  final List<int> privilegeIds;
  final int createdBy;
  AssignPrivilegesToRole(this.role, this.privilegeIds, this.createdBy);
}
