import 'package:equatable/equatable.dart';

class Salesperson extends Equatable {
  final int? id;
  final String uuid;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String passwordHash;
  final String referralCode;
  final int? parentSalespersonId;
  final String status;
  final String? createdAt;
  final String? updatedAt;

  /// Optional: populated when joining the table with its parent
  final Salesperson? parentDetail;

  const Salesperson({
    this.id,
    required this.uuid,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.passwordHash,
    required this.referralCode,
    this.parentSalespersonId,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.parentDetail,
  });

  factory Salesperson.fromMap(Map<String, dynamic> map) {
    return Salesperson(
      id: map['id'] as int?,
      uuid: map['uuid'] as String,
      fullName: map['full_name'] as String,
      email: map['email'] as String,
      phoneNumber: map['phone_number'] as String,
      passwordHash: map['password_hash'] as String,
      referralCode: map['referral_code'] as String,
      parentSalespersonId: map['parent_salesperson_id'] as int?,
      status: map['status'] as String,
      createdAt: map['created_at']?.toString(),
      updatedAt: map['updated_at']?.toString(),

      // A joined parent salesperson (if query included parent columns)
      parentDetail: map['parent_uuid'] != null
          ? Salesperson(
              id: map['parent_salesperson_id'],
              uuid: map['parent_uuid'],
              fullName: map['parent_full_name'],
              email: map['parent_email'],
              phoneNumber: map['parent_phone'],
              passwordHash: map['parent_password_hash'],
              referralCode: map['parent_referral_code'],
              status: map['parent_status'],
              createdAt: map['parent_created_at'],
              updatedAt: map['parent_updated_at'],
            )
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uuid': uuid,
      'full_name': fullName,
      'email': email,
      'phone_number': phoneNumber,
      'password_hash': passwordHash,
      'referral_code': referralCode,
      'parent_salesperson_id': parentSalespersonId,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  Salesperson copyWith({
    int? id,
    String? uuid,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? passwordHash,
    String? referralCode,
    int? parentSalespersonId,
    String? status,
    String? createdAt,
    String? updatedAt,
    Salesperson? parentDetail,
  }) {
    return Salesperson(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      passwordHash: passwordHash ?? this.passwordHash,
      referralCode: referralCode ?? this.referralCode,
      parentSalespersonId: parentSalespersonId ?? this.parentSalespersonId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      parentDetail: parentDetail ?? this.parentDetail,
    );
  }

  @override
  List<Object?> get props => [
    id,
    uuid,
    fullName,
    email,
    phoneNumber,
    passwordHash,
    referralCode,
    parentSalespersonId,
    status,
    createdAt,
    updatedAt,
    parentDetail,
  ];
}
