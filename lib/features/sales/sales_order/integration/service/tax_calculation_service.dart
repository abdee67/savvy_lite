// features/sales/services/tax_calculation_service.dart

import 'package:savvy_stock/features/system_constant/models/system_constant.dart';
import 'package:savvy_stock/features/system_constant/repo/system_constant_service.dart';

class TaxCalculationResult {
  final double subtotal;
  final double taxableAmount;
  final double vatAmount;
  final double withholdingAmount;
  final double discountAmount;
  final double totalAmount;
  final String calculationBreakdown;

  const TaxCalculationResult({
    required this.subtotal,
    required this.taxableAmount,
    required this.vatAmount,
    required this.withholdingAmount,
    required this.discountAmount,
    required this.totalAmount,
    required this.calculationBreakdown,
  });
}

class TaxCalculationService {
  TaxCalculationResult calculateTax({
    required double subtotal,
    required double discountAmount,
    required bool applyWithholding,
    required double taxableAmount,
    required SystemConstant systemConstants,
    required SystemConstantsService systemConstantService,
  }) {
    final vatRate = systemConstantService.vatRate / 100.0;
    final withholdingRate = systemConstantService.withholdingRate / 100.0;
    final withholdingInitial = systemConstantService.withholdingInitial;

    // Calculate VAT on taxable items only
    final vatAmount = taxableAmount * vatRate;

    // Calculate withholding tax if applicable
    double withholdingAmount = 0.0;
    if (applyWithholding && subtotal >= withholdingInitial) {
      withholdingAmount = subtotal * withholdingRate;
    }

    // Calculate final total
    final totalAmount =
        subtotal + vatAmount - withholdingAmount - discountAmount;
    final decimal = systemConstantService.decimalPlaces;

    // Create calculation breakdown
    final breakdown =
        '''
Subtotal: ${systemConstantService.roundToDecimalPlaces(subtotal, decimal)}
Taxable Amount: ${systemConstantService.roundToDecimalPlaces(taxableAmount, decimal)}
VAT (${systemConstantService.vatRate}%): ${systemConstantService.roundToDecimalPlaces(vatAmount, decimal)}
${applyWithholding ? 'Withholding Tax (${systemConstantService.withholdingRate}%): ${systemConstantService.roundToDecimalPlaces(withholdingAmount, decimal)}' : 'Withholding Tax: Not Applied'}
Discount: ${systemConstantService.roundToDecimalPlaces(discountAmount, decimal)}
Total: ${systemConstantService.roundToDecimalPlaces(totalAmount, decimal)}
''';

    return TaxCalculationResult(
      subtotal: subtotal,
      taxableAmount: taxableAmount,
      vatAmount: vatAmount,
      withholdingAmount: withholdingAmount,
      discountAmount: discountAmount,
      totalAmount: totalAmount,
      calculationBreakdown: breakdown,
    );
  }

  // Check if item is taxable
  bool isItemTaxable(bool? itemTaxable) {
    return itemTaxable == true;
  }
}
