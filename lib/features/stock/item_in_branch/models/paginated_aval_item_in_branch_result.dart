import 'package:savvy_stock/features/stock/item_in_branch/models/item_in_branch_model.dart';

class PaginatedItemInBranchResult {
  final List<ItemInBranchModel> itemInBranch;
  final int totalCount;

  PaginatedItemInBranchResult({
    required this.itemInBranch,
    required this.totalCount,
  });
}
