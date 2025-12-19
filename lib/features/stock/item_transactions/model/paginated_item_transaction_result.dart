import 'package:savvy_stock/features/stock/item_entry/models/item_entry_model.dart';
import 'package:savvy_stock/features/stock/item_transactions/model/item_transaction_model.dart';

class PaginatedItemTransactionResult {
  final List<ItemTransactionModel>? items;
  final List<ItemEntryModel>? itemEntries;
  final int totalCount;

  PaginatedItemTransactionResult({
    this.items,
    this.itemEntries,
    required this.totalCount,
  });
}
