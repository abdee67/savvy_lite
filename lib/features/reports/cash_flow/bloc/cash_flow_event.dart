// bloc/sales_order_header_event.dart
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:savvy_stock/features/sales/sales_order/header/model/sales_transaction_filtering_model.dart';

@immutable
abstract class CashFlowEvent extends Equatable {
  const CashFlowEvent();
}

// ============================================================================
// Aged Credit Receipt Report Events
// ============================================================================
class LoadCashInFlowReport extends CashFlowEvent {
  final int companyId;
  final int page;
  final int pageSize;
  final SalesTransactionReportFilters filters;

  const LoadCashInFlowReport({
    required this.companyId,
    this.page = 1,
    this.pageSize = 25,
    this.filters = const SalesTransactionReportFilters(),
  });

  @override
  List<Object?> get props => [companyId, page, pageSize, filters];
}

class LoadMoreCashInFlowReport extends CashFlowEvent {
  const LoadMoreCashInFlowReport();

  @override
  List<Object?> get props => [];
}

class UpdateCashInFlowReportFilters extends CashFlowEvent {
  final SalesTransactionReportFilters filters;

  const UpdateCashInFlowReportFilters(this.filters);

  @override
  List<Object?> get props => [filters];
}

class ClearCashInFlowReportFilters extends CashFlowEvent {
  const ClearCashInFlowReportFilters();

  @override
  List<Object?> get props => [];
}

class ExportCashInFlowReportToExcel extends CashFlowEvent {
  final SalesTransactionReportFilters filters;

  const ExportCashInFlowReportToExcel(this.filters);

  @override
  List<Object?> get props => [filters];
}

class ExportCashInFlowReportToPDF extends CashFlowEvent {
  final SalesTransactionReportFilters filters;

  const ExportCashInFlowReportToPDF(this.filters);

  @override
  List<Object?> get props => [filters];
}

// ============================================================================
// Cash Out Flow Report Events
// ============================================================================
class LoadCashOutFlowReport extends CashFlowEvent {
  final int companyId;
  final int page;
  final int pageSize;
  final SalesTransactionReportFilters filters;

  const LoadCashOutFlowReport({
    required this.companyId,
    this.page = 1,
    this.pageSize = 25,
    this.filters = const SalesTransactionReportFilters(),
  });

  @override
  List<Object?> get props => [companyId, page, pageSize, filters];
}

class LoadMoreCashOutFlowReport extends CashFlowEvent {
  const LoadMoreCashOutFlowReport();

  @override
  List<Object?> get props => [];
}

class UpdateCashOutFlowReportFilters extends CashFlowEvent {
  final SalesTransactionReportFilters filters;

  const UpdateCashOutFlowReportFilters(this.filters);

  @override
  List<Object?> get props => [filters];
}

class ClearCashOutFlowReportFilters extends CashFlowEvent {
  const ClearCashOutFlowReportFilters();

  @override
  List<Object?> get props => [];
}

class ExportCashOutFlowReportToExcel extends CashFlowEvent {
  final SalesTransactionReportFilters filters;

  const ExportCashOutFlowReportToExcel(this.filters);

  @override
  List<Object?> get props => [filters];
}

class ExportCashOutFlowReportToPDF extends CashFlowEvent {
  final SalesTransactionReportFilters filters;

  const ExportCashOutFlowReportToPDF(this.filters);

  @override
  List<Object?> get props => [filters];
}

// ============================================================================
// Cash Flow Summary Report Events
// ============================================================================
class LoadCashFlowSummaryReport extends CashFlowEvent {
  final int companyId;
  final int page;
  final int pageSize;
  final SalesTransactionReportFilters filters;

  const LoadCashFlowSummaryReport({
    required this.companyId,
    this.page = 1,
    this.pageSize = 25,
    this.filters = const SalesTransactionReportFilters(),
  });

  @override
  List<Object?> get props => [companyId, page, pageSize, filters];
}

class LoadMoreCashFlowSummaryReport extends CashFlowEvent {
  const LoadMoreCashFlowSummaryReport();

  @override
  List<Object?> get props => [];
}

class UpdateCashFlowSummaryReportFilters extends CashFlowEvent {
  final SalesTransactionReportFilters filters;

  const UpdateCashFlowSummaryReportFilters(this.filters);

  @override
  List<Object?> get props => [filters];
}

class ClearCashFlowSummaryReportFilters extends CashFlowEvent {
  const ClearCashFlowSummaryReportFilters();

  @override
  List<Object?> get props => [];
}

class ExportCashFlowSummaryReportToExcel extends CashFlowEvent {
  final SalesTransactionReportFilters filters;

  const ExportCashFlowSummaryReportToExcel(this.filters);

  @override
  List<Object?> get props => [filters];
}

class ExportCashFlowSummaryReportToPDF extends CashFlowEvent {
  final SalesTransactionReportFilters filters;

  const ExportCashFlowSummaryReportToPDF(this.filters);

  @override
  List<Object?> get props => [filters];
}
