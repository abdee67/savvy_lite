import 'package:savvy_stock/features/sales/sales_item_entry/models/items.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/models/stores.dart';

class ItemInStore {
  final Item item;
  final List<Store> availableStores;

  ItemInStore({required this.item, required this.availableStores});
}
