import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:savvy_stock/features/stock/item_entry/models/item_entry_model.dart';
import 'package:savvy_stock/features/stock/item_entry/models/item_report_filter.model.dart';

@immutable
abstract class ItemEntryEvent extends Equatable {
  const ItemEntryEvent();

  @override
  List<Object> get props => [];
}

class LoadItems extends ItemEntryEvent {
  final int companyId;
  const LoadItems(this.companyId);

  @override
  List<Object> get props => [companyId];
}

class CreateItem extends ItemEntryEvent {
  final ItemEntryModel item;
  const CreateItem(this.item);

  @override
  List<Object> get props => [item];
}

class UpdateItem extends ItemEntryEvent {
  final ItemEntryModel item;
  const UpdateItem(this.item);

  @override
  List<Object> get props => [item];
}

class DeleteItem extends ItemEntryEvent {
  final int itemId;
  final ItemEntryModel deletedItem;
  final int deletedIndex;

  const DeleteItem({
    required this.itemId,
    required this.deletedItem,
    required this.deletedIndex,
  });

  @override
  List<Object> get props => [itemId, deletedItem, deletedIndex];
}

// Filter and search events
class FilterItemList extends ItemEntryEvent {
  const FilterItemList();
}

class SearchItems extends ItemEntryEvent {
  final String query;
  const SearchItems(this.query);

  @override
  List<Object> get props => [query];
}

class GenerateBarcodes extends ItemEntryEvent {
  const GenerateBarcodes();
}

class SelectItem extends ItemEntryEvent {
  final ItemEntryModel item;
  final bool isSelected;
  const SelectItem(this.item, this.isSelected);

  @override
  List<Object> get props => [item, isSelected];
}

class SelectAllItems extends ItemEntryEvent {
  final List<ItemEntryModel> items;
  const SelectAllItems(this.items);

  @override
  List<Object> get props => [items];
}

class ClearSelection extends ItemEntryEvent {
  const ClearSelection();

  @override
  List<Object> get props => [];
}

class SetItemForm extends ItemEntryEvent {
  final ItemEntryModel item;
  const SetItemForm(this.item);

  @override
  List<Object> get props => [item];
}

class DeleteSelectedItems extends ItemEntryEvent {
  final List<int> selectedItems;
  final List<ItemEntryModel> deletedItems;
  final List<int> deletedIndexes;

  const DeleteSelectedItems({
    required this.selectedItems,
    required this.deletedItems,
    required this.deletedIndexes,
  });

  @override
  List<Object> get props => [selectedItems, deletedItems, deletedIndexes];
}

class UndoDelete extends ItemEntryEvent {
  final List<ItemEntryModel> deletedItems;
  final List<int> deletedIndexes;

  const UndoDelete({required this.deletedItems, required this.deletedIndexes});

  @override
  List<Object> get props => [deletedItems, deletedIndexes];
}

class ShowItemDetail extends ItemEntryEvent {
  final ItemEntryModel item;
  const ShowItemDetail(this.item);

  @override
  List<Object> get props => [item];
}

class HideItemDetail extends ItemEntryEvent {
  const HideItemDetail();
}

class ExportItem extends ItemEntryEvent {
  final List<ItemEntryModel> itemsToExport;
  const ExportItem(this.itemsToExport);

  @override
  List<Object> get props => [itemsToExport];
}

class ExportSingleItem extends ItemEntryEvent {
  final ItemEntryModel itemToExport;
  const ExportSingleItem(this.itemToExport);

  @override
  List<Object> get props => [itemToExport];
}

// Preparation events (from Java controller)
class PrepareCreate extends ItemEntryEvent {}

class PrepareCopy extends ItemEntryEvent {
  final ItemEntryModel itemToCopy;

  const PrepareCopy(this.itemToCopy);
}

class PrepareCreateInCreate extends ItemEntryEvent {
  const PrepareCreateInCreate();
}

class PrepareCreateInCreate1 extends ItemEntryEvent {
  const PrepareCreateInCreate1();
}

class PrepareCreateInCreateFormain extends ItemEntryEvent {
  const PrepareCreateInCreateFormain();
}

class PrepareCreateInEdit extends ItemEntryEvent {
  const PrepareCreateInEdit();
}

class PrepareEdit extends ItemEntryEvent {
  const PrepareEdit();
}

class PrepareEdit1 extends ItemEntryEvent {
  final int item;

  const PrepareEdit1(this.item);
}

// Complex business operations (from Java controller)
class SaveRow extends ItemEntryEvent {
  final ItemEntryModel item;

  const SaveRow(this.item);
}

class SaveRow1 extends ItemEntryEvent {
  final ItemEntryModel item;

  const SaveRow1(this.item);
}

class SaveRowMain extends ItemEntryEvent {
  final ItemEntryModel item;

  const SaveRowMain(this.item);
}

class SaveInEdit extends ItemEntryEvent {
  final List<ItemEntryModel> items;

  const SaveInEdit(this.items);
}

class CreateInEdit extends ItemEntryEvent {
  const CreateInEdit();
}

class RemoveInCreate extends ItemEntryEvent {
  final ItemEntryModel item;

  const RemoveInCreate(this.item);
}

class RemoveInEdit extends ItemEntryEvent {
  final ItemEntryModel item;

  const RemoveInEdit(this.item);
}

class RemoveRecord extends ItemEntryEvent {
  final ItemEntryModel item;

  const RemoveRecord(this.item);
}

class CancelUpdate extends ItemEntryEvent {
  const CancelUpdate();
}

class CancelCreate extends ItemEntryEvent {
  const CancelCreate();
}

class DiscardChanges extends ItemEntryEvent {
  const DiscardChanges();
}

class RefreshList extends ItemEntryEvent {
  const RefreshList();
}

class RefreshList1 extends ItemEntryEvent {
  const RefreshList1();
}

// Navigation events
class SaveAndClose extends ItemEntryEvent {
  final String linkName;

  const SaveAndClose(this.linkName);
}

class SaveAndAddNew extends ItemEntryEvent {
  final String linkName;

  const SaveAndAddNew(this.linkName);
}

class SaveAndAddContinue extends ItemEntryEvent {
  final String linkName;

  const SaveAndAddContinue(this.linkName);
}

class LoadItemReport extends ItemEntryEvent {
  final int companyId;
  final ItemReportFilters filters;
  final int page;
  final int pageSize;

  const LoadItemReport({
    required this.companyId,
    required this.filters,
    this.page = 1,
    this.pageSize = 20,
  });

  @override
  List<Object> get props => [companyId, filters, page, pageSize];
}

class LoadMoreItemReport extends ItemEntryEvent {}

class UpdateItemReportFilters extends ItemEntryEvent {
  final ItemReportFilters filters;

  const UpdateItemReportFilters(this.filters);

  @override
  List<Object> get props => [filters];
}

class ClearItemReportFilters extends ItemEntryEvent {}

class ExportItemReportToExcel extends ItemEntryEvent {
  final ItemReportFilters filters;

  const ExportItemReportToExcel(this.filters);

  @override
  List<Object> get props => [filters];
}

class ExportItemReportToPDF extends ItemEntryEvent {
  final ItemReportFilters filters;

  const ExportItemReportToPDF(this.filters);

  @override
  List<Object> get props => [filters];
}
