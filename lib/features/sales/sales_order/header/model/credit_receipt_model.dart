import 'package:savvy_stock/features/sales/customer/models/customer_model.dart';
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
    this.remainingValues,
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
      soHeaderRef: map['so_header'] != null
          ? SalesOrderHeader(
              id: map['so_header'],
              amountTotal: map['total_amount'],
              customerBillTo: map['customer_bill_to'],
              orderDate: map['order_date'] != null
                  ? DateTime.tryParse(map['order_date'])
                  : null,
              fsNumber: map['fs_number'],
              orderType: map['order_type'],
              orderTypeRef: map['order_type_description'] != null
                  ? UdcDetails(
                      id: map['order_type'],
                      detailCode: map['order_type_code'],
                      description1: map['order_type_description'],
                    )
                  : null,
              customerBillToRef: map['customer_bill_to_name'] != null
                  ? Customer(
                      id: map['customer_bill_to'],
                      customerName: map['customer_bill_to_name'],
                    )
                  : null,
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
    double? remainingValues,
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
      remainingValues: remainingValues ?? this.remainingValues,
    );
  }

  double? remainingValues;
  void setRemainingValues(double value) {
    remainingValues = value;
  }
}
