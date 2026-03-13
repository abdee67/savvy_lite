import 'package:savvy_stock/features/stock/item_locations/models/item_locations_model.dart';

class PaginatedItemLocationsResult {
  final List<ItemLocation> items;
  final int count;

  PaginatedItemLocationsResult({required this.items, required this.count});
}
