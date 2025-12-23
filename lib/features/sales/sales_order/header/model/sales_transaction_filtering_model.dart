class SalesTransactionReportFilters {
  final int? customerId;
  final int? itemId;
  final String? fsNumber;
  final String? proformaReference;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? salesType; // 'Cash', 'Credit', or null for all
  final bool voidIndicator;
  final bool allDetailTransactions; // true = detail view, false = header view
  final int? branchId;
  final int? locationId;

  const SalesTransactionReportFilters({
    this.customerId,
    this.itemId,
    this.fsNumber,
    this.proformaReference,
    this.dateFrom,
    this.dateTo,
    this.salesType,
    this.voidIndicator = false,
    this.allDetailTransactions = false,
    this.branchId,
    this.locationId,
  });

  bool get hasFilters =>
      customerId != null ||
      itemId != null ||
      fsNumber != null ||
      proformaReference != null ||
      dateFrom != null ||
      dateTo != null ||
      salesType != null ||
      voidIndicator ||
      branchId != null ||
      locationId != null;

  bool get isDetailView => allDetailTransactions;
  bool get isCashOnly => salesType == 'Cash';
  bool get isCreditOnly => salesType == 'Credit';
  bool get hasDateRange => dateFrom != null && dateTo != null;

  SalesTransactionReportFilters copyWith({
    int? customerId,
    int? itemId,
    String? fsNumber,
    String? proformaReference,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? salesType,
    bool? voidIndicator,
    bool? allDetailTransactions,
    int? branchId,
    int? locationId,
  }) {
    return SalesTransactionReportFilters(
      customerId: customerId ?? this.customerId,
      itemId: itemId ?? this.itemId,
      fsNumber: fsNumber ?? this.fsNumber,
      proformaReference: proformaReference ?? this.proformaReference,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      salesType: salesType ?? this.salesType,
      voidIndicator: voidIndicator ?? this.voidIndicator,
      allDetailTransactions:
          allDetailTransactions ?? this.allDetailTransactions,
      branchId: branchId ?? this.branchId,
      locationId: locationId ?? this.locationId,
    );
  }

  // Helper method to clear all filters
  SalesTransactionReportFilters clearAll() {
    return const SalesTransactionReportFilters();
  }

  @override
  String toString() {
    return 'SalesTransactionReportFilters('
        'customerId: $customerId, '
        'itemId: $itemId, '
        'fsNumber: $fsNumber, '
        'proformaReference: $proformaReference, '
        'dateFrom: $dateFrom, '
        'dateTo: $dateTo, '
        'salesType: $salesType, '
        'voidIndicator: $voidIndicator, '
        'allDetailTransactions: $allDetailTransactions, '
        'branchId: $branchId, '
        'locationId: $locationId)';
  }
}
