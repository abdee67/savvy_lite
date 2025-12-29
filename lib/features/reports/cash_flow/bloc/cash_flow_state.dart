// bloc/sales_order_header_state.dart

import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/reports/cash_flow/models/cash_inflow_totals.dart';
import 'package:savvy_stock/features/reports/cash_flow/models/cash_flow_transaction_DTO.dart';
import 'package:savvy_stock/features/reports/cash_flow/models/cash_out_flow_totals.dart';
import 'package:savvy_stock/features/reports/cash_flow/models/cash_flow_summary_totals.dart';
import 'package:savvy_stock/features/sales/sales_order/header/model/sales_transaction_filtering_model.dart';

enum CashFlowStatus {
  initial,
  loading,
  loaded,
  creating,
  updating,
  deleting,
  saving,
  processing,
  success,
  error,
  failure,
  calculating,

  // Cash In Flow Report
  loadingCashInFlowReport,
  filteringCashInFlowReport,
  loadedCashInFlowReport,
  loadingMoreCashInFlowReport,
  exportingCashInFlowReport,
  exportCashInFlowReportSuccess,
  exportAgedCreditPaymentReportFailure,

  // Cash Out Flow Report
  loadingCashOutFlowReport,
  filteringCashOutFlowReport,
  loadedCashOutFlowReport,
  loadingMoreCashOutFlowReport,
  exportingCashOutFlowReport,
  exportCashOutFlowReportSuccess,
  exportCashOutFlowReportFailure,

  // Cash Flow Summary Report
  loadingCashFlowSummaryReport,
  filteringCashFlowSummaryReport,
  loadedCashFlowSummaryReport,
  loadingMoreCashFlowSummaryReport,
  exportingCashFlowSummaryReport,
  exportCashFlowSummaryReportSuccess,
  exportCashFlowSummaryReportFailure,
}

class CashFlowState extends Equatable {
  final CashFlowStatus status;
  final String? successmessage;
  final String? error;
  // Aged Credit Receipt Report fields
  final List<CashflowTransactionReportDTO> cashInFlowReport;
  final SalesTransactionReportFilters cashInFlowReportFilters;
  final CashInFlowTotals? cashInFlowReportTotals;
  final int cashInFlowReportPage;
  final int cashInFlowReportPageSize;
  final int cashInFlowReportTotalCount;
  final int cashInFlowReportTotalPages;
  final bool hasMoreCashInFlowReport;
  final String? exportCashInFlowReportMessage;

  // Cash Out Flow Report fields
  final List<CashflowTransactionReportDTO> cashOutFlowReport;
  final SalesTransactionReportFilters cashOutFlowReportFilters;
  final CashOutFlowTotals? cashOutFlowReportTotals;
  final int cashOutFlowReportPage;
  final int cashOutFlowReportPageSize;
  final int cashOutFlowReportTotalCount;
  final int cashOutFlowReportTotalPages;
  final bool hasMoreCashOutFlowReport;
  final String? exportCashOutFlowReportMessage;

  // Cash Flow Summary Report fields
  final List<CashflowTransactionReportDTO> cashFlowSummaryReport;
  final SalesTransactionReportFilters cashFlowSummaryReportFilters;
  final CashFlowSummaryTotals? cashFlowSummaryReportTotals;
  final int cashFlowSummaryReportPage;
  final int cashFlowSummaryReportPageSize;
  final int cashFlowSummaryReportTotalCount;
  final int cashFlowSummaryReportTotalPages;
  final bool hasMoreCashFlowSummaryReport;
  final String? exportCashFlowSummaryReportMessage;

  const CashFlowState({
    this.status = CashFlowStatus.initial,
    this.successmessage,
    this.error,
    this.cashInFlowReport = const [],
    this.cashInFlowReportFilters = const SalesTransactionReportFilters(),
    this.cashInFlowReportTotals,
    this.cashInFlowReportPage = 1,
    this.cashInFlowReportPageSize = 20,
    this.cashInFlowReportTotalCount = 0,
    this.cashInFlowReportTotalPages = 1,
    this.hasMoreCashInFlowReport = false,
    this.exportCashInFlowReportMessage,
    this.cashOutFlowReport = const [],
    this.cashOutFlowReportFilters = const SalesTransactionReportFilters(),
    this.cashOutFlowReportTotals,
    this.cashOutFlowReportPage = 1,
    this.cashOutFlowReportPageSize = 20,
    this.cashOutFlowReportTotalCount = 0,
    this.cashOutFlowReportTotalPages = 1,
    this.hasMoreCashOutFlowReport = false,
    this.exportCashOutFlowReportMessage,
    this.cashFlowSummaryReport = const [],
    this.cashFlowSummaryReportFilters = const SalesTransactionReportFilters(),
    this.cashFlowSummaryReportTotals,
    this.cashFlowSummaryReportPage = 1,
    this.cashFlowSummaryReportPageSize = 20,
    this.cashFlowSummaryReportTotalCount = 0,
    this.cashFlowSummaryReportTotalPages = 1,
    this.hasMoreCashFlowSummaryReport = false,
    this.exportCashFlowSummaryReportMessage,
  });

  // Status check methods
  bool isLoading() => status == CashFlowStatus.loading;
  bool isProcessing() => status == CashFlowStatus.processing;
  bool isSaving() => status == CashFlowStatus.saving;
  bool isSuccess() => status == CashFlowStatus.success;
  bool isError() => status == CashFlowStatus.error;
  bool isFailure() => status == CashFlowStatus.failure;
  bool isDeleting() => status == CashFlowStatus.deleting;
  bool isLoaded() => status == CashFlowStatus.loaded;
  bool isInitial() => status == CashFlowStatus.initial;
  bool isCreating() => status == CashFlowStatus.creating;
  bool isUpdating() => status == CashFlowStatus.updating;
  bool isCalculating() => status == CashFlowStatus.calculating;

  CashFlowState copyWith({
    CashFlowStatus? status,
    String? successmessage,
    String? error,
    SalesTransactionReportFilters? cashInFlowReportFilters,
    List<CashflowTransactionReportDTO>? cashInFlowReport,
    CashInFlowTotals? cashInFlowReportTotals,
    int? cashInFlowReportPage,
    int? cashInFlowReportPageSize,
    int? cashInFlowReportTotalCount,
    int? cashInFlowReportTotalPages,
    bool? hasMoreCashInFlowReport,
    String? exportCashInFlowReportMessage,

    // Cash Out Flow Report fields
    SalesTransactionReportFilters? cashOutFlowReportFilters,
    List<CashflowTransactionReportDTO>? cashOutFlowReport,
    CashOutFlowTotals? cashOutFlowReportTotals,
    int? cashOutFlowReportPage,
    int? cashOutFlowReportPageSize,
    int? cashOutFlowReportTotalCount,
    int? cashOutFlowReportTotalPages,
    bool? hasMoreCashOutFlowReport,
    String? exportCashOutFlowReportMessage,

    // Cash Flow Summary Report fields
    SalesTransactionReportFilters? cashFlowSummaryReportFilters,
    List<CashflowTransactionReportDTO>? cashFlowSummaryReport,
    CashFlowSummaryTotals? cashFlowSummaryReportTotals,
    int? cashFlowSummaryReportPage,
    int? cashFlowSummaryReportPageSize,
    int? cashFlowSummaryReportTotalCount,
    int? cashFlowSummaryReportTotalPages,
    bool? hasMoreCashFlowSummaryReport,
    String? exportCashFlowSummaryReportMessage,
  }) {
    return CashFlowState(
      status: status ?? this.status,

      cashInFlowReport: cashInFlowReport ?? this.cashInFlowReport,
      cashInFlowReportFilters:
          cashInFlowReportFilters ?? this.cashInFlowReportFilters,
      cashInFlowReportTotals:
          cashInFlowReportTotals ?? this.cashInFlowReportTotals,
      cashInFlowReportPage: cashInFlowReportPage ?? this.cashInFlowReportPage,
      cashInFlowReportPageSize:
          cashInFlowReportPageSize ?? this.cashInFlowReportPageSize,
      cashInFlowReportTotalCount:
          cashInFlowReportTotalCount ?? this.cashInFlowReportTotalCount,
      cashInFlowReportTotalPages:
          cashInFlowReportTotalPages ?? this.cashInFlowReportTotalPages,
      hasMoreCashInFlowReport:
          hasMoreCashInFlowReport ?? this.hasMoreCashInFlowReport,
      exportCashInFlowReportMessage:
          exportCashInFlowReportMessage ?? this.exportCashInFlowReportMessage,

      // Cash Out Flow Report fields
      cashOutFlowReportFilters:
          cashOutFlowReportFilters ?? this.cashOutFlowReportFilters,
      cashOutFlowReport: cashOutFlowReport ?? this.cashOutFlowReport,
      cashOutFlowReportTotals:
          cashOutFlowReportTotals ?? this.cashOutFlowReportTotals,
      cashOutFlowReportPage:
          cashOutFlowReportPage ?? this.cashOutFlowReportPage,
      cashOutFlowReportPageSize:
          cashOutFlowReportPageSize ?? this.cashOutFlowReportPageSize,
      cashOutFlowReportTotalCount:
          cashOutFlowReportTotalCount ?? this.cashOutFlowReportTotalCount,
      cashOutFlowReportTotalPages:
          cashOutFlowReportTotalPages ?? this.cashOutFlowReportTotalPages,
      hasMoreCashOutFlowReport:
          hasMoreCashOutFlowReport ?? this.hasMoreCashOutFlowReport,
      exportCashOutFlowReportMessage:
          exportCashOutFlowReportMessage ?? this.exportCashOutFlowReportMessage,

      // Cash Flow Summary Report fields
      cashFlowSummaryReportFilters:
          cashFlowSummaryReportFilters ?? this.cashFlowSummaryReportFilters,
      cashFlowSummaryReport:
          cashFlowSummaryReport ?? this.cashFlowSummaryReport,
      cashFlowSummaryReportTotals:
          cashFlowSummaryReportTotals ?? this.cashFlowSummaryReportTotals,
      cashFlowSummaryReportPage:
          cashFlowSummaryReportPage ?? this.cashFlowSummaryReportPage,
      cashFlowSummaryReportPageSize:
          cashFlowSummaryReportPageSize ?? this.cashFlowSummaryReportPageSize,
      cashFlowSummaryReportTotalCount:
          cashFlowSummaryReportTotalCount ??
          this.cashFlowSummaryReportTotalCount,
      cashFlowSummaryReportTotalPages:
          cashFlowSummaryReportTotalPages ??
          this.cashFlowSummaryReportTotalPages,
      hasMoreCashFlowSummaryReport:
          hasMoreCashFlowSummaryReport ?? this.hasMoreCashFlowSummaryReport,
      exportCashFlowSummaryReportMessage:
          exportCashFlowSummaryReportMessage ??
          this.exportCashFlowSummaryReportMessage,
    );
  }

  // Helper methods for common state transitions
  CashFlowState loadingState() => copyWith(
    status: CashFlowStatus.loading,
    error: null,
    successmessage: null,
  );

  CashFlowState loadingMoreState() => copyWith(
    status: CashFlowStatus.loadingMoreCashInFlowReport,
    error: null,
    successmessage: null,
  );

  CashFlowState successState(String message) => copyWith(
    status: CashFlowStatus.success,
    successmessage: message,
    error: null,
  );

  CashFlowState errorState(String errorMessage) => copyWith(
    status: CashFlowStatus.error,
    error: errorMessage,
    successmessage: null,
  );

  CashFlowState processingState() => copyWith(
    status: CashFlowStatus.processing,
    error: null,
    successmessage: null,
  );

  CashFlowState calculatingState() => copyWith(
    status: CashFlowStatus.calculating,
    error: null,
    successmessage: null,
  );

  CashFlowState clearMessages() => copyWith(error: null, successmessage: null);

  @override
  List<Object?> get props => [
    status,
    successmessage,
    error,
    cashInFlowReport,
    cashInFlowReportFilters,
    cashInFlowReportTotals,
    cashInFlowReportPage,
    cashInFlowReportPageSize,
    cashInFlowReportTotalCount,
    cashInFlowReportTotalPages,
    hasMoreCashInFlowReport,
    exportCashInFlowReportMessage,
    cashOutFlowReport,
    cashOutFlowReportFilters,
    cashOutFlowReportTotals,
    cashOutFlowReportPage,
    cashOutFlowReportPageSize,
    cashOutFlowReportTotalCount,
    cashOutFlowReportTotalPages,
    hasMoreCashOutFlowReport,
    exportCashOutFlowReportMessage,
    cashFlowSummaryReport,
    cashFlowSummaryReportFilters,
    cashFlowSummaryReportTotals,
    cashFlowSummaryReportPage,
    cashFlowSummaryReportPageSize,
    cashFlowSummaryReportTotalCount,
    cashFlowSummaryReportTotalPages,
    hasMoreCashFlowSummaryReport,
    exportCashFlowSummaryReportMessage,
  ];
}
