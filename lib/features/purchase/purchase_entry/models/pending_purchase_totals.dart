import 'package:equatable/equatable.dart';

class PendingPurchaseTotals extends Equatable {
  final double
  totalTransactionQunatity; // Sum of amountGross (matches Java's amountTotalPOTotal)
  final double
  totalReceivedQuantity; // Sum of amountGrandTotalCost (matches Java's grandTotalPOTotal)
  final double
  totalRemainigQuantity; // Sum of amountGrandTotalCost (matches Java's grandTotalPOTotal)
  final int totalCount; // Total number of records
  final int currentPage;
  final int totalPages;

  const PendingPurchaseTotals({
    required this.totalReceivedQuantity,
    required this.totalRemainigQuantity,
    required this.totalTransactionQunatity,
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
  });

  @override
  List<Object?> get props => [
    totalTransactionQunatity,
    totalReceivedQuantity,
    totalRemainigQuantity,
    totalCount,
    currentPage,
    totalPages,
  ];
}
