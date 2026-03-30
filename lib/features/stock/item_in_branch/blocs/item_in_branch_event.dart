import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/models/purchase_order_receiver_model.dart';
import 'package:savvy_stock/features/sales/sales_order/detail/model/sales_order_detail.dart';
import 'package:savvy_stock/features/stock/item_in_branch/models/available_items_in_branch_filter.dart';
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

// Complex business operations (from Java controller)
class SaveRow extends ItemInBranchEvent {
  final List<ItemInBranchModel> items;

  const SaveRow(this.items);
}

class SaveInEdit extends ItemInBranchEvent {
  final ItemInBranchModel item;
  final String? transactionType;
  final int? transactionNumber;
  final String? remark;

  const SaveInEdit(
    this.item, {
    this.transactionType = 'A',
    this.transactionNumber,
    this.remark,
  });
}

class CreateInEdit extends ItemInBranchEvent {
  final ItemInBranchModel item;

  const CreateInEdit(this.item);
}

class RemoveInCreate extends ItemInBranchEvent {
  final ItemInBranchModel item;

  const RemoveInCreate(this.item);
}

class RemoveInEdit extends ItemInBranchEvent {
  final ItemInBranchModel item;

  const RemoveInEdit(this.item);
}

// Advanced operation events
class LoadItemBranchByItemAndBranch extends ItemInBranchEvent {
  final int itemNumber;
  final int branchId;

  const LoadItemBranchByItemAndBranch(this.itemNumber, this.branchId);
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

// Stock management events

class UpdateStockForSalesOrderVoid extends ItemInBranchEvent {
  final SalesOrderDetail salesOrderDetail;

  const UpdateStockForSalesOrderVoid(this.salesOrderDetail);
}

class UpdateStockForPurchaseOrder extends ItemInBranchEvent {
  final PurchaseOrderReceiver purchaseOrderReceiver;

  const UpdateStockForPurchaseOrder(this.purchaseOrderReceiver);
}

class SetDefaultPrice extends ItemInBranchEvent {
  final ItemInBranchModel item;

  const SetDefaultPrice(this.item);
}

// Filter events
class FilterItemsInBranch extends ItemInBranchEvent {}

class FilterSelectedItems extends ItemInBranchEvent {
  final int itemNumber;

  const FilterSelectedItems(this.itemNumber);
}

class ClearDataForFilter extends ItemInBranchEvent {}

class SendNotification extends ItemInBranchEvent {
  final ItemInBranchModel item;

  const SendNotification(this.item);
}

class LoadItemInBranchReport extends ItemInBranchEvent {
  final int companyId;
  final int page;
  final int pageSize;

  const LoadItemInBranchReport({
    required this.companyId,
    this.page = 1,
    this.pageSize = 20,
  });

  @override
  List<Object> get props => [companyId, page, pageSize];
}

class LoadMoreItemInBranchReport extends ItemInBranchEvent {}

class ExportItemInBranchReportToExcel extends ItemInBranchEvent {
  const ExportItemInBranchReportToExcel();

  @override
  List<Object> get props => [];
}

class ExportItemInBranchReportToPDF extends ItemInBranchEvent {
  const ExportItemInBranchReportToPDF();

  @override
  List<Object> get props => [];
}

class LoadAvailableItemsInBranch extends ItemInBranchEvent {
  final int companyId;
  final int page;
  final int pageSize;
  final String? sortBy;
  final bool sortAscending;

  const LoadAvailableItemsInBranch({
    required this.companyId,
    this.page = 1,
    this.pageSize = 10,
    this.sortBy,
    this.sortAscending = true,
  });

  @override
  List<Object> get props => [companyId, page, pageSize, sortBy!, sortAscending];
}

class LoadMoreAvailableItemsInBranch extends ItemInBranchEvent {}

class FilterAvailableItemsInBranch extends ItemInBranchEvent {
  final AvailableItemsInBranchFilter filters;
  const FilterAvailableItemsInBranch(this.filters);

  @override
  List<Object> get props => [filters];
}

class ClearAvailableItemsInBranchFilters extends ItemInBranchEvent {}
