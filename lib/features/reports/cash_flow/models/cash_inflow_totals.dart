// Model for sales transaction report totals
class CashInFlowTotals {
  final double totalDebit;
  final int totalCount;
  final int currentPage;
  final int totalPages;

  const CashInFlowTotals({
    this.totalDebit = 0.0,
    this.totalCount = 0,
    this.currentPage = 1,
    this.totalPages = 1,
  });

  CashInFlowTotals copyWith({
    double? totalDebit,
    int? totalCount,
    int? currentPage,
    int? totalPages,
  }) {
    return CashInFlowTotals(
      totalDebit: totalDebit ?? this.totalDebit,
      totalCount: totalCount ?? this.totalCount,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
    );
  }

  @override
  String toString() {
    return 'CashInFlowTotals('
        'totalDebit: $totalDebit, '
        'totalCount: $totalCount, '
        'currentPage: $currentPage, '
        'totalPages: $totalPages)';
  }
}
