// features/privilege/blocs/privilege_event.dart
import 'package:meta/meta.dart';
import 'package:savvy_stock/features/admin/privilege/models/privilege_model.dart';

@immutable
abstract class PrivilegeEvent {}

class LoadPrivileges extends PrivilegeEvent {}

class CreatePrivilege extends PrivilegeEvent {
  final Privilege privilege;
  CreatePrivilege(this.privilege);
}

class UpdatePrivilege extends PrivilegeEvent {
  final Privilege privilege;
  UpdatePrivilege(this.privilege);
}

class DeletePrivilege extends PrivilegeEvent {
  final int privilegeId;
  DeletePrivilege(this.privilegeId);
}
