// features/stock/item_master/models/item_master_model.dart
class ItemMaster {
  int? id;
  String? itemDescription;
  int? companyCategory;
  int? categoryCode01;
  int? categoryCode02;
  int? categoryCode03;
  int? categoryCode04;
  int? categoryCode05;
  int? categoryCode06;
  int? categoryCode07;
  int? categoryCode08;
  int? categoryCode09;
  int? categoryCode10;
  String? createdByFlag;
  int? defualtUom;
  String? taxableFlag;

  // Migration fields (not in database table)
  int? branch;
  double? unitPrice;
  double? unitCost;
  double? quantity;
  DateTime? dateExpired;
  String? batchNumber;
  String? locationCode1;
  String? locationCode2;
  String? locationCode3;
  String? locationCode4;
  String? locationCode5;
  String? locationCode6;
  String? locationCode7;
  String? locationCode8;
  String? locationCode9;
  String? locationCode10;

  // UI fields
  int? tempId;
  bool? validCell;
  bool? taxableBoolean;

  // Additional fields from joins
  String? companyCategoryDescription;
  String? defualtUomDescription;
  String? categoryCode01Description;
  String? categoryCode02Description;
  String? categoryCode03Description;
  String? categoryCode04Description;
  String? categoryCode05Description;
  String? categoryCode06Description;
  String? categoryCode07Description;
  String? categoryCode08Description;
  String? categoryCode09Description;
  String? categoryCode10Description;

  ItemMaster({
    this.id,
    this.itemDescription,
    this.companyCategory,
    this.categoryCode01,
    this.categoryCode02,
    this.categoryCode03,
    this.categoryCode04,
    this.categoryCode05,
    this.categoryCode06,
    this.categoryCode07,
    this.categoryCode08,
    this.categoryCode09,
    this.categoryCode10,
    this.createdByFlag = 'Y',
    this.defualtUom,
    this.taxableFlag = 'Y',

    // Migration fields
    this.branch,
    this.unitPrice,
    this.unitCost,
    this.quantity,
    this.dateExpired,
    this.batchNumber,
    this.locationCode1,
    this.locationCode2,
    this.locationCode3,
    this.locationCode4,
    this.locationCode5,
    this.locationCode6,
    this.locationCode7,
    this.locationCode8,
    this.locationCode9,
    this.locationCode10,

    // UI fields
    this.tempId,
    this.validCell = true,
    this.taxableBoolean,

    // Join descriptions
    this.companyCategoryDescription,
    this.defualtUomDescription,
    this.categoryCode01Description,
    this.categoryCode02Description,
    this.categoryCode03Description,
    this.categoryCode04Description,
    this.categoryCode05Description,
    this.categoryCode06Description,
    this.categoryCode07Description,
    this.categoryCode08Description,
    this.categoryCode09Description,
    this.categoryCode10Description,
  });

  factory ItemMaster.fromMap(Map<String, dynamic> map) {
    return ItemMaster(
      id: map['id'],
      itemDescription: map['item_description'],
      companyCategory: map['company_category'],
      categoryCode01: map['category_code_01'],
      categoryCode02: map['category_code_02'],
      categoryCode03: map['category_code_03'],
      categoryCode04: map['category_code_04'],
      categoryCode05: map['category_code_05'],
      categoryCode06: map['category_code_06'],
      categoryCode07: map['category_code_07'],
      categoryCode08: map['category_code_08'],
      categoryCode09: map['category_code_09'],
      categoryCode10: map['category_code_10'],
      createdByFlag: map['created_by_flag'],
      defualtUom: map['defualt_uom'],
      taxableFlag: map['taxable_flag'],

      // UI fields
      tempId: map['temp_id'],
      validCell: map['valid_cell'] == 1,
      taxableBoolean: map['taxable_flag'] == 'Y',

      // Join descriptions
      companyCategoryDescription: map['company_category_description'],
      defualtUomDescription: map['defualt_uom_description'],
      categoryCode01Description: map['category_code_01_description'],
      categoryCode02Description: map['category_code_02_description'],
      categoryCode03Description: map['category_code_03_description'],
      categoryCode04Description: map['category_code_04_description'],
      categoryCode05Description: map['category_code_05_description'],
      categoryCode06Description: map['category_code_06_description'],
      categoryCode07Description: map['category_code_07_description'],
      categoryCode08Description: map['category_code_08_description'],
      categoryCode09Description: map['category_code_09_description'],
      categoryCode10Description: map['category_code_10_description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item_description': itemDescription,
      'company_category': companyCategory,
      'category_code_01': categoryCode01,
      'category_code_02': categoryCode02,
      'category_code_03': categoryCode03,
      'category_code_04': categoryCode04,
      'category_code_05': categoryCode05,
      'category_code_06': categoryCode06,
      'category_code_07': categoryCode07,
      'category_code_08': categoryCode08,
      'category_code_09': categoryCode09,
      'category_code_10': categoryCode10,
      'created_by_flag': createdByFlag,
      'defualt_uom': defualtUom,
      'taxable_flag': taxableFlag,
      'temp_id': tempId,
      'valid_cell': validCell == true ? 1 : 0,
    };
  }

  ItemMaster copyWith({
    int? id,
    String? itemDescription,
    int? companyCategory,
    int? categoryCode01,
    int? categoryCode02,
    int? categoryCode03,
    int? categoryCode04,
    int? categoryCode05,
    int? categoryCode06,
    int? categoryCode07,
    int? categoryCode08,
    int? categoryCode09,
    int? categoryCode10,
    String? createdByFlag,
    int? defualtUom,
    String? taxableFlag,

    // Migration fields
    int? branch,
    double? unitPrice,
    double? unitCost,
    double? quantity,
    DateTime? dateExpired,
    String? batchNumber,
    String? locationCode1,
    String? locationCode2,
    String? locationCode3,
    String? locationCode4,
    String? locationCode5,
    String? locationCode6,
    String? locationCode7,
    String? locationCode8,
    String? locationCode9,
    String? locationCode10,

    // UI fields
    int? tempId,
    bool? validCell,
    bool? taxableBoolean,

    // Join descriptions
    String? companyCategoryDescription,
    String? defualtUomDescription,
    String? categoryCode01Description,
    String? categoryCode02Description,
    String? categoryCode03Description,
    String? categoryCode04Description,
    String? categoryCode05Description,
    String? categoryCode06Description,
    String? categoryCode07Description,
    String? categoryCode08Description,
    String? categoryCode09Description,
    String? categoryCode10Description,
  }) {
    return ItemMaster(
      id: id ?? this.id,
      itemDescription: itemDescription ?? this.itemDescription,
      companyCategory: companyCategory ?? this.companyCategory,
      categoryCode01: categoryCode01 ?? this.categoryCode01,
      categoryCode02: categoryCode02 ?? this.categoryCode02,
      categoryCode03: categoryCode03 ?? this.categoryCode03,
      categoryCode04: categoryCode04 ?? this.categoryCode04,
      categoryCode05: categoryCode05 ?? this.categoryCode05,
      categoryCode06: categoryCode06 ?? this.categoryCode06,
      categoryCode07: categoryCode07 ?? this.categoryCode07,
      categoryCode08: categoryCode08 ?? this.categoryCode08,
      categoryCode09: categoryCode09 ?? this.categoryCode09,
      categoryCode10: categoryCode10 ?? this.categoryCode10,
      createdByFlag: createdByFlag ?? this.createdByFlag,
      defualtUom: defualtUom ?? this.defualtUom,
      taxableFlag: taxableFlag ?? this.taxableFlag,

      // Migration fields
      branch: branch ?? this.branch,
      unitPrice: unitPrice ?? this.unitPrice,
      unitCost: unitCost ?? this.unitCost,
      quantity: quantity ?? this.quantity,
      dateExpired: dateExpired ?? this.dateExpired,
      batchNumber: batchNumber ?? this.batchNumber,
      locationCode1: locationCode1 ?? this.locationCode1,
      locationCode2: locationCode2 ?? this.locationCode2,
      locationCode3: locationCode3 ?? this.locationCode3,
      locationCode4: locationCode4 ?? this.locationCode4,
      locationCode5: locationCode5 ?? this.locationCode5,
      locationCode6: locationCode6 ?? this.locationCode6,
      locationCode7: locationCode7 ?? this.locationCode7,
      locationCode8: locationCode8 ?? this.locationCode8,
      locationCode9: locationCode9 ?? this.locationCode9,
      locationCode10: locationCode10 ?? this.locationCode10,

      // UI fields
      tempId: tempId ?? this.tempId,
      validCell: validCell ?? this.validCell,
      taxableBoolean: taxableBoolean ?? this.taxableBoolean,

      // Join descriptions
      companyCategoryDescription:
          companyCategoryDescription ?? this.companyCategoryDescription,
      defualtUomDescription:
          defualtUomDescription ?? this.defualtUomDescription,
      categoryCode01Description:
          categoryCode01Description ?? this.categoryCode01Description,
      categoryCode02Description:
          categoryCode02Description ?? this.categoryCode02Description,
      categoryCode03Description:
          categoryCode03Description ?? this.categoryCode03Description,
      categoryCode04Description:
          categoryCode04Description ?? this.categoryCode04Description,
      categoryCode05Description:
          categoryCode05Description ?? this.categoryCode05Description,
      categoryCode06Description:
          categoryCode06Description ?? this.categoryCode06Description,
      categoryCode07Description:
          categoryCode07Description ?? this.categoryCode07Description,
      categoryCode08Description:
          categoryCode08Description ?? this.categoryCode08Description,
      categoryCode09Description:
          categoryCode09Description ?? this.categoryCode09Description,
      categoryCode10Description:
          categoryCode10Description ?? this.categoryCode10Description,
    );
  }
}
