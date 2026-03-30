import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/models/purchase_order_receiver_model.dart';
import 'package:savvy_stock/features/sales/sales_order/detail/model/sales_order_detail.dart';
import 'package:savvy_stock/features/stock/item_locations/models/item_location_filters.dart';
import 'package:savvy_stock/features/stock/item_locations/models/item_locations_model.dart';

// Events
abstract class ItemLocationsEvent extends Equatable {
  const ItemLocationsEvent();

  @override
  List<Object?> get props => [];
}

class LoadLazyItemLocations extends ItemLocationsEvent {
  final int companyId;
  final int page;
  final int pageSize;
  final String? sortBy;
  final bool sortAscending;

  const LoadLazyItemLocations({
    required this.companyId,
    this.page = 1,
    this.pageSize = 10,
    this.sortBy,
    this.sortAscending = true,
  });

  @override
  List<Object?> get props => [companyId, page, pageSize, sortBy, sortAscending];
}

class LoadMoreLazyItemLocations extends ItemLocationsEvent {}

class FilterLazyItemLocations extends ItemLocationsEvent {
  final ItemLocationFilters filters;
  const FilterLazyItemLocations(this.filters);

  @override
  List<Object?> get props => [filters];
}

class ClearLazyItemLocationsFilters extends ItemLocationsEvent {}

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

class LoadItemLocationsForBranch extends ItemLocationsEvent {
  final int companyId;
  final int branchId;
  const LoadItemLocationsForBranch({
    required this.companyId,
    required this.branchId,
  });

  @override
  List<Object> get props => [companyId, branchId];
}

class LoadItemLocationsByItemNumber extends ItemLocationsEvent {
  final int companyId;
  final int itemId;
  const LoadItemLocationsByItemNumber({
    required this.companyId,
    required this.itemId,
  });

  @override
  List<Object> get props => [companyId, itemId];
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
  final PurchaseOrderReceiver? por;
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
