import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/stock/item_entry/models/item_entry_model.dart';
import 'package:savvy_stock/features/udc_detail/models/udc_details.dart';

class ItemUomConversion extends Equatable {
  final int? id;
  final int? branch;
  final int? itemNumber;
  final double? conversionFactor;
  final int? createdBy;
  final DateTime? dateCreated;
  final int? updatedBy;
  final DateTime? dateUpdated;
  final int? fromUom;
  final UdcDetails? fromUOM;
  final ItemEntryModel? itemName;
  final int? toUom;
  final UdcDetails? toUOM;
  final int? uomStructureLevel;
  final double? inverseConversion;
  final int? company;

  //transient proprties
  final int? tempId;
  final bool? validCell;

  const ItemUomConversion({
    this.id,
    this.branch,
    this.itemNumber,
    this.conversionFactor,
    this.createdBy,
    this.dateCreated,
    this.updatedBy,
    this.dateUpdated,
    this.fromUom,
    this.itemName,
    this.toUom,
    this.fromUOM,
    this.toUOM,
    this.uomStructureLevel,
    this.inverseConversion,
    this.company,
    this.tempId,
    this.validCell,
  });

  factory ItemUomConversion.empty() {
    return ItemUomConversion(
      id: null,
      branch: null,
      itemNumber: null,
      conversionFactor: null,
      createdBy: null,
      dateCreated: null,
      updatedBy: null,
      dateUpdated: null,
      fromUom: null,
      toUom: null,
      uomStructureLevel: null,
      inverseConversion: null,
      company: null,
    );
  }

  factory ItemUomConversion.fromMap(Map<String, dynamic> map) {
    return ItemUomConversion(
      id: map['id'] as int?,
      branch: map['branch'] as int?,
      itemNumber: map['item_number'] as int?,
      conversionFactor: map['conversion_factor']?.toDouble(),
      createdBy: map['created_by'] as int?,
      dateCreated: map['date_created'] != null
          ? DateTime.tryParse(map['date_created'])
          : null,
      updatedBy: map['updated_by'] as int?,
      dateUpdated: map['date_updated'] != null
          ? DateTime.tryParse(map['date_updated'])
          : null,
      fromUom: map['from_uom'] as int?,
      toUom: map['to_uom'] as int?,
      uomStructureLevel: map['uom_structure_level'] as int?,
      inverseConversion: map['inverse_conversion']?.toDouble(),
      company: map['company'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'branch': branch,
      'item_number': itemNumber,
      'conversion_factor': conversionFactor,
      'created_by': createdBy,
      'date_created': dateCreated?.toIso8601String(),
      'updated_by': updatedBy,
      'date_updated': dateUpdated?.toIso8601String(),
      'from_uom': fromUom,
      'to_uom': toUom,
      'uom_structure_level': uomStructureLevel,
      'inverse_conversion': inverseConversion,
      'company': company,
    };
  }

  ItemUomConversion copyWith({
    int? id,
    int? branch,
    int? itemNumber,
    double? conversionFactor,
    int? createdBy,
    DateTime? dateCreated,
    int? updatedBy,
    DateTime? dateUpdated,
    int? fromUom,
    ItemEntryModel? itemName,
    int? toUom,
    UdcDetails? fromUOM,
    UdcDetails? toUOM,
    int? uomStructureLevel,
    double? inverseConversion,
    int? company,
    int? tempId,
    bool? validCell,
  }) {
    return ItemUomConversion(
      id: id ?? this.id,
      branch: branch ?? this.branch,
      itemNumber: itemNumber ?? this.itemNumber,
      conversionFactor: conversionFactor ?? this.conversionFactor,
      createdBy: createdBy ?? this.createdBy,
      dateCreated: dateCreated ?? this.dateCreated,
      updatedBy: updatedBy ?? this.updatedBy,
      itemName: itemName ?? this.itemName,
      dateUpdated: dateUpdated ?? this.dateUpdated,
      fromUom: fromUom ?? this.fromUom,
      toUom: toUom ?? this.toUom,
      fromUOM: fromUOM ?? this.fromUOM,
      toUOM: toUOM ?? this.toUOM,
      uomStructureLevel: uomStructureLevel ?? this.uomStructureLevel,
      inverseConversion: inverseConversion ?? this.inverseConversion,
      company: company ?? this.company,
      tempId: tempId ?? this.tempId,
      validCell: validCell ?? this.validCell,
    );
  }

  @override
  List<Object?> get props => [
    id,
    branch,
    itemNumber,
    conversionFactor,
    createdBy,
    dateCreated,
    updatedBy,
    itemName,
    dateUpdated,
    fromUom,
    toUom,
    fromUOM,
    toUOM,
    uomStructureLevel,
    inverseConversion,
    company,
    tempId,
    validCell,
  ];
}
