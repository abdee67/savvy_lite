import 'package:savvy_stock/core/models/company.dart';

class UserModel {
  final int? id;
  final String? password;
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

  factory UserModel.fromMap(Map<String, dynamic> json) {
    DateTime? _parseDate(dynamic v) {
      if (v == null) return null;
      if (v is int) {
        // Treat as milliseconds since epoch
        return DateTime.fromMillisecondsSinceEpoch(v);
      }
      if (v is String) {
        if (v.isEmpty) return null;
        // Try parse ISO string
        try {
          return DateTime.parse(v);
        } catch (_) {
          // Try parse as int string milliseconds
          final asInt = int.tryParse(v);
          if (asInt != null) {
            return DateTime.fromMillisecondsSinceEpoch(asInt);
          }
          return null;
        }
      }
      return null;
    }

    int? _asInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is String) return int.tryParse(v);
      return null;
    }

    String? _asString(dynamic v) {
      if (v == null) return null;
      return v.toString();
    }

    return UserModel(
      id: _asInt(json['id']),
      password: _asString(json['password']),
      employeesId: _asInt(json['employees_id']),
      createdBy: _asInt(json['created_by']),
      updatedBy: _asInt(json['updated_by']),
      dateCreated: _parseDate(json['date_created']),
      dateUpdated: _parseDate(json['date_updated']),
      usercol: _asString(json['usercol']),
      branch: _asInt(json['branch']),
      status: _asString(json['status']),
      superUser: _asString(json['super_user']),
      passwordLastUpdated: _parseDate(json['password_last_updated']),
      company: _asInt(json['company']),
      userEmail: _asString(json['user_email']),
      confirmationCode: _asString(json['confirmation_code']),
      confirmationsExpireTime: _parseDate(json['confirmations_expire_time']),
      userName: _asString(json['user_name']),
      type: _asString(json['type']) ?? 'Company',
      salesperson: _asInt(json['salesperson']),
    );
  }

  Map<String, dynamic> toMap() {
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

  UserModel copyWith({
    int? id,
    String? password,
    int? employeesId,
    int? createdBy,
    int? updatedBy,
    DateTime? dateCreated,
    DateTime? dateUpdated,
    String? usercol,
    int? branch,
    String? status,
    String? superUser,
    DateTime? passwordLastUpdated,
    int? company,
    String? userEmail,
    String? confirmationCode,
    DateTime? confirmationsExpireTime,
    String? userName,
    String? type,
    int? salesperson,
  }) {
    return UserModel(
      id: id ?? this.id,
      password: password ?? this.password,
      employeesId: employeesId ?? this.employeesId,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      dateCreated: dateCreated ?? this.dateCreated,
      dateUpdated: dateUpdated ?? this.dateUpdated,
      usercol: usercol ?? this.usercol,
      branch: branch ?? this.branch,
      status: status ?? this.status,
      superUser: superUser ?? this.superUser,
      passwordLastUpdated: passwordLastUpdated ?? this.passwordLastUpdated,
      company: company ?? this.company,
      userEmail: userEmail ?? this.userEmail,
      confirmationCode: confirmationCode ?? this.confirmationCode,
      confirmationsExpireTime:
          confirmationsExpireTime ?? this.confirmationsExpireTime,
      userName: userName ?? this.userName,
      type: type ?? this.type,
      salesperson: salesperson ?? this.salesperson,
    );
  }

  List<Object?> get props => [
    id,
    password,
    employeesId,
    createdBy,
    updatedBy,
    dateCreated,
    dateUpdated,
    usercol,
    branch,
    status,
    superUser,
    passwordLastUpdated,
    company,
    userEmail,
    confirmationCode,
    confirmationsExpireTime,
    userName,
    type,
    salesperson,
  ];
  @override
  String toString() {
    return 'UserModel{id: $id, password: $password, employeesId: $employeesId, createdBy: $createdBy, updatedBy: $updatedBy, dateCreated: $dateCreated, dateUpdated: $dateUpdated, usercol: $usercol, branch: $branch, status: $status, superUser: $superUser, passwordLastUpdated: $passwordLastUpdated, company: $company, userEmail: $userEmail, confirmationCode: $confirmationCode, confirmationsExpireTime: $confirmationsExpireTime, userName: $userName, type: $type, salesperson: $salesperson}';
  }
}
