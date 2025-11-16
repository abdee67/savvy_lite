// Case 1: Simple stock update without location/lot management
import 'package:savvy_stock/core/repositories/udc_repository.dart';
import 'package:savvy_stock/features/sales/sales_order/detail/model/sales_order_detail.dart';
import 'package:savvy_stock/features/sales/sales_order/header/bloc/sales_order_header_state.dart';
import 'package:savvy_stock/features/stock/item_uom_conversions/repo/item_uom_conv_repo.dart';
import 'package:savvy_stock/features/stock/item_in_branch/models/item_in_branch_model.dart';
import 'package:savvy_stock/features/stock/item_in_branch/repo/item_in_branch_repo.dart';
import 'package:savvy_stock/features/stock/item_locations/repo/item_location_repo.dart';
import 'package:savvy_stock/features/stock/item_transactions/repo/item_transaction_repo.dart';
import 'package:savvy_stock/features/stock/lot_coloring/model/lot_coloring_model.dart';
import 'package:savvy_stock/features/stock/lot_coloring/repo/lot_expiration_repo.dart';
import 'package:savvy_stock/features/stock/lot_master/models/lot_master_model.dart';
import 'package:savvy_stock/features/stock/lot_master/repo/lot_master_repo.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_bloc.dart';
import 'package:savvy_stock/features/system_constant/models/system_constant.dart';

class ValidateStockAvailabilityService {
  @override
  final StockItemInBranchRepository stockItemInBranchRepository;
  final ItemTransactionRepository itemTransactionsRepository;
  final ItemLocationsRepository itemLocationsRepository;
  final ItemUomConversionsRepository itemUomConversionsRepository;
  final LotMasterRepository lotMasterRepository;
  final LotExpirationColorsRepository expirationColorsRepository;
  final SystemConstantBloc systemConstantBloc;
  final UdcRepository udcRepository;

  ValidateStockAvailabilityService({
    required this.itemTransactionsRepository,
    required this.stockItemInBranchRepository,
    required this.itemLocationsRepository,
    required this.itemUomConversionsRepository,
    required this.lotMasterRepository,
    required this.expirationColorsRepository,
    required this.systemConstantBloc,
    required this.udcRepository,
  });

  // Case 3: Both location and lot management
  Future<void> handleLotStockUpdate(
    SalesOrderDetail soD,
    double factor,
    int companyId,
  ) async {
    final systemConstant = systemConstantBloc.state.selected;
    final lotType = systemConstant?.lotType;
    final lotTypeCode = await udcRepository.getUdcDetailById(lotType);
    final lotTypeCodeId = lotTypeCode?.detailCode;
    List<LotMaster> lotMasterList = [];

    // Check if manual lot selection is enabled and lot is provided
    if (!(systemConstant?.lotQtyAutoForSalesBoolean ?? true) &&
        soD.lotNumber != null) {
      lotMasterList.add(soD.lot!);
    } else {
      // Automatic lot selection - get all available lots
      lotMasterList = await lotMasterRepository.getLotMastersByItemAndBranch(
        itemNumber: soD.itemsTableId!,
        branch: soD.itemBranch!.branch,
        companyId: companyId,
      );

      // Filter out expired lots and those with no quantity
      lotMasterList = lotMasterList
          .where(
            (lot) =>
                lot.statusCode != 'E' && // Exclude expired
                lot.quantityAvailable != null &&
                lot.quantityAvailable! > 0,
          )
          .toList();

      // Apply additional filtering and sorting based on lot type
      lotMasterList = await _filterAndSortLotsForSales(
        lotMasterList,
        soD,
        companyId,
        lotTypeCodeId,
      );
    }

    double remainingQty = factor * soD.quantity!;

    for (final lot in lotMasterList) {
      if (remainingQty <= 0) break;

      final currentLot = await lotMasterRepository.getLotMasterById(
        lot.id!,
        companyId,
      );
      final availableQty = currentLot?.quantityAvailable ?? 0.0;

      if (availableQty >= remainingQty) {
        // This lot has enough stock
        final newQty = availableQty - remainingQty;
        final updatedLot = currentLot?.copyWith(quantityAvailable: newQty);

        await lotMasterRepository.updateLotMaster(updatedLot!);

        // Create transaction for this lot
        await itemTransactionsRepository.stockCardCreation(
          ib: null,
          loc: null,
          lm: updatedLot,
          transactionType: 'I',
          trNo: soD.orderHeader?.orderNumber,
          remark: 'Sales',
          qty: -remainingQty,
          por: null,
          soD: soD,
        );

        remainingQty = 0;
      } else {
        // Take all available from this lot
        final updatedLot = currentLot?.copyWith(quantityAvailable: 0.0);
        await lotMasterRepository.updateLotMaster(updatedLot!);

        // Create transaction for this lot
        await itemTransactionsRepository.stockCardCreation(
          ib: null,
          loc: null,
          lm: updatedLot,
          transactionType: 'I',
          trNo: soD.orderHeader?.orderNumber,
          remark: 'Sales',
          qty: -availableQty,
          por: null,
          soD: soD,
        );

        remainingQty -= availableQty;
      }
    }

    if (remainingQty > 0) {
      throw Exception(
        'Insufficient stock across lots. Remaining: $remainingQty',
      );
    }

    // Update the main item branch quantity
    await updateItemBranchQuantity(soD, factor, companyId);
  }

  // Helper method to filter and sort lots for sales
  Future<List<LotMaster>> _filterAndSortLotsForSales(
    List<LotMaster> lots,
    SalesOrderDetail soD,
    int companyId,
    String? lotTypeCodeId,
  ) async {
    final systemConstant = systemConstantBloc.state.selected;
    final lotType = systemConstant?.lotType;
    final lotTypeCode = await udcRepository.getUdcDetailById(lotType);
    final lotTypeCodeId = lotTypeCode?.detailCode;
    List<LotMaster> filteredLots = [];

    for (final lot in lots) {
      bool isActiveForSales = await _isLotActiveForSales(
        soD,
        lot,
        lotTypeCodeId,
        companyId,
      );
      if (isActiveForSales) {
        filteredLots.add(lot);
      }
    }

    // Sort based on lot type
    if (lotTypeCodeId == null || lotTypeCodeId == 'X') {
      // Sort by expiration date
      filteredLots.sort(
        (a, b) => (a.dateExpiration ?? DateTime.now()).compareTo(
          b.dateExpiration ?? DateTime.now(),
        ),
      );
    } else if (lotTypeCodeId == 'F') {
      // Sort by effective date
      filteredLots.sort(
        (a, b) => (a.dateEffective ?? DateTime.now()).compareTo(
          b.dateEffective ?? DateTime.now(),
        ),
      );
    } else if (lotTypeCodeId == 'R') {
      // Sort by received date
      filteredLots.sort(
        (a, b) => (a.dateReceived ?? DateTime.now()).compareTo(
          b.dateReceived ?? DateTime.now(),
        ),
      );
    }

    return filteredLots;
  }

  // Helper method to check if lot is active for sales
  Future<bool> _isLotActiveForSales(
    SalesOrderDetail soD,
    LotMaster lot,
    String? lotType,
    int companyId,
  ) async {
    try {
      LotExpirationColor? expirationColor;

      if (lotType == null || lotType == 'X') {
        expirationColor = await expirationColorsRepository
            .getLotExpirationColorByDetails(
              branchId: soD.itemBranch!.branch,
              itemId: soD.itemsTableId!,
              companyId: companyId,
              daysDifference: int.parse(
                lot.dateExpiration!
                    .difference(DateTime.now())
                    .inDays
                    .toString(),
              ),
            );
      } else if (lotType == 'F') {
        expirationColor = await expirationColorsRepository
            .getLotExpirationColorByDetails(
              branchId: soD.itemBranch!.branch,
              itemId: soD.itemsTableId!,
              daysDifference: int.parse(
                lot.dateEffective!.difference(DateTime.now()).inDays.toString(),
              ),
              companyId: companyId,
            );
      } else if (lotType == 'R') {
        expirationColor = await expirationColorsRepository
            .getLotExpirationColorByDetails(
              branchId: soD.itemBranch!.branch,
              itemId: soD.itemsTableId!,
              daysDifference: int.parse(
                lot.dateReceived!.difference(DateTime.now()).inDays.toString(),
              ),
              companyId: companyId,
            );
      }

      // If no expiration color rule exists, or if it exists and allows sales
      return expirationColor == null ||
          expirationColor.activeForSalesFlag == 'Y';
    } catch (e) {
      // If there's an error checking, assume it's active for sales
      return true;
    }
  }

  // Helper method for lot-level validation
  Future<({double availableQty, String message, bool isValid})>
  validateLotLevelAvailability(SalesOrderDetail soD, int companyId) async {
    try {
      // Get available lots for this item and branch
      List<LotMaster> availableLots = await lotMasterRepository
          .getLotMastersByItemAndBranch(
            itemNumber: soD.itemsTableId!,
            branch: soD.itemBranch!.branch,
            companyId: companyId,
          );

      // Filter lots based on system configuration (like Java logic)
      final systemConstant = systemConstantBloc.state.selected;
      final lotType = systemConstant?.lotType;
      final lotTypeCode = await udcRepository.getUdcDetailById(lotType);
      final lotTypeCodeId = lotTypeCode?.detailCode;

      // Apply filtering similar to Java implementation
      availableLots = availableLots
          .where((lot) => lot.statusCode != 'E') // Exclude expired
          .where(
            (lot) =>
                lot.quantityAvailable != null && lot.quantityAvailable! > 0,
          )
          .toList();

      // Apply additional filtering based on lot type and expiration colors
      availableLots = await _filterAndSortLotsForSales(
        availableLots,
        soD,
        companyId,
        lotTypeCodeId,
      );

      // Calculate total available quantity from valid lots
      double totalAvailable = availableLots.fold(
        0.0,
        (sum, lot) => sum + (lot.quantityAvailable ?? 0.0),
      );

      // Check if specific lot is selected (manual lot selection)
      if (!(systemConstant?.lotQtyAutoForSalesBoolean ?? true) &&
          soD.lotNumber != null) {
        final selectedLot = availableLots.firstWhere(
          (lot) => lot.id == soD.lot!.id,
          orElse: () => LotMaster(),
        );

        if (selectedLot.id == null) {
          return (
            availableQty: 0.0,
            message: 'Selected lot not available for sales',
            isValid: false,
          );
        }

        final lotQty = selectedLot.quantityAvailable ?? 0.0;
        return (
          availableQty: lotQty,
          message:
              'Lot-level: ${lotQty.toStringAsFixed(2)} available in selected lot',
          isValid: lotQty > 0,
        );
      }

      return (
        availableQty: totalAvailable,
        message:
            'Lot-level: ${totalAvailable.toStringAsFixed(2)} available across ${availableLots.length} lots',
        isValid: totalAvailable > 0,
      );
    } catch (e) {
      return (
        availableQty: 0.0,
        message: 'Error checking lot availability: $e',
        isValid: false,
      );
    }
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

  // Case 2: Location management only
  Future<void> handleLocationStockUpdate(
    SalesOrderDetail soD,
    double factor,
    int companyId,
  ) async {
    // Get all item locations for this item and branch
    final itemLocationsList = await itemLocationsRepository
        .getItemLocationsByBranchAndItem(
          companyId: companyId,
          branchId: soD.itemBranch!.branch,
          itemId: soD.itemsTableId!,
        );

    // Filter locations with available stock
    final availableLocations = itemLocationsList
        .where((il) => il.quantityOnHand != null && il.quantityOnHand! > 0)
        .toList();

    double remainingQty = factor * soD.quantity!;

    for (final location in availableLocations) {
      if (remainingQty <= 0) break;

      final currentLocation = await itemLocationsRepository.getItemLocationById(
        location.id!,
        companyId,
      );
      final availableQty = currentLocation?.quantityOnHand ?? 0.0;

      if (availableQty >= remainingQty) {
        // This location has enough stock
        final newQty = availableQty - remainingQty;
        final updatedLocation = currentLocation?.copyWith(
          quantityOnHand: newQty,
        );

        await itemLocationsRepository.updateItemLocation(updatedLocation!);

        // Create transaction for this location
        await itemTransactionsRepository.stockCardCreation(
          ib: null,
          loc: updatedLocation,
          lm: null,
          transactionType: 'I',
          trNo: soD.orderHeader?.orderNumber,
          remark: 'Sales',
          qty: -remainingQty,
          por: null,
          soD: soD,
        );

        remainingQty = 0;
      } else {
        // Take all available from this location
        final updatedLocation = currentLocation?.copyWith(quantityOnHand: 0.0);
        await itemLocationsRepository.updateItemLocation(updatedLocation!);

        // Create transaction for this location
        await itemTransactionsRepository.stockCardCreation(
          ib: null,
          loc: updatedLocation,
          lm: null,
          transactionType: 'I',
          trNo: soD.orderHeader?.orderNumber,
          remark: 'Sales',
          qty: -availableQty,
          por: null,
          soD: soD,
        );

        remainingQty -= availableQty;
      }
    }

    if (remainingQty > 0) {
      throw Exception(
        'Insufficient stock across locations. Remaining: $remainingQty',
      );
    }

    // Update the main item branch quantity
    await updateItemBranchQuantity(soD, factor, companyId);
  }

  Future<({double availableQty, String message, bool isValid})>
  validateLocationLevelAvailability(SalesOrderDetail soD, int companyId) async {
    try {
      // Get all locations for this item and branch
      final locations = await itemLocationsRepository
          .getItemLocationsByBranchAndItem(
            itemId: soD.itemsTableId!,
            branchId: soD.itemBranch!.branch,
            companyId: companyId,
          );

      // Filter locations with available stock
      final availableLocations = locations
          .where((loc) => loc.quantityOnHand != null && loc.quantityOnHand! > 0)
          .toList();

      // Calculate total available quantity across locations
      double totalAvailable = availableLocations.fold(
        0.0,
        (sum, loc) => sum + (loc.quantityOnHand ?? 0.0),
      );

      return (
        availableQty: totalAvailable,
        message:
            'Location-level: ${totalAvailable.toStringAsFixed(2)} available across ${availableLocations.length} locations',
        isValid: totalAvailable > 0,
      );
    } catch (e) {
      return (
        availableQty: 0.0,
        message: 'Error checking location availability: $e',
        isValid: false,
      );
    }
  }

  Future<void> handleSimpleStockUpdate(
    SalesOrderDetail soD,
    double factor,
    int companyId,
  ) async {
    final itemsInBranch = await stockItemInBranchRepository.findByItemAndBranch(
      soD.itemsTableId!,
      soD.itemBranch!.branch,
      companyId,
    );

    if (itemsInBranch != null) {
      final qtyToSubtract = factor * soD.quantity!;
      final newQty = (itemsInBranch.quantityAvailable ?? 0.0) - qtyToSubtract;

      // Update item branch quantity
      await stockItemInBranchRepository.updateQuantity(
        itemsInBranch.id,
        newQty,
        companyId,
      );

      // Create stock card entry - equivalent to Java's stockCARDCreation
      await itemTransactionsRepository.stockCardCreation(
        ib: itemsInBranch,
        loc: null,
        lm: null,
        transactionType: 'I', // 'I' for Issue/Sales
        trNo: soD.orderHeader?.orderNumber,
        remark: 'Sales',
        qty: -soD.quantity!, // Negative quantity for sales
        por: null,
        soD: soD,
      );
    } else {
      throw Exception(
        'Item branch not found for item: ${soD.itemsTableId}, branch: ${soD.itemBranch!.branch}',
      );
    }
  }

  Future<({double availableQty, String message, bool isValid})>
  validateBranchLevelAvailability(SalesOrderDetail soD, int companyId) async {
    try {
      // Get item branch quantity
      final itemBranch = await stockItemInBranchRepository.findByItemAndBranch(
        soD.itemsTableId!,
        soD.itemBranch!.branch,
        companyId,
      );

      if (itemBranch == null) {
        return (
          availableQty: 0.0,
          message: 'Item branch not found',
          isValid: false,
        );
      }

      final availableQty = itemBranch.quantityAvailable ?? 0.0;

      // Check for expired lots if lot management exists but isn't enforced
      double expiredQuantity = 0.0;
      try {
        expiredQuantity = await lotMasterRepository.calculateExpiredLotQuantity(
          soD,
          companyId,
        );
      } catch (e) {
        // Ignore expiration calculation errors for simple validation
      }

      final actualAvailable = availableQty - expiredQuantity;

      return (
        availableQty: actualAvailable,
        message:
            'Branch-level: ${actualAvailable.toStringAsFixed(2)} available (${expiredQuantity > 0 ? '${expiredQuantity.toStringAsFixed(2)} expired' : 'no expired stock'})',
        isValid: actualAvailable > 0,
      );
    } catch (e) {
      return (
        availableQty: 0.0,
        message: 'Error checking branch availability: $e',
        isValid: false,
      );
    }
  }

  // Helper method to update item branch quantity after location/lot updates
  Future<void> updateItemBranchQuantity(
    SalesOrderDetail soD,
    double factor,
    int companyId,
  ) async {
    final itemsInBranch = await stockItemInBranchRepository.findByItemAndBranch(
      soD.itemsTableId!,
      soD.itemBranch!.branch,
      companyId,
    );

    if (itemsInBranch != null) {
      // Recalculate total available quantity from locations/lots
      double totalAvailable = 0.0;

      if (systemConstantBloc.state.selected?.applyLocationMgmBoolean ?? false) {
        final locations = await itemLocationsRepository
            .getItemLocationsByBranchAndItem(
              branchId: soD.itemBranch!.branch,
              itemId: soD.itemsTableId!,
              companyId: companyId,
            );
        totalAvailable = locations.fold(
          0.0,
          (sum, location) => sum + (location.quantityOnHand ?? 0.0),
        );
      } else if (systemConstantBloc.state.selected?.applyLotMgmBoolean ??
          false) {
        final lots = await lotMasterRepository.getLotMastersByItemAndBranch(
          branch: soD.itemBranch!.branch,
          itemNumber: soD.itemsTableId!,
          companyId: companyId,
        );
        totalAvailable = lots.fold(
          0.0,
          (sum, lot) => sum + (lot.quantityAvailable ?? 0.0),
        );
      }

      // Convert back to primary UoM if needed
      final reverseFactor = await itemUomConversionsRepository
          .fromPrimaryToOther(
            soD.itemsTableId!,
            soD.unitOfMeasure ?? soD.itemBranch!.unitOfMeasure!,
            companyId,
          );

      final convertedQty = totalAvailable * reverseFactor;

      // Update item branch
      await stockItemInBranchRepository.updateQuantity(
        itemsInBranch.id,
        convertedQty,
        companyId,
      );
    }
  }

  double _validateLotManagement(SalesOrderDetail item) {
    final errors = <String>[];

    if (item.lotNumber == null) {
      errors.add('Lot number is required for ${item.item?.itemDescription}');
    } else if (item.lot?.quantityAvailable != null &&
        item.quantity != null &&
        item.lot!.quantityAvailable! < item.quantity!) {
      errors.add(
        'Insufficient quantity in selected lot for ${item.item?.itemDescription}',
      );
    }

    // Check lot expiration
    if (item.lot?.dateExpiration != null) {
      final daysToExpiry = item.lot!.dateExpiration!
          .difference(DateTime.now())
          .inDays;
      if (daysToExpiry < 30) {
        errors.add(
          'Lot for ${item.item?.itemDescription} expires in $daysToExpiry days',
        );
      }
    }

    return 0;
  }

  List<String> _validateBusinessRules(
    List<SalesOrderDetail> items,
    ItemInBranchModel itemBranch,
  ) {
    final errors = <String>[];

    // Validate minimum order amount
    final totalQuantity = items.fold(
      0.0,
      (sum, item) => sum + (item.quantity ?? 0),
    );
    final minOrderQuantity = itemBranch.reorderPoint ?? 0;

    if (totalQuantity < minOrderQuantity) {
      errors.add(
        'Order amount ($totalQuantity) is below minimum order amount ($minOrderQuantity)',
      );
    }

    return errors;
  }
}
