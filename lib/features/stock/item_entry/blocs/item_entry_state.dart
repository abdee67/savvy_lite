import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/stock/item_entry/models/item_entry_model.dart';

enum ItemEntryStatus {
  initial,
  loading,
  searching,
  success,
  failure,
  creating,
  updating,
  deleting,
  exporting,
}

enum ItemEntryDetailStatus { hidden, showing, editing }

class ItemEntryState extends Equatable {
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

  // Role management state

  const ItemEntryState({
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
  });

  // --- Helper Getters ---
  bool get isLoading => status == ItemEntryStatus.loading;
  bool get isSuccess => status == ItemEntryStatus.success;
  bool get isFailure => status == ItemEntryStatus.failure;
  bool get isCreating => status == ItemEntryStatus.creating;
  bool get isUpdating => status == ItemEntryStatus.updating;
  bool get isDeleting => status == ItemEntryStatus.deleting;
  bool get isExportingData => status == ItemEntryStatus.exporting;

  bool get isDetailVisible => detailStatus != ItemEntryDetailStatus.hidden;
  bool get isDetailEditing => detailStatus == ItemEntryDetailStatus.editing;

  bool get hasItems => items.isNotEmpty;
  bool get hasFilteredItems => filteredItems.isNotEmpty;
  bool get hasSelection => selectedItems.isNotEmpty;
  bool get canEdit => selectedItems.length == 1;
  bool get canDelete => selectedItems.isNotEmpty;
  bool get canExport => filteredItems.isNotEmpty;

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
