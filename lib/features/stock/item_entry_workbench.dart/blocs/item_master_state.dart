import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/stock/item_entry_workbench.dart/models/item_master_model.dart';

enum ItemMasterStatus {
  initial,
  loading,
  loaded,
  creating,
  updating,
  deleting,
  saving,
  searching,
  success,
  failure,
  duplication,
  editing,
  migrating,
  generatingTemplate,
  processingFile,
}

class ItemMasterState extends Equatable {
  final ItemMasterStatus status;
  final String? message;

  // Core data lists
  final List<ItemMaster> items;
  final List<ItemMaster> filteredItems;
  final List<ItemMaster> selectedItems;
  final String searchQuery;

  // State variables from Java controller
  final List<ItemMaster> multiselectionItems;
  final List<ItemMaster> createItems;
  final List<ItemMaster> editItems;
  final List<ItemMaster> filteredValues;

  // Selected items
  final ItemMaster? selected;
  final ItemMaster? selected1;
  final ItemMaster? selected2;

  // Pagination
  final int first;

  // Data migration
  final List<String> columns4;
  final Map<String, String> columns4LabelMap;
  final List<String> migrationColumns;
  final Map<String, String> migrationColumnLabels;
  final List<bool> columnVisibility;
  final List<ItemMaster> uploadedItems;
  final File? currentExcelFile;
  final bool isDuplicate;

  // UI state
  final bool showMigrationPanel;
  final bool showCreatePanel;
  final bool showEditPanel;

  const ItemMasterState({
    this.status = ItemMasterStatus.initial,
    this.message,
    this.items = const [],
    this.filteredItems = const [],
    this.selectedItems = const [],
    this.searchQuery = '',
    this.multiselectionItems = const [],
    this.createItems = const [],
    this.editItems = const [],
    this.filteredValues = const [],
    this.selected,
    this.selected1,
    this.selected2,
    this.first = 0,
    this.columns4 = const [],
    this.columns4LabelMap = const {},
    this.migrationColumns = const [],
    this.migrationColumnLabels = const {},
    this.columnVisibility = const [],
    this.uploadedItems = const [],
    this.currentExcelFile,
    this.isDuplicate = false,
    this.showMigrationPanel = false,
    this.showCreatePanel = false,
    this.showEditPanel = false,
  });

  // --- Helper Getters ---
  bool get isLoading => status == ItemMasterStatus.loading;
  bool get isSuccess => status == ItemMasterStatus.success;
  bool get isFailure => status == ItemMasterStatus.failure;
  bool get isCreating => status == ItemMasterStatus.creating;
  bool get isUpdating => status == ItemMasterStatus.updating;
  bool get isDeleting => status == ItemMasterStatus.deleting;
  bool get isSaving => status == ItemMasterStatus.saving;
  bool get isEditing => status == ItemMasterStatus.editing;
  bool get isDuplication => status == ItemMasterStatus.duplication;
  bool get isMigrating => status == ItemMasterStatus.migrating;
  bool get isLoaded => status == ItemMasterStatus.loaded;
  bool get isSearching => status == ItemMasterStatus.searching;
  bool get isInitial => status == ItemMasterStatus.initial;

  bool get hasItems => items.isNotEmpty;
  bool get hasFilteredItems => filteredItems.isNotEmpty;
  bool get hasSelection => selectedItems.isNotEmpty;
  bool get hasMultiSelection => multiselectionItems.isNotEmpty;
  bool get hasCreateItems => createItems.isNotEmpty;
  bool get hasEditItems => editItems.isNotEmpty;
  bool get canEdit => multiselectionItems.length == 1;
  bool get canDelete => multiselectionItems.isNotEmpty;
  bool get canCopy => multiselectionItems.isNotEmpty;

  bool get hasSelected => selected != null;
  bool get hasSelected1 => selected1 != null;
  bool get hasSelected2 => selected2!.itemDescription!.isNotEmpty;

  bool get hasMigrationColumns => columns4.isNotEmpty;

  // --- CopyWith for immutability ---
  ItemMasterState copyWith({
    ItemMasterStatus? status,
    String? message,
    List<ItemMaster>? items,
    List<ItemMaster>? filteredItems,
    List<ItemMaster>? selectedItems,
    String? searchQuery,
    List<ItemMaster>? multiselectionItems,
    List<ItemMaster>? createItems,
    List<ItemMaster>? editItems,
    List<ItemMaster>? filteredValues,
    ItemMaster? selected,
    ItemMaster? selected1,
    ItemMaster? selected2,
    int? first,
    List<String>? columns4,
    Map<String, String>? columns4LabelMap,
    bool? isDuplicate,
    bool? showMigrationPanel,
    bool? showCreatePanel,
    bool? showEditPanel,
    List<String>? migrationColumns,
    Map<String, String>? migrationColumnLabels,
    List<bool>? columnVisibility,
    List<ItemMaster>? uploadedItems,
    File? currentExcelFile,
  }) {
    return ItemMasterState(
      status: status ?? this.status,
      message: message ?? this.message,
      items: items ?? this.items,
      filteredItems: filteredItems ?? this.filteredItems,
      selectedItems: selectedItems ?? this.selectedItems,
      searchQuery: searchQuery ?? this.searchQuery,
      multiselectionItems: multiselectionItems ?? this.multiselectionItems,
      createItems: createItems ?? this.createItems,
      editItems: editItems ?? this.editItems,
      filteredValues: filteredValues ?? this.filteredValues,
      selected: selected ?? this.selected,
      selected1: selected1 ?? this.selected1,
      selected2: selected2 ?? this.selected2,
      first: first ?? this.first,
      columns4: columns4 ?? this.columns4,
      columns4LabelMap: columns4LabelMap ?? this.columns4LabelMap,
      isDuplicate: isDuplicate ?? this.isDuplicate,
      showMigrationPanel: showMigrationPanel ?? this.showMigrationPanel,
      showCreatePanel: showCreatePanel ?? this.showCreatePanel,
      showEditPanel: showEditPanel ?? this.showEditPanel,
      migrationColumns: migrationColumns ?? this.migrationColumns,
      migrationColumnLabels:
          migrationColumnLabels ?? this.migrationColumnLabels,
      columnVisibility: columnVisibility ?? this.columnVisibility,
      uploadedItems: uploadedItems ?? this.uploadedItems,
      currentExcelFile: currentExcelFile ?? this.currentExcelFile,
    );
  }

  @override
  List<Object?> get props => [
    status,
    message,
    items,
    filteredItems,
    selectedItems,
    searchQuery,
    multiselectionItems,
    createItems,
    editItems,
    filteredValues,
    selected,
    selected1,
    selected2,
    first,
    columns4,
    columns4LabelMap,
    isDuplicate,
    showMigrationPanel,
    showCreatePanel,
    showEditPanel,
    migrationColumns,
    migrationColumnLabels,
    columnVisibility,
    uploadedItems,
    currentExcelFile,
  ];
}
