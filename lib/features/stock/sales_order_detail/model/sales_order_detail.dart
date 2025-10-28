import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:savvy_stock/features/stock/sales_order_header/model/sales_order_header.dart';
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
  });

  // ✅ Create object from SQLite row (can include JOIN fields)
  factory SalesOrderDetail.fromMap(Map<String, dynamic> map) {
    return SalesOrderDetail(
      id: map['id'] as int?,
      unitPrice: (map['unit_price'] as num?)?.toDouble(),
      quantity: (map['quantity'] as num?)?.toDouble(),
      extendedPrice: (map['extended_price'] as num?)?.toDouble(),
      taxable: map['taxable'] as String?,
      reference1: map['reference1'] as String?,
      reference2: map['reference2'] as String?,
      salesOrderHeaderId: map['sales_order_header_id'] as int?,
      itemsTableId: map['items_table_id'] as int?,
      itemInBranch: map['item_in_branch'] as int?,
      company: map['company'] as int?,
      lotNumber: map['lot_number'] as int?,
      unitCost: (map['unit_cost'] as num?)?.toDouble(),
      amountCost: (map['amount_cost'] as num?)?.toDouble(),
      unitOfMeasure: map['unit_of_measure'] as int?,
      tempId: map['temp_id'] as int?,

      // 👇 Joined objects (optional)
      item: map['item_name'] != null
          ? ItemEntryModel.fromMap({
              'id': map['items_table_id'],
              'item_name': map['item_name'],
              'item_code': map['item_code'],
            })
          : null,
      lot: map['lot_batch_number_supplier'] != null
          ? LotMaster.fromMap({
              'id': map['lot_number'],
              'batch_number_supplier': map['lot_batch_number_supplier'],
            })
          : null,
      uom: map['uom_code'] != null
          ? UdcDetails.fromJson({
              'id': map['unit_of_measure'],
              'code': map['uom_code'],
              'description': map['uom_description'],
            })
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
  ];
}
