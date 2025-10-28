import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/udc_detail/models/udc_details.dart';

class PurchaseOrderHeaderModel extends Equatable {
  final int? id;
  final int? supplierId;
  final String? dateTransaction;
  final String? dateDelivery;
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
  final String? dateUpdated;
  final double? amountOpenCredit;
  final int? orderNumber;
  final int? paymentTerm;
  final int? orderType;
  final String? creditDueDate;

  final UdcDetails? paymentStatusRef;
  final UdcDetails? paymentInstrumentRef;
  final UdcDetails? orderTypeRef;


  const PurchaseOrderHeaderModel({
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
    this.creditDueDate,
    this.paymentStatusRef,
    this.paymentInstrumentRef,
    this.orderTypeRef,
  });

  factory PurchaseOrderHeaderModel.fromMap(Map<String, dynamic> map) {
    return PurchaseOrderHeaderModel(
      id: map['id'],
      supplierId: map['supplier_id'],
      dateTransaction: map['date_transation'],
      dateDelivery: map['date_delivery'],
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
      dateUpdated: map['date_updated'],
      amountOpenCredit: map['amount_open_credit'],
      orderNumber: map['order_number'],
      paymentTerm: map['payment_term'],
      orderType: map['order_type'],
      creditDueDate: map['credit_due_date'],
      paymentStatusRef: UdcDetails.fromJson(map['payment_status_ref']),
      paymentInstrumentRef: UdcDetails.fromJson(map['payment_instrument_ref']),
      orderTypeRef: UdcDetails.fromJson(map['order_type_ref']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supplier_id': supplierId,
      'date_transation': dateTransaction,
      'date_delivery': dateDelivery,
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
      'date_updated': dateUpdated,
      'amount_open_credit': amountOpenCredit,
      'order_number': orderNumber,
      'payment_term': paymentTerm,
      'order_type': orderType,
      'credit_due_date': creditDueDate,
    };
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
        creditDueDate,
      ];
}
