import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/models/confirmed_item.dart';

class OrderModel extends Equatable {
  final String id;
  final DateTime date;
  final List<ConfirmedItem> items;

  const OrderModel({required this.id, required this.date, required this.items});

  double get subtotal {
    return items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  @override
  List<Object?> get props => [id, date, items];
}
