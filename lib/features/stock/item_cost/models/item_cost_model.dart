import 'package:savvy_stock/features/stock/item_entry/models/item_entry_model.dart';
import 'package:savvy_stock/features/stock/item_in_branch/models/item_in_branch_model.dart';

class ItemCost {
  int? id;
  int? itemNumber;
  double? amountUnitCost;
  int? company;
  int? userId;
  int? dateUpdated;
  int? tempId;

  //from join
  final ItemInBranchModel? fromUOM;

  ItemCost({
    this.id,
    this.itemNumber,
    this.amountUnitCost,
    this.company,
    this.userId,
    this.dateUpdated,
    this.fromUOM,
    this.tempId,

  });
  factory ItemCost.empty() {
    return ItemCost(
      id: null,
      itemNumber: null,
      amountUnitCost: null,
      company: null,
      userId: null,
      dateUpdated: null,
      fromUOM: null,
      tempId: null,
    );
  }

  factory ItemCost.fromMap(Map<String, dynamic> map) {
    return ItemCost(
      id: map['id'],
      itemNumber: map['item_number'],
      amountUnitCost: map['amount_unit_cost'],
      company: map['company'],
      userId: map['user_id'],
      dateUpdated: map['date_updated'],
      tempId: map['temp_id'],
      fromUOM: ItemInBranchModel.fromMap(map),
        );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item_number': itemNumber,
      'amount_unit_cost': amountUnitCost,
      'company': company,
      'user_id': userId,
      'date_updated': dateUpdated,
    };
  }

  ItemCost copyWith({
    int? id,
    int? itemNumber,
    double? amountUnitCost,
    int? company,
    int? userId,
    int? dateUpdated,
    int? tempId,
  }) {
    return ItemCost(
      id: id ?? this.id,
      itemNumber: itemNumber ?? this.itemNumber,
      amountUnitCost: amountUnitCost ?? this.amountUnitCost,
      company: company ?? this.company,
      userId: userId ?? this.userId,
      dateUpdated: dateUpdated ?? this.dateUpdated,
      tempId: tempId ?? this.tempId,
    );
  }
}