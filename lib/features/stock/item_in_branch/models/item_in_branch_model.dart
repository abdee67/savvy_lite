import 'package:savvy_stock/features/branch_list/models/branch_list_model.dart';
import 'package:savvy_stock/features/stock/item_entry/models/item_entry_model.dart';

class ItemInBranchModel {
  final int id;
  final int itemNumber;
  final Branch? branchrefrence;
  final ItemEntryModel? item;
  final int branch;
  final double? unitPrice;
  final double? quantityAvailable;
  final int? company;
  final String? unitOfMeasure;
  final double? marginRate;
  final String? marginType;

  ItemInBranchModel({
    required this.id,
    required this.itemNumber,
    this.item,
    this.branchrefrence,
    required this.branch,
    this.unitPrice,
    this.quantityAvailable,
    this.company,
    this.unitOfMeasure,
    this.marginRate,
    this.marginType,
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
      unitOfMeasure: map['unit_of_measure']?.toString(),
      marginRate: asDouble(map['margin_rate']),
      marginType: map['margin_type']?.toString(),
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
    String? unitOfMeasure,
    double? marginRate,
    String? marginType,
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
    );
  }
}
