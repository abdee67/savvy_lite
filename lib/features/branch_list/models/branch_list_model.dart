class Branch {
  final int id;
  final String? referenceId;
  final String? description;
  final String? city;
  final String? region;
  final String? state;
  final String? country;
  final String? addressLine;
  final int? company;
  final String? branchPhone;
  final double? marginRate;
  final String? marginType;

  const Branch({
    required this.id,
    this.referenceId,
    this.description,
    this.city,
    this.region,
    this.state,
    this.country,
    this.addressLine,
    this.company,
    this.branchPhone,
    this.marginRate,
    this.marginType,
  });

  static Branch empty() {
    return Branch(
      id: 0,
      referenceId: null,
      description: null,
      city: null,
      region: null,
      state: null,
      addressLine: null,
      company: null,
      branchPhone: null,
      marginRate: null,
      marginType: null,
    );
  }

  bool get isEmpty => id == 0;
  bool get isNotEmpty => id != 0;

  factory Branch.fromMap(Map<String, dynamic> map) {
    return Branch(
      id: (map['id'] as num).toInt(),
      referenceId: map['reference_id']?.toString(),
      description: map['description']?.toString(),
      city: map['city']?.toString(),
      region: map['region']?.toString(),
      state: map['state']?.toString(),
      country: map['country']?.toString(),
      addressLine: map['address_line']?.toString(),
      company: (map['company'] as num?)?.toInt(),
      branchPhone: map['branch_phone']?.toString(),
      marginRate: (map['margin_rate'] as num?)?.toDouble(),
      marginType: map['margin_type']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reference_id': referenceId,
      'description': description,
      'city': city,
      'region': region,
      'state': state,
      'country': country ?? 'Ethiopia',
      'address_line': addressLine,
      'company': company,
      'branch_phone': branchPhone,
      'margin_rate': marginRate,
      'margin_type': marginType,
    };
  }

  Branch copyWith({
    int? id,
    String? referenceId,
    String? description,
    String? city,
    String? region,
    String? state,
    String? addressLine,
    int? company,
    String? branchPhone,
    double? marginRate,
    String? marginType,
  }) {
    return Branch(
      id: id ?? this.id,
      referenceId: referenceId ?? this.referenceId,
      description: description ?? this.description,
      city: city ?? this.city,
      region: region ?? this.region,
      state: state ?? this.state,
      country: 'Ethiopia',
      addressLine: addressLine ?? this.addressLine,
      company: company ?? this.company,
      branchPhone: branchPhone ?? this.branchPhone,
      marginRate: marginRate ?? this.marginRate,
      marginType: marginType ?? this.marginType,
    );
  }
}
