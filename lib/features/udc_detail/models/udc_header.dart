class UdcHeader {
  final int? id;
  final String headerCode;
  final String description1;
  final String? description2;
  final String? systemCode;
  final DateTime? dateCreated;
  final DateTime? dateUpdated;
  final int? createdBy;
  final int? updatedBy;

  UdcHeader({
    this.id,
    required this.headerCode,
    required this.description1,
    this.description2,
    this.systemCode,
    this.dateCreated,
    this.dateUpdated,
    this.createdBy,
    this.updatedBy,
  });

  factory UdcHeader.fromJson(Map<String, dynamic> json) {
    return UdcHeader(
      id: json['id'],
      headerCode: json['header_code'],
      description1: json['description_1'],
      description2: json['description_2'],
      systemCode: json['system_code'],
      dateCreated: json['date_created'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['date_created'])
          : null,
      dateUpdated: json['date_updated'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['date_updated'])
          : null,
      createdBy: json['created_by'],
      updatedBy: json['updated_by'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'header_code': headerCode,
      'description_1': description1,
      'description_2': description2,
      'system_code': systemCode,
      'date_created': dateCreated?.millisecondsSinceEpoch,
      'date_updated': dateUpdated?.millisecondsSinceEpoch,
      'created_by': createdBy,
      'updated_by': updatedBy,
    };
  }

  Map<String, dynamic> toDatabaseMap() {
    return {
      'id': id,
      'header_code': headerCode,
      'description_1': description1,
      'description_2': description2,
      'system_code': systemCode,
      'date_created': dateCreated?.millisecondsSinceEpoch,
      'date_updated': dateUpdated?.millisecondsSinceEpoch,
      'created_by': createdBy,
      'updated_by': updatedBy,
    };
  }
}
