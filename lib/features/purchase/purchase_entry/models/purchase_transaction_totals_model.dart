import 'package:equatable/equatable.dart';

class PurchaseTransactionTotals extends Equatable {
  final double
  totalAmountGross; // Sum of amountGross (matches Java's amountTotalPOTotal)
  final double
  totalGrandAmountGross; // Sum of amountGrandTotalCost (matches Java's grandTotalPOTotal)
  final int totalCount; // Total number of records
  final int currentPage;
  final int totalPages;

  const PurchaseTransactionTotals({
    required this.totalAmountGross,
    required this.totalGrandAmountGross,
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
  });

  @override
  List<Object?> get props => [
    totalAmountGross,
    totalGrandAmountGross,
    totalCount,
    currentPage,
    totalPages,
  ];
}
