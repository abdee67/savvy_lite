// features/sales/services/lot_management_service.dart
import 'package:savvy_stock/features/sales/sales_order_detail/model/sales_order_detail.dart';
import 'package:savvy_stock/features/stock/lot_coloring/repo/lot_expiration_repo.dart';
import 'package:savvy_stock/features/stock/lot_master/models/lot_master_model.dart';
import 'package:savvy_stock/features/stock/lot_master/repo/lot_master_repo.dart';
import 'package:savvy_stock/features/system_constant/models/system_constant.dart';

class LotValidationResult {
  final bool isValid;
  final LotMaster? recommendedLot;
  final double availableQuantity;
  final String message;
  final List<LotMaster> availableLots;

  const LotValidationResult({
    required this.isValid,
    this.recommendedLot,
    required this.availableQuantity,
    required this.message,
    required this.availableLots,
  });
}

class LotManagementService {
  final LotMasterRepository lotMasterRepository;
  final LotExpirationColorsRepository expirationColorsRepository;

  LotManagementService({
    required this.lotMasterRepository,
    required this.expirationColorsRepository,
  });

  Future<LotValidationResult> validateLotForSale({
    required int itemId,
    required int branchId,
    required int companyId,
    required double requestedQuantity,
    required SystemConstant systemConstants,
    LotMaster? selectedLot,
  }) async {
    try {
      // Get all available lots for the item
      final availableLots = await lotMasterRepository
          .getLotMastersByItemAndBranch(
            itemNumber: itemId,
            branch: branchId,
            companyId: companyId,
          );

      // Filter out expired and inactive lots
      final validLots = await _filterValidLots(
        availableLots,
        branchId,
        itemId,
        companyId,
      );

      if (validLots.isEmpty) {
        return LotValidationResult(
          isValid: false,
          availableQuantity: 0.0,
          message: 'No valid lots available for this item',
          availableLots: [],
        );
      }

      // If lot is manually selected, validate it
      if (selectedLot != null && !systemConstants.lotQtyAutoForSalesBoolean) {
        return await _validateSelectedLot(
          selectedLot,
          requestedQuantity,
          validLots,
          systemConstants,
        );
      }

      // Auto-select lot based on FIFO/FEFO
      return await _autoSelectLot(
        validLots,
        requestedQuantity,
        systemConstants,
      );
    } catch (e) {
      return LotValidationResult(
        isValid: false,
        availableQuantity: 0.0,
        message: 'Error validating lot: $e',
        availableLots: [],
      );
    }
  }

  Future<List<LotMaster>> _filterValidLots(
    List<LotMaster> lots,
    int branchId,
    int itemId,
    int companyId,
  ) async {
    final validLots = <LotMaster>[];

    for (final lot in lots) {
      // Check if lot has available quantity
      if (lot.quantityAvailable! <= 0) continue;

      // Check expiration status
      final expirationColor = await expirationColorsRepository
          .getLotExpirationColorByDetails(
            branchId: branchId,
            itemId: itemId,
            daysDifference: int.parse(lot.dateExpiration.toString()),
            companyId: companyId,
          );

      // Only include lots that are active for sales
      if (expirationColor?.activeForSalesFlag == 'Y') {
        validLots.add(lot);
      }
    }

    // Sort by expiration date (FEFO) or receipt date (FIFO)
    validLots.sort((a, b) => a.dateExpiration!.compareTo(b.dateExpiration!));

    return validLots;
  }

  Future<LotValidationResult> _validateSelectedLot(
    LotMaster selectedLot,
    double requestedQuantity,
    List<LotMaster> validLots,
    SystemConstant systemConstants,
  ) async {
    // Check if selected lot is in valid lots
    final isValidLot = validLots.any((lot) => lot.id == selectedLot.id);

    if (!isValidLot) {
      return LotValidationResult(
        isValid: false,
        availableQuantity: 0.0,
        message: 'Selected lot is not valid or available for sales',
        availableLots: validLots,
      );
    }

    // Check quantity availability
    if (selectedLot.quantityAvailable! < requestedQuantity) {
      return LotValidationResult(
        isValid: false,
        availableQuantity: selectedLot.quantityAvailable!,
        message: 'Insufficient quantity in selected lot',
        availableLots: validLots,
      );
    }

    return LotValidationResult(
      isValid: true,
      recommendedLot: selectedLot,
      availableQuantity: selectedLot.quantityAvailable!,
      message: 'Lot validation successful',
      availableLots: validLots,
    );
  }

  Future<LotValidationResult> _autoSelectLot(
    List<LotMaster> validLots,
    double requestedQuantity,
    SystemConstant systemConstants,
  ) async {
    double remainingQuantity = requestedQuantity;
    final List<LotMaster> allocatedLots = [];

    for (final lot in validLots) {
      if (remainingQuantity <= 0) break;

      final quantityFromThisLot = lot.quantityAvailable! >= remainingQuantity
          ? remainingQuantity
          : lot.quantityAvailable!;

      allocatedLots.add(lot.copyWith(quantityAvailable: quantityFromThisLot));
      remainingQuantity -= quantityFromThisLot;
    }

    if (remainingQuantity > 0) {
      return LotValidationResult(
        isValid: false,
        availableQuantity: requestedQuantity - remainingQuantity,
        message: 'Insufficient quantity across all lots',
        availableLots: validLots,
      );
    }

    return LotValidationResult(
      isValid: true,
      recommendedLot: allocatedLots.first, // Use first allocated lot
      availableQuantity: requestedQuantity,
      message: 'Auto-lot allocation successful',
      availableLots: validLots,
    );
  }

  // Update lot quantities after sale
  Future<void> updateLotQuantitiesAfterSale({
    required List<SalesOrderDetail> soldItems,
    required int companyId,
  }) async {
    for (final item in soldItems) {
      if (item.lotNumber != null && item.quantity != null) {
        await lotMasterRepository.updateLotMaster(item.lot!);
      }
    }
  }

  // Restore lot quantities for voided sales
  Future<void> restoreLotQuantitiesForVoid({
    required List<SalesOrderDetail> voidedItems,
    required int companyId,
  }) async {
    for (final item in voidedItems) {
      if (item.lotNumber != null && item.quantity != null) {
        await lotMasterRepository.restoreLotQuantity(
          item.lotNumber!,
          item.quantity!,
          companyId,
        );
      }
    }
  }
}
