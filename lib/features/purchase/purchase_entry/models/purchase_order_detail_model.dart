import 'package:savvy_stock/features/purchase/purchase_entry/models/purchase_order_header_model.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/models/purchase_order_receiver_model.dart';
import 'package:savvy_stock/features/stock/item_entry/models/item_entry_model.dart';
import 'package:savvy_stock/features/udc_detail/models/udc_details.dart';

class PurchaseOrderDetail {
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
  final DateTime? dateReceived;
  final DateTime? dateDelivery;
  final int? company;
  final int? userId;
  final DateTime? dateUpdated;
  final DateTime? dateEffective;
  final DateTime? dateExpiration;
  final int? unitOfMeasure;
  final String? batchNumberSupplier;
  final int? tempId;
  final PurchaseOrderReceiver?
  autoReceiptReceiver; // Transient field for auto-receipt data

  // Navigation properties
  final PurchaseOrderHeader? poHeaderRef;
  final ItemEntryModel? itemNumberRef;
  final UdcDetails? poReceiveStatusRef;
  final UdcDetails? unitOfMeasureRef;

  PurchaseOrderDetail({
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
    this.tempId,
    this.autoReceiptReceiver,
    this.poHeaderRef,
    this.itemNumberRef,
    this.poReceiveStatusRef,
    this.unitOfMeasureRef,
  });

  factory PurchaseOrderDetail.fromMap(Map<String, dynamic> map) {
    return PurchaseOrderDetail(
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
      dateReceived: map['date_received'] == null
          ? null
          : DateTime.parse(map['date_received']),
      dateDelivery: map['date_delivery'] == null
          ? null
          : DateTime.parse(map['date_delivery']),
      company: map['company'],
      userId: map['user_id'],
      dateUpdated: map['date_updated'] == null
          ? null
          : DateTime.parse(map['date_updated']),
      dateEffective: map['date_effective'] == null
          ? null
          : DateTime.parse(map['date_effective']),
      dateExpiration: map['date_expiration'] == null
          ? null
          : DateTime.parse(map['date_expiration']),
      unitOfMeasure: map['unit_of_measure'],
      batchNumberSupplier: map['batch_number_supplier'],
      tempId: map['temp_id'],
      // autoReceiptReceiver is not mapped from DB columns directly unless joined,
      // but here we are strictly removing the column mapping as requested.
      poHeaderRef: map['order_number'] != null
          ? PurchaseOrderHeader(
              id: map['po_header'],
              orderNumber: map['order_number'],
              dateDelivery: map['date_delivery'] == null
                  ? null
                  : DateTime.parse(map['date_delivery']),
              poReceiveStatus: map['po_receive_status'],
              dateTransaction: map['date_transaction'] == null
                  ? null
                  : DateTime.parse(map['date_transaction']),
              invoiceNumber: map['invoice_number'],
              orderType: map['order_type'],
              supplierId: map['supplier_id'],
            )
          : null,
      poReceiveStatusRef: map['po_receive_status_description'] != null
          ? UdcDetails(
              id: map['po_receive_status'],
              description1: map['po_receive_status_description'],
              detailCode: map['po_receive_status_code'],
            )
          : null,

      itemNumberRef: map['item_description'] != null
          ? ItemEntryModel(
              id: map['item_number'],
              itemDescription: map['item_description'],
              barcode: map['item_code'],
              taxable: map['taxable'],
            )
          : null,
      unitOfMeasureRef: map['unit_of_measure_description'] != null
          ? UdcDetails(
              id: map['unit_of_measure'],
              description1: map['unit_of_measure_description'],
              detailCode: map['unit_of_measure_code'],
            )
          : null,
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
      'date_received': dateReceived?.toIso8601String(),
      'date_delivery': dateDelivery?.toIso8601String(),
      'company': company,
      'user_id': userId,
      'date_updated': dateUpdated?.toIso8601String(),
      'date_effective': dateEffective?.toIso8601String(),
      'date_expiration': dateExpiration?.toIso8601String(),
      'unit_of_measure': unitOfMeasure,
      'batch_number_supplier': batchNumberSupplier,
      // autoReceiptReceiver is NOT persisted TO the detail table
    };
  }

  // Copy with
  PurchaseOrderDetail copyWith({
    int? id,
    int? poHeader,
    int? itemNumber,
    int? poReceiveStatus,
    double? quantityTransaction,
    double? unitCost,
    double? amountExtendedCost,
    double? quantityOpen,
    double? amountOpen,
    double? quantityRecieved,
    double? amountReceived,
    DateTime? dateReceived,
    DateTime? dateDelivery,
    int? company,
    int? userId,
    DateTime? dateUpdated,
    DateTime? dateEffective,
    DateTime? dateExpiration,
    int? unitOfMeasure,
    String? batchNumberSupplier,
    int? tempId,
    PurchaseOrderReceiver? autoReceiptReceiver,
    PurchaseOrderHeader? poHeaderRef,
    ItemEntryModel? itemNumberRef,
    UdcDetails? poReceiveStatusRef,
    UdcDetails? unitOfMeasureRef,
  }) {
    return PurchaseOrderDetail(
      id: id ?? this.id,
      poHeader: poHeader ?? this.poHeader,
      itemNumber: itemNumber ?? this.itemNumber,
      poReceiveStatus: poReceiveStatus ?? this.poReceiveStatus,
      quantityTransaction: quantityTransaction ?? this.quantityTransaction,
      unitCost: unitCost ?? this.unitCost,
      amountExtendedCost: amountExtendedCost ?? this.amountExtendedCost,
      quantityOpen: quantityOpen ?? this.quantityOpen,
      amountOpen: amountOpen ?? this.amountOpen,
      quantityRecieved: quantityRecieved ?? this.quantityRecieved,
      amountReceived: amountReceived ?? this.amountReceived,
      dateReceived: dateReceived ?? this.dateReceived,
      dateDelivery: dateDelivery ?? this.dateDelivery,
      company: company ?? this.company,
      userId: userId ?? this.userId,
      dateUpdated: dateUpdated ?? this.dateUpdated,
      dateEffective: dateEffective ?? this.dateEffective,
      dateExpiration: dateExpiration ?? this.dateExpiration,
      unitOfMeasure: unitOfMeasure ?? this.unitOfMeasure,
      batchNumberSupplier: batchNumberSupplier ?? this.batchNumberSupplier,
      tempId: tempId ?? this.tempId,
      autoReceiptReceiver: autoReceiptReceiver ?? this.autoReceiptReceiver,
      poHeaderRef: poHeaderRef ?? this.poHeaderRef,
      itemNumberRef: itemNumberRef ?? this.itemNumberRef,
      poReceiveStatusRef: poReceiveStatusRef ?? this.poReceiveStatusRef,
      unitOfMeasureRef: unitOfMeasureRef ?? this.unitOfMeasureRef,
    );
  }
}
