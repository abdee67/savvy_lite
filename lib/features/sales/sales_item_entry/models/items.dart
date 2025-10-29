import 'package:equatable/equatable.dart';

class Item extends Equatable {
  final String id;
  final String description;
  final String uom;
  final int barcode;

  const Item({
    required this.id,
    required this.description,
    required this.uom,
    this.barcode = 0,
  });
  @override
  List<Object?> get props => [id, description, uom, barcode];
  static const empty = Item(id: '', description: '', uom: '', barcode: 0);
  bool get isEmpty => this == empty;
  bool get isNotEmpty => this != empty;
}
