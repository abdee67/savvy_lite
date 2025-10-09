import 'package:equatable/equatable.dart';

class ItemLocation extends Equatable {
  final int? id;
  final int? branch;
  final int? itemNumber;
  final int? location;
  final int? createdBy;
  final DateTime? dateCreated;
  final int? updatedBy;
  final DateTime? dateUpdated;
  final double? quantityOnHand;
  final int? company;

  const ItemLocation({
    this.id,
    this.branch,
    this.itemNumber,
    this.location,
    this.createdBy,
    this.dateCreated,
    this.updatedBy,
    this.dateUpdated,
    this.quantityOnHand,
    this.company,
  });

  factory ItemLocation.fromMap(Map<String, dynamic> map) {
    return ItemLocation(
      id: map['id'] as int?,
      branch: map['branch'] as int?,
      itemNumber: map['item_number'] as int?,
      location: map['location'] as int?,
      createdBy: map['created_by'] as int?,
      dateCreated: map['date_created'] != null
          ? DateTime.tryParse(map['date_created'])
          : null,
      updatedBy: map['updated_by'] as int?,
      dateUpdated: map['date_updated'] != null
          ? DateTime.tryParse(map['date_updated'])
          : null,
      quantityOnHand: map['quantity_on_hand'] != null
          ? (map['quantity_on_hand'] as num).toDouble()
          : null,
      company: map['company'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'branch': branch,
      'item_number': itemNumber,
      'location': location,
      'created_by': createdBy,
      'date_created': dateCreated?.toIso8601String(),
      'updated_by': updatedBy,
      'date_updated': dateUpdated?.toIso8601String(),
      'quantity_on_hand': quantityOnHand,
      'company': company,
    };
  }

  ItemLocation copyWith({
    int? id,
    int? branch,
    int? itemNumber,
    int? location,
    int? createdBy,
    DateTime? dateCreated,
    int? updatedBy,
    DateTime? dateUpdated,
    double? quantityOnHand,
    int? company,
  }) {
    return ItemLocation(
      id: id ?? this.id,
      branch: branch ?? this.branch,
      itemNumber: itemNumber ?? this.itemNumber,
      location: location ?? this.location,
      createdBy: createdBy ?? this.createdBy,
      dateCreated: dateCreated ?? this.dateCreated,
      updatedBy: updatedBy ?? this.updatedBy,
      dateUpdated: dateUpdated ?? this.dateUpdated,
      quantityOnHand: quantityOnHand ?? this.quantityOnHand,
      company: company ?? this.company,
    );
  }

  @override
  List<Object?> get props => [
    id,
    branch,
    itemNumber,
    location,
    createdBy,
    dateCreated,
    updatedBy,
    dateUpdated,
    quantityOnHand,
    company,
  ];
}
