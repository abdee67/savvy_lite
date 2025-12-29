class CashflowTransactionReportDTO {
  final String reference;
  final DateTime date;
  final String cashCredit;
  final String orderType;
  final double amount;

  const CashflowTransactionReportDTO({
    required this.reference,
    required this.date,
    required this.cashCredit,
    required this.orderType,
    required this.amount,
  });

  /// Construct from aggregated SQL query row
  factory CashflowTransactionReportDTO.fromQuery(Map<String, dynamic> row) {
    return CashflowTransactionReportDTO(
      reference: row['reference'] as String,
      date: DateTime.parse(row['dates']),
      cashCredit: row['cashCredit'] as String,
      orderType: row['orderType'] as String,
      amount: (row['amount'] as num).toDouble(),
    );
  }

  CashflowTransactionReportDTO copyWith({
    String? reference,
    DateTime? date,
    String? cashCredit,
    String? orderType,
    double? amount,
  }) {
    return CashflowTransactionReportDTO(
      reference: reference ?? this.reference,
      date: date ?? this.date,
      cashCredit: cashCredit ?? this.cashCredit,
      orderType: orderType ?? this.orderType,
      amount: amount ?? this.amount,
    );
  }
}
