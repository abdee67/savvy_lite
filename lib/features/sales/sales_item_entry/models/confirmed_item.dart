import 'package:equatable/equatable.dart';

class ConfirmedItem extends Equatable {
  final String itemId;
  final String itemName;
  final double quantity;
  final double totalPrice;
  final String? storeId;

  const ConfirmedItem({
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.totalPrice,
    this.storeId,
  });

  @override
  List<Object?> get props => [itemId, itemName, quantity, totalPrice, storeId];
}
