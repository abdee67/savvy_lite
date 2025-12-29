// features/sales/invoice_history/models/invoice_history_detail.dart
class InvoiceHistoryDetail {
  final int? id;
  final int? invoiceHistory;
  final String? item;
  final String? unitOfMeasure;
  final double? quantityTransaction;
  final double? amountUnitPrice;
  final double? amountExtendedPrice;
  int? company;
  final int? tempId;

  InvoiceHistoryDetail({
    this.id,
    this.invoiceHistory,
    this.item,
    this.unitOfMeasure,
    this.quantityTransaction,
    this.amountUnitPrice,
    this.amountExtendedPrice,
    this.company,
    this.tempId,
  });

  // Copy with method
  InvoiceHistoryDetail copyWith({
    int? id,
    int? invoiceHistory,
    String? item,
    String? unitOfMeasure,
    double? quantityTransaction,
    double? amountUnitPrice,
    double? amountExtendedPrice,
    int? company,
    int? tempId,
  }) {
    return InvoiceHistoryDetail(
      id: id ?? this.id,
      invoiceHistory: invoiceHistory ?? this.invoiceHistory,
      item: item ?? this.item,
      unitOfMeasure: unitOfMeasure ?? this.unitOfMeasure,
      quantityTransaction: quantityTransaction ?? this.quantityTransaction,
      amountUnitPrice: amountUnitPrice ?? this.amountUnitPrice,
      amountExtendedPrice: amountExtendedPrice ?? this.amountExtendedPrice,
      company: company ?? this.company,
      tempId: tempId ?? this.tempId,
    );
  }

  // Convert to Map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_history': invoiceHistory,
      'item': item,
      'unit_of_measure': unitOfMeasure,
      'quantity_transaction': quantityTransaction,
      'amount_unit_price': amountUnitPrice,
      'amount_extended_price': amountExtendedPrice,
      'company': company,
    };
  }

  // Create from Map
  factory InvoiceHistoryDetail.fromMap(Map<String, dynamic> map) {
    return InvoiceHistoryDetail(
      id: map['id'],
      invoiceHistory: map['invoice_history'],
      item: map['item'],
      unitOfMeasure: map['unit_of_measure'],
      quantityTransaction: map['quantity_transaction']?.toDouble(),
      amountUnitPrice: map['amount_unit_price']?.toDouble(),
      amountExtendedPrice: map['amount_extended_price']?.toDouble(),
      company: map['company'],
    );
  }

  // Calculate extended price if not provided
  InvoiceHistoryDetail calculateExtendedPrice() {
    if (amountUnitPrice != null && quantityTransaction != null) {
      return copyWith(
        amountExtendedPrice: amountUnitPrice! * quantityTransaction!,
      );
    }
    return this;
  }

  @override
  String toString() {
    return 'InvoiceHistoryDetail(id: $id, item: $item, quantity: $quantityTransaction, unitPrice: $amountUnitPrice, extendedPrice: $amountExtendedPrice)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InvoiceHistoryDetail &&
        other.id == id &&
        other.invoiceHistory == invoiceHistory &&
        other.item == item &&
        other.unitOfMeasure == unitOfMeasure &&
        other.quantityTransaction == quantityTransaction &&
        other.amountUnitPrice == amountUnitPrice &&
        other.amountExtendedPrice == amountExtendedPrice &&
        other.company == company;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      invoiceHistory,
      item,
      unitOfMeasure,
      quantityTransaction,
      amountUnitPrice,
      amountExtendedPrice,
      company,
    );
  }
}
