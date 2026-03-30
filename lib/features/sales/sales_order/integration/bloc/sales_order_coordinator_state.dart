// features/sales/sales_order/coordinator/bloc/sales_order_coordinator_state.dart
import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/sales/customer/models/customer_model.dart';
import 'package:savvy_stock/features/sales/sales_order/invoice/detail/model/invoice_detail_model.dart';
import 'package:savvy_stock/features/sales/sales_order/invoice/header/model/invoice_header_model.dart';
import 'package:savvy_stock/features/sales/sales_order/header/model/sales_order_header.dart';
import 'package:savvy_stock/features/sales/sales_order/detail/model/sales_order_detail.dart';
import 'package:savvy_stock/features/stock/item_in_branch/models/item_in_branch_model.dart';

enum SalesOrderCoordinatorStatus {
  initial,
  loading,
  creatingHeader,
  creatingDetails,
  updatingHeader,
  updatingDetails,
  voiding,
  preparing,
  prepared,
  processing,
  reversingStock,
  calculating,
  synchronizing,
  success,
  error,
  partialError,
  rollback,
  paymentProcessing,
}

class SalesOrderCoordinatorState extends Equatable {
  final SalesOrderCoordinatorStatus status;
  final String? error;
  final String? lastOperation;
  final Set<String> pendingOperations;

  // Order Data
  final SalesOrderHeader? currentHeader;
  final List<SalesOrderDetail> currentDetails;
  final List<SalesOrderDetail> lastSavedDetails;

  // Financial Calculations
  final double? lastSubTotal;
  final double? lastTax;
  final double? lastWithholdAmount;
  final double? lastTotalAmount;
  final double? lastDiscountAmount;
  final double? lastAmountOpen;
  final DateTime? lastCalculationTime;

  // Payment Details
  final String paymentMethod;
  final int paymentStatus;
  final int paymentInstrument;
  final String paymentTerm;
  final String? transactionID;
  final String? salesRepresent;
  final String? commentsSo;
  final String? referenceNote1;
  final String? referenceNote2;
  final String? referenceNote3;

  // Tax & Fees Configuration
  final double? vatRate;
  final double? withholdingRate;
  final double? withholdingInitial;
  final bool isWithholdingEnabled;
  final bool canApplyWithholding;

  // Validation & Status
  final bool isStockValidated;
  final bool isCalculationsComplete;
  final bool isOrderComplete;
  final Map<int, ItemInBranchModel> stockValidationResults;

  // System Constants
  final String? systemConstantsError;
  final DateTime? lastSyncTime;
  final String? successMessage;
  final Customer? defaultCustomer;

  // Invoice Generation
  final bool invoiceGenerated;
  final InvoiceHistoryHeader? invoiceHeader;
  final List<InvoiceHistoryDetail> invoiceDetails;
  final String? invoiceFsNumber;

  // Filter
  final String filterQuery;

  const SalesOrderCoordinatorState({
    this.status = SalesOrderCoordinatorStatus.initial,
    this.error,
    this.lastOperation,
    this.pendingOperations = const {},
    this.currentHeader,
    this.currentDetails = const [],
    this.lastSavedDetails = const [],
    this.lastSubTotal,
    this.lastTax,
    this.lastWithholdAmount,
    this.lastTotalAmount,
    this.lastDiscountAmount,
    this.lastAmountOpen,
    this.lastCalculationTime,
    this.paymentMethod = 'Cash',
    this.paymentStatus = 0,
    this.paymentInstrument = 0,
    this.paymentTerm = '',
    this.transactionID,
    this.salesRepresent,
    this.commentsSo,
    this.referenceNote1,
    this.referenceNote2,
    this.referenceNote3,
    this.vatRate,
    this.withholdingRate,
    this.withholdingInitial,
    this.isWithholdingEnabled = false,
    this.canApplyWithholding = false,
    this.isStockValidated = false,
    this.isCalculationsComplete = false,
    this.isOrderComplete = false,
    this.stockValidationResults = const {},
    this.systemConstantsError,
    this.lastSyncTime,
    this.successMessage,
    this.defaultCustomer,
    this.invoiceDetails = const [],
    this.invoiceGenerated = false,
    this.invoiceHeader,
    this.invoiceFsNumber,
    this.filterQuery = '',
  });

  // Getters for financial data
  double get subtotal => lastSubTotal ?? 0.0;
  double get taxAmount => lastTax ?? 0.0;
  double get withholdingAmount => lastWithholdAmount ?? 0.0;
  double get discountAmount => lastDiscountAmount ?? 0.0;
  double get grandTotal => lastTotalAmount ?? 0.0;

  // Validation getters
  bool get isValid =>
      currentHeader != null &&
      currentDetails.isNotEmpty &&
      paymentMethod.isNotEmpty &&
      invoiceHeader != null &&
      invoiceDetails.isNotEmpty &&
      paymentInstrument != 0 &&
      (paymentMethod != 'Credit' || paymentTerm.isNotEmpty);

  bool get requiresStockValidation => currentDetails.isNotEmpty;
  bool get isProcessing => status == SalesOrderCoordinatorStatus.processing;
  bool get isPaymentProcessing =>
      status == SalesOrderCoordinatorStatus.paymentProcessing;

  @override
  List<Object?> get props => [
    status,
    currentHeader,
    currentDetails,
    lastSavedDetails,
    error,
    successMessage,
    lastSyncTime,
    lastOperation,
    lastCalculationTime,
    isOrderComplete,
    isStockValidated,
    isCalculationsComplete,
    stockValidationResults,
    lastSubTotal,
    lastTax,
    lastWithholdAmount,
    lastDiscountAmount,
    lastTotalAmount,
    pendingOperations,
    defaultCustomer,
    lastAmountOpen,
    paymentMethod,
    paymentInstrument,
    paymentTerm,
    transactionID,
    salesRepresent,
    commentsSo,
    referenceNote1,
    referenceNote2,
    referenceNote3,
    vatRate,
    withholdingRate,
    withholdingInitial,
    isWithholdingEnabled,
    canApplyWithholding,
    invoiceDetails,
    invoiceGenerated,
    invoiceHeader,
    invoiceFsNumber,
    filterQuery,
  ];

  SalesOrderCoordinatorState copyWith({
    SalesOrderCoordinatorStatus? status,
    SalesOrderHeader? currentHeader,
    List<SalesOrderDetail>? currentDetails,
    List<SalesOrderDetail>? lastSavedDetails,
    String? error,
    String? successMessage,
    DateTime? lastSyncTime,
    String? lastOperation,
    DateTime? lastCalculationTime,
    bool? isOrderComplete,
    bool? isStockValidated,
    bool? isCalculationsComplete,
    Map<int, ItemInBranchModel>? stockValidationResults,
    double? lastSubTotal,
    double? lastTax,
    double? lastWithholdAmount,
    double? lastDiscountAmount,
    double? lastTotalAmount,
    Set<String>? pendingOperations,
    Customer? defaultCustomer,
    double? lastAmountOpen,
    int? paymentStatus,
    String? paymentMethod,
    int? paymentInstrument,
    String? paymentTerm,
    String? transactionID,
    String? salesRepresent,
    String? commentsSo,
    String? referenceNote1,
    String? referenceNote2,
    String? referenceNote3,
    double? vatRate,
    double? withholdingRate,
    double? withholdingInitial,
    bool? isWithholdingEnabled,
    bool? canApplyWithholding,
    List<InvoiceHistoryDetail>? invoiceDetails,
    bool? invoiceGenerated,
    InvoiceHistoryHeader? invoiceHeader,
    String? invoiceFsNumber,
    String? filterQuery,
  }) {
    return SalesOrderCoordinatorState(
      status: status ?? this.status,
      currentHeader: currentHeader ?? this.currentHeader,
      currentDetails: currentDetails ?? this.currentDetails,
      lastSavedDetails: lastSavedDetails ?? this.lastSavedDetails,
      error: error ?? this.error,
      successMessage: successMessage ?? this.successMessage,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      lastOperation: lastOperation ?? this.lastOperation,
      lastCalculationTime: lastCalculationTime ?? this.lastCalculationTime,
      isOrderComplete: isOrderComplete ?? this.isOrderComplete,
      isStockValidated: isStockValidated ?? this.isStockValidated,
      isCalculationsComplete:
          isCalculationsComplete ?? this.isCalculationsComplete,
      stockValidationResults:
          stockValidationResults ?? this.stockValidationResults,
      lastSubTotal: lastSubTotal ?? this.lastSubTotal,
      lastTax: lastTax ?? this.lastTax,
      lastWithholdAmount: lastWithholdAmount ?? this.lastWithholdAmount,
      lastDiscountAmount: lastDiscountAmount ?? this.lastDiscountAmount,
      lastTotalAmount: lastTotalAmount ?? this.lastTotalAmount,
      pendingOperations: pendingOperations ?? this.pendingOperations,
      defaultCustomer: defaultCustomer ?? this.defaultCustomer,
      lastAmountOpen: lastAmountOpen ?? this.lastAmountOpen,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentInstrument: paymentInstrument ?? this.paymentInstrument,
      paymentTerm: paymentTerm ?? this.paymentTerm,
      transactionID: transactionID ?? this.transactionID,
      salesRepresent: salesRepresent ?? this.salesRepresent,
      commentsSo: commentsSo ?? this.commentsSo,
      referenceNote1: referenceNote1 ?? this.referenceNote1,
      referenceNote2: referenceNote2 ?? this.referenceNote2,
      referenceNote3: referenceNote3 ?? this.referenceNote3,
      vatRate: vatRate ?? this.vatRate,
      withholdingRate: withholdingRate ?? this.withholdingRate,
      withholdingInitial: withholdingInitial ?? this.withholdingInitial,
      isWithholdingEnabled: isWithholdingEnabled ?? this.isWithholdingEnabled,
      canApplyWithholding: canApplyWithholding ?? this.canApplyWithholding,
      invoiceDetails: invoiceDetails ?? this.invoiceDetails,
      invoiceGenerated: invoiceGenerated ?? this.invoiceGenerated,
      invoiceHeader: invoiceHeader ?? this.invoiceHeader,
      invoiceFsNumber: invoiceFsNumber ?? this.invoiceFsNumber,
      filterQuery: filterQuery ?? this.filterQuery,
    );
  }

  // Helper methods
  SalesOrderCoordinatorState loadingState(String operation) {
    return copyWith(
      status: SalesOrderCoordinatorStatus.loading,
      pendingOperations: {...pendingOperations, operation},
      error: null,
      successMessage: null,
    );
  }

  SalesOrderCoordinatorState successState(String message, {String? operation}) {
    final updatedOperations = operation != null
        ? (Set<String>.from(pendingOperations)..remove(operation))
        : pendingOperations;

    return copyWith(
      status: SalesOrderCoordinatorStatus.success,
      successMessage: message,
      error: null,
      pendingOperations: updatedOperations,
    );
  }

  SalesOrderCoordinatorState errorState(String error, {String? operation}) {
    final updatedOperations = operation != null
        ? (Set<String>.from(pendingOperations)..remove(operation))
        : pendingOperations;

    return copyWith(
      status: SalesOrderCoordinatorStatus.error,
      error: error,
      successMessage: null,
      pendingOperations: updatedOperations,
    );
  }

  SalesOrderCoordinatorState operationComplete(String operation) {
    return copyWith(
      pendingOperations: {...pendingOperations}..remove(operation),
    );
  }

  SalesOrderCoordinatorState processingState(String operation) {
    return copyWith(
      status: SalesOrderCoordinatorStatus.processing,
      pendingOperations: {...pendingOperations, operation},
      error: null,
      lastOperation: operation,
    );
  }

  SalesOrderCoordinatorState paymentProcessingState() {
    return copyWith(
      status: SalesOrderCoordinatorStatus.paymentProcessing,
      pendingOperations: {...pendingOperations, 'process_payment'},
      error: null,
      lastOperation: 'Processing payment',
    );
  }

  bool get hasPendingOperations => pendingOperations.isNotEmpty;
  bool get canCreateOrder =>
      currentHeader != null && currentDetails.isNotEmpty && isStockValidated;
  bool get canUpdateOrder =>
      currentHeader?.id != null && currentDetails.isNotEmpty;
}
