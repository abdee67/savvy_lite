/// Response model from the Java server's login endpoint.
///
/// Contains all company-level data needed to populate a new device's
/// local database after successful remote authentication.
class RemoteLoginResponse {
  final bool success;
  final String? message;
  final String? serverToken;

  /// Core entities
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? company;
  final Map<String, dynamic>? branch;
  final Map<String, dynamic>? employee;

  /// Role & privilege mappings (company-specific)
  final List<Map<String, dynamic>> roles;
  final List<Map<String, dynamic>> rolePrivileges;
  final List<Map<String, dynamic>> userRoles;

  /// Configuration data
  final List<Map<String, dynamic>> systemConstants;
  final List<Map<String, dynamic>> nextNumbers;
  final List<Map<String, dynamic>> fsTables;
  final Map<String, dynamic>? companySubscription;

  const RemoteLoginResponse({
    required this.success,
    this.message,
    this.serverToken,
    this.user,
    this.company,
    this.branch,
    this.employee,
    this.roles = const [],
    this.rolePrivileges = const [],
    this.userRoles = const [],
    this.systemConstants = const [],
    this.nextNumbers = const [],
    this.fsTables = const [],
    this.companySubscription,
  });

  factory RemoteLoginResponse.fromJson(Map<String, dynamic> json) {
    return RemoteLoginResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      serverToken: json['token'] as String?,
      user: json['user'] as Map<String, dynamic>?,
      company: json['company'] as Map<String, dynamic>?,
      branch: json['branch'] as Map<String, dynamic>?,
      employee: json['employee'] as Map<String, dynamic>?,
      roles: _parseList(json['roles']),
      rolePrivileges: _parseList(json['role_privileges']),
      userRoles: _parseList(json['user_roles']),
      systemConstants: _parseList(json['system_constants']),
      nextNumbers: _parseList(json['next_numbers']),
      fsTables: _parseList(json['fs_table']),
      companySubscription:
          json['company_subscription'] as Map<String, dynamic>?,
    );
  }

  factory RemoteLoginResponse.failure(String message) {
    return RemoteLoginResponse(success: false, message: message);
  }

  static List<Map<String, dynamic>> _parseList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .whereType<Map<String, dynamic>>()
          .toList();
    }
    return [];
  }

  /// Whether the response contains enough data to populate the local DB.
  bool get hasCompanyData =>
      company != null &&
      user != null &&
      branch != null &&
      employee != null;
}
