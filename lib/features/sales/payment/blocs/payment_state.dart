import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/models/confirmed_item.dart';

enum PaymentStatus {
  initial,
  loading,
  ready,
  processing,
  success,
  failure,
  cancelled,
}

class PaymentState extends Equatable {
  final PaymentStatus status;
  final List<ConfirmedItem> confirmedItems;
  final double totalAmount;
  final double subtotal;
  final double taxAmount;
  final double withholdingAmount;
  final double discountAmount;
  final bool isWithholdingEnabled;
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
    this.isWithholdingEnabled = false,
    this.paymentType = 'Cash',
    this.paymentMethod = '',
    this.paymentInstrument = '',
    this.paymentTerm = '',
    this.errorMessage,
    this.transactionID,
  });

  double get grandTotal =>
      (subtotal + taxAmount - discountAmount - withholdingAmount).clamp(
        0,
        double.infinity,
      );

  bool get isValid =>
      confirmedItems.isNotEmpty &&
      grandTotal > 0 &&
      paymentType.isNotEmpty &&
      paymentMethod.isNotEmpty &&
      paymentInstrument.isNotEmpty &&
      paymentTerm.isNotEmpty;

  PaymentState copyWith({
    PaymentStatus? status,
    double? totalAmount,
    List<ConfirmedItem>? confirmedItems,
    double? subtotal,
    double? taxAmount,
    double? withholdingAmount,
    double? discountAmount,
    bool? isWithholdingEnabled,
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
      isWithholdingEnabled: isWithholdingEnabled ?? this.isWithholdingEnabled,
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
    isWithholdingEnabled,
    paymentType,
    paymentMethod,
    paymentInstrument,
    paymentTerm,
    errorMessage,
    transactionID,
    grandTotal, // Include computed properties in props for Equatable
  ];
}
