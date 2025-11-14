// features/sales/sales_order/coordinator/bloc/sales_order_coordinator_state.dart
import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/sales/sales_order/header/model/sales_order_header.dart';
import 'package:savvy_stock/features/sales/sales_order/detail/model/sales_order_detail.dart';

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
}

class SalesOrderCoordinatorState extends Equatable {
  final SalesOrderCoordinatorStatus status;
  final SalesOrderHeader? currentHeader;
  final List<SalesOrderDetail> currentDetails;
  final List<SalesOrderDetail> lastSavedDetails;
  final String? error;
  final String? successMessage;
  final DateTime? lastSyncTime;
  final String? lastOperation;
  final DateTime? lastCalculationTime;
  final bool isOrderComplete;
  final bool isStockValidated;
  final bool isCalculationsComplete;
  final Map<int, StockValidationResult> stockValidationResults;
  final double? lastSubTotal;
  final double? lastTax;
  final double? lastWithholdAmount;
  final double? lastDiscountAmount;
  final double? lastTotalAmount;
  final Set<String> pendingOperations;

  const SalesOrderCoordinatorState({
    this.status = SalesOrderCoordinatorStatus.initial,
    this.currentHeader,
    this.currentDetails = const [],
    this.lastSavedDetails = const [],
    this.error,
    this.successMessage,
    this.lastSyncTime,
    this.lastOperation,
    this.lastCalculationTime,
    this.isOrderComplete = false,
    this.isStockValidated = false,
    this.isCalculationsComplete = false,
    this.stockValidationResults = const {},
    this.lastSubTotal,
    this.lastTax,
    this.lastWithholdAmount,
    this.lastDiscountAmount,
    this.lastTotalAmount,
    this.pendingOperations = const {},
  });

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
    Map<int, StockValidationResult>? stockValidationResults,
    double? lastSubTotal,
    double? lastTax,
    double? lastWithholdAmount,
    double? lastDiscountAmount,
    double? lastTotalAmount,
    Set<String>? pendingOperations,
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

  bool get hasPendingOperations => pendingOperations.isNotEmpty;
  bool get canCreateOrder =>
      currentHeader != null && currentDetails.isNotEmpty && isStockValidated;
  bool get canUpdateOrder =>
      currentHeader?.id != null && currentDetails.isNotEmpty;
}
