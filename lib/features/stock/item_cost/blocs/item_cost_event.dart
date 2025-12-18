// bloc/item_cost_event.dart
import 'package:flutter/foundation.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/models/purchase_order_header_model.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/models/purchase_order_receiver_model.dart';
import 'package:savvy_stock/features/stock/item_cost/models/item_cost_model.dart';

@immutable
abstract class ItemCostEvent {}

// Initialization events
class LoadItemCosts extends ItemCostEvent {}

class RefreshItemCosts extends ItemCostEvent {}

// Selection events
class SelectItemCost extends ItemCostEvent {
  final ItemCost itemCost;
  SelectItemCost(this.itemCost);
}

class SelectMultipleItemCosts extends ItemCostEvent {
  final List<ItemCost> itemCosts;
  SelectMultipleItemCosts(this.itemCosts);
}

class ClearSelection extends ItemCostEvent {}

// Creation events
class PrepareCreate extends ItemCostEvent {}

class PrepareCopy extends ItemCostEvent {
  final ItemCost itemCostToCopy;
  PrepareCopy(this.itemCostToCopy);
}

class PrepareCreateInCreate extends ItemCostEvent {}

class PrepareCreateInEdit extends ItemCostEvent {}

class PrepareEdit extends ItemCostEvent {}

// CRUD operations
class SaveItemCost extends ItemCostEvent {
  final List<ItemCost> items;
  SaveItemCost(this.items);
}

class SaveRow extends ItemCostEvent {
  final List<ItemCost> items;
  SaveRow(this.items);
}

class SaveInEdit extends ItemCostEvent {
  final List<ItemCost> items;
  SaveInEdit(this.items);
}

class CreateInEdit extends ItemCostEvent {
  final ItemCost itemCost;
  CreateInEdit(this.itemCost);
}

class DeleteItemCost extends ItemCostEvent {
  final ItemCost itemCost;
  DeleteItemCost(this.itemCost);
}

class DeleteMultipleItemCosts extends ItemCostEvent {
  final List<ItemCost> itemCosts;
  DeleteMultipleItemCosts(this.itemCosts);
}

class RemoveInCreate extends ItemCostEvent {
  final ItemCost itemCost;
  RemoveInCreate(this.itemCost);
}

class RemoveInEdit extends ItemCostEvent {
  final ItemCost itemCost;
  RemoveInEdit(this.itemCost);
}

// Navigation events
class SaveAndClose extends ItemCostEvent {
  final String linkName;
  SaveAndClose(this.linkName);
}

class SaveAndAddNew extends ItemCostEvent {
  final String linkName;
  SaveAndAddNew(this.linkName);
}

class SaveAndAddContinue extends ItemCostEvent {
  final String linkName;
  SaveAndAddContinue(this.linkName);
}

// Business logic events
class UpdateItemCosts extends ItemCostEvent {
  final PurchaseOrderHeader purchaseOrderHeader;
  UpdateItemCosts(this.purchaseOrderHeader);
}

/*class UpdateItemCostsForItemMaster extends ItemCostEvent {
  final ItemMaster itemMaster;
  final ItemEntryModel item;
  UpdateItemCostsForItemMaster(this.itemMaster, this.item);
}
*/
class UpdateUnitPrice extends ItemCostEvent {
  final ItemCost itemCost;
  final PurchaseOrderReceiver purchaseOrderReceiver;
  UpdateUnitPrice(this.itemCost, this.purchaseOrderReceiver);
}

// Filter events
class FilterItemCosts extends ItemCostEvent {
  final List<ItemCost> filteredItems;
  FilterItemCosts(this.filteredItems);
}

//report events
class LoadItemCostReport extends ItemCostEvent {
  final int companyId;
  final int page;
  final int pageSize;

  LoadItemCostReport({
    required this.companyId,
    this.page = 1,
    this.pageSize = 20,
  });
}

class UpdateItemCostReportFilters extends ItemCostEvent {
  UpdateItemCostReportFilters();
}

class ClearItemCostReportFilters extends ItemCostEvent {
  ClearItemCostReportFilters();
}

class ExportItemCostReportToExcel extends ItemCostEvent {
  ExportItemCostReportToExcel();
}

class ExportItemCostReportToPDF extends ItemCostEvent {
  ExportItemCostReportToPDF();
}

class LoadMoreItemCostReport extends ItemCostEvent {}

// Cancel events
class CancelUpdate extends ItemCostEvent {}

class CancelCreate extends ItemCostEvent {}

class DiscardChanges extends ItemCostEvent {}
