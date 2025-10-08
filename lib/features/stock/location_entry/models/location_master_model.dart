import 'package:equatable/equatable.dart';

class LocationMaster extends Equatable {
  final int? id;
  final String? code01; // varchar(30) DEFAULT NULL
  final String? code02; // varchar(30) DEFAULT NULL
  final String? code03; // varchar(30) DEFAULT NULL
  final String? code04; // varchar(30) DEFAULT NULL
  final String? code05; // varchar(30) DEFAULT NULL
  final String? code06; // varchar(30) DEFAULT NULL
  final String? code07; // varchar(30) DEFAULT NULL
  final String? code08; // varchar(30) DEFAULT NULL
  final String? code09; // varchar(30) DEFAULT NULL
  final String? code10; // varchar(30) DEFAULT NULL

  // Audit Fields
  final String? locationDescription;
  final int? createdBy; // int unsigned DEFAULT NULL (FK to user_table)
  final DateTime? dateCreated; // datetime DEFAULT NULL
  final int? updatedBy; // int unsigned DEFAULT NULL (FK to user_table)
  final DateTime? dateUpdated; // datetime DEFAULT NULL
  final int? company;
  final int? branch;
  final String? marginType;
  final double? marginRate;
  final String? branchName;

  //transient proprties
  final int? tempId;
  final bool? validCell;

  const LocationMaster({
    this.id,
    this.code01,
    this.code02,
    this.code03,
    this.code04,
    this.code05,
    this.code06,
    this.code07,
    this.code08,
    this.code09,
    this.code10,
    this.locationDescription,
    this.createdBy,
    this.dateCreated,
    this.dateUpdated,
    this.updatedBy,
    this.company,
    this.branch,
    this.marginType,
    this.marginRate,
    this.branchName,
    this.tempId,
    this.validCell,
  });

  factory LocationMaster.fromMap(Map<String, dynamic> map) {
    return LocationMaster(
      id: map['id'] as int?,
      branch: map['branch'] as int?,
      code01: map['code_01'] as String?,
      code02: map['code_02'] as String?,
      code03: map['code_03'] as String?,
      code04: map['code_04'] as String?,
      code05: map['code_05'] as String?,
      code06: map['code_06'] as String?,
      code07: map['code_07'] as String?,
      code08: map['code_08'] as String?,
      code09: map['code_09'] as String?,
      code10: map['code_10'] as String?,
      marginType: map['margin_type'] as String?,
      marginRate: map['margin_rate'] as double?,
      locationDescription: map['loaction_description'] as String,
      createdBy: map['created_by'] as int?,
      dateCreated: map['date_created'] != null
          ? DateTime.tryParse(map['date_created'])
          : null,
      updatedBy: map['updated_by'] as int?,
      dateUpdated: map['date_updated'] != null
          ? DateTime.tryParse(map['date_updated'])
          : null,
      company: map['company'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'branch': branch,
      'code_01': code01,
      'code_02': code02,
      'code_03': code03,
      'code_04': code04,
      'code_05': code05,
      'code_06': code06,
      'code_07': code07,
      'code_08': code08,
      'code_09': code09,
      'code_10': code10,
      'margin_type': marginType,
      'margin_rate': marginRate,
      'loacation_description': locationDescription,
      'created_by': createdBy,
      'date_created': dateCreated?.toIso8601String(),
      'updated_by': updatedBy,
      'date_updated': dateUpdated?.toIso8601String(),
      'company': company,
    };
  }

  LocationMaster copyWith({
    int? id,
    int? branch,
    String? code01,
    String? code02,
    String? code03,
    String? code04,
    String? code05,
    String? code06,
    String? code07,
    String? code08,
    String? code09,
    String? code10,
    int? createdBy,
    String? marginType,
    double? marginRate,
    String? branchName,
    String? locationDescription,
    DateTime? dateCreated,
    int? updatedBy,
    DateTime? dateUpdated,
    int? company,
    double? inverseConversion,
    int? tempId,
    bool? validCell,
  }) {
    return LocationMaster(
      id: id ?? this.id,
      branch: branch ?? this.branch,
      code01: code01 ?? this.code01,
      code02: code02 ?? this.code02,
      code03: code03 ?? this.code03,
      code04: code04 ?? this.code04,
      code05: code05 ?? this.code05,
      code06: code06 ?? this.code06,
      code07: code07 ?? this.code07,
      code08: code08 ?? this.code08,
      code09: code09 ?? this.code09,
      code10: code10 ?? this.code10,
      branchName: branchName ?? this.branchName,
      marginType: marginType ?? this.marginType,
      marginRate: marginRate ?? this.marginRate,
      locationDescription: locationDescription ?? this.locationDescription,
      createdBy: createdBy ?? this.createdBy,
      dateCreated: dateCreated ?? this.dateCreated,
      updatedBy: updatedBy ?? this.updatedBy,
      dateUpdated: dateUpdated ?? this.dateUpdated,
      company: company ?? this.company,
      tempId: tempId ?? this.tempId,
      validCell: validCell ?? this.validCell,
    );
  }

  @override
  List<Object?> get props => [
    id,
    branch,
    code01,
    code02,
    code03,
    code04,
    code05,
    code06,
    code07,
    code08,
    code09,
    code10,
    branchName,
    marginType,
    marginRate,
    locationDescription,
    createdBy,
    dateCreated,
    updatedBy,
    dateUpdated,
    company,
    tempId,
    validCell,
  ];
}
