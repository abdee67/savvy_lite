class ExpirationReportFilters {
  final int? itemId;
  final int? branchId;
  final int? locationId;
  final bool showZeroAvailability;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? batchNumber;

  const ExpirationReportFilters({
    this.itemId,
    this.branchId,
    this.locationId,
    this.showZeroAvailability = false,
    this.dateFrom,
    this.dateTo,
    this.batchNumber,
  });

  bool get hasFilters =>
      itemId != null ||
      branchId != null ||
      locationId != null ||
      showZeroAvailability ||
      dateFrom != null ||
      dateTo != null ||
      batchNumber != null;

  ExpirationReportFilters copyWith({
    int? itemId,
    int? branchId,
    int? locationId,
    bool? showZeroAvailability,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? batchNumber,
  }) {
    return ExpirationReportFilters(
      itemId: itemId ?? this.itemId,
      branchId: branchId ?? this.branchId,
      locationId: locationId ?? this.locationId,
      showZeroAvailability: showZeroAvailability ?? this.showZeroAvailability,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      batchNumber: batchNumber ?? this.batchNumber,
    );
  }
}
