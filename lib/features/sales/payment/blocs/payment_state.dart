import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/sales/customer/models/customer_model.dart';
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
  final double grandTotal;
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
  final Customer? customer;
  final bool canApplyWithholding;
  final String? systemConstantsError;

  // System Constants
  final double vatRate;
  final double withholdingRate;
  final double withholdingInitial;

  const PaymentState({
    this.status = PaymentStatus.initial,
    this.confirmedItems = const [],
    this.subtotal = 0,
    this.taxAmount = 0,
    this.grandTotal = 0,
    this.withholdingAmount = 0,
    this.discountAmount = 0,
    this.isWithholdingEnabled = false,
    this.paymentType = 'Cash',
    this.paymentMethod = '',
    this.paymentInstrument = '',
    this.paymentTerm = '',
    this.errorMessage,
    this.transactionID,
    this.customer,
    this.canApplyWithholding = false,
    this.systemConstantsError,

    // System Constants
    this.vatRate = 0.15, //Default fallback 15%
    this.withholdingRate = 0.02, //Default fallback 2%
    this.withholdingInitial =
        10000.0, //Default fallback Minimum amount for withholding
  });

  bool get isValid =>
      confirmedItems.isNotEmpty &&
      grandTotal > 0 &&
      paymentType.isNotEmpty &&
      paymentMethod.isNotEmpty &&
      paymentInstrument.isNotEmpty &&
      paymentTerm.isNotEmpty;

  PaymentState copyWith({
    PaymentStatus? status,
    List<ConfirmedItem>? confirmedItems,
    double? subtotal,
    double? grandTotal,
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
    Customer? customer,
    bool? canApplyWithholding,
    String? systemConstantsError,

    // System Constants
    double? vatRate,
    double? withholdingRate,
    double? withholdingInitial,
  }) {
    return PaymentState(
      status: status ?? this.status,
      confirmedItems: confirmedItems ?? this.confirmedItems,
      subtotal: subtotal ?? this.subtotal,
      grandTotal: grandTotal ?? this.grandTotal,
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
      customer: customer ?? this.customer,
      canApplyWithholding: canApplyWithholding ?? this.canApplyWithholding,
      systemConstantsError: systemConstantsError ?? this.systemConstantsError,

      // System Constants
      vatRate: vatRate ?? this.vatRate,
      withholdingRate: withholdingRate ?? this.withholdingRate,
      withholdingInitial: withholdingInitial ?? this.withholdingInitial,
    );
  }

  @override
  List<Object?> get props => [
    status,
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
    customer,
    canApplyWithholding,
    systemConstantsError,

    // System Constants
    vatRate,
    withholdingRate,
    withholdingInitial,
  ];
}
