import 'package:equatable/equatable.dart';

class ConfirmedItem extends Equatable {
  final String itemName;
  final double quantity;
  final double totalPrice;

  const ConfirmedItem({
    required this.itemName,
    required this.quantity,
    required this.totalPrice,
  });

  @override
  List<Object?> get props => [itemName, quantity, totalPrice];
}
