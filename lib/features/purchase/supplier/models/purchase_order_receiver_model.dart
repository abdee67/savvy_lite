class PurchaseOrderReceiverModel {
  final int? id;
  final int? poDetail;
  final int? itemNumber;
  final double? quantityTransaction;
  final double? unitCost;
  final double? amountExtendedCost;
  final double? quantityOpen;
  final double? amountOpen;
  final double? quantityRecieved;
  final double? amountReceived;
  final DateTime? dateReceived;
  final int? company;
  final int? userId;
  final DateTime? dateUpdated;
  final int? branchRecieved;
  final DateTime? dateEffective;
  final DateTime? dateExpiration;
  final int? location;
  final int? unitOfMeasure;
  final String? batchNumberSupplier;

  PurchaseOrderReceiverModel({
    this.id,
    this.poDetail,
    this.itemNumber,
    this.quantityTransaction,
    this.unitCost,
    this.amountExtendedCost,
    this.quantityOpen,
    this.amountOpen,
    this.quantityRecieved,
    this.amountReceived,
    this.dateReceived,
    this.company,
    this.userId,
    this.dateUpdated,
    this.branchRecieved,
    this.dateEffective,
    this.dateExpiration,
    this.location,
    this.unitOfMeasure,
    this.batchNumberSupplier,
  });

  factory PurchaseOrderReceiverModel.fromMap(Map<String, dynamic> map) {
    return PurchaseOrderReceiverModel(
      id: map['id'],
      poDetail: map['po_detail'],
      itemNumber: map['item_number'],
      quantityTransaction: map['quantity_transaction'],
      unitCost: map['unit_cost'],
      amountExtendedCost: map['amount_extended_cost'],
      quantityOpen: map['quantity_open'],
      amountOpen: map['amount_open'],
      quantityRecieved: map['quantity_recieved'],
      amountReceived: map['amount_received'],
      dateReceived: map['date_received'] != null
          ? DateTime.parse(map['date_received'])
          : null,
      company: map['company'],
      userId: map['user_id'],
      dateUpdated: map['date_updated'] != null
          ? DateTime.parse(map['date_updated'])
          : null,
      branchRecieved: map['branch_recieved'],
      dateEffective: map['date_effective'] != null
          ? DateTime.parse(map['date_effective'])
          : null,
      dateExpiration: map['date_expiration'] != null
          ? DateTime.parse(map['date_expiration'])
          : null,
      location: map['location'],
      unitOfMeasure: map['unit_of_measure'],
      batchNumberSupplier: map['batch_number_supplier'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'po_detail': poDetail,
      'item_number': itemNumber,
      'quantity_transaction': quantityTransaction,
      'unit_cost': unitCost,
      'amount_extended_cost': amountExtendedCost,
      'quantity_open': quantityOpen,
      'amount_open': amountOpen,
      'quantity_recieved': quantityRecieved,
      'amount_received': amountReceived,
      'date_received': dateReceived?.toIso8601String(),
      'company': company,
      'user_id': userId,
      'date_updated': dateUpdated?.toIso8601String(),
      'branch_recieved': branchRecieved,
      'date_effective': dateEffective?.toIso8601String(),
      'date_expiration': dateExpiration?.toIso8601String(),
      'location': location,
      'unit_of_measure': unitOfMeasure,
      'batch_number_supplier': batchNumberSupplier,
    };
  }
}
