import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/branch_list/models/branch_list_model.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/models/purchase_order_detail_model.dart';
import 'package:savvy_stock/features/stock/item_entry/models/item_entry_model.dart';
import 'package:savvy_stock/features/stock/item_locations/models/item_locations_model.dart';
import 'package:savvy_stock/features/stock/location_entry/models/location_master_model.dart';
import 'package:savvy_stock/features/udc_detail/models/udc_details.dart';

class PurchaseOrderReceiver extends Equatable {
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
  final int? tempId;
  final bool? validCell;

  // Navigation properties
  final PurchaseOrderDetail? poDetailRef;
  final ItemEntryModel? itemNumberRef;
  final Branch? branchRecievedRef;
  final LocationMaster? locationRef;
  final UdcDetails? unitOfMeasureRef;

  const PurchaseOrderReceiver({
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
    this.poDetailRef,
    this.itemNumberRef,
    this.branchRecievedRef,
    this.locationRef,
    this.unitOfMeasureRef,
    this.tempId,
    this.validCell,
  });

  factory PurchaseOrderReceiver.fromMap(Map<String, dynamic> map) {
    return PurchaseOrderReceiver(
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
      poDetailRef: map['quantity_transaction'] != null
          ? PurchaseOrderDetail(
              id: map['po_detail'],
              dateEffective: map['date_effective'] != null
                  ? DateTime.parse(map['date_effective'])
                  : null,
              dateDelivery: map['date_delivery'] != null
                  ? DateTime.parse(map['date_delivery'])
                  : null,
              poReceiveStatus: map['po_receive_status'],
              quantityTransaction: map['quantity_transaction'],
              unitCost: map['unit_cost'],
              amountExtendedCost: map['amount_extended_cost'],
            )
          : null,
      itemNumberRef: map['item_description'] != null
          ? ItemEntryModel(
              id: map['item_number'],
              itemDescription: map['item_description'],
              barcode: map['item_code'],
            )
          : null,
      branchRecievedRef: map['branch_recieved_description'] != null
          ? Branch(
              id: map['branch_recieved'],
              description: map['branch_recieved_description'],
            )
          : null,
      locationRef: map['location_description'] != null
          ? LocationMaster(
              id: map['location'],
              locationDescription: map['location_description'],
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

  //CopyWith
  PurchaseOrderReceiver copyWith({
    int? id,
    int? poDetail,
    int? itemNumber,
    double? quantityTransaction,
    double? unitCost,
    double? amountExtendedCost,
    double? quantityOpen,
    double? amountOpen,
    double? quantityRecieved,
    double? amountReceived,
    DateTime? dateReceived,
    int? company,
    int? userId,
    DateTime? dateUpdated,
    int? branchRecieved,
    DateTime? dateEffective,
    DateTime? dateExpiration,
    int? location,
    int? unitOfMeasure,
    String? batchNumberSupplier,
    PurchaseOrderDetail? poDetailRef,
    ItemEntryModel? itemNumberRef,
    Branch? branchRecievedRef,
    LocationMaster? locationRef,
    UdcDetails? unitOfMeasureRef,
    int? tempId,
    bool? validCell,
  }) {
    return PurchaseOrderReceiver(
      id: id ?? this.id,
      poDetail: poDetail ?? this.poDetail,
      itemNumber: itemNumber ?? this.itemNumber,
      quantityTransaction: quantityTransaction ?? this.quantityTransaction,
      unitCost: unitCost ?? this.unitCost,
      amountExtendedCost: amountExtendedCost ?? this.amountExtendedCost,
      quantityOpen: quantityOpen ?? this.quantityOpen,
      amountOpen: amountOpen ?? this.amountOpen,
      quantityRecieved: quantityRecieved ?? this.quantityRecieved,
      amountReceived: amountReceived ?? this.amountReceived,
      dateReceived: dateReceived ?? this.dateReceived,
      company: company ?? this.company,
      userId: userId ?? this.userId,
      dateUpdated: dateUpdated ?? this.dateUpdated,
      branchRecieved: branchRecieved ?? this.branchRecieved,
      dateEffective: dateEffective ?? this.dateEffective,
      dateExpiration: dateExpiration ?? this.dateExpiration,
      location: location ?? this.location,
      unitOfMeasure: unitOfMeasure ?? this.unitOfMeasure,
      batchNumberSupplier: batchNumberSupplier ?? this.batchNumberSupplier,
      poDetailRef: poDetailRef ?? this.poDetailRef,
      itemNumberRef: itemNumberRef ?? this.itemNumberRef,
      branchRecievedRef: branchRecievedRef ?? this.branchRecievedRef,
      locationRef: locationRef ?? this.locationRef,
      unitOfMeasureRef: unitOfMeasureRef ?? this.unitOfMeasureRef,
      tempId: tempId ?? this.tempId,
      validCell: validCell ?? this.validCell,
    );
  }

  @override
  List<Object?> get props => [
    id,
    poDetail,
    itemNumber,
    quantityTransaction,
    unitCost,
    amountExtendedCost,
    quantityOpen,
    amountOpen,
    quantityRecieved,
    amountReceived,
    dateReceived,
    company,
    userId,
    dateUpdated,
    branchRecieved,
    dateEffective,
    dateExpiration,
    location,
    unitOfMeasure,
    batchNumberSupplier,
    poDetailRef,
    itemNumberRef,
    branchRecievedRef,
    locationRef,
    unitOfMeasureRef,
    tempId,
    validCell,
  ];
}
