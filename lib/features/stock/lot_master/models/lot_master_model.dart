import 'package:savvy_stock/features/stock/lot_coloring/model/lot_coloring_model.dart';

class LotMaster {
  final int? id;
  final int? itemNumber;
  final int? lotNumber;
  final double? unitPrice;
  final double? quantityAvailable;
  final int? company;
  final DateTime? dateEffective;
  final DateTime? dateExpiration;
  final DateTime? dateReceived;
  final int? branch;
  final int? location;
  final int? lotStatus;
  final String? batchNumberSupplier;

  final String? statusCode; //A, E, I
  final String? statusDescription; //Active, Expired, Inactive
  LotExpirationColor? tempColorType;

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
  });

  factory LotMaster.fromMap(Map<String, dynamic> map) {
    return LotMaster(
      id: map['id'] as int?,
      itemNumber: map['item_number'] as int?,
      lotNumber: map['lot_number'] as int?,
      unitPrice: map['unit_price'] != null
          ? (map['unit_price'] as num).toDouble()
          : null,
      quantityAvailable: map['quantity_available'] != null
          ? (map['quantity_available'] as num).toDouble()
          : null,
      company: map['company'] as int?,
      dateEffective: map['date_effective'] != null
          ? DateTime.tryParse(map['date_effective'])
          : null,
      dateExpiration: map['date_expiration'] != null
          ? DateTime.tryParse(map['date_expiration'])
          : null,
      dateReceived: map['date_received'] != null
          ? DateTime.tryParse(map['date_received'])
          : null,
      branch: map['branch'] as int?,
      location: map['location'] as int?,
      lotStatus: map['lot_status'] as int?,
      batchNumberSupplier: map['batch_number_supplier'] as String?,
      //FROM JOINS
      statusCode: map['status_code'] as String?, //A, E, I
      statusDescription:
          map['status_description'] as String?, //Active, Expired, Inactive
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
  ];
}
