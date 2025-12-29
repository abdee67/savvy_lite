// Model for sales transaction report totals
class CashOutFlowTotals {
  final double totalCredit;
  final int totalCount;
  final int currentPage;
  final int totalPages;

  const CashOutFlowTotals({
    this.totalCredit = 0.0,
    this.totalCount = 0,
    this.currentPage = 1,
    this.totalPages = 1,
  });

  CashOutFlowTotals copyWith({
    double? totalCredit,
    int? totalCount,
    int? currentPage,
    int? totalPages,
  }) {
    return CashOutFlowTotals(
      totalCredit: totalCredit ?? this.totalCredit,
      totalCount: totalCount ?? this.totalCount,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
    );
  }

  @override
  String toString() {
    return 'CashOutFlowTotals('
        'totalCredit: $totalCredit, '
        'totalCount: $totalCount, '
        'currentPage: $currentPage, '
        'totalPages: $totalPages)';
  }
}
