// Model for sales transaction report totals
class SalesTransactionReportTotals {
  final double withholdTotal;
  final double vatTotal;
  final double discountTotal;
  final double revenueTotal;
  final double cogsTotal;
  final double grossProfitTotal;
  final int totalCount;
  final int currentPage;
  final int totalPages;

  const SalesTransactionReportTotals({
    this.withholdTotal = 0.0,
    this.vatTotal = 0.0,
    this.discountTotal = 0.0,
    this.revenueTotal = 0.0,
    this.cogsTotal = 0.0,
    this.grossProfitTotal = 0.0,
    this.totalCount = 0,
    this.currentPage = 1,
    this.totalPages = 1,
  });

  SalesTransactionReportTotals copyWith({
    double? withholdTotal,
    double? vatTotal,
    double? discountTotal,
    double? revenueTotal,
    double? cogsTotal,
    double? grossProfitTotal,
    int? totalCount,
    int? currentPage,
    int? totalPages,
  }) {
    return SalesTransactionReportTotals(
      withholdTotal: withholdTotal ?? this.withholdTotal,
      vatTotal: vatTotal ?? this.vatTotal,
      discountTotal: discountTotal ?? this.discountTotal,
      revenueTotal: revenueTotal ?? this.revenueTotal,
      cogsTotal: cogsTotal ?? this.cogsTotal,
      grossProfitTotal: grossProfitTotal ?? this.grossProfitTotal,
      totalCount: totalCount ?? this.totalCount,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
    );
  }

  @override
  String toString() {
    return 'SalesTransactionReportTotals('
        'withholdTotal: $withholdTotal, '
        'vatTotal: $vatTotal, '
        'discountTotal: $discountTotal, '
        'revenueTotal: $revenueTotal, '
        'cogsTotal: $cogsTotal, '
        'grossProfitTotal: $grossProfitTotal, '
        'totalCount: $totalCount, '
        'currentPage: $currentPage, '
        'totalPages: $totalPages)';
  }
}
