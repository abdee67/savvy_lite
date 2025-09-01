import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/models/items.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/models/confirmed_items.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/models/stores.dart';

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
  final Store? store;

  const SelectStore({required this.index, this.store});

  @override
  List<Object> get props => [index, store ?? Store.empty];
}

class UpdateQuantity extends ItemEntryEvent {
  final int index;
  final double quantity;

  const UpdateQuantity({required this.index, required this.quantity});

  @override
  List<Object> get props => [index, quantity];
}

class AddNewItem extends ItemEntryEvent {}

class RemoveItem extends ItemEntryEvent {
  final int index;

  const RemoveItem({required this.index});

  @override
  List<Object> get props => [index];
}

class EditItem extends ItemEntryEvent {
  final int index;
  final Item? item;
  final Store? store;
  final double quantity;

  const EditItem({
    required this.index,
    this.item,
    this.store,
    required this.quantity,
  });

  @override
  List<Object> get props => [
    index,
    item ?? Item.empty,
    store ?? Store.empty,
    quantity,
  ];
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

class ClearSelectedItems extends ItemEntryEvent {}
