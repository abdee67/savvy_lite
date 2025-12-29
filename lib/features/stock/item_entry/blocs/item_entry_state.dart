import 'package:savvy_stock/features/stock/item_entry/models/item_entry_model.dart';
import 'package:savvy_stock/features/stock/item_entry/models/item_report_filter.model.dart';

enum ItemEntryStatus {
  initial,
  loading,
  loaded,
  creating,
  updating,
  deleting,
  searching,
  exporting,
  success,
  failure,
  duplication,
  editing,
  loadingItemReport,
  loadedItemReport,
  loadingMoreItemReport,
  exportingReport,
  exportReportSuccess,
}

enum ItemEntryDetailStatus { hidden, showing, editing }

class ItemEntryState {
  final ItemEntryStatus status;
  final String? message;
  final int? itemId;
  final int? companyId;
  final List<ItemEntryModel> items;
  final List<ItemEntryModel> filteredItems;
  final String searchQuery;
  final List<ItemEntryModel> selectedItems;
  final ItemEntryModel? itemForm;

  final ItemEntryDetailStatus detailStatus;
  final ItemEntryModel? itemDetail;

  final List<ItemEntryModel> recentlyDeleted;
  final List<int> recentlyDeletedIndexes;

  final bool isExporting;
  final bool showDetailPanel;
  final List<ItemEntryModel> exportedItems; //export multiple Branchs
  final ItemEntryModel? exportedItem; //export single Branch

  // Advanced data fields from Java controller
  final List<ItemEntryModel> multiselectionItems;
  List<ItemEntryModel> createItems;
  List<ItemEntryModel> editItems;
  final List<ItemEntryModel> filteredValues;
  ItemEntryModel? selected;
  final ItemEntryModel? selected1;
  final ItemEntryModel? selected2;
  final ItemEntryModel? selected3;
  final List<ItemEntryModel> barcodeItems;

  final List<ItemEntryModel> itemReportItems;
  final ItemReportFilters itemReportFilters;
  final int itemReportPage;
  final int itemReportTotalPages;
  final int itemReportTotalCount;
  final double itemReportTotalCost;
  final bool hasMoreItemReport;
  final String exportReportMessage;

  ItemEntryState({
    this.status = ItemEntryStatus.initial,
    this.message,
    this.itemId,
    this.companyId,
    this.items = const [],
    this.filteredItems = const [],
    this.searchQuery = '',
    this.selectedItems = const [],
    this.itemForm,
    this.detailStatus = ItemEntryDetailStatus.hidden,
    this.itemDetail,
    this.recentlyDeleted = const [],
    this.recentlyDeletedIndexes = const [],
    this.isExporting = false,
    this.showDetailPanel = false,
    this.exportedItems = const [],
    this.exportedItem,
    this.multiselectionItems = const [],
    this.createItems = const [],
    this.editItems = const [],
    this.filteredValues = const [],
    this.selected,
    this.selected1,
    this.selected2,
    this.selected3,
    this.barcodeItems = const [],
    this.itemReportItems = const [],
    this.itemReportFilters = const ItemReportFilters(),
    this.itemReportPage = 0,
    this.itemReportTotalPages = 0,
    this.itemReportTotalCount = 0,
    this.itemReportTotalCost = 0,
    this.hasMoreItemReport = false,
    this.exportReportMessage = '',
  });

  // --- Helper Getters ---
  bool get isLoading => status == ItemEntryStatus.loading;
  bool get isSuccess => status == ItemEntryStatus.success;
  bool get isFailure => status == ItemEntryStatus.failure;
  bool get isCreating => status == ItemEntryStatus.creating;
  bool get isUpdating => status == ItemEntryStatus.updating;
  bool get isDeleting => status == ItemEntryStatus.deleting;
  bool get isExportingData => status == ItemEntryStatus.exporting;
  bool get isEditing => status == ItemEntryStatus.editing;
  bool get isDuplication => status == ItemEntryStatus.duplication;
  bool get isLoaded => status == ItemEntryStatus.loaded;
  bool get isSearching => status == ItemEntryStatus.searching;
  bool get isInitial => status == ItemEntryStatus.initial;

  bool get isDetailVisible => detailStatus != ItemEntryDetailStatus.hidden;
  bool get isDetailEditing => detailStatus == ItemEntryDetailStatus.editing;

  bool get hasItems => items.isNotEmpty;
  bool get hasFilteredItems => filteredItems.isNotEmpty;
  bool get hasSelection => selectedItems.isNotEmpty;
  bool get canEdit => selectedItems.length == 1;
  bool get canDelete => selectedItems.isNotEmpty;
  bool get canExport => filteredItems.isNotEmpty;
  bool get useBarcode => barcodeItems.isNotEmpty;
  bool get hasItemReport => itemReportItems.isNotEmpty;
  bool get hasPreviousPage => itemReportPage > 1;
  bool get hasNextPage => itemReportPage < itemReportTotalPages;

  bool get hasRecentDeletions => recentlyDeleted.isNotEmpty;

  // --- CopyWith for immutability ---
  ItemEntryState copyWith({
    ItemEntryStatus? status,
    String? message,
    int? itemId,
    int? companyId,
    List<ItemEntryModel>? items,
    List<ItemEntryModel>? filteredItems,
    String? searchQuery,
    List<ItemEntryModel>? selectedItems,
    ItemEntryModel? itemForm,
    ItemEntryDetailStatus? detailStatus,
    ItemEntryModel? itemDetail,
    List<ItemEntryModel>? recentlyDeleted,
    List<int>? recentlyDeletedIndexes,
    bool? isExporting,
    bool? showDetailPanel,
    List<ItemEntryModel>? exportedItems,
    ItemEntryModel? exportedItem,
    List<ItemEntryModel>? multiselectionItems,
    List<ItemEntryModel>? createItems,
    List<ItemEntryModel>? editItems,
    List<ItemEntryModel>? filteredValues,
    ItemEntryModel? selected,
    ItemEntryModel? selected1,
    ItemEntryModel? selected2,
    ItemEntryModel? selected3,
    List<ItemEntryModel>? barcodeItems,
    List<ItemEntryModel>? itemReportItems,
    ItemReportFilters? itemReportFilters,
    int? itemReportPage,
    int? itemReportTotalPages,
    int? itemReportTotalCount,
    double? itemReportTotalCost,
    bool? hasMoreItemReport,
    String? exportReportMessage,
  }) {
    return ItemEntryState(
      status: status ?? this.status,
      message: message ?? this.message,
      itemId: itemId ?? this.itemId,
      companyId: companyId ?? this.companyId,
      items: items ?? this.items,
      filteredItems: filteredItems ?? this.filteredItems,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedItems: selectedItems ?? this.selectedItems,
      itemForm: itemForm ?? this.itemForm,
      detailStatus: detailStatus ?? this.detailStatus,
      itemDetail: itemDetail ?? this.itemDetail,
      recentlyDeleted: recentlyDeleted ?? this.recentlyDeleted,
      recentlyDeletedIndexes:
          recentlyDeletedIndexes ?? this.recentlyDeletedIndexes,
      isExporting: isExporting ?? this.isExporting,
      showDetailPanel: showDetailPanel ?? this.showDetailPanel,
      exportedItems: exportedItems ?? this.exportedItems,
      exportedItem: exportedItem ?? this.exportedItem,
      multiselectionItems: multiselectionItems ?? this.multiselectionItems,
      createItems: createItems ?? this.createItems,
      editItems: editItems ?? this.editItems,
      filteredValues: filteredValues ?? this.filteredValues,
      selected: selected ?? this.selected,
      selected1: selected1 ?? this.selected1,
      selected2: selected2 ?? this.selected2,
      selected3: selected3 ?? this.selected3,
      barcodeItems: barcodeItems ?? this.barcodeItems,
      itemReportItems: itemReportItems ?? this.itemReportItems,
      itemReportFilters: itemReportFilters ?? this.itemReportFilters,
      itemReportPage: itemReportPage ?? this.itemReportPage,
      itemReportTotalPages: itemReportTotalPages ?? this.itemReportTotalPages,
      itemReportTotalCount: itemReportTotalCount ?? this.itemReportTotalCount,
      itemReportTotalCost: itemReportTotalCost ?? this.itemReportTotalCost,
      hasMoreItemReport: hasMoreItemReport ?? this.hasMoreItemReport,
      exportReportMessage: exportReportMessage ?? this.exportReportMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    message,
    itemId,
    companyId,
    items,
    filteredItems,
    searchQuery,
    selectedItems,
    itemForm,
    detailStatus,
    itemDetail,
    recentlyDeleted,
    recentlyDeletedIndexes,
    isExporting,
    showDetailPanel,
    exportedItems,
    exportedItem,
    multiselectionItems,
    createItems,
    editItems,
    filteredValues,
    selected,
    selected1,
    selected2,
    selected3,
    barcodeItems,
    itemReportItems,
    itemReportFilters,
    itemReportPage,
    itemReportTotalPages,
    itemReportTotalCount,
    itemReportTotalCost,
    hasMoreItemReport,
    exportReportMessage,
  ];
}
