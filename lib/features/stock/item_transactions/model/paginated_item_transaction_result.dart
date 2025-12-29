import 'package:savvy_stock/features/stock/item_entry/models/item_entry_model.dart';
import 'package:savvy_stock/features/stock/item_in_branch/models/item_in_branch_model.dart';
import 'package:savvy_stock/features/stock/item_transactions/model/item_transaction_model.dart';

class PaginatedItemTransactionResult {
  final List<ItemTransactionModel>? items;
  final List<ItemEntryModel>? itemEntries;
  final List<ItemInBranchModel>? itemInBranch;
  final int totalCount;

  PaginatedItemTransactionResult({
    this.items,
    this.itemEntries,
    this.itemInBranch,
    required this.totalCount,
  });
}
