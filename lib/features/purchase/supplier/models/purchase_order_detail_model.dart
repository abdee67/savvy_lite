class PurchaseOrderDetailModel {
  final int? id;
  final int? poHeader;
  final int? itemNumber;
  final int? poReceiveStatus;
  final double? quantityTransaction;
  final double? unitCost;
  final double? amountExtendedCost;
  final double? quantityOpen;
  final double? amountOpen;
  final double? quantityRecieved;
  final double? amountReceived;
  final String? dateReceived;
  final String? dateDelivery;
  final int? company;
  final int? userId;
  final String? dateUpdated;
  final String? dateEffective;
  final String? dateExpiration;
  final int? unitOfMeasure;
  final String? batchNumberSupplier;

  PurchaseOrderDetailModel({
    this.id,
    this.poHeader,
    this.itemNumber,
    this.poReceiveStatus,
    this.quantityTransaction,
    this.unitCost,
    this.amountExtendedCost,
    this.quantityOpen,
    this.amountOpen,
    this.quantityRecieved,
    this.amountReceived,
    this.dateReceived,
    this.dateDelivery,
    this.company,
    this.userId,
    this.dateUpdated,
    this.dateEffective,
    this.dateExpiration,
    this.unitOfMeasure,
    this.batchNumberSupplier,
  });

  factory PurchaseOrderDetailModel.fromMap(Map<String, dynamic> map) {
    return PurchaseOrderDetailModel(
      id: map['id'],
      poHeader: map['po_header'],
      itemNumber: map['item_number'],
      poReceiveStatus: map['po_receive_status'],
      quantityTransaction: map['quantity_transaction'],
      unitCost: map['unit_cost'],
      amountExtendedCost: map['amount_extended_cost'],
      quantityOpen: map['quantity_open'],
      amountOpen: map['amount_open'],
      quantityRecieved: map['quantity_recieved'],
      amountReceived: map['amount_received'],
      dateReceived: map['date_received'],
      dateDelivery: map['date_delivery'],
      company: map['company'],
      userId: map['user_id'],
      dateUpdated: map['date_updated'],
      dateEffective: map['date_effective'],
      dateExpiration: map['date_expiration'],
      unitOfMeasure: map['unit_of_measure'],
      batchNumberSupplier: map['batch_number_supplier'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'po_header': poHeader,
      'item_number': itemNumber,
      'po_receive_status': poReceiveStatus,
      'quantity_transaction': quantityTransaction,
      'unit_cost': unitCost,
      'amount_extended_cost': amountExtendedCost,
      'quantity_open': quantityOpen,
      'amount_open': amountOpen,
      'quantity_recieved': quantityRecieved,
      'amount_received': amountReceived,
      'date_received': dateReceived,
      'date_delivery': dateDelivery,
      'company': company,
      'user_id': userId,
      'date_updated': dateUpdated,
      'date_effective': dateEffective,
      'date_expiration': dateExpiration,
      'unit_of_measure': unitOfMeasure,
      'batch_number_supplier': batchNumberSupplier,
    };
  }
}
