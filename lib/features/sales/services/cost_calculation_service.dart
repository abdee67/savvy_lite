// features/sales/services/cost_calculation_service.dart
import 'package:savvy_stock/features/sales/sales_order_detail/model/sales_order_detail.dart';
import 'package:savvy_stock/features/stock/item_UoM_conversions/repo/item_uom_conv_repo.dart';
import 'package:savvy_stock/features/stock/item_cost/repo/item_cost_repository.dart';

class CostCalculationResult {
  final double unitCost;
  final double amountCost;
  final String costSource;
  final DateTime? costDate;

  const CostCalculationResult({
    required this.unitCost,
    required this.amountCost,
    required this.costSource,
    this.costDate,
  });
}

class CostCalculationService {
  final ItemCostRepository itemCostRepository;
  final ItemUomConversionsRepository uomConversionRepository;

  CostCalculationService({
    required this.itemCostRepository,
    required this.uomConversionRepository,
  });

  Future<CostCalculationResult> calculateItemCost({
    required SalesOrderDetail item,
    required int companyId,
  }) async {
    try {
      // Get standard cost from item cost table
      final itemCost = await itemCostRepository.findByItemNumberAndCompany(
        item.itemsTableId!,
        companyId,
      );

      double unitCost = 0.0;
      String costSource = 'Standard Cost';

      if (itemCost.isNotEmpty) {
        unitCost = itemCost.first.amountUnitCost ?? 0.0;
      } else {
        // Fallback: Use last purchase price or average cost
        final avgCost = await _getAverageCost(item.itemsTableId!, companyId);
        unitCost = avgCost;
        costSource = 'Average Cost';
      }

      // Apply UOM conversion if needed
      if (item.unitOfMeasure != null &&
          item.itemBranch?.unitOfMeasure != item.unitOfMeasure) {
        unitCost = await _convertCostUOM(
          unitCost,
          item.itemsTableId!,
          item.itemBranch!.unitOfMeasure!,
          item.unitOfMeasure!,
          companyId,
        );
      }

      final amountCost = unitCost * (item.quantity ?? 0);

      return CostCalculationResult(
        unitCost: unitCost,
        amountCost: amountCost,
        costSource: costSource,
        costDate: DateTime.now(),
      );
    } catch (e) {
      // Fallback to zero cost with error tracking
      return CostCalculationResult(
        unitCost: 0.0,
        amountCost: 0.0,
        costSource: 'Error - Using Zero',
        costDate: DateTime.now(),
      );
    }
  }

  Future<double> _getAverageCost(int itemId, int companyId) async {
    // Implement average cost calculation based on purchase history
    final purchaseHistory = await itemCostRepository.getPurchaseHistory(
      itemId,
      companyId,
    );

    if (purchaseHistory.isEmpty) return 0.0;

    final totalValue = purchaseHistory.fold(
      0.0,
      (sum, record) =>
          sum + (record.amountUnitCost! * record.fromUOM!.quantityAvailable!),
    );
    final totalQuantity = purchaseHistory.fold(
      0.0,
      (sum, record) => sum + record.fromUOM!.quantityAvailable!,
    );

    return totalQuantity > 0 ? totalValue / totalQuantity : 0.0;
  }

  Future<double> _convertCostUOM(
    double cost,
    int itemId,
    int fromUomId,
    int toUomId,
    int companyId,
  ) async {
    // Get UOM conversion factor and adjust cost
    final conversion = await uomConversionRepository.getConversionFactor(
      itemId,
      fromUomId,
      toUomId,
      companyId,
    );

    return cost * conversion;
  }

  // Calculate total cost for all items in order
  Future<double> calculateTotalOrderCost(List<SalesOrderDetail> items) async {
    double totalCost = 0.0;

    for (final item in items) {
      final costResult = await calculateItemCost(
        item: item,
        companyId: item.company!,
      );
      totalCost += costResult.amountCost;
    }

    return totalCost;
  }
}
