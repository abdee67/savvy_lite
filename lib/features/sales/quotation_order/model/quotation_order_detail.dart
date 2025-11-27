// features/sales/quotation_order/models/quotation_order_detail.dart
import 'package:savvy_stock/features/sales/quotation_order/model/quotation_order_header.dart';
import 'package:savvy_stock/features/stock/item_entry/models/item_entry_model.dart';
import 'package:savvy_stock/features/stock/item_in_branch/models/item_in_branch_model.dart';
import 'package:savvy_stock/features/udc_detail/models/udc_details.dart';

class QuotationOrderDetail {
  final int? id;
  final int quoteOrderHeaderId;
  final int itemsTableId;
  final int? itemInBranch;
  final int? company;
  final double? unitPrice;
  final double? quantity;
  final double? extendedPrice;
  final double? unitCost;
  final double? amountCost;
  final String? taxable;
  final double? discountPercent;
  final double? discountAmount;
  final int? unitOfMeasure;
  final String lineStatus;
  final String? reference1;
  final String? reference2;
  final int? prformaStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? createdBy;
  final int? updatedBy;
  final int? tempId;

  // Related entities
  final ItemEntryModel? itemTableRef;
  final ItemInBranchModel? itemBranchRef;
  final UdcDetails? uomRef;
  final UdcDetails? proformaStatusRef;
  final QuotationOrderHeader? quoteOrderHeaderRef;

  QuotationOrderDetail({
    this.id,
    required this.quoteOrderHeaderId,
    required this.itemsTableId,
    this.itemInBranch,
    this.company,
    this.unitPrice,
    this.quantity,
    this.extendedPrice,
    this.unitCost,
    this.amountCost,
    this.taxable,
    this.discountPercent,
    this.discountAmount,
    this.unitOfMeasure,
    this.lineStatus = 'Open',
    this.reference1,
    this.reference2,
    this.prformaStatus,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.tempId,
    this.itemTableRef,
    this.itemBranchRef,
    this.uomRef,
    this.proformaStatusRef,
    this.quoteOrderHeaderRef,
  });

  bool get isValid => itemsTableId != 0 && quantity != null && quantity! > 0;
  bool get hasExtendedPrice => extendedPrice != null && extendedPrice! > 0;

  factory QuotationOrderDetail.fromMap(Map<String, dynamic> map) {
    return QuotationOrderDetail(
      id: map['id'],
      quoteOrderHeaderId: map['quote_order_header_id'],
      itemsTableId: map['items_table_id'],
      itemInBranch: map['item_in_branch'],
      company: map['company'],
      unitPrice: map['unit_price'],
      quantity: map['quantity'],
      extendedPrice: map['extended_price'],
      unitCost: map['unit_cost'],
      amountCost: map['amount_cost'],
      taxable: map['taxable'],
      discountPercent: map['discount_percent'],
      discountAmount: map['discount_amount'],
      unitOfMeasure: map['unit_of_measure'],
      lineStatus: map['line_status'] ?? 'Open',
      reference1: map['reference1'],
      reference2: map['reference2'],
      prformaStatus: map['prforma_status'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
      createdBy: map['created_by'],
      updatedBy: map['updated_by'],
      tempId: map['temp_id'],
      itemTableRef: map['item_table']
          ? ItemEntryModel(
              id: map['item_table'],
              itemDescription: map['item_description'],
            )
          : null,
      itemBranchRef: map['item_branch']
          ? ItemInBranchModel(
              id: map['item_branch'],
              itemNumber: map['item_number'],
              branch: map['branch'],
            )
          : null,
      uomRef: map['unit_of_measure']
          ? UdcDetails(
              id: map['unit_of_measure'],
              description1: map['unit_of_measure_description'],
              detailCode: map['unit_of_measure_code'],
            )
          : null,
      proformaStatusRef: map['proforma_status']
          ? UdcDetails(
              id: map['proforma_status'],
              description1: map['proforma_status_description'],
              detailCode: map['proforma_status_code'],
            )
          : null,
      quoteOrderHeaderRef: map['quote_order_header']
          ? QuotationOrderHeader(
              id: map['quote_order_header'],
              orderNumber: map['order_number'],
              employeesId: map['employees_id'],
              customerBillTo: map['customer_bill_to_id'],
              customerTableId: map['customer_table_id'],
            )
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'quote_order_header_id': quoteOrderHeaderId,
      'items_table_id': itemsTableId,
      'item_in_branch': itemInBranch,
      'company': company,
      'unit_price': unitPrice,
      'quantity': quantity,
      'extended_price': extendedPrice,
      'unit_cost': unitCost,
      'amount_cost': amountCost,
      'taxable': taxable,
      'discount_percent': discountPercent,
      'discount_amount': discountAmount,
      'unit_of_measure': unitOfMeasure,
      'line_status': lineStatus,
      'reference1': reference1,
      'reference2': reference2,
      'prforma_status': prformaStatus,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'created_by': createdBy,
      'updated_by': updatedBy,
      if (tempId != null) 'temp_id': tempId,
    };
  }

  QuotationOrderDetail copyWith({
    int? id,
    int? quoteOrderHeaderId,
    int? itemsTableId,
    int? itemInBranch,
    int? company,
    double? unitPrice,
    double? quantity,
    double? extendedPrice,
    double? unitCost,
    double? amountCost,
    String? taxable,
    double? discountPercent,
    double? discountAmount,
    int? unitOfMeasure,
    String? lineStatus,
    String? reference1,
    String? reference2,
    int? prformaStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? createdBy,
    int? updatedBy,
    int? tempId,
    ItemEntryModel? itemTableRef,
    ItemInBranchModel? itemBranchRef,
    UdcDetails? uomRef,
    UdcDetails? proformaStatusRef,
    QuotationOrderHeader? quoteOrderHeaderRef,
  }) {
    return QuotationOrderDetail(
      id: id ?? this.id,
      quoteOrderHeaderId: quoteOrderHeaderId ?? this.quoteOrderHeaderId,
      itemsTableId: itemsTableId ?? this.itemsTableId,
      itemInBranch: itemInBranch ?? this.itemInBranch,
      company: company ?? this.company,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      extendedPrice: extendedPrice ?? this.extendedPrice,
      unitCost: unitCost ?? this.unitCost,
      amountCost: amountCost ?? this.amountCost,
      taxable: taxable ?? this.taxable,
      discountPercent: discountPercent ?? this.discountPercent,
      discountAmount: discountAmount ?? this.discountAmount,
      unitOfMeasure: unitOfMeasure ?? this.unitOfMeasure,
      lineStatus: lineStatus ?? this.lineStatus,
      reference1: reference1 ?? this.reference1,
      reference2: reference2 ?? this.reference2,
      prformaStatus: prformaStatus ?? this.prformaStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      tempId: tempId ?? this.tempId,
      itemTableRef: itemTableRef ?? this.itemTableRef,
      itemBranchRef: itemBranchRef ?? this.itemBranchRef,
      uomRef: uomRef ?? this.uomRef,
      proformaStatusRef: proformaStatusRef ?? this.proformaStatusRef,
      quoteOrderHeaderRef: quoteOrderHeaderRef ?? this.quoteOrderHeaderRef,
    );
  }
}
