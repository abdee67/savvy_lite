import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/sales/payment/blocs/payment_state.dart';

class PaymentModel extends Equatable {
  final String id;
  final String transactionID;
  final String paymentType;
  final String paymentMethod;
  final String paymentInstrument;
  final String paymentTerm;
  final String paymentStatus;
  final DateTime paymentDate;
  final double amount;
  final double discountAmount;
  final double withholdingAmount;
  final double taxAmount;

  const PaymentModel({
    required this.id,
    required this.transactionID,
    required this.paymentType,
    required this.paymentMethod,
    required this.paymentInstrument,
    required this.paymentTerm,
    required this.paymentStatus,
    required this.paymentDate,
    required this.amount,
    this.discountAmount = 0,
    this.withholdingAmount = 0,
    this.taxAmount = 0,
  });

  @override
  List<Object> get props => [
    id,
    transactionID,
    paymentType,
    paymentMethod,
    paymentInstrument,
    paymentTerm,
    paymentStatus,
    paymentDate,
    amount,
    discountAmount,
    withholdingAmount,
    taxAmount,
  ];

  PaymentModel copyWith({
    String? id,
    String? transactionID,
    String? paymentType,
    String? paymentMethod,
    String? paymentInstrument,
    String? paymentTerm,
    String? paymentStatus,
    DateTime? paymentDate,
    double? amount,
    double? discountAmount,
    double? withholdingAmount,
    double? taxAmount,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      transactionID: transactionID ?? this.transactionID,
      paymentType: paymentType ?? this.paymentType,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentInstrument: paymentInstrument ?? this.paymentInstrument,
      paymentTerm: paymentTerm ?? this.paymentTerm,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentDate: paymentDate ?? this.paymentDate,
      amount: amount ?? this.amount,
      discountAmount: discountAmount ?? this.discountAmount,
      withholdingAmount: withholdingAmount ?? this.withholdingAmount,
      taxAmount: taxAmount ?? this.taxAmount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transactionID': transactionID,
      'paymentType': paymentType,
      'paymentMethod': paymentMethod,
      'paymentInstrument': paymentInstrument,
      'paymentTerm': paymentTerm,
      'paymentStatus': paymentStatus,
      'paymentDate': paymentDate.toIso8601String(),
      'amount': amount,
      'discountAmount': discountAmount,
      'withholdingAmount': withholdingAmount,
      'taxAmount': taxAmount,
    };
  }

  factory PaymentModel.fromMap(Map<String, dynamic> map) {
    return PaymentModel(
      id: map['id']?.toString() ?? '',
      transactionID: map['transactionID']?.toString() ?? '',
      paymentType: map['paymentType']?.toString() ?? '',
      paymentMethod: map['paymentMethod']?.toString() ?? '',
      paymentInstrument: map['paymentInstrument']?.toString() ?? '',
      paymentTerm: map['paymentTerm']?.toString() ?? '',
      paymentStatus: map['paymentStatus']?.toString() ?? '',
      paymentDate: map['paymentDate'] != null
          ? DateTime.tryParse(map['paymentDate']) ?? DateTime.now()
          : DateTime.now(),
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      discountAmount: (map['discountAmount'] as num?)?.toDouble() ?? 0,
      withholdingAmount: (map['withholdingAmount'] as num?)?.toDouble() ?? 0,
      taxAmount: (map['taxAmount'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  String toString() {
    return 'PaymentModel('
        'id: $id, '
        'transactionID: $transactionID, '
        'paymentType: $paymentType, '
        'paymentMethod: $paymentMethod, '
        'paymentInstrument: $paymentInstrument, '
        'paymentTerm: $paymentTerm, '
        'paymentStatus: $paymentStatus, '
        'paymentDate: $paymentDate, '
        'amount: $amount, '
        'discountAmount: $discountAmount, '
        'withholdingAmount: $withholdingAmount, '
        'taxAmount: $taxAmount'
        ')';
  }

  // Helper method to create a PaymentModel from PaymentState
  factory PaymentModel.fromPaymentState({
    required String id,
    required String transactionID,
    required PaymentState state,
    required String paymentStatus,
  }) {
    return PaymentModel(
      id: id,
      transactionID: transactionID,
      paymentType: state.paymentType,
      paymentMethod: state.paymentMethod,
      paymentInstrument: state.paymentInstrument,
      paymentTerm: state.paymentTerm,
      paymentStatus: paymentStatus,
      paymentDate: DateTime.now(),
      amount: state.grandTotal,
      discountAmount: state.discountAmount,
      withholdingAmount: state.withholdingAmount,
      taxAmount: state.taxAmount,
    );
  }
}
