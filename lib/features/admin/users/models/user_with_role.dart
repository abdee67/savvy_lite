import 'package:savvy_stock/features/admin/privilege/models/privilege_model.dart';
import 'package:savvy_stock/features/admin/role/models/role_model.dart';
import 'package:savvy_stock/features/admin/users/models/user_model.dart';

class UserWithRole {
  final UserModel user;
  final List<Role> roles;

  UserWithRole({required this.user, required this.roles});

  List<Privilege> get allPrivileges =>
      roles.expand((role) => role.privileges).toList();

  bool hasPrivilege(String privilegeUri) {
    return allPrivileges.any((privilege) => privilege.uri == privilegeUri);
  }

  bool hasAnyPrivilege(List<String> privilegeUris) {
    return allPrivileges.any(
      (privilege) => privilegeUris.contains(privilege.uri),
    );
  }

  bool hasRole(String roleName) {
    return roles.any((role) => role.name == roleName);
  }

  bool hasAnyRole(List<String> roleNames) {
    return roles.any((role) => roleNames.contains(role.name));
  }

  bool get isAuthenticated => roles.isNotEmpty;
}
