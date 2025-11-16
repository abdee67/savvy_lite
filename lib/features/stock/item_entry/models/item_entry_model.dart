class ItemEntryModel {
  int id;
  final String? itemsId;
  final String? itemDescription;
  final String? unitOfMeasure;
  final double? unitPrice;
  final String? taxable; // 'Y' or 'N'
  String? barcode;
  final int? company;
  final double? marginRate;
  final String? marginType;
  final double? reorderPoint;
  String? referenceId;
  int? tempId;
  bool? validCell;
  // Additional fields from joins
  String? unitOfMeasureDescription;

  ItemEntryModel({
    required this.id,
    this.itemsId,
    this.itemDescription,
    this.unitOfMeasure,
    this.unitPrice,
    this.taxable,
    this.barcode,
    this.company,
    this.marginRate,
    this.marginType,
    this.reorderPoint,
    this.referenceId,
    this.tempId,
    this.validCell = true,
    this.unitOfMeasureDescription,
  });

  factory ItemEntryModel.empty() {
    return ItemEntryModel(
      id: 0,
      itemsId: null,
      itemDescription: null,
      unitOfMeasure: null,
      unitPrice: null,
      taxable: null,
      barcode: null,
      company: null,
      marginRate: null,
      marginType: null,
      reorderPoint: null,
    );
  }

  factory ItemEntryModel.fromMap(Map<String, dynamic> map) {
    double? asDouble(dynamic v) {
      if (v == null) return null;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    int? asInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is String) return int.tryParse(v);
      return null;
    }

    return ItemEntryModel(
      id: asInt(map['id'])!,
      itemsId: map['items_id']?.toString(),
      itemDescription: map['item_description']?.toString(),
      unitOfMeasure: map['unit_of_measure']?.toString(),
      unitPrice: asDouble(map['unit_price']),
      taxable: map['taxable']?.toString(),
      barcode: map['barcode']?.toString(),
      company: asInt(map['company']),
      marginRate: asDouble(map['margin_rate']),
      marginType: map['margin_type']?.toString(),
      reorderPoint: asDouble(map['reorder_point']),
      referenceId: map['reference_id']?.toString(),
      tempId: asInt(map['temp_id']),
      validCell: map['valid_cell'] == 1,
      unitOfMeasureDescription: map['unit_of_measure_description']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'items_id': itemsId,
      'item_description': itemDescription,
      'unit_of_measure': unitOfMeasure,
      'unit_price': unitPrice,
      'taxable': taxable,
      'barcode': barcode,
      'company': company,
      'margin_rate': marginRate,
      'margin_type': marginType,
      'reorder_point': reorderPoint,
      'reference_id': referenceId,
    };
  }

  ItemEntryModel copyWith({
    int? id,
    String? itemsId,
    String? itemDescription,
    String? unitOfMeasure,
    double? unitPrice,
    String? taxable,
    String? barcode,
    int? company,
    double? marginRate,
    String? marginType,
    double? reorderPoint,
    String? referenceId,
    int? tempId,
    bool? validCell,
    String? unitOfMeasureDescription,
  }) {
    return ItemEntryModel(
      id: id ?? this.id,
      itemsId: itemsId ?? this.itemsId,
      itemDescription: itemDescription ?? this.itemDescription,
      unitOfMeasure: unitOfMeasure ?? this.unitOfMeasure,
      unitPrice: unitPrice ?? this.unitPrice,
      taxable: taxable ?? this.taxable,
      barcode: barcode ?? this.barcode,
      company: company ?? this.company,
      marginRate: marginRate ?? this.marginRate,
      marginType: marginType ?? this.marginType,
      reorderPoint: reorderPoint ?? this.reorderPoint,
      referenceId: referenceId ?? this.referenceId,
      tempId: tempId ?? this.tempId,
      validCell: validCell ?? this.validCell,
      unitOfMeasureDescription:
          unitOfMeasureDescription ?? this.unitOfMeasureDescription,
    );
  }

  @override
  List<Object?> get props => [
    id,
    itemsId,
    itemDescription,
    unitOfMeasure,
    unitPrice,
    taxable,
    barcode,
    company,
    marginRate,
    marginType,
    reorderPoint,
    referenceId,
    tempId,
    validCell,
    unitOfMeasureDescription,
  ];
}
