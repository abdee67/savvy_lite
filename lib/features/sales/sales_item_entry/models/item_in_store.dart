import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/models/items.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/models/stores.dart';

class ItemInStore extends Equatable {
  final Item item;
  final Store store;
  final double unitPrice;
  final int availability;

  const ItemInStore({
    required this.item,
    required this.store,
    required this.unitPrice,
    required this.availability,
  });

  @override
  List<Object?> get props => [item, store, unitPrice, availability];

  static const empty = ItemInStore(
    item: Item.empty,
    store: Store.empty,
    unitPrice: 0,
    availability: 0,
  );
  bool get isEmpty => this == empty;
  bool get isNotEmpty => this != empty;
}
