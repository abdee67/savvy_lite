class SystemConstant {
  final int? id;
  late final String? applyLotMgm;
  final String? applyLocationMgm;
  final String? interfaceCustomer;
  final String? interfaceEmployee;
  final int? decimalPlaces;
  final DateTime? dateLastUpdated;
  final DateTime? timeLastUpdated;
  final int? updatedBy;
  late final String? generateBarcodeForItem;
  final int? company;
  final double? rateVatPercentage;
  final double? rateWithholdingPercentage;
  final double? withHoldInitials;
  late final String? autoSalesPrice;
  final int? lotType;
  final int? locationCategoryLevel;
  late final String? lotQtyAutoForSales;
  final int? tempId;
  final bool isSynced;
  final DateTime? lastSyncTime;

  SystemConstant({
    this.id,
    this.applyLotMgm,
    this.applyLocationMgm,
    this.interfaceCustomer,
    this.interfaceEmployee,
    this.decimalPlaces,
    this.dateLastUpdated,
    this.timeLastUpdated,
    this.updatedBy,
    this.generateBarcodeForItem,
    this.company,
    this.rateVatPercentage,
    this.rateWithholdingPercentage,
    this.withHoldInitials,
    this.autoSalesPrice,
    this.lotType,
    this.locationCategoryLevel,
    this.lotQtyAutoForSales,
    this.tempId,
    this.isSynced = true,
    this.lastSyncTime,
  });

  factory SystemConstant.fromJson(Map<String, dynamic> json) {
    return SystemConstant(
      id: json['id'],
      applyLotMgm: json['apply_lot_mgm'],
      applyLocationMgm: json['apply_location_mgm'],
      interfaceCustomer: json['interface_customer'],
      interfaceEmployee: json['interface_employee'],
      decimalPlaces: json['decimal_places'],
      dateLastUpdated: json['date_last_updated'] != null
          ? DateTime.parse(json['date_last_updated'])
          : null,
      timeLastUpdated: json['time_last_updated'] != null
          ? DateTime.parse('1970-01-01 ${json['time_last_updated']}')
          : null,
      updatedBy: json['ubpdated_by'],
      generateBarcodeForItem: json['generate_barcode_for_item'],
      company: json['company'],
      rateVatPercentage: json['rate_vat_percentage']?.toDouble(),
      rateWithholdingPercentage: json['rate_with_percentage']?.toDouble(),
      withHoldInitials: json['with_hold_initials']?.toDouble(),
      autoSalesPrice: json['auto_sales_price'],
      lotType: json['lot_type'],
      locationCategoryLevel: json['location_category_level'],
      lotQtyAutoForSales: json['lot_qty_auto_for_sales'],
      isSynced: json['is_synced'] == 1,
      lastSyncTime: json['last_sync_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['last_sync_time'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'apply_lot_mgm': applyLotMgm,
      'apply_location_mgm': applyLocationMgm,
      'interface_customer': interfaceCustomer,
      'interface_employee': interfaceEmployee,
      'decimal_places': decimalPlaces,
      'date_last_updated': dateLastUpdated?.toIso8601String().split('T')[0],
      'time_last_updated': timeLastUpdated
          ?.toIso8601String()
          .split('T')[1]
          .substring(0, 8),
      'ubpdated_by': updatedBy,
      'generate_barcode_for_item': generateBarcodeForItem,
      'company': company,
      'rate_vat_percentage': rateVatPercentage,
      'rate_with_percentage': rateWithholdingPercentage,
      'with_hold_initials': withHoldInitials,
      'auto_sales_price': autoSalesPrice,
      'lot_type': lotType,
      'location_category_level': locationCategoryLevel,
      'lot_qty_auto_for_sales': lotQtyAutoForSales,
      'is_synced': isSynced ? 1 : 0,
      'last_sync_time': lastSyncTime?.millisecondsSinceEpoch,
    };
  }

  Map<String, dynamic> toDatabaseMap() {
    return {
      'id': id,
      'apply_lot_mgm': applyLotMgm,
      'apply_location_mgm': applyLocationMgm,
      'interface_customer': interfaceCustomer,
      'interface_employee': interfaceEmployee,
      'decimal_places': decimalPlaces,
      'date_last_updated': dateLastUpdated?.millisecondsSinceEpoch,
      'time_last_updated': timeLastUpdated?.millisecondsSinceEpoch,
      'updated_by': updatedBy,
      'generate_barcode_for_item': generateBarcodeForItem,
      'company': company,
      'rate_vat_percentage': rateVatPercentage,
      'rate_with_percentage': rateWithholdingPercentage,
      'with_hold_initials': withHoldInitials,
      'auto_sales_price': autoSalesPrice,
      'lot_type': lotType,
      'location_category_level': locationCategoryLevel,
      'lot_qty_auto_for_sales': lotQtyAutoForSales,
      'is_synced': isSynced ? 1 : 0,
      'last_sync_time': lastSyncTime?.millisecondsSinceEpoch,
    };
  }

  factory SystemConstant.fromDatabaseMap(Map<String, dynamic> map) {
    return SystemConstant(
      id: map['id'],
      applyLotMgm: map['apply_lot_mgm'],
      applyLocationMgm: map['apply_location_mgm'],
      interfaceCustomer: map['interface_customer'],
      interfaceEmployee: map['interface_employee'],
      decimalPlaces: map['decimal_places'],
      dateLastUpdated: map['date_last_updated'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['date_last_updated'])
          : null,
      timeLastUpdated: map['time_last_updated'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['time_last_updated'])
          : null,
      updatedBy: map['updated_by'],
      generateBarcodeForItem: map['generate_barcode_for_item'],
      company: map['company'],
      rateVatPercentage: map['rate_vat_percentage']?.toDouble(),
      rateWithholdingPercentage: map['rate_with_percentage']?.toDouble(),
      withHoldInitials: map['with_hold_initials']?.toDouble(),
      autoSalesPrice: map['auto_sales_price'],
      lotType: map['lot_type'] is String
          ? int.tryParse(map['lot_type'])
          : map['lot_type'],
      locationCategoryLevel: map['location_category_level'],
      lotQtyAutoForSales: map['lot_qty_auto_for_sales'],
      isSynced: map['is_synced'] == 1,
      lastSyncTime: map['last_sync_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_sync_time'])
          : null,
    );
  }
  bool get shouldAutoGenerateBarcodeForItem => generateBarcodeForItem == 'Y';

  SystemConstant copyWith({
    int? id,
    String? applyLotMgm,
    String? applyLocationMgm,
    String? interfaceCustomer,
    String? interfaceEmployee,
    int? decimalPlaces,
    DateTime? dateLastUpdated,
    DateTime? timeLastUpdated,
    int? updatedBy,
    String? generateBarcodeForItem,
    int? company,
    double? rateVatPercentage,
    double? rateWithholdingPercentage,
    double? withHoldInitials,
    String? autoSalesPrice,
    int? lotType,
    int? locationCategoryLevel,
    String? lotQtyAutoForSales,
    int? tempId,
    bool? isSynced,
    DateTime? lastSyncTime,
  }) {
    return SystemConstant(
      id: id ?? this.id,
      applyLotMgm: applyLotMgm ?? this.applyLotMgm,
      applyLocationMgm: applyLocationMgm ?? this.applyLocationMgm,
      interfaceCustomer: interfaceCustomer ?? this.interfaceCustomer,
      interfaceEmployee: interfaceEmployee ?? this.interfaceEmployee,
      decimalPlaces: decimalPlaces ?? this.decimalPlaces,
      dateLastUpdated: dateLastUpdated ?? this.dateLastUpdated,
      timeLastUpdated: timeLastUpdated ?? this.timeLastUpdated,
      updatedBy: updatedBy ?? this.updatedBy,
      generateBarcodeForItem:
          generateBarcodeForItem ?? this.generateBarcodeForItem,
      company: company ?? this.company,
      rateVatPercentage: rateVatPercentage ?? this.rateVatPercentage,
      rateWithholdingPercentage:
          rateWithholdingPercentage ?? this.rateWithholdingPercentage,
      withHoldInitials: withHoldInitials ?? this.withHoldInitials,
      autoSalesPrice: autoSalesPrice ?? this.autoSalesPrice,
      lotType: lotType ?? this.lotType,
      locationCategoryLevel:
          locationCategoryLevel ?? this.locationCategoryLevel,
      lotQtyAutoForSales: lotQtyAutoForSales ?? this.lotQtyAutoForSales,
      tempId: tempId ?? this.tempId,
      isSynced: isSynced ?? this.isSynced,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }

  // Helper methods for boolean conversions
  bool get applyLotMgmBoolean => applyLotMgm == 'Y';
  bool get lotQtyAutoForSalesBoolean => lotQtyAutoForSales == 'Y';
  bool get autoSalesPriceBoolean => autoSalesPrice == 'Y';
  bool get generateBarcodeForItemBoolean => generateBarcodeForItem == 'Y';

  set applyLotMgmBoolean(bool value) => applyLotMgm = value ? 'Y' : 'N';
  set lotQtyAutoForSalesBoolean(bool value) =>
      lotQtyAutoForSales = value ? 'Y' : 'N';
  set autoSalesPriceBoolean(bool value) => autoSalesPrice = value ? 'Y' : 'N';
  set generateBarcodeForItemBoolean(bool value) =>
      generateBarcodeForItem = value ? 'Y' : 'N';
}
