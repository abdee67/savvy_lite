import 'package:savvy_stock/features/purchase/purchase_entry/models/purchase_order_header_model.dart';
import 'package:savvy_stock/features/udc_detail/models/udc_details.dart';

class CreditPayment {
  final int? id;
  final int? poHeader;
  final double? paymentAmount;
  final DateTime? datePayment;
  final int? paymentInstrument;
  final int? company;
  final int? userId;
  final DateTime? dateUpdated;
  final int? tempId; // For unsaved payments

  final PurchaseOrderHeader? poHeaderRef;
  final UdcDetails? paymentInstrumentRef;

  CreditPayment({
    this.id,
    this.poHeader,
    this.paymentAmount,
    this.datePayment,
    this.paymentInstrument,
    this.company,
    this.userId,
    this.dateUpdated,
    this.poHeaderRef,
    this.tempId,
    this.paymentInstrumentRef,
  });

  /// -----------------------
  /// Map → Model
  /// -----------------------
  factory CreditPayment.fromMap(Map<String, dynamic> map) {
    return CreditPayment(
      id: map['id'],
      poHeader: map['po_header'],
      paymentAmount: (map['payment_amount'] as num?)?.toDouble(),
      datePayment: map['date_payment'] != null
          ? DateTime.tryParse(map['date_payment'])
          : null,
      paymentInstrument: map['payment_instrument'],
      company: map['company'],
      userId: map['user_id'],
      dateUpdated: map['date_updated'] != null
          ? DateTime.tryParse(map['date_updated'])
          : null,
      poHeaderRef: map['total_amount'] != null
          ? PurchaseOrderHeader(
              id: map['po_header_id'],
              amountGrandTotalCost: map['total_amount'],
              invoiceNumber: map['invoice_number'],
              supplierId: map['supplier_id'],
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
      'po_header': poHeader,
      'payment_amount': paymentAmount,
      'date_payment': datePayment?.toIso8601String(),
      'payment_instrument': paymentInstrument,
      'company': company,
      'user_id': userId,
      'date_updated': dateUpdated?.toIso8601String(),
    };
  }

  /// CopyWith for safe updates
  CreditPayment copyWith({
    int? id,
    int? poHeader,
    double? paymentAmount,
    DateTime? datePayment,
    int? paymentInstrument,
    int? company,
    int? userId,
    DateTime? dateUpdated,
    int? tempId,
    PurchaseOrderHeader? poHeaderRef,
  }) {
    return CreditPayment(
      id: id ?? this.id,
      poHeader: poHeader ?? this.poHeader,
      paymentAmount: paymentAmount ?? this.paymentAmount,
      datePayment: datePayment ?? this.datePayment,
      paymentInstrument: paymentInstrument ?? this.paymentInstrument,
      company: company ?? this.company,
      userId: userId ?? this.userId,
      dateUpdated: dateUpdated ?? this.dateUpdated,
      poHeaderRef: poHeaderRef ?? this.poHeaderRef,
      tempId: tempId ?? this.tempId,
    );
  }
}
