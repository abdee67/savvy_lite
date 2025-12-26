import 'package:equatable/equatable.dart';

class GRNTotals extends Equatable {
  final double totalReceivedQuantity; // Sum of receivedQuantity
  final double totalReceivedAmount; // Sum of receivedAmount
  final int totalCount; // Total number of records
  final int currentPage;
  final int totalPages;

  const GRNTotals({
    required this.totalReceivedQuantity,
    required this.totalReceivedAmount,
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
  });

  @override
  List<Object?> get props => [
    totalReceivedQuantity,
    totalReceivedAmount,
    totalCount,
    currentPage,
    totalPages,
  ];
}
