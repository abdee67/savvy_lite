class Item {
  String? id;
  String description;
  double quantity;
  String uom;
  String? store;
  double unitPrice;
  double lineTotal;
  bool isOutofStock;
  bool isFieldsEnabled;

  Item({
    this.id,
    required this.description,
    required this.quantity,
    required this.uom,
    this.store,
    required this.unitPrice,
    required this.lineTotal,
    required this.isOutofStock,
    required this.isFieldsEnabled,
  });
}
