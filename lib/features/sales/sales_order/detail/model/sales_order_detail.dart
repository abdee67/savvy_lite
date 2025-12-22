import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:savvy_stock/features/sales/sales_order/header/model/sales_order_header.dart';
import 'package:savvy_stock/features/stock/item_entry/models/item_entry_model.dart';
import 'package:savvy_stock/features/stock/item_in_branch/models/item_in_branch_model.dart';
import 'package:savvy_stock/features/stock/lot_master/models/lot_master_model.dart';
import 'package:savvy_stock/features/udc_detail/models/udc_details.dart';

@immutable
class SalesOrderDetail extends Equatable {
  final int? id;
  final double? unitPrice;
  final double? quantity;
  final double? extendedPrice;
  final String? taxable;
  final String? reference1;
  final String? reference2;
  final int? salesOrderHeaderId;
  final int? itemsTableId;
  final int? itemInBranch;
  final int? company;
  final int? lotNumber;
  final double? unitCost;
  final double? amountCost;
  final int? unitOfMeasure;
  final int? tempId;

  // 🔗 Related entities (from JOIN queries)
  final ItemEntryModel? item;
  final LotMaster? lot;
  final ItemInBranchModel? itemBranch;
  final UdcDetails? uom;
  final SalesOrderHeader? orderHeader;
  final int? quantityAvailable;
  final int? lotQuantityAvailable;
  final DateTime? lotExpiration;

  const SalesOrderDetail({
    this.id,
    this.unitPrice,
    this.quantity,
    this.extendedPrice,
    this.taxable,
    this.reference1,
    this.reference2,
    this.salesOrderHeaderId,
    this.itemsTableId,
    this.itemInBranch,
    this.company,
    this.lotNumber,
    this.unitCost,
    this.amountCost,
    this.unitOfMeasure,
    this.item,
    this.lot,
    this.itemBranch,
    this.uom,
    this.orderHeader,
    this.tempId,
    this.quantityAvailable,
    this.lotQuantityAvailable,
    this.lotExpiration,
  });

  // ✅ Create object from SQLite row (can include JOIN fields)
  factory SalesOrderDetail.fromMap(Map<String, dynamic> map) {
    return SalesOrderDetail(
      id: (map['id'] as num?)?.toInt(),
      unitPrice: (map['unit_price'] as num?)?.toDouble(),
      quantity: (map['quantity'] as num?)?.toDouble(),
      extendedPrice: (map['extended_price'] as num?)?.toDouble(),
      taxable: map['taxable']?.toString(),
      reference1: map['reference1']?.toString(),
      reference2: map['reference2']?.toString(),
      salesOrderHeaderId: (map['sales_order_header_id'] as num?)?.toInt(),
      itemsTableId: (map['items_table_id'] as num?)?.toInt(),
      itemInBranch: (map['item_in_branch'] as num?)?.toInt(),
      company: (map['company'] as num?)?.toInt(),
      lotNumber: (map['lot_number'] as num?)?.toInt(),
      unitCost: (map['unit_cost'] as num?)?.toDouble(),
      amountCost: (map['amount_cost'] as num?)?.toDouble(),
      unitOfMeasure: (map['unit_of_measure'] as num?)?.toInt(),
      quantityAvailable: (map['quantity_available'] as num?)?.toInt(),
      lotQuantityAvailable: (map['lot_quantity_available'] as num?)?.toInt(),
      lotExpiration: map['lot_expiration'] != null
          ? DateTime.tryParse(map['lot_expiration'].toString())
          : null,

      tempId: (map['temp_id'] as num?)?.toInt(),

      // 👇 Joined objects (optional)
      item: map['items_id'] != null
          ? ItemEntryModel(
              id: map['items_table_id'],
              itemsId: map['items_id'],
              itemDescription: map['item_description'],
              unitOfMeasure: map['unit_of_measure'],
              unitPrice: map['unit_price'],
              taxable: map['taxable'],
              barcode: map['barcode'],
              company: map['company'],
              marginRate: map['margin_rate'],
              marginType: map['margin_type'],
              reorderPoint: map['reorder_point'],
              referenceId: map['reference_id'],
              tempId: map['temp_id'],
              validCell: map['valid_cell'],
              unitOfMeasureDescription: map['unit_of_measure_description'],
            )
          : null,
      lot: map['lot_number'] != null && map['batch_number_supplier'] != null
          ? LotMaster(
              id: map['lot_number'],
              batchNumberSupplier: map['batch_number_supplier'],
              itemNumber: map['item_number'],
              branch: map['branch'],
              location: map['location'],
              lotStatus: map['lot_status'],
              dateEffective: map['date_effective'],
              dateExpiration: map['date_expiration'],
              dateReceived: map['date_received'],
              company: map['company'],
              statusCode: map['status_code'],
              statusDescription: map['status_description'],
              quantityAvailable: map['quantity_available'],
            )
          : null,
      itemBranch: map['item_in_branch'] != null && map['item_number'] != null
          ? ItemInBranchModel(
              id: map['item_in_branch'],
              itemNumber: map['item_number'],
              branch: map['branch'],
              quantityAvailable: map['quantity_available'],
              company: map['company'],
              unitOfMeasure: map['unit_of_measure'],
            )
          : null,
      uom: map['unit_of_measure_description'] != null
          ? UdcDetails(
              id: map['unit_of_measure'],
              description1: map['unit_of_measure_description'],
              detailCode: map['unit_of_measure_code'],
            )
          : null,
      orderHeader: map['order_type'] != null
          ? SalesOrderHeader(
              id: map['sales_order_header_id'],
              customerBillTo: map['customer_bill_to'],
              orderType: map['order_type'],
            )
          : null,
    );
  }

  // ✅ Convert object to SQLite insert/update map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'unit_price': unitPrice,
      'quantity': quantity,
      'extended_price': extendedPrice,
      'taxable': taxable,
      'reference1': reference1,
      'reference2': reference2,
      'sales_order_header_id': salesOrderHeaderId,
      'items_table_id': itemsTableId,
      'item_in_branch': itemInBranch,
      'company': company,
      'lot_number': lotNumber,
      'unit_cost': unitCost,
      'amount_cost': amountCost,
      'unit_of_measure': unitOfMeasure,
    };
  }

  bool get isValid => itemsTableId != 0 && quantity != null && quantity! > 0;
  bool get hasExtendedPrice => extendedPrice != null && extendedPrice! > 0;

  SalesOrderDetail copyWith({
    int? id,
    double? unitPrice,
    double? quantity,
    double? extendedPrice,
    String? taxable,
    String? reference1,
    String? reference2,
    int? salesOrderHeaderId,
    int? itemsTableId,
    int? itemInBranch,
    int? company,
    int? lotNumber,
    double? unitCost,
    double? amountCost,
    int? unitOfMeasure,
    ItemEntryModel? item,
    LotMaster? lot,
    ItemInBranchModel? itemBranch,
    UdcDetails? uom,
    SalesOrderHeader? orderHeader,
    int? quantityAvailable,
    int? lotQuantityAvailable,
    DateTime? lotExpiration,
    int? tempId,
  }) {
    return SalesOrderDetail(
      id: id ?? this.id,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      extendedPrice: extendedPrice ?? this.extendedPrice,
      taxable: taxable ?? this.taxable,
      reference1: reference1 ?? this.reference1,
      reference2: reference2 ?? this.reference2,
      salesOrderHeaderId: salesOrderHeaderId ?? this.salesOrderHeaderId,
      itemsTableId: itemsTableId ?? this.itemsTableId,
      itemInBranch: itemInBranch ?? this.itemInBranch,
      company: company ?? this.company,
      lotNumber: lotNumber ?? this.lotNumber,
      unitCost: unitCost ?? this.unitCost,
      amountCost: amountCost ?? this.amountCost,
      unitOfMeasure: unitOfMeasure ?? this.unitOfMeasure,
      item: item ?? this.item,
      lot: lot ?? this.lot,
      itemBranch: itemBranch ?? this.itemBranch,
      uom: uom ?? this.uom,
      orderHeader: orderHeader ?? this.orderHeader,
      quantityAvailable: quantityAvailable ?? this.quantityAvailable,
      lotQuantityAvailable: lotQuantityAvailable ?? this.lotQuantityAvailable,
      lotExpiration: lotExpiration ?? this.lotExpiration,
      tempId: tempId ?? this.tempId,
    );
  }

  @override
  List<Object?> get props => [
    id,
    unitPrice,
    quantity,
    extendedPrice,
    taxable,
    reference1,
    reference2,
    salesOrderHeaderId,
    itemsTableId,
    itemInBranch,
    company,
    lotNumber,
    unitCost,
    amountCost,
    unitOfMeasure,
    item,
    lot,
    itemBranch,
    uom,
    orderHeader,
    quantityAvailable,
    lotQuantityAvailable,
    lotExpiration,
    tempId,
  ];
}

class StockValidationResult {
  final bool isValid;
  final double availableQuantity;
  final double requestedQuantity;
  final double beyondQuantity;
  final String message;

  const StockValidationResult({
    required this.isValid,
    required this.availableQuantity,
    required this.requestedQuantity,
    required this.beyondQuantity,
    required this.message,
  });
}
