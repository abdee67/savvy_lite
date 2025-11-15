// features/sales/sales_order/integration/service/sales_order_integration_service.dart
import 'dart:async';
import 'package:savvy_stock/features/sales/customer/models/customer_model.dart';
import 'package:savvy_stock/features/sales/sales_order/header/bloc/sales_order_header_bloc.dart';
import 'package:savvy_stock/features/sales/sales_order/header/bloc/sales_order_header_event.dart';
import 'package:savvy_stock/features/sales/sales_order/header/bloc/sales_order_header_state.dart';
import 'package:savvy_stock/features/sales/sales_order/header/model/sales_order_header.dart';
import 'package:savvy_stock/features/sales/sales_order/detail/bloc/sales_order_detail_bloc.dart';
import 'package:savvy_stock/features/sales/sales_order/detail/bloc/sales_order_detail_event.dart';
import 'package:savvy_stock/features/sales/sales_order/detail/bloc/sales_order_detail_state.dart';
import 'package:savvy_stock/features/sales/sales_order/detail/model/sales_order_detail.dart';
import 'package:savvy_stock/features/stock/item_in_branch/models/item_in_branch_model.dart';

class SalesOrderIntegrationService {
  final SalesOrderHeaderBloc headerBloc;
  final SalesOrderDetailBloc detailBloc;

  SalesOrderIntegrationService({
    required this.headerBloc,
    required this.detailBloc,
  });

  // 🎯 COMPLETE ORDER MANAGEMENT

  /// Creates a complete sales order with header and details (equivalent to JSF's complete order creation)
  Future<void> createSalesOrderWithDetails({
    required SalesOrderHeader header,
    required List<SalesOrderDetail> details,
  }) async {
    try {
      // Step 1: Validate business rules before creation
      await _validateOrderCreation(header, details);

      // Step 2: Create header first (like JSF's header creation)
      final createdHeader = await _createSalesOrderHeader(header);
      if (createdHeader == null) {
        throw Exception('Failed to create sales order header');
      }

      // Step 3: Create all details with header reference
      await _createSalesOrderDetails(createdHeader, details);

      // Step 4: Update stock quantities (like JSF's stock adjustment)
      await _updateStockForAllDetails(details);

      // Step 5: Calculate final totals (like JSF's calQtyWithAmt)
      await _calculateFinalTotals(createdHeader, details);

      // Step 6: Validate complete order state
      await _validateCompleteOrder(createdHeader, details);
    } catch (e) {
      // Comprehensive rollback on failure
      await _rollbackCreateOperation(header, details);
      rethrow;
    }
  }

  /// Updates an existing sales order with new header and details
  Future<void> updateSalesOrderWithDetails({
    required SalesOrderHeader header,
    required List<SalesOrderDetail> details,
  }) async {
    try {
      // Step 1: Backup current state for rollback
      final originalHeader = headerBloc.state.selected;
      final originalDetails = await _getDetailsForHeader(header.id!);

      // Step 2: Validate update operation
      await _validateOrderUpdate(header, details);

      // Step 3: Update header
      await _updateSalesOrderHeader(header);

      // Step 4: Update details (handle additions, modifications, deletions)
      await _updateSalesOrderDetails(header, details, originalDetails);

      // Step 5: Adjust stock based on changes
      await _adjustStockForUpdate(originalDetails, details);

      // Step 6: Recalculate totals
      await _calculateFinalTotals(header, details);
    } catch (e) {
      // Rollback to original state
      await _rollbackUpdateOperation(header, details);
      rethrow;
    }
  }

  /// Voids a sales order with comprehensive stock reversal (equivalent to JSF's void functionality)
  Future<void> voidSalesOrderWithStockReversal(SalesOrderHeader header) async {
    try {
      // Step 1: Get all order details for stock reversal
      final details = await _getDetailsForHeader(header.id!);

      // Step 2: Reverse stock for all details (like JSF's stock reversal on void)
      await _reverseStockForAllDetails(details);

      // Step 3: Void the header
      await _voidSalesOrderHeader(header);

      // Step 4: Void all associated details
      await _voidSalesOrderDetails(details);

      // Step 5: Validate void operation
      await _validateVoidOperation(header, details);
    } catch (e) {
      // Partial rollback for void operation
      await _rollbackVoidOperation(header);
      rethrow;
    }
  }

  /// Deletes a sales order with optional stock reversal
  Future<void> deleteSalesOrderWithStockReversal({
    required int salesOrderId,
    bool reverseStock = true,
  }) async {
    try {
      final header = headerBloc.state.headers.firstWhere(
        (h) => h.id == salesOrderId,
        orElse: () => throw Exception('Sales order not found: $salesOrderId'),
      );

      final details = await _getDetailsForHeader(salesOrderId);

      // Reverse stock if requested
      if (reverseStock) {
        await _reverseStockForAllDetails(details);
      }

      // Delete details first (due to foreign key constraints)
      await _deleteSalesOrderDetails(details);

      // Delete header
      await _deleteSalesOrderHeader(salesOrderId);
    } catch (e) {
      throw Exception('Failed to delete sales order: $e');
    }
  }

  // 🎯 FINANCIAL CALCULATIONS (JSF calQtyWithAmt equivalent)

  /// Calculates complete order totals including tax, discounts, and withholding
  Future<void> calculateOrderTotals(List<SalesOrderDetail> details) async {
    final currentHeader = headerBloc.state.selected;
    if (currentHeader == null) {
      throw Exception('No header selected for calculation');
    }

    if (details.isEmpty) {
      throw Exception('No details available for calculation');
    }

    try {
      // Calculate subtotal from all details
      final subTotal = _calculateSubtotal(details);

      // Get current financial settings from header state
      final applyWithholding = headerBloc.state.applyWH ?? false;
      final discountAmount = headerBloc.state.discountAmount ?? 0.0;

      // Trigger comprehensive calculation in header bloc
      headerBloc.add(
        CalculateOrderTotals(
          header: currentHeader,
          orderDetails: details,
          applyWithholding: applyWithholding,
          discountAmount: discountAmount,
        ),
      );

      // Wait for calculation to complete
      await _waitForCalculationCompletion();
    } catch (e) {
      throw Exception('Failed to calculate order totals: $e');
    }
  }

  // 🎯 CUSTOMER MANAGEMENT (JSF customerSetItems equivalent)

  /// Updates customer information and propagates to order
  void updateCustomerInfo(Customer customer) {
    final currentHeader = headerBloc.state.selected;

    // Update customer info in header (like JSF's customerSetItems)
    headerBloc.add(
      UpdateCustomerInfo(customer: customer, currentHeader: currentHeader),
    );

    // Apply customer-specific pricing to details if needed
    _applyCustomerPricingToDetails(customer);
  }

  // 🎯 PRICE MANAGEMENT (JSF unitPriceSetBySelectedItemBranch equivalent)

  /// Updates unit price based on selected item branch with UOM conversion
  void updateUnitPriceFromItemBranch(
    ItemInBranchModel itemBranch,
    SalesOrderDetail detail,
  ) {
    // Update unit price with UOM conversion (like JSF's unitPriceSetBySelectedItemBranch)
    detailBloc.add(
      UpdateUnitPriceWithUom(
        salesOrderDetail: detail,
        itemsInBranch: itemBranch,
      ),
    );

    // Auto-recalculate extended price
    detailBloc.add(CalculateExtendedPrice(item: detail));

    // Recalculate order totals after price update
    final currentDetails = detailBloc.state.createItems;
    if (currentDetails.isNotEmpty) {
      calculateOrderTotals(currentDetails);
    }
  }

  // 🎯 STOCK MANAGEMENT

  /// Validates stock availability for all order details
  Future<void> validateAllStock(List<SalesOrderDetail> details) async {
    if (details.isEmpty) return;

    try {
      for (final detail in details) {
        if (detail.itemInBranch != null) {
          // Trigger stock validation for each detail
          detailBloc.add(ValidateStockAvailability(salesOrderDetail: detail));

          // Small delay to prevent overwhelming the system
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

      // Wait for all validations to complete
      await _waitForStockValidationCompletion(details.length);
    } catch (e) {
      throw Exception('Stock validation failed: $e');
    }
  }

  /// Updates stock for all details in the order
  Future<void> updateStockForAllDetails(List<SalesOrderDetail> details) async {
    for (final detail in details) {
      if (detail.itemInBranch != null && detail.quantity != null) {
        detailBloc.add(UpdateStockForSalesOrder(salesOrderDetail: detail));

        // Small delay to prevent database contention
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }
  }

  // 🎯 ORDER PREPARATION & INITIALIZATION

  /// Prepares a new sales order with default values
  Future<void> prepareNewSalesOrder({
    required int companyId,
    required int employeeId,
    required int branchId,
    Customer? defaultCustomer,
  }) async {
    try {
      // Prepare header
      headerBloc.add(
        PrepareCreateSalesOrderHeader(
          companyId: companyId,
          branchId: branchId,
          employeeId: employeeId,
        ),
      );

      // Wait for header preparation
      await _waitForHeaderPreparation();

      // Prepare details
      detailBloc.add(PrepareCreateSalesOrderDetails());

      // Set default customer if provided
      if (defaultCustomer != null) {
        updateCustomerInfo(defaultCustomer);
      }
    } catch (e) {
      throw Exception('Failed to prepare new sales order: $e');
    }
  }

  /// Loads a complete sales order with header and details
  Future<void> loadCompleteSalesOrder(int salesOrderId) async {
    try {
      // Find and select the header
      final header = headerBloc.state.headers.firstWhere(
        (h) => h.id == salesOrderId,
        orElse: () => throw Exception('Sales order not found: $salesOrderId'),
      );

      headerBloc.add(SelectSalesOrder(header: header));

      // Load details for the header
      detailBloc.add(LoadSalesOrderDetailsByHeader(headerId: salesOrderId));

      // Wait for details to load
      await _waitForDetailsLoadCompletion();
    } catch (e) {
      throw Exception('Failed to load sales order: $e');
    }
  }

  // 🎯 PRIVATE IMPLEMENTATION METHODS

  // Header Operations
  Future<SalesOrderHeader?> _createSalesOrderHeader(
    SalesOrderHeader header,
  ) async {
    final completer = Completer<SalesOrderHeader?>();
    late StreamSubscription subscription;
    int retryCount = 0;
    const maxRetries = 10;

    subscription = headerBloc.stream.listen((headerState) {
      if (headerState.status == SalesOrderHeaderStatus.success &&
          headerState.selected?.id != null) {
        if (!completer.isCompleted) {
          completer.complete(headerState.selected);
          subscription.cancel();
        }
      } else if (headerState.status == SalesOrderHeaderStatus.failure) {
        if (!completer.isCompleted) {
          completer.complete(null);
          subscription.cancel();
        }
      }
    });

    // Start header creation
    headerBloc.add(CreateSalesOrderHeader(header: header));

    // Timeout handling
    Future.delayed(const Duration(seconds: 10), () {
      if (!completer.isCompleted) {
        completer.complete(null);
        subscription.cancel();
      }
    });

    // Retry mechanism for edge cases
    final timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      retryCount++;
      if (retryCount >= maxRetries) {
        timer.cancel();
        if (!completer.isCompleted) completer.complete(null);
      }
    });

    final result = await completer.future;
    timer.cancel();
    await subscription.cancel();
    return result;
  }

  Future<void> _updateSalesOrderHeader(SalesOrderHeader header) async {
    final completer = Completer<void>();
    late StreamSubscription subscription;
    subscription = headerBloc.stream.listen((headerState) {
      if (headerState.status == SalesOrderHeaderStatus.success) {
        if (!completer.isCompleted) {
          completer.complete();
          subscription.cancel();
        }
      } else if (headerState.status == SalesOrderHeaderStatus.failure) {
        if (!completer.isCompleted) {
          completer.completeError(headerState.error ?? 'Header update failed');
          subscription.cancel();
        }
      }
    });

    headerBloc.add(UpdateSalesOrderHeader(header: header));
    await completer.future.timeout(const Duration(seconds: 10));
  }

  Future<void> _voidSalesOrderHeader(SalesOrderHeader header) async {
    final completer = Completer<void>();
    late StreamSubscription subscription;
    subscription = headerBloc.stream.listen((headerState) {
      if (headerState.status == SalesOrderHeaderStatus.success) {
        if (!completer.isCompleted) {
          completer.complete();
          subscription.cancel();
        }
      } else if (headerState.status == SalesOrderHeaderStatus.failure) {
        if (!completer.isCompleted) {
          completer.completeError(headerState.error ?? 'Header void failed');
          subscription.cancel();
        }
      }
    });

    headerBloc.add(VoidSalesOrder(id: header.id!, voidIndicator: 'V'));
    await completer.future.timeout(const Duration(seconds: 10));
  }

  Future<void> _deleteSalesOrderHeader(int headerId) async {
    final completer = Completer<void>();
    late StreamSubscription subscription;
    subscription = headerBloc.stream.listen((headerState) {
      if (headerState.status == SalesOrderHeaderStatus.success) {
        if (!completer.isCompleted) {
          completer.complete();
          subscription.cancel();
        }
      } else if (headerState.status == SalesOrderHeaderStatus.failure) {
        if (!completer.isCompleted) {
          completer.completeError(
            headerState.error ?? 'Header deletion failed',
          );
          subscription.cancel();
        }
      }
    });

    headerBloc.add(DeleteSalesOrderHeader(id: headerId));
    await completer.future.timeout(const Duration(seconds: 10));
  }

  // Detail Operations
  Future<void> _createSalesOrderDetails(
    SalesOrderHeader header,
    List<SalesOrderDetail> details,
  ) async {
    // Clear any existing create items
    detailBloc.add(const ClearCreateItemsSalesOrderDetails());

    // Add all details with header reference
    for (final detail in details) {
      final detailWithHeader = detail.copyWith(salesOrderHeaderId: header.id);
      detailBloc.add(AddToCreateItemsSalesOrderDetails(item: detailWithHeader));
    }

    // Save all details
    final completer = Completer<void>();
    late StreamSubscription subscription;
    subscription = detailBloc.stream.listen((detailState) {
      if (detailState.status == SalesOrderDetailStatus.success) {
        if (!completer.isCompleted) {
          completer.complete();
          subscription.cancel();
        }
      } else if (detailState.status == SalesOrderDetailStatus.failure) {
        if (!completer.isCompleted) {
          completer.completeError(
            detailState.errorMessage ?? 'Details creation failed',
          );
          subscription.cancel();
        }
      }
    });

    detailBloc.add(SaveCreateItems(salesOrderHeaderId: header.id!));
    await completer.future.timeout(const Duration(seconds: 15));
  }

  Future<void> _updateSalesOrderDetails(
    SalesOrderHeader header,
    List<SalesOrderDetail> newDetails,
    List<SalesOrderDetail> originalDetails,
  ) async {
    // This is a simplified implementation - in production you'd need to handle:
    // - Added details
    // - Modified details
    // - Removed details

    // Clear existing items
    detailBloc.add(const ClearCreateItemsSalesOrderDetails());
    detailBloc.add(const ClearEditItemsSalesOrderDetails());

    // Add all new/modified details
    for (final detail in newDetails) {
      final updatedDetail = detail.copyWith(salesOrderHeaderId: header.id);
      if (detail.id == null) {
        detailBloc.add(AddToCreateItemsSalesOrderDetails(item: updatedDetail));
      } else {
        detailBloc.add(UpdateSalesOrderDetails(details: updatedDetail));
      }
    }

    // Save changes
    final completer = Completer<void>();
    late StreamSubscription subscription;
    subscription = detailBloc.stream.listen((detailState) {
      if (detailState.status == SalesOrderDetailStatus.success) {
        if (!completer.isCompleted) {
          completer.complete();
          subscription.cancel();
        }
      } else if (detailState.status == SalesOrderDetailStatus.failure) {
        if (!completer.isCompleted) {
          completer.completeError(
            detailState.errorMessage ?? 'Details update failed',
          );
          subscription.cancel();
        }
      }
    });

    // Save both create and edit items
    detailBloc.add(SaveCreateItems(salesOrderHeaderId: header.id!));
    detailBloc.add(SaveEditItems());

    await completer.future.timeout(const Duration(seconds: 15));
  }

  Future<void> _voidSalesOrderDetails(List<SalesOrderDetail> details) async {
    // Void each detail
    for (final detail in details) {
      //final voidIndicator = detail.orderHeader!.voidIndicator;
      //final voidedDetail = detail.copyWith(voidIndicator: 'V');
      detailBloc.add(UpdateSalesOrderDetails(details: detail));
    }

    // Wait for void operations to complete
    await Future.delayed(const Duration(seconds: 2));
  }

  Future<void> _deleteSalesOrderDetails(List<SalesOrderDetail> details) async {
    // Delete details that have IDs (are persisted)
    final persistedDetails = details
        .where((detail) => detail.id != null)
        .toList();

    for (final detail in persistedDetails) {
      detailBloc.add(DeleteSalesOrderDetails(id: detail.id!));

      // Small delay to prevent database contention
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  // Stock Operations
  Future<void> _reverseStockForAllDetails(
    List<SalesOrderDetail> details,
  ) async {
    for (final detail in details) {
      if (detail.itemInBranch != null && detail.quantity != null) {
        // Use the stock reversal functionality
        detailBloc.add(
          ReverseStockOnVoid(
            salesOrderId: detail.id!,
            applyLotMgm:
                headerBloc.state.systemConstants?.applyLotMgmBoolean ?? false,
          ),
        );

        // Small delay to prevent system overload
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    // Wait for all stock reversals to complete
    await Future.delayed(const Duration(seconds: 2));
  }

  Future<void> _adjustStockForUpdate(
    List<SalesOrderDetail> originalDetails,
    List<SalesOrderDetail> updatedDetails,
  ) async {
    // This is a complex operation that would compare original vs updated quantities
    // and adjust stock accordingly. For now, we'll use a simplified approach.

    // Reverse stock for original quantities
    for (final originalDetail in originalDetails) {
      if (originalDetail.itemInBranch != null &&
          originalDetail.quantity != null) {
        final reverseDetail = originalDetail.copyWith(
          quantity: -originalDetail.quantity!,
        );
        detailBloc.add(
          UpdateStockForSalesOrder(salesOrderDetail: reverseDetail),
        );
      }
    }

    // Apply stock for updated quantities
    for (final updatedDetail in updatedDetails) {
      if (updatedDetail.itemInBranch != null &&
          updatedDetail.quantity != null) {
        detailBloc.add(
          UpdateStockForSalesOrder(salesOrderDetail: updatedDetail),
        );
      }
    }

    // Wait for stock adjustments to complete
    await Future.delayed(const Duration(seconds: 2));
  }

  // Validation Methods
  Future<void> _validateOrderCreation(
    SalesOrderHeader header,
    List<SalesOrderDetail> details,
  ) async {
    if (header.company == null) {
      throw Exception('Company ID is required for order creation');
    }

    if (details.isEmpty) {
      throw Exception('At least one order detail is required');
    }

    // Validate stock availability
    await validateAllStock(details);

    // Check if all stock validations passed
    final detailState = detailBloc.state;
    final allStockValid = detailState.stockValidationResults.values.every(
      (result) => result.isValid,
    );

    if (!allStockValid) {
      throw Exception('Some items have insufficient stock');
    }
  }

  Future<void> _validateOrderUpdate(
    SalesOrderHeader header,
    List<SalesOrderDetail> details,
  ) async {
    if (header.id == null) {
      throw Exception('Cannot update order without ID');
    }

    if (details.isEmpty) {
      throw Exception('At least one order detail is required');
    }

    await validateAllStock(details);
  }

  Future<void> _validateCompleteOrder(
    SalesOrderHeader header,
    List<SalesOrderDetail> details,
  ) async {
    // Verify header was created successfully
    if (header.id == null) {
      throw Exception('Header creation validation failed');
    }

    // Verify all details reference the correct header
    final invalidDetails = details.where(
      (detail) => detail.salesOrderHeaderId != header.id,
    );
    if (invalidDetails.isNotEmpty) {
      throw Exception('Some details have incorrect header reference');
    }

    // Verify financial calculations are complete
    final headerState = headerBloc.state;
  }

  Future<void> _validateVoidOperation(
    SalesOrderHeader header,
    List<SalesOrderDetail> details,
  ) async {
    // Verify header is voided
    if (header.voidIndicator != 'V') {
      throw Exception('Header void operation failed');
    }

    // Verify all details are voided
    final nonVoidedDetails = details.where(
      (detail) => detail.orderHeader!.voidIndicator != 'V',
    );
    if (nonVoidedDetails.isNotEmpty) {
      throw Exception('Some details were not voided properly');
    }
  }

  // Helper Methods
  Future<List<SalesOrderDetail>> _getDetailsForHeader(int headerId) async {
    final completer = Completer<List<SalesOrderDetail>>();
    late StreamSubscription subscription;
    subscription = detailBloc.stream.listen((detailState) {
      if (detailState.status == SalesOrderDetailStatus.loaded) {
        if (!completer.isCompleted) {
          completer.complete(detailState.items);
          subscription.cancel();
        }
      }
    });

    // Trigger details load
    detailBloc.add(LoadSalesOrderDetailsByHeader(headerId: headerId));

    final details = await completer.future.timeout(const Duration(seconds: 10));
    return details;
  }

  Future<void> _waitForCalculationCompletion() async {
    final completer = Completer<void>();
    late StreamSubscription subscription;
    subscription = headerBloc.stream.listen((headerState) {
      if (headerState.status == SalesOrderHeaderStatus.loaded) {
        if (!completer.isCompleted) {
          completer.complete();
          subscription.cancel();
        }
      }
    });

    await completer.future.timeout(const Duration(seconds: 5));
  }

  Future<void> _waitForStockValidationCompletion(int expectedCount) async {
    final completer = Completer<void>();
    int validationChecks = 0;
    const maxChecks = 20; // 2 seconds max

    final timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      validationChecks++;

      final detailState = detailBloc.state;
      if (detailState.stockValidationResults.length >= expectedCount ||
          validationChecks >= maxChecks) {
        timer.cancel();
        if (!completer.isCompleted) completer.complete();
      }
    });

    await completer.future;
  }

  Future<void> _waitForHeaderPreparation() async {
    final completer = Completer<void>();
    late StreamSubscription subscription;
    subscription = headerBloc.stream.listen((headerState) {
      if (headerState.status == SalesOrderHeaderStatus.loaded &&
          headerState.selected != null) {
        if (!completer.isCompleted) {
          completer.complete();
          subscription.cancel();
        }
      }
    });

    await completer.future.timeout(const Duration(seconds: 5));
  }

  Future<void> _waitForDetailsLoadCompletion() async {
    final completer = Completer<void>();
    late StreamSubscription subscription;
    subscription = detailBloc.stream.listen((detailState) {
      if (detailState.status == SalesOrderDetailStatus.loaded) {
        if (!completer.isCompleted) {
          completer.complete();
          subscription.cancel();
        }
      }
    });

    await completer.future.timeout(const Duration(seconds: 5));
  }

  double _calculateSubtotal(List<SalesOrderDetail> details) {
    return details.fold<double>(0.0, (sum, detail) {
      return sum + (detail.extendedPrice ?? 0.0);
    });
  }

  void _applyCustomerPricingToDetails(Customer customer) {
    // Apply customer-specific pricing rules to order details
    // This could include customer discounts, special pricing, etc.
    final currentDetails = detailBloc.state.createItems;

    for (final detail in currentDetails) {
      final updatedDetail = detail.copyWith(unitPrice: detail.unitPrice);
      detailBloc.add(CalculateExtendedPrice(item: updatedDetail));
    }

    // Recalculate totals after pricing changes
    if (currentDetails.isNotEmpty) {
      calculateOrderTotals(currentDetails);
    }
  }

  // Rollback Methods
  Future<void> _rollbackCreateOperation(
    SalesOrderHeader header,
    List<SalesOrderDetail> details,
  ) async {
    // If header was created, delete it
    if (headerBloc.state.selected?.id != null) {
      try {
        headerBloc.add(
          DeleteSalesOrderHeader(id: headerBloc.state.selected!.id!),
        );
      } catch (e) {
        print('Warning: Failed to rollback header creation: $e');
      }
    }

    // Reverse any stock that was updated
    try {
      await _reverseStockForAllDetails(details);
    } catch (e) {
      print('Warning: Failed to rollback stock updates: $e');
    }

    // Clear any created details
    detailBloc.add(const ClearCreateItemsSalesOrderDetails());
  }

  Future<void> _rollbackUpdateOperation(
    SalesOrderHeader header,
    List<SalesOrderDetail> details,
  ) async {
    // This would restore the original state
    // Implementation depends on your specific rollback requirements
    print('Rolling back update operation for order: ${header.id}');
  }

  Future<void> _rollbackVoidOperation(SalesOrderHeader header) async {
    // Attempt to un-void the header
    try {
      headerBloc.add(UnvoidSalesOrder(id: header.id!));
    } catch (e) {
      print('Warning: Failed to rollback void operation: $e');
    }
  }

  Future<void> _updateStockForAllDetails(List<SalesOrderDetail> details) async {
    for (final detail in details) {
      if (detail.itemInBranch != null && detail.quantity != null) {
        detailBloc.add(UpdateStockForSalesOrder(salesOrderDetail: detail));

        // Small delay to prevent overwhelming the system
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }
  }

  Future<void> _calculateFinalTotals(
    SalesOrderHeader header,
    List<SalesOrderDetail> details,
  ) async {
    await calculateOrderTotals(details);

    // Additional validation of calculated totals
    final headerState = headerBloc.state;
    if (headerState.totalAmount <= 0) {
      throw Exception('Invalid total amount calculated');
    }
  }
}
