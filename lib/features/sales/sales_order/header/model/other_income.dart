import 'package:savvy_stock/features/udc_detail/models/udc_details.dart';

class OtherIncome {
  final int? id;
  final double? incomeAmount;
  final DateTime? dateIncome;
  final String? reasonDescription;
  final int? paymentInstrument;
  final int? company;
  final int? userId;
  final DateTime? dateUpdated;

  final UdcDetails? paymentInstrumentRef;

  OtherIncome({
    this.id,
    this.incomeAmount,
    this.dateIncome,
    this.reasonDescription,
    this.paymentInstrument,
    this.company,
    this.userId,
    this.dateUpdated,
    this.paymentInstrumentRef,
  });

  factory OtherIncome.fromMap(Map<String, dynamic> map) {
    return OtherIncome(
      id: map['id'],
      incomeAmount: (map['income_amount'] as num?)?.toDouble(),
      dateIncome: map['date_income'] != null
          ? DateTime.tryParse(map['date_income'])
          : null,
      reasonDescription: map['reason_description'],
      paymentInstrument: map['payment_instrument'],
      company: map['company'],
      userId: map['user_id'],
      dateUpdated: map['date_updated'] != null
          ? DateTime.tryParse(map['date_updated'])
          : null,
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
      'income_amount': incomeAmount,
      'date_income': dateIncome?.toIso8601String(),
      'reason_description': reasonDescription,
      'payment_instrument': paymentInstrument,
      'company': company,
      'user_id': userId,
      'date_updated': dateUpdated?.toIso8601String(),
    };
  }

  OtherIncome copyWith({
    int? id,
    double? incomeAmount,
    DateTime? dateIncome,
    String? reasonDescription,
    int? paymentInstrument,
    int? company,
    int? userId,
    DateTime? dateUpdated,
    UdcDetails? paymentInstrumentRef,
  }) {
    return OtherIncome(
      id: id ?? this.id,
      incomeAmount: incomeAmount ?? this.incomeAmount,
      dateIncome: dateIncome ?? this.dateIncome,
      reasonDescription: reasonDescription ?? this.reasonDescription,
      paymentInstrument: paymentInstrument ?? this.paymentInstrument,
      company: company ?? this.company,
      userId: userId ?? this.userId,
      dateUpdated: dateUpdated ?? this.dateUpdated,
      paymentInstrumentRef: paymentInstrumentRef ?? this.paymentInstrumentRef,
    );
  }
}
