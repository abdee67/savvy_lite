import 'package:savvy_stock/features/stock/item_cost/models/item_cost_model.dart';

class PaginatedItemCostResult {
  final List<ItemCost> items;
  final int totalCount;

  PaginatedItemCostResult({required this.items, required this.totalCount});
}
