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
}

class LotMasterState {
  final LotMasterStatus status;
  final List<LotMaster> items;
  final List<LotMaster> filteredItems;
  final String searchQuery;
  final List<LotMaster> createItems;
  final List<LotMaster> editItems;
  final List<LotMaster> multiSelectionItems;
  final List<LotMaster> selectedItems;
  final LotMaster? selected;
  final LotMaster? selected1;
  final LotMaster? selected2;
  final String message;
  final String? error;
  final int companyId;

  // Filter fields
  final int? filterItemId;
  final DateTime? filterExpStart;
  final DateTime? filterExpEnd;
  final int? filterLocationId;
  final int? filterStatusId;

  const LotMasterState({
    this.status = LotMasterStatus.initial,
    this.items = const [],
    this.filteredItems = const [],
    this.searchQuery = '',
    this.createItems = const [],
    this.editItems = const [],
    this.multiSelectionItems = const [],
    this.selectedItems = const [],
    this.selected,
    this.selected1,
    this.selected2,
    this.message = '',
    this.error,
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
    List<LotMaster>? multiSelectionItems,
    List<LotMaster>? selectedItems,
    LotMaster? selected,
    LotMaster? selected1,
    LotMaster? selected2,
    String? message,
    String? error,
    int? companyId,

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
      multiSelectionItems: multiSelectionItems ?? this.multiSelectionItems,
      selectedItems: selectedItems ?? this.selectedItems,
      selected: selected ?? this.selected,
      selected1: selected1 ?? this.selected1,
      selected2: selected2 ?? this.selected2,
      message: message ?? this.message,
      error: error ?? this.error,
      companyId: companyId ?? this.companyId,
      filterItemId: filterItemId ?? this.filterItemId,
      filterExpStart: filterExpStart ?? this.filterExpStart,
      filterExpEnd: filterExpEnd ?? this.filterExpEnd,
      filterLocationId: filterLocationId ?? this.filterLocationId,
      filterStatusId: filterStatusId ?? this.filterStatusId,
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
    multiSelectionItems,
    selectedItems,
    selected,
    selected1,
    selected2,
    message,
    error,
    companyId,
    filterItemId,
    filterExpStart,
    filterExpEnd,
    filterLocationId,
    filterStatusId,
  ];
}
