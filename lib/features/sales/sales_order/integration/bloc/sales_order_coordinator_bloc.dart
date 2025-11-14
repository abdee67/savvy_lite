// features/sales/sales_order/coordinator/bloc/sales_order_coordinator_bloc.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:savvy_stock/features/sales/sales_order/detail/model/sales_order_detail.dart';
import 'package:savvy_stock/features/sales/sales_order/integration/service/sales_order_integration_service.dart';
import 'package:savvy_stock/features/sales/sales_order/header/bloc/sales_order_header_bloc.dart';
import 'package:savvy_stock/features/sales/sales_order/header/bloc/sales_order_header_event.dart';
import 'package:savvy_stock/features/sales/sales_order/header/bloc/sales_order_header_state.dart';
import 'package:savvy_stock/features/sales/sales_order/detail/bloc/sales_order_detail_bloc.dart';
import 'package:savvy_stock/features/sales/sales_order/detail/bloc/sales_order_detail_event.dart';
import 'package:savvy_stock/features/sales/sales_order/detail/bloc/sales_order_detail_state.dart';
import 'sales_order_coordinator_event.dart';
import 'sales_order_coordinator_state.dart';

class SalesOrderCoordinatorBloc
    extends Bloc<SalesOrderCoordinatorEvent, SalesOrderCoordinatorState> {
  final SalesOrderHeaderBloc headerBloc;
  final SalesOrderDetailBloc detailBloc;
  final SalesOrderIntegrationService integrationService;

  StreamSubscription<SalesOrderHeaderState>? _headerSubscription;
  StreamSubscription<SalesOrderDetailState>? _detailSubscription;
  StreamSubscription? _headerEventSubscription;
  StreamSubscription? _detailEventSubscription;

  SalesOrderCoordinatorBloc({
    required this.headerBloc,
    required this.detailBloc,
  }) : integrationService = SalesOrderIntegrationService(
         headerBloc: headerBloc,
         detailBloc: detailBloc,
       ),
       super(const SalesOrderCoordinatorState()) {
    // Listen to state changes from both BLoCs
    _headerSubscription = headerBloc.stream.listen(_onHeaderStateChanged);
    _detailSubscription = detailBloc.stream.listen(_onDetailStateChanged);

    /* // You can also listen to events if needed for advanced coordination
    _headerEventSubscription = headerBloc.listen((event) {
      // Handle specific header events if needed
    });

    _detailEventSubscription = detailBloc.listen((event) {
      // Handle specific detail events if needed
    });*/

    // Register all event handlers
    _registerEventHandlers();
  }

  void _registerEventHandlers() {
    // Order Lifecycle
    on<CreateCompleteSalesOrder>(_onCreateCompleteSalesOrder);
    on<UpdateCompleteSalesOrder>(_onUpdateCompleteSalesOrder);
    on<VoidCompleteSalesOrder>(_onVoidCompleteSalesOrder);
    on<DeleteCompleteSalesOrder>(_onDeleteCompleteSalesOrder);

    // Calculations & Validation
    on<CalculateCompleteOrderTotals>(_onCalculateCompleteOrderTotals);
    on<ValidateCompleteStockAvailability>(_onValidateCompleteStockAvailability);
    on<SyncFinancialData>(_onSyncFinancialData);

    // Synchronization
    on<SyncCustomerToOrder>(_onSyncCustomerToOrder);
    on<SyncHeaderToDetails>(_onSyncHeaderToDetails);

    // Preparation & Initialization
    on<PrepareNewSalesOrder>(_onPrepareNewSalesOrder);
    on<LoadCompleteSalesOrder>(_onLoadCompleteSalesOrder);

    // Detail Management
    on<AddDetailToOrder>(_onAddDetailToOrder);
    on<UpdateDetailInOrder>(_onUpdateDetailInOrder);
    on<RemoveDetailFromOrder>(_onRemoveDetailFromOrder);
    on<ClearOrderDetails>(_onClearOrderDetails);

    // State Synchronization
    on<HeaderStateChanged>(_onHeaderStateChangedEvent);
    on<DetailStateChanged>(_onDetailStateChangedEvent);

    // Utility
    on<ResetCoordinatorState>(_onResetCoordinatorState);
    on<RetryFailedOperation>(_onRetryFailedOperation);
  }

  // 🎯 ORDER LIFECYCLE HANDLERS

  Future<void> _onCreateCompleteSalesOrder(
    CreateCompleteSalesOrder event,
    Emitter<SalesOrderCoordinatorState> emit,
  ) async {
    emit(state.loadingState('create_order'));

    try {
      await integrationService.createSalesOrderWithDetails(
        header: event.header,
        details: event.details,
      );

      final currentHeader = headerBloc.state.selected;
      final currentDetails = detailBloc.state.createItems;

      emit(
        state
            .successState(
              'Sales order created successfully',
              operation: 'create_order',
            )
            .copyWith(
              currentHeader: currentHeader,
              currentDetails: currentDetails,
              lastSavedDetails: currentDetails,
              isOrderComplete: true,
              isStockValidated: true,
              isCalculationsComplete: true,
              lastSyncTime: DateTime.now(),
            ),
      );
    } catch (e) {
      emit(
        state.errorState(
          'Failed to create sales order: $e',
          operation: 'create_order',
        ),
      );
    }
  }

  Future<void> _onUpdateCompleteSalesOrder(
    UpdateCompleteSalesOrder event,
    Emitter<SalesOrderCoordinatorState> emit,
  ) async {
    if (!state.canUpdateOrder) {
      emit(state.errorState('Cannot update order: No valid order selected'));
      return;
    }

    emit(state.loadingState('update_order'));

    try {
      await integrationService.updateSalesOrderWithDetails(
        header: event.header,
        details: event.details,
      );

      emit(
        state
            .successState(
              'Sales order updated successfully',
              operation: 'update_order',
            )
            .copyWith(
              currentHeader: event.header,
              currentDetails: event.details,
              lastSavedDetails: event.details,
              lastSyncTime: DateTime.now(),
            ),
      );
    } catch (e) {
      emit(
        state.errorState(
          'Failed to update sales order: $e',
          operation: 'update_order',
        ),
      );
    }
  }

  Future<void> _onVoidCompleteSalesOrder(
    VoidCompleteSalesOrder event,
    Emitter<SalesOrderCoordinatorState> emit,
  ) async {
    emit(state.loadingState('void_order'));

    try {
      final header = headerBloc.state.headers.firstWhere(
        (h) => h.id == event.salesOrderId,
        orElse: () => throw Exception('Sales order not found'),
      );

      await integrationService.voidSalesOrderWithStockReversal(header);

      emit(
        state
            .successState(
              'Sales order voided successfully',
              operation: 'void_order',
            )
            .copyWith(
              currentHeader: header.copyWith(voidIndicator: 'V'),
              isOrderComplete: false,
              lastSyncTime: DateTime.now(),
            ),
      );
    } catch (e) {
      emit(
        state.errorState(
          'Failed to void sales order: $e',
          operation: 'void_order',
        ),
      );
    }
  }

  Future<void> _onDeleteCompleteSalesOrder(
    DeleteCompleteSalesOrder event,
    Emitter<SalesOrderCoordinatorState> emit,
  ) async {
    emit(state.loadingState('delete_order'));

    try {
      // For deletion, we might want to reverse stock first
      if (event.reverseStock) {
        final header = headerBloc.state.headers.firstWhere(
          (h) => h.id == event.salesOrderId,
        );
        await integrationService.voidSalesOrderWithStockReversal(header);
      }

      // Delete the header (details should cascade or be deleted separately)
      headerBloc.add(DeleteSalesOrderHeader(id: event.salesOrderId));

      emit(
        state
            .successState(
              'Sales order deleted successfully',
              operation: 'delete_order',
            )
            .copyWith(
              currentHeader: null,
              currentDetails: const [],
              isOrderComplete: false,
            ),
      );
    } catch (e) {
      emit(
        state.errorState(
          'Failed to delete sales order: $e',
          operation: 'delete_order',
        ),
      );
    }
  }

  // 🎯 CALCULATION & VALIDATION HANDLERS

  Future<void> _onCalculateCompleteOrderTotals(
    CalculateCompleteOrderTotals event,
    Emitter<SalesOrderCoordinatorState> emit,
  ) async {
    final currentDetails = detailBloc.state.createItems;
    final currentHeader = headerBloc.state.selected;

    if (currentHeader == null || currentDetails.isEmpty) {
      emit(state.errorState('No header or details available for calculation'));
      return;
    }

    emit(state.loadingState('calculate_totals'));

    try {
      await integrationService.calculateOrderTotals(currentDetails);

      // Wait for header bloc to finish calculation
      await Future.delayed(const Duration(milliseconds: 500));

      final headerState = headerBloc.state;

      emit(
        state
            .successState(
              'Totals calculated successfully',
              operation: 'calculate_totals',
            )
            .copyWith(
              lastSubTotal: headerState.subTotal,
              lastTax: headerState.tax,
              lastWithholdAmount: headerState.withholdAmount,
              lastTotalAmount: headerState.totalAmount,
              lastCalculationTime: DateTime.now(),
              isCalculationsComplete: true,
            ),
      );
    } catch (e) {
      emit(
        state.errorState(
          'Failed to calculate totals: $e',
          operation: 'calculate_totals',
        ),
      );
    }
  }

  Future<void> _onValidateCompleteStockAvailability(
    ValidateCompleteStockAvailability event,
    Emitter<SalesOrderCoordinatorState> emit,
  ) async {
    final currentDetails = detailBloc.state.createItems;

    if (currentDetails.isEmpty) {
      emit(state.errorState('No details available for stock validation'));
      return;
    }

    emit(state.loadingState('validate_stock'));

    try {
      await integrationService.validateAllStock(currentDetails);

      // Wait for validation to complete
      await Future.delayed(const Duration(seconds: 2));

      final detailState = detailBloc.state;
      final allValid = detailState.stockValidationResults.values.every(
        (result) => result.isValid,
      );

      emit(
        state.copyWith(
          status: SalesOrderCoordinatorStatus.success,
          isStockValidated: allValid,
          stockValidationResults: detailState.stockValidationResults,
          pendingOperations: {...state.pendingOperations}
            ..remove('validate_stock'),
        ),
      );
    } catch (e) {
      emit(
        state.errorState(
          'Failed to validate stock: $e',
          operation: 'validate_stock',
        ),
      );
    }
  }

  void _onSyncFinancialData(
    SyncFinancialData event,
    Emitter<SalesOrderCoordinatorState> emit,
  ) {
    // Update header bloc with new financial settings
    if (event.applyWithholding != null) {
      headerBloc.add(
        ApplyWithholdingTax(applyWithholding: event.applyWithholding!),
      );
    }

    if (event.discountAmount != null) {
      headerBloc.add(ApplyDiscount(discountAmount: event.discountAmount!));
    }

    // Recalculate totals
    add(const CalculateCompleteOrderTotals());

    emit(
      state.copyWith(
        lastSyncTime: DateTime.now(),
        lastOperation: 'Financial data synced',
      ),
    );
  }

  // 🎯 SYNCHRONIZATION HANDLERS

  void _onSyncCustomerToOrder(
    SyncCustomerToOrder event,
    Emitter<SalesOrderCoordinatorState> emit,
  ) {
    integrationService.updateCustomerInfo(event.customer);

    emit(
      state.copyWith(
        lastSyncTime: DateTime.now(),
        lastOperation: 'Customer data synced to order',
      ),
    );
  }

  void _onSyncHeaderToDetails(
    SyncHeaderToDetails event,
    Emitter<SalesOrderCoordinatorState> emit,
  ) {
    final header = event.header ?? headerBloc.state.selected;

    if (header != null) {
      // Update all details with the current header ID
      final currentDetails = detailBloc.state.createItems;
      final updatedDetails = currentDetails.map((detail) {
        return detail.copyWith(salesOrderHeaderId: header.id);
      }).toList();

      // Update details in detail bloc
      detailBloc.add(const ClearCreateItemsSalesOrderDetails());
      for (final detail in updatedDetails) {
        detailBloc.add(AddToCreateItemsSalesOrderDetails(item: detail));
      }

      emit(
        state.copyWith(
          currentDetails: updatedDetails,
          lastSyncTime: DateTime.now(),
          lastOperation: 'Header data synced to details',
        ),
      );
    }
  }

  // 🎯 PREPARATION & INITIALIZATION HANDLERS

  Future<void> _onPrepareNewSalesOrder(
    PrepareNewSalesOrder event,
    Emitter<SalesOrderCoordinatorState> emit,
  ) async {
    emit(state.loadingState('prepare_new_order'));

    try {
      // Prepare header
      headerBloc.add(
        PrepareCreateSalesOrderHeader(
          companyId: event.companyId,
          employeeId: event.employeeId,
        ),
      );

      // Wait for header preparation
      await Future.delayed(const Duration(milliseconds: 300));

      // Prepare details
      detailBloc.add(PrepareCreateSalesOrderDetails());

      // Set default customer if provided
      if (event.defaultCustomer != null) {
        add(SyncCustomerToOrder(customer: event.defaultCustomer!));
      }

      emit(
        state
            .successState(
              'New sales order prepared',
              operation: 'prepare_new_order',
            )
            .copyWith(
              currentHeader: headerBloc.state.selected,
              currentDetails: const [],
              isOrderComplete: false,
              isStockValidated: false,
              isCalculationsComplete: false,
            ),
      );
    } catch (e) {
      emit(
        state.errorState(
          'Failed to prepare new sales order: $e',
          operation: 'prepare_new_order',
        ),
      );
    }
  }

  Future<void> _onLoadCompleteSalesOrder(
    LoadCompleteSalesOrder event,
    Emitter<SalesOrderCoordinatorState> emit,
  ) async {
    emit(state.loadingState('load_order'));

    try {
      // Load header
      final header = headerBloc.state.headers.firstWhere(
        (h) => h.id == event.salesOrderId,
        orElse: () => throw Exception('Sales order not found'),
      );

      headerBloc.add(SelectSalesOrder(header: header));

      // Load details
      detailBloc.add(
        LoadSalesOrderDetailsByHeader(headerId: event.salesOrderId),
      );

      // Wait for details to load
      await Future.delayed(const Duration(milliseconds: 500));

      final details = detailBloc.state.items;

      emit(
        state
            .successState(
              'Sales order loaded successfully',
              operation: 'load_order',
            )
            .copyWith(
              currentHeader: header,
              currentDetails: details,
              lastSavedDetails: details,
              isOrderComplete: true,
              isStockValidated: true, // Assuming loaded orders were validated
              isCalculationsComplete: true,
            ),
      );
    } catch (e) {
      emit(
        state.errorState(
          'Failed to load sales order: $e',
          operation: 'load_order',
        ),
      );
    }
  }

  // 🎯 DETAIL MANAGEMENT HANDLERS

  void _onAddDetailToOrder(
    AddDetailToOrder event,
    Emitter<SalesOrderCoordinatorState> emit,
  ) {
    detailBloc.add(AddToCreateItemsSalesOrderDetails(item: event.detail));

    final updatedDetails = [...state.currentDetails, event.detail];

    emit(
      state.copyWith(
        currentDetails: updatedDetails,
        isStockValidated: false, // Reset validation when details change
        isCalculationsComplete: false,
      ),
    );

    // Auto-validate stock and recalculate totals
    add(const ValidateCompleteStockAvailability());
    add(const CalculateCompleteOrderTotals());
  }

  void _onUpdateDetailInOrder(
    UpdateDetailInOrder event,
    Emitter<SalesOrderCoordinatorState> emit,
  ) {
    detailBloc.add(
      UpdateInCreateItemsSalesOrderDetails(
        item: event.detail,
        index: event.index,
      ),
    );

    final updatedDetails = List<SalesOrderDetail>.from(state.currentDetails);
    if (event.index < updatedDetails.length) {
      updatedDetails[event.index] = event.detail;
    }

    emit(
      state.copyWith(
        currentDetails: updatedDetails,
        isStockValidated: false,
        isCalculationsComplete: false,
      ),
    );

    add(const ValidateCompleteStockAvailability());
    add(const CalculateCompleteOrderTotals());
  }

  void _onRemoveDetailFromOrder(
    RemoveDetailFromOrder event,
    Emitter<SalesOrderCoordinatorState> emit,
  ) {
    detailBloc.add(RemoveFromCreateItemsSalesOrderDetails(item: event.detail));

    final updatedDetails = state.currentDetails
        .where(
          (detail) =>
              detail.tempId != event.detail.tempId &&
              detail.id != event.detail.id,
        )
        .toList();

    emit(
      state.copyWith(
        currentDetails: updatedDetails,
        isStockValidated: updatedDetails.isEmpty ? true : false,
      ),
    );

    if (updatedDetails.isNotEmpty) {
      add(const ValidateCompleteStockAvailability());
      add(const CalculateCompleteOrderTotals());
    }
  }

  void _onClearOrderDetails(
    ClearOrderDetails event,
    Emitter<SalesOrderCoordinatorState> emit,
  ) {
    detailBloc.add(const ClearCreateItemsSalesOrderDetails());

    emit(
      state.copyWith(
        currentDetails: const [],
        isStockValidated: true,
        isCalculationsComplete: false,
        stockValidationResults: const {},
      ),
    );
  }

  // 🎯 STATE SYNCHRONIZATION HANDLERS

  void _onHeaderStateChangedEvent(
    HeaderStateChanged event,
    Emitter<SalesOrderCoordinatorState> emit,
  ) {
    if (event.selectedHeader != state.currentHeader) {
      emit(state.copyWith(currentHeader: event.selectedHeader));

      // If header changed and we have details, sync them
      if (event.selectedHeader != null && state.currentDetails.isNotEmpty) {
        add(SyncHeaderToDetails(header: event.selectedHeader));
      }
    }
  }

  void _onDetailStateChangedEvent(
    DetailStateChanged event,
    Emitter<SalesOrderCoordinatorState> emit,
  ) {
    if (event.createItems != state.currentDetails) {
      emit(state.copyWith(currentDetails: event.createItems));
    }
  }

  // 🎯 UTILITY HANDLERS

  void _onResetCoordinatorState(
    ResetCoordinatorState event,
    Emitter<SalesOrderCoordinatorState> emit,
  ) {
    emit(const SalesOrderCoordinatorState());
  }

  void _onRetryFailedOperation(
    RetryFailedOperation event,
    Emitter<SalesOrderCoordinatorState> emit,
  ) {
    // Retry the failed event
    add(event.failedEvent);
  }

  // 🎯 STATE LISTENERS

  void _onHeaderStateChanged(SalesOrderHeaderState headerState) {
    // Propagate relevant header state changes to coordinator
    add(
      HeaderStateChanged(
        selectedHeader: headerState.selected,
        headers: headerState.headers,
      ),
    );

    // Auto-sync financial changes
    if (headerState.applyWH != state.lastWithholdAmount ||
        headerState.discountAmount != state.lastDiscountAmount) {
      add(
        SyncFinancialData(
          applyWithholding: headerState.applyWH,
          discountAmount: headerState.discountAmount,
        ),
      );
    }
  }

  void _onDetailStateChanged(SalesOrderDetailState detailState) {
    // Propagate relevant detail state changes to coordinator
    add(
      DetailStateChanged(
        currentDetails: detailState.items,
        createItems: detailState.createItems,
        editItems: detailState.editItems,
      ),
    );

    // Update stock validation status
    if (detailState.stockValidationResults != state.stockValidationResults) {
      final allValid = detailState.stockValidationResults.values.every(
        (result) => result.isValid,
      );

      emit(
        state.copyWith(
          isStockValidated: allValid,
          stockValidationResults: detailState.stockValidationResults,
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _headerSubscription?.cancel();
    _detailSubscription?.cancel();
    _headerEventSubscription?.cancel();
    _detailEventSubscription?.cancel();
    return super.close();
  }
}
