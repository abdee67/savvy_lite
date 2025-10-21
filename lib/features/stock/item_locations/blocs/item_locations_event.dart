import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:savvy_stock/features/stock/item_locations/models/item_locations_model.dart';

@immutable
abstract class ItemLocationsEvent extends Equatable {
  const ItemLocationsEvent();

  @override
  List<Object> get props => [];
}

class LoadItems extends ItemLocationsEvent {
  final int companyId;
  const LoadItems(this.companyId);

  @override
  List<Object> get props => [companyId];
}

class LoadItemLocationsByBranchAndItem extends ItemLocationsEvent {
  final int branchId;
  final int itemId;
  final int companyId;
  const LoadItemLocationsByBranchAndItem({
    required this.branchId,
    required this.itemId,
    required this.companyId,
  });

  @override
  List<Object> get props => [branchId, itemId];
}

class CreateItem extends ItemLocationsEvent {
  final ItemLocation item;
  const CreateItem(this.item);

  @override
  List<Object> get props => [item];
}

class UpdateItem extends ItemLocationsEvent {
  final ItemLocation item;
  const UpdateItem(this.item);

  @override
  List<Object> get props => [item];
}

class DeleteItem extends ItemLocationsEvent {
  final int itemId;
  final ItemLocation deletedItem;
  final int deletedIndex;

  const DeleteItem({
    required this.itemId,
    required this.deletedItem,
    required this.deletedIndex,
  });

  @override
  List<Object> get props => [itemId, deletedItem, deletedIndex];
}

class SearchItems extends ItemLocationsEvent {
  final String query;
  const SearchItems(this.query);

  @override
  List<Object> get props => [query];
}

class SelectItem extends ItemLocationsEvent {
  final ItemLocation item;
  final bool isSelected;
  const SelectItem(this.item, this.isSelected);

  @override
  List<Object> get props => [item, isSelected];
}

class SelectAllItems extends ItemLocationsEvent {
  final List<ItemLocation> items;
  const SelectAllItems(this.items);

  @override
  List<Object> get props => [items];
}

class ClearSelection extends ItemLocationsEvent {
  const ClearSelection();

  @override
  List<Object> get props => [];
}

class DeleteSelectedItems extends ItemLocationsEvent {
  final List<int> selectedItems;
  final List<ItemLocation> deletedItems;
  final List<int> deletedIndexes;

  const DeleteSelectedItems({
    required this.selectedItems,
    required this.deletedItems,
    required this.deletedIndexes,
  });

  @override
  List<Object> get props => [selectedItems, deletedItems, deletedIndexes];
}
