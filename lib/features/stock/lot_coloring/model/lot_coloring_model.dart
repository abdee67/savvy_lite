class LotExpirationColor {
  final int? id;
  final int? itemNumber; // FK -> items_table
  final int? branch; // FK -> branch_table
  int? daysMaximum;
  int? colorType; // FK -> udc_details (color type)
  final int? company; // FK -> company_table
  String? description;
  int? daysMinimum;
  String? activeForSalesFlag; // 'Y' or 'N'
  final String? lotExpLevel; // e.g., A/B/C or priority level
  final int? tempId;

  //from left join
  final String? branchName;
  final String? itemDescription;
  final String? colorTypeName;
  final String? colorTypeCode;

  LotExpirationColor({
    this.id,
    this.itemNumber,
    this.branch,
    this.daysMaximum,
    this.colorType,
    this.company,
    this.description,
    this.daysMinimum,
    this.activeForSalesFlag = 'Y',
    this.lotExpLevel,
    this.tempId,

    this.branchName,
    this.itemDescription,
    this.colorTypeName,
    this.colorTypeCode,
  });

  factory LotExpirationColor.fromMap(Map<String, dynamic> map) {
    return LotExpirationColor(
      id: map['id'] as int?,
      itemNumber: map['item_number'] as int?,
      branch: map['branch'] as int?,
      daysMaximum: map['days_maximum'] as int?,
      colorType: map['color_type'] as int?,
      company: map['company'] as int?,
      description: map['description'] as String?,
      daysMinimum: map['days_minimum'] as int?,
      activeForSalesFlag: map['active_for_sales_flag'] as String?,
      lotExpLevel: map['lot_exp_level'] as String?,

      //from left join
      branchName: map['branch_name'] as String?,
      itemDescription: map['item_description'] as String?,
      colorTypeName: map['color_type_name'] as String?,
      colorTypeCode: map['color_type_code'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item_number': itemNumber,
      'branch': branch,
      'days_maximum': daysMaximum,
      'color_type': colorType,
      'company': company,
      'description': description,
      'days_minimum': daysMinimum,
      'active_for_sales_flag': activeForSalesFlag,
      'lot_exp_level': lotExpLevel,
    };
  }

  LotExpirationColor copyWith({
    int? id,
    int? itemNumber,
    int? branch,
    int? daysMaximum,
    int? colorType,
    int? company,
    String? description,
    int? daysMinimum,
    String? activeForSalesFlag,
    String? lotExpLevel,
    int? tempId,

    //from left join
    String? branchName,
    String? itemDescription,
    String? colorTypeName,
    String? colorTypeCode,
  }) {
    return LotExpirationColor(
      id: id ?? this.id,
      itemNumber: itemNumber ?? this.itemNumber,
      branch: branch ?? this.branch,
      daysMaximum: daysMaximum ?? this.daysMaximum,
      colorType: colorType ?? this.colorType,
      company: company ?? this.company,
      description: description ?? this.description,
      daysMinimum: daysMinimum ?? this.daysMinimum,
      activeForSalesFlag: activeForSalesFlag ?? this.activeForSalesFlag,
      lotExpLevel: lotExpLevel ?? this.lotExpLevel,
      tempId: tempId ?? this.tempId,

      //from left join
      branchName: branchName ?? this.branchName,
      itemDescription: itemDescription ?? this.itemDescription,
      colorTypeName: colorTypeName ?? this.colorTypeName,
      colorTypeCode: colorTypeCode ?? this.colorTypeCode,
    );
  }

  @override
  List<Object?> get props => [
    id,
    itemNumber,
    branch,
    daysMaximum,
    colorType,
    company,
    description,
    daysMinimum,
    activeForSalesFlag,
    lotExpLevel,
    tempId,

    //from left join
    branchName,
    itemDescription,
    colorTypeName,
    colorTypeCode,
  ];
}
