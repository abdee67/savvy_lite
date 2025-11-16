import 'package:savvy_stock/features/branch_list/models/branch_list_model.dart';
import 'package:savvy_stock/features/stock/location_entry/models/location_master_model.dart';
import 'package:savvy_stock/features/stock/lot_coloring/model/lot_coloring_model.dart';
import 'package:savvy_stock/features/stock/item_entry/models/item_entry_model.dart';

class LotMaster {
  final int? id;
  final int? itemNumber;
  int? lotNumber;
  final double? unitPrice;
  double? quantityAvailable;
  final int? company;
  DateTime? dateEffective;
  DateTime? dateExpiration;
  DateTime? dateReceived;
  final int? branch;
  final int? location;
  final int? lotStatus;
  final String? batchNumberSupplier;

  final String? statusCode; //A, E, I
  final String? statusDescription; //Active, Expired, Inactive
  LotExpirationColor? tempColorType;
  ItemEntryModel? itemRef;
  Branch? branchRef;
  LocationMaster? locationRef;

  LotMaster({
    this.id,
    this.itemNumber,
    this.lotNumber,
    this.unitPrice,
    this.quantityAvailable,
    this.company,
    this.dateEffective,
    this.dateExpiration,
    this.dateReceived,
    this.branch,
    this.location,
    this.lotStatus,
    this.batchNumberSupplier,
    this.statusCode,
    this.statusDescription,
    this.tempColorType,
    this.itemRef,
    this.branchRef,
    this.locationRef,
  });

  factory LotMaster.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is String) return DateTime.tryParse(v);
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
      return null;
    }

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
      if (v is num) return v.toInt();
      return null;
    }

    final itemNumber = asInt(map['item_number']);
    final branch = asInt(map['branch']);
    final location = asInt(map['location']);

    return LotMaster(
      id: asInt(map['id']),
      itemNumber: itemNumber,
      lotNumber: asInt(map['lot_number']),
      unitPrice: asDouble(map['unit_price']),
      quantityAvailable: asDouble(map['quantity_available']),
      company: asInt(map['company']),
      dateEffective: parseDate(map['date_effective']),
      dateExpiration: parseDate(map['date_expiration']),
      dateReceived: parseDate(map['date_received']),
      branch: asInt(map['branch']),
      location: asInt(map['location']),
      lotStatus: asInt(map['lot_status']),
      batchNumberSupplier: map['batch_number_supplier']?.toString(),
      //FROM JOINS
      statusCode: map['status_code']?.toString(), //A, E, I
      statusDescription: map['status_description']
          ?.toString(), //Active, Expired, Inactive
      itemRef: itemNumber != null
          ? ItemEntryModel(
              id: itemNumber,
              itemsId: (map['items_id'] ?? map['item_id'])?.toString(),
              itemDescription: map['item_description']?.toString(),
              unitOfMeasure: map['unit_of_measure']?.toString(),
              unitPrice: asDouble(map['unit_price']),
              taxable: map['taxable']?.toString(),
              barcode: map['barcode']?.toString(),
              company: asInt(map['company']),
              marginRate: asDouble(map['margin_rate']),
              marginType: map['margin_type']?.toString(),
              reorderPoint: asDouble(map['reorder_point']),
            )
          : null,
      branchRef: branch != null
          ? Branch(
              id: branch,
              referenceId: map['reference_id']?.toString(),
              description: (map['description'])?.toString(),
              city: map['city']?.toString(),
              region: map['region']?.toString(),
              country: map['country']?.toString(),
              marginRate: asDouble(map['margin_rate']),
              marginType: map['margin_type']?.toString(),
            )
          : null,
      locationRef: location != null
          ? LocationMaster(
              id: location,
              locationDescription: map['location_description']?.toString(),
            )
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item_number': itemNumber,
      'lot_number': lotNumber,
      'unit_price': unitPrice,
      'quantity_available': quantityAvailable,
      'company': company,
      'date_effective': dateEffective?.toIso8601String(),
      'date_expiration': dateExpiration?.toIso8601String(),
      'date_received': dateReceived?.toIso8601String(),
      'branch': branch,
      'location': location,
      'lot_status': lotStatus,
      'batch_number_supplier': batchNumberSupplier,
    };
  }

  LotMaster copyWith({
    int? id,
    int? branch,
    int? itemNumber,
    int? lotNumber,
    double? unitPrice,
    double? quantityAvailable,
    int? company,
    DateTime? dateEffective,
    DateTime? dateExpiration,
    DateTime? dateReceived,
    int? location,
    int? lotStatus,
    String? batchNumberSupplier,
    String? statusCode,
    String? statusDescription,
    LotExpirationColor? tempColorType,
    ItemEntryModel? itemRef,
  }) {
    return LotMaster(
      id: id ?? this.id,
      branch: branch ?? this.branch,
      itemNumber: itemNumber ?? this.itemNumber,
      lotNumber: lotNumber ?? this.lotNumber,
      unitPrice: unitPrice ?? this.unitPrice,
      quantityAvailable: quantityAvailable ?? this.quantityAvailable,
      company: company ?? this.company,
      dateEffective: dateEffective ?? this.dateEffective,
      dateExpiration: dateExpiration ?? this.dateExpiration,
      dateReceived: dateReceived ?? this.dateReceived,
      location: location ?? this.location,
      lotStatus: lotStatus ?? this.lotStatus,
      batchNumberSupplier: batchNumberSupplier ?? this.batchNumberSupplier,
      statusCode: statusCode ?? this.statusCode,
      statusDescription: statusDescription ?? this.statusDescription,
      tempColorType: tempColorType ?? this.tempColorType,
      itemRef: itemRef ?? this.itemRef,
    );
  }

  @override
  List<Object?> get props => [
    id,
    branch,
    itemNumber,
    lotNumber,
    unitPrice,
    quantityAvailable,
    company,
    dateEffective,
    dateExpiration,
    dateReceived,
    location,
    lotStatus,
    batchNumberSupplier,
    statusCode,
    statusDescription,
    tempColorType,
    itemRef,
  ];
}
