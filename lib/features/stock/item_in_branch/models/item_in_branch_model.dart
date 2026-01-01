import 'package:savvy_stock/features/branch_list/models/branch_list_model.dart';
import 'package:savvy_stock/features/stock/item_entry/models/item_entry_model.dart';
import 'package:savvy_stock/features/udc_detail/models/udc_details.dart';

class ItemInBranchModel {
  final int id;
  final int itemNumber;
  final ItemEntryModel? item;
  final int branch;
  final double? unitPrice;
  double? quantityAvailable;
  final int? company;
  final int? unitOfMeasure;
  final double? marginRate;
  final String? marginType;
  double? reorderPoint;
  int? tempId;

  // Additional fields from joins
  ItemEntryModel? itemRef;
  Branch? branchRef;
  final UdcDetails? unitOfMeasureRef;

  ItemInBranchModel({
    required this.id,
    required this.itemNumber,
    this.item,
    required this.branch,
    this.unitPrice,
    this.quantityAvailable,
    this.company,
    this.unitOfMeasure,
    this.marginRate,
    this.marginType,
    this.reorderPoint,
    this.tempId,
    this.itemRef,
    this.branchRef,
    this.unitOfMeasureRef,
  });

  factory ItemInBranchModel.empty() {
    return ItemInBranchModel(id: 0, itemNumber: 0, branch: 0, company: null);
  }

  factory ItemInBranchModel.fromMap(Map<String, dynamic> map) {
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

    return ItemInBranchModel(
      id: asInt(map['id'])!,
      itemNumber: asInt(map['item_number'])!,
      branch: asInt(map['branch'])!,
      unitPrice: asDouble(map['unit_price']),
      quantityAvailable: asDouble(map['quantity_available']),
      company: asInt(map['company'])!,
      unitOfMeasure: asInt(map['unit_of_measure']),
      marginRate: asDouble(map['margin_rate']),
      marginType: map['margin_type']?.toString(),
      reorderPoint: asDouble(map['reorder_point']),
      branchRef: map['branch'] != null
          ? Branch(
              id: asInt(map['branch']) ?? 0,
              referenceId: map['branch_reference']?.toString(),
              description: map['branch_description']?.toString(),
              city: map['branch_city']?.toString(),
              region: map['branch_region']?.toString(),
              state: map['branch_state']?.toString(),
              country: map['branch_country']?.toString(),
              addressLine: map['branch_address_line']?.toString(),
              company: asInt(map['branch_company']),
              branchPhone: map['branch_phone']?.toString(),
              marginRate: asDouble(map['branch_margin_rate']),
              marginType: map['branch_margin_type']?.toString(),
            )
          : null,
      unitOfMeasureRef: map['unit_of_measure'] != null
          ? UdcDetails(
              id: asInt(map['unit_of_measure']) ?? 0,
              description1: map['unit_of_measure_description'],
              detailCode: map['unit_of_measure_code'],
            )
          : null,
      itemRef: map['item_number'] != null
          ? ItemEntryModel(
              id: asInt(map['item_number']) ?? 0,
              itemsId: map['items_id']?.toString(),
              itemDescription: map['item_description']?.toString(),
              unitOfMeasure: map['unit_of_measure']?.toString(),
              unitOfMeasureDescription:
                  map['unit_of_measure_description'] != null
                  ? UdcDetails(
                      id: asInt(map['unit_of_measure']) ?? 0,
                      description1:
                          map['unit_of_measure_description']?.toString() ?? '',
                      detailCode: map['unit_of_measure_code']?.toString() ?? '',
                    )
                  : null,
              unitPrice: asDouble(map['unit_price']),
              taxable: map['taxable']?.toString(),
              barcode: map['barcode']?.toString(),
              company: asInt(map['item_company']) ?? asInt(map['company']),
              marginRate: asDouble(map['item_margin_rate']),
              marginType: map['item_margin_type']?.toString(),
              reorderPoint: asDouble(map['item_reorder_point']),
            )
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item_number': itemNumber,
      'branch': branch,
      'unit_price': unitPrice,
      'quantity_available': quantityAvailable,
      'company': company,
      'unit_of_measure': unitOfMeasure,
      'margin_rate': marginRate,
      'margin_type': marginType,
    };
  }

  ItemInBranchModel copyWith({
    int? id,
    int? itemNumber,
    int? branch,
    double? unitPrice,
    double? quantityAvailable,
    int? company,
    int? unitOfMeasure,
    double? marginRate,
    String? marginType,
    int? tempId,
    Branch? branchRef,
    ItemEntryModel? itemRef,
  }) {
    return ItemInBranchModel(
      id: id ?? this.id,
      itemNumber: itemNumber ?? this.itemNumber,
      branch: branch ?? this.branch,
      unitPrice: unitPrice ?? this.unitPrice,
      quantityAvailable: quantityAvailable ?? this.quantityAvailable,
      company: company ?? this.company,
      unitOfMeasure: unitOfMeasure ?? this.unitOfMeasure,
      marginRate: marginRate ?? this.marginRate,
      marginType: marginType ?? this.marginType,
      tempId: tempId ?? this.tempId,
      branchRef: branchRef ?? this.branchRef,
      itemRef: itemRef ?? this.itemRef,
    );
  }
}
