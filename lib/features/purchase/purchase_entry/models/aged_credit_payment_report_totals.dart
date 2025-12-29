// Model for sales transaction report totals
class AgedCreditPaymentTotals {
  final double totalGrossAmount;
  final double totalPaidAmount;
  final double totalRemainingAmount;
  final int totalCount;
  final int currentPage;
  final int totalPages;

  const AgedCreditPaymentTotals({
    this.totalGrossAmount = 0.0,
    this.totalPaidAmount = 0.0,
    this.totalRemainingAmount = 0.0,
    this.totalCount = 0,
    this.currentPage = 1,
    this.totalPages = 1,
  });

  AgedCreditPaymentTotals copyWith({
    double? totalGrossAmount,
    double? totalPaidAmount,
    double? totalRemainingAmount,
    int? totalCount,
    int? currentPage,
    int? totalPages,
  }) {
    return AgedCreditPaymentTotals(
      totalGrossAmount: totalGrossAmount ?? this.totalGrossAmount,
      totalPaidAmount: totalPaidAmount ?? this.totalPaidAmount,
      totalRemainingAmount: totalRemainingAmount ?? this.totalRemainingAmount,
      totalCount: totalCount ?? this.totalCount,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
    );
  }

  @override
  String toString() {
    return 'AgedCreditPaymentTotals('
        'totalGrossAmount: $totalGrossAmount, '
        'totalPaidAmount: $totalPaidAmount, '
        'totalRemainingAmount: $totalRemainingAmount, '
        'totalCount: $totalCount, '
        'currentPage: $currentPage, '
        'totalPages: $totalPages)';
  }
}
