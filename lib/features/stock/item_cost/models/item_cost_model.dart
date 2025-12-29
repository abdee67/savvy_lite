import 'package:savvy_stock/features/stock/item_entry/models/item_entry_model.dart';
import 'package:savvy_stock/features/stock/item_in_branch/models/item_in_branch_model.dart';
import 'package:savvy_stock/features/udc_detail/models/udc_details.dart';

class ItemCost {
  int? id;
  int? itemNumber;
  double? amountUnitCost;
  int? company;
  int? userId;
  DateTime? dateUpdated;
  int? tempId;

  //from join
  final ItemInBranchModel? fromUOM;
  final ItemEntryModel? itemRef;

  ItemCost({
    this.id,
    this.itemNumber,
    this.amountUnitCost,
    this.company,
    this.userId,
    this.dateUpdated,
    this.fromUOM,
    this.tempId,
    this.itemRef,
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
      itemRef: null,
    );
  }

  factory ItemCost.fromMap(Map<String, dynamic> map) {
    return ItemCost(
      id: map['id'],
      itemNumber: map['item_number'],
      amountUnitCost: map['amount_unit_cost'],
      company: map['company'],
      userId: map['user_id'],
      dateUpdated: map['date_updated'] != null
          ? DateTime.parse(map['date_updated'])
          : null,
      tempId: map['temp_id'],
      fromUOM: map['branch_description'] != null
          ? ItemInBranchModel(
              id: map['branch'],
              itemNumber: map['item_number'],
              branch: map['branch'],
            )
          : null,
      itemRef: map['item_description'] != null
          ? ItemEntryModel(
              id: map['item_number'],
              itemsId: map['item_id'],
              unitOfMeasure: map['unit_of_measure']?.toString(),
              itemDescription: map['item_description'],
              unitOfMeasureDescription:
                  map['unit_of_measure_description'] != null
                  ? UdcDetails(
                      id: map['unit_of_measure'],
                      description1: map['unit_of_measure_description'],
                      detailCode: map['unit_of_measure_code'],
                    )
                  : null,
            )
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item_number': itemNumber,
      'amount_unit_cost': amountUnitCost,
      'company': company,
      'user_id': userId,
      'date_updated': dateUpdated?.toIso8601String(),
    };
  }

  ItemCost copyWith({
    int? id,
    int? itemNumber,
    double? amountUnitCost,
    int? company,
    int? userId,
    DateTime? dateUpdated,
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
