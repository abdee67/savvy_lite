class UserModel {
  final int? id;
  final String password;
  final int? employeesId;
  final int? createdBy;
  final int? updatedBy;
  final DateTime? dateCreated;
  final DateTime? dateUpdated;
  final String? usercol;
  final int? branch;
  final String? status;
  final String? superUser;
  final DateTime? passwordLastUpdated;
  final int? company;
  final String? userEmail;
  final String? confirmationCode;
  final DateTime? confirmationsExpireTime;
  final String? userName;
  final String? type;
  final int? salesperson;

  UserModel({
    required this.id,
    required this.password,
    this.employeesId,
    this.createdBy,
    this.updatedBy,
    this.dateCreated,
    this.dateUpdated,
    this.usercol,
    this.branch,
    this.status,
    this.superUser,
    this.passwordLastUpdated,
    this.company,
    this.userEmail,
    this.confirmationCode,
    this.confirmationsExpireTime,
    this.userName,
    this.type = 'Company',
    this.salesperson,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      password: json['password'],
      employeesId: json['employees_id'],
      createdBy: json['created_by'],
      updatedBy: json['updated_by'],
      dateCreated: json['date_created'] != null
          ? DateTime.parse(json['date_created'])
          : null,
      dateUpdated: json['date_updated'] != null
          ? DateTime.parse(json['date_updated'])
          : null,
      usercol: json['usercol'],
      branch: json['branch'],
      status: json['status'],
      superUser: json['super_user'],
      passwordLastUpdated: json['password_last_updated'] != null
          ? DateTime.parse(json['password_last_updated'])
          : null,
      company: json['company'],
      userEmail: json['user_email'],
      confirmationCode: json['confirmation_code'],
      confirmationsExpireTime: json['confirmations_expire_time'] != null
          ? DateTime.parse(json['confirmations_expire_time'])
          : null,
      userName: json['user_name'],
      type: json['type'] ?? 'Company',
      salesperson: json['salesperson'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'password': password,
      'employees_id': employeesId,
      'created_by': createdBy,
      'updated_by': updatedBy,
      'date_created': dateCreated?.toIso8601String(),
      'date_updated': dateUpdated?.toIso8601String(),
      'usercol': usercol,
      'branch': branch,
      'status': status,
      'super_user': superUser,
      'password_last_updated': passwordLastUpdated?.toIso8601String(),
      'company': company,
      'user_email': userEmail,
      'confirmation_code': confirmationCode,
      'confirmations_expire_time': confirmationsExpireTime?.toIso8601String(),
      'user_name': userName,
      'type': type,
      'salesperson': salesperson,
    };
  }
}
