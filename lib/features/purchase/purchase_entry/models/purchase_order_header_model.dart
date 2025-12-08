import 'package:savvy_stock/features/admin/users/models/user_model.dart';
import 'package:savvy_stock/features/purchase/supplier_entry/models/supplier_model.dart';
import 'package:savvy_stock/features/udc_detail/models/udc_details.dart';

class PurchaseOrderHeader {
  final int? id;
  final int? supplierId;
  final DateTime? dateTransaction;
  final DateTime? dateDelivery;
  final int? poReceiveStatus;
  final int? company;
  final double? taxableAmount;
  final double? taxAmount;
  final double? amountWithhold;
  final double? amountDiscount;
  final double? amountGross;
  final double? amountOtherCosts;
  final double? amountGrandTotalCost;
  final int? paymentStatus;
  final int? paymentInstrument;
  final int? userId;
  final DateTime? dateUpdated;
  final double? amountOpenCredit;
  final int? orderNumber;
  final int? paymentTerm;
  final int? orderType;
  DateTime? creditDueDate;
  final String? invoiceNumber;
  final int? tempId;

  // Navigation properties
  final SupplierModel? supplierRef;
  final UdcDetails? poReceiveStatusRef;
  final UdcDetails? paymentStatusRef;
  final UdcDetails? orderTypeRef;
  final UserModel? userRef;

  PurchaseOrderHeader({
    this.id,
    this.supplierId,
    this.dateTransaction,
    this.dateDelivery,
    this.poReceiveStatus,
    this.company,
    this.taxableAmount,
    this.taxAmount,
    this.amountWithhold,
    this.amountDiscount,
    this.amountGross,
    this.amountOtherCosts,
    this.amountGrandTotalCost,
    this.paymentStatus,
    this.paymentInstrument,
    this.userId,
    this.dateUpdated,
    this.amountOpenCredit,
    this.orderNumber,
    this.paymentTerm,
    this.orderType,
    this.tempId,
    this.creditDueDate,
    this.invoiceNumber,
    this.paymentStatusRef,
    this.orderTypeRef,
    this.supplierRef,
    this.poReceiveStatusRef,
    this.userRef,
  });

  factory PurchaseOrderHeader.fromMap(Map<String, dynamic> map) {
    return PurchaseOrderHeader(
      id: map['id'],
      supplierId: map['supplier_id'],
      dateTransaction: map['date_transaction'] == null
          ? null
          : DateTime.parse(map['date_transaction']),
      dateDelivery: map['date_delivery'] == null
          ? null
          : DateTime.parse(map['date_delivery']),
      poReceiveStatus: map['po_receive_status'],
      company: map['company'],
      taxableAmount: map['taxable_amount'],
      taxAmount: map['tax_amount'],
      amountWithhold: map['amount_withhold'],
      amountDiscount: map['amount_discount'],
      amountGross: map['amount_gross'],
      amountOtherCosts: map['amount_other_costs'],
      amountGrandTotalCost: map['amount_grand_total_cost'],
      paymentStatus: map['payment_status'],
      paymentInstrument: map['payment_instrument'],
      userId: map['user_id'],
      dateUpdated: map['date_updated'] == null
          ? null
          : DateTime.parse(map['date_updated']),
      amountOpenCredit: map['amount_open_credit'],
      orderNumber: map['order_number'],
      paymentTerm: map['payment_term'],
      orderType: map['order_type'],
      tempId: map['temp_id'],
      creditDueDate: map['credit_due_date'] == null
          ? null
          : DateTime.parse(map['credit_due_date']),
      invoiceNumber: map['invoice_number'],
      paymentStatusRef: map['payment_status_description'] != null
          ? UdcDetails(
              id: map['payment_status'],
              description1: map['payment_status_description'],
              detailCode: map['payment_status_code'],
            )
          : null,
      orderTypeRef: map['order_type_description'] != null
          ? UdcDetails(
              id: map['order_type'],
              description1: map['order_type_description'],
              detailCode: map['order_type_code'],
            )
          : null,
      supplierRef: map['supplier_name'] != null
          ? SupplierModel(
              id: map['supplier_id'],
              supplierName: map['supplier_name'],
            )
          : null,
      poReceiveStatusRef: map['po_receive_status_description'] != null
          ? UdcDetails(
              id: map['po_receive_status'],
              description1: map['po_receive_status_description'],
              detailCode: map['po_receive_status_code'],
            )
          : null,
      userRef: map['user_name'] != null
          ? UserModel(
              id: map['user_id'],
              userName: map['user_name'],
              password: map['password'],
            )
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supplier_id': supplierId,
      'date_transaction': dateTransaction?.toIso8601String(),
      'date_delivery': dateDelivery?.toIso8601String(),
      'po_receive_status': poReceiveStatus,
      'company': company,
      'taxable_amount': taxableAmount,
      'tax_amount': taxAmount,
      'amount_withhold': amountWithhold,
      'amount_discount': amountDiscount,
      'amount_gross': amountGross,
      'amount_other_costs': amountOtherCosts,
      'amount_grand_total_cost': amountGrandTotalCost,
      'payment_status': paymentStatus,
      'payment_instrument': paymentInstrument,
      'user_id': userId,
      'date_updated': dateUpdated?.toIso8601String(),
      'amount_open_credit': amountOpenCredit,
      'order_number': orderNumber,
      'payment_term': paymentTerm,
      'order_type': orderType,
      'credit_due_date': creditDueDate?.toIso8601String(),
      'invoice_number': invoiceNumber,
    };
  }

  //CopyWith
  PurchaseOrderHeader copyWith({
    int? id,
    int? supplierId,
    DateTime? dateTransaction,
    DateTime? dateDelivery,
    int? poReceiveStatus,
    int? company,
    double? taxableAmount,
    double? taxAmount,
    double? amountWithhold,
    double? amountDiscount,
    double? amountGross,
    double? amountOtherCosts,
    double? amountGrandTotalCost,
    int? paymentStatus,
    int? paymentInstrument,
    int? userId,
    DateTime? dateUpdated,
    double? amountOpenCredit,
    int? orderNumber,
    int? paymentTerm,
    int? orderType,
    DateTime? creditDueDate,
    String? invoiceNumber,
    int? tempId,
    UdcDetails? paymentStatusRef,
    UdcDetails? orderTypeRef,
    SupplierModel? supplierRef,
    UdcDetails? poReceiveStatusRef,
  }) {
    return PurchaseOrderHeader(
      id: id ?? this.id,
      supplierId: supplierId ?? this.supplierId,
      dateTransaction: dateTransaction ?? this.dateTransaction,
      dateDelivery: dateDelivery ?? this.dateDelivery,
      poReceiveStatus: poReceiveStatus ?? this.poReceiveStatus,
      company: company ?? this.company,
      taxableAmount: taxableAmount ?? this.taxableAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      amountWithhold: amountWithhold ?? this.amountWithhold,
      amountDiscount: amountDiscount ?? this.amountDiscount,
      amountGross: amountGross ?? this.amountGross,
      amountOtherCosts: amountOtherCosts ?? this.amountOtherCosts,
      amountGrandTotalCost: amountGrandTotalCost ?? this.amountGrandTotalCost,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentInstrument: paymentInstrument ?? this.paymentInstrument,
      userId: userId ?? this.userId,
      dateUpdated: dateUpdated ?? this.dateUpdated,
      amountOpenCredit: amountOpenCredit ?? this.amountOpenCredit,
      orderNumber: orderNumber ?? this.orderNumber,
      paymentTerm: paymentTerm ?? this.paymentTerm,
      orderType: orderType ?? this.orderType,
      creditDueDate: creditDueDate ?? this.creditDueDate,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      tempId: tempId ?? this.tempId,
      paymentStatusRef: paymentStatusRef ?? this.paymentStatusRef,
      orderTypeRef: orderTypeRef ?? this.orderTypeRef,
      supplierRef: supplierRef ?? this.supplierRef,
      poReceiveStatusRef: poReceiveStatusRef ?? this.poReceiveStatusRef,
    );
  }

  @override
  List<Object?> get props => [
    id,
    supplierId,
    dateTransaction,
    dateDelivery,
    poReceiveStatus,
    company,
    taxableAmount,
    taxAmount,
    amountWithhold,
    amountDiscount,
    amountGross,
    amountOtherCosts,
    amountGrandTotalCost,
    paymentStatus,
    paymentInstrument,
    userId,
    dateUpdated,
    amountOpenCredit,
    orderNumber,
    paymentTerm,
    orderType,
    tempId,
    creditDueDate,
    invoiceNumber,
    paymentStatusRef,
    orderTypeRef,
    supplierRef,
    poReceiveStatusRef,
  ];
}
