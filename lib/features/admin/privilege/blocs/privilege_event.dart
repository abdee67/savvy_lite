// features/privilege/blocs/privilege_event.dart
import 'package:meta/meta.dart';
import 'package:savvy_stock/features/admin/privilege/models/privilege_model.dart';

@immutable
abstract class PrivilegeEvent {}

class LoadPrivileges extends PrivilegeEvent {
  final int companyId;
  LoadPrivileges(this.companyId);
}

class CreatePrivilege extends PrivilegeEvent {
  final String name;
  final String description;
  final String type;
  final String uri;
  final String? linkLabel;
  final String? buttonLabel;
  final bool vendorOnly;

  CreatePrivilege(
    this.name,
    this.description,
    this.type,
    this.uri,
    this.linkLabel,
    this.buttonLabel,
    this.vendorOnly,
  );
}

class UpdatePrivilege extends PrivilegeEvent {
  final Privilege privilege;
  UpdatePrivilege(this.privilege);
}

class DeletePrivilege extends PrivilegeEvent {
  final int privilegeId;
  DeletePrivilege(this.privilegeId);
}
