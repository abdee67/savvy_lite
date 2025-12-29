// bloc/item_cost_state.dart

import 'package:savvy_stock/features/stock/item_cost/models/item_cost_model.dart';

enum ItemCostStatus {
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

  loadingItemCostReport,
  loadedItemCostReport,
  loadingMoreItemCostReport,
  exportingItemCostReport,
  exportItemCostReportSuccess,
}

class ItemCostState {
  final ItemCostStatus status;
  final List<ItemCost> items;
  final List<ItemCost> createItems;
  final List<ItemCost> editItems;
  final List<ItemCost> multiselectionItems;
  final List<ItemCost> filteredValues;
  final ItemCost? selected;
  final ItemCost? selected1;
  final ItemCost? selected2;
  final String? errorMessage;
  final String? successMessage;
  final bool isLoading;

  // Item Cost Report fields
  final List<ItemCost> itemCostReportItems;
  final int itemCostReportPage;
  final int itemCostReportTotalPages;
  final int itemCostReportTotalCount;
  final double itemCostReportTotalCost;
  final bool hasMoreItemCostReport;

  const ItemCostState({
    this.status = ItemCostStatus.initial,
    this.items = const [],
    this.createItems = const [],
    this.editItems = const [],
    this.multiselectionItems = const [],
    this.filteredValues = const [],
    this.selected,
    this.selected1,
    this.selected2,
    this.errorMessage,
    this.successMessage,
    this.isLoading = false,
    this.itemCostReportItems = const [],
    this.itemCostReportPage = 1,
    this.itemCostReportTotalPages = 0,
    this.itemCostReportTotalCount = 0,
    this.itemCostReportTotalCost = 0.0,
    this.hasMoreItemCostReport = false,
  });

  ItemCostState copyWith({
    ItemCostStatus? status,
    List<ItemCost>? items,
    List<ItemCost>? createItems,
    List<ItemCost>? editItems,
    List<ItemCost>? multiselectionItems,
    List<ItemCost>? filteredValues,
    ItemCost? selected,
    ItemCost? selected1,
    ItemCost? selected2,
    String? errorMessage,
    String? successMessage,
    bool? isLoading,
    List<ItemCost>? itemCostReportItems,
    int? itemCostReportPage,
    int? itemCostReportTotalPages,
    int? itemCostReportTotalCount,
    double? itemCostReportTotalCost,
    bool? hasMoreItemCostReport,
  }) {
    return ItemCostState(
      status: status ?? this.status,
      items: items ?? this.items,
      createItems: createItems ?? this.createItems,
      editItems: editItems ?? this.editItems,
      multiselectionItems: multiselectionItems ?? this.multiselectionItems,
      filteredValues: filteredValues ?? this.filteredValues,
      selected: selected ?? this.selected,
      selected1: selected1 ?? this.selected1,
      selected2: selected2 ?? this.selected2,
      errorMessage: errorMessage ?? this.errorMessage,
      successMessage: successMessage ?? this.successMessage,
      isLoading: isLoading ?? this.isLoading,
      itemCostReportItems: itemCostReportItems ?? this.itemCostReportItems,
      itemCostReportPage: itemCostReportPage ?? this.itemCostReportPage,
      itemCostReportTotalPages:
          itemCostReportTotalPages ?? this.itemCostReportTotalPages,
      itemCostReportTotalCount:
          itemCostReportTotalCount ?? this.itemCostReportTotalCount,
      itemCostReportTotalCost:
          itemCostReportTotalCost ?? this.itemCostReportTotalCost,
      hasMoreItemCostReport:
          hasMoreItemCostReport ?? this.hasMoreItemCostReport,
    );
  }

  bool get isSuccess => status == ItemCostStatus.success;
  bool get isFailure => status == ItemCostStatus.failure;
  bool get isCreating => status == ItemCostStatus.creating;
  bool get isUpdating => status == ItemCostStatus.updating;
  bool get isDeleting => status == ItemCostStatus.deleting;
  bool get isFiltering => status == ItemCostStatus.filtering;
  bool get isSearching => status == ItemCostStatus.searching;
  bool get hasItems => items.isNotEmpty;
  bool get hasFilteredItems => filteredValues.isNotEmpty;
  bool get hasSelection => multiselectionItems.isNotEmpty;
  bool get canEdit => multiselectionItems.length == 1;
  bool get canDelete => multiselectionItems.isNotEmpty;
  bool get canExport => filteredValues.isNotEmpty;
  bool get hasNextPage => itemCostReportPage < itemCostReportTotalPages;
  bool get hasPreviousPage => itemCostReportPage > 1;

  @override
  List<Object?> get props => [
    items,
    createItems,
    editItems,
    multiselectionItems,
    filteredValues,
    selected,
    selected1,
    selected2,
    isLoading,
    itemCostReportItems,
    itemCostReportPage,
    itemCostReportTotalPages,
    itemCostReportTotalCount,
    itemCostReportTotalCost,
    hasMoreItemCostReport,
  ];
}
