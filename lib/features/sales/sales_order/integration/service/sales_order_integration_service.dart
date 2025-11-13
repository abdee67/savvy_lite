// features/sales/sales_order_integration/sales_order_integration_service.dart
import 'dart:async';

import 'package:savvy_stock/features/sales/customer/models/customer_model.dart';
import 'package:savvy_stock/features/sales/sales_order/header/bloc/sales_order_header_bloc.dart';
import 'package:savvy_stock/features/sales/sales_order/header/bloc/sales_order_header_event.dart';
import 'package:savvy_stock/features/sales/sales_order/header/bloc/sales_order_header_state.dart';
import 'package:savvy_stock/features/sales/sales_order/header/model/sales_order_header.dart';
import 'package:savvy_stock/features/sales/sales_order/detail/bloc/sales_order_detail_bloc.dart';
import 'package:savvy_stock/features/sales/sales_order/detail/bloc/sales_order_detail_event.dart';
import 'package:savvy_stock/features/sales/sales_order/detail/model/sales_order_detail.dart';
import 'package:savvy_stock/features/stock/item_in_branch/models/item_in_branch_model.dart';

class SalesOrderIntegrationService {
  final SalesOrderHeaderBloc headerBloc;
  final SalesOrderDetailBloc detailBloc;

  SalesOrderIntegrationService({
    required this.headerBloc,
    required this.detailBloc,
  });

  // Replicate JSF's interdependent functionality
  Future<void> createSalesOrderWithDetails({
    required SalesOrderHeader header,
    required List<SalesOrderDetail> details,
  }) async {
    // 1. Create header first
    headerBloc.add(CreateSalesOrderHeader(header: header));

    // Wait for header creation
    await _waitForHeaderCreation(header);

    // 2. Create details with header reference
    final headerId = headerBloc.state.selected?.id;
    if (headerId != null) {
      final detailsWithHeader = details
          .map((detail) => detail.copyWith(salesOrderHeaderId: headerId))
          .toList();

      detailBloc.add(CreateSalesOrderDetails(details: detailsWithHeader.first));
    }
  }

  // Replicate JSF's calQtyWithAmt functionality
  void calculateOrderTotals(List<SalesOrderDetail> details) {
    final header = headerBloc.state.selected;
    if (header != null) {
      headerBloc.add(
        CalculateOrderTotals(
          header: header,
          orderDetails: details,
          applyWithholding: headerBloc.state.applyWH ?? false,
          discountAmount: headerBloc.state.discountAmount ?? 0.0,
        ),
      );
    }
  }

  // Replicate JSF's customerSetItems functionality
  void updateCustomerInfo(Customer customer) {
    headerBloc.add(
      UpdateCustomerInfo(
        customer: customer,
        currentHeader: headerBloc.state.selected,
      ),
    );
  }

  // Replicate JSF's unitPriceSetBySelectedItemBranch
  void updateUnitPriceFromItemBranch(
    ItemInBranchModel itemBranch,
    SalesOrderDetail detail,
  ) {
    detailBloc.add(
      UpdateUnitPriceWithUom(
        salesOrderDetail: detail,
        itemsInBranch: itemBranch,
      ),
    );

    // Recalculate totals after price update
    calculateOrderTotals(detailBloc.state.createItems);
  }

  // Replicate JSF's void functionality
  Future<void> voidSalesOrder(SalesOrderHeader header) async {
    headerBloc.add(VoidSalesOrder(id: header.id!, voidIndicator: 'V'));

    /* // Also void all associated details
    final details = await _getDetailsForHeader(header.id!);
    for (final detail in details) {
      detailBloc.add(UpdateSalesOrderDetails(
        details: detail.copyWith(voidIndicator: 'V'),
      ));
    }*/

    // Reverse stock (like Java's soVoid)
    detailBloc.add(
      ReverseStockOnVoid(
        salesOrderId: header.id!,
        applyLotMgm:
            headerBloc.state.systemConstants?.applyLotMgmBoolean ?? false,
      ),
    );
  }

  // Helper methods
  Future<SalesOrderHeader?> _waitForHeaderCreation(
    SalesOrderHeader header,
  ) async {
    final completer = Completer<SalesOrderHeader?>();
    StreamSubscription? subscription;
    int retryCount = 0;
    const maxRetries = 10;
    const retryInterval = Duration(milliseconds: 500);

    subscription = headerBloc.stream.listen((headerState) {
      // Check if header was created successfully
      if (headerState.status == SalesOrderHeaderStatus.success) {
        final createdHeader = headerState.selected;
        if (createdHeader != null && createdHeader.id != null) {
          if (!completer.isCompleted) {
            completer.complete(createdHeader);
            subscription?.cancel();
          }
          return;
        }
      }

      // Check for errors
      if (headerState.status == SalesOrderHeaderStatus.failure) {
        if (!completer.isCompleted) {
          completer.complete(null);
          subscription?.cancel();
        }
        return;
      }
    });

    // Timeout handling
    Future.delayed(const Duration(seconds: 10), () {
      if (!completer.isCompleted) {
        completer.complete(null);
        subscription?.cancel();
      }
    });

    // Retry mechanism
    final timer = Timer.periodic(retryInterval, (timer) async {
      retryCount++;
      if (retryCount >= maxRetries) {
        timer.cancel();
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      }

      // Manually trigger a refresh to check for created header
      if (headerBloc.state.companyId != null) {
        headerBloc.add(
          LoadSalesOrderHeaders(companyId: headerBloc.state.companyId!),
        );
      }
    });

    final result = await completer.future;
    timer.cancel();
    subscription?.cancel();
    return result;
  }

  // ✅ Enhanced void functionality with stock reversal
  Future<void> voidSalesOrderWithStockReversal(SalesOrderHeader header) async {
    try {
      // 1. Get all details for the header
      final details = await _getDetailsForHeader(header.id!);

      // 2. Reverse stock for each detail
      for (final detail in details) {
        if (detail.itemInBranch != null && detail.quantity != null) {
          await _reverseStockForDetail(detail);
        }
      }

      // 3. Void the header
      headerBloc.add(VoidSalesOrder(id: header.id!, voidIndicator: 'V'));

      /* // 4. Void all associated details
      final voidedDetails = details.map((detail) => 
        detail.copyWith(voidIndicator: 'V')
      ).toList(); */

      detailBloc.add(UpdateSalesOrderDetails(details: details.first));
    } catch (e) {
      throw Exception('Failed to void sales order with stock reversal: $e');
    }
  }

  Future<List<SalesOrderDetail>> _getDetailsForHeader(int headerId) async {
    try {
      final companyId = headerBloc.state.companyId;
      if (companyId == null) return [];

      // Use repository to fetch details
      final details = await detailBloc.repository
          .getSalesOrderDetailsByHeaderId(headerId, companyId);

      return details;
    } catch (e) {
      print('Error fetching details for header $headerId: $e');
      return [];
    }
  }

  Future<void> _reverseStockForDetail(SalesOrderDetail detail) async {
    // Reverse the stock adjustment (add back what was subtracted)
    final reverseDetail = detail.copyWith(
      quantity: -detail.quantity!, // Negative quantity to reverse
    );

    detailBloc.add(UpdateStockForSalesOrder(salesOrderDetail: reverseDetail));
  }
}
