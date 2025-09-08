class PaymentModel {
  final String id;
  final String transactionID;
  final String paymentType;
  final String paymentMethod;
  final String paymentInstrument;
  final String paymentTerm;
  final String paymentStatus;
  final DateTime paymentDate;
  final double amount;
  final double discountAmount;
  final double withholdingAmount;
  final double taxAmount;

  const PaymentModel({
    required this.id,
    required this.transactionID,
    required this.paymentType,
    required this.paymentMethod,
    required this.paymentInstrument,
    required this.paymentTerm,
    required this.paymentDate,
    required this.amount,
    required this.paymentStatus,
    this.discountAmount = 0,
    this.withholdingAmount = 0,
    this.taxAmount = 0,
  });

  List<Object> get props => [
    id,
    transactionID,
    amount,
    paymentType,
    paymentMethod,
    paymentInstrument,
    paymentTerm,
    paymentDate,
    paymentStatus,
    discountAmount,
    withholdingAmount,
    taxAmount,
  ];

  PaymentModel copyWith({
    String? id,
    String? transactionID,
    String? paymentType,
    String? paymentMethod,
    String? paymentInstrument,
    String? paymentTerm,
    String? paymentStatus,
    double? amount,
    double? taxAmount,
    double? discountAmount,
    double? withholdingAmount,
    DateTime? paymentDate,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      transactionID: transactionID ?? this.transactionID,
      paymentType: paymentType ?? this.paymentType,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentInstrument: paymentInstrument ?? this.paymentInstrument,
      paymentTerm: paymentTerm ?? this.paymentTerm,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      amount: amount ?? this.amount,
      taxAmount: taxAmount ?? this.taxAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      withholdingAmount: withholdingAmount ?? this.withholdingAmount,
      paymentDate: paymentDate ?? this.paymentDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transactionID': transactionID,
      'amount': amount,
      'paymentType': paymentType,
      'paymentMethod': paymentMethod,
      'paymentInstrument': paymentInstrument,
      'paymentTerm': paymentTerm,
      'paymentDate': paymentDate.toIso8601String(),
      'paymentStatus': paymentStatus,
      'discountAmount': discountAmount,
      'withholdingAmount': withholdingAmount,
      'taxAmount': taxAmount,
    };
  }

  factory PaymentModel.fromMap(Map<String, dynamic> map) {
    return PaymentModel(
      id: map['id'] ?? '',
      transactionID: map['transactionID'] ?? '',
      paymentType: map['paymentType'] ?? '',
      paymentMethod: map['paymentMethod'] ?? '',
      paymentInstrument: map['paymentInstrument'] ?? '',
      paymentTerm: map['paymentTerm'] ?? '',
      paymentDate: DateTime.parse(map['paymentDate']),
      amount: map['amount'] ?? 0,
      discountAmount: map['discountAmount'] ?? 0,
      withholdingAmount: map['withholdingAmount'] ?? 0,
      taxAmount: map['taxAmount'] ?? 0,
      paymentStatus: map['paymentStatus'] ?? '',
    );
  }
}
