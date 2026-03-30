// features/purchase_order/services/purchase_order_stock_service.dart
import 'dart:developer' as developer;
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:savvy_stock/core/repositories/udc_repository.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/models/purchase_order_receiver_model.dart';
import 'package:savvy_stock/features/stock/item_uom_conversions/repo/item_uom_conv_repo.dart';
import 'package:savvy_stock/features/stock/item_in_branch/repo/item_in_branch_repo.dart';
import 'package:savvy_stock/features/stock/item_locations/repo/item_location_repo.dart';
import 'package:savvy_stock/features/stock/item_transactions/repo/item_transaction_repo.dart';
import 'package:savvy_stock/features/stock/lot_coloring/repo/lot_expiration_repo.dart';
import 'package:savvy_stock/features/stock/lot_master/models/lot_master_model.dart';
import 'package:savvy_stock/features/stock/lot_master/repo/lot_master_repo.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_bloc.dart';
import 'package:savvy_stock/features/system_constant/models/system_constant.dart';

class PurchaseOrderStockService {
  final StockItemInBranchRepository stockItemInBranchRepository;
  final ItemTransactionRepository itemTransactionsRepository;
  final ItemLocationsRepository itemLocationsRepository;
  final ItemUomConversionsRepository itemUomConversionsRepository;
  final LotMasterRepository lotMasterRepository;
  final LotExpirationColorsRepository expirationColorsRepository;
  final SystemConstantBloc systemConstantBloc;
  final UdcRepository udcRepository;

  PurchaseOrderStockService({
    required this.itemTransactionsRepository,
    required this.stockItemInBranchRepository,
    required this.itemLocationsRepository,
    required this.itemUomConversionsRepository,
    required this.lotMasterRepository,
    required this.expirationColorsRepository,
    required this.systemConstantBloc,
    required this.udcRepository,
  });

  // ============ MAIN STOCK UPDATE METHOD (Mimics Java Controller) ============
  Future<void> updateStockItemAvailabilityPor({
    required PurchaseOrderReceiver receiver,
    required int companyId,
    required int orderNumber,
  }) async {
    try {
      if (kDebugMode) {
        developer.log('📦 Starting stock update for receiver:');
        developer.log('  itemNumber: ${receiver.itemNumber}');
        developer.log('  branchRecieved: ${receiver.branchRecieved}');
        developer.log('  location: ${receiver.location}');
        developer.log('  unitOfMeasure: ${receiver.unitOfMeasure}');
      }

      // Validate receiver (same as Java)
      if (receiver.itemNumber == null ||
          receiver.quantityRecieved == null ||
          receiver.quantityRecieved == 0.0 ||
          receiver.branchRecieved == null) {
        if (kDebugMode) {
          developer.log('⚠️ Receiver validation failed, skipping stock update');
        }
        return; // Same early return as Java
      }

      final systemConstant = systemConstantBloc.state.selected;
      if (systemConstant == null) {
        throw Exception('System constants not loaded');
      }

      final applyLocationMgmt = systemConstant.applyLocationMgmBoolean;
      final applyLotMgmt = systemConstant.applyLotMgmBoolean;

      if (kDebugMode) {
        developer.log('  applyLocationMgmt: $applyLocationMgmt');
        developer.log('  applyLotMgmt: $applyLotMgmt');
      }

      // Case 1: No location or lot management
      if (!applyLocationMgmt && !applyLotMgmt) {
        if (kDebugMode) {
          developer.log('📍 Using simple stock update (no location/lot mgmt)');
        }
        await _handleSimpleStockUpdateForPurchase(
          receiver: receiver,
          systemConstant: systemConstant,
          companyId: companyId,
          orderNumber: orderNumber,
        );
      }
      // Case 2: Location management only
      else if (applyLocationMgmt &&
          !applyLotMgmt &&
          receiver.location != null) {
        if (kDebugMode) {
          developer.log('📍 Using location stock update');
        }
        await _handleLocationStockUpdateForPurchase(
          receiver: receiver,
          systemConstant: systemConstant,
          companyId: companyId,
          orderNumber: orderNumber,
        );
      }
      // Case 3: Both location and lot management
      else if (applyLocationMgmt && applyLotMgmt && receiver.location != null) {
        if (kDebugMode) {
          developer.log('📍 Using lot management');
        }
        await _handleLotManagementForPurchase(
          receiver: receiver,
          orderNumber: orderNumber,
          companyId: companyId,
        );
      }

      if (kDebugMode) {
        developer.log('✅ Stock update completed successfully');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        developer.log('❌ Error updating stock for purchase order: $e');
        developer.log('Stack trace: $stackTrace');
      }
      rethrow; // Rethrow to see the error in the bloc
    }
  }

  // ============ CASE 1: SIMPLE STOCK UPDATE ============
  Future<void> _handleSimpleStockUpdateForPurchase({
    required PurchaseOrderReceiver receiver,
    required SystemConstant systemConstant,
    required int companyId,
    required int orderNumber,
  }) async {
    // Validate unitOfMeasure is not null
    if (receiver.unitOfMeasure == null) {
      if (kDebugMode) {
        developer.log(
          '⚠️ UnitOfMeasure is null for receiver, skipping stock update',
        );
      }
      return;
    }

    // Find ItemsInBranch by company, item number, and branch (same as Java)
    final itemsInBranchList = await stockItemInBranchRepository
        .findByItemAndBranch(
          receiver.itemNumber!,
          receiver.branchRecieved!,
          companyId,
        );

    if (itemsInBranchList != null) {
      // Validate that branch has unitOfMeasure set
      if (itemsInBranchList.unitOfMeasure == null) {
        if (kDebugMode) {
          developer.log(
            '⚠️ ItemsInBranch.unitOfMeasure is null, skipping stock update',
          );
        }
        return;
      }

      // Get conversion factor from receiver UOM to branch UOM
      final factor = await itemUomConversionsRepository.fromOtherToAnother(
        receiver.itemNumber!,
        receiver.unitOfMeasure!,
        itemsInBranchList.unitOfMeasure!,
        companyId,
      );

      // Calculate quantities (same as Java)
      final currentQuantity = itemsInBranchList.quantityAvailable ?? 0.0;
      final receivedQuantityInBranchUom =
          factor * (receiver.quantityRecieved ?? 0.0);

      // Apply decimal places rounding if needed (from system constant)
      final decimalPlaces = systemConstant.decimalPlaces ?? 2;
      final roundedReceivedQuantity = _roundToDecimalPlaces(
        receivedQuantityInBranchUom,
        decimalPlaces,
      );

      final newQuantity = currentQuantity + roundedReceivedQuantity;

      // Update ItemsInBranch
      await stockItemInBranchRepository.updateQuantity(
        itemsInBranchList.id,
        newQuantity,
        companyId,
      );

      // Create stock card transaction (same as Java's stockCARDCreation)
      await itemTransactionsRepository.stockCardCreation(
        ib: itemsInBranchList,
        loc: null,
        lm: null,
        transactionType: 'R', // 'C' for Receipt/Purchase//C IS COMPLETE
        trNo: orderNumber,
        remark: 'Purchase',
        qty: roundedReceivedQuantity, // Positive quantity for purchase
        por: receiver,
        soD: null,
        supplier: receiver.poDetailRef?.poHeaderRef?.supplierId,
        orderType: receiver.poDetailRef?.poHeaderRef?.orderType,
      );
    }
  }

  // ============ CASE 2: LOCATION MANAGEMENT ONLY ============
  Future<void> _handleLocationStockUpdateForPurchase({
    required PurchaseOrderReceiver receiver,
    required SystemConstant systemConstant,
    required int companyId,
    required int orderNumber,
  }) async {
    // Get the ItemLocations
    final itemLocation = await itemLocationsRepository.getItemLocationById(
      receiver.location!,
      companyId,
    );

    if (itemLocation != null) {
      // Get branch UOM for the item (same as Java's itemBranchUoM)
      final branchUom = await _getItemBranchUom(
        itemNumber: receiver.itemNumber!,
        branchId: receiver.branchRecieved!,
        companyId: companyId,
      );

      if (branchUom != null) {
        // Get conversion factor
        final factor = await itemUomConversionsRepository.fromOtherToAnother(
          receiver.itemNumber!,
          receiver.unitOfMeasure!,
          branchUom,
          companyId,
        );
        if (kDebugMode &&
            factor == 1.0 &&
            receiver.unitOfMeasure != branchUom) {
          developer.log(
            '⚠️ Warning: UOM conversion factor is 1.0 but UOMs differ',
          );
          developer.log(
            '  From UOM: ${receiver.unitOfMeasure}, To UOM: $branchUom',
          );
        }
        if (kDebugMode) {
          developer.log('Factor: $factor');
        }

        // Calculate new quantity on hand
        final currentQuantity = itemLocation.quantityOnHand ?? 0.0;
        final receivedQuantity = factor * (receiver.quantityRecieved ?? 0.0);
        final roundedReceivedQuantity = _roundToDecimalPlaces(
          receivedQuantity,
          systemConstant.decimalPlaces ?? 2,
        );

        final newQuantity = currentQuantity + roundedReceivedQuantity;

        if (kDebugMode) {
          developer.log('New Quantity for location: $newQuantity');
          developer.log('Rounded Received Quantity: $roundedReceivedQuantity');
        }

        // Update ItemLocations (use updateItemLocation for existing locations)
        await itemLocationsRepository.updateItemLocation(
          itemLocation.copyWith(quantityOnHand: newQuantity),
        );

        // Also update ItemsInBranch total quantity (cascading update)
        await _updateItemsInBranchQuantity(
          itemNumber: receiver.itemNumber!,
          branchId: receiver.branchRecieved!,
          quantity: roundedReceivedQuantity,
          companyId: companyId,
        );

        // Get ItemsInBranch for stock card transaction
        final itemsInBranch = await stockItemInBranchRepository
            .findByItemAndBranch(
              receiver.itemNumber!,
              receiver.branchRecieved!,
              companyId,
            );

        // Create stock card transaction (same as Java's stockCARDCreation)
        await itemTransactionsRepository.stockCardCreation(
          ib: itemsInBranch,
          loc: itemLocation.copyWith(quantityOnHand: newQuantity),
          lm: null,
          transactionType: 'R', // Receipt/Purchase
          trNo: orderNumber,
          remark: 'Purchase',
          qty: roundedReceivedQuantity,
          por: receiver,
          soD: null,
          supplier: receiver.poDetailRef?.poHeaderRef?.supplierId,
          orderType: receiver.poDetailRef?.poHeaderRef?.orderType,
        );
      }
    }
  }

  // ============ CASE 3: LOCATION AND LOT MANAGEMENT ============
  Future<void> _handleLotManagementForPurchase({
    required PurchaseOrderReceiver receiver,
    required int orderNumber,
    required int companyId,
  }) async {
    // Auto create lot for purchase order (same as Java's autoCreatingLotForPO)
    await _autoCreateLotForPurchaseOrder(
      receiver: receiver,
      orderNumber: orderNumber,
      companyId: companyId,
    );
  }

  // ============ AUTO CREATE LOT FOR PURCHASE ORDER (Java Implementation) ============
  Future<void> _autoCreateLotForPurchaseOrder({
    required PurchaseOrderReceiver receiver,
    required int orderNumber,
    required int companyId,
  }) async {
    try {
      final systemConstant = systemConstantBloc.state.selected;
      if (systemConstant == null) return;

      final lotType = systemConstant.lotType;
      if (lotType == null) return;
      final lotTypeDetail = await udcRepository.getUdcDetailById(lotType);
      final lotTypeCodeId = lotTypeDetail?.detailCode;

      // Check conditions same as Java
      final hasExpirationDate = receiver.dateExpiration != null;
      final hasEffectiveDate = receiver.dateEffective != null;
      final hasReceivedDate = receiver.dateReceived != null;

      final shouldCreateLot =
          ((lotTypeCodeId == null || lotTypeCodeId == 'X') &&
              hasExpirationDate) ||
          (lotTypeCodeId == 'F' && hasEffectiveDate) ||
          (lotTypeCodeId == 'R' && hasReceivedDate);

      if (!shouldCreateLot) return;

      List<LotMaster> lotMasterList = [];

      // Query lots based on date (same as Java)
      if ((lotTypeCodeId == null || lotTypeCodeId == 'X') &&
          hasExpirationDate) {
        lotMasterList = await lotMasterRepository.getLotMastersByExpirationDate(
          dateExpiration: receiver.dateExpiration!,
          companyId: companyId,
        );
      } else if (lotTypeCodeId == 'F' && hasEffectiveDate) {
        lotMasterList = await lotMasterRepository.getLotMastersByEffectiveDate(
          dateEffective: receiver.dateEffective!,
          companyId: companyId,
        );
      } else if (lotTypeCodeId == 'R' && hasReceivedDate) {
        lotMasterList = await lotMasterRepository.getLotMastersByReceivedDate(
          dateReceived: receiver.dateReceived!,
          companyId: companyId,
        );
      }

      // Sort by lot number descending (same as Java)
      lotMasterList.sort((a, b) => b.lotNumber!.compareTo(a.lotNumber ?? 0));

      // Get next lot number
      final nextLotNumber = lotMasterList.isEmpty
          ? await lotMasterRepository.getNextLotNumber(
              companyId: companyId,
            ) // You need to implement this
          : lotMasterList.first.lotNumber!;

      // Get branch UOM for conversion
      final branchUom = await _getItemBranchUom(
        itemNumber: receiver.itemNumber!,
        branchId: receiver.branchRecieved!,
        companyId: companyId,
      );

      if (branchUom == null) return;

      // Calculate quantity in branch UOM
      final factor = await itemUomConversionsRepository.fromOtherToAnother(
        receiver.itemNumber!,
        receiver.unitOfMeasure!,
        branchUom,
        companyId,
      );

      final qty = factor * (receiver.quantityRecieved ?? 0.0);

      // Create new lot master
      final newLot = LotMaster(
        lotNumber: nextLotNumber,
        company: companyId,
        branch: receiver.branchRecieved,
        itemNumber: receiver.itemNumber,
        location: receiver.location,
        quantityAvailable: qty,
        dateEffective: receiver.dateEffective,
        dateExpiration: receiver.dateExpiration,
        dateReceived: receiver.dateReceived,
        lotStatus: await _lotStatusIdentifier(
          dateEffective: receiver.dateEffective,
          dateExpiration: receiver.dateExpiration,
          dateReceived: receiver.dateReceived,
          currentStatusId: null,
        ),
        batchNumberSupplier: receiver.batchNumberSupplier,
        unitPrice: await _getItemBranchUnitPrice(
          itemNumber: receiver.itemNumber!,
          branchId: receiver.branchRecieved!,
          companyId: companyId,
        ),
      );

      // Save the lot and capture its ID
      final newLotId = await lotMasterRepository.createLotMaster(newLot);
      final persistedLot = newLot.copyWith(id: newLotId);

      // Update item location quantity (same as Java's updatingItemLocationQuantity)
      await _updateItemLocationQuantity(
        lot: persistedLot,
        transactionType: 'R',
        trNo: orderNumber,
        remark: 'Purchase',
        qtyTr: qty,
        por: receiver,
      );
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error auto-creating lot for purchase order: $e');
      }
      // Don't rethrow - same as Java
    }
  }

  // ============ LOT STATUS IDENTIFIER (Java Implementation) ============
  Future<int?> _lotStatusIdentifier({
    DateTime? dateEffective,
    DateTime? dateExpiration,
    DateTime? dateReceived,
    int? currentStatusId,
  }) async {
    final systemConstant = systemConstantBloc.state.selected;
    if (systemConstant == null) return null;

    final lotType = systemConstant.lotType;
    if (lotType == null) return null;
    final lotTypeDetail = await udcRepository.getUdcDetailById(lotType);
    final lotTypeCodeId = lotTypeDetail?.detailCode;

    bool valid = false;
    DateTime? targetDate;

    if (lotTypeCodeId == 'X' && dateExpiration != null) {
      valid = true;
      targetDate = dateExpiration;
    } else if (lotTypeCodeId == 'F' && dateEffective != null) {
      valid = true;
      targetDate = dateEffective;
    } else if (lotTypeCodeId == 'R' && dateReceived != null) {
      valid = true;
      targetDate = dateReceived;
    }

    if (valid && targetDate != null) {
      final now = DateTime.now();
      final daysDifference = targetDate.difference(now).inDays;

      if (lotTypeCodeId != 'R') {
        if (daysDifference <= 0) {
          // Expired status
          return await _getUdcDetailId('E', 'LS');
        } else {
          // Active status, preserve current if not expired
          if (currentStatusId != null) {
            final currentStatus = await udcRepository.getUdcDetailById(
              currentStatusId,
            );
            if (currentStatus?.detailCode != 'E') {
              return currentStatusId;
            }
          }
          return await _getUdcDetailId('A', 'LS');
        }
      } else {
        // Received date type - always active unless explicitly set
        return currentStatusId ?? await _getUdcDetailId('A', 'LS');
      }
    }

    return null;
  }

  // ============ UPDATE ITEM LOCATION QUANTITY (Java Implementation) ============
  Future<void> _updateItemLocationQuantity({
    required LotMaster lot,
    required String transactionType,
    required int trNo,
    required String remark,
    required double qtyTr,
    required PurchaseOrderReceiver por,
  }) async {
    if (lot.itemNumber == null ||
        lot.branch == null ||
        lot.location == null ||
        lot.company == null) {
      return;
    }

    try {
      // 1) Cascade lot quantities to item_location and items_in_branch
      //    (sums ALL lots for this item/branch/location, not only expired ones)
      await lotMasterRepository.updatingItemLocationQuantityFromLot(
        lot: lot,
        transactionType: transactionType,
        trNo: trNo,
        remark: remark,
        qtyChange: qtyTr,
        soD: null,
        companyId: lot.company!,
      );

      // 2) Create stock card entry based on the lot movement
      await itemTransactionsRepository.stockCardCreation(
        ib: null,
        loc: null,
        lm: lot,
        transactionType: transactionType,
        trNo: trNo,
        remark: remark,
        qty: qtyTr,
        por: por,
        soD: null,
        supplier: por.poDetailRef?.poHeaderRef?.supplierId,
        orderType: por.poDetailRef?.poHeaderRef?.orderType,
      );
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error updating item location quantity: $e');
      }
    }
  }

  // ============ HELPER METHODS ============

  Future<int?> _getItemBranchUom({
    required int itemNumber,
    required int branchId,
    required int companyId,
  }) async {
    final itemsInBranch = await stockItemInBranchRepository.findByItemAndBranch(
      itemNumber,
      branchId,
      companyId,
    );
    return itemsInBranch?.unitOfMeasure;
  }

  Future<double?> _getItemBranchUnitPrice({
    required int itemNumber,
    required int branchId,
    required int companyId,
  }) async {
    final itemsInBranch = await stockItemInBranchRepository.findByItemAndBranch(
      itemNumber,
      branchId,
      companyId,
    );
    return itemsInBranch?.unitPrice;
  }

  Future<void> _updateItemsInBranchQuantity({
    required int itemNumber,
    required int branchId,
    required double quantity,
    required int companyId,
  }) async {
    try {
      final itemsInBranch = await stockItemInBranchRepository
          .findByItemAndBranch(itemNumber, branchId, companyId);

      if (itemsInBranch != null) {
        final currentQuantity = itemsInBranch.quantityAvailable ?? 0.0;
        final newQuantity = currentQuantity + quantity;
        if (kDebugMode) {
          developer.log('New Quantityyy for ib: $newQuantity');
        }

        await stockItemInBranchRepository.updateQuantity(
          itemsInBranch.id,
          newQuantity,
          companyId,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('Failed to update ItemsInBranch quantity: $e');
      }
    }
  }

  Future<void> _updateItemsInBranchTotalQuantity({
    required int itemNumber,
    required int branchId,
    required int companyId,
  }) async {
    try {
      // Get all item locations for this item and branch
      final locations = await itemLocationsRepository
          .getItemLocationsByBranchAndItem(
            companyId: companyId,
            branchId: branchId,
            itemId: itemNumber,
          );

      // Calculate total quantity from all locations
      final totalQuantity = locations
          .where((loc) => loc.quantityOnHand != null)
          .map((loc) => loc.quantityOnHand!)
          .fold(0.0, (sum, qty) => sum + qty);

      // Update ItemsInBranch
      final itemsInBranch = await stockItemInBranchRepository
          .findByItemAndBranch(itemNumber, branchId, companyId);

      if (itemsInBranch != null) {
        await stockItemInBranchRepository.updateQuantity(
          itemsInBranch.id,
          totalQuantity,
          companyId,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('Failed to update ItemsInBranch total quantity: $e');
      }
    }
  }

  Future<int?> _getUdcDetailId(String detailCode, String udcHeader) async {
    try {
      final udcDetails = await udcRepository.getUdcDetailsByCode(
        detailCode,
        udcHeader,
      );
      return udcDetails.isNotEmpty ? udcDetails.first.id : null;
    } catch (e) {
      return null;
    }
  }

  double _roundToDecimalPlaces(double value, int decimalPlaces) {
    if (decimalPlaces == 0) return value.roundToDouble();
    final factor = pow(10, decimalPlaces);
    return (value * factor).roundToDouble() / factor;
  }
}
