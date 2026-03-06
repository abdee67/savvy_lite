// repositories/item_transaction_repository.dart
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:savvy_stock/features/next_number/repo/next_number_repo.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/models/purchase_order_receiver_model.dart';
import 'package:savvy_stock/features/sales/sales_order/detail/model/sales_order_detail.dart';
import 'package:savvy_stock/features/stock/item_transactions/model/paginated_item_transaction_result.dart';
import 'package:savvy_stock/features/stock/item_uom_conversions/blocs/item_uom_conversions_bloc.dart';
import 'package:savvy_stock/features/stock/item_uom_conversions/repo/item_uom_conv_repo.dart';
import 'package:savvy_stock/features/stock/lot_master/models/lot_master_model.dart';
import 'package:savvy_stock/features/stock/lot_master/repo/lot_master_repo.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_bloc.dart';
import 'package:savvy_stock/core/repositories/udc_repository.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/stock/item_cost/repo/item_cost_repository.dart';
import 'package:savvy_stock/features/stock/item_in_branch/models/item_in_branch_model.dart';
import 'package:savvy_stock/features/stock/item_in_branch/repo/item_in_branch_repo.dart';
import 'package:savvy_stock/features/stock/item_locations/models/item_locations_model.dart';
import 'package:savvy_stock/features/stock/item_locations/repo/item_location_repo.dart';
import 'package:savvy_stock/features/stock/item_transactions/model/item_transaction_model.dart';
import 'package:savvy_stock/features/stock/location_entry/repo/location_master_repository.dart';
import 'package:sqflite/sqflite.dart';

class ItemTransactionRepository {
  final LocalDatabaseService databaseService;
  final AuthBloc authBloc;
  final SystemConstantBloc systemConstantBloc;
  final UdcRepository udcDetailsController;
  final ItemUomConversionBloc itemUomConversionBloc;

  // Use repositories instead of BLoCs for data access
  final StockItemInBranchRepository itemInBranchRepository;
  final ItemLocationsRepository itemLocationsRepository;
  final LotMasterRepository lotMasterRepository;
  final LocationMasterRepository locationMasterRepository;
  final NextNumberRepository nextNumberRepository;

  final ItemUomConversionsRepository itemUomConversionRepository;
  final ItemCostRepository itemCostRepository;

  ItemTransactionRepository({
    required this.databaseService,
    required this.authBloc,
    required this.systemConstantBloc,
    required this.udcDetailsController,
    required this.itemUomConversionBloc,
    required this.itemInBranchRepository,
    required this.itemLocationsRepository,
    required this.lotMasterRepository,
    required this.locationMasterRepository,
    required this.nextNumberRepository,
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
    int? supplier,
    int? orderType,
    int? customer,
    Transaction? txn,
  }) async {
    try {
      if (kDebugMode) {
        developer.log(
          'DEBUG: stockCardCreation started. ib: $ib, loc: $loc, lm: $lm, qty: $qty',
        );
      }
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
          if (kDebugMode) {
            developer.log('DEBUG: Creating ItemBranchTransaction');
          }
          await _createItemBranchTransaction(
            ib: ib,
            transactionType: transactionType,
            trNo: trNo,
            remark: remark,
            qty: qty,
            por: por,
            soD: soD,
            supplier: supplier,
            orderType: orderType,
            customer: customer,
            user: user.id,
            companyId: companyId,
            txn: txn,
          );
        } else if (loc != null &&
            applyLocationMgmt &&
            !applyLotMgmt &&
            qty != 0.0) {
          if (kDebugMode) {
            developer.log('DEBUG: Creating LocationTransaction');
          }
          await _createLocationTransaction(
            loc: loc,
            transactionType: transactionType,
            trNo: trNo,
            remark: remark,
            qty: qty,
            por: por,
            soD: soD,
            supplier: supplier,
            orderType: orderType,
            customer: customer,
            user: user.id,
            companyId: companyId,
            txn: txn,
          );
        } else if (lm != null &&
            applyLocationMgmt &&
            applyLotMgmt &&
            qty != 0.0) {
          if (kDebugMode) {
            developer.log('DEBUG: Creating LotTransaction');
          }
          await _createLotTransaction(
            lm: lm,
            transactionType: transactionType,
            trNo: trNo,
            remark: remark,
            qty: qty,
            por: por,
            soD: soD,
            supplier: supplier,
            orderType: orderType,
            customer: customer,
            user: user.id,
            companyId: companyId,
            txn: txn,
          );
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        developer.log('DEBUG: Error in stock card creation: $e');
        developer.log('DEBUG: StackTrace: $stackTrace');
      }
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
    int? supplier,
    int? orderType,
    int? customer,
    required int user,
    required int companyId,
    Transaction? txn,
  }) async {
    final db = txn ?? await databaseService.database;

    // Get transaction type UDC
    final udcList = await udcDetailsController.getLocalUdcDetailsByCode(
      transactionType,
      'TT',
      txn: txn,
    );
    if (udcList.isEmpty) {
      throw Exception(
        'Transaction type UDC not found for code: $transactionType',
      );
    }
    final udc = udcList.first;

    // Set transaction number - prefer linked header, fall back to provided trNo
    int? trNumber =
        por?.poDetailRef?.poHeaderRef?.orderNumber ??
        soD?.orderHeader?.orderNumber ??
        trNo;

    trNumber ??= await nextNumberRepository.generateNextNumber(
      'TN',
      companyId,
      txn: txn,
    );

    // Calculate quantities and costs
    if (ib.itemNumber == 0 || ib.branch == 0) {
      throw Exception('Item branch missing item number or branch: ${ib.id}');
    }

    if (ib.unitOfMeasure == null) {
      throw Exception('Unit of measure is missing for item branch: ${ib.id}');
    }

    final itemCost = await itemCostRepository.findByItem(
      ib.itemNumber,
      companyId,
      txn: txn,
    );
    final unitCost = itemCost?.amountUnitCost ?? 0.0;

    final factorP = await itemUomConversionRepository.fromOtherToPrimary(
      ib.itemNumber,
      ib.unitOfMeasure!,
      companyId,
      txn: txn,
    );

    final qTrn = factorP * qty;
    final amountCost = qTrn * unitCost;

    final qBfrTrn = factorP * (ib.quantityAvailable ?? 0.0);
    final beforeAmountCost = qBfrTrn * unitCost;

    // Create transaction
    final transaction = ItemTransactionModel(
      dateCreated: DateTime.now(),
      quantityTransaction: qTrn,
      beforeStoreQuantityAvailable: qBfrTrn,
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
      supplier: supplier ?? por?.poDetailRef?.poHeaderRef?.supplierId,
      orderType:
          orderType ??
          por?.poDetailRef?.poHeaderRef?.orderType ??
          soD?.orderHeader?.orderType,
      customer: customer ?? soD?.orderHeader?.customerBillTo,
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
    int? supplier,
    int? orderType,
    int? customer,
    required int user,
    required int companyId,
    Transaction? txn,
  }) async {
    final db = txn ?? await databaseService.database;

    // Get transaction type UDC
    final udcList = await udcDetailsController.getLocalUdcDetailsByCode(
      transactionType,
      'TT',
      txn: txn,
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
      txn: txn,
    );

    if (ib == null) {
      throw Exception(
        'Item branch not found for item: ${loc.itemNumber}, branch: ${loc.branch}',
      );
    }

    // Set transaction number - prefer linked header, fall back to provided trNo
    int? trNumber =
        por?.poDetailRef?.poHeaderRef?.orderNumber ??
        soD?.orderHeader?.orderNumber ??
        trNo;

    trNumber ??= await nextNumberRepository.generateNextNumber(
      'TN',
      companyId,
      txn: txn,
    );

    // Checks moved to top of function

    final uom = await _getItemBranchUoM(
      loc.itemNumber!,
      loc.branch!,
      companyId,
      txn: txn,
    );

    if (ib.unitOfMeasure == null && uom == null) {
      throw Exception('Unit of measure not found for item: ${loc.itemNumber}');
    }

    final effectiveUom = ib.unitOfMeasure ?? uom;

    final factorP = await itemUomConversionRepository.fromOtherToPrimary(
      loc.itemNumber!,
      effectiveUom!,
      companyId,
      txn: txn,
    );

    final qtyAvInStore = ib.quantityAvailable ?? 0.0;

    final itemCost = await itemCostRepository.findByItem(
      loc.itemNumber!,
      companyId,
      txn: txn,
    );
    final unitCost = itemCost?.amountUnitCost ?? 0.0;

    final qTrn = (factorP * qty).abs();
    final amountCost = qTrn * unitCost;
    final qBfrTrn = (factorP * qtyAvInStore).abs();
    final beforeAmountCost = qBfrTrn * unitCost;

    // Create transaction
    final transaction = ItemTransactionModel(
      dateCreated: DateTime.now(),
      quantityTransaction: qTrn,
      beforeStoreQuantityAvailable: qBfrTrn,
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
      supplier: supplier ?? por?.poDetailRef?.poHeaderRef?.supplierId,
      orderType:
          orderType ??
          por?.poDetailRef?.poHeaderRef?.orderType ??
          soD?.orderHeader?.orderTypeRef?.id ??
          soD?.orderHeader?.orderType,
      customer:
          customer ??
          soD?.orderHeader?.customerTableRef?.id ??
          soD?.orderHeader?.customerBillTo,
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
    int? supplier,
    int? orderType,
    int? customer,
    required int user,
    required int companyId,
    Transaction? txn,
  }) async {
    if (kDebugMode) {
      developer.log(
        'DEBUG: _createLotTransaction started. lm: ${lm.id}, item: ${lm.itemNumber}, branch: ${lm.branch}',
      );
    }
    final db = txn ?? await databaseService.database;

    // Get transaction type UDC
    final udcList = await udcDetailsController.getLocalUdcDetailsByCode(
      transactionType,
      'TT',
      txn: txn,
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
    if (kDebugMode) {
      developer.log(
        'DEBUG: Finding ItemBranch for item: ${lm.itemNumber}, branch: ${lm.branch}',
      );
    }
    final ib = await itemInBranchRepository.findByItemAndBranch(
      lm.itemNumber!,
      lm.branch!,
      companyId,
      txn: txn,
    );

    if (ib == null) {
      throw Exception(
        'Item branch not found for item: ${lm.itemNumber}, branch: ${lm.branch}',
      );
    }

    // Set transaction number - prefer linked header, fall back to provided trNo
    int? trNumber =
        por?.poDetailRef?.poHeaderRef?.orderNumber ??
        soD?.orderHeader?.orderNumber ??
        trNo;

    trNumber ??= await nextNumberRepository.generateNextNumber(
      'TN',
      companyId,
      txn: txn,
    );

    // Calculate quantities and costs
    final qtyAvInStore = ib.quantityAvailable ?? 0.0;

    if (kDebugMode) {
      developer.log('DEBUG: Finding ItemCost for item: ${lm.itemNumber}');
    }
    final itemCost = await itemCostRepository.findByItem(
      lm.itemNumber!,
      companyId,
      txn: txn,
    );
    final unitCost = itemCost?.amountUnitCost ?? 0.0;

    // Checks moved to top of function

    if (kDebugMode) {
      developer.log(
        'DEBUG: Getting UoM for item: ${lm.itemNumber}, branch: ${lm.branch}',
      );
    }
    final uom = await _getItemBranchUoM(
      lm.itemNumber!,
      lm.branch!,
      companyId,
      txn: txn,
    );
    if (kDebugMode) {
      developer.log('DEBUG: uom: $uom, ib.unitOfMeasure: ${ib.unitOfMeasure}');
    }

    if (ib.unitOfMeasure == null && uom == null) {
      throw Exception('Unit of measure not found for item: ${lm.itemNumber}');
    }

    final effectiveUom = ib.unitOfMeasure ?? uom;
    if (kDebugMode) {
      developer.log('DEBUG: effectiveUom: $effectiveUom');
    }

    if (effectiveUom == null) {
      throw Exception('Effective UoM is null despite checks');
    }

    if (kDebugMode) {
      developer.log('DEBUG: Converting UoM');
    }
    final factorP = await itemUomConversionRepository.fromOtherToPrimary(
      lm.itemNumber!,
      effectiveUom,
      companyId,
      txn: txn,
    );
    if (kDebugMode) {
      developer.log('DEBUG: factorP: $factorP');
    }

    final qTrn = (factorP * qty).abs();
    final amountCost = qTrn * unitCost;
    final qBfrTrn = (factorP * qtyAvInStore).abs();
    final beforeAmountCost = qBfrTrn * unitCost;

    // Create transaction
    final transaction = ItemTransactionModel(
      dateCreated: DateTime.now(),
      quantityTransaction: qTrn,
      beforeStoreQuantityAvailable: qBfrTrn,
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
      supplier: supplier ?? por?.poDetailRef?.poHeaderRef?.supplierId,
      orderType:
          orderType ??
          por?.poDetailRef?.poHeaderRef?.orderType ??
          soD?.orderHeader?.orderTypeRef?.id ??
          soD?.orderHeader?.orderType,
      customer:
          customer ??
          soD?.orderHeader?.customerTableRef?.id ??
          soD?.orderHeader?.customerBillTo,
    );

    if (kDebugMode) {
      developer.log('DEBUG: Inserting transaction');
    }
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
    Transaction? txn,
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
          txn,
        );
        if (!isValid) {
          return false;
        }
      }

      // Process all transactions
      final db = await databaseService.database;
      final batch = db.batch();

      // Resolve Transaction Type Code ONCE
      final udc = await udcDetailsController.getUdcDetailById(
        masterTransaction.transactionType!,
      );
      final transactionTypeCode = udc?.detailCode;

      if (transactionTypeCode == null) {
        throw Exception(
          'Transaction Type Detail Code not found (UDC may be missing)',
        );
      }
      final masterWithCode = masterTransaction.copyWith(
        transactionTypeDetail: udc,
      );

      for (final transaction in detailTransactions) {
        // 1. Resolve Item Branch / Location / Lot relative fields
        double currentQtyAvailable = 0.0;
        int? effectiveUom;

        // Resolve references
        ItemInBranchModel? resolvedIb;
        LotMaster? resolvedLot;

        if (transaction.itemNumber != null &&
            masterTransaction.branch != null) {
          resolvedIb = await itemInBranchRepository.findByItemAndBranch(
            transaction.itemNumber!,
            masterTransaction.branch!,
            companyId,
          );
        }

        if (transaction.lotNumber != null) {
          resolvedLot = await lotMasterRepository.getLotMasterById(
            transaction.lotNumber!,
            companyId,
          );
        }

        // Determine current available quantity based on management policy
        if (applyLotMgmt && resolvedLot != null) {
          currentQtyAvailable = resolvedLot.quantityAvailable ?? 0.0;
          effectiveUom = resolvedIb?.unitOfMeasure;
        } else if (applyLocationMgmt && transaction.itemLocation != null) {
          final il = await itemLocationsRepository.getItemLocationById(
            transaction.itemLocation!,
            companyId,
          );
          currentQtyAvailable = il?.quantityOnHand ?? 0.0;
          effectiveUom = resolvedIb?.unitOfMeasure;
        } else {
          currentQtyAvailable = resolvedIb?.quantityAvailable ?? 0.0;
          effectiveUom = resolvedIb?.unitOfMeasure;
        }

        // 2. Resolve Cost
        final itemCostObj = await itemCostRepository.findByItem(
          transaction.itemNumber!,
          companyId,
        );
        final unitCost = itemCostObj?.amountUnitCost ?? 0.0;

        // 3. UoM Conversion Factor (from transaction UoM to Primary/Base)
        double factorToPrimary = 1.0;
        if (transaction.unitOfMeasure != null && effectiveUom != null) {
          factorToPrimary = await itemUomConversionRepository
              .fromOtherToPrimary(
                transaction.itemNumber!,
                transaction.unitOfMeasure!,
                companyId,
              );
        }

        // Calculate Amounts
        final beforeStoreQty = currentQtyAvailable;
        final beforeAmtCost = beforeStoreQty * unitCost;

        final qtyTrans = transaction.quantityTransaction;
        final amtCost = (qtyTrans * factorToPrimary) * unitCost;

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
          customer: transaction.customer ?? masterTransaction.customer,
          orderType: transaction.orderType ?? masterTransaction.orderType,
          supplier: transaction.supplier ?? masterTransaction.supplier,
          // Populated Snapshots
          beforeStoreQuantityAvailable: beforeStoreQty,
          unitCost: unitCost,
          amountCost: amtCost,
          beforeAmountCost: beforeAmtCost,
        );

        await _processInventoryTransaction(
          enriched,
          masterWithCode,
          applyLocationMgmt,
          applyLotMgmt,
          companyId,
          explicitCode: transactionTypeCode,
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
    Transaction? txn,
  ) async {
    final transactionType = masterTransaction.transactionTypeDetail?.detailCode;

    if (transactionType == 'A') {
      return await _validateAdjustmentTransaction(
        item,
        masterTransaction,
        applyLocationMgmt,
        applyLotMgmt,
        companyId,
        txn,
      );
    } else if (transactionType == 'I') {
      return await _validateIssueTransaction(
        item,
        masterTransaction,
        applyLocationMgmt,
        applyLotMgmt,
        companyId,
        txn,
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
    Transaction? txn,
  ) async {
    // Determine conversion factor from Transaction UoM -> Storage UoM
    Future<double> getFactor(int? storeUom) async {
      if (item.unitOfMeasure != null && storeUom != null) {
        return await itemUomConversionRepository.fromOtherToAnother(
          item.itemNumber!,
          item.unitOfMeasure!,
          storeUom,
          companyId,
        );
      }
      return 1.0;
    }

    if (!item.adjustToIncrease) {
      // Validating Decrease Logic
      if (!applyLocationMgmt && !applyLotMgmt) {
        // Branch Check
        final ib = await itemInBranchRepository.findByItemAndBranch(
          item.itemNumber!,
          masterTransaction.branch!,
          companyId,
          txn: txn,
        );
        if (ib == null) throw Exception('Item not found in branch');

        final factor = await getFactor(ib.unitOfMeasure);
        final currentQty = ib.quantityAvailable ?? 0.0;
        final deduction = (item.quantityTransaction * factor).abs();

        if (currentQty < deduction) {
          throw Exception('Insufficient quantity in store for item');
        }
      } else if (applyLocationMgmt && !applyLotMgmt) {
        // Location Check
        if (item.itemLocation == null) throw Exception('Location is required');
        final il = await itemLocationsRepository.getItemLocationById(
          item.itemLocation!,
          companyId,
          txn: txn,
        );
        if (il == null) throw Exception('Location record not found');

        // Assuming Location uses Primary UoM or we fetch it from Item/Branch
        final ib = await itemInBranchRepository.findByItemAndBranch(
          item.itemNumber!,
          masterTransaction.branch!,
          companyId,
          txn: txn,
        );

        final factor = await getFactor(ib?.unitOfMeasure);
        final currentQty = il.quantityOnHand ?? 0.0;
        final deduction = (item.quantityTransaction * factor).abs();

        if (currentQty < deduction) {
          throw Exception(
            'Insufficient quantity in location ${il.locationDescription?.locationDescription}',
          );
        }
      } else if (applyLotMgmt) {
        // Lot Check (covers Lot + Location if managed)
        if (item.lotNumber == null) throw Exception('Lot is required');
        final lm = await lotMasterRepository.getLotMasterById(
          item.lotNumber!,
          companyId,
          txn: txn,
        );
        if (lm == null) throw Exception('Lot record not found');

        final ib = await itemInBranchRepository.findByItemAndBranch(
          item.itemNumber!,
          masterTransaction.branch!,
          companyId,
          txn: txn,
        );
        final factor = await getFactor(ib?.unitOfMeasure);
        final currentQty = lm.quantityAvailable ?? 0.0;
        final deduction = (item.quantityTransaction * factor).abs();

        if (currentQty < deduction) {
          throw Exception('Insufficient quantity in Lot ${lm.lotNumber}');
        }
      }
    }

    return true;
  }

  Future<bool> _validateIssueTransaction(
    ItemTransactionModel item,
    ItemTransactionModel masterTransaction,
    bool applyLocationMgmt,
    bool applyLotMgmt,
    int companyId,
    Transaction? txn,
  ) async {
    // Implement validation logic for issue transactions
    // Determine conversion factor from Transaction UoM -> Storage UoM
    Future<double> getFactor(int? storeUom) async {
      if (item.unitOfMeasure != null && storeUom != null) {
        return await itemUomConversionRepository.fromOtherToAnother(
          item.itemNumber!,
          item.unitOfMeasure!,
          storeUom,
          companyId,
        );
      }
      return 1.0;
    }

    // Validating Decrease Logic
    if (!applyLocationMgmt && !applyLotMgmt) {
      // Branch Check
      final ib = await itemInBranchRepository.findByItemAndBranch(
        item.itemNumber!,
        masterTransaction.branch!,
        companyId,
        txn: txn,
      );
      if (ib == null) throw Exception('Item not found in branch');

      final factor = await getFactor(ib.unitOfMeasure);
      final currentQty = ib.quantityAvailable ?? 0.0;
      final deduction = (item.quantityTransaction * factor).abs();

      if (currentQty < deduction) {
        throw Exception('Insufficient quantity in store for item');
      }
    } else if (applyLocationMgmt && !applyLotMgmt) {
      // Location Check
      if (item.itemLocation == null) throw Exception('Location is required');
      final il = await itemLocationsRepository.getItemLocationById(
        item.itemLocation!,
        companyId,
        txn: txn,
      );
      if (il == null) throw Exception('Location record not found');

      // Assuming Location uses Primary UoM or we fetch it from Item/Branch
      final ib = await itemInBranchRepository.findByItemAndBranch(
        item.itemNumber!,
        masterTransaction.branch!,
        companyId,
        txn: txn,
      );

      final factor = await getFactor(ib?.unitOfMeasure);
      final currentQty = il.quantityOnHand ?? 0.0;
      final deduction = (item.quantityTransaction * factor).abs();

      if (currentQty < deduction) {
        throw Exception(
          'Insufficient quantity in location ${il.locationDescription?.locationDescription}',
        );
      }
    } else if (applyLotMgmt) {
      // Lot Check (covers Lot + Location if managed)
      if (item.lotNumber == null) throw Exception('Lot is required');
      final lm = await lotMasterRepository.getLotMasterById(
        item.lotNumber!,
        companyId,
        txn: txn,
      );
      if (lm == null) throw Exception('Lot record not found');

      final ib = await itemInBranchRepository.findByItemAndBranch(
        item.itemNumber!,
        masterTransaction.branch!,
        companyId,
        txn: txn,
      );
      final factor = await getFactor(ib?.unitOfMeasure);
      final currentQty = lm.quantityAvailable ?? 0.0;
      final deduction = (item.quantityTransaction * factor).abs();

      if (currentQty < deduction) {
        throw Exception('Insufficient quantity in Lot ${lm.lotNumber}');
      }
    }

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
    int companyId, {
    String? explicitCode,
    Transaction? txn,
  }) async {
    // Derive transaction type code from UDC using the id to avoid relying on unset relations
    String? transactionType = explicitCode;
    if (transactionType == null && masterTransaction.transactionType != null) {
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
        txn,
      );
    } else if (transactionType == 'I') {
      await _processIssueTransaction(
        item,
        masterTransaction,
        applyLocationMgmt,
        applyLotMgmt,
        companyId,
        txn,
      );
    } else if (transactionType == 'T') {
      await _processTransferTransaction(
        item,
        masterTransaction,
        applyLocationMgmt,
        applyLotMgmt,
        companyId,
        txn,
      );
    }
  }

  Future<bool> _processIssueTransaction(
    ItemTransactionModel item,
    ItemTransactionModel masterTransaction,
    bool applyLocationMgmt,
    bool applyLotMgmt,
    int companyId,
    Transaction? txn,
  ) async {
    // Similar implementation for issue transactions
    // ✅ FIXED
    if (!applyLocationMgmt && !applyLotMgmt) {
      await _adjustItemBranch(item, masterTransaction, 'D', companyId, txn);
    } else if (applyLocationMgmt && !applyLotMgmt) {
      await _adjustItemLocation(item, masterTransaction, 'D', companyId, txn);
    } else if (applyLocationMgmt && applyLotMgmt) {
      await _adjustLotMaster(item, masterTransaction, 'D', companyId, txn);
    }

    return true;
  }

  Future<bool> _processTransferTransaction(
    ItemTransactionModel item,
    ItemTransactionModel masterTransaction,
    bool applyLocationMgmt,
    bool applyLotMgmt,
    int companyId,
    Transaction? txn,
  ) async {
    // 1. Branch to Branch Transfer (No Location, No Lot)
    if (!applyLocationMgmt && !applyLotMgmt) {
      final sourceBranchId = masterTransaction.branch;
      final destBranchId = masterTransaction.branchTo;

      if (sourceBranchId == null || destBranchId == null) {
        throw Exception("Source and Destination Branch are required.");
      }
      if (sourceBranchId == destBranchId) {
        throw Exception("Transferring to same branch not allowed!");
      }

      // Fetch Source
      final ibSource = await itemInBranchRepository.findByItemAndBranch(
        item.itemNumber!,
        sourceBranchId,
        companyId,
        txn: txn,
      );
      if (ibSource == null) {
        throw Exception("Item not found in source branch.");
      }

      // Fetch Dest (Create if not exists - needed for UoM)
      final ibDest = await _getOrCreateItemInBranch(
        item.itemNumber!,
        destBranchId,
        companyId,
        masterTransaction.createdBy ?? 0,
        int.tryParse(item.item?.unitOfMeasure ?? ''),
        txn: txn,
      );

      // Conversions
      double factorFrom = 1.0;
      if (item.unitOfMeasure != null && ibSource.unitOfMeasure != null) {
        factorFrom = await itemUomConversionRepository.fromOtherToAnother(
          item.itemNumber!,
          item.unitOfMeasure!,
          ibSource.unitOfMeasure!,
          companyId,
          txn: txn,
        );
      }

      double factorTo = 1.0;
      if (item.unitOfMeasure != null && ibDest.unitOfMeasure != null) {
        factorTo = await itemUomConversionRepository.fromOtherToAnother(
          item.itemNumber!,
          item.unitOfMeasure!,
          ibDest.unitOfMeasure!,
          companyId,
          txn: txn,
        );
      }

      double qIFrom = (factorFrom * item.quantityTransaction).abs();
      double qITo = (factorTo * item.quantityTransaction).abs();
      double qb = ibSource.quantityAvailable ?? 0.0;

      // Strict Quantity Validation
      if (qb < qIFrom) {
        throw Exception("Quantity is Greater than expected value!");
      }

      // Execute Updates
      await itemInBranchRepository.update(
        ibSource.copyWith(quantityAvailable: qb - qIFrom),
        txn: txn,
      );

      await itemInBranchRepository.update(
        ibDest.copyWith(
          quantityAvailable: (ibDest.quantityAvailable ?? 0.0) + qITo,
        ),
        txn: txn,
      );
    }
    // 2. Location to Location Transfer
    else if (applyLocationMgmt && !applyLotMgmt) {
      // Validate Locations
      if (item.itemLocation == null || item.itemLocationsTo == null) {
        throw Exception("Source and Destination Locations are required.");
      }
      if (item.itemLocation == item.itemLocationsTo) {
        throw Exception("Transferring to same location not allowed!");
      }

      // Fetch Source Location
      final ilSource = await itemLocationsRepository.getItemLocationById(
        item.itemLocation!,
        companyId,
        txn: txn,
      );
      if (ilSource == null) throw Exception("Source Location not found.");

      final sourceBranchId = masterTransaction.branch!;

      // Resolve Dest Branch from Dest Location Master
      final destLocMaster = await locationMasterRepository
          .getLocationMasterById(item.itemLocationsTo!, companyId, txn: txn);
      if (destLocMaster == null) {
        throw Exception("Destination Location Master not found.");
      }
      final destBranchId = destLocMaster.branch!;

      // Fetch IBs for UoM conversions
      final ibSource = await itemInBranchRepository.findByItemAndBranch(
        item.itemNumber!,
        sourceBranchId,
        companyId,
        txn: txn,
      );
      final ibDest = await _getOrCreateItemInBranch(
        item.itemNumber!,
        destBranchId,
        companyId,
        masterTransaction.createdBy ?? 0,
        int.tryParse(item.item?.unitOfMeasure ?? ''),
        txn: txn,
      );

      // Factors
      double factorFrom = 1.0;
      if (item.unitOfMeasure != null && ibSource?.unitOfMeasure != null) {
        factorFrom = await itemUomConversionRepository.fromOtherToAnother(
          item.itemNumber!,
          item.unitOfMeasure!,
          ibSource!.unitOfMeasure!,
          companyId,
          txn: txn,
        );
      }
      double factorTo = 1.0;
      if (item.unitOfMeasure != null && ibDest.unitOfMeasure != null) {
        factorTo = await itemUomConversionRepository.fromOtherToAnother(
          item.itemNumber!,
          item.unitOfMeasure!,
          ibDest.unitOfMeasure!,
          companyId,
          txn: txn,
        );
      }

      double qIFrom = (item.quantityTransaction * factorFrom).abs();
      double qITo = (item.quantityTransaction * factorTo).abs();
      double qb = ilSource.quantityOnHand ?? 0.0;

      // Strict Validation
      if (qb < qIFrom) {
        throw Exception("Quantity is Greater than expected value!");
      }

      // Find/Create Dest ItemLocation
      var ilDest = await itemLocationsRepository
          .getItemLocationByItemBranchLocation(
            branchId: destBranchId,
            itemNumber: item.itemNumber!,
            locationId: destLocMaster.id!,
            companyId: companyId,
            txn: txn,
          );

      if (ilDest == null) {
        final newItemLocation = ItemLocation(
          branch: destBranchId,
          itemNumber: item.itemNumber,
          location: destLocMaster.id,
          quantityOnHand: 0.0,
          company: companyId,
          dateCreated: DateTime.now(),
          dateUpdated: DateTime.now(),
          createdBy: masterTransaction.createdBy ?? 0,
          updatedBy: masterTransaction.createdBy ?? 0,
        );
        final id = await itemLocationsRepository.createItemLocation(
          newItemLocation,
          txn: txn,
        );
        ilDest = newItemLocation.copyWith(id: id);
      }

      // 1. Locations
      await itemLocationsRepository.updateItemLocation(
        ilSource.copyWith(quantityOnHand: qb - qIFrom),
        txn: txn,
      );
      await itemLocationsRepository.updateItemLocation(
        ilDest.copyWith(quantityOnHand: (ilDest.quantityOnHand ?? 0.0) + qITo),
        txn: txn,
      );

      // 2. Branches
      // Handle same-branch case to avoid overwriting updates
      if (sourceBranchId == destBranchId) {
        if (ibSource != null) {
          // factorFrom/factorTo should be identical if UoM is same for Branch
          final newQty = (ibSource.quantityAvailable ?? 0.0) - qIFrom + qITo;
          await itemInBranchRepository.update(
            ibSource.copyWith(quantityAvailable: newQty),
            txn: txn,
          );
        }
      } else {
        // Distinct Branches
        if (ibSource != null) {
          await itemInBranchRepository.update(
            ibSource.copyWith(
              quantityAvailable: (ibSource.quantityAvailable ?? 0.0) - qIFrom,
            ),
            txn: txn,
          );
        }
        await itemInBranchRepository.update(
          ibDest.copyWith(
            quantityAvailable: (ibDest.quantityAvailable ?? 0.0) + qITo,
          ),
          txn: txn,
        );
      }
    }
    // 3. Lot to Lot Transfer (Move Lot to another Location)
    else if (applyLocationMgmt && applyLotMgmt) {
      if (item.lotNumber == null) {
        throw Exception("Source Lot Number is required.");
      }
      if (item.itemLocationsTo == null) {
        throw Exception("Destination Location is required for Lot Transfer.");
      }

      // Strict Check: Source Location != Dest Location
      if (item.itemLocation != null) {
        if (item.itemLocation == item.itemLocationsTo) {
          throw Exception("Transferring to same location not allowed!");
        }
      }

      // Fetch Source Lot
      final sourceLot = await lotMasterRepository.getLotMasterById(
        item.lotNumber!,
        companyId,
        txn: txn,
      );
      if (sourceLot == null) throw Exception("Source Lot not found.");

      if (sourceLot.location == item.itemLocationsTo) {
        throw Exception("Transferring to same location not allowed!");
      }

      // Dest Branch from Dest Location
      final destLocMaster = await locationMasterRepository
          .getLocationMasterById(item.itemLocationsTo!, companyId, txn: txn);
      if (destLocMaster == null) {
        throw Exception("Destination Location Master not found.");
      }
      final destBranchId = destLocMaster.branch!;
      final sourceBranchId = masterTransaction.branch!;

      // Fetch IBs for Factors
      final ibSource = await itemInBranchRepository.findByItemAndBranch(
        item.itemNumber!,
        sourceBranchId,
        companyId,
        txn: txn,
      );
      final ibDest = await _getOrCreateItemInBranch(
        item.itemNumber!,
        destBranchId,
        companyId,
        masterTransaction.createdBy ?? 0,
        int.tryParse(item.item?.unitOfMeasure ?? ''),
        txn: txn,
      );

      // Factors
      double factorFrom = 1.0;
      if (item.unitOfMeasure != null && ibSource?.unitOfMeasure != null) {
        factorFrom = await itemUomConversionRepository.fromOtherToAnother(
          item.itemNumber!,
          item.unitOfMeasure!,
          ibSource!.unitOfMeasure!,
          companyId,
          txn: txn,
        );
      }
      double factorTo = 1.0;
      if (item.unitOfMeasure != null && ibDest.unitOfMeasure != null) {
        factorTo = await itemUomConversionRepository.fromOtherToAnother(
          item.itemNumber!,
          item.unitOfMeasure!,
          ibDest.unitOfMeasure!,
          companyId,
          txn: txn,
        );
      }

      double qIFrom = (item.quantityTransaction * factorFrom).abs();
      double qITo = (item.quantityTransaction * factorTo).abs();
      double qb = sourceLot.quantityAvailable ?? 0.0;

      if (qb < qIFrom) {
        throw Exception("Quantity is Greater than expected value!");
      }

      // Destination Lot Logic
      final destLots = await lotMasterRepository.getLotMastersByItemAndBranch(
        itemNumber: item.itemNumber!,
        branch: destBranchId,
        companyId: companyId,
        txn: txn,
      );

      LotMaster? destLot;
      try {
        destLot = destLots.firstWhere(
          (l) =>
              l.lotNumber == sourceLot.lotNumber &&
              l.location == item.itemLocationsTo,
        );
      } catch (e) {
        destLot = null;
      }

      if (destLot == null) {
        final newLot = sourceLot.copyWith(
          id: null,
          branch: destBranchId,
          location: item.itemLocationsTo,
          quantityAvailable: 0.0,
          dateReceived: DateTime.now(),
        );
        final id = await lotMasterRepository.createLotMaster(newLot, txn: txn);
        destLot = newLot.copyWith(id: id);
      }

      // 1. Lots
      await lotMasterRepository.updateLotMaster(
        sourceLot.copyWith(quantityAvailable: qb - qIFrom),
        txn: txn,
      );
      await lotMasterRepository.updateLotMaster(
        destLot.copyWith(
          quantityAvailable: (destLot.quantityAvailable ?? 0.0) + qITo,
        ),
        txn: txn,
      );

      // 2. Locations (Cascade)
      // Source
      if (sourceLot.location != null) {
        final ilSource = await itemLocationsRepository.getItemLocationById(
          sourceLot.location!,
          companyId,
          txn: txn,
        );
        if (ilSource != null) {
          await itemLocationsRepository.updateItemLocation(
            ilSource.copyWith(
              quantityOnHand: (ilSource.quantityOnHand ?? 0.0) - qIFrom,
            ),
            txn: txn,
          );
        }
      }
      // Dest
      var ilDest = await itemLocationsRepository
          .getItemLocationByItemBranchLocation(
            branchId: destBranchId,
            itemNumber: item.itemNumber!,
            locationId: destLocMaster.id!,
            companyId: companyId,
            txn: txn,
          );
      if (ilDest == null) {
        final newItemLocation = ItemLocation(
          branch: destBranchId,
          itemNumber: item.itemNumber,
          location: destLocMaster.id,
          quantityOnHand: 0.0,
          company: companyId,
          dateCreated: DateTime.now(),
          dateUpdated: DateTime.now(),
          createdBy: masterTransaction.createdBy ?? 0,
          updatedBy: masterTransaction.createdBy ?? 0,
        );
        final id = await itemLocationsRepository.createItemLocation(
          newItemLocation,
          txn: txn,
        );
        ilDest = newItemLocation.copyWith(id: id);
      }
      await itemLocationsRepository.updateItemLocation(
        ilDest.copyWith(quantityOnHand: (ilDest.quantityOnHand ?? 0.0) + qITo),
        txn: txn,
      );

      // 3. Branches (Cascade)
      if (sourceBranchId == destBranchId) {
        if (ibSource != null) {
          final newQty = (ibSource.quantityAvailable ?? 0.0) - qIFrom + qITo;
          await itemInBranchRepository.update(
            ibSource.copyWith(quantityAvailable: newQty),
            txn: txn,
          );
        }
      } else {
        if (ibSource != null) {
          await itemInBranchRepository.update(
            ibSource.copyWith(
              quantityAvailable: (ibSource.quantityAvailable ?? 0.0) - qIFrom,
            ),
            txn: txn,
          );
        }
        await itemInBranchRepository.update(
          ibDest.copyWith(
            quantityAvailable: (ibDest.quantityAvailable ?? 0.0) + qITo,
          ),
          txn: txn,
        );
      }
    }
    return true;
  }

  Future<void> _processAdjustmentTransaction(
    ItemTransactionModel item,
    ItemTransactionModel masterTransaction,
    bool applyLocationMgmt,
    bool applyLotMgmt,
    int companyId,
    Transaction? txn,
  ) async {
    final incDec = item.adjustToIncrease ? 'I' : 'D';

    if (!applyLocationMgmt && !applyLotMgmt) {
      await _adjustItemBranch(item, masterTransaction, incDec, companyId, txn);
    } else if (applyLocationMgmt && !applyLotMgmt) {
      await _adjustItemLocation(
        item,
        masterTransaction,
        incDec,
        companyId,
        txn,
      );
    } else if (applyLocationMgmt && applyLotMgmt) {
      await _adjustLotMaster(item, masterTransaction, incDec, companyId, txn);
    }
  }

  Future<void> _adjustItemBranch(
    ItemTransactionModel item,
    ItemTransactionModel masterTransaction,
    String incDec,
    int companyId,
    Transaction? txn,
  ) async {
    final ib = await itemInBranchRepository.findByItemAndBranch(
      item.itemNumber!,
      masterTransaction.branch!,
      companyId,
      txn: txn,
    );

    if (ib != null) {
      final currentQty = ib.quantityAvailable ?? 0.0;

      // Calculate Factor: Transaction UoM -> Item Branch UoM (usually Primary)
      double factor = 1.0;
      if (item.unitOfMeasure != null && ib.unitOfMeasure != null) {
        // Assuming 'ib.unitOfMeasure' is the storage UoM
        factor = await itemUomConversionRepository.fromOtherToAnother(
          item.itemNumber!,
          item.unitOfMeasure!,
          ib.unitOfMeasure!,
          companyId,
          txn: txn,
        );
      }

      final adjustmentQty = (item.quantityTransaction * factor).abs();

      if (incDec == 'D' && currentQty < adjustmentQty) {
        throw Exception("Quantity is Greater than expected value!");
      }

      final newQty = incDec == 'I'
          ? currentQty + adjustmentQty
          : currentQty - adjustmentQty;

      final updatedIb = ib.copyWith(quantityAvailable: newQty);
      await itemInBranchRepository.update(updatedIb, txn: txn);
    }
  }

  Future<void> _adjustItemLocation(
    ItemTransactionModel item,
    ItemTransactionModel masterTransaction,
    String incDec,
    int companyId,
    Transaction? txn,
  ) async {
    if (item.itemLocation != null) {
      // 1. Fetch by ID
      final il = await itemLocationsRepository.getItemLocationById(
        item.itemLocation!,
        companyId,
        txn: txn,
      );

      if (il != null) {
        final qb = il.quantityOnHand ?? 0.0;

        // 2. Conversion: Transaction UoM -> Item Primary (Standard)
        // We assume Locations store in Primary UoM for simplicity, or we check IB's UoM.
        final ib = await itemInBranchRepository.findByItemAndBranch(
          item.itemNumber!,
          masterTransaction.branch!,
          companyId,
        );

        double factor = 1.0;
        if (item.unitOfMeasure != null && ib?.unitOfMeasure != null) {
          factor = await itemUomConversionRepository.fromOtherToAnother(
            item.itemNumber!,
            item.unitOfMeasure!,
            ib!.unitOfMeasure!,
            companyId,
          );
        }

        final qI = (factor * item.quantityTransaction).abs();

        if (incDec == 'D' && qb < qI) {
          throw Exception("Quantity is Greater than expected value!");
        }

        final newQty = (incDec == 'I') ? qb + qI : qb - qI;
        final updatedLoc = il.copyWith(quantityOnHand: newQty);

        await itemLocationsRepository.updateItemLocation(updatedLoc, txn: txn);

        // 3. Cascade to Branch
        // We apply the SAME delta (qI) to the branch
        if (ib != null) {
          final currentBranchQty = ib.quantityAvailable ?? 0.0;
          final newBranchQty = (incDec == 'I')
              ? currentBranchQty + qI
              : currentBranchQty - qI;

          await itemInBranchRepository.update(
            ib.copyWith(quantityAvailable: newBranchQty),
          );
        }
      }
    }
  }

  Future<void> _adjustLotMaster(
    ItemTransactionModel item,
    ItemTransactionModel masterTransaction,
    String incDec,
    int companyId,
    Transaction? txn,
  ) async {
    if (item.lotNumber != null) {
      // 1. Fetch by ID
      final lm = await lotMasterRepository.getLotMasterById(
        item.lotNumber!,
        companyId,
        txn: txn,
      );

      if (lm != null) {
        final qb = lm.quantityAvailable ?? 0.0;

        // 2. Conversion
        final ib = await itemInBranchRepository.findByItemAndBranch(
          item.itemNumber!,
          masterTransaction.branch!,
          companyId,
        );

        double factor = 1.0;
        if (item.unitOfMeasure != null && ib?.unitOfMeasure != null) {
          factor = await itemUomConversionRepository.fromOtherToAnother(
            item.itemNumber!,
            item.unitOfMeasure!,
            ib!.unitOfMeasure!,
            companyId,
          );
        }

        final qI = (factor * item.quantityTransaction).abs();

        // Validation
        if (incDec == 'D' && qb < qI) {
          throw Exception("Quantity is Greater than expected value!");
        }

        final newQty = (incDec == 'I') ? qb + qI : qb - qI;
        final updatedLot = lm.copyWith(quantityAvailable: newQty);

        await lotMasterRepository.updateLotMaster(updatedLot, txn: txn);

        // 3. Cascade - Location (if exists)
        if (lm.location != null) {
          final il = await itemLocationsRepository.getItemLocationById(
            lm.location!,
            companyId,
            txn: txn,
          );
          if (il != null) {
            final currentLocQty = il.quantityOnHand ?? 0.0;
            final newLocQty = (incDec == 'I')
                ? currentLocQty + qI
                : currentLocQty - qI;
            await itemLocationsRepository.updateItemLocation(
              il.copyWith(quantityOnHand: newLocQty),
              txn: txn,
            );
          }
        }

        // 4. Cascade - Branch
        if (ib != null) {
          final currentBranchQty = ib.quantityAvailable ?? 0.0;
          final newBranchQty = (incDec == 'I')
              ? currentBranchQty + qI
              : currentBranchQty - qI;
          await itemInBranchRepository.update(
            ib.copyWith(quantityAvailable: newBranchQty),
          );
        }
      }
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
      if (kDebugMode) {
        developer.log('Error calculating opening amount: $e');
      }
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
      if (kDebugMode) {
        developer.log('Error calculating total opening: $e');
      }
      throw Exception('Failed to calculate total opening: $e');
    }
  }

  Future<int?> _getItemBranchUoM(
    int itemNumber,
    int branch,
    int companyId, {
    Transaction? txn,
  }) async {
    final db = txn ?? await databaseService.database;
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
                 it.item_location,
                il.location,
                lcm.location_description as location_description,
             lm.lot_number,
             ib.quantity_available,
             i.item_description as item_description,
             b.description as branch_name,
             udt.description_1 as transaction_type_description,
             udt.detail_code as transaction_type_code,
             uds.description_1 as lot_status_description,
             uds.detail_code as lot_status_code,
             udo.description_1 as order_type_description,
             udo.detail_code as order_type_code,
             sup.supplier_name as supplier_name,
             cus.customer_name as customer_name,
             lm.batch_number_supplier as batch_number_supplier,
             udm.description_1 as unit_of_measure_description
      FROM item_transactions it
      LEFT JOIN item_location il ON it.item_location = il.id
      LEFT JOIN location_master lcm ON il.location = lcm.id
      LEFT JOIN lot_master lm ON it.lot_number = lm.id
      LEFT JOIN items_in_branch ib ON it.item_branch = ib.id
      LEFT JOIN items_table i ON it.item_number = i.id
      LEFT JOIN branch_table b ON it.branch = b.id
      LEFT JOIN udc_details udt ON it.transaction_type = udt.id
      LEFT JOIN udc_details uds ON it.lot_status = uds.id
      LEFT JOIN udc_details udm ON it.unit_of_measure = udm.id
      LEFT JOIN udc_details udo ON it.order_type = udo.id
      LEFT JOIN supplier_table sup ON it.supplier = sup.id
      LEFT JOIN customer_table cus ON it.customer = cus.id
      WHERE it.company = ?
      ORDER BY it.date_created DESC
    ''',
      [companyId],
    );

    return transactions
        .map((map) => ItemTransactionModel.fromMap(map))
        .toList();
  }

  Future<PaginatedItemTransactionResult> getPaginatedItemTransactions({
    required int companyId,
    required int page,
    required int pageSize,
    String? sortField,
    bool ascending = true,
  }) async {
    final db = await databaseService.database;

    // Build base query
    var query = '''
        SELECT it.*,
             il.location,
             lcm.location_description as location_description,
             lm.lot_number,
             lm.batch_number_supplier as batch_number_supplier,
             ib.quantity_available,
             i.item_description as item_description,
             b.description as branch_name,
             udt.description_1 as transaction_type_description,
             uds.description_1 as lot_status_description,
             udo.description_1 as order_type_description,
             sup.supplier_name as supplier_name,
             cus.customer_name as customer_name,
             udm.description_1 as unit_of_measure_description
      FROM item_transactions it
      LEFT JOIN item_location il ON it.item_location = il.id
      LEFT JOIN location_master lcm ON il.location = lcm.id
      LEFT JOIN lot_master lm ON it.lot_number = lm.id
      LEFT JOIN items_in_branch ib ON it.item_branch = ib.id
      LEFT JOIN items_table i ON it.item_number = i.id
      LEFT JOIN branch_table b ON it.branch = b.id
      LEFT JOIN udc_details udt ON it.transaction_type = udt.id
      LEFT JOIN udc_details uds ON it.lot_status = uds.id
      LEFT JOIN udc_details udm ON it.unit_of_measure = udm.id
      LEFT JOIN udc_details udo ON it.order_type = udo.id
      LEFT JOIN supplier_table sup ON it.supplier = sup.id
      LEFT JOIN customer_table cus ON it.customer = cus.id
      WHERE it.company = ?
    ''';

    final params = <dynamic>[companyId];

    // Add sorting
    if (sortField != null) {
      query += ' ORDER BY $sortField ${ascending ? 'ASC' : 'DESC'}';
    }

    // Add pagination
    query += ' LIMIT ? OFFSET ?';
    params.add(pageSize);
    params.add((page - 1) * pageSize);

    // Execute main query
    final itemsData = await db.rawQuery(query, params);

    // Count total records
    final countResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM item_transactions WHERE company = ?',
      [companyId],
    );

    final totalCount = (countResult.first['count'] as int?) ?? 0;

    // Parse results
    final items = itemsData.map((row) {
      return ItemTransactionModel.fromMap(row);
    }).toList();

    return PaginatedItemTransactionResult(items: items, totalCount: totalCount);
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

  Future<double> openingQuantityBefore(
    int itemId,
    int companyId,
    DateTime dateFrom,
  ) async {
    try {
      final db = await databaseService.database;
      final typeCodes = ["A", "I", "T"];
      final typeIds = <int>[];

      for (var code in typeCodes) {
        final udc = await udcDetailsController.getLocalUdcDetailsByCode(
          code,
          'TT',
        );
        if (udc.isNotEmpty) {
          typeIds.add(udc.first.id);
        }
      }

      final dateFromStr = dateFrom.toIso8601String();
      final startOfDay = DateTime(
        dateFrom.year,
        dateFrom.month,
        dateFrom.day,
      ).toIso8601String();

      double transValueTotal = 0.0;
      if (typeIds.isNotEmpty) {
        final typeIdsStr = typeIds.join(',');
        final transactions = await db.rawQuery(
          '''
          SELECT quantity_transaction, unit_of_measure 
          FROM item_transactions 
          WHERE company = ? 
          AND item_number = ? 
          AND order_type IS NULL 
          AND transaction_type IN ($typeIdsStr)
          AND date_created < ?
        ''',
          [companyId, itemId, dateFromStr],
        );

        for (var row in transactions) {
          final qty = row['quantity_transaction'] as double? ?? 0.0;
          final uom = row['unit_of_measure'] as int?;

          if (uom != null) {
            final rowFactor = await itemUomConversionRepository
                .fromOtherToPrimary(itemId, uom, companyId);
            transValueTotal += (qty * rowFactor);
          }
        }
      }
      final purchasesResult = await db.rawQuery(
        '''
        SELECT SUM(d.quantity_transaction) as total
        FROM purchase_order_detail d
        JOIN purchase_order_header h ON d.po_header = h.id
        WHERE d.company = ?
        AND d.item_number = ?
        AND h.date_transation < ?
      ''',
        [companyId, itemId, startOfDay],
      );

      final totalPurchases = (purchasesResult.first['total'] as double?) ?? 0.0;

      final salesResult = await db.rawQuery(
        '''
        SELECT SUM(d.quantity) as total
        FROM sales_order_details d
        JOIN sales_order_header h ON d.sales_order_header_id = h.id
        WHERE d.company = ?
        AND d.items_table_id = ?
        AND (h.void_indicator IS NULL OR h.void_indicator = 'null') 
        AND h.order_date < ?
      ''',
        [companyId, itemId, startOfDay],
      );

      final cogs = (salesResult.first['total'] as double?) ?? 0.0;

      return (transValueTotal + totalPurchases) - cogs;
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error in openingQuantityBefore: $e');
      }
      return 0.0;
    }
  }

  Future<double> openingQuantityBeforeToday(
    int itemId,
    int companyId,
    DateTime dateFrom,
  ) async {
    try {
      final db = await databaseService.database;

      final typeCodes = ["A", "I", "T"];
      final typeIds = <int>[];
      for (var code in typeCodes) {
        final udc = await udcDetailsController.getLocalUdcDetailsByCode(
          code,
          'TT',
        );
        if (udc.isNotEmpty) {
          typeIds.add(udc.first.id);
        }
      }

      final startOfDay = DateTime(dateFrom.year, dateFrom.month, dateFrom.day);
      final endOfDay = DateTime(
        dateFrom.year,
        dateFrom.month,
        dateFrom.day,
        23,
        59,
        59,
        999,
      );

      final startStr = startOfDay.toIso8601String();
      final endStr = endOfDay.toIso8601String();

      double transValueTotal = 0.0;
      if (typeIds.isNotEmpty) {
        final typeIdsStr = typeIds.join(',');
        final transactions = await db.rawQuery(
          '''
          SELECT quantity_transaction, unit_of_measure 
          FROM item_transactions 
          WHERE company = ? 
          AND item_number = ? 
          AND order_type IS NULL 
          AND transaction_type IN ($typeIdsStr)
          AND date_created BETWEEN ? AND ?
        ''',
          [companyId, itemId, startStr, endStr],
        );

        for (var row in transactions) {
          final qty = row['quantity_transaction'] as double? ?? 0.0;
          final uom = row['unit_of_measure'] as int?;

          if (uom != null) {
            final rowFactor = await itemUomConversionRepository
                .fromOtherToPrimary(itemId, uom, companyId);
            transValueTotal += (qty * rowFactor);
          }
        }
      }
      final purchasesResult = await db.rawQuery(
        '''
        SELECT SUM(d.quantity_transaction) as total
        FROM purchase_order_detail d
        JOIN purchase_order_header h ON d.po_header = h.id
        WHERE d.company = ?
        AND d.item_number = ?
        AND h.date_transation BETWEEN ? AND ?
      ''',
        [companyId, itemId, startStr, endStr],
      );

      final totalPurchases = (purchasesResult.first['total'] as double?) ?? 0.0;

      return transValueTotal + totalPurchases;
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error in openingQuantityBeforeToday: $e');
      }
      return 0.0;
    }
  }

  Future<double> salesQTYonthisdates(
    int itemId,
    int companyId,
    DateTime dateFrom,
  ) async {
    try {
      final db = await databaseService.database;

      // 1. Get UDC for Order Type "S" (Sales) in Header "OT"
      final udcList = await udcDetailsController.getLocalUdcDetailsByCode(
        'SO',
        'OT',
      );
      int? orderTypeId;
      if (udcList.isNotEmpty) {
        orderTypeId = udcList.first.id;
      }

      if (orderTypeId == null) {
        return 0.0;
      }

      // 2. Date Range: Start of Day to End of Day
      final startOfDay = DateTime(
        dateFrom.year,
        dateFrom.month,
        dateFrom.day,
      ).toIso8601String();

      final endOfDay = DateTime(
        dateFrom.year,
        dateFrom.month,
        dateFrom.day,
        23,
        59,
        59,
        999,
      ).toIso8601String();

      // 3. Query ItemTransactions
      // "SELECT i FROM ItemTransactions i WHERE ... AND orderType = :orderType"
      // Sum quantityTransaction
      final result = await db.rawQuery(
        '''
        SELECT SUM(quantity_transaction) as total
        FROM item_transactions
        WHERE company = ?
        AND item_number = ?
        AND order_type = ?
        AND date_created BETWEEN ? AND ?
      ''',
        [companyId, itemId, orderTypeId, startOfDay, endOfDay],
      );

      final totalAmt = (result.first['total'] as double?) ?? 0.0;

      return totalAmt.abs();
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error in salesQTYonthisdates: $e');
      }
      return 0.0;
    }
  }

  Future<double> diffrencesalesOnThisdatesQTY(
    int itemId,
    int companyId,
    DateTime dateFrom,
  ) async {
    try {
      final salesQty = await salesQTYonthisdates(itemId, companyId, dateFrom);
      final before = await openingQuantityBefore(itemId, companyId, dateFrom);
      final today = await openingQuantityBeforeToday(
        itemId,
        companyId,
        dateFrom,
      );

      final totalQty = before + today;
      final amt = totalQty - salesQty;

      return amt;
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error in diffrencesalesOnThisdatesQTY: $e');
      }
      return 0.0;
    }
  }

  Future<double> openingAmountInitial(
    int itemId,
    int companyId,
    DateTime dateFrom,
    DateTime dateThru,
  ) async {
    try {
      final db = await databaseService.database;

      // 1. Get the balance as of the start of history (before any transactions in range)
      double balanceBefore = await openingAmountBefore(
        itemId,
        companyId,
        dateFrom,
      );

      // 2. Sum internal movements (A, I, T) DURING the range
      double internalMovementsValue = 0.0;

      final typeCodes = ["A", "I", "T"];
      final typeIds = <int>[];
      for (var code in typeCodes) {
        final udc = await udcDetailsController.getUdcDetailsByCode(code, 'TT');
        if (udc.isNotEmpty) {
          typeIds.add(udc.first.id);
        }
      }

      if (typeIds.isNotEmpty) {
        final dateFromStr = DateTime(
          dateFrom.year,
          dateFrom.month,
          dateFrom.day,
        ).toIso8601String();
        final dateThruEndOfDay = DateTime(
          dateThru.year,
          dateThru.month,
          dateThru.day,
          23,
          59,
          59,
          999,
        ).toIso8601String();

        final typeIdsStr = typeIds.join(',');
        final transactions = await db.rawQuery(
          '''
          SELECT amount_cost 
          FROM item_transactions 
          WHERE company = ? 
          AND item_number = ? 
          AND order_type IS NULL 
          AND transaction_type IN ($typeIdsStr)
          AND date_created BETWEEN ? AND ?
        ''',
          [companyId, itemId, dateFromStr, dateThruEndOfDay],
        );

        for (var row in transactions) {
          internalMovementsValue +=
              (row['amount_cost'] as num?)?.toDouble() ?? 0.0;
        }
      }

      return balanceBefore + internalMovementsValue;
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error in openingAmountInitial: $e');
      }
      return 0.0;
    }
  }

  Future<double> openingAmountBefore(
    int itemId,
    int companyId,
    DateTime dateFrom,
  ) async {
    try {
      final db = await databaseService.database;
      final startOfDay = DateTime(
        dateFrom.year,
        dateFrom.month,
        dateFrom.day,
      ).toIso8601String();

      // We can get the opening balance MUCH more reliably by looking at
      // the 'before_amount_cost' of the FIRST transaction on or after dateFrom,
      // OR the 'after' balance of the transaction before it.

      final firstInPeriod = await db.rawQuery(
        '''
        SELECT before_amount_cost 
        FROM item_transactions 
        WHERE company = ? AND item_number = ? AND date_created >= ?
        ORDER BY date_created ASC LIMIT 1
      ''',
        [companyId, itemId, startOfDay],
      );

      if (firstInPeriod.isNotEmpty) {
        return (firstInPeriod.first['before_amount_cost'] as num?)
                ?.toDouble() ??
            0.0;
      }

      // If no transactions on or after dateFrom, find the LAST one BEFORE dateFrom
      final lastBeforePeriod = await db.rawQuery(
        '''
        SELECT before_amount_cost, amount_cost 
        FROM item_transactions 
        WHERE company = ? AND item_number = ? AND date_created < ?
        ORDER BY date_created DESC LIMIT 1
      ''',
        [companyId, itemId, startOfDay],
      );

      if (lastBeforePeriod.isNotEmpty) {
        final before =
            (lastBeforePeriod.first['before_amount_cost'] as num?)
                ?.toDouble() ??
            0.0;
        final delta =
            (lastBeforePeriod.first['amount_cost'] as num?)?.toDouble() ?? 0.0;
        return before + delta;
      }

      // Fallback: Current items in branch value if NO transaction history exists
      final itemInBranchList = await itemInBranchRepository.findByItem(
        itemId,
        companyId,
      );
      double currentTotalValue = 0.0;
      final itemCost = await itemCostRepository.findByItem(itemId, companyId);
      final unitCost = itemCost?.amountUnitCost ?? 0.0;

      for (var ib in itemInBranchList) {
        final factor = await itemUomConversionRepository.fromOtherToPrimary(
          itemId,
          ib.unitOfMeasure!,
          companyId,
        );
        currentTotalValue += (ib.quantityAvailable ?? 0.0) * factor * unitCost;
      }

      return currentTotalValue;
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error in openingAmountBefore: $e');
      }
      return 0.0;
    }
  }

  Future<double> purchaseAmountOnDate(
    int itemId,
    int companyId,
    DateTime dateFrom,
    DateTime dateThru,
  ) async {
    try {
      final db = await databaseService.database;

      final startOfDay = DateTime(
        dateFrom.year,
        dateFrom.month,
        dateFrom.day,
      ).toIso8601String();

      final endOfDay = DateTime(
        dateThru.year,
        dateThru.month,
        dateThru.day,
        23,
        59,
        59,
        999,
      ).toIso8601String();

      final result = await db.rawQuery(
        '''
        SELECT SUM(d.amount_extended_cost) as total
        FROM purchase_order_detail d
        JOIN purchase_order_header h ON d.po_header = h.id
        WHERE d.company = ?
        AND d.item_number = ?
        AND h.date_transation BETWEEN ? AND ?
      ''',
        [companyId, itemId, startOfDay, endOfDay],
      );

      final totalAmt = (result.first['total'] as double?) ?? 0.0;
      return totalAmt;
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error in purchaseAmountOnDate: $e');
      }
      return 0.0;
    }
  }

  Future<double> salesAmountOnThisDate(
    int itemId,
    int companyId,
    DateTime dateFrom,
    DateTime dateThru,
  ) async {
    try {
      final db = await databaseService.database;

      final startOfDay = DateTime(
        dateFrom.year,
        dateFrom.month,
        dateFrom.day,
      ).toIso8601String();

      final endOfDay = DateTime(
        dateThru.year,
        dateThru.month,
        dateThru.day,
        23,
        59,
        59,
        999,
      ).toIso8601String();

      final result = await db.rawQuery(
        '''
        SELECT SUM(d.extended_price) as total
        FROM sales_order_details d
        JOIN sales_order_header h ON d.sales_order_header_id = h.id
        WHERE d.company = ?
        AND d.items_table_id = ?
        AND h.order_date BETWEEN ? AND ?
      ''',
        [companyId, itemId, startOfDay, endOfDay],
      );

      final totalAmt = (result.first['total'] as double?) ?? 0.0;
      return totalAmt;
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error in salesAmountOnDate: $e');
      }
      return 0.0;
    }
  }

  Future<double> salesAmountOnThisDateCOS(
    int itemId,
    int companyId,
    DateTime dateFrom,
    DateTime dateThru,
  ) async {
    try {
      final db = await databaseService.database;

      final startOfDay = DateTime(
        dateFrom.year,
        dateFrom.month,
        dateFrom.day,
      ).toIso8601String();

      final endOfDay = DateTime(
        dateThru.year,
        dateThru.month,
        dateThru.day,
        23,
        59,
        59,
        999,
      ).toIso8601String();

      final result = await db.rawQuery(
        '''
        SELECT SUM(d.amount_cost) as total
        FROM sales_order_details d
        JOIN sales_order_header h ON d.sales_order_header_id = h.id
        WHERE d.company = ?
        AND d.items_table_id = ?
        AND h.order_date BETWEEN ? AND ?
      ''',
        [companyId, itemId, startOfDay, endOfDay],
      );

      final totalAmt = (result.first['total'] as double?) ?? 0.0;
      return totalAmt;
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error in salesAmountOnThisDateCOS: $e');
      }
      return 0.0;
    }
  }

  //gross profit(salesAmountOnThisDate - salesAmountOnThisDateCOS)
  Future<double> grossProfitOnThisDate(
    int itemId,
    int companyId,
    DateTime dateFrom,
    DateTime dateThru,
  ) async {
    try {
      final totalSalesAmountOnThisDate = await salesAmountOnThisDate(
        itemId,
        companyId,
        dateFrom,
        dateThru,
      );
      final totalSalesAmountCostOnThisDateCOS = await salesAmountOnThisDateCOS(
        itemId,
        companyId,
        dateFrom,
        dateThru,
      );
      return totalSalesAmountOnThisDate - totalSalesAmountCostOnThisDateCOS;
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error in grossProfitOnThisDate: $e');
      }
      return 0.0;
    }
  }

  //amount ending(openingAmountInitial - purchaseAmountOnDate + salesAmountOnDateCOS)
  Future<double> amountEnding(
    int itemId,
    int companyId,
    DateTime dateFrom,
    DateTime dateThru,
  ) async {
    try {
      final oai = await openingAmountInitial(
        itemId,
        companyId,
        dateFrom,
        dateThru,
      );
      final paotd = await purchaseAmountOnDate(
        itemId,
        companyId,
        dateFrom,
        dateThru,
      );
      final saotd = await salesAmountOnThisDateCOS(
        itemId,
        companyId,
        dateFrom,
        dateThru,
      );
      return oai + paotd - saotd;
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error in amountEnding: $e');
      }
      return 0.0;
    }
  }

  Future<ItemInBranchModel> _getOrCreateItemInBranch(
    int itemNumber,
    int branchId,
    int companyId,
    int createdBy,
    int? uom, {
    Transaction? txn,
  }) async {
    final ib = await itemInBranchRepository.findByItemAndBranch(
      itemNumber,
      branchId,
      companyId,
      txn: txn,
    );

    if (ib != null) {
      return ib;
    }

    // Create new ItemInBranch
    final newIb = ItemInBranchModel(
      id: 0,
      itemNumber: itemNumber,
      branch: branchId,
      company: companyId,
      quantityAvailable: 0.0,
      //averageCost: 0.0, // Default
      unitOfMeasure: uom,
      reorderPoint: 0.0,
    );

    final id = await itemInBranchRepository.create(newIb, txn: txn);
    return newIb.copyWith(id: id);
  }
}
