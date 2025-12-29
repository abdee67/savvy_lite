// Model for sales transaction report totals
class AgedCreditReceiptTotals {
  final double totalAmountprice;
  final double paidpriceAmount;
  final double remainingPriceAmount;
  final int totalCount;
  final int currentPage;
  final int totalPages;

  const AgedCreditReceiptTotals({
    this.totalAmountprice = 0.0,
    this.paidpriceAmount = 0.0,
    this.remainingPriceAmount = 0.0,
    this.totalCount = 0,
    this.currentPage = 1,
    this.totalPages = 1,
  });

  AgedCreditReceiptTotals copyWith({
    double? totalAmountprice,
    double? paidpriceAmount,
    double? remainingPriceAmount,
    int? totalCount,
    int? currentPage,
    int? totalPages,
  }) {
    return AgedCreditReceiptTotals(
      totalAmountprice: totalAmountprice ?? this.totalAmountprice,
      paidpriceAmount: paidpriceAmount ?? this.paidpriceAmount,
      remainingPriceAmount: remainingPriceAmount ?? this.remainingPriceAmount,
      totalCount: totalCount ?? this.totalCount,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
    );
  }

  @override
  String toString() {
    return 'AgedCreditReceiptTotals('
        'totalAmountprice: $totalAmountprice, '
        'paidpriceAmount: $paidpriceAmount, '
        'remainingPriceAmount: $remainingPriceAmount, '
        'totalCount: $totalCount, '
        'currentPage: $currentPage, '
        'totalPages: $totalPages)';
  }
}
