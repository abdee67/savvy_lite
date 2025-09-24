import 'package:flutter/widgets.dart';
import 'package:savvy_stock/features/admin/users/models/user_model.dart';

@immutable
abstract class UserEvent {}

class LoadUsers extends UserEvent {
  final int companyId;
  LoadUsers(this.companyId);
}

class CreateUser extends UserEvent {
  final UserModel user;
  final List<int> roleIds;
  final int createdBy;
  CreateUser(this.user, this.roleIds, this.createdBy);
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
