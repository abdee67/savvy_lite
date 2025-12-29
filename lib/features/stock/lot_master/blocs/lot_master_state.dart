// features/stock/lot_master/blocs/lot_master_state.dart

import 'package:savvy_stock/features/stock/lot_master/models/expiration_report_filters.dart';
import 'package:savvy_stock/features/stock/lot_master/models/lot_master_model.dart';

enum LotMasterStatus {
  initial,
  loading,
  loaded,
  creating,
  updating,
  deleting,
  filtering,
  searching,
  success,
  failure,
  dateValidationFailed,
  duplicationFound,
  exporting,
  loadingExpirationReport,
  loadedExpirationReport,
  loadingMoreExpirationReport,
  exportingReport,
  exportReportSuccess,
  loadingUpcomingExpiryReport,
  loadedUpcomingExpiryReport,
  loadingMoreUpcomingExpiryReport,
}

class LotMasterState {
  final LotMasterStatus status;
  final List<LotMaster> items;
  final List<LotMaster> filteredItems;
  final List<LotMaster> createItems;
  final List<LotMaster> editItems;
  final List<LotMaster> selectedItems;
  final LotMaster? selected;
  final LotMaster? selected2;
  final String message;
  final int? companyId;
  final String searchQuery;

  // Filter fields
  final int? filterItemId;
  final DateTime? filterExpStart;
  final DateTime? filterExpEnd;
  final int? filterLocationId;
  final int? filterStatusId;

  // Additional state
  final Map<int, double>? quantitySummary;
  final List<LotMaster>? expiringLots;
  final bool? datesValid;
  final bool? hasDuplication;

  // Expiration report fields
  final List<LotMaster> expirationReportLots;
  final ExpirationReportFilters expirationReportFilters;
  final int expirationReportPage;
  final int expirationReportTotalPages;
  final int expirationReportTotalCount;
  final double expirationReportTotalCost;
  final bool hasMoreExpirationReport;
  final String exportReportMessage;

  // Upcoming Expiry Report fields
  final List<LotMaster> upcomingExpiryLots;
  final ExpirationReportFilters upcomingExpiryFilters;
  final int upcomingExpiryPage;
  final int upcomingExpiryTotalPages;
  final int upcomingExpiryTotalCount;
  final double upcomingExpiryTotalCost;
  final bool hasMoreUpcomingExpiry;
  final int upcomingExpiryDaysThreshold;

  const LotMasterState({
    this.status = LotMasterStatus.initial,
    this.items = const [],
    this.filteredItems = const [],
    this.searchQuery = '',
    this.createItems = const [],
    this.editItems = const [],
    this.selectedItems = const [],
    this.quantitySummary,
    this.expiringLots,
    this.datesValid,
    this.hasDuplication,
    this.selected,
    this.selected2,
    this.message = '',
    this.companyId = 0,
    this.filterItemId,
    this.filterExpStart,
    this.filterExpEnd,
    this.filterLocationId,
    this.filterStatusId,

    // Expiration report fields
    this.expirationReportLots = const [],
    this.expirationReportFilters = const ExpirationReportFilters(),
    this.expirationReportPage = 1,
    this.expirationReportTotalPages = 0,
    this.expirationReportTotalCount = 0,
    this.expirationReportTotalCost = 0.0,
    this.hasMoreExpirationReport = false,
    this.exportReportMessage = '',

    // Upcoming Expiry Report fields
    this.upcomingExpiryLots = const [],
    this.upcomingExpiryFilters = const ExpirationReportFilters(),
    this.upcomingExpiryPage = 1,
    this.upcomingExpiryTotalPages = 0,
    this.upcomingExpiryTotalCount = 0,
    this.upcomingExpiryTotalCost = 0.0,
    this.hasMoreUpcomingExpiry = false,
    this.upcomingExpiryDaysThreshold = 30,
  });

  bool get isLoading => status == LotMasterStatus.loading;
  bool get isSuccess => status == LotMasterStatus.success;
  bool get isFailure => status == LotMasterStatus.failure;
  bool get isCreating => status == LotMasterStatus.creating;
  bool get isUpdating => status == LotMasterStatus.updating;
  bool get isDeleting => status == LotMasterStatus.deleting;
  bool get isFiltering => status == LotMasterStatus.filtering;
  bool get isSearching => status == LotMasterStatus.searching;

  bool get hasItems => items.isNotEmpty;
  bool get hasFilteredItems => filteredItems.isNotEmpty;
  bool get hasSelection => selectedItems.isNotEmpty;
  bool get canEdit => selectedItems.length == 1;
  bool get canDelete => selectedItems.isNotEmpty;
  bool get canExport => filteredItems.isNotEmpty;
  bool get hasNextPage => expirationReportPage < expirationReportTotalPages;
  bool get hasPreviousPage => expirationReportPage > 1;

  // --- CopyWith for immutability ---
  LotMasterState copyWith({
    LotMasterStatus? status,
    List<LotMaster>? items,
    List<LotMaster>? filteredItems,
    String? searchQuery,
    List<LotMaster>? createItems,
    List<LotMaster>? editItems,
    List<LotMaster>? selectedItems,
    LotMaster? selected,
    LotMaster? selected2,
    String? message,
    String? error,
    int? companyId,
    Map<int, double>? quantitySummary,
    List<LotMaster>? expiringLots,
    bool? datesValid,
    bool? hasDuplication,

    int? filterItemId,
    DateTime? filterExpStart,
    DateTime? filterExpEnd,
    int? filterLocationId,
    int? filterStatusId,

    //Expired report
    List<LotMaster>? expirationReportLots,
    ExpirationReportFilters? expirationReportFilters,
    int? expirationReportPage,
    int? expirationReportTotalPages,
    int? expirationReportTotalCount,
    double? expirationReportTotalCost,
    bool? hasMoreExpirationReport,
    String? exportReportMessage,

    // Upcoming Expiry Report specific
    List<LotMaster>? upcomingExpiryLots,
    ExpirationReportFilters? upcomingExpiryFilters,
    int? upcomingExpiryPage,
    int? upcomingExpiryTotalPages,
    int? upcomingExpiryTotalCount,
    double? upcomingExpiryTotalCost,
    bool? hasMoreUpcomingExpiry,
    int? upcomingExpiryDaysThreshold,
  }) {
    return LotMasterState(
      status: status ?? this.status,
      items: items ?? this.items,
      filteredItems: filteredItems ?? this.filteredItems,
      searchQuery: searchQuery ?? this.searchQuery,
      createItems: createItems ?? this.createItems,
      editItems: editItems ?? this.editItems,
      selectedItems: selectedItems ?? this.selectedItems,
      selected: selected ?? this.selected,
      selected2: selected2 ?? this.selected2,
      message: message ?? this.message,
      companyId: companyId ?? this.companyId,
      filterItemId: filterItemId ?? this.filterItemId,
      filterExpStart: filterExpStart ?? this.filterExpStart,
      filterExpEnd: filterExpEnd ?? this.filterExpEnd,
      filterLocationId: filterLocationId ?? this.filterLocationId,
      filterStatusId: filterStatusId ?? this.filterStatusId,
      quantitySummary: quantitySummary ?? this.quantitySummary,
      expiringLots: expiringLots ?? this.expiringLots,
      datesValid: datesValid ?? this.datesValid,
      hasDuplication: hasDuplication ?? this.hasDuplication,

      expirationReportLots: expirationReportLots ?? this.expirationReportLots,
      expirationReportFilters:
          expirationReportFilters ?? this.expirationReportFilters,
      expirationReportPage: expirationReportPage ?? this.expirationReportPage,
      expirationReportTotalPages:
          expirationReportTotalPages ?? this.expirationReportTotalPages,
      expirationReportTotalCount:
          expirationReportTotalCount ?? this.expirationReportTotalCount,
      expirationReportTotalCost:
          expirationReportTotalCost ?? this.expirationReportTotalCost,
      hasMoreExpirationReport:
          hasMoreExpirationReport ?? this.hasMoreExpirationReport,
      exportReportMessage: exportReportMessage ?? this.exportReportMessage,

      // Upcoming Expiry Report fields
      upcomingExpiryLots: upcomingExpiryLots ?? this.upcomingExpiryLots,
      upcomingExpiryFilters:
          upcomingExpiryFilters ?? this.upcomingExpiryFilters,
      upcomingExpiryPage: upcomingExpiryPage ?? this.upcomingExpiryPage,
      upcomingExpiryTotalPages:
          upcomingExpiryTotalPages ?? this.upcomingExpiryTotalPages,
      upcomingExpiryTotalCount:
          upcomingExpiryTotalCount ?? this.upcomingExpiryTotalCount,
      upcomingExpiryTotalCost:
          upcomingExpiryTotalCost ?? this.upcomingExpiryTotalCost,
      hasMoreUpcomingExpiry:
          hasMoreUpcomingExpiry ?? this.hasMoreUpcomingExpiry,
      upcomingExpiryDaysThreshold:
          upcomingExpiryDaysThreshold ?? this.upcomingExpiryDaysThreshold,
    );
  }

  @override
  List<Object?> get props => [
    status,
    items,
    filteredItems,
    searchQuery,
    createItems,
    editItems,
    selectedItems,
    selected,
    selected2,
    message,
    companyId,
    filterItemId,
    filterExpStart,
    filterExpEnd,
    filterLocationId,
    filterStatusId,
    quantitySummary,
    expiringLots,
    datesValid,
    hasDuplication,
    expirationReportLots,
    expirationReportFilters,
    expirationReportPage,
    expirationReportTotalPages,
    expirationReportTotalCount,
    expirationReportTotalCost,
    hasMoreExpirationReport,
    exportReportMessage,

    // Upcoming Expiry Report fields
    upcomingExpiryLots,
    upcomingExpiryFilters,
    upcomingExpiryPage,
    upcomingExpiryTotalPages,
    upcomingExpiryTotalCount,
    upcomingExpiryTotalCost,
    hasMoreUpcomingExpiry,
    upcomingExpiryDaysThreshold,
  ];
}
