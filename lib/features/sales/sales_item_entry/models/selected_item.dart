import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/models/item_in_store.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/models/items.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/models/stores.dart';

class SelectedItem extends Equatable {
  final Item? item;
  final ItemInStore? store;
  final double quantity;
  final bool isOutOfStock;

  const SelectedItem({
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

  SelectedItem copyWith({
    Item? item,
    ItemInStore? store,
    double? quantity,
    bool? isOutOfStock,
  }) {
    return SelectedItem(
      item: item ?? this.item,
      store: store ?? this.store,
      quantity: quantity ?? this.quantity,
      isOutOfStock: isOutOfStock ?? this.isOutOfStock,
    );
  }

  @override
  List<Object?> get props => [item, store, quantity, isOutOfStock];
  static const empty = SelectedItem();
  bool get isEmpty => this == empty;
  bool get isNotEmpty => this != empty;
  bool get isValid =>
      item != null &&
      store != null &&
      quantity > 0 &&
      extendedPrice > 0 &&
      quantity <= store!.availability;
}
