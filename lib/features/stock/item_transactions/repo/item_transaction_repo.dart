// repositories/item_transaction_repository.dart
import 'package:savvy_stock/features/purchase/purchase_entry/models/purchase_order_receiver_model.dart';
import 'package:savvy_stock/features/sales/sales_order/detail/model/sales_order_detail.dart';
import 'package:savvy_stock/features/stock/item_uom_conversions/repo/item_uom_conv_repo.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_bloc.dart';
import 'package:savvy_stock/core/repositories/udc_repository.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/next_number/bloc/next_number_bloc.dart';
import 'package:savvy_stock/features/stock/item_cost/repo/item_cost_repository.dart';
import 'package:savvy_stock/features/stock/item_in_branch/models/item_in_branch_model.dart';
import 'package:savvy_stock/features/stock/item_in_branch/repo/item_in_branch_repo.dart';
import 'package:savvy_stock/features/stock/item_locations/models/item_locations_model.dart';
import 'package:savvy_stock/features/stock/item_locations/repo/item_location_repo.dart';
import 'package:savvy_stock/features/stock/item_transactions/model/item_transaction_model.dart';
import 'package:savvy_stock/features/stock/lot_master/models/lot_master_model.dart';
import 'package:savvy_stock/features/stock/lot_master/repo/lot_master_repo.dart';
import 'package:savvy_stock/features/stock/item_uom_conversions/blocs/item_uom_conversions_bloc.dart';

class ItemTransactionRepository {
  final LocalDatabaseService databaseService;
  final AuthBloc authBloc;
  final SystemConstantBloc systemConstantBloc;
  final NextNumberBloc nextNumberBloc;
  final UdcRepository udcDetailsController;
  final ItemUomConversionBloc itemUomConversionBloc;

  // Use repositories instead of BLoCs for data access
  final StockItemInBranchRepository itemInBranchRepository;
  final ItemLocationsRepository itemLocationsRepository;
  final LotMasterRepository lotMasterRepository;

  final ItemUomConversionsRepository itemUomConversionRepository;
  final ItemCostRepository itemCostRepository;

  ItemTransactionRepository({
    required this.databaseService,
    required this.authBloc,
    required this.systemConstantBloc,
    required this.nextNumberBloc,
    required this.udcDetailsController,
    required this.itemUomConversionBloc,
    required this.itemInBranchRepository,
    required this.itemLocationsRepository,
    required this.lotMasterRepository,
    required this.itemUomConversionRepository,
    required this.itemCostRepository,
  });

  // Complex stock card creation equivalent to Java method
  Future<void> stockCardCreation({
    required ItemInBranchModel? ib,
    required ItemLocation? loc,
    required LotMaster? lm,
    required String transactionType,
    required int? trNo,
    required String? remark,
    required double qty,
    required PurchaseOrderReceiver? por,
    required SalesOrderDetail? soD,
  }) async {
    try {
      print(
        'DEBUG: stockCardCreation started. ib: $ib, loc: $loc, lm: $lm, qty: $qty',
      );
      if (ib != null || loc != null || lm != null) {
        final systemConstant = systemConstantBloc.state.selected;
        final applyLotMgmt = systemConstant?.applyLotMgmBoolean ?? false;
        final applyLocationMgmt =
            systemConstant?.applyLocationMgmBoolean ?? false;
        final user = authBloc.state.userId;
        final companyId = authBloc.state.companyId;

        if (user == null || companyId == null) {
          throw Exception('User not authenticated or company not set');
        }

        if (ib != null && !applyLocationMgmt && !applyLotMgmt && qty != 0.0) {
          print('DEBUG: Creating ItemBranchTransaction');
          await _createItemBranchTransaction(
            ib: ib,
            transactionType: transactionType,
            trNo: trNo,
            remark: remark,
            qty: qty,
            por: por,
            soD: soD,
            user: user.id,
            companyId: companyId,
          );
        } else if (loc != null &&
            applyLocationMgmt &&
            !applyLotMgmt &&
            qty != 0.0) {
          print('DEBUG: Creating LocationTransaction');
          await _createLocationTransaction(
            loc: loc,
            transactionType: transactionType,
            trNo: trNo,
            remark: remark,
            qty: qty,
            por: por,
            soD: soD,
            user: user.id,
            companyId: companyId,
          );
        } else if (lm != null &&
            applyLocationMgmt &&
            applyLotMgmt &&
            qty != 0.0) {
          print('DEBUG: Creating LotTransaction');
          await _createLotTransaction(
            lm: lm,
            transactionType: transactionType,
            trNo: trNo,
            remark: remark,
            qty: qty,
            por: por,
            soD: soD,
            user: user.id,
            companyId: companyId,
          );
        }
      }
    } catch (e, stackTrace) {
      print('DEBUG: Error in stock card creation: $e');
      print('DEBUG: StackTrace: $stackTrace');
      throw Exception('Error in stock card creation: $e');
    }
  }

  Future<void> _createItemBranchTransaction({
    required ItemInBranchModel ib,
    required String transactionType,
    required int? trNo,
    required String? remark,
    required double qty,
    required PurchaseOrderReceiver? por,
    required SalesOrderDetail? soD,
    required int user,
    required int companyId,
  }) async {
    final db = await databaseService.database;

    // Get transaction type UDC
    final udcList = await udcDetailsController.getLocalUdcDetailsByCode(
      transactionType,
      'TT',
    );
    if (udcList.isEmpty) {
      throw Exception(
        'Transaction type UDC not found for code: $transactionType',
      );
    }
    final udc = udcList.first;

    // Set transaction number
    int? trNumber = por != null
        ? por.poDetailRef?.poHeaderRef!.orderNumber
        : (soD != null ? soD.orderHeader?.orderNumber : trNo);

    trNumber ??= await nextNumberBloc.generateFormattedNumber('TN');

    // Calculate quantities and costs
    if (ib.itemNumber == 0 || ib.branch == 0) {
      throw Exception('Item branch missing item number or branch: ${ib.id}');
    }

    if (ib.unitOfMeasure == null) {
      throw Exception('Unit of measure is missing for item branch: ${ib.id}');
    }

    final factor = await itemUomConversionRepository.fromOtherToAnother(
      ib.itemNumber,
      ib.unitOfMeasure!,
      ib.unitOfMeasure!, // Same UoM for item branch
      companyId,
    );

    final qtyAvInStore = (ib.quantityAvailable ?? 0.0) + (factor * qty);

    final itemCost = await itemCostRepository.findByItem(
      ib.itemNumber,
      companyId,
    );
    final unitCost = itemCost?.amountUnitCost ?? 0.0;

    final factorP = await itemUomConversionRepository.fromOtherToPrimary(
      ib.itemNumber,
      ib.unitOfMeasure!,
      companyId,
    );

    final qTrn = (factorP * qty).abs();
    final amountCost = qTrn * unitCost;

    final qBfrTrn = (factorP * qtyAvInStore).abs();
    final beforeAmountCost = qBfrTrn * unitCost;

    // Create transaction
    final transaction = ItemTransactionModel(
      dateCreated: DateTime.now(),
      quantityTransaction: qty,
      beforeStoreQuantityAvailable: qtyAvInStore,
      unitCost: unitCost,
      amountCost: amountCost,
      beforeAmountCost: beforeAmountCost,
      company: companyId,
      createdBy: user,
      transactionType: udc.id,
      transactionNumber: trNumber,
      remark: remark ?? udc.description1,
      itemBranch: ib.id,
      itemNumber: ib.itemNumber,
      branch: ib.branch,
      unitOfMeasure: ib.unitOfMeasure,
      supplier: por?.poDetailRef?.poHeaderRef!.supplierId,
      orderType:
          por?.poDetailRef?.poHeaderRef!.orderType ??
          soD?.orderHeader?.orderTypeRef?.id,
      customer: soD?.orderHeader?.customerTableRef?.id,
    );

    await db.insert('item_transactions', transaction.toMap());

    // Update item branch quantity
    // final updatedIb = ib.copyWith(quantityAvailable: qtyAvInStore);(Not necessary fpr sales order it will update there not here)
    //await itemInBranchRepository.update(updatedIb);
  }

  Future<void> _createLocationTransaction({
    required ItemLocation loc,
    required String transactionType,
    required int? trNo,
    required String? remark,
    required double qty,
    required PurchaseOrderReceiver? por,
    required SalesOrderDetail? soD,
    required int user,
    required int companyId,
  }) async {
    final db = await databaseService.database;

    // Get transaction type UDC
    final udcList = await udcDetailsController.getLocalUdcDetailsByCode(
      transactionType,
      'TT',
    );
    if (udcList.isEmpty) {
      throw Exception(
        'Transaction type UDC not found for code: $transactionType',
      );
    }
    final udc = udcList.first;

    if (loc.itemNumber == null || loc.branch == null) {
      throw Exception('Location missing item number or branch: ${loc.id}');
    }

    // Get item branch
    final ib = await itemInBranchRepository.findByItemAndBranch(
      loc.itemNumber!,
      loc.branch!,
      companyId,
    );

    if (ib == null) {
      throw Exception(
        'Item branch not found for item: ${loc.itemNumber}, branch: ${loc.branch}',
      );
    }

    // Set transaction number
    int? trNumber = por != null
        ? por.poDetailRef?.poHeaderRef!.orderNumber
        : (soD != null ? soD.orderHeader?.orderNumber : trNo);

    trNumber ??= await nextNumberBloc.generateFormattedNumber('TN');

    // Checks moved to top of function

    final uom = await _getItemBranchUoM(
      loc.itemNumber!,
      loc.branch!,
      companyId,
    );

    if (ib.unitOfMeasure == null && uom == null) {
      throw Exception('Unit of measure not found for item: ${loc.itemNumber}');
    }

    final effectiveUom = ib.unitOfMeasure ?? uom;

    final factorP = await itemUomConversionRepository.fromOtherToPrimary(
      loc.itemNumber!,
      effectiveUom!,
      companyId,
    );

    final qtyAvInStore = ib.quantityAvailable ?? 0.0;

    final itemCost = await itemCostRepository.findByItem(
      loc.itemNumber!,
      companyId,
    );
    final unitCost = itemCost?.amountUnitCost ?? 0.0;

    final qTrn = (factorP * qty).abs();
    final amountCost = qTrn * unitCost;
    final qBfrTrn = (factorP * qtyAvInStore).abs();
    final beforeAmountCost = qBfrTrn * unitCost;

    // Create transaction
    final transaction = ItemTransactionModel(
      dateCreated: DateTime.now(),
      quantityTransaction: qty,
      beforeStoreQuantityAvailable: qtyAvInStore,
      unitCost: unitCost,
      amountCost: amountCost,
      beforeAmountCost: beforeAmountCost,
      company: companyId,
      createdBy: user,
      transactionType: udc.id,
      transactionNumber: trNumber,
      remark: remark ?? udc.description1,
      itemLocation: loc.id,
      itemBranch: ib.id,
      itemNumber: loc.itemNumber,
      branch: loc.branch,
      unitOfMeasure: ib.unitOfMeasure ?? uom,
      supplier: por?.poDetailRef?.poHeaderRef?.supplierId,
      orderType:
          por?.poDetailRef?.poHeaderRef!.orderType ??
          soD?.orderHeader?.orderTypeRef?.id,
      customer: soD?.orderHeader?.customerTableRef?.id,
    );

    await db.insert('item_transactions', transaction.toMap());

    // Update item location quantity
    final updatedLoc = loc.copyWith(
      quantityOnHand: (loc.quantityOnHand ?? 0.0) + qty,
    );
    // await itemLocationsRepository.updateItemLocation(updatedLoc);//Not necessary fpr sales order it will update there not here

    // Note: Item branch quantity update removed - now handled by cascading save in location repository
  }

  Future<void> _createLotTransaction({
    required LotMaster lm,
    required String transactionType,
    required int? trNo,
    required String? remark,
    required double qty,
    required PurchaseOrderReceiver? por,
    required SalesOrderDetail? soD,
    required int user,
    required int companyId,
  }) async {
    print(
      'DEBUG: _createLotTransaction started. lm: ${lm.id}, item: ${lm.itemNumber}, branch: ${lm.branch}',
    );
    final db = await databaseService.database;

    // Get transaction type UDC
    final udcList = await udcDetailsController.getLocalUdcDetailsByCode(
      transactionType,
      'TT',
    );
    if (udcList.isEmpty) {
      throw Exception(
        'Transaction type UDC not found for code: $transactionType',
      );
    }
    final udc = udcList.first;

    if (lm.itemNumber == null || lm.branch == null) {
      throw Exception('Lot master missing item number or branch: ${lm.id}');
    }

    // Get item branch
    print(
      'DEBUG: Finding ItemBranch for item: ${lm.itemNumber}, branch: ${lm.branch}',
    );
    final ib = await itemInBranchRepository.findByItemAndBranch(
      lm.itemNumber!,
      lm.branch!,
      companyId,
    );

    if (ib == null) {
      throw Exception(
        'Item branch not found for item: ${lm.itemNumber}, branch: ${lm.branch}',
      );
    }

    // Set transaction number
    int? trNumber = por != null
        ? por.poDetailRef?.poHeaderRef!.orderNumber
        : (soD != null ? soD.orderHeader?.orderNumber : trNo);

    trNumber ??= await nextNumberBloc.generateFormattedNumber('TN');

    // Calculate quantities and costs
    final qtyAvInStore = ib.quantityAvailable ?? 0.0;

    print('DEBUG: Finding ItemCost for item: ${lm.itemNumber}');
    final itemCost = await itemCostRepository.findByItem(
      lm.itemNumber!,
      companyId,
    );
    final unitCost = itemCost?.amountUnitCost ?? 0.0;

    // Checks moved to top of function

    print(
      'DEBUG: Getting UoM for item: ${lm.itemNumber}, branch: ${lm.branch}',
    );
    final uom = await _getItemBranchUoM(lm.itemNumber!, lm.branch!, companyId);
    print('DEBUG: uom: $uom, ib.unitOfMeasure: ${ib.unitOfMeasure}');

    if (ib.unitOfMeasure == null && uom == null) {
      throw Exception('Unit of measure not found for item: ${lm.itemNumber}');
    }

    final effectiveUom = ib.unitOfMeasure ?? uom;
    print('DEBUG: effectiveUom: $effectiveUom');

    if (effectiveUom == null) {
      throw Exception('Effective UoM is null despite checks');
    }

    print('DEBUG: Converting UoM');
    final factorP = await itemUomConversionRepository.fromOtherToPrimary(
      lm.itemNumber!,
      effectiveUom,
      companyId,
    );
    print('DEBUG: factorP: $factorP');

    final qTrn = (factorP * qty).abs();
    final amountCost = qTrn * unitCost;
    final qBfrTrn = (factorP * qtyAvInStore).abs();
    final beforeAmountCost = qBfrTrn * unitCost;

    // Create transaction
    final transaction = ItemTransactionModel(
      dateCreated: DateTime.now(),
      quantityTransaction: qty,
      beforeStoreQuantityAvailable: qtyAvInStore,
      unitCost: unitCost,
      amountCost: amountCost,
      beforeAmountCost: beforeAmountCost,
      company: companyId,
      createdBy: user,
      transactionType: udc.id,
      transactionNumber: trNumber,
      remark: remark ?? udc.description1,
      itemLocation: lm.location,
      lotNumber: lm.id,
      lotStatus: lm.lotStatus,
      itemBranch: ib.id,
      itemNumber: lm.itemNumber,
      branch: lm.branch,
      unitOfMeasure: ib.unitOfMeasure ?? uom,
      supplier: por?.poDetailRef?.poHeaderRef!.supplierId,
      orderType:
          por?.poDetailRef?.poHeaderRef!.orderType ??
          soD?.orderHeader?.orderTypeRef?.id,
      customer: soD?.orderHeader?.customerBillToRef?.id,
    );

    print('DEBUG: Inserting transaction');
    await db.insert('item_transactions', transaction.toMap());

    // Update lot quantity
    final updatedLm = lm.copyWith(
      quantityAvailable: (lm.quantityAvailable ?? 0.0) + qty,
    );
    //await lotMasterRepository.updateLotMaster(updatedLm);//Not necessary for sales order it will update there not here

    // Update item branch quantity
    final updatedIb = ib.copyWith(
      quantityAvailable: qtyAvInStore + (factorP * qty),
    );
    //await itemInBranchRepository.update(updatedIb);//Not necessary for sales order it will update there not here
  }

  // Complex inventory transactions - FIXED implementation
  Future<bool> executeInventoryTransactions({
    required ItemTransactionModel masterTransaction,
    required List<ItemTransactionModel> detailTransactions,
  }) async {
    try {
      if (masterTransaction.transactionType == null) return false;

      final companyId = authBloc.state.companyId;
      if (companyId == null) {
        throw Exception('Company ID is null');
      }

      final systemConstant = systemConstantBloc.state.selected;
      final applyLocationMgmt =
          systemConstant?.applyLocationMgmBoolean ?? false;
      final applyLotMgmt = systemConstant?.applyLotMgmBoolean ?? false;

      // Validate all transactions first
      for (final item in detailTransactions) {
        final isValid = await _validateInventoryTransaction(
          item,
          masterTransaction,
          applyLocationMgmt,
          applyLotMgmt,
          companyId,
        );
        if (!isValid) {
          return false;
        }
      }

      // Process all transactions
      final db = await databaseService.database;
      final batch = db.batch();

      for (final transaction in detailTransactions) {
        // Enrich detail with master/defaults and resolved references before saving
        final resolvedIb =
            (transaction.itemNumber != null && masterTransaction.branch != null)
            ? await itemInBranchRepository.findByItemAndBranch(
                transaction.itemNumber!,
                masterTransaction.branch!,
                companyId,
              )
            : null;

        final resolvedLot = (transaction.lotNumber != null)
            ? await lotMasterRepository.getLotMasterById(
                transaction.lotNumber!,
                companyId,
              )
            : null;

        final enriched = transaction.copyWith(
          remark: transaction.remark ?? masterTransaction.remark,
          transactionNumber:
              transaction.transactionNumber ??
              masterTransaction.transactionNumber,
          transactionType:
              transaction.transactionType ?? masterTransaction.transactionType,
          branch: transaction.branch ?? masterTransaction.branch,
          company: transaction.company ?? masterTransaction.company,
          itemBranch: transaction.itemBranch ?? resolvedIb?.id,
          lotStatus: transaction.lotStatus ?? resolvedLot?.lotStatus,
        );

        await _processInventoryTransaction(
          enriched,
          masterTransaction,
          applyLocationMgmt,
          applyLotMgmt,
          companyId,
        );
        batch.insert('item_transactions', enriched.toMap());
      }

      await batch.commit();
      return true;
    } catch (e) {
      throw Exception('Error executing inventory transactions: $e');
    }
  }

  Future<bool> _validateInventoryTransaction(
    ItemTransactionModel item,
    ItemTransactionModel masterTransaction,
    bool applyLocationMgmt,
    bool applyLotMgmt,
    int companyId,
  ) async {
    final transactionType = masterTransaction.transactionTypeDetail?.detailCode;

    if (transactionType == 'A') {
      return await _validateAdjustmentTransaction(
        item,
        masterTransaction,
        applyLocationMgmt,
        applyLotMgmt,
        companyId,
      );
    } else if (transactionType == 'I') {
      return await _validateIssueTransaction(
        item,
        masterTransaction,
        applyLocationMgmt,
        applyLotMgmt,
        companyId,
      );
    } else if (transactionType == 'T') {
      return await _validateTransferTransaction(
        item,
        masterTransaction,
        applyLocationMgmt,
        applyLotMgmt,
        companyId,
      );
    }

    return true;
  }

  Future<bool> _validateAdjustmentTransaction(
    ItemTransactionModel item,
    ItemTransactionModel masterTransaction,
    bool applyLocationMgmt,
    bool applyLotMgmt,
    int companyId,
  ) async {
    if (!applyLocationMgmt && !applyLotMgmt) {
      final ib = await itemInBranchRepository.findByItemAndBranch(
        item.itemNumber!,
        masterTransaction.branch!,
        companyId,
      );
      if (ib == null) return false;

      final currentQty = ib.quantityAvailable ?? 0.0;
      final adjustmentQty = item.quantityTransaction;

      if (!item.adjustToIncrease && currentQty < adjustmentQty.abs()) {
        return false; // Insufficient quantity for decrease
      }
    }
    // Add similar validations for location and lot management
    return true;
  }

  Future<bool> _validateIssueTransaction(
    ItemTransactionModel item,
    ItemTransactionModel masterTransaction,
    bool applyLocationMgmt,
    bool applyLotMgmt,
    int companyId,
  ) async {
    // Implement validation logic for issue transactions

    return true;
  }

  Future<bool> _validateTransferTransaction(
    ItemTransactionModel item,
    ItemTransactionModel masterTransaction,
    bool applyLocationMgmt,
    bool applyLotMgmt,
    int companyId,
  ) async {
    // Implement validation logic for transfer transactions

    return true;
  }

  Future<void> _processInventoryTransaction(
    ItemTransactionModel item,
    ItemTransactionModel masterTransaction,
    bool applyLocationMgmt,
    bool applyLotMgmt,
    int companyId,
  ) async {
    // Derive transaction type code from UDC using the id to avoid relying on unset relations
    String? transactionType;
    if (masterTransaction.transactionType != null) {
      final udc = await udcDetailsController.getUdcDetailById(
        masterTransaction.transactionType,
      );
      transactionType = udc?.detailCode;
    }

    if (transactionType == 'A') {
      await _processAdjustmentTransaction(
        item,
        masterTransaction,
        applyLocationMgmt,
        applyLotMgmt,
        companyId,
      );
    } else if (transactionType == 'I') {
      await _processIssueTransaction(
        item,
        masterTransaction,
        applyLocationMgmt,
        applyLotMgmt,
        companyId,
      );
    } else if (transactionType == 'T') {
      await _processTransferTransaction(
        item,
        masterTransaction,
        applyLocationMgmt,
        applyLotMgmt,
        companyId,
      );
    }
  }

  Future<bool> _processIssueTransaction(
    ItemTransactionModel item,
    ItemTransactionModel masterTransaction,
    bool applyLocationMgmt,
    bool applyLotMgmt,
    int companyId,
  ) async {
    // Similar implementation for issue transactions
    // ✅ FIXED
    if (!applyLocationMgmt && !applyLotMgmt) {
      await _adjustItemBranch(item, masterTransaction, 'D', companyId);
    } else if (applyLocationMgmt && !applyLotMgmt) {
      await _adjustItemLocation(item, masterTransaction, 'D', companyId);
    } else if (applyLocationMgmt && applyLotMgmt) {
      await _adjustLotMaster(item, masterTransaction, 'D', companyId);
    }

    return true;
  }

  Future<bool> _processTransferTransaction(
    ItemTransactionModel item,
    ItemTransactionModel masterTransaction,
    bool applyLocationMgmt,
    bool applyLotMgmt,
    int companyId,
  ) async {
    // Similar implementation for transfer transactions
    if (!applyLocationMgmt && !applyLotMgmt) {
      await _adjustItemBranch(item, masterTransaction, 'D', companyId);
    } else if (applyLocationMgmt && !applyLotMgmt) {
      await _adjustItemLocation(item, masterTransaction, 'D', companyId);
    } else if (applyLocationMgmt && applyLotMgmt) {
      await _adjustLotMaster(item, masterTransaction, 'D', companyId);
    }
    return true;
  }

  Future<void> _processAdjustmentTransaction(
    ItemTransactionModel item,
    ItemTransactionModel masterTransaction,
    bool applyLocationMgmt,
    bool applyLotMgmt,
    int companyId,
  ) async {
    final incDec = item.adjustToIncrease ? 'I' : 'D';

    if (!applyLocationMgmt && !applyLotMgmt) {
      await _adjustItemBranch(item, masterTransaction, incDec, companyId);
    } else if (applyLocationMgmt && !applyLotMgmt) {
      await _adjustItemLocation(item, masterTransaction, incDec, companyId);
    } else if (applyLocationMgmt && applyLotMgmt) {
      await _adjustLotMaster(item, masterTransaction, incDec, companyId);
    }
  }

  Future<void> _adjustItemBranch(
    ItemTransactionModel item,
    ItemTransactionModel masterTransaction,
    String incDec,
    int companyId,
  ) async {
    final ib = await itemInBranchRepository.findByItemAndBranch(
      item.itemNumber!,
      masterTransaction.branch!,
      companyId,
    );

    if (ib != null) {
      final currentQty = ib.quantityAvailable ?? 0.0;
      final adjustmentQty = item.quantityTransaction;

      final newQty = incDec == 'I'
          ? currentQty + adjustmentQty
          : currentQty - adjustmentQty;

      final updatedIb = ib.copyWith(quantityAvailable: newQty);
      await itemInBranchRepository.update(updatedIb);
    }
  }

  Future<void> _adjustItemLocation(
    ItemTransactionModel item,
    ItemTransactionModel masterTransaction,
    String incDec,
    int companyId,
  ) async {
    if (item.location != null) {
      final il = item.location!;
      final qb = il.quantityOnHand ?? 0.0;
      final uom = await _getItemBranchUoM(
        item.itemNumber!,
        masterTransaction.branch!,
        companyId,
      );
      final factor = await itemUomConversionRepository.fromOtherToAnother(
        item.itemNumber!,
        uom!,
        item.unitOfMeasure!,
        companyId,
      );

      final qI = factor * (item.quantityTransaction).abs();

      if (qI < 0.0 && qb < qI.abs()) {
        return; // Quantity greater than expected
      }

      if (incDec == 'I') {
        il.quantityOnHand = qb + qI;
      } else {
        il.quantityOnHand = qb - qI;
      }

      itemLocationsRepository.updateItemLocation(item.location!);
    }
  }

  Future<void> _adjustLotMaster(
    ItemTransactionModel item,
    ItemTransactionModel masterTransaction,
    String incDec,
    int companyId,
  ) async {
    if (item.lot != null) {
      final lm = item.lot!;
      final qb = lm.quantityAvailable ?? 0.0;
      final uom = await _getItemBranchUoM(
        item.itemNumber!,
        masterTransaction.branch!,
        companyId,
      );
      final factor = await itemUomConversionRepository.fromOtherToAnother(
        item.itemNumber!,
        uom!,
        item.unitOfMeasure!,
        companyId,
      );

      final qI = factor * (item.quantityTransaction).abs();

      if (qI < 0.0 && qb < qI.abs()) {
        return; // Quantity greater than expected
      }

      if (incDec == 'I') {
        lm.quantityAvailable = qb + qI;
      } else {
        lm.quantityAvailable = qb - qI;
      }

      lotMasterRepository.updateLotMaster(lm);
    }
  }

  // Opening amount calculation equivalent to Java version
  Future<double> calculateOpeningAmount({
    required int itemId,
    required int? branchId,
    required DateTime dateFrom,
    required DateTime dateThru,
  }) async {
    try {
      double qOpen = 0.0;
      final db = await databaseService.database;
      final user = authBloc.state.userId;
      final companyId = authBloc.state.companyId;

      if (user == null || companyId == null) return 0.0;

      final fromDateTime = DateTime(
        dateFrom.year,
        dateFrom.month,
        dateFrom.day,
      );
      final thruDateTime = DateTime(
        dateThru.year,
        dateThru.month,
        dateThru.day,
        23,
        59,
        59,
      );

      if (branchId != null) {
        // Single branch calculation
        final ib = await itemInBranchRepository.findByItemAndBranch(
          itemId,
          branchId,
          companyId,
        );

        // 1. Try to find transactions within the date range
        List<Map<String, dynamic>> transactions = await db.rawQuery(
          '''
        SELECT * FROM item_transactions 
        WHERE company = ? 
        AND item_number = ? 
        AND branch = ? 
        AND date_created BETWEEN ? AND ? 
        AND before_amount_cost IS NOT NULL
        ORDER BY date_created
        ''',
          [
            companyId,
            itemId,
            branchId,
            fromDateTime.toIso8601String(),
            thruDateTime.toIso8601String(),
          ],
        );

        if (transactions.isEmpty) {
          // 2. Find before any transaction (most recent before dateFrom)
          transactions = await db.rawQuery(
            '''
          SELECT * FROM item_transactions 
          WHERE company = ? 
          AND item_number = ? 
          AND branch = ? 
          AND date_created < ? 
          AND before_amount_cost IS NOT NULL
          ORDER BY date_created DESC
          LIMIT 1
          ''',
            [companyId, itemId, branchId, fromDateTime.toIso8601String()],
          );
        }
        if (transactions.isEmpty) {
          // 3. Still empty, find after (oldest after dateThru)
          transactions = await db.rawQuery(
            '''
          SELECT * FROM item_transactions 
          WHERE company = ? 
          AND item_number = ? 
          AND branch = ? 
          AND date_created > ? 
          AND before_amount_cost IS NOT NULL
          ORDER BY date_created ASC
          LIMIT 1
          ''',
            [companyId, itemId, branchId, thruDateTime.toIso8601String()],
          );
        }

        if (transactions.isEmpty) {
          // Take current available
          final itemCostObj = await itemCostRepository.findByItem(
            itemId,
            companyId,
          );

          if (ib != null) {
            final factor = await itemUomConversionRepository.fromOtherToPrimary(
              itemId,
              ib.unitOfMeasure!,
              companyId,
            );
            final unitCost = itemCostObj?.amountUnitCost ?? 0.0;
            qOpen = (factor * (ib.quantityAvailable ?? 0.0) * unitCost).abs();
          } else {
            qOpen = 0.0;
          }
        } else {
          qOpen = transactions.isNotEmpty
              ? (transactions.first['before_amount_cost'] as double).abs()
              : 0.0;
        }
      } else {
        // All branches calculation
        final itemInBranchModelList = await itemInBranchRepository.findByItem(
          itemId,
          companyId,
        );

        for (final ib in itemInBranchModelList) {
          List<Map<String, dynamic>> transactions = await db.rawQuery(
            '''
            SELECT * FROM item_transactions 
            WHERE company = ? AND item_number = ? AND branch = ? 
            AND date_created BETWEEN ? AND ? AND before_amount_cost IS NOT NULL
            ORDER BY date_created
          ''',
            [
              companyId,
              itemId,
              ib.branch,
              fromDateTime.toIso8601String(),
              thruDateTime.toIso8601String(),
            ],
          );

          if (transactions.isEmpty) {
            transactions = await db.rawQuery(
              '''
              SELECT * FROM item_transactions 
              WHERE company = ? AND item_number = ? AND branch = ? 
              AND date_created < ? AND before_amount_cost IS NOT NULL
              ORDER BY date_created DESC LIMIT 1
            ''',
              [companyId, itemId, ib.branch, fromDateTime.toIso8601String()],
            );
          }

          if (transactions.isEmpty) {
            transactions = await db.rawQuery(
              '''
              SELECT * FROM item_transactions 
              WHERE company = ? AND item_number = ? AND branch = ? 
              AND date_created > ? AND before_amount_cost IS NOT NULL
              ORDER BY date_created DESC LIMIT 1
            ''',
              [companyId, itemId, ib.branch, thruDateTime.toIso8601String()],
            );
          }

          if (transactions.isEmpty) {
            final itemCost = await itemCostRepository.findByItem(
              itemId,
              companyId,
            );

            if (itemCost != null) {
              final factor = await itemUomConversionRepository
                  .fromOtherToPrimary(itemId, ib.unitOfMeasure!, companyId);
              final unitCost = itemCost.amountUnitCost ?? 0.0;
              qOpen += (factor * (ib.quantityAvailable ?? 0.0) * unitCost)
                  .abs();
            }
          } else {
            qOpen += (transactions.first['before_amount_cost'] as num)
                .toDouble()
                .abs();
          }
        }
      }

      return qOpen;
    } catch (e) {
      print('Error calculating opening amount: $e');
      throw Exception('Error calculating opening amount: $e');
    }
  }

  Future<double> getTotalOpening({
    required List<int> itemIds,
    required DateTime dateFrom,
    required DateTime dateThru,
  }) async {
    try {
      double totalOpening = 0.0;

      for (final itemId in itemIds) {
        final opening = await calculateOpeningAmount(
          itemId: itemId,
          branchId: null, // Calculate for all branches
          dateFrom: dateFrom,
          dateThru: dateThru,
        );
        totalOpening += opening;
      }

      return totalOpening;
    } catch (e) {
      print('Error calculating total opening: $e');
      throw Exception('Failed to calculate total opening: $e');
    }
  }

  Future<int?> _getItemBranchUoM(
    int itemNumber,
    int branch,
    int companyId,
  ) async {
    final db = await databaseService.database;
    final result = await db.rawQuery(
      'SELECT unit_of_measure FROM items_in_branch WHERE item_number = ? AND branch = ? AND company = ?',
      [itemNumber, branch, companyId],
    );
    return result.isNotEmpty ? result.first['unit_of_measure'] as int? : null;
  }

  // Basic CRUD operations
  Future<List<ItemTransactionModel>> getTransactionsByCompany(
    int companyId,
  ) async {
    final db = await databaseService.database;
    final transactions = await db.rawQuery(
      '''
      SELECT it.*,
             il.location,
             lm.lot_number,
             ib.quantity_available,
             i.item_description as item_description,
             b.description as branch_name,
             udt.description_1 as transaction_type,
             uds.description_1 as lot_status,
             udm.description_1 as unit_of_measure
      FROM item_transactions it
      LEFT JOIN item_location il ON it.item_location = il.id
      LEFT JOIN lot_master lm ON it.lot_number = lm.id
      LEFT JOIN items_in_branch ib ON it.item_branch = ib.id
      LEFT JOIN items_table i ON it.item_number = i.id
      LEFT JOIN branch_table b ON it.branch = b.id
      LEFT JOIN udc_details udt ON it.transaction_type = udt.id
      LEFT JOIN udc_details uds ON it.lot_status = uds.id
      LEFT JOIN udc_details udm ON it.unit_of_measure = udm.id
      WHERE it.company = ?
      ORDER BY it.date_created DESC
    ''',
      [companyId],
    );

    return transactions
        .map((map) => ItemTransactionModel.fromMap(map))
        .toList();
  }

  Future<int> createTransaction(ItemTransactionModel transaction) async {
    final db = await databaseService.database;
    return await db.insert('item_transactions', transaction.toMap());
  }

  Future<void> updateTransaction(ItemTransactionModel transaction) async {
    final db = await databaseService.database;
    await db.update(
      'item_transactions',
      transaction.toMap(),
      where: 'id = ? AND company = ?',
      whereArgs: [transaction.id, authBloc.state.companyId],
    );
  }

  Future<void> deleteTransaction(int id) async {
    final db = await databaseService.database;
    await db.delete(
      'item_transactions',
      where: 'id = ? AND company = ?',
      whereArgs: [id, authBloc.state.companyId],
    );
  }

  Future<void> deleteTransactions(
    List<ItemTransactionModel> transactions,
  ) async {
    final db = await databaseService.database;
    final batch = db.batch();

    for (final transaction in transactions) {
      if (transaction.id != null) {
        batch.delete(
          'item_transactions',
          where: 'id = ? AND company = ?',
          whereArgs: [transaction.id, authBloc.state.companyId],
        );
      }
    }

    await batch.commit();
  }
}
