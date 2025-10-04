import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/stock/item_in_branch/models/item_in_branch_model.dart';

enum ItemInBranchStatus {
  initial,
  loading,
  searching,
  success,
  failure,
  creating,
  updating,
  deleting,
  duplication,
  exporting,
}

enum ItemInBranchDetailStatus { hidden, showing, editing }

class ItemInBranchState extends Equatable {
  final ItemInBranchStatus status;
  final String? message;
  final int? itemId;
  final int? companyId;
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

  // Role management state

  const ItemInBranchState({
    this.status = ItemInBranchStatus.initial,
    this.message,
    this.itemId,
    this.companyId,
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
  });

  // --- Helper Getters ---
  bool get isLoading => status == ItemInBranchStatus.loading;
  bool get isSuccess => status == ItemInBranchStatus.success;
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
  ];
}
