class ItemReportFilters {
  final DateTime? dateFrom;
  final DateTime? dateTo;

  const ItemReportFilters({this.dateFrom, this.dateTo});

  bool get hasFilters => dateFrom != null || dateTo != null;

  ItemReportFilters copyWith({DateTime? dateFrom, DateTime? dateTo}) {
    return ItemReportFilters(
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
    );
  }
}
