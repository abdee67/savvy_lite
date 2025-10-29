// bloc/item_uom_conversion_event.dart
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:savvy_stock/features/stock/item_UoM_conversions/models/item_UoM_conversions_model.dart';

@immutable
abstract class ItemUomConversionEvent extends Equatable {
  const ItemUomConversionEvent();
}

class LoadItemUomConversions extends ItemUomConversionEvent {
  final int companyId;
  const LoadItemUomConversions(this.companyId);
  @override
  List<Object> get props => [companyId];
}

class SaveItemUomConversion extends ItemUomConversionEvent {
  final ItemUomConversion item;
  final int userId;
  const SaveItemUomConversion(this.item, this.userId);
  @override
  List<Object> get props => [item, userId];
}

class UpdateItemUomConversion extends ItemUomConversionEvent {
  final ItemUomConversion item;
  final int? userId;
  const UpdateItemUomConversion(this.item, this.userId);
  @override
  List<Object> get props => [item, userId ?? Object()];
}

class DeleteItemUomConversion extends ItemUomConversionEvent {
  final ItemUomConversion item;
  const DeleteItemUomConversion(this.item);
  @override
  List<Object> get props => [item];
}

// UI Management Events
class PrepareCreateUomConversion extends ItemUomConversionEvent {
  final int companyId;
  const PrepareCreateUomConversion(this.companyId);
  @override
  List<Object> get props => [companyId];
}

class AddToCreateList extends ItemUomConversionEvent {
  final ItemUomConversion item;
  const AddToCreateList(this.item);
  @override
  List<Object> get props => [item];
}

class RemoveFromCreateList extends ItemUomConversionEvent {
  final ItemUomConversion item;
  const RemoveFromCreateList(this.item);
  @override
  List<Object> get props => [item];
}

class SetSelectedItem extends ItemUomConversionEvent {
  final ItemUomConversion? item;
  const SetSelectedItem(this.item);
  @override
  List<Object> get props => [item ?? Object()];
}

class SetMultiSelectionItems extends ItemUomConversionEvent {
  final List<ItemUomConversion> items;
  const SetMultiSelectionItems(this.items);
  @override
  List<Object> get props => [items];
}

class ClearCreateList extends ItemUomConversionEvent {
  @override
  List<Object> get props => [];
}

class CalculateUomConversion extends ItemUomConversionEvent {
  final int itemId;
  final int fromUomId;
  final int toUomId;
  final int companyId;
  const CalculateUomConversion({
    required this.itemId,
    required this.fromUomId,
    required this.toUomId,
    required this.companyId,
  });
  @override
  List<Object> get props => [itemId, fromUomId, toUomId, companyId];
}
class ValidateStructure extends ItemUomConversionEvent {
  final List<ItemUomConversion> createItems;
  final ItemUomConversion? currentItem;
  const ValidateStructure({
    required this.createItems,
    this.currentItem,
  });

  @override
  List<Object> get props => [createItems];
}

class CheckDuplication extends ItemUomConversionEvent {
  final ItemUomConversion item;
  const CheckDuplication(this.item);

  @override
  List<Object> get props => [item];
}
