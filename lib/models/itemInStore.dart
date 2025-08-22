import 'package:savvy_stock/models/items.dart';
import 'package:savvy_stock/screens/stores.dart';

class ItemInStore {
  final Item item;
  final List<Store> availableStores;

  ItemInStore({required this.item, required this.availableStores});
}
