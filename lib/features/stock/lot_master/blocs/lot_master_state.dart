// features/stock/lot_master/blocs/lot_master_state.dart

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
  duplicationFound

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
  ];
}
