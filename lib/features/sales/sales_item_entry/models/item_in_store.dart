import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/models/items.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/models/stores.dart';

class ItemInStore extends Equatable {
  final Item item;
  final List<Store> availableStores;

  const ItemInStore({required this.item, required this.availableStores});

  @override
  List<Object?> get props => [item, availableStores];
}
