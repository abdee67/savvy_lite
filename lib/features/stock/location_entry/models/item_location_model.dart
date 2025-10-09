import 'package:equatable/equatable.dart';

class ItemLocation extends Equatable {
  // Primary Fields
  final int? id; // INTEGER PRIMARY KEY AUTOINCREMENT
  final double? quantityOnHand; // REAL

  // Relational IDs (Foreign Keys)
  final int? itemNumber; // INTEGER (FK to items_table)
  final int? branch; // INTEGER (FK to branch_table)
  final int? location; // INTEGER (FK to location_master)
  final int? company; // INTEGER (FK to company_table)

  // Audit Fields (Stored as UNIX timestamps - INTEGER)
  final DateTime? dateUpdated; // INTEGER
  final DateTime? dateCreated; // INTEGER
  final int? updatedBy; // INTEGER (FK to user_table)
  final int? createdBy; // INTEGER (FK to user_table)

  const ItemLocation({
    this.id,
    this.quantityOnHand,
    this.itemNumber,
    this.branch,
    this.location,
    this.company,
    this.dateUpdated,
    this.dateCreated,
    this.updatedBy,
    this.createdBy,
  });

  factory ItemLocation.fromMap(Map<String, dynamic> map) {
    return ItemLocation(
      id: map['id'] as int?,
      branch: map['branch'] as int?,
      createdBy: map['created_by'] as int?,
      itemNumber: map['item_number'] as int?,
      location: map['location'] as int,
      quantityOnHand: map['quantity_on_hand'] as double,
      dateCreated: map['date_created'] != null
          ? DateTime.tryParse(map['date_created'])
          : null,
      updatedBy: map['updated_by'] as int?,
      dateUpdated: map['date_updated'] != null
          ? DateTime.tryParse(map['date_updated'])
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
      'quantity_on_hand': quantityOnHand,
      'created_by': createdBy,
      'date_created': dateCreated?.toIso8601String(),
      'updated_by': updatedBy,
      'date_updated': dateUpdated?.toIso8601String(),
      'company': company,
    };
  }

  ItemLocation copyWith({
    int? id,
    int? branch,
    int? itemNumber,
    int? location,
    double? quantityOnHand,
    int? createdBy,
    DateTime? dateCreated,
    int? updatedBy,
    DateTime? dateUpdated,
    int? company,
    double? inverseConversion,
    int? tempId,
    bool? validCell,
  }) {
    return ItemLocation(
      id: id ?? this.id,
      branch: branch ?? this.branch,
      itemNumber: itemNumber ?? this.itemNumber,
      location: location ?? this.location,
      quantityOnHand: quantityOnHand ?? this.quantityOnHand,
      createdBy: createdBy ?? this.createdBy,
      dateCreated: dateCreated ?? this.dateCreated,
      updatedBy: updatedBy ?? this.updatedBy,
      dateUpdated: dateUpdated ?? this.dateUpdated,
      company: company ?? this.company,
    );
  }

  @override
  List<Object?> get props => [
    id,
    branch,
    itemNumber,
    location,
    quantityOnHand,
    createdBy,
    dateCreated,
    updatedBy,
    dateUpdated,
    company,
  ];
}
