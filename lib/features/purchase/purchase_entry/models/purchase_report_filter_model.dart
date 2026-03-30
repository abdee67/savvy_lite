class PurchaseReportFilters {
  final int? supplierId;
  final int? itemId;
  final String? fsNumber;
  final String? proformaReference;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? purchaseType; // 'Cash', 'Credit', or null for all
  final bool voidIndicator;
  final bool allDetailTransactions; // true = detail view, false = header view
  final int? branchId;
  final int? locationId;

  const PurchaseReportFilters({
    this.supplierId,
    this.itemId,
    this.fsNumber,
    this.proformaReference,
    this.dateFrom,
    this.dateTo,
    this.purchaseType,
    this.voidIndicator = false,
    this.allDetailTransactions = false,
    this.branchId,
    this.locationId,
  });

  bool get hasFilters =>
      supplierId != null ||
      itemId != null ||
      fsNumber != null ||
      proformaReference != null ||
      dateFrom != null ||
      dateTo != null ||
      purchaseType != null ||
      voidIndicator ||
      branchId != null ||
      locationId != null;

  bool get isDetailView => allDetailTransactions;
  bool get isCashOnly => purchaseType == 'Cash';
  bool get isCreditOnly => purchaseType == 'Credit';
  bool get hasDateRange => dateFrom != null && dateTo != null;

  PurchaseReportFilters copyWith({
    int? supplierId,
    int? itemId,
    String? fsNumber,
    String? proformaReference,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? purchaseType,
    bool? voidIndicator,
    bool? allDetailTransactions,
    int? branchId,
    int? locationId,
  }) {
    return PurchaseReportFilters(
      supplierId: supplierId ?? this.supplierId,
      itemId: itemId ?? this.itemId,
      fsNumber: fsNumber ?? this.fsNumber,
      proformaReference: proformaReference ?? this.proformaReference,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      purchaseType: purchaseType ?? this.purchaseType,
      voidIndicator: voidIndicator ?? this.voidIndicator,
      allDetailTransactions:
          allDetailTransactions ?? this.allDetailTransactions,
      branchId: branchId ?? this.branchId,
      locationId: locationId ?? this.locationId,
    );
  }

  // Helper method to clear all filters
  PurchaseReportFilters clearAll() {
    return const PurchaseReportFilters();
  }

  @override
  String toString() {
    return 'PurchaseReportFilters('
        'supplierId: $supplierId, '
        'itemId: $itemId, '
        'fsNumber: $fsNumber, '
        'proformaReference: $proformaReference, '
        'dateFrom: $dateFrom, '
        'dateTo: $dateTo, '
        'purchaseType: $purchaseType, '
        'voidIndicator: $voidIndicator, '
        'allDetailTransactions: $allDetailTransactions, '
        'branchId: $branchId, '
        'locationId: $locationId)';
  }
}
