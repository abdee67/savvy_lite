import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:savvy_stock/features/sales/sales_order/integration/service/sales_order_integration_service.dart';
import 'package:savvy_stock/features/sales/sales_order/header/bloc/sales_order_header_bloc.dart';
import 'package:savvy_stock/features/sales/sales_order/header/bloc/sales_order_header_event.dart';
import 'package:savvy_stock/features/sales/sales_order/header/bloc/sales_order_header_state.dart';
import 'package:savvy_stock/features/sales/sales_order/header/model/sales_order_header.dart';
import 'package:savvy_stock/features/sales/sales_order/detail/bloc/sales_order_detail_bloc.dart';
import 'package:savvy_stock/features/sales/sales_order/detail/bloc/sales_order_detail_event.dart';
import 'package:savvy_stock/features/sales/sales_order/detail/bloc/sales_order_detail_state.dart';
import 'package:savvy_stock/features/sales/sales_order/detail/model/sales_order_detail.dart';
import 'sales_order_coordinator_event.dart';
import 'sales_order_coordinator_state.dart';

class SalesOrderCoordinatorBloc
    extends Bloc<SalesOrderCoordinatorEvent, SalesOrderCoordinatorState> {
  final SalesOrderHeaderBloc headerBloc;
  final SalesOrderDetailBloc detailBloc;
  final SalesOrderIntegrationService integrationService;

  StreamSubscription? _headerSubscription;
  StreamSubscription? _detailSubscription;

  SalesOrderCoordinatorBloc({
    required this.headerBloc,
    required this.detailBloc,
  }) : integrationService = SalesOrderIntegrationService(
         headerBloc: headerBloc,
         detailBloc: detailBloc,
       ),
       super(const SalesOrderCoordinatorState()) {
    // Listen to both blocs for state synchronization
    _headerSubscription = headerBloc.stream.listen(_onHeaderStateChanged);
    _detailSubscription = detailBloc.stream.listen(_onDetailStateChanged);

    // Event handlers
    on<CreateCompleteSalesOrder>(_onCreateCompleteSalesOrder);
    on<UpdateSalesOrderWithDetails>(_onUpdateSalesOrderWithDetails);
    on<VoidSalesOrderWithDetails>(_onVoidSalesOrderWithDetails);
    on<CalculateCompleteTotals>(_onCalculateCompleteTotals);
    on<SyncCustomerToDetails>(_onSyncCustomerToDetails);
    on<SyncHeaderToDetails>(_onSyncHeaderToDetails);
    on<PrepareNewOrder>(_onPrepareNewOrder);
    on<UpdateUnitPriceFromItemBranch>(_onUpdateUnitPriceFromItemBranch);
    on<UpdateHeaderFinancials>(_onUpdateHeaderFinancials);
    on<UpdateDetails>(_onUpdateDetails);
    on<HeaderSelectionChanged>(_onHeaderSelectionChanged);
    on<DetailsChanged>(_onDetailsChanged);
    on<ReverseStockOnVoidIntegration>(_onReverseStockOnVoidIntegration);
  }

  Future<void> _onCreateCompleteSalesOrder(
    CreateCompleteSalesOrder event,
    Emitter<SalesOrderCoordinatorState> emit,
  ) async {
    emit(state.copyWith(status: SalesOrderCoordinatorStatus.creatingHeader));

    try {
      await integrationService.createSalesOrderWithDetails(
        header: event.header,
        details: event.details,
      );

      emit(
        state.copyWith(
          status: SalesOrderCoordinatorStatus.success,
          lastOperation: 'Sales order created successfully',
          currentHeader: event.header,
          currentDetails: event.details,
          isOrderComplete: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: SalesOrderCoordinatorStatus.error,
          error: 'Failed to create sales order: $e',
        ),
      );
    }
  }

  Future<void> _onUpdateSalesOrderWithDetails(
    UpdateSalesOrderWithDetails event,
    Emitter<SalesOrderCoordinatorState> emit,
  ) async {
    emit(state.copyWith(status: SalesOrderCoordinatorStatus.processing));

    try {
      // 1. Update the header
      headerBloc.add(UpdateSalesOrderHeader(header: event.header));

      // 2. Update details
      final currentDetails = detailBloc.state.createItems;
      final detailsToUpdate = event.details.map((detail) {
        // Ensure details reference the correct header
        return detail.copyWith(salesOrderHeaderId: event.header.id);
      }).toList();

      // 3. Clear existing details and add updated ones
      detailBloc.add(ClearCreateItemsSalesOrderDetails());
      for (final detail in detailsToUpdate) {
        detailBloc.add(AddToCreateItemsSalesOrderDetails(item: detail));
      }

      // 4. Save all details
      detailBloc.add(SaveCreateItems(salesOrderHeaderId: event.header.id!));

      // 5. Recalculate totals with updated data
      integrationService.calculateOrderTotals(detailsToUpdate);

      emit(
        state.copyWith(
          status: SalesOrderCoordinatorStatus.success,
          lastOperation: 'Sales order updated successfully',
          currentHeader: event.header,
          lastDetails: detailsToUpdate,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: SalesOrderCoordinatorStatus.error,
          error: 'Failed to update sales order: $e',
        ),
      );
    }
  }

  Future<void> _onVoidSalesOrderWithDetails(
    VoidSalesOrderWithDetails event,
    Emitter<SalesOrderCoordinatorState> emit,
  ) async {
    emit(state.copyWith(status: SalesOrderCoordinatorStatus.voiding));

    try {
      await integrationService.voidSalesOrder(event.header);

      emit(
        state.copyWith(
          status: SalesOrderCoordinatorStatus.success,
          lastOperation: 'Sales order voided successfully',
          currentHeader: null,
          currentDetails: const [],
          isOrderComplete: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: SalesOrderCoordinatorStatus.error,
          error: 'Failed to void sales order: $e',
        ),
      );
    }
  }

  void _onCalculateCompleteTotals(
    CalculateCompleteTotals event,
    Emitter<SalesOrderCoordinatorState> emit,
  ) {
    try {
      final currentDetails = detailBloc.state.createItems;
      final currentHeader = headerBloc.state.selected;

      if (currentHeader != null && currentDetails.isNotEmpty) {
        integrationService.calculateOrderTotals(currentDetails);

        emit(
          state.copyWith(
            status: SalesOrderCoordinatorStatus.success,
            lastOperation: 'Totals calculated successfully',
            lastCalculation: DateTime.now(),
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: SalesOrderCoordinatorStatus.error,
            error: 'No header or details available for calculation',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: SalesOrderCoordinatorStatus.error,
          error: 'Failed to calculate totals: $e',
        ),
      );
    }
  }

  void _onSyncCustomerToDetails(
    SyncCustomerToDetails event,
    Emitter<SalesOrderCoordinatorState> emit,
  ) {
    emit(state.copyWith(isUpdatingCustomer: true));

    integrationService.updateCustomerInfo(event.customer);

    emit(
      state.copyWith(
        currentCustomer: event.customer,
        lastSyncTime: DateTime.now(),
        isUpdatingCustomer: false,
      ),
    );
  }

  void _onSyncHeaderToDetails(
    SyncHeaderToDetails event,
    Emitter<SalesOrderCoordinatorState> emit,
  ) {
    try {
      final currentHeader = headerBloc.state.selected;
      final currentDetails = detailBloc.state.createItems;

      if (currentHeader != null && currentDetails.isNotEmpty) {
        // Sync header changes to details
        final updatedDetails = currentDetails.map((detail) {
          return detail.copyWith(
            // Sync any header fields that should propagate to details
            salesOrderHeaderId: currentHeader.id,
            // Add other fields that need synchronization
          );
        }).toList();

        // Update details with synced data
        detailBloc.add(ClearCreateItemsSalesOrderDetails());
        for (final detail in updatedDetails) {
          detailBloc.add(AddToCreateItemsSalesOrderDetails(item: detail));
        }

        emit(
          state.copyWith(
            lastOperation: 'Header data synced to details',
            lastSyncTime: DateTime.now(),
          ),
        );
      }
    } catch (e) {
      emit(state.copyWith(error: 'Failed to sync header to details: $e'));
    }
  }

  Future<void> _onPrepareNewOrder(
    PrepareNewOrder event,
    Emitter<SalesOrderCoordinatorState> emit,
  ) async {
    final companyId = headerBloc.state.companyId;
    final employeeId = headerBloc.state.selected?.employeesId;

    if (companyId != null && employeeId != null) {
      // Prepare header
      headerBloc.add(
        PrepareCreateSalesOrderHeader(
          companyId: companyId,
          employeeId: employeeId,
        ),
      );

      // Prepare details
      detailBloc.add(PrepareCreateSalesOrderDetails());

      emit(
        state.copyWith(
          currentHeader: null,
          currentDetails: const [],
          isOrderComplete: false,
          lastOperation: 'New order prepared',
        ),
      );
    }
  }

  void _onUpdateUnitPriceFromItemBranch(
    UpdateUnitPriceFromItemBranch event,
    Emitter<SalesOrderCoordinatorState> emit,
  ) {
    emit(state.copyWith(isUnitPriceUpdating: true));

    integrationService.updateUnitPriceFromItemBranch(
      event.itemBranch,
      event.detail,
    );

    emit(
      state.copyWith(isUnitPriceUpdating: false, lastSyncTime: DateTime.now()),
    );
  }

  void _onUpdateHeaderFinancials(
    UpdateHeaderFinancials event,
    Emitter<SalesOrderCoordinatorState> emit,
  ) {
    emit(
      state.copyWith(
        lastApplyWH: event.applyWH,
        lastDiscountAmount: event.discountAmount,
      ),
    );
  }

  void _onUpdateDetails(
    UpdateDetails event,
    Emitter<SalesOrderCoordinatorState> emit,
  ) {
    emit(
      state.copyWith(
        currentDetails: event.details,
        lastDetails: state.currentDetails,
      ),
    );
  }

  void _onHeaderSelectionChanged(
    HeaderSelectionChanged event,
    Emitter<SalesOrderCoordinatorState> emit,
  ) {
    emit(state.copyWith(currentHeader: event.selectedHeader));
  }

  void _onDetailsChanged(
    DetailsChanged event,
    Emitter<SalesOrderCoordinatorState> emit,
  ) {
    emit(state.copyWith(currentDetails: event.details));
  }

  Future<void> _onReverseStockOnVoidIntegration(
    ReverseStockOnVoidIntegration event,
    Emitter<SalesOrderCoordinatorState> emit,
  ) async {
    emit(state.copyWith(status: SalesOrderCoordinatorStatus.reversingStock));

    try {
      await integrationService.voidSalesOrderWithStockReversal(event.header);

      emit(
        state.copyWith(
          status: SalesOrderCoordinatorStatus.success,
          lastOperation: 'Stock reversed and sales order voided successfully',
          currentHeader: event.header.copyWith(voidIndicator: 'V'),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: SalesOrderCoordinatorStatus.error,
          error: 'Failed to reverse stock on void: $e',
        ),
      );
    }
  }

  void _onHeaderStateChanged(SalesOrderHeaderState headerState) {
    // Sync relevant header state to details
    if (headerState.selected != null &&
        headerState.selected != state.currentHeader) {
      add(HeaderSelectionChanged(selectedHeader: headerState.selected));
      add(const SyncHeaderToDetails());
    }

    // Recalculate totals when header financial settings change
    if (headerState.applyWH != state.lastApplyWH ||
        headerState.discountAmount != state.lastDiscountAmount) {
      add(
        UpdateHeaderFinancials(
          applyWH: headerState.applyWH,
          discountAmount: headerState.discountAmount ?? 0.0,
        ),
      );
      add(const CalculateCompleteTotals());
    }
  }

  void _onDetailStateChanged(SalesOrderDetailState detailState) {
    // Recalculate totals when details change
    if (detailState.createItems != state.lastDetails) {
      add(UpdateDetails(details: detailState.createItems));
      add(const CalculateCompleteTotals());
    }
    // Validate stock when details are modified
    if (detailState.createItems.isNotEmpty &&
        detailState.status == SalesOrderDetailStatus.loaded) {
      detailBloc.add(
        ValidateStockAvailability(
          salesOrderDetail: detailState.createItems.first,
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _headerSubscription?.cancel();
    _detailSubscription?.cancel();
    return super.close();
  }
}
