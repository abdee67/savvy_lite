import 'package:savvy_stock/features/udc_detail/models/udc_details.dart';

class OtherExpense {
  final int? id;
  final double? paymentAmount;
  final DateTime? datePayment;
  final String? reasonDescription;
  final int? paymentInstrument;
  final int? company;
  final int? userId;
  final DateTime? dateUpdated;
  final int? tempId; // For local state management

  final UdcDetails? paymentInstrumentRef;

  OtherExpense({
    this.id,
    this.paymentAmount,
    this.datePayment,
    this.reasonDescription,
    this.paymentInstrument,
    this.company,
    this.userId,
    this.dateUpdated,
    this.paymentInstrumentRef,
    this.tempId,
  });

  factory OtherExpense.empty() {
    return OtherExpense(
      id: null,
      paymentAmount: null,
      datePayment: null,
      reasonDescription: null,
      paymentInstrument: null,
      company: null,
      userId: null,
      dateUpdated: null,
      paymentInstrumentRef: null,
      tempId: null,
    );
  }

  factory OtherExpense.fromMap(Map<String, dynamic> map) {
    return OtherExpense(
      id: map['id'],
      paymentAmount: (map['payment_amount'] as num?)?.toDouble(),
      datePayment: map['date_payment'] != null
          ? DateTime.tryParse(map['date_payment'])
          : null,
      reasonDescription: map['reason_description'],
      paymentInstrument: map['payment_instrument'],
      company: map['company'],
      userId: map['user_id'],
      dateUpdated: map['date_updated'] != null
          ? DateTime.tryParse(map['date_updated'])
          : null,
      tempId: map['temp_id'],
      paymentInstrumentRef: map['payment_instrument_description'] != null
          ? UdcDetails(
              id: map['payment_instrument'],
              description1: map['payment_instrument_description'],
              detailCode: map['payment_instrument_code'],
            )
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'payment_amount': paymentAmount,
      'date_payment': datePayment?.toIso8601String(),
      'reason_description': reasonDescription,
      'payment_instrument': paymentInstrument,
      'company': company,
      'user_id': userId,
      'date_updated': dateUpdated?.toIso8601String(),
    };
  }

  OtherExpense copyWith({
    int? id,
    double? paymentAmount,
    DateTime? datePayment,
    String? reasonDescription,
    int? paymentInstrument,
    int? company,
    int? userId,
    DateTime? dateUpdated,
    UdcDetails? paymentInstrumentRef,
    int? tempId,
  }) {
    return OtherExpense(
      id: id ?? this.id,
      paymentAmount: paymentAmount ?? this.paymentAmount,
      datePayment: datePayment ?? this.datePayment,
      reasonDescription: reasonDescription ?? this.reasonDescription,
      paymentInstrument: paymentInstrument ?? this.paymentInstrument,
      company: company ?? this.company,
      userId: userId ?? this.userId,
      dateUpdated: dateUpdated ?? this.dateUpdated,
      paymentInstrumentRef: paymentInstrumentRef ?? this.paymentInstrumentRef,
      tempId: tempId ?? this.tempId,
    );
  }
}
