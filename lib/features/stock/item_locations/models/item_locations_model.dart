import 'package:savvy_stock/features/branch_list/models/branch_list_model.dart';
import 'package:savvy_stock/features/stock/item_entry/models/item_entry_model.dart';
import 'package:savvy_stock/features/stock/location_entry/models/location_master_model.dart';

class ItemLocation {
  // Primary Fields
  final int? id; // INTEGER PRIMARY KEY AUTOINCREMENT
  double? quantityOnHand; // REAL

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

  //joins
  final LocationMaster? locationDescription;
  final ItemEntryModel? itemRef;
  final Branch? branchRef;

  ItemLocation({
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
    this.locationDescription,
    this.itemRef,
    this.branchRef,
  });

  factory ItemLocation.empty() {
    return ItemLocation(
      id: null,
      branch: null,
      createdBy: null,
      itemNumber: null,
      location: null,
      quantityOnHand: null,
      dateCreated: null,
      updatedBy: null,
      dateUpdated: null,
      company: null,
      locationDescription: null,
      branchRef: null,
    );
  }

  factory ItemLocation.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is String) return DateTime.tryParse(v);
      if (v is int) {
        // Support unix seconds or milliseconds
        final isMillis = v > 10000000000; // ~Sat Nov 20 2286
        return DateTime.fromMillisecondsSinceEpoch(
          isMillis ? v : v * 1000,
          isUtc: false,
        );
      }
      return null;
    }

    double? asDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    int? asInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is String) return int.tryParse(v);
      return null;
    }

    return ItemLocation(
      id: asInt(map['id']),
      branch: asInt(map['branch']),
      createdBy: asInt(map['created_by']),
      itemNumber: asInt(map['item_number']),
      location: asInt(map['location']),
      quantityOnHand: asDouble(map['quantity_on_hand']),
      dateCreated: parseDate(map['date_created']),
      updatedBy: asInt(map['updated_by']),
      dateUpdated: parseDate(map['date_updated']),
      company: asInt(map['company']),
      locationDescription: map['location_description'] != null
          ? LocationMaster(
              id: asInt(map['location']) ?? 0,
              branch: asInt(map['branch']) ?? 0,
              locationDescription: map['location_description']?.toString(),
              company: asInt(map['company']) ?? 0,
            )
          : null,
      itemRef: map['item_number'] != null
          ? ItemEntryModel(
              id: asInt(map['item_number']) ?? 0,
              itemsId: map['items_id']?.toString(),
              itemDescription: map['item_description']?.toString(),
              unitOfMeasure: map['unit_of_measure']?.toString(),
              unitPrice: asDouble(map['unit_price']),
              taxable: map['taxable']?.toString(),
              barcode: map['barcode']?.toString(),
              company: asInt(map['item_company']) ?? asInt(map['company']),
              marginRate: asDouble(map['item_margin_rate']),
              marginType: map['item_margin_type']?.toString(),
              reorderPoint: asDouble(map['item_reorder_point']),
            )
          : null,
      branchRef: map['branch'] != null
          ? Branch(
              id: asInt(map['branch']) ?? 0,
              description: map['branch_description']?.toString(),
              company: asInt(map['company']) ?? asInt(map['company']),
            )
          : null,
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
    LocationMaster? locationDescription,
    ItemEntryModel? itemRef,
    Branch? branchRef,
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
      locationDescription: locationDescription ?? this.locationDescription,
      itemRef: itemRef ?? this.itemRef,
      branchRef: branchRef ?? this.branchRef,
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
    locationDescription,
    itemRef,
  ];
}
