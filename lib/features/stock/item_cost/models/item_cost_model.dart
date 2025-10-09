import 'package:equatable/equatable.dart';

class ItemCost extends Equatable {
  final int? id;
  final int? itemNumber;
  final double? amountUnitCost;
  final int? company;
  final int? userId;
  final DateTime? dateUpdated;

  const ItemCost({
    this.id,
    this.itemNumber,
    this.amountUnitCost,
    this.company,
    this.userId,
    this.dateUpdated,
  });

  factory ItemCost.fromMap(Map<String, dynamic> map) {
    return ItemCost(
      id: map['id'] as int?,
      itemNumber: map['item_number'] as int?,
      amountUnitCost: map['amount_unit_cost'] != null
          ? (map['amount_unit_cost'] as num).toDouble()
          : null,
      company: map['company'] as int?,
      userId: map['user_id'] as int?,
      dateUpdated: map['date_updated'] != null
          ? DateTime.tryParse(map['date_updated'])
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
  }) {
    return ItemCost(
      id: id ?? this.id,
      itemNumber: itemNumber ?? this.itemNumber,
      amountUnitCost: amountUnitCost ?? this.amountUnitCost,
      company: company ?? this.company,
      userId: userId ?? this.userId,
      dateUpdated: dateUpdated ?? this.dateUpdated,
    );
  }

  @override
  List<Object?> get props => [
    id,
    itemNumber,
    amountUnitCost,
    company,
    userId,
    dateUpdated,
  ];
}
