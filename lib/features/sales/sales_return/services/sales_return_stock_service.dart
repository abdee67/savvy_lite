// features/sales/sales_return/integration/service/sales_return_stock_service.dart
import 'package:savvy_stock/core/repositories/udc_repository.dart';
import 'package:savvy_stock/features/sales/sales_order/detail/model/sales_order_detail.dart';
import 'package:savvy_stock/features/sales/sales_order/detail/repo/sales_order_detail_repo.dart';
import 'package:savvy_stock/features/sales/sales_order/header/model/sales_order_header.dart';
import 'package:savvy_stock/features/sales/sales_order/header/repo/sales_order_header_repo.dart';
import 'package:savvy_stock/features/sales/sales_return/models/void_sales_details.dart';
import 'package:savvy_stock/features/sales/sales_return/models/void_sales_header.dart';
import 'package:savvy_stock/features/sales/sales_return/repos/sales_return_repository.dart';
import 'package:savvy_stock/features/stock/item_in_branch/repo/item_in_branch_repo.dart';
import 'package:savvy_stock/features/stock/item_locations/repo/item_location_repo.dart';
import 'package:savvy_stock/features/stock/item_transactions/repo/item_transaction_repo.dart';
import 'package:savvy_stock/features/stock/item_uom_conversions/repo/item_uom_conv_repo.dart';
import 'package:savvy_stock/features/stock/lot_master/repo/lot_master_repo.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_bloc.dart';

class SalesReturnStockService {
  final StockItemInBranchRepository itemsInBranchRepository;
  final ItemLocationsRepository itemLocationsRepository;
  final LotMasterRepository lotMasterRepository;
  final ItemTransactionRepository itemTransactionsRepository;
  final ItemUomConversionsRepository itemUomConversionsRepository;
  final SystemConstantBloc systemConstantBloc;
  final UdcRepository udcRepository;
  final SalesOrderDetailRepository salesOrderDetailRepository;
  final SalesOrderHeaderRepository salesOrderHeaderRepository;
  final SalesReturnRepository salesReturnRepository;

  SalesReturnStockService({
    required this.itemsInBranchRepository,
    required this.itemLocationsRepository,
    required this.lotMasterRepository,
    required this.itemTransactionsRepository,
    required this.itemUomConversionsRepository,
    required this.systemConstantBloc,
    required this.udcRepository,
    required this.salesOrderDetailRepository,
    required this.salesOrderHeaderRepository,
    required this.salesReturnRepository,
  });

  // 🎯 MAIN RETURN SUBMISSION - FOLLOWING JAVA PATTERN
  Future<void> processSalesReturnSubmission({
    required SalesReturnHeader returnHeader,
    required List<SalesReturnDetails> returnDetails,
    required SalesOrderHeader originalSalesOrder,
    required int companyId,
  }) async {
    try {
      // 1. Void the original sales order (like Java's soVoid)
      await _voidOriginalSalesOrder(
        originalSalesOrder,
        returnHeader,
        companyId,
      );

      // 2. Create sales return header(create both header and details  in bloc)
      // final createdReturnHeader = await salesReturnRepository.createSalesReturnHeader(returnHeader);

      // 3. Create sales return details
      // await salesReturnRepository.createSalesReturnDetailsBatch(returnDetails, createdReturnHeader.id!);
      // await _adjustStockForReturnDetails(returnDetails, companyId);
    } catch (e) {
      throw Exception('Failed to process sales return: $e');
    }
  }

  // 🎯 VOID ORIGINAL SALES ORDER (like Java's soVoid)
  Future<void> _voidOriginalSalesOrder(
    SalesOrderHeader salesOrder,
    SalesReturnHeader returnHeader,
    int companyId,
  ) async {
    if (salesOrder.id != null) {
      // Get all sales order details for this header
      final salesOrderDetails = await salesOrderDetailRepository
          .getSalesOrderDetailsByHeaderId(salesOrder.id!, companyId);

      for (final salesOrderDetail in salesOrderDetails) {
        await _updatingStockItemAvailablitySoVoid(salesOrderDetail, companyId);
      }

      // Update sales order header with void indicator and return references
      final updatedSalesOrder = salesOrder.copyWith(
        voidIndicator: 'V',
        referenceNote3: returnHeader.referenceNote3,
        referenceNote4: returnHeader.returnStatus?.toString(),

        //  commentIfVoid: returnHeader.commentForReturn,
      );

      await salesOrderHeaderRepository.updateSalesOrderHeader(
        updatedSalesOrder,
      );
    }
  }

  // 🎯 STOCK ADJUSTMENT FOR VOID (like Java's updatingStockItemAvailablitySoVoid)
  Future<void> _updatingStockItemAvailablitySoVoid(
    SalesOrderDetail soD,
    int companyId,
  ) async {
    try {
      if (soD.itemsTableId != null &&
          soD.quantity != null &&
          soD.quantity != 0.0 &&
          soD.itemInBranch != null) {
        final systemConstant = systemConstantBloc.state.selected;
        final applyLocationMgmt =
            systemConstant?.applyLocationMgmBoolean ?? false;
        final applyLotMgmt = systemConstant?.applyLotMgmBoolean ?? false;

        if (!applyLocationMgmt && !applyLotMgmt) {
          // Case 1: Simple stock update without location/lot management
          await _handleSimpleStockVoid(soD, companyId);
        } else if (applyLocationMgmt && !applyLotMgmt) {
          // Case 2: Location management only
          await _handleLocationStockVoid(soD, companyId);
        } else if (applyLocationMgmt && applyLotMgmt && soD.lotNumber != null) {
          // Case 3: Both location and lot management
          await _handleLotStockVoid(
            salesOrderDetail: soD,
            companyId: companyId,
          );
        }
      }
    } catch (e) {
      throw Exception('Error adjusting stock for void: $e');
    }
  }

  // 🎯 CASE 1: SIMPLE STOCK VOID (No location/lot management)
  Future<void> _handleSimpleStockVoid(
    SalesOrderDetail soD,
    int companyId,
  ) async {
    var itemsInBranch = await itemsInBranchRepository.findByItemAndBranch(
      soD.itemsTableId!,
      soD.itemInBranch!,
      companyId,
    );
    itemsInBranch ??= await itemsInBranchRepository.findById(
      soD.itemInBranch!,
      companyId,
    );

    // Fallback: if not found by ID, find by Item ID
    if (itemsInBranch == null) {
      print(
        '⚠️ ItemInBranch ${soD.itemInBranch} not found. Falling back to Item ID search.',
      );
      final matches = await itemsInBranchRepository.findByItem(
        soD.itemsTableId!,
        companyId,
      );
      if (matches.isNotEmpty) {
        itemsInBranch = matches.first;
        print(
          '✅ Fallback succeeded: Using ItemInBranch ID ${itemsInBranch.id}',
        );
      }
    }

    if (itemsInBranch != null) {
      final factor = await itemUomConversionsRepository.fromOtherToPrimary(
        soD.itemsTableId!,
        soD.unitOfMeasure!,
        companyId,
      );
      final qty = itemsInBranch.quantityAvailable! + (soD.quantity! * factor);

      // Update item branch quantity
      await itemsInBranchRepository.updateQuantity(
        itemsInBranch.id,
        qty,
        companyId,
      );

      // Create stock card transaction (like Java's stockCARDCreation)
      await itemTransactionsRepository.stockCardCreation(
        ib: itemsInBranch,
        loc: null,
        lm: null,
        transactionType: 'A', // Adjustment
        trNo: soD.orderHeader?.orderNumber,
        remark: 'Void',
        qty: soD.quantity! * factor,
        por: null,
        soD: soD,
      );
    }
  }

  // 🎯 CASE 2: LOCATION MANAGEMENT ONLY
  Future<void> _handleLocationStockVoid(
    SalesOrderDetail soD,
    int companyId,
  ) async {
    var itemInBranchRecord = await itemsInBranchRepository.findById(
      soD.itemInBranch!,
      companyId,
    );

    // Fallback
    if (itemInBranchRecord == null) {
      final matches = await itemsInBranchRepository.findByItem(
        soD.itemsTableId!,
        companyId,
      );
      if (matches.isNotEmpty) {
        itemInBranchRecord = matches.first;
      }
    }

    if (itemInBranchRecord == null) return;

    final itemLocationsList = await itemLocationsRepository
        .getItemLocationsByBranchAndItem(
          branchId: itemInBranchRecord.branch,
          itemId: soD.itemsTableId!,
          companyId: companyId,
        );

    // Filter locations with quantity
    final locationsWithStock = itemLocationsList
        .where((il) => il.quantityOnHand != null)
        .toList();

    double qtyTr = soD.quantity!;

    for (final il in locationsWithStock) {
      final item = await itemLocationsRepository.getItemLocationById(
        il.id!,
        companyId,
      );
      if (item != null) {
        final factor = await itemUomConversionsRepository.fromOtherToPrimary(
          soD.itemsTableId!,
          soD.unitOfMeasure!,
          companyId,
        );

        final changeQty = qtyTr * factor;
        final newQty = (item.quantityOnHand ?? 0.0) + changeQty;

        final updatedLoc = item.copyWith(quantityOnHand: newQty);

        // Cascading Save - Updates Location and Branch
        await itemLocationsRepository.saveLocationForSalesOrder(
          location: updatedLoc,
          transactionType: 'A',
          trNo: soD.orderHeader?.orderNumber,
          remark: 'Void',
          soD: soD,
          companyId: companyId,
        );

        // Create stock card transaction
        await itemTransactionsRepository.stockCardCreation(
          ib: null,
          loc: item,
          lm: null,
          transactionType: 'A',
          trNo: soD.orderHeader?.orderNumber,
          remark: 'Void',
          qty: changeQty,
          por: null,
          soD: soD,
        );

        // Break after updating one location to prevent duplicating stock across all locations
        break;
      }
    }
  }

  // 🎯 CASE 3: LOT MANAGEMENT

  Future<void> _handleLotStockVoid({
    required SalesOrderDetail salesOrderDetail,
    required int companyId,
  }) async {
    // Validate lot dates based on lot type (like Java's validation)
    final lt = await lotMasterRepository.getLotMasterById(
      salesOrderDetail.lotNumber!,
      companyId,
    );
    final systemConstant = systemConstantBloc.state.selected;
    final lotType = await udcRepository.getUdcDetailById(
      systemConstant?.lotType,
    );

    final lotTypeCode = lotType?.detailCode;

    bool isValidLot = false;
    if (lt == null) {
      throw Exception('Lot not found');
    }
    if (lotTypeCode == 'X' && lt.dateExpiration != null) {
      isValidLot = true;
    } else if (lotTypeCode == 'F' && lt.dateEffective != null) {
      isValidLot = true;
    } else if (lotTypeCode == 'R' && lt.dateReceived != null) {
      isValidLot = true;
    }

    if (!isValidLot) {
      throw Exception('Lot dates are not correct for the configured lot type');
    }

    // Set lot status (like Java's lotStatusIdentifier)
    lt.statusCode = await lotMasterRepository.identifyLotStatus(lt);

    // final originalQuantity = await lotMasterRepository.getLotMasterById(item.id!, companyId);
    // 🎯 FIX: Get UOM if it's null (might not be loaded from database)
    int? uomId = salesOrderDetail.unitOfMeasure;
    if (uomId == null && salesOrderDetail.itemInBranch != null) {
      // Fetch item branch to get default UOM
      final itemBranch = await itemsInBranchRepository.findById(
        salesOrderDetail.itemInBranch!,
        companyId,
      );
      uomId = itemBranch?.unitOfMeasure;
    }
    if (uomId == null) {
      throw Exception('Unit of measure not found for sales order detail');
    }

    if (lt.id == null) {
      // Create new lot
      if (lt.quantityAvailable == null || lt.quantityAvailable == 0.0) {
        lt.quantityAvailable = 0.0;
      }
      await lotMasterRepository.createLotMaster(lt);
    }

    final factor = await itemUomConversionsRepository.fromOtherToPrimary(
      salesOrderDetail.itemsTableId!,
      uomId,
      companyId,
    );

    final changeQty = salesOrderDetail.quantity! * factor;
    final newTotal = (lt.quantityAvailable ?? 0.0) + changeQty;

    final updatedLot = lt.copyWith(quantityAvailable: newTotal);

    // Cascading Save - Updates Lot, Location, and Branch
    await lotMasterRepository.saveLotForSalesOrder(
      lot: updatedLot,
      transactionType: 'A',
      trNo: salesOrderDetail.orderHeader?.orderNumber,
      remark: 'Void',
      soD: salesOrderDetail,
      companyId: companyId,
    );

    // Create stock card transaction
    await itemTransactionsRepository.stockCardCreation(
      ib: null,
      loc: null,
      lm: lt,
      transactionType: 'A',
      trNo: salesOrderDetail.orderHeader?.orderNumber,
      remark: 'Void',
      qty: changeQty,
      por: null,
      soD: salesOrderDetail,
    );
  }
}
