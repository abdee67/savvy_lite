// features/sales/invoice_history/models/invoice_history_header.dart
class InvoiceHistoryHeader {
  final int? id;
  final String? fsNumber;
  final String? customerName;
  final String? tinNumber;
  final String? phoneNumber;
  final String? country;
  final String? city;
  final String? region;
  final double? taxAmount;
  final double? withholdAmount;
  final double? totalAmount;
  final DateTime? dateTransaction;
  final String? salesPerson;
  final String? mrcNumber;
  final double? discountAmount;
  final double? amountBeforeTax;
  int? company;
  final int? tempId;

  InvoiceHistoryHeader({
    this.id,
    this.fsNumber,
    this.customerName,
    this.tinNumber,
    this.phoneNumber,
    this.country,
    this.city,
    this.region,
    this.taxAmount,
    this.withholdAmount,
    this.totalAmount,
    this.dateTransaction,
    this.salesPerson,
    this.mrcNumber,
    this.discountAmount,
    this.amountBeforeTax,
    this.company,
    this.tempId,
  });

  // Copy with method
  InvoiceHistoryHeader copyWith({
    int? id,
    String? fsNumber,
    String? customerName,
    String? tinNumber,
    String? phoneNumber,
    String? country,
    String? city,
    String? region,
    double? taxAmount,
    double? withholdAmount,
    double? totalAmount,
    DateTime? dateTransaction,
    String? salesPerson,
    String? mrcNumber,
    double? discountAmount,
    double? amountBeforeTax,
    int? company,
    int? tempId,
  }) {
    return InvoiceHistoryHeader(
      id: id ?? this.id,
      fsNumber: fsNumber ?? this.fsNumber,
      customerName: customerName ?? this.customerName,
      tinNumber: tinNumber ?? this.tinNumber,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      country: country ?? this.country,
      city: city ?? this.city,
      region: region ?? this.region,
      taxAmount: taxAmount ?? this.taxAmount,
      withholdAmount: withholdAmount ?? this.withholdAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      dateTransaction: dateTransaction ?? this.dateTransaction,
      salesPerson: salesPerson ?? this.salesPerson,
      mrcNumber: mrcNumber ?? this.mrcNumber,
      discountAmount: discountAmount ?? this.discountAmount,
      amountBeforeTax: amountBeforeTax ?? this.amountBeforeTax,
      company: company ?? this.company,
      tempId: tempId ?? this.tempId,
    );
  }

  // Convert to Map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fs_number': fsNumber,
      'customer_name': customerName,
      'tin_number': tinNumber,
      'phone_number': phoneNumber,
      'country': country,
      'city': city,
      'region': region,
      'tax_amount': taxAmount,
      'withhold_amount': withholdAmount,
      'total_amount': totalAmount,
      'date_transaction': dateTransaction?.toIso8601String(),
      'sales_person': salesPerson,
      'mrc_number': mrcNumber,
      'discount_amount': discountAmount,
      'amount_beforeTax': amountBeforeTax,
      'company': company,
    };
  }

  // Create from Map
  factory InvoiceHistoryHeader.fromMap(Map<String, dynamic> map) {
    return InvoiceHistoryHeader(
      id: map['id'],
      fsNumber: map['fs_number'],
      customerName: map['customer_name'],
      tinNumber: map['tin_number'],
      phoneNumber: map['phone_number'],
      country: map['country'],
      city: map['city'],
      region: map['region'],
      taxAmount: map['tax_amount']?.toDouble(),
      withholdAmount: map['withhold_amount']?.toDouble(),
      totalAmount: map['total_amount']?.toDouble(),
      dateTransaction: map['date_transaction'] != null
          ? DateTime.tryParse(map['date_transaction'])
          : null,
      salesPerson: map['sales_person'],
      mrcNumber: map['mrc_number'],
      discountAmount: map['discount_amount']?.toDouble(),
      amountBeforeTax: map['amount_beforeTax']?.toDouble(),
      company: map['company'],
    );
  }

  @override
  String toString() {
    return 'InvoiceHistoryHeader(id: $id, fsNumber: $fsNumber, customerName: $customerName, totalAmount: $totalAmount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InvoiceHistoryHeader &&
        other.id == id &&
        other.fsNumber == fsNumber &&
        other.customerName == customerName &&
        other.tinNumber == tinNumber &&
        other.phoneNumber == phoneNumber &&
        other.country == country &&
        other.city == city &&
        other.region == region &&
        other.taxAmount == taxAmount &&
        other.withholdAmount == withholdAmount &&
        other.totalAmount == totalAmount &&
        other.dateTransaction == dateTransaction &&
        other.salesPerson == salesPerson &&
        other.mrcNumber == mrcNumber &&
        other.discountAmount == discountAmount &&
        other.amountBeforeTax == amountBeforeTax &&
        other.company == company;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      fsNumber,
      customerName,
      tinNumber,
      phoneNumber,
      country,
      city,
      region,
      taxAmount,
      withholdAmount,
      totalAmount,
      dateTransaction,
      salesPerson,
      mrcNumber,
      discountAmount,
      amountBeforeTax,
      company,
    );
  }
}
