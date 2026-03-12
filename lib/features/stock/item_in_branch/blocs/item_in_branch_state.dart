import 'package:savvy_stock/features/stock/item_in_branch/models/available_items_in_branch_filter.dart';
import 'package:savvy_stock/features/stock/item_in_branch/models/item_in_branch_model.dart';
import 'package:savvy_stock/features/stock/item_in_branch/models/paginated_aval_item_in_branch_result.dart';

enum ItemInBranchStatus {
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
  loadingitemInBranchReport,
  loadeditemInBranchReport,
  loadingMoreitemInBranchReport,
  exportingReport,
  exportReportSuccess,

  loadAvailableItemInBranch,
  loadMoreAvailableItemInBranch,
  loadedAvailableItemInBranch,
  loadingMoreAvailableItemInBranch,
  exportingAvailableItemInBranch,
  exportAvailableItemInBranchSuccess,
}

enum ItemInBranchDetailStatus { hidden, showing, editing }

class ItemInBranchState {
  final ItemInBranchStatus status;
  final String? message;
  final int? itemId;
  final int? companyId;
  final int? branchId;

  final List<ItemInBranchModel> items;
  final List<ItemInBranchModel> filteredItems;
  final String searchQuery;
  final List<ItemInBranchModel> selectedItems;
  final ItemInBranchModel? itemForm;

  final ItemInBranchDetailStatus detailStatus;
  final ItemInBranchModel? itemDetail;

  final List<ItemInBranchModel> recentlyDeleted;
  final List<int> recentlyDeletedIndexes;

  final bool isExporting;
  final bool showDetailPanel;
  final List<ItemInBranchModel> exportedItems; //export multiple Branchs
  final ItemInBranchModel? exportedItem; //export single Branch

  // Advanced data fields
  final ItemInBranchModel? currentItemBranch;
  final List<ItemInBranchModel> itemsByItem;
  final List<ItemInBranchModel> itemsByBranch;
  final List<ItemInBranchModel> lowStockItems;
  final List<ItemInBranchModel> outOfStockItems;
  final List<ItemInBranchModel> availableItems;
  final List<ItemInBranchModel> createItems;
  final List<ItemInBranchModel> editItems;
  final ItemInBranchModel? selected;
  final ItemInBranchModel? selected1;
  final ItemInBranchModel? selected2;

  final List<ItemInBranchModel> itemInBranchReportItems;
  final int itemInBranchReportPage;
  final int itemInBranchReportTotalPages;
  final int itemInBranchReportTotalCount;
  final double itemInBranchReportTotalCost;
  final bool hasMoreitemInBranchReport;
  final String exportReportMessage;

  // Financial data
  double totalAmountInETB = 0.0;

  final List<ItemInBranchModel> availableItemInBranchItems;
  final List<PaginatedItemInBranchResult> availableItemInBranchResults;
  final AvailableItemsInBranchFilter availableItemInBranchFilters;
  final int availableItemInBranchPage;
  final int availableItemInBranchTotalPages;
  final int availableItemInBranchTotalCount;
  final bool hasMoreAvailableItemInBranch;
  final String exportAvailableItemInBranchMessage;
  final Map<int, double> availableItemsInBranchCost;
  final Map<int, double> availableItemsExpirationQty;

  ItemInBranchState({
    this.status = ItemInBranchStatus.initial,
    this.message,
    this.itemId,
    this.companyId,
    this.branchId,
    this.items = const [],
    this.filteredItems = const [],
    this.searchQuery = '',
    this.selectedItems = const [],
    this.itemForm,
    this.detailStatus = ItemInBranchDetailStatus.hidden,
    this.itemDetail,
    this.recentlyDeleted = const [],
    this.recentlyDeletedIndexes = const [],
    this.isExporting = false,
    this.showDetailPanel = false,
    this.exportedItems = const [],
    this.exportedItem,
    this.currentItemBranch,
    this.itemsByItem = const [],
    this.itemsByBranch = const [],
    this.lowStockItems = const [],
    this.outOfStockItems = const [],
    this.availableItems = const [],
    this.createItems = const [],
    this.editItems = const [],
    this.selected,
    this.selected1,
    this.selected2,
    this.totalAmountInETB = 0.0,
    this.itemInBranchReportItems = const [],
    this.itemInBranchReportPage = 0,
    this.itemInBranchReportTotalPages = 0,
    this.itemInBranchReportTotalCount = 0,
    this.itemInBranchReportTotalCost = 0,
    this.hasMoreitemInBranchReport = false,
    this.exportReportMessage = '',
    this.availableItemInBranchItems = const [],
    this.availableItemInBranchResults = const [],
    this.availableItemInBranchFilters = const AvailableItemsInBranchFilter(),
    this.availableItemInBranchPage = 0,
    this.availableItemInBranchTotalPages = 0,
    this.availableItemInBranchTotalCount = 0,
    this.hasMoreAvailableItemInBranch = false,
    this.exportAvailableItemInBranchMessage = '',
    this.availableItemsInBranchCost = const {},
    this.availableItemsExpirationQty = const {},
  });

  // --- Helper Getters ---
  bool get isLoading => status == ItemInBranchStatus.loading;
  bool get isSuccess => status == ItemInBranchStatus.success;
  bool get isLoaded => status == ItemInBranchStatus.loaded;
  bool get isFailure => status == ItemInBranchStatus.failure;
  bool get isCreating => status == ItemInBranchStatus.creating;
  bool get isUpdating => status == ItemInBranchStatus.updating;
  bool get isDeleting => status == ItemInBranchStatus.deleting;
  bool get isExportingData => status == ItemInBranchStatus.exporting;

  bool get isDetailVisible => detailStatus != ItemInBranchDetailStatus.hidden;
  bool get isDetailEditing => detailStatus == ItemInBranchDetailStatus.editing;

  bool get hasItems => items.isNotEmpty;
  bool get hasFilteredItems => filteredItems.isNotEmpty;
  bool get hasSelection => selectedItems.isNotEmpty;
  bool get canEdit => selectedItems.length == 1;
  bool get canDelete => selectedItems.isNotEmpty;
  bool get canExport => filteredItems.isNotEmpty;

  bool get hasRecentDeletions => recentlyDeleted.isNotEmpty;

  bool get hasItemsByItem => itemsByItem.isNotEmpty;
  bool get hasItemsByBranch => itemsByBranch.isNotEmpty;
  bool get hasLowStockItems => lowStockItems.isNotEmpty;
  bool get hasOutOfStockItems => outOfStockItems.isNotEmpty;
  bool get hasAvailableItems => availableItems.isNotEmpty;
  bool get hasitemInBranchReport => itemInBranchReportItems.isNotEmpty;
  bool get hasPreviousPage => itemInBranchReportPage > 1;
  bool get hasNextPage => itemInBranchReportPage < itemInBranchReportTotalPages;

  // --- CopyWith for immutability ---
  ItemInBranchState copyWith({
    ItemInBranchStatus? status,
    String? message,
    int? itemId,
    int? companyId,
    List<ItemInBranchModel>? items,
    List<ItemInBranchModel>? filteredItems,
    String? searchQuery,
    List<ItemInBranchModel>? selectedItems,
    ItemInBranchModel? itemForm,
    ItemInBranchDetailStatus? detailStatus,
    ItemInBranchModel? itemDetail,
    List<ItemInBranchModel>? recentlyDeleted,
    List<int>? recentlyDeletedIndexes,
    bool? isExporting,
    bool? showDetailPanel,
    List<ItemInBranchModel>? exportedItems,
    ItemInBranchModel? exportedItem,
    ItemInBranchModel? currentItemBranch,
    List<ItemInBranchModel>? itemsByItem,
    List<ItemInBranchModel>? itemsByBranch,
    List<ItemInBranchModel>? lowStockItems,
    List<ItemInBranchModel>? outOfStockItems,
    List<ItemInBranchModel>? availableItems,
    List<ItemInBranchModel>? createItems,
    List<ItemInBranchModel>? editItems,
    ItemInBranchModel? selected,
    ItemInBranchModel? selected1,
    ItemInBranchModel? selected2,
    double? totalAmountInETB,
    List<ItemInBranchModel>? itemInBranchReportItems,
    int? itemInBranchReportPage,
    int? itemInBranchReportTotalPages,
    int? itemInBranchReportTotalCount,
    double? itemInBranchReportTotalCost,
    bool? hasMoreitemInBranchReport,
    String? exportReportMessage,
    List<ItemInBranchModel>? availableItemInBranchItems,
    List<PaginatedItemInBranchResult>? availableItemInBranchResults,
    AvailableItemsInBranchFilter? availableItemInBranchFilters,
    int? availableItemInBranchPage,
    int? availableItemInBranchTotalPages,
    int? availableItemInBranchTotalCount,
    bool? hasMoreAvailableItemInBranch,
    String? exportAvailableItemInBranchMessage,
    Map<int, double>? availableItemsInBranchCost,
    Map<int, double>? availableItemsExpirationQty,
  }) {
    return ItemInBranchState(
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
      exportedItem: exportedItem ?? this.exportedItem,
      exportedItems: exportedItems ?? this.exportedItems,
      currentItemBranch: currentItemBranch ?? this.currentItemBranch,
      itemsByItem: itemsByItem ?? this.itemsByItem,
      itemsByBranch: itemsByBranch ?? this.itemsByBranch,
      lowStockItems: lowStockItems ?? this.lowStockItems,
      outOfStockItems: outOfStockItems ?? this.outOfStockItems,
      availableItems: availableItems ?? this.availableItems,
      createItems: createItems ?? this.createItems,
      editItems: editItems ?? this.editItems,
      selected: selected ?? this.selected,
      selected1: selected1 ?? this.selected1,
      selected2: selected2 ?? this.selected2,
      totalAmountInETB: totalAmountInETB ?? this.totalAmountInETB,
      itemInBranchReportItems:
          itemInBranchReportItems ?? this.itemInBranchReportItems,
      itemInBranchReportPage:
          itemInBranchReportPage ?? this.itemInBranchReportPage,
      itemInBranchReportTotalPages:
          itemInBranchReportTotalPages ?? this.itemInBranchReportTotalPages,
      itemInBranchReportTotalCount:
          itemInBranchReportTotalCount ?? this.itemInBranchReportTotalCount,
      itemInBranchReportTotalCost:
          itemInBranchReportTotalCost ?? this.itemInBranchReportTotalCost,
      hasMoreitemInBranchReport:
          hasMoreitemInBranchReport ?? this.hasMoreitemInBranchReport,
      exportReportMessage: exportReportMessage ?? this.exportReportMessage,
      availableItemInBranchFilters:
          availableItemInBranchFilters ?? this.availableItemInBranchFilters,
      availableItemInBranchItems:
          availableItemInBranchItems ?? this.availableItemInBranchItems,
      availableItemInBranchPage:
          availableItemInBranchPage ?? this.availableItemInBranchPage,
      availableItemInBranchTotalCount:
          availableItemInBranchTotalCount ??
          this.availableItemInBranchTotalCount,
      availableItemInBranchTotalPages:
          availableItemInBranchTotalPages ??
          this.availableItemInBranchTotalPages,
      hasMoreAvailableItemInBranch:
          hasMoreAvailableItemInBranch ?? this.hasMoreAvailableItemInBranch,
      exportAvailableItemInBranchMessage:
          exportAvailableItemInBranchMessage ??
          this.exportAvailableItemInBranchMessage,
      availableItemsInBranchCost:
          availableItemsInBranchCost ?? this.availableItemsInBranchCost,
      availableItemsExpirationQty:
          availableItemsExpirationQty ?? this.availableItemsExpirationQty,
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
    currentItemBranch,
    itemsByItem,
    itemsByBranch,
    lowStockItems,
    outOfStockItems,
    availableItems,
    createItems,
    editItems,
    selected,
    selected1,
    selected2,
    totalAmountInETB,
    itemInBranchReportItems,
    itemInBranchReportPage,
    itemInBranchReportTotalPages,
    itemInBranchReportTotalCount,
    itemInBranchReportTotalCost,
    hasMoreitemInBranchReport,
    exportReportMessage,
    availableItemInBranchFilters,
    availableItemInBranchItems,
    availableItemInBranchPage,
    availableItemInBranchTotalCount,
    availableItemInBranchTotalPages,
    hasMoreAvailableItemInBranch,
    exportAvailableItemInBranchMessage,
    availableItemsInBranchCost,
    availableItemsExpirationQty,
  ];
}
