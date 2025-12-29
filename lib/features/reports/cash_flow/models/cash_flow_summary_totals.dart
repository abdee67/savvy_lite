// Model for combined cash flow summary totals
class CashFlowSummaryTotals {
  final double totalInflow;
  final double totalOutflow;
  final double netCashFlow;
  final int totalCount;

  const CashFlowSummaryTotals({
    this.totalInflow = 0.0,
    this.totalOutflow = 0.0,
    this.netCashFlow = 0.0,
    this.totalCount = 0,
  });

  CashFlowSummaryTotals copyWith({
    double? totalInflow,
    double? totalOutflow,
    double? netCashFlow,
    int? totalCount,
  }) {
    return CashFlowSummaryTotals(
      totalInflow: totalInflow ?? this.totalInflow,
      totalOutflow: totalOutflow ?? this.totalOutflow,
      netCashFlow: netCashFlow ?? this.netCashFlow,
      totalCount: totalCount ?? this.totalCount,
    );
  }

  @override
  String toString() {
    return 'CashFlowSummaryTotals('
        'totalInflow: $totalInflow, '
        'totalOutflow: $totalOutflow, '
        'netCashFlow: $netCashFlow, '
        'totalCount: $totalCount)';
  }
}
