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
  final ItemTransactionModel transaction;

  const SaveItemTransaction(this.transaction);

  @override
  List<Object?> get props => [transaction];
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

class CalculateOpeningAmount extends ItemTransactionsEvent {
  final int itemId;
  final int branchId;
  final DateTime fromDate;
  final DateTime toDate;

  const CalculateOpeningAmount({
    required this.itemId,
    required this.branchId,
    required this.fromDate,
    required this.toDate,
  });

  @override
  List<Object?> get props => [itemId, branchId, fromDate, toDate];
}

class SaveAndClose extends ItemTransactionsEvent {
  final String route;

  const SaveAndClose(this.route);

  @override
  List<Object?> get props => [route];
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
