import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/models/confirmed_item.dart';

enum PaymentStatus { initial, loading, ready, processing, success, failure }

class PaymentState extends Equatable {
  final PaymentStatus status;
  final List<ConfirmedItem> confirmedItems;
  final double totalAmount;
  final double subtotal;
  final double taxAmount;
  final double withholdingAmount;
  final double discountAmount;
  final String paymentType;
  final String paymentMethod;
  final String paymentInstrument;
  final String paymentTerm;
  final String? errorMessage;
  final String? transactionID;

  const PaymentState({
    this.status = PaymentStatus.initial,
    this.totalAmount = 0,
    this.confirmedItems = const [],
    this.subtotal = 0,
    this.taxAmount = 0,
    this.withholdingAmount = 0,
    this.discountAmount = 0,
    this.paymentType = 'Cash',
    this.paymentMethod = '',
    this.paymentInstrument = '',
    this.paymentTerm = '',
    this.errorMessage,
    this.transactionID,
  });

  double get grandTotal =>
      subtotal + taxAmount - discountAmount - withholdingAmount;
  double get grandTotalWithheld => grandTotal - withholdingAmount;
  double get grandTotalDiscount => grandTotal - discountAmount;
  double get grandTotalTax => grandTotal - taxAmount;
  double get grandTotalWithholding => grandTotal - withholdingAmount;
  bool get isValid =>
      confirmedItems.isNotEmpty &&
      totalAmount > 0 &&
      paymentType.isNotEmpty &&
      paymentMethod.isNotEmpty &&
      paymentInstrument.isNotEmpty &&
      paymentTerm.isNotEmpty &&
      grandTotalWithheld >= 0 &&
      grandTotalDiscount >= 0 &&
      grandTotalTax >= 0 &&
      grandTotalWithholding >= 0;

  PaymentState copyWith({
    PaymentStatus? status,
    double? totalAmount,
    List<ConfirmedItem>? confirmedItems,
    double? subtotal,
    double? taxAmount,
    double? withholdingAmount,
    double? discountAmount,
    String? paymentType,
    String? paymentMethod,
    String? paymentInstrument,
    String? paymentTerm,
    String? errorMessage,
    String? transactionID,
  }) {
    return PaymentState(
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      confirmedItems: confirmedItems ?? this.confirmedItems,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      withholdingAmount: withholdingAmount ?? this.withholdingAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      paymentType: paymentType ?? this.paymentType,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentInstrument: paymentInstrument ?? this.paymentInstrument,
      paymentTerm: paymentTerm ?? this.paymentTerm,
      errorMessage: errorMessage ?? this.errorMessage,
      transactionID: transactionID ?? this.transactionID,
    );
  }

  @override
  List<Object?> get props => [
    status,
    totalAmount,
    confirmedItems,
    subtotal,
    taxAmount,
    withholdingAmount,
    discountAmount,
    paymentType,
    paymentMethod,
    paymentInstrument,
    paymentTerm,
    errorMessage,
    transactionID,
  ];
}
