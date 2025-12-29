// bloc/cash_flow_bloc.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:savvy_stock/features/reports/cash_flow/bloc/cash_flow_event.dart';
import 'package:savvy_stock/features/reports/cash_flow/bloc/cash_flow_state.dart';
import 'package:savvy_stock/features/reports/cash_flow/models/cash_inflow_totals.dart';
import 'package:savvy_stock/features/reports/cash_flow/models/cash_out_flow_totals.dart';
import 'package:savvy_stock/features/reports/cash_flow/repo/cash_flow_repo.dart';
import 'package:savvy_stock/features/sales/sales_order/header/model/sales_transaction_filtering_model.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/reports/cash_flow/models/cash_flow_transaction_DTO.dart';

class CashFlowBloc extends Bloc<CashFlowEvent, CashFlowState> {
  final AuthBloc authBloc;
  final CashFlowRepository cashFlowRepository;

  StreamSubscription? _authSubscription;

  CashFlowBloc({required this.authBloc, required this.cashFlowRepository})
    : super(const CashFlowState()) {
    // Listen to authentication state
    _authSubscription = authBloc.stream.listen((authState) {
      if (authState.isAuthenticated &&
          authState.companyId != null &&
          authState.userId != null) {}
    });

    on<LoadCashInFlowReport>(_onLoadCashInFlowReport);
    on<LoadMoreCashInFlowReport>(_onLoadMoreCashInFlowReport);
    on<UpdateCashInFlowReportFilters>(_onUpdateCashInFlowFilters);
    on<ClearCashInFlowReportFilters>(_onClearCashInFlowFilters);
    on<ExportCashInFlowReportToExcel>(_onExportCashInFlowToExcel);
    on<ExportCashInFlowReportToPDF>(_onExportCashInFlowToPDF);

    on<LoadCashOutFlowReport>(_onLoadCashOutFlowReport);
    on<LoadMoreCashOutFlowReport>(_onLoadMoreCashOutFlowReport);
    on<UpdateCashOutFlowReportFilters>(_onUpdateCashOutFlowFilters);
    on<ClearCashOutFlowReportFilters>(_onClearCashOutFlowFilters);
    on<ExportCashOutFlowReportToExcel>(_onExportCashOutFlowToExcel);
    on<ExportCashOutFlowReportToPDF>(_onExportCashOutFlowToPDF);

    on<LoadCashFlowSummaryReport>(_onLoadCashFlowSummaryReport);
    on<LoadMoreCashFlowSummaryReport>(_onLoadMoreCashFlowSummaryReport);
    on<UpdateCashFlowSummaryReportFilters>(_onUpdateCashFlowSummaryFilters);
    on<ClearCashFlowSummaryReportFilters>(_onClearCashFlowSummaryFilters);
    on<ExportCashFlowSummaryReportToExcel>(_onExportCashFlowSummaryToExcel);
    on<ExportCashFlowSummaryReportToPDF>(_onExportCashFlowSummaryToPDF);
  }
  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }

  // ============================================================================
  // EVENT HANDLERS
  // ============================================================================

  Future<void> _onLoadCashInFlowReport(
    LoadCashInFlowReport event,
    Emitter<CashFlowState> emit,
  ) async {
    try {
      emit(state.copyWith(status: CashFlowStatus.loadingCashInFlowReport));

      // Fetch paginated data based on filter view type
      final result = await cashFlowRepository.getCashInflowTransactions(
        companyId: event.companyId,
        page: event.page,
        pageSize: event.pageSize,
        startDate: event.filters.dateFrom,
        endDate: event.filters.dateTo,
        salesType: event.filters.salesType,
      );

      // Calculate totals
      final totalsResult = await cashFlowRepository.calculateCashInFlowTotals(
        companyId: event.companyId,
        startDate: event.filters.dateFrom,
        endDate: event.filters.dateTo,
        salesType: event.filters.salesType, // Added salesType
      );

      final totals = CashInFlowTotals(
        totalDebit: totalsResult['totalDebit'] as double,
        totalCount: totalsResult['totalCount'] as int,
        currentPage: result['currentPage'] as int,
        totalPages: result['totalPages'] as int,
      );

      emit(
        state.copyWith(
          status: CashFlowStatus.loadedCashInFlowReport,
          cashInFlowReport:
              result['items']
                  as List<
                    CashflowTransactionReportDTO
                  >, // Note: State expects List<SalesOrderHeader>, need to verify State definition
          cashInFlowReportFilters: event.filters,
          cashInFlowReportTotals: totals,
          cashInFlowReportPage: result['currentPage'] as int,
          cashInFlowReportPageSize: event.pageSize,
          cashInFlowReportTotalCount: result['totalCount'] as int,
          cashInFlowReportTotalPages: result['totalPages'] as int,
          hasMoreCashInFlowReport:
              (result['currentPage'] as int) < (result['totalPages'] as int),
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to load cash inflow report: $e'));
    }
  }

  Future<void> _onLoadMoreCashInFlowReport(
    LoadMoreCashInFlowReport event,
    Emitter<CashFlowState> emit,
  ) async {
    if (!state.hasMoreCashInFlowReport) return;

    try {
      emit(state.copyWith(status: CashFlowStatus.loadingMoreCashInFlowReport));
      final nextPage = state.cashInFlowReportPage + 1;
      final filters = state.cashInFlowReportFilters;

      // Fetch next page
      final result = await cashFlowRepository.getCashInflowTransactions(
        companyId: authBloc.state.companyId!,
        page: nextPage,
        pageSize: state.cashInFlowReportPageSize,
        startDate: filters.dateFrom,
        endDate: filters.dateTo,
        salesType: filters.salesType,
      );

      emit(
        state.copyWith(
          status: CashFlowStatus.loadedCashInFlowReport,
          cashInFlowReport: [
            ...state.cashInFlowReport,
            ...(result['items'] as List<CashflowTransactionReportDTO>),
          ],
          cashInFlowReportPage: result['currentPage'] as int,
          hasMoreCashInFlowReport:
              (result['currentPage'] as int) < (result['totalPages'] as int),
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to load more cash inflow receipts: $e'));
    }
  }

  Future<void> _onUpdateCashInFlowFilters(
    UpdateCashInFlowReportFilters event,
    Emitter<CashFlowState> emit,
  ) async {
    // Reload data with new filters
    add(
      LoadCashInFlowReport(
        companyId: authBloc.state.companyId!,
        page: 1,
        pageSize: state.cashInFlowReportPageSize,
        filters: event.filters,
      ),
    );
  }

  void _onClearCashInFlowFilters(
    ClearCashInFlowReportFilters event,
    Emitter<CashFlowState> emit,
  ) {
    // Reload with empty filters
    add(
      LoadCashInFlowReport(
        companyId: authBloc.state.companyId!,
        page: 1,
        pageSize: state.cashInFlowReportPageSize,
        filters: const SalesTransactionReportFilters(),
      ),
    );
  }

  Future<void> _onExportCashInFlowToExcel(
    ExportCashInFlowReportToExcel event,
    Emitter<CashFlowState> emit,
  ) async {
    try {
      emit(state.copyWith(status: CashFlowStatus.exportingCashInFlowReport));
      emit(
        state.copyWith(
          status: CashFlowStatus.loadedCashInFlowReport,
          exportCashInFlowReportMessage:
              'Excel export functionality coming soon',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: CashFlowStatus.loadedCashInFlowReport,
          exportCashInFlowReportMessage: 'Failed to export to Excel: $e',
        ),
      );
    }
  }

  Future<void> _onExportCashInFlowToPDF(
    ExportCashInFlowReportToPDF event,
    Emitter<CashFlowState> emit,
  ) async {
    try {
      emit(state.copyWith(status: CashFlowStatus.exportingCashInFlowReport));
      emit(
        state.copyWith(
          status: CashFlowStatus.loadedCashInFlowReport,
          exportCashInFlowReportMessage: 'PDF export functionality coming soon',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: CashFlowStatus.loadedCashInFlowReport,
          exportCashInFlowReportMessage: 'Failed to export to PDF: $e',
        ),
      );
    }
  }

  //===========CASH OUT FLOW REPORT===========

  Future<void> _onLoadCashOutFlowReport(
    LoadCashOutFlowReport event,
    Emitter<CashFlowState> emit,
  ) async {
    try {
      emit(state.copyWith(status: CashFlowStatus.loadingCashOutFlowReport));

      // Fetch paginated data based on filter view type
      final result = await cashFlowRepository.getCashOutflowTransactions(
        companyId: event.companyId,
        page: event.page,
        pageSize: event.pageSize,
        startDate: event.filters.dateFrom,
        endDate: event.filters.dateTo,
        purchaseType: event.filters.salesType,
      );

      // Calculate totals
      final totalsResult = await cashFlowRepository.calculateCashOutFlowTotals(
        companyId: event.companyId,
        startDate: event.filters.dateFrom,
        endDate: event.filters.dateTo,
        purchaseType: event.filters.salesType,
      );

      final totals = CashOutFlowTotals(
        totalCredit: totalsResult['totalCredit'] as double,
        totalCount: totalsResult['totalCount'] as int,
        currentPage: result['currentPage'] as int,
        totalPages: result['totalPages'] as int,
      );

      emit(
        state.copyWith(
          status: CashFlowStatus.loadedCashOutFlowReport,
          cashOutFlowReport:
              result['items'] as List<CashflowTransactionReportDTO>,
          cashOutFlowReportFilters: event.filters,
          cashOutFlowReportTotals: totals,
          cashOutFlowReportPage: result['currentPage'] as int,
          cashOutFlowReportPageSize: event.pageSize,
          cashOutFlowReportTotalCount: result['totalCount'] as int,
          cashOutFlowReportTotalPages: result['totalPages'] as int,
          hasMoreCashOutFlowReport:
              (result['currentPage'] as int) < (result['totalPages'] as int),
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to load cash out flow report: $e'));
    }
  }

  Future<void> _onLoadMoreCashOutFlowReport(
    LoadMoreCashOutFlowReport event,
    Emitter<CashFlowState> emit,
  ) async {
    if (!state.hasMoreCashOutFlowReport) return;

    try {
      emit(state.copyWith(status: CashFlowStatus.loadingMoreCashOutFlowReport));
      final nextPage = state.cashOutFlowReportPage + 1;
      final filters = state.cashOutFlowReportFilters;

      // Fetch next page
      final result = await cashFlowRepository.getCashOutflowTransactions(
        companyId: authBloc.state.companyId!,
        page: nextPage,
        pageSize: state.cashOutFlowReportPageSize,
        startDate: filters.dateFrom,
        endDate: filters.dateTo,
        purchaseType: filters.salesType,
      );

      emit(
        state.copyWith(
          status: CashFlowStatus.loadedCashOutFlowReport,
          cashOutFlowReport: [
            ...state.cashOutFlowReport,
            ...(result['items'] as List<CashflowTransactionReportDTO>),
          ],
          cashOutFlowReportPage: result['currentPage'] as int,
          hasMoreCashOutFlowReport:
              (result['currentPage'] as int) < (result['totalPages'] as int),
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to load more cash out flow receipts: $e'));
    }
  }

  Future<void> _onUpdateCashOutFlowFilters(
    UpdateCashOutFlowReportFilters event,
    Emitter<CashFlowState> emit,
  ) async {
    // Reload data with new filters
    add(
      LoadCashOutFlowReport(
        companyId: authBloc.state.companyId!,
        page: 1,
        pageSize: state.cashOutFlowReportPageSize,
        filters: event.filters,
      ),
    );
  }

  void _onClearCashOutFlowFilters(
    ClearCashOutFlowReportFilters event,
    Emitter<CashFlowState> emit,
  ) {
    // Reload with empty filters
    add(
      LoadCashOutFlowReport(
        companyId: authBloc.state.companyId!,
        page: 1,
        pageSize: state.cashOutFlowReportPageSize,
        filters: const SalesTransactionReportFilters(),
      ),
    );
  }

  Future<void> _onExportCashOutFlowToExcel(
    ExportCashOutFlowReportToExcel event,
    Emitter<CashFlowState> emit,
  ) async {
    try {
      emit(state.copyWith(status: CashFlowStatus.exportingCashOutFlowReport));
      emit(
        state.copyWith(
          status: CashFlowStatus.loadedCashOutFlowReport,
          exportCashOutFlowReportMessage:
              'Excel export functionality coming soon',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: CashFlowStatus.loadedCashOutFlowReport,
          exportCashOutFlowReportMessage: 'Failed to export to Excel: $e',
        ),
      );
    }
  }

  Future<void> _onExportCashOutFlowToPDF(
    ExportCashOutFlowReportToPDF event,
    Emitter<CashFlowState> emit,
  ) async {
    try {
      emit(state.copyWith(status: CashFlowStatus.exportingCashOutFlowReport));
      emit(
        state.copyWith(
          status: CashFlowStatus.loadedCashOutFlowReport,
          exportCashOutFlowReportMessage:
              'PDF export functionality coming soon',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: CashFlowStatus.loadedCashOutFlowReport,
          exportCashOutFlowReportMessage: 'Failed to export to PDF: $e',
        ),
      );
    }
  }
  //===========CASH FLOW SUMMARY REPORT===========

  Future<void> _onLoadCashFlowSummaryReport(
    LoadCashFlowSummaryReport event,
    Emitter<CashFlowState> emit,
  ) async {
    try {
      emit(state.copyWith(status: CashFlowStatus.loadingCashFlowSummaryReport));

      // Fetch paginated data
      final result = await cashFlowRepository.getCashFlowSummaryTransactions(
        companyId: event.companyId,
        page: event.page,
        pageSize: event.pageSize,
        startDate: event.filters.dateFrom,
        endDate: event.filters.dateTo,
        status: event.filters.salesType,
      );

      // Calculate totals
      final totals = await cashFlowRepository.calculateCashFlowSummaryTotals(
        companyId: event.companyId,
        startDate: event.filters.dateFrom,
        endDate: event.filters.dateTo,
        status: event.filters.salesType,
      );

      emit(
        state.copyWith(
          status: CashFlowStatus.loadedCashFlowSummaryReport,
          cashFlowSummaryReport:
              result['items'] as List<CashflowTransactionReportDTO>,
          cashFlowSummaryReportFilters: event.filters,
          cashFlowSummaryReportTotals: totals,
          cashFlowSummaryReportPage: result['currentPage'] as int,
          cashFlowSummaryReportPageSize: event.pageSize,
          cashFlowSummaryReportTotalCount: result['totalCount'] as int,
          cashFlowSummaryReportTotalPages: result['totalPages'] as int,
          hasMoreCashFlowSummaryReport:
              (result['currentPage'] as int) < (result['totalPages'] as int),
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to load cash flow summary report: $e'));
    }
  }

  Future<void> _onLoadMoreCashFlowSummaryReport(
    LoadMoreCashFlowSummaryReport event,
    Emitter<CashFlowState> emit,
  ) async {
    if (!state.hasMoreCashFlowSummaryReport) return;

    try {
      emit(
        state.copyWith(status: CashFlowStatus.loadingMoreCashFlowSummaryReport),
      );
      final nextPage = state.cashFlowSummaryReportPage + 1;
      final filters = state.cashFlowSummaryReportFilters;

      // Fetch next page
      final result = await cashFlowRepository.getCashFlowSummaryTransactions(
        companyId: authBloc.state.companyId!,
        page: nextPage,
        pageSize: state.cashFlowSummaryReportPageSize,
        startDate: filters.dateFrom,
        endDate: filters.dateTo,
        status: filters.salesType,
      );

      emit(
        state.copyWith(
          status: CashFlowStatus.loadedCashFlowSummaryReport,
          cashFlowSummaryReport: [
            ...state.cashFlowSummaryReport,
            ...(result['items'] as List<CashflowTransactionReportDTO>),
          ],
          cashFlowSummaryReportPage: result['currentPage'] as int,
          hasMoreCashFlowSummaryReport:
              (result['currentPage'] as int) < (result['totalPages'] as int),
        ),
      );
    } catch (e) {
      emit(
        state.errorState('Failed to load more cash flow summary records: $e'),
      );
    }
  }

  Future<void> _onUpdateCashFlowSummaryFilters(
    UpdateCashFlowSummaryReportFilters event,
    Emitter<CashFlowState> emit,
  ) async {
    // Reload data with new filters
    add(
      LoadCashFlowSummaryReport(
        companyId: authBloc.state.companyId!,
        page: 1,
        pageSize: state.cashFlowSummaryReportPageSize,
        filters: event.filters,
      ),
    );
  }

  void _onClearCashFlowSummaryFilters(
    ClearCashFlowSummaryReportFilters event,
    Emitter<CashFlowState> emit,
  ) {
    // Reload with empty filters
    add(
      LoadCashFlowSummaryReport(
        companyId: authBloc.state.companyId!,
        page: 1,
        pageSize: state.cashFlowSummaryReportPageSize,
        filters: const SalesTransactionReportFilters(),
      ),
    );
  }

  Future<void> _onExportCashFlowSummaryToExcel(
    ExportCashFlowSummaryReportToExcel event,
    Emitter<CashFlowState> emit,
  ) async {
    try {
      emit(
        state.copyWith(status: CashFlowStatus.exportingCashFlowSummaryReport),
      );
      emit(
        state.copyWith(
          status: CashFlowStatus.loadedCashFlowSummaryReport,
          exportCashFlowSummaryReportMessage:
              'Excel export functionality coming soon',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: CashFlowStatus.loadedCashFlowSummaryReport,
          exportCashFlowSummaryReportMessage: 'Failed to export to Excel: $e',
        ),
      );
    }
  }

  Future<void> _onExportCashFlowSummaryToPDF(
    ExportCashFlowSummaryReportToPDF event,
    Emitter<CashFlowState> emit,
  ) async {
    try {
      emit(
        state.copyWith(status: CashFlowStatus.exportingCashFlowSummaryReport),
      );
      emit(
        state.copyWith(
          status: CashFlowStatus.loadedCashFlowSummaryReport,
          exportCashFlowSummaryReportMessage:
              'PDF export functionality coming soon',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: CashFlowStatus.loadedCashFlowSummaryReport,
          exportCashFlowSummaryReportMessage: 'Failed to export to PDF: $e',
        ),
      );
    }
  }
}
