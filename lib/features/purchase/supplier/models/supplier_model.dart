class SupplierModel {
  final int? id;
  final String? supplierName;
  final String? city;
  final String? region;
  final String? state;
  final String? country;
  final String? phoneNo1;
  final String? phoneNo2;
  final String? addressLine;
  final String? email;
  final int? company;
  final int? createdBy;
  final DateTime? dateCreated;
  final int? userId;
  final DateTime? dateUpdated;
  final String? tinNumber;
  final String? contactPerson;
  final String? contactTitle;

  SupplierModel({
    this.id,
    this.supplierName,
    this.city,
    this.region,
    this.state,
    this.country,
    this.phoneNo1,
    this.phoneNo2,
    this.addressLine,
    this.email,
    this.company,
    this.createdBy,
    this.dateCreated,
    this.userId,
    this.dateUpdated,
    this.tinNumber,
    this.contactPerson,
    this.contactTitle,
  });

  factory SupplierModel.fromMap(Map<String, dynamic> map) {
    return SupplierModel(
      id: map['id'],
      supplierName: map['supplier_name'],
      city: map['city'],
      region: map['region'],
      state: map['state'],
      country: map['country'],
      phoneNo1: map['phone_no_1'],
      phoneNo2: map['phone_no_2'],
      addressLine: map['address_line'],
      email: map['email'],
      company: map['company'],
      createdBy: map['created_by'],
      dateCreated: map['date_created'],
      userId: map['user_id'],
      dateUpdated: map['date_updated'],
      tinNumber: map['tin_number'],
      contactPerson: map['contact_person'],
      contactTitle: map['contact_title'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supplier_name': supplierName,
      'city': city,
      'region': region,
      'state': state,
      'country': country,
      'phone_no_1': phoneNo1,
      'phone_no_2': phoneNo2,
      'address_line': addressLine,
      'email': email,
      'company': company,
      'created_by': createdBy,
      'date_created': dateCreated,
      'user_id': userId,
      'date_updated': dateUpdated,
      'tin_number': tinNumber,
      'contact_person': contactPerson,
      'contact_title': contactTitle,
    };
  }

  /// CopyWith for safe updates
  SupplierModel copyWith({
    int? id,
    String? supplierName,
    String? city,
    String? region,
    String? state,
    String? country,
    String? phoneNo1,
    String? phoneNo2,
    String? addressLine,
    String? email,
    int? company,
    int? createdBy,
    DateTime? dateCreated,
    int? userId,
    DateTime? dateUpdated,
    String? tinNumber,
    String? contactPerson,
    String? contactTitle,
  }) {
    return SupplierModel(
      id: id ?? this.id,
      supplierName: supplierName ?? this.supplierName,
      city: city ?? this.city,
      region: region ?? this.region,
      state: state ?? this.state,
      country: country ?? this.country,
      phoneNo1: phoneNo1 ?? this.phoneNo1,
      phoneNo2: phoneNo2 ?? this.phoneNo2,
      addressLine: addressLine ?? this.addressLine,
      email: email ?? this.email,
      company: company ?? this.company,
      createdBy: createdBy ?? this.createdBy,
      dateCreated: dateCreated ?? this.dateCreated,
      userId: userId ?? this.userId,
      dateUpdated: dateUpdated ?? this.dateUpdated,
      tinNumber: tinNumber ?? this.tinNumber,
      contactPerson: contactPerson ?? this.contactPerson,
      contactTitle: contactTitle ?? this.contactTitle,
    );
  }
}
