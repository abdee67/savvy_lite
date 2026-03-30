import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/stock/item_locations/models/item_location_filters.dart';
import 'package:savvy_stock/features/stock/item_locations/models/item_locations_model.dart';

enum ItemLocationsStatus {
  initial,
  loading,
  searching,
  success,
  failure,
  creating,
  updating,
  deleting,
  exporting,
  loadingItemLocationAvailability,
  loadingMoreItemLocationAvailability,
}

enum ItemLocationsDetailStatus { hidden, showing, editing }

class ItemLocationsState extends Equatable {
  final ItemLocationsStatus status;
  final String? message;
  final int? itemId;
  final int? branchId;
  final int? companyId;
  final List<ItemLocation> items;
  final List<ItemLocation> filteredItems;
  final String searchQuery;
  final List<ItemLocation> selectedItems;
  final ItemLocation? itemForm;

  final ItemLocationsDetailStatus detailStatus;
  final ItemLocation? itemDetail;

  final List<ItemLocation> recentlyDeleted;
  final List<int> recentlyDeletedIndexes;

  final bool isExporting;
  final bool showDetailPanel;
  final List<ItemLocation> exportedItems; //export multiple Branchs
  final ItemLocation? exportedItem; //export single Branch

  // Lazy loading state
  final List<ItemLocation> lazyItems;
  final ItemLocationFilters lazyFilters;
  final int lazyTotalCount;
  final int lazyTotalPages;
  final int lazyPage;
  final bool hasMoreLazyItems;
  final Map<int, double> locationCosts;

  // Role management state

  const ItemLocationsState({
    this.status = ItemLocationsStatus.initial,
    this.message,
    this.itemId,
    this.branchId,
    this.companyId,
    this.items = const [],
    this.filteredItems = const [],
    this.searchQuery = '',
    this.selectedItems = const [],
    this.itemForm,
    this.detailStatus = ItemLocationsDetailStatus.hidden,
    this.itemDetail,
    this.recentlyDeleted = const [],
    this.recentlyDeletedIndexes = const [],
    this.isExporting = false,
    this.showDetailPanel = false,
    this.exportedItems = const [],
    this.exportedItem,
    this.lazyItems = const [],
    this.lazyFilters = const ItemLocationFilters(),
    this.lazyTotalCount = 0,
    this.lazyTotalPages = 0,
    this.lazyPage = 1,
    this.hasMoreLazyItems = false,
    this.locationCosts = const {},
  });

  // --- Helper Getters ---
  bool get isLoading => status == ItemLocationsStatus.loading;
  bool get isSuccess => status == ItemLocationsStatus.success;
  bool get isFailure => status == ItemLocationsStatus.failure;
  bool get isCreating => status == ItemLocationsStatus.creating;
  bool get isUpdating => status == ItemLocationsStatus.updating;
  bool get isDeleting => status == ItemLocationsStatus.deleting;
  bool get isExportingData => status == ItemLocationsStatus.exporting;

  bool get isDetailVisible => detailStatus != ItemLocationsDetailStatus.hidden;
  bool get isDetailEditing => detailStatus == ItemLocationsDetailStatus.editing;

  bool get hasItems => items.isNotEmpty;
  bool get hasFilteredItems => filteredItems.isNotEmpty;
  bool get hasSelection => selectedItems.isNotEmpty;
  bool get canEdit => selectedItems.length == 1;
  bool get canDelete => selectedItems.isNotEmpty;
  bool get canExport => filteredItems.isNotEmpty;

  bool get hasRecentDeletions => recentlyDeleted.isNotEmpty;

  // --- CopyWith for immutability ---
  ItemLocationsState copyWith({
    ItemLocationsStatus? status,
    String? message,
    int? itemId,
    int? branchId,
    int? companyId,
    List<ItemLocation>? items,
    List<ItemLocation>? filteredItems,
    String? searchQuery,
    List<ItemLocation>? selectedItems,
    ItemLocation? itemForm,
    ItemLocationsDetailStatus? detailStatus,
    ItemLocation? itemDetail,
    List<ItemLocation>? recentlyDeleted,
    List<int>? recentlyDeletedIndexes,
    bool? isExporting,
    bool? showDetailPanel,
    List<ItemLocation>? exportedItems,
    ItemLocation? exportedItem,
    List<ItemLocation>? lazyItems,
    ItemLocationFilters? lazyFilters,
    int? lazyTotalCount,
    int? lazyTotalPages,
    int? lazyPage,
    bool? hasMoreLazyItems,
    Map<int, double>? locationCosts,
  }) {
    return ItemLocationsState(
      status: status ?? this.status,
      message: message ?? this.message,
      itemId: itemId ?? this.itemId,
      branchId: branchId ?? this.branchId,
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
      lazyItems: lazyItems ?? this.lazyItems,
      lazyFilters: lazyFilters ?? this.lazyFilters,
      lazyTotalCount: lazyTotalCount ?? this.lazyTotalCount,
      lazyTotalPages: lazyTotalPages ?? this.lazyTotalPages,
      lazyPage: lazyPage ?? this.lazyPage,
      hasMoreLazyItems: hasMoreLazyItems ?? this.hasMoreLazyItems,
      locationCosts: locationCosts ?? this.locationCosts,
    );
  }

  @override
  List<Object?> get props => [
    status,
    message,
    itemId,
    branchId,
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
    lazyItems,
    lazyFilters,
    lazyTotalCount,
    lazyTotalPages,
    lazyPage,
    hasMoreLazyItems,
    locationCosts,
  ];
}
