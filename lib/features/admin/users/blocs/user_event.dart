import 'package:flutter/widgets.dart';

@immutable
abstract class UserEvent {}

class LoadUsers extends UserEvent {
  final int companyId;
  LoadUsers(this.companyId);
}

class CreateUser extends UserEvent {
  final String employeesId;
  final String userName;
  final String password;
  final List<int> roleIds;
  CreateUser(this.employeesId, this.userName, this.password, this.roleIds);
}

class UpdateUser extends UserEvent {
  final int userId;
  final List<int> roleIds;
  UpdateUser(this.userId, this.roleIds);
}

class DeleteUser extends UserEvent {
  final int userId;
  DeleteUser(this.userId);
}

class AssignRolesToUser extends UserEvent {
  final int userId;
  final int companyId;
  final List<int> roleIds;
  final int createdBy;
  AssignRolesToUser(this.userId, this.companyId, this.roleIds, this.createdBy);
}
