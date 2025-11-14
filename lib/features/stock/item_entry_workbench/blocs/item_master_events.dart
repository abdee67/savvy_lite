import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:savvy_stock/features/stock/item_entry_workbench/models/item_master_model.dart';

@immutable
abstract class ItemMasterEvent {
  const ItemMasterEvent();
}

// ========== CORE CRUD OPERATIONS ==========
class LoadItemMasters extends ItemMasterEvent {
  final int? companyCategoryId;

  const LoadItemMasters(this.companyCategoryId);
}

class CreateItemMaster extends ItemMasterEvent {
  final ItemMaster item;

  const CreateItemMaster(this.item);
}

class UpdateItemMaster extends ItemMasterEvent {
  final ItemMaster item;

  const UpdateItemMaster(this.item);
}

class DeleteItemMaster extends ItemMasterEvent {
  final ItemMaster item;

  const DeleteItemMaster(this.item);
}

class DeleteSelectedItemMasters extends ItemMasterEvent {
  final List<ItemMaster> items;

  const DeleteSelectedItemMasters(this.items);
}

// ========== PREPARATION OPERATIONS ==========
class PrepareCreate extends ItemMasterEvent {
  const PrepareCreate();
}

class PrepareCopy extends ItemMasterEvent {
  const PrepareCopy();
}

class PrepareCreateInCreate extends ItemMasterEvent {
  const PrepareCreateInCreate();
}

class PrepareCreate1 extends ItemMasterEvent {
  const PrepareCreate1();
}

class PrepareCreateInEdit extends ItemMasterEvent {
  const PrepareCreateInEdit();
}

class PrepareEdit extends ItemMasterEvent {
  const PrepareEdit();
}

// ========== COMPLEX BUSINESS OPERATIONS ==========
class SaveRow extends ItemMasterEvent {
  const SaveRow();
}

class SaveInEdit extends ItemMasterEvent {
  const SaveInEdit();
}

class CreateInEdit extends ItemMasterEvent {
  const CreateInEdit();
}

class RemoveInCreate extends ItemMasterEvent {
  final ItemMaster item;

  const RemoveInCreate(this.item);
}

class RemoveInEdit extends ItemMasterEvent {
  final ItemMaster item;

  const RemoveInEdit(this.item);
}

class RemoveRecord extends ItemMasterEvent {
  final ItemMaster item;

  const RemoveRecord(this.item);
}

class CancelUpdate extends ItemMasterEvent {
  const CancelUpdate();
}

class CancelCreate extends ItemMasterEvent {
  const CancelCreate();
}

class DiscardChanges extends ItemMasterEvent {
  const DiscardChanges();
}

class RefreshList extends ItemMasterEvent {
  const RefreshList();
}

// ========== DATA MIGRATION OPERATIONS ==========
class ApplyMigration extends ItemMasterEvent {
  final ItemMaster item;

  const ApplyMigration(this.item);
}

class DataMigrationStock extends ItemMasterEvent {
  const DataMigrationStock();
}

class PrepareDataMigrationImport extends ItemMasterEvent {
  final String theClass;
  final String theModule;

  const PrepareDataMigrationImport(this.theClass, this.theModule);
}
// Add these events to your existing item_master_events.dart

// Excel Upload Events
class PrepareExcelTemplate extends ItemMasterEvent {
  final String className;
  final String moduleName;

  const PrepareExcelTemplate(this.className, this.moduleName);

  @override
  List<Object?> get props => [className, moduleName];
}

class ProcessExcelFile extends ItemMasterEvent {
  final File excelFile;
  final List<String> columns;
  final Map<String, String> columnLabels;

  const ProcessExcelFile({
    required this.excelFile,
    required this.columns,
    required this.columnLabels,
  });

  @override
  List<Object?> get props => [excelFile, columns, columnLabels];
}

class UpdateMigrationColumns extends ItemMasterEvent {
  final List<String> columns;
  final Map<String, String> columnLabels;

  const UpdateMigrationColumns({
    required this.columns,
    required this.columnLabels,
  });

  @override
  List<Object?> get props => [columns, columnLabels];
}

class SetColumnVisibility extends ItemMasterEvent {
  final List<bool> columnVisibility;

  const SetColumnVisibility(this.columnVisibility);

  @override
  List<Object?> get props => [columnVisibility];
}

class FilterItemEntry extends ItemMasterEvent {
  const FilterItemEntry();
}

class SettingDefaults extends ItemMasterEvent {
  final ItemMaster item;

  const SettingDefaults(this.item);
}

// ========== FILTER AND SEARCH OPERATIONS ==========
class SearchItemMasters extends ItemMasterEvent {
  final String query;
  final int? companyCategoryId;

  const SearchItemMasters(this.query, {this.companyCategoryId});
}

class GetItemsAvailableSelectMany extends ItemMasterEvent {
  final int companyCategoryId;

  const GetItemsAvailableSelectMany(this.companyCategoryId);
}

class GetItemsAvailableSelectOne extends ItemMasterEvent {
  const GetItemsAvailableSelectOne();
}

class GetItemDescriptions extends ItemMasterEvent {
  final int companyCategoryId;

  const GetItemDescriptions(this.companyCategoryId);
}

class GetLocationCategories extends ItemMasterEvent {
  final String locCode;

  const GetLocationCategories(this.locCode);
}

// ========== STATE MANAGEMENT OPERATIONS ==========
class UpdateSelected extends ItemMasterEvent {
  final ItemMaster? selected;
  final ItemMaster? selected1;
  final ItemMaster? selected2;

  const UpdateSelected({this.selected, this.selected1, this.selected2});
}

class UpdateMultiSelection extends ItemMasterEvent {
  final List<ItemMaster> multiSelectionItems;

  const UpdateMultiSelection(this.multiSelectionItems);
}

class UpdateCreateItems extends ItemMasterEvent {
  final List<ItemMaster> createItems;

  const UpdateCreateItems(this.createItems);
}

class UpdateEditItems extends ItemMasterEvent {
  final List<ItemMaster> editItems;

  const UpdateEditItems(this.editItems);
}

class UpdateFilteredValues extends ItemMasterEvent {
  final List<ItemMaster> filteredValues;

  const UpdateFilteredValues(this.filteredValues);
}

class UpdateFirst extends ItemMasterEvent {
  final int first;

  const UpdateFirst(this.first);
}

class SaveAndClose extends ItemMasterEvent {
  final String linkName;

  const SaveAndClose(this.linkName);
}

class SaveAndAddNew extends ItemMasterEvent {
  final String linkName;

  const SaveAndAddNew(this.linkName);
}

class SaveAndAddContinue extends ItemMasterEvent {
  final String linkName;

  const SaveAndAddContinue(this.linkName);
}

class CheckDuplicate extends ItemMasterEvent {
  final ItemMaster item;

  const CheckDuplicate(this.item);
}
