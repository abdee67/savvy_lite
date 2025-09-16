import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/models/item_in_store.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/models/items.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/models/confirmed_item.dart';

@immutable
abstract class ItemEntryEvent extends Equatable {
  const ItemEntryEvent();

  @override
  List<Object> get props => [];
}

class LoadItemsAndStores extends ItemEntryEvent {}

class SelectItem extends ItemEntryEvent {
  final int index;
  final Item? item;

  const SelectItem({required this.index, this.item});

  @override
  List<Object> get props => [index, item ?? Item.empty];
}

class SelectStore extends ItemEntryEvent {
  final int index;
  final ItemInStore? itemInStore;

  const SelectStore({required this.index, this.itemInStore});

  @override
  List<Object> get props => [index, itemInStore ?? ItemInStore.empty];
}

class UpdateQuantity extends ItemEntryEvent {
  final int index;
  final double quantity;

  const UpdateQuantity({required this.index, required this.quantity});

  @override
  List<Object> get props => [index, quantity];
}

class UpdatePrice extends ItemEntryEvent {
  final int index;
  final double price;

  const UpdatePrice({required this.index, required this.price});

  @override
  List<Object> get props => [index, price];
}

class AddNewItem extends ItemEntryEvent {}

class DeleteConfirmedItem extends ItemEntryEvent {
  final int index;
  const DeleteConfirmedItem({required this.index});

  @override
  List<Object> get props => [index];
}

class UndoDelete extends ItemEntryEvent {
  final ConfirmedItem deletedItem;
  final int deletedIndex;

  const UndoDelete({required this.deletedItem, required this.deletedIndex});
}

class MoveToEdit extends ItemEntryEvent {
  final int confirmedIndex;
  final int selectedIndex; // Optional: specify where to place it

  const MoveToEdit({required this.confirmedIndex, this.selectedIndex = -1});

  @override
  List<Object> get props => [confirmedIndex, selectedIndex];
}

class ConfirmOrder extends ItemEntryEvent {}

class ToggleBarcode extends ItemEntryEvent {
  final bool useBarcode;

  const ToggleBarcode({required this.useBarcode});

  @override
  List<Object> get props => [useBarcode];
}

class AddBarcodeItems extends ItemEntryEvent {
  final List<ConfirmedItem> items;

  const AddBarcodeItems({required this.items});

  @override
  List<Object> get props => [items];
}

class ScanBarcode extends ItemEntryEvent {
  final String barcode;

  const ScanBarcode({required this.barcode});

  @override
  List<Object> get props => [barcode];
}

class ClearSelectedItems extends ItemEntryEvent {}
