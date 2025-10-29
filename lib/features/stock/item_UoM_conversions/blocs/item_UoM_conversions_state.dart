// bloc/item_uom_conversion_state.dart
import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/stock/item_UoM_conversions/models/item_UoM_conversions_model.dart';
import 'package:savvy_stock/features/stock/item_UoM_conversions/models/uom_cconverstion_ui_state.dart';

enum ItemUomConversionStatus {
  initial,
  loading,
  searching,
  success,
  loaded,
  failure,
  creating,
  updating,
  deleting,
  duplication,
  structureInvalid,
  exporting,
  converting,
}

enum ItemUomConversionDetailStatus { hidden, showing, editing }

class ItemUomConversionState extends Equatable {
  final ItemUomConversionStatus status;
  final String? message;
  final int? companyId;
  final List<ItemUomConversion> items;
  final List<ItemUomConversion> filteredItems;
  final String searchQuery;

  // UI state management
  final UomConversionUiState uiState;

  final ItemUomConversionDetailStatus detailStatus;
  final ItemUomConversion? itemDetail;

  final List<ItemUomConversion> recentlyDeleted;
  final List<int> recentlyDeletedIndexes;

  final bool isExporting;
  final bool showDetailPanel;
  final List<ItemUomConversion> exportedItems;
  final ItemUomConversion? exportedItem;

  // Conversion results
  final double? conversionFactor;
  final String? conversionError;

   final bool? structureValid;
  final bool? hasDuplication;

  const ItemUomConversionState({
    this.status = ItemUomConversionStatus.initial,
    this.message,
    this.companyId,
    this.items = const [],
    this.filteredItems = const [],
    this.searchQuery = '',
    this.uiState = const UomConversionUiState(),
    this.detailStatus = ItemUomConversionDetailStatus.hidden,
    this.itemDetail,
    this.recentlyDeleted = const [],
    this.recentlyDeletedIndexes = const [],
    this.isExporting = false,
    this.showDetailPanel = false,
    this.exportedItems = const [],
    this.exportedItem,
    this.conversionFactor,
    this.conversionError,
    this.structureValid,
    this.hasDuplication,
  });

  // Helper getters for UI state
  List<ItemUomConversion> get createItems => uiState.createItems;
  List<ItemUomConversion> get editItems => uiState.editItems;
  ItemUomConversion? get selected => uiState.selected;
  ItemUomConversion? get selected1 => uiState.selected1;
  ItemUomConversion? get selected2 => uiState.selected2;
  List<ItemUomConversion> get multiSelectionItems =>
      uiState.multiSelectionItems;

  bool get isLoading => status == ItemUomConversionStatus.loading;
  bool get isSuccess => status == ItemUomConversionStatus.success;
  bool get isLoaded => status == ItemUomConversionStatus.loaded;
  bool get isFailure => status == ItemUomConversionStatus.failure;
  bool get isCreating => status == ItemUomConversionStatus.creating;
  bool get isUpdating => status == ItemUomConversionStatus.updating;
  bool get isDeleting => status == ItemUomConversionStatus.deleting;
  bool get isExportingData => status == ItemUomConversionStatus.exporting;
  bool get isConverting => status == ItemUomConversionStatus.converting;

  bool get isDetailVisible =>
      detailStatus != ItemUomConversionDetailStatus.hidden;
  bool get isDetailEditing =>
      detailStatus == ItemUomConversionDetailStatus.editing;

  bool get hasItems => items.isNotEmpty;
  bool get hasFilteredItems => filteredItems.isNotEmpty;
  bool get hasSelection => uiState.selected != null;
  bool get hasMultiSelection => uiState.multiSelectionItems.isNotEmpty;
  bool get canEdit => uiState.multiSelectionItems.length == 1;
  bool get canDelete => uiState.multiSelectionItems.isNotEmpty;
  bool get canExport => filteredItems.isNotEmpty;

  bool get hasRecentDeletions => recentlyDeleted.isNotEmpty;
  bool get hasCreateItems => uiState.createItems.isNotEmpty;
  bool get hasEditItems => uiState.editItems.isNotEmpty;

  bool get isSearching => status == ItemUomConversionStatus.searching;
  bool get isDuplicated => status == ItemUomConversionStatus.duplication;

  bool get isStructureValid => structureValid ?? false;
  bool get doeshasDuplication => hasDuplication ?? false;

/*************  ✨ Windsurf Command ⭐  *************/
  /// Creates a copy of the current state with the given parameters.
  ///
  /// [status] The new status of the state.
  /// [message] The new message of the state.
  /// [companyId] The new company ID of the state.
  /// [items] The new list of items in the state.
  /// [filteredItems] The new list of filtered items in the state.
  /// [searchQuery] The new search query in the state.
  /// [uiState] The new UI state of the state.
  /// [detailStatus] The new detail status of the state.
  /// [itemDetail] The new item detail of the state.
  /// [recentlyDeleted] The new list of recently deleted items in the state.

/*******  cb3288db-3d7f-401f-a91f-82707029c64d  *******/
  ItemUomConversionState copyWith({
    ItemUomConversionStatus? status,
    String? message,
    int? companyId,
    List<ItemUomConversion>? items,
    List<ItemUomConversion>? filteredItems,
    String? searchQuery,
    UomConversionUiState? uiState,
    ItemUomConversionDetailStatus? detailStatus,
    ItemUomConversion? itemDetail,
    List<ItemUomConversion>? recentlyDeleted,
    List<int>? recentlyDeletedIndexes,
    bool? isExporting,
    bool? showDetailPanel,
    List<ItemUomConversion>? exportedItems,
    ItemUomConversion? exportedItem,
    double? conversionFactor,
    String? conversionError,
    bool? structureValid,
    bool? hasDuplication,
  }) {
    return ItemUomConversionState(
      status: status ?? this.status,
      message: message ?? this.message,
      companyId: companyId ?? this.companyId,
      items: items ?? this.items,
      filteredItems: filteredItems ?? this.filteredItems,
      searchQuery: searchQuery ?? this.searchQuery,
      uiState: uiState ?? this.uiState,
      detailStatus: detailStatus ?? this.detailStatus,
      itemDetail: itemDetail ?? this.itemDetail,
      recentlyDeleted: recentlyDeleted ?? this.recentlyDeleted,
      recentlyDeletedIndexes:
          recentlyDeletedIndexes ?? this.recentlyDeletedIndexes,
      isExporting: isExporting ?? this.isExporting,
      showDetailPanel: showDetailPanel ?? this.showDetailPanel,
      exportedItems: exportedItems ?? this.exportedItems,
      exportedItem: exportedItem ?? this.exportedItem,
      conversionFactor: conversionFactor ?? this.conversionFactor,
      conversionError: conversionError ?? this.conversionError,
      structureValid: structureValid ?? this.structureValid,
      hasDuplication: hasDuplication ?? this.hasDuplication,
    );
  }

  @override
  List<Object?> get props => [
    status,
    message,
    companyId,
    items,
    filteredItems,
    searchQuery,
    uiState,
    detailStatus,
    itemDetail,
    recentlyDeleted,
    recentlyDeletedIndexes,
    isExporting,
    showDetailPanel,
    exportedItems,
    exportedItem,
    conversionFactor,
    conversionError,
    structureValid,
    hasDuplication,
  ];
}
