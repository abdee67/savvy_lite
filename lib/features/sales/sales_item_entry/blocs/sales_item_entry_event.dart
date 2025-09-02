import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/models/items.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/models/confirmed_item.dart';
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

class EditConfirmedItem extends ItemEntryEvent {
  final int index;
  final double newQuantity;

  const EditConfirmedItem({required this.index, required this.newQuantity});

  @override
  List<Object> get props => [index, newQuantity];
}

class DeleteConfirmedItem extends ItemEntryEvent {
  final int index;

  const DeleteConfirmedItem({required this.index});

  @override
  List<Object> get props => [index];
}

class SelectConfirmedItem extends ItemEntryEvent {
  final int index;
  final bool isMultiple;

  const SelectConfirmedItem({required this.index, this.isMultiple = false});

  @override
  List<Object> get props => [index, isMultiple];
}

class SelectAllConfirmedItem extends ItemEntryEvent {
  const SelectAllConfirmedItem();

  @override
  List<Object> get props => [];
}

class UnSelectConfirmedItem extends ItemEntryEvent {
  final int index;

  const UnSelectConfirmedItem({required this.index});

  @override
  List<Object> get props => [index];
}

class ClearSelectedConfirmedItems extends ItemEntryEvent {}

class MoveSelectedToEdit extends ItemEntryEvent {
  final int index;

  const MoveSelectedToEdit({required this.index});

  @override
  List<Object> get props => [index];
}

class MoveSelectedToDelete extends ItemEntryEvent {
  final int index;
  final bool isMultiple;

  const MoveSelectedToDelete({required this.index, this.isMultiple = false});

  @override
  List<Object> get props => [index, isMultiple];
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
