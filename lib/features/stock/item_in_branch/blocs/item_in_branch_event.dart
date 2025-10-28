import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:savvy_stock/features/stock/item_in_branch/models/item_in_branch_model.dart';

@immutable
abstract class ItemInBranchEvent extends Equatable {
  const ItemInBranchEvent();

  @override
  List<Object> get props => [];
}

class LoadItemsFromBranch extends ItemInBranchEvent {
  final int companyId;
  final int? branchId;
  const LoadItemsFromBranch(this.companyId, {this.branchId});

  @override
  List<Object> get props => [companyId, branchId ?? -1];
}

class AddItemToBranch extends ItemInBranchEvent {
  final ItemInBranchModel item;
  const AddItemToBranch(this.item);

  @override
  List<Object> get props => [item];
}

class UpdateItem extends ItemInBranchEvent {
  final ItemInBranchModel item;
  const UpdateItem(this.item);

  @override
  List<Object> get props => [item];
}

class DeleteItemFromBranch extends ItemInBranchEvent {
  final int itemId;
  final ItemInBranchModel deletedItem;
  final int deletedIndex;

  const DeleteItemFromBranch({
    required this.itemId,
    required this.deletedItem,
    required this.deletedIndex,
  });

  @override
  List<Object> get props => [itemId, deletedItem, deletedIndex];
}

class SearchItemsFromBranch extends ItemInBranchEvent {
  final String query;
  const SearchItemsFromBranch(this.query);

  @override
  List<Object> get props => [query];
}

class SelectItemFromBranch extends ItemInBranchEvent {
  final ItemInBranchModel item;
  final bool isSelected;
  const SelectItemFromBranch(this.item, this.isSelected);

  @override
  List<Object> get props => [item, isSelected];
}

class SelectAllItemsFromBranch extends ItemInBranchEvent {
  final List<ItemInBranchModel> items;
  const SelectAllItemsFromBranch(this.items);

  @override
  List<Object> get props => [items];
}

class ClearSelectionFromBranch extends ItemInBranchEvent {
  const ClearSelectionFromBranch();

  @override
  List<Object> get props => [];
}

class SetItemFormFromBranch extends ItemInBranchEvent {
  final ItemInBranchModel item;
  const SetItemFormFromBranch(this.item);

  @override
  List<Object> get props => [item];
}

class DeleteSelectedItemsFromBranch extends ItemInBranchEvent {
  final List<int> selectedItems;
  final List<ItemInBranchModel> deletedItems;
  final List<int> deletedIndexes;

  const DeleteSelectedItemsFromBranch({
    required this.selectedItems,
    required this.deletedItems,
    required this.deletedIndexes,
  });

  @override
  List<Object> get props => [selectedItems, deletedItems, deletedIndexes];
}

class UndoDeleteFromBranch extends ItemInBranchEvent {
  final List<ItemInBranchModel> deletedItems;
  final List<int> deletedIndexes;

  const UndoDeleteFromBranch({
    required this.deletedItems,
    required this.deletedIndexes,
  });

  @override
  List<Object> get props => [deletedItems, deletedIndexes];
}

class ShowItemDetailFromBranch extends ItemInBranchEvent {
  final ItemInBranchModel item;
  const ShowItemDetailFromBranch(this.item);

  @override
  List<Object> get props => [item];
}

class HideItemDetailFromBranch extends ItemInBranchEvent {
  const HideItemDetailFromBranch();
}

class ExportItemFromBranch extends ItemInBranchEvent {
  final List<ItemInBranchModel> itemsToExport;
  const ExportItemFromBranch(this.itemsToExport);

  @override
  List<Object> get props => [itemsToExport];
}

class ExportSingleItemFromBranch extends ItemInBranchEvent {
  final ItemInBranchModel itemToExport;
  const ExportSingleItemFromBranch(this.itemToExport);

  @override
  List<Object> get props => [itemToExport];
}
// Advanced operation events
class LoadItemBranchByItemAndBranch extends ItemInBranchEvent {
  final int itemNumber;
  final int branchId;

  LoadItemBranchByItemAndBranch(this.itemNumber, this.branchId);
}

class UpdateItemBranchUnitPrice extends ItemInBranchEvent {
  final int itemBranchId;
  final double newPrice;

 const UpdateItemBranchUnitPrice(this.itemBranchId, this.newPrice);
  @override
  List<Object> get props => [itemBranchId, newPrice];
}

class LoadItemsInBranchByItem extends ItemInBranchEvent {
  final int itemNumber;

 const LoadItemsInBranchByItem(this.itemNumber);
  @override
  List<Object> get props => [itemNumber];
}

class LoadItemsInBranchByBranch extends ItemInBranchEvent {
  final int branchId;

 const LoadItemsInBranchByBranch(this.branchId);
  @override
  List<Object> get props => [branchId];
}

class LoadLowStockItems extends ItemInBranchEvent {
  final int? branchId;

 const LoadLowStockItems({this.branchId});
  @override
  List<Object> get props => [branchId ?? -1];
}

class LoadOutOfStockItems extends ItemInBranchEvent {
  final int? branchId;

 const LoadOutOfStockItems({this.branchId});
  @override
  List<Object> get props => [branchId ?? -1];
}

class UpdateItemQuantity extends ItemInBranchEvent {
  final int itemId;
  final double quantity;

 const UpdateItemQuantity(this.itemId, this.quantity);
  @override
  List<Object> get props => [itemId, quantity];
}
