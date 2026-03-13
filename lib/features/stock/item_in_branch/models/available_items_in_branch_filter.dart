import 'package:equatable/equatable.dart';

class AvailableItemsInBranchFilter extends Equatable {
  final int? itemNumber;
  final int? branchId;
  final bool noAvailable;

  const AvailableItemsInBranchFilter({
    this.itemNumber,
    this.branchId,
    this.noAvailable = false,
  });

  factory AvailableItemsInBranchFilter.empty() {
    return const AvailableItemsInBranchFilter();
  }

  AvailableItemsInBranchFilter copyWith({
    int? itemNumber,
    int? branchId,
    bool? noAvailable,
  }) {
    return AvailableItemsInBranchFilter(
      itemNumber: itemNumber ?? this.itemNumber,
      branchId: branchId ?? this.branchId,
      noAvailable: noAvailable ?? this.noAvailable,
    );
  }

  @override
  List<Object?> get props => [itemNumber, branchId, noAvailable];
}
