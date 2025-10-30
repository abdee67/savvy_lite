import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/stock/item_transactions/model/item_transaction_model.dart';

abstract class ItemTransactionsEvent extends Equatable {
  const ItemTransactionsEvent();

  @override
  List<Object?> get props => [];
}

class LoadItemTransactions extends ItemTransactionsEvent {
  final int companyId;
  final int? branchId;
  final DateTime? fromDate;
  final DateTime? toDate;

  const LoadItemTransactions({
    required this.companyId,
    this.branchId,
    this.fromDate,
    this.toDate,
  });

  @override
  List<Object?> get props => [companyId, branchId, fromDate, toDate];
}

class PrepareCreate extends ItemTransactionsEvent {}

class CreateItemTransaction extends ItemTransactionsEvent {
  final ItemTransactionModel transaction;
  const CreateItemTransaction(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

class PrepareCreateInEdit extends ItemTransactionsEvent {}

class PrepareEdit extends ItemTransactionsEvent {
  final ItemTransactionModel transaction;

  const PrepareEdit(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

class PrepareCopy extends ItemTransactionsEvent {
  final ItemTransactionModel transaction;

  const PrepareCopy(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

class SaveItemTransaction extends ItemTransactionsEvent {
  final List<ItemTransactionModel> transactions;

  const SaveItemTransaction(this.transactions);

  @override
  List<Object?> get props => [transactions];
}

class SaveRowTransaction extends ItemTransactionsEvent {
  const SaveRowTransaction();

  @override
  List<Object?> get props => [];
}

class SaveInEdit extends ItemTransactionsEvent {
  const SaveInEdit();

  @override
  List<Object?> get props => [];
}

class UpdateItemTransaction extends ItemTransactionsEvent {
  final ItemTransactionModel transaction;

  const UpdateItemTransaction(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

class DeleteItemTransaction extends ItemTransactionsEvent {
  final ItemTransactionModel transaction;

  const DeleteItemTransaction(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

class DeleteMultipleItemTransactions extends ItemTransactionsEvent {
  final List<ItemTransactionModel> transactions;

  const DeleteMultipleItemTransactions(this.transactions);

  @override
  List<Object?> get props => [transactions];
}

class FilterItemTransactions extends ItemTransactionsEvent {
  final String query;
  final Map<String, dynamic>? filters;
  final DateTime? fromDate;
  final DateTime? toDate;

  const FilterItemTransactions({
    required this.query,
    this.filters,
    this.fromDate,
    this.toDate,
  });

  @override
  List<Object?> get props => [query, filters, fromDate, toDate];
}

class CreateStockCardTransaction extends ItemTransactionsEvent {
  final int itemBranchId;
  final int locationId;
  final int? lotId;
  final String transactionType;
  final int transactionNumber;
  final String remark;
  final double quantity;
  final int? purchaseOrderId;
  final int? salesOrderId;

  const CreateStockCardTransaction({
    required this.itemBranchId,
    required this.locationId,
    this.lotId,
    required this.transactionType,
    required this.transactionNumber,
    required this.remark,
    required this.quantity,
    this.purchaseOrderId,
    this.salesOrderId,
  });

  @override
  List<Object?> get props => [
    itemBranchId,
    locationId,
    lotId,
    transactionType,
    transactionNumber,
    remark,
    quantity,
    purchaseOrderId,
    salesOrderId,
  ];
}

class ExecuteInventoryTransaction extends ItemTransactionsEvent {
  final ItemTransactionModel masterTransaction;
  final List<ItemTransactionModel> detailTransactions;
  const ExecuteInventoryTransaction({
    required this.masterTransaction,
    required this.detailTransactions,
  });
}

class CalculateOpeningAmount extends ItemTransactionsEvent {
  final int itemId;
  final int? branchId;
  final DateTime dateFrom;
  final DateTime dateThru;
  const CalculateOpeningAmount({
    required this.itemId,
    this.branchId,
    required this.dateFrom,
    required this.dateThru,
  });
}

class SaveAndClose extends ItemTransactionsEvent {
  final String route;

  const SaveAndClose(this.route);

  @override
  List<Object?> get props => [route];
}

class GetTotalOpening extends ItemTransactionsEvent {
  final int itemIds;
  final int? branchId;
  final DateTime dateFrom;
  final DateTime dateThru;
  const GetTotalOpening({
    required this.itemIds,
    this.branchId,
    required this.dateFrom,
    required this.dateThru,
  });
}

class SaveAndAddNew extends ItemTransactionsEvent {
  final String route;

  const SaveAndAddNew(this.route);

  @override
  List<Object?> get props => [route];
}

class CancelCreate extends ItemTransactionsEvent {}

class CancelUpdate extends ItemTransactionsEvent {}

class Discard extends ItemTransactionsEvent {}

class SelectItemTransaction extends ItemTransactionsEvent {
  final ItemTransactionModel transaction;

  const SelectItemTransaction(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

class SelectMultipleItemTransactions extends ItemTransactionsEvent {
  final List<ItemTransactionModel> transactions;

  const SelectMultipleItemTransactions(this.transactions);

  @override
  List<Object?> get props => [transactions];
}

class ClearSelection extends ItemTransactionsEvent {}

class ExportTransactions extends ItemTransactionsEvent {
  final List<ItemTransactionModel> transactions;
  final String format; // e.g., 'excel', 'pdf'

  const ExportTransactions(this.transactions, this.format);

  @override
  List<Object?> get props => [transactions, format];
}
// events/item_transaction_event.dart

// Events for location dropdown
class LoadLocationsForItem extends ItemTransactionsEvent {
  final int itemNumber;
  final int branchId;
  const LoadLocationsForItem(this.itemNumber, this.branchId);
}

class SelectLocation extends ItemTransactionsEvent {
  final int? locationId;
  final int itemNumber;
  final int branchId;
  const SelectLocation(this.locationId, this.itemNumber, this.branchId);
}

// Events for lot dropdown
class LoadLotsForItem extends ItemTransactionsEvent {
  final int itemNumber;
  final int branchId;
  final int? locationId;
  const LoadLotsForItem(this.itemNumber, this.branchId, this.locationId);
}

class SelectLot extends ItemTransactionsEvent {
  final int? lotId;
  const SelectLot(this.lotId);
}

// Events for to-location dropdown (for transfers)
class LoadToLocationsForItem extends ItemTransactionsEvent {
  final int itemNumber;
  final int toBranchId;
  const LoadToLocationsForItem(this.itemNumber, this.toBranchId);
}

class SelectToLocation extends ItemTransactionsEvent {
  final int? toLocationId;
  const SelectToLocation(this.toLocationId);
}

// Events for item dropdown
class LoadItemsForBranch extends ItemTransactionsEvent {
  final int branchId;
  const LoadItemsForBranch(this.branchId);
}

class SelectItem extends ItemTransactionsEvent {
  final int? itemNumber;
  final int branchId;
  const SelectItem(this.itemNumber, this.branchId);
}

// Event to get UoM descriptions
class LoadUoMDescription extends ItemTransactionsEvent {
  final int uomId;
  const LoadUoMDescription(this.uomId);
}
