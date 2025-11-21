// bloc/item_uom_conversion_state.dart
import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/stock/item_uom_conversions/models/item_uom_conversions_model.dart';
import 'package:savvy_stock/features/stock/item_uom_conversions/models/uom_cconverstion_ui_state.dart';
import 'package:savvy_stock/features/udc_detail/models/udc_details.dart';

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
  validationFailed,
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
  final List<ItemUomConversion> createItems;
  final List<ItemUomConversion> editItems;
  final List<ItemUomConversion> multiSelectionItems;
  final List<ItemUomConversion> filteredValues;
  final ItemUomConversion? selected;
  final ItemUomConversion? selected1;
  final ItemUomConversion? selected2;
  final int first;
  final List<UdcDetails> availableUomsForItem;
  final bool isLoadingUomsForItem;

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
    this.createItems = const [],
    this.editItems = const [],
    this.multiSelectionItems = const [],
    this.filteredValues = const [],
    this.selected,
    this.selected1,
    this.selected2,
    this.first = 0,
    this.availableUomsForItem = const [],
    this.isLoadingUomsForItem = false,
  });

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
  bool get isStructureInvalid =>
      status == ItemUomConversionStatus.structureInvalid;
  bool get isValidationFailed =>
      status == ItemUomConversionStatus.validationFailed;

  bool get isStructureValid => structureValid ?? false;
  bool get doeshasDuplication => hasDuplication ?? false;

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
    List<ItemUomConversion>? createItems,
    List<ItemUomConversion>? editItems,
    List<ItemUomConversion>? multiSelectionItems,
    List<ItemUomConversion>? filteredValues,
    ItemUomConversion? selected,
    ItemUomConversion? selected1,
    ItemUomConversion? selected2,
    int? first,
    List<UdcDetails>? availableUomsForItem,
    bool? isLoadingUomsForItem,
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
      createItems: createItems ?? this.createItems,
      editItems: editItems ?? this.editItems,
      multiSelectionItems: multiSelectionItems ?? this.multiSelectionItems,
      filteredValues: filteredValues ?? this.filteredValues,
      selected: selected ?? this.selected,
      selected1: selected1 ?? this.selected1,
      selected2: selected2 ?? this.selected2,
      first: first ?? this.first,
      availableUomsForItem: availableUomsForItem ?? this.availableUomsForItem,
      isLoadingUomsForItem: isLoadingUomsForItem ?? this.isLoadingUomsForItem,
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
    createItems,
    editItems,
    multiSelectionItems,
    filteredValues,
    selected,
    selected1,
    selected2,
    first,
    availableUomsForItem,
    isLoadingUomsForItem,
  ];
}
