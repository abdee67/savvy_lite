import 'package:equatable/equatable.dart';

class ItemLocationFilters extends Equatable {
  final int? itemNumber;
  final int? branchId;
  final int? locationId;
  final bool noAvailable;

  const ItemLocationFilters({
    this.itemNumber,
    this.branchId,
    this.locationId,
    this.noAvailable = false,
  });

  factory ItemLocationFilters.empty() {
    return const ItemLocationFilters();
  }

  ItemLocationFilters copyWith({
    int? itemNumber,
    int? branchId,
    int? locationId,
    bool? noAvailable,
  }) {
    return ItemLocationFilters(
      itemNumber: itemNumber ?? this.itemNumber,
      branchId: branchId ?? this.branchId,
      locationId: locationId ?? this.locationId,
      noAvailable: noAvailable ?? this.noAvailable,
    );
  }

  @override
  List<Object?> get props => [
        itemNumber,
        branchId,
        locationId,
        noAvailable,
      ];
}
