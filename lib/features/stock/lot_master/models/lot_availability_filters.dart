// features/stock/lot_master/models/lot_availability_filters.dart
import 'package:equatable/equatable.dart';

class LotAvailabilityFilters extends Equatable {
  final int? itemNumber;
  final int? branch;
  final String? batchNumberSupplier;
  final int? locationId;

  final String? selectFilterDates; // 'RANGE', 'YEARS', 'DAYS', 'EXPIRED'
  final DateTime? startDateForFilter;
  final DateTime? endDateForFilter;
  final int? yearsPut;
  final int? minDays;
  final int? maxDays;

  final bool noAvailability;

  const LotAvailabilityFilters({
    this.itemNumber,
    this.branch,
    this.batchNumberSupplier,
    this.locationId,
    this.selectFilterDates,
    this.startDateForFilter,
    this.endDateForFilter,
    this.yearsPut,
    this.minDays,
    this.maxDays,
    this.noAvailability = false,
  });

  LotAvailabilityFilters copyWith({
    int? itemNumber,
    int? branch,
    String? batchNumberSupplier,
    int? locationId,
    String? selectFilterDates,
    DateTime? startDateForFilter,
    DateTime? endDateForFilter,
    int? yearsPut,
    int? minDays,
    int? maxDays,
    bool? noAvailability,
  }) {
    return LotAvailabilityFilters(
      itemNumber: itemNumber ?? this.itemNumber,
      branch: branch ?? this.branch,
      batchNumberSupplier: batchNumberSupplier ?? this.batchNumberSupplier,
      locationId: locationId ?? this.locationId,
      selectFilterDates: selectFilterDates ?? this.selectFilterDates,
      startDateForFilter: startDateForFilter ?? this.startDateForFilter,
      endDateForFilter: endDateForFilter ?? this.endDateForFilter,
      yearsPut: yearsPut ?? this.yearsPut,
      minDays: minDays ?? this.minDays,
      maxDays: maxDays ?? this.maxDays,
      noAvailability: noAvailability ?? this.noAvailability,
    );
  }

  @override
  List<Object?> get props => [
    itemNumber,
    branch,
    batchNumberSupplier,
    locationId,
    selectFilterDates,
    startDateForFilter,
    endDateForFilter,
    yearsPut,
    minDays,
    maxDays,
    noAvailability,
  ];
}
