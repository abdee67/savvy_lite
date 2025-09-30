import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:savvy_stock/features/admin/role/models/role_model.dart';
import 'package:savvy_stock/features/admin/users/models/user_model.dart';

@immutable
abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object> get props => [];
}

class LoadUsers extends UserEvent {
  final int companyId;
  const LoadUsers(this.companyId);
}

class CreateUser extends UserEvent {
  final UserModel user;
  final List<int> roleIds;
  const CreateUser(this.user, this.roleIds);
}

class UpdateUser extends UserEvent {
  final UserModel user;
  final List<Role> roles;
  const UpdateUser(this.user, this.roles);
}

class AssignRolesToUser extends UserEvent {
  final int userId;
  final int companyId;
  final List<int> roleIds;
  final int createdBy;
  const AssignRolesToUser(
    this.userId,
    this.companyId,
    this.roleIds,
    this.createdBy,
  );
}

class DeleteUser extends UserEvent {
  final int userId;
  final UserModel deletedUser;
  final int deletedIndex;

  const DeleteUser({
    required this.userId,
    required this.deletedUser,
    required this.deletedIndex,
  });

  @override
  List<Object> get props => [userId, deletedUser, deletedIndex];
}

class SearchUsers extends UserEvent {
  final String query;
  const SearchUsers(this.query);

  @override
  List<Object> get props => [query];
}

class SelectUser extends UserEvent {
  final UserModel user;
  final bool isSelected;
  const SelectUser(this.user, this.isSelected);

  @override
  List<Object> get props => [user, isSelected];
}

class SelectAllUsers extends UserEvent {
  final List<UserModel> users;
  const SelectAllUsers(this.users);

  @override
  List<Object> get props => [users];
}

class DeleteSelectedUsers extends UserEvent {
  final List<int> selectedUsers;
  final List<UserModel> deletedUsers;
  final List<int> deletedIndexes;

  const DeleteSelectedUsers({
    required this.selectedUsers,
    required this.deletedUsers,
    required this.deletedIndexes,
  });

  @override
  List<Object> get props => [selectedUsers, deletedUsers, deletedIndexes];
}

class UndoDelete extends UserEvent {
  final List<UserModel> deletedItems;
  final List<int> deletedIndexes;

  const UndoDelete({required this.deletedItems, required this.deletedIndexes});

  @override
  List<Object> get props => [deletedItems, deletedIndexes];
}

class ShowUserDetail extends UserEvent {
  final UserModel user;
  const ShowUserDetail(this.user);

  @override
  List<Object> get props => [user];
}

class HideUserDetail extends UserEvent {
  const HideUserDetail();
}

class ExportUser extends UserEvent {
  final List<UserModel> usersToExport;
  const ExportUser(this.usersToExport);

  @override
  List<Object> get props => [usersToExport];
}

class ExportSingleUser extends UserEvent {
  final UserModel userToExport;
  const ExportSingleUser(this.userToExport);

  @override
  List<Object> get props => [userToExport];
}

class ClearSelection extends UserEvent {
  const ClearSelection();
}
