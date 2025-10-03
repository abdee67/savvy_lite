import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:savvy_stock/features/stock/item_entry/models/item_entry_model.dart';

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

class SearchItems extends ItemEntryEvent {
  final String query;
  const SearchItems(this.query);

  @override
  List<Object> get props => [query];
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
