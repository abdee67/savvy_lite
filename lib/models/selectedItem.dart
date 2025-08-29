import 'package:savvy_stock/models/items.dart';
import 'package:savvy_stock/screens/stores.dart';

class SelectedItem {
  Item? item;
  Store? store;
  double quantity;
  bool isOutOfStock;

  SelectedItem({
    this.item,
    this.store,
    this.quantity = 0,
    this.isOutOfStock = false,
  });

  double get unitPrice => store?.unitPrice ?? 0;
  double get extendedPrice {
    if (store == null || quantity <= 0 || unitPrice <= 0) return 0;
    return quantity * unitPrice;
  }
}
