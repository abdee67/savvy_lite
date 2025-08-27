class Item {
  final String id;
  final String description;
  final String uom;
  final double barcode;

  Item({
    required this.id,
    required this.description,
    required this.uom,
    this.barcode = 0,
  });
}
