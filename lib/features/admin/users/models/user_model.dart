import 'dart:typed_data';

import 'package:argon2/argon2.dart';

class UserModel {
  final int id;
  final String? password;
  final int? employeesId;
  final int? createdBy;
  final int? updatedBy;
  final DateTime? dateCreated;
  final DateTime? dateUpdated;
  final String? usercol;
  final int? branch;
  final String? status;
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
    DateTime? parseDate(dynamic v) {
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

    int? asInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is String) return int.tryParse(v);
      return null;
    }

    String? asString(dynamic v) {
      if (v == null) return null;
      return v.toString();
    }

    return UserModel(
      id: asInt(json['id'])!,
      password: asString(json['password']),
      employeesId: asInt(json['employees_id']),
      createdBy: asInt(json['created_by']),
      updatedBy: asInt(json['updated_by']),
      dateCreated: parseDate(json['date_created']),
      dateUpdated: parseDate(json['date_updated']),
      usercol: asString(json['usercol']),
      branch: asInt(json['branch']),
      status: asString(json['status']),
      passwordLastUpdated: parseDate(json['password_last_updated']),
      company: asInt(json['company']),
      userEmail: asString(json['user_email']),
      confirmationCode: asString(json['confirmation_code']),
      confirmationsExpireTime: parseDate(json['confirmations_expire_time']),
      userName: asString(json['user_name']),
      type: asString(json['type']) ?? 'Company',
      salesperson: asInt(json['salesperson']),
    );
  }
  // Argon2 password hashing helper
  static Future<String> generateArgon2Hash(password) async {
    final salt = 'somesalt'.toBytesLatin1();
    final parameters = Argon2Parameters(
      Argon2Parameters.ARGON2_i,
      salt,
      version: Argon2Parameters.ARGON2_VERSION_10,
      iterations: 2,
      memoryPowerOf2: 16,
    );

    final argon2 = Argon2BytesGenerator();
    argon2.init(parameters);
    final passwordBytes = parameters.converter.convert(password);
    final result = Uint8List(32);
    argon2.generateBytes(passwordBytes, result, 0, result.length);
    return result.toHexString();
  }

  // Factory method for creating new users with hashed password
  static Future<UserModel> createWithHashedPassword({
    required int id,
    required String plainPassword,
    String? userName,
    String? userEmail,
    int? branch,
    int? company,
    int? employeesId,
  }) async {
    final hashedPassword = await generateArgon2Hash(plainPassword);
    return UserModel(
      id: id,
      password: hashedPassword,
      userName: userName,
      userEmail: userEmail,
      branch: branch,
      company: company,
      employeesId: employeesId,
      dateCreated: DateTime.now(),
      type: 'Company',
    );
  }

  // Method to verify password
  Future<bool> verifyPassword(String plainPassword) async {
    if (password == null) return false;
    final hashedInput = await generateArgon2Hash(plainPassword);
    return hashedInput == password;
  }

  // Method to check if password needs rehashing (if algorithm changes)
  bool get passwordNeedsRehash {
    // You can add logic here to check if the hash uses outdated parameters
    return false; // Placeholder
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
      'status': 'active',
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
    return 'UserModel{id: $id, password: $password, employeesId: $employeesId, createdBy: $createdBy, updatedBy: $updatedBy, dateCreated: $dateCreated, dateUpdated: $dateUpdated, usercol: $usercol, branch: $branch, status: $status, passwordLastUpdated: $passwordLastUpdated, company: $company, userEmail: $userEmail, confirmationCode: $confirmationCode, confirmationsExpireTime: $confirmationsExpireTime, userName: $userName, type: $type, salesperson: $salesperson}';
  }
}
