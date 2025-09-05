import 'package:equatable/equatable.dart';

class Item extends Equatable {
  final String id;
  final String description;
  final String uom;
  final int barcode;
  final double unitPrice;

  const Item({
    required this.id,
    required this.description,
    required this.uom,
    this.barcode = 0,
    this.unitPrice = 0,
  });
  @override
  List<Object?> get props => [id, description, uom, barcode, unitPrice];
  static const empty = Item(
    id: '',
    description: '',
    uom: '',
    barcode: 0,
    unitPrice: 0,
  );
  bool get isEmpty => this == empty;
  bool get isNotEmpty => this != empty;
}
