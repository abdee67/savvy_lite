import 'package:savvy_stock/features/stock/lot_master/models/lot_master_model.dart';

class PaginatedExpirationResult {
  final List<LotMaster> lots;
  final int totalCount;
  final double totalCost;

  PaginatedExpirationResult({
    required this.lots,
    required this.totalCount,
    required this.totalCost,
  });
}
