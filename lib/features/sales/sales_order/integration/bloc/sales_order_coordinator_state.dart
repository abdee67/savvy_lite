import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/sales/customer/models/customer_model.dart';
import 'package:savvy_stock/features/sales/sales_order/header/model/sales_order_header.dart';
import 'package:savvy_stock/features/sales/sales_order/detail/model/sales_order_detail.dart';

enum SalesOrderCoordinatorStatus {
  initial,
  processing,
  success,
  error,
  synchronizing,
  calculating,
  creatingHeader,
  creatingDetails,
  voiding,
  reversingStock,
}

class SalesOrderTotals {
  final double totalAmount;
  final double totalTax;
  final double grandTotal;
  final double discountAmount;
  final double withholdingTax;

  const SalesOrderTotals({
    this.totalAmount = 0.0,
    this.totalTax = 0.0,
    this.grandTotal = 0.0,
    this.discountAmount = 0.0,
    this.withholdingTax = 0.0,
  });

  SalesOrderTotals copyWith({
    double? totalAmount,
    double? totalTax,
    double? grandTotal,
    double? discountAmount,
    double? withholdingTax,
  }) {
    return SalesOrderTotals(
      totalAmount: totalAmount ?? this.totalAmount,
      totalTax: totalTax ?? this.totalTax,
      grandTotal: grandTotal ?? this.grandTotal,
      discountAmount: discountAmount ?? this.discountAmount,
      withholdingTax: withholdingTax ?? this.withholdingTax,
    );
  }
}

class SalesOrderCoordinatorState extends Equatable {
  final SalesOrderCoordinatorStatus status;
  final String? lastOperation;
  final DateTime? lastCalculation;
  final String? error;
  final SalesOrderHeader? currentHeader;
  final List<SalesOrderDetail> currentDetails;
  final bool? lastApplyWH;
  final double? lastDiscountAmount;
  final List<SalesOrderDetail>? lastDetails;
  final Customer? currentCustomer;
  final SalesOrderTotals totals;
  final bool isOrderComplete;
  final DateTime? lastSyncTime;
  final bool isCalculatingTotals;
  final bool isUpdatingCustomer;
  final bool isUnitPriceUpdating;

  const SalesOrderCoordinatorState({
    this.status = SalesOrderCoordinatorStatus.initial,
    this.lastOperation,
    this.lastCalculation,
    this.error,
    this.currentHeader,
    this.currentDetails = const [],
    this.lastApplyWH,
    this.lastDiscountAmount,
    this.lastDetails,
    this.currentCustomer,
    this.totals = const SalesOrderTotals(),
    this.isOrderComplete = false,
    this.lastSyncTime,
    this.isCalculatingTotals = false,
    this.isUpdatingCustomer = false,
    this.isUnitPriceUpdating = false,
  });

  SalesOrderCoordinatorState copyWith({
    SalesOrderCoordinatorStatus? status,
    String? lastOperation,
    DateTime? lastCalculation,
    String? error,
    SalesOrderHeader? currentHeader,
    List<SalesOrderDetail>? currentDetails,
    bool? lastApplyWH,
    double? lastDiscountAmount,
    List<SalesOrderDetail>? lastDetails,
    Customer? currentCustomer,
    SalesOrderTotals? totals,
    bool? isOrderComplete,
    DateTime? lastSyncTime,
    bool? isCalculatingTotals,
    bool? isUpdatingCustomer,
    bool? isUnitPriceUpdating,
  }) {
    return SalesOrderCoordinatorState(
      status: status ?? this.status,
      lastOperation: lastOperation ?? this.lastOperation,
      lastCalculation: lastCalculation ?? this.lastCalculation,
      error: error ?? this.error,
      currentHeader: currentHeader ?? this.currentHeader,
      currentDetails: currentDetails ?? this.currentDetails,
      lastApplyWH: lastApplyWH ?? this.lastApplyWH,
      lastDiscountAmount: lastDiscountAmount ?? this.lastDiscountAmount,
      lastDetails: lastDetails ?? this.lastDetails,
      currentCustomer: currentCustomer ?? this.currentCustomer,
      totals: totals ?? this.totals,
      isOrderComplete: isOrderComplete ?? this.isOrderComplete,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      isCalculatingTotals: isCalculatingTotals ?? this.isCalculatingTotals,
      isUpdatingCustomer: isUpdatingCustomer ?? this.isUpdatingCustomer,
      isUnitPriceUpdating: isUnitPriceUpdating ?? this.isUnitPriceUpdating,
    );
  }

  bool get isProcessing => status == SalesOrderCoordinatorStatus.processing;
  bool get hasError => status == SalesOrderCoordinatorStatus.error;
  bool get hasCurrentOrder => currentHeader != null;
  bool get hasDetails => currentDetails.isNotEmpty;
  bool get canSubmitOrder => hasCurrentOrder && hasDetails && isOrderComplete;
  bool get isCreating =>
      status == SalesOrderCoordinatorStatus.creatingHeader ||
      status == SalesOrderCoordinatorStatus.creatingDetails;
  bool get isVoiding => status == SalesOrderCoordinatorStatus.voiding;
  bool get isReversingStock =>
      status == SalesOrderCoordinatorStatus.reversingStock;

  @override
  List<Object?> get props => [
    status,
    lastOperation,
    lastCalculation,
    error,
    currentHeader,
    currentDetails,
    lastApplyWH,
    lastDiscountAmount,
    lastDetails,
    currentCustomer,
    totals,
    isOrderComplete,
    lastSyncTime,
    isCalculatingTotals,
    isUpdatingCustomer,
    isUnitPriceUpdating,
  ];
}
