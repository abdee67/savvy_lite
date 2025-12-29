import 'package:savvy_stock/features/sales/sales_order/header/model/sales_order_header.dart';
import 'package:savvy_stock/features/udc_detail/models/udc_details.dart';

class CreditReceipt {
  final int? id;
  final int? soHeader;
  final double? receiptAmount;
  final DateTime? dateReceipt;
  final int? paymentInstrument;
  final int? company;
  final int? userId;
  final DateTime? dateUpdated;
  final int? tempId;

  final SalesOrderHeader? soHeaderRef;
  final UdcDetails? paymentInstrumentRef;

  CreditReceipt({
    this.id,
    this.soHeader,
    this.receiptAmount,
    this.dateReceipt,
    this.paymentInstrument,
    this.company,
    this.userId,
    this.dateUpdated,
    this.tempId,
    this.soHeaderRef,
    this.paymentInstrumentRef,
  });

  factory CreditReceipt.fromMap(Map<String, dynamic> map) {
    return CreditReceipt(
      id: map['id'],
      soHeader: map['so_header'],
      receiptAmount: (map['receipt_amount'] as num?)?.toDouble(),
      dateReceipt: map['date_receipt'] != null
          ? DateTime.tryParse(map['date_receipt'])
          : null,
      paymentInstrument: map['payment_instrument'],
      company: map['company'],
      userId: map['user_id'],
      dateUpdated: map['date_updated'] != null
          ? DateTime.tryParse(map['date_updated'])
          : null,
      soHeaderRef: map['total_amount'] != null
          ? SalesOrderHeader(
              id: map['so_header'],
              amountTotal: map['total_amount'],
              orderNumber: map['order_number'],
              customerBillTo: map['customer_bill_to'],
              fsNumber: map['fs_number'],
            )
          : null,
      paymentInstrumentRef: map['payment_instrument_description'] != null
          ? UdcDetails(
              id: map['payment_instrument'],
              detailCode: map['payment_instrument_code'],
              description1: map['payment_instrument_description'],
            )
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'so_header': soHeader,
      'receipt_amount': receiptAmount,
      'date_receipt': dateReceipt?.toIso8601String(),
      'payment_instrument': paymentInstrument,
      'company': company,
      'user_id': userId,
      'date_updated': dateUpdated?.toIso8601String(),
    };
  }

  CreditReceipt copyWith({
    int? id,
    int? soHeader,
    double? receiptAmount,
    DateTime? dateReceipt,
    int? paymentInstrument,
    int? company,
    int? userId,
    DateTime? dateUpdated,
    int? tempId,
    SalesOrderHeader? soHeaderRef,
    UdcDetails? paymentInstrumentRef,
  }) {
    return CreditReceipt(
      id: id ?? this.id,
      soHeader: soHeader ?? this.soHeader,
      receiptAmount: receiptAmount ?? this.receiptAmount,
      dateReceipt: dateReceipt ?? this.dateReceipt,
      paymentInstrument: paymentInstrument ?? this.paymentInstrument,
      company: company ?? this.company,
      userId: userId ?? this.userId,
      dateUpdated: dateUpdated ?? this.dateUpdated,
      tempId: tempId ?? this.tempId,
      soHeaderRef: soHeaderRef ?? this.soHeaderRef,
      paymentInstrumentRef: paymentInstrumentRef ?? this.paymentInstrumentRef,
    );
  }
}
