import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/models/purchase_order_receiver_model.dart';
import 'package:savvy_stock/features/sales/sales_order/detail/model/sales_order_detail.dart';
import 'package:savvy_stock/features/stock/item_locations/models/item_locations_model.dart';

// Events
abstract class ItemLocationsEvent extends Equatable {
  const ItemLocationsEvent();

  @override
  List<Object> get props => [];
}

class LoadItemLocations extends ItemLocationsEvent {
  final int companyId;
  const LoadItemLocations(this.companyId);

  @override
  List<Object> get props => [companyId];
}

class LoadItemLocationsByBranchAndItem extends ItemLocationsEvent {
  final int companyId;
  final int branchId;
  final int itemId;
  final int? locationId;
  const LoadItemLocationsByBranchAndItem({
    required this.companyId,
    required this.branchId,
    required this.itemId,
    this.locationId,
  });

  @override
  List<Object> get props => [companyId, branchId, itemId];
}

class CreateItemLocation extends ItemLocationsEvent {
  final ItemLocation item;
  const CreateItemLocation(this.item);

  @override
  List<Object> get props => [item];
}

class UpdateItemLocation extends ItemLocationsEvent {
  final ItemLocation item;
  const UpdateItemLocation(this.item);

  @override
  List<Object> get props => [item];
}

class DeleteItemLocation extends ItemLocationsEvent {
  final int itemId;
  final ItemLocation? deletedItem;
  final int? deletedIndex;
  const DeleteItemLocation({
    required this.itemId,
    this.deletedItem,
    this.deletedIndex,
  });

  @override
  List<Object> get props => [itemId];
}

class SearchItemLocations extends ItemLocationsEvent {
  final String query;
  const SearchItemLocations(this.query);

  @override
  List<Object> get props => [query];
}

class SelectItemLocation extends ItemLocationsEvent {
  final ItemLocation item;
  final bool isSelected;
  const SelectItemLocation(this.item, this.isSelected);

  @override
  List<Object> get props => [item, isSelected];
}

class SelectAllItemLocations extends ItemLocationsEvent {
  final List<ItemLocation> items;
  const SelectAllItemLocations(this.items);

  @override
  List<Object> get props => [items];
}

class ClearSelection extends ItemLocationsEvent {}

class DeleteSelectedItemLocations extends ItemLocationsEvent {
  final List<int> selectedItems;
  final List<ItemLocation> deletedItems;
  final List<int> deletedIndexes;
  const DeleteSelectedItemLocations({
    required this.selectedItems,
    required this.deletedItems,
    required this.deletedIndexes,
  });

  @override
  List<Object> get props => [selectedItems, deletedItems, deletedIndexes];
}

class SaveItemLocationRow extends ItemLocationsEvent {
  final ItemLocation item;
  final String action;
  final int? transactionNumber;
  final String? remark;
  final PurchaseOrderReceiverModel? por;
  final SalesOrderDetail? soD;
  const SaveItemLocationRow(
    this.item, {
    this.action = 'A',
    this.transactionNumber,
    this.remark,
    this.por,
    this.soD,
  });

  @override
  List<Object> get props => [item, action];
}
