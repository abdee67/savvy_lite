// =============================
// Sales Return Details Model
// =============================

import 'package:savvy_stock/features/sales/sales_return/models/void_sales_header.dart';
import 'package:savvy_stock/features/stock/item_entry/models/item_entry_model.dart';
import 'package:savvy_stock/features/stock/item_in_branch/models/item_in_branch_model.dart';
import 'package:savvy_stock/features/stock/lot_master/models/lot_master_model.dart';
import 'package:savvy_stock/features/udc_detail/models/udc_details.dart';

class SalesReturnDetails {
  final int? id;

  final double? unitPrice;
  final double? quantity;
  final double? extendedPrice;

  final String? taxable;
  final String? reference1;
  final String? reference2;

  final int? salesReturnHeaderId;
  final int itemsTableId;
  final int? itemInBranch;

  final int? company;
  final int? lotNumber;

  final double? unitCost;

  final double? returnQuantity;
  final double? returnAmountCost;
  final double? returnAmountPrice;
  final double? returnExtendedPrice;

  final double? amountCost;

  final int? unitOfMeasure;
  final int? returnStatus;
  final int? returnReason;

  final int? tempId;

  // 🔗 Related entities (from JOIN queries)
  final SalesReturnHeader? salesReturnHeaderRef; //sales return header model
  final ItemInBranchModel? itemInBranchRef; //item in branch model
  final LotMaster? lotNumberRef; //lot master
  final UdcDetails? unitOfMeasureRef; //unit of measure
  final UdcDetails? returnStatusRef; //return status
  final UdcDetails? returnReasonRef; //return reason
  final ItemEntryModel? itemEntryRef; //item entry model

  SalesReturnDetails({
    this.id,
    this.unitPrice,
    this.quantity,
    this.extendedPrice,
    this.taxable,
    this.reference1,
    this.reference2,
    this.salesReturnHeaderId,
    required this.itemsTableId,
    this.itemInBranch,
    this.company,
    this.lotNumber,
    this.unitCost,
    this.returnQuantity,
    this.returnAmountCost,
    this.returnAmountPrice,
    this.returnExtendedPrice,
    this.amountCost,
    this.unitOfMeasure,
    this.returnStatus,
    this.returnReason,
    this.tempId,
    this.salesReturnHeaderRef,
    this.itemInBranchRef,
    this.lotNumberRef,
    this.unitOfMeasureRef,
    this.returnStatusRef,
    this.returnReasonRef,
    this.itemEntryRef,
  });

  // ====================
  // Copy With
  // ====================

  factory SalesReturnDetails.fromMap(Map<String, dynamic> map) {
    return SalesReturnDetails(
      id: map['id'],
      unitPrice: _toDouble(map['unit_price']),
      quantity: _toDouble(map['quantity']),
      extendedPrice: _toDouble(map['extended_price']),
      taxable: map['taxable']?.toString(),
      reference1: map['reference1']?.toString(),
      reference2: map['reference2']?.toString(),
      salesReturnHeaderId: map['sales_return_header_id'],
      itemsTableId: map['items_table_id'],
      itemInBranch: map['item_in_branch'],
      company: map['company'],
      lotNumber: map['lot_number'],
      unitCost: _toDouble(map['unit_cost']),
      returnQuantity: _toDouble(map['return_quantity']),
      returnAmountCost: _toDouble(map['return_amount_cost']),
      returnAmountPrice: _toDouble(map['return_amount_price']),
      returnExtendedPrice: _toDouble(map['return_extended_price']),
      amountCost: _toDouble(map['amount_cost']),
      unitOfMeasure: map['unit_of_measure'],
      returnStatus: map['return_status'],
      returnReason: map['return_reason'],
      tempId: map['temp_id'],
      salesReturnHeaderRef: map['sales_return_header_id']
          ? SalesReturnHeader(
              id: map['sales_return_header_id'],
              customerBillTo: map['customer_bill_to'],
              customerTableId: map['customer_table_id'],
              employeesId: map['employees_id'],
            )
          : null,
      itemInBranchRef: map['item_in_branch']
          ? ItemInBranchModel(
              id: map['item_in_branch'],
              itemNumber: map['item_number'],
              branch: map['branch'],
              quantityAvailable: map['availbale_quantity'],
            )
          : null,
      lotNumberRef: map['lot_number']
          ? LotMaster(id: map['lot_number'], lotNumber: map['lot_number'])
          : null,
      unitOfMeasureRef: map['unit_of_measure']
          ? UdcDetails(
              id: map['unit_of_measure'],
              detailCode: map['detail_code'],
              description1: map['unit_of_measure'],
            )
          : null,
      returnStatusRef: map['return_status']
          ? UdcDetails(
              id: map['return_status'],
              detailCode: map['detail_code'],
              description1: map['return_status'],
            )
          : null,
      returnReasonRef: map['return_reason']
          ? UdcDetails(
              id: map['return_reason'],
              detailCode: map['detail_code'],
              description1: map['return_reason'],
            )
          : null,
      itemEntryRef: map['items_table_id']
          ? ItemEntryModel(
              id: map['items_table_id'],
              itemDescription: map['item_description'],
            )
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'unit_price': unitPrice,
      'quantity': quantity,
      'extended_price': extendedPrice,
      'taxable': taxable,
      'reference1': reference1,
      'reference2': reference2,
      'sales_return_header_id': salesReturnHeaderId,
      'items_table_id': itemsTableId,
      'item_in_branch': itemInBranch,
      'company': company,
      'lot_number': lotNumber,
      'unit_cost': unitCost,
      'return_quantity': returnQuantity,
      'return_amount_cost': returnAmountCost,
      'return_amount_price': returnAmountPrice,
      'return_extended_price': returnExtendedPrice,
      'amount_cost': amountCost,
      'unit_of_measure': unitOfMeasure,
      'return_status': returnStatus,
      'return_reason': returnReason,
    };
  }

  // ====================
  // Copy With
  // ====================
  SalesReturnDetails copyWith({
    int? id,
    double? unitPrice,
    double? quantity,
    double? extendedPrice,
    String? taxable,
    String? reference1,
    String? reference2,
    int? salesReturnHeaderId,
    int? itemsTableId,
    int? itemInBranch,
    int? company,
    int? lotNumber,
    double? unitCost,
    double? returnQuantity,
    double? returnAmountCost,
    double? returnAmountPrice,
    double? returnExtendedPrice,
    double? amountCost,
    int? unitOfMeasure,
    int? returnStatus,
    int? returnReason,
    int? tempId,
    SalesReturnHeader? salesReturnHeaderRef,
    ItemInBranchModel? itemInBranchRef,
    LotMaster? lotNumberRef,
    UdcDetails? unitOfMeasureRef,
    UdcDetails? returnStatusRef,
    UdcDetails? returnReasonRef,
    ItemEntryModel? itemEntryRef,
  }) {
    return SalesReturnDetails(
      id: id ?? this.id,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      extendedPrice: extendedPrice ?? this.extendedPrice,
      taxable: taxable ?? this.taxable,
      reference1: reference1 ?? this.reference1,
      reference2: reference2 ?? this.reference2,
      salesReturnHeaderId: salesReturnHeaderId ?? this.salesReturnHeaderId,
      itemsTableId: itemsTableId ?? this.itemsTableId,
      itemInBranch: itemInBranch ?? this.itemInBranch,
      company: company ?? this.company,
      lotNumber: lotNumber ?? this.lotNumber,
      unitCost: unitCost ?? this.unitCost,
      returnQuantity: returnQuantity ?? this.returnQuantity,
      returnAmountCost: returnAmountCost ?? this.returnAmountCost,
      returnAmountPrice: returnAmountPrice ?? this.returnAmountPrice,
      returnExtendedPrice: returnExtendedPrice ?? this.returnExtendedPrice,
      amountCost: amountCost ?? this.amountCost,
      unitOfMeasure: unitOfMeasure ?? this.unitOfMeasure,
      returnStatus: returnStatus ?? this.returnStatus,
      returnReason: returnReason ?? this.returnReason,
      tempId: tempId ?? this.tempId,
      salesReturnHeaderRef: salesReturnHeaderRef ?? this.salesReturnHeaderRef,
      itemInBranchRef: itemInBranchRef ?? this.itemInBranchRef,
      lotNumberRef: lotNumberRef ?? this.lotNumberRef,
      unitOfMeasureRef: unitOfMeasureRef ?? this.unitOfMeasureRef,
      returnStatusRef: returnStatusRef ?? this.returnStatusRef,
      returnReasonRef: returnReasonRef ?? this.returnReasonRef,
      itemEntryRef: itemEntryRef ?? this.itemEntryRef,
    );
  }
}

//
// Helpers
//
DateTime? _toDate(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString());
}

String? _fromDate(DateTime? d) {
  return d?.toIso8601String();
}

double? _toDouble(dynamic v) {
  if (v == null) return null;
  return double.tryParse(v.toString());
}
