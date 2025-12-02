// features/sales/sales_order/coordinator/bloc/sales_order_coordinator_bloc.dart
import 'dart:async';
import 'dart:math';
import 'package:bloc/bloc.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/auth/blocs/auth_state.dart';
import 'package:savvy_stock/features/sales/sales_order/invoice/detail/bloc/invoice_detail.event.dart';
import 'package:savvy_stock/features/sales/sales_order/invoice/detail/bloc/invoice_detail_bloc.dart';
import 'package:savvy_stock/features/sales/sales_order/invoice/detail/model/invoice_detail_model.dart';
import 'package:savvy_stock/features/sales/sales_order/invoice/header/bloc/invoice_header_bloc.dart';
import 'package:savvy_stock/features/sales/sales_order/invoice/header/bloc/invoice_header_event.dart';
import 'package:savvy_stock/features/sales/sales_order/invoice/header/model/invoice_header_model.dart';
import 'package:savvy_stock/features/sales/sales_order/detail/model/sales_order_detail.dart';
import 'package:savvy_stock/features/sales/sales_order/integration/service/sales_order_integration_service.dart';
import 'package:savvy_stock/features/sales/sales_order/header/bloc/sales_order_header_bloc.dart';
import 'package:savvy_stock/features/sales/sales_order/header/bloc/sales_order_header_event.dart';
import 'package:savvy_stock/features/sales/sales_order/header/bloc/sales_order_header_state.dart';
import 'package:savvy_stock/features/sales/sales_order/detail/bloc/sales_order_detail_bloc.dart';
import 'package:savvy_stock/features/sales/sales_order/detail/bloc/sales_order_detail_event.dart';
import 'package:savvy_stock/features/sales/sales_order/detail/bloc/sales_order_detail_state.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_bloc.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_state.dart';
import 'package:savvy_stock/features/sales/quotation_order/repo/quotation_order_repo.dart';
import 'sales_order_coordinator_event.dart';
import 'sales_order_coordinator_state.dart';

class SalesOrderCoordinatorBloc
    extends Bloc<SalesOrderCoordinatorEvent, SalesOrderCoordinatorState> {
  final SalesOrderHeaderBloc headerBloc;
  final SalesOrderDetailBloc detailBloc;
  final SystemConstantBloc systemConstantBloc;
  final InvoiceHistoryHeaderBloc invoiceHeaderBloc;
  final InvoiceHistoryDetailBloc invoiceDetailBloc;
  final AuthBloc authBloc;
  final SalesOrderIntegrationService integrationService;

  StreamSubscription<SalesOrderHeaderState>? _headerSubscription;
  StreamSubscription<SalesOrderDetailState>? _detailSubscription;
  StreamSubscription? _headerEventSubscription;
  StreamSubscription? _detailEventSubscription;
  StreamSubscription<SystemConstantState>? _systemConstantSubscription;
  StreamSubscription<AuthState>? _authSubscription;

  SalesOrderCoordinatorBloc({
    required this.headerBloc,
    required this.detailBloc,
    required this.invoiceHeaderBloc,
    required this.invoiceDetailBloc,
    required this.systemConstantBloc,
    required this.authBloc,
  }) : integrationService = SalesOrderIntegrationService(
         headerBloc: headerBloc,
         detailBloc: detailBloc,
         authBloc: authBloc,
         invoiceHeaderBloc: invoiceHeaderBloc,
         invoiceDetailBloc: invoiceDetailBloc,
       ),
       super(const SalesOrderCoordinatorState()) {
    // Listen to state changes from both BLoCs
    _headerSubscription = headerBloc.stream.listen(_onHeaderStateChanged);
    _detailSubscription = detailBloc.stream.listen(_onDetailStateChanged);
    _systemConstantSubscription = systemConstantBloc.stream.listen(
      _onSystemConstantsChanged,
    );

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

    // Financial Calculations & Payment
    on<CalculateCompleteOrderTotals>(_onCalculateCompleteOrderTotals);
    on<ValidateCompleteStockAvailability>(_onValidateCompleteStockAvailability);
    on<SyncFinancialData>(_onSyncFinancialData);
    on<UpdateTaxAndFees>(_onUpdateTaxAndFees);
    on<ProcessPayment>(_onProcessPayment);
    on<UpdatePaymentDetails>(_onUpdatePaymentDetails);
    on<LoadFeeSystemConstants>(_onLoadFeeSystemConstants);

    // Synchronization
    on<SyncCustomerToOrder>(_onSyncCustomerToOrder);
    on<SyncHeaderToDetails>(_onSyncHeaderToDetails);

    // Preparation & Initialization
    on<PrepareNewSalesOrder>(_onPrepareNewSalesOrder);
    on<LoadCompleteSalesOrder>(_onLoadCompleteSalesOrder);
    on<InitializeFromQuotation>(_onInitializeFromQuotation);

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

    // Invoice Generation
    on<GenerateInvoiceFromSalesOrder>(_onGenerateInvoiceFromSalesOrder);
  }

  // 🎯 ORDER LIFECYCLE HANDLERS

  Future<void> _onCreateCompleteSalesOrder(
    CreateCompleteSalesOrder event,
    Emitter<SalesOrderCoordinatorState> emit,
  ) async {
    emit(state.loadingState('create_order'));

    try {
      // 1. Prepare the header with latest data from state
      var headerToCreate = event.header;

      // Populate financial data
      headerToCreate = headerToCreate.copyWith(
        amountTotal: state.lastTotalAmount,
        amountOpen: state.lastAmountOpen,
        tax: state.lastTax,
        withholdAmount: state.lastWithholdAmount,
        discountAmount: state.lastDiscountAmount,
        // Ensure defaults if null
        discount: headerToCreate.discount ?? '0',
        addOn: headerToCreate.addOn ?? '0',
        // Populate payment data
        paymentMethod: state.paymentMethod,
        paymentInstrument: state.paymentInstrument,
        withHoldApply: 'Y',
        paymentTerm: int.tryParse(state.paymentTerm) ?? 0,
        requiredDate: headerToCreate.requiredDate ?? DateTime.now(),
        shippedDate: headerToCreate.shippedDate ?? DateTime.now(),
        salesType: headerToCreate.salesType ?? 'Unknown',
      );

      // Handle payment term if it's a date string (for Credit)
      if (state.paymentMethod == 'Credit' && state.paymentTerm.isNotEmpty) {
        try {
          final creditDate = DateTime.parse(state.paymentTerm);
          headerToCreate = headerToCreate.copyWith(creditDateToPay: creditDate);
        } catch (e) {
          print('Error parsing credit date: $e');
        }
      }

      // Calculate total cost from details
      double totalCost = 0.0;
      for (final detail in event.details) {
        totalCost += (detail.amountCost ?? 0.0);
      }
      headerToCreate = headerToCreate.copyWith(amountCost: totalCost);

      await integrationService.createSalesOrderWithDetails(
        header: headerToCreate,
        details: event.details,
      );
      final currentHeader = headerBloc.state.selected;
      // Use the details that were used to create the order; detailBloc.createItems
      // may have been cleared by the save process.
      final currentDetails = event.details;

      // ✅ Update quotation status if this was converted from a quotation (Java style)
      // Check if referenceNote3 contains a quotation fs_number
      if (headerToCreate.proformaFlag != null &&
          headerToCreate.proformaFlag!.isNotEmpty &&
          currentHeader?.fsNumber != null) {
        try {
          final quotationFsNumber = headerToCreate.proformaReference!;
          final quotationRepo = QuotationOrderRepository();

          // Query quotation by fs_number (matching Java implementation)
          final quotationHeaders = await quotationRepo.getQuotationOrderHeaders(
            companyId: headerToCreate.company,
            fsNumber: quotationFsNumber,
          );

          // Update each matching quotation (usually just one)
          for (final quotationHeader in quotationHeaders) {
            final updatedQuotation = quotationHeader.copyWith(
              conversionStatus: 'Converted',
              referenceNote3:
                  currentHeader!.fsNumber, // Store sales order fs_number
              conversionDate: headerToCreate.orderDate ?? DateTime.now(),
            );
            await quotationRepo.updateQuotationOrderHeader(updatedQuotation);
            print(
              'DEBUG: Updated quotation ${quotationHeader.fsNumber} status to Converted, linked to sales order ${currentHeader.fsNumber}',
            );
          }
        } catch (e) {
          print('WARNING: Failed to update quotation status: $e');
          // Don't fail the entire operation if quotation update fails
        }
      }

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

      // Now that coordinator state has header and details, trigger invoice generation
      add(const GenerateInvoiceFromSalesOrder());
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
        invoiceHeader: event.invoiceHeader,
        invoiceDetails: event.invoiceDetails,
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
    final currentDetails =
        state.currentDetails; // Use coordinator state, not detail bloc
    final currentHeader = state.currentHeader;

    if (currentHeader == null || currentDetails.isEmpty) {
      emit(state.errorState('No header or details available for calculation'));
      return;
    }

    print('Coordinator: Calculating totals for ${currentDetails.length} items');

    emit(state.loadingState('calculate_totals'));

    try {
      // Use header bloc to calculate totals
      headerBloc.add(
        CalculateOrderTotals(
          header: currentHeader,
          orderDetails: currentDetails,
          applyWithholding: state.isWithholdingEnabled,
          discountAmount: state.lastDiscountAmount ?? 0.0,
        ),
      );
      // Mark calculation as requested; actual financial values will be
      // synchronized from the header bloc via _onHeaderStateChangedEvent.
      emit(
        state.copyWith(
          lastCalculationTime: DateTime.now(),
          isCalculationsComplete: true,
          pendingOperations: {...state.pendingOperations}
            ..remove('calculate_totals'),
        ),
      );

      print(
        'Coordinator: Totals calculation requested for ${currentDetails.length} items',
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

  Future<void> _onUpdateTaxAndFees(
    UpdateTaxAndFees event,
    Emitter<SalesOrderCoordinatorState> emit,
  ) async {
    try {
      print(
        'Coordinator: Updating tax and fees - Discount: ${event.discountAmount}, Withholding: ${event.isWithholdingEnabled}',
      );

      // Update withholding in header bloc
      headerBloc.add(
        ApplyWithholdingTax(applyWithholding: event.isWithholdingEnabled),
      );

      // Update discount in header bloc
      headerBloc.add(ApplyDiscount(discountAmount: event.discountAmount));

      // Check if withholding can be applied
      final canApplyWithholding =
          event.subtotal >= (state.withholdingInitial ?? 0.0);

      emit(
        state.copyWith(
          lastDiscountAmount: event.discountAmount,
          isWithholdingEnabled: event.isWithholdingEnabled,
          canApplyWithholding: canApplyWithholding,
          lastOperation: 'Tax and fees updated',
          lastSyncTime: DateTime.now(),
        ),
      );

      // Recalculate totals with new settings
      if (state.currentDetails.isNotEmpty) {
        add(const CalculateCompleteOrderTotals());
      }
    } catch (e) {
      emit(state.errorState('Failed to update tax and fees: $e'));
    }
  }

  Future<void> _onProcessPayment(
    ProcessPayment event,
    Emitter<SalesOrderCoordinatorState> emit,
  ) async {
    // Validate payment details
    if (!state.isValid) {
      emit(
        state.errorState(
          'Please complete all payment details before processing',
        ),
      );
      return;
    }

    emit(state.paymentProcessingState());

    try {
      // Simulate payment processing (2 seconds delay)
      await Future.delayed(const Duration(seconds: 2));

      final random = Random();
      if (random.nextDouble() > 0.2) {
        // Payment successful
        final transactionID = _generateTransactionID();

        // Create the complete sales order
        //  await _createCompleteSalesOrder(transactionID);

        // Finalize the sales order with invoice generation
        add(const GenerateInvoiceFromSalesOrder());

        print(
          'Coordinator: Payment successful - Transaction ID: $transactionID',
        );

        emit(
          state
              .successState('Payment processed successfully')
              .copyWith(
                transactionID: transactionID,
                isOrderComplete: true,
                lastOperation: 'Payment completed',
              ),
        );

        print(
          'Coordinator: Payment successful - Transaction ID: $transactionID',
        );
      } else {
        // Payment failed
        emit(state.errorState('Payment processing failed. Please try again.'));
      }
    } catch (e) {
      emit(state.errorState('Payment processing error: $e'));
    }
  }

  void _onUpdatePaymentDetails(
    UpdatePaymentDetails event,
    Emitter<SalesOrderCoordinatorState> emit,
  ) {
    print(
      'Coordinator: Updating payment details - Type: ${event.paymentMethod}, Instrument: ${event.paymentInstrument}',
    );

    emit(
      state.copyWith(
        paymentMethod: event.paymentMethod,
        paymentInstrument: event.paymentInstrument,
        paymentTerm: event.paymentTerm.toString(),
        lastOperation: 'Payment details updated',
        lastSyncTime: DateTime.now(),
      ),
    );

    // Update header with payment details if header exists
    if (state.currentHeader != null) {
      headerBloc.add(UpdatePaymentMethod(paymentMethod: event.paymentMethod));

      if (event.paymentTerm.toString().isNotEmpty) {
        headerBloc.add(
          SetPaymentTerm(paymentTermId: int.parse(event.paymentTerm)),
        );
      }
    }
  }

  Future<void> _onLoadFeeSystemConstants(
    LoadFeeSystemConstants event,
    Emitter<SalesOrderCoordinatorState> emit,
  ) async {
    try {
      final systemConstantsService = systemConstantBloc.systemConstantService;

      // Ensure system constants are loaded
      await systemConstantsService.ensureLoaded();

      final vatRate = systemConstantsService.vatRate;
      final withholdingRate = systemConstantsService.withholdingRate;
      final withholdingInitial = systemConstantsService.withholdingInitial;

      print(
        'Coordinator: Loaded system constants - VAT: $vatRate, Withholding Rate: $withholdingRate, Withholding Initial: $withholdingInitial',
      );

      emit(
        state.copyWith(
          vatRate: vatRate,
          withholdingRate: withholdingRate,
          withholdingInitial: withholdingInitial,
          lastOperation: 'System constants loaded',
        ),
      );

      // Recalculate with new rates if we have existing data
      /*  if (state.currentDetails.isNotEmpty) {
        add(const CalculateCompleteOrderTotals());
      }*/
    } catch (e) {
      emit(
        state.copyWith(
          error: 'Failed to load system constants: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _createCompleteSalesOrder(String transactionID) async {
    final currentHeader = state.currentHeader;
    final currentDetails = state.currentDetails;

    if (currentHeader == null || currentDetails.isEmpty) {
      throw Exception('Cannot create order: Missing header or details');
    }

    // Update header with payment details
    final updatedHeader = currentHeader.copyWith(
      paymentMethod: state.paymentMethod,
      paymentTerm: int.parse(state.paymentTerm),
      referenceNote1: transactionID,
      paymentStatus: state.paymentStatus,
    );

    // Create the complete order through integration service
    await integrationService.createSalesOrderWithDetails(
      header: updatedHeader,
      details: currentDetails,
    );
  }

  Future<void> _onValidateCompleteStockAvailability(
    ValidateCompleteStockAvailability event,
    Emitter<SalesOrderCoordinatorState> emit,
  ) async {
    final currentDetails = state.currentDetails; // Use coordinator state

    if (currentDetails.isEmpty) {
      print('Coordinator: No details available for stock validation');
      emit(state.copyWith(isStockValidated: true));
      return;
    }

    print('Coordinator: Validating stock for ${currentDetails.length} items');

    try {
      await integrationService.validateAllStock(currentDetails);

      // Use a shorter delay
      await Future.delayed(const Duration(milliseconds: 500));

      final detailState = detailBloc.state;
      final allValid = detailState.stockValidationResults.values.every(
        (result) => result.quantityAvailable! >= 0,
      );

      emit(
        state.copyWith(
          isStockValidated: allValid,
          stockValidationResults: detailState.stockValidationResults,
          pendingOperations: {...state.pendingOperations}
            ..remove('validate_stock'),
        ),
      );

      print('Coordinator: Stock validation completed - All valid: $allValid');
    } catch (e) {
      print('Coordinator: Error validating stock - $e');
      emit(
        state.copyWith(
          pendingOperations: {...state.pendingOperations}
            ..remove('validate_stock'),
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

    if (detailBloc.state.createItems.isNotEmpty) {
      // Recalculate totals
      add(const CalculateCompleteOrderTotals());
    }
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
      // Prepare header and details (and optional default customer) via integration service
      await integrationService.prepareNewSalesOrder(
        companyId: event.companyId,
        employeeId: event.employeeId,
        branchId: event.branchId,
        defaultCustomer: event.defaultCustomer,
      );

      // Load fee-related system constants into coordinator state
      add(const LoadFeeSystemConstants());

      final preparedHeader = headerBloc.state.selected;
      final defaultCustomer = headerBloc.state.defaultCustomer;
      final paymentInstrument = state.paymentInstrument;

      emit(
        state
            .successState(
              'New sales order prepared',
              operation: 'prepare_new_order',
            )
            .copyWith(
              currentHeader: preparedHeader,
              currentDetails: const [],
              paymentMethod: 'Cash',
              paymentInstrument: paymentInstrument,
              isOrderComplete: false,
              isStockValidated: false,
              isCalculationsComplete: false,
              defaultCustomer: defaultCustomer,
            ),
      );

      print(
        'Coordinator: New order prepared - Header: ${preparedHeader?.id}, defaultCustomerCount=${defaultCustomer ?? 0}',
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
      await integrationService.loadCompleteSalesOrder(event.salesOrderId);
      emit(
        state
            .successState(
              'Sales order loaded successfully',
              operation: 'load_order',
            )
            .copyWith(
              currentHeader: header,
              currentDetails: detailBloc.state.items,
              lastSavedDetails: detailBloc.state.items,
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

  Future<void> _onInitializeFromQuotation(
    InitializeFromQuotation event,
    Emitter<SalesOrderCoordinatorState> emit,
  ) async {
    emit(state.loadingState('initialize_from_quotation'));

    try {
      // 1. Set Header in Header Bloc
      headerBloc.add(SelectSalesOrder(header: event.header));

      // 2. Set Details in Detail Bloc
      detailBloc.add(const ClearCreateItemsSalesOrderDetails());
      for (final detail in event.details) {
        detailBloc.add(AddToCreateItemsSalesOrderDetails(item: detail));
      }

      // 3. Load System Constants
      add(const LoadFeeSystemConstants());

      // 4. Update Coordinator State
      emit(
        state
            .successState(
              'Initialized from quotation',
              operation: 'initialize_from_quotation',
            )
            .copyWith(
              currentHeader: event.header,
              currentDetails: event.details,
              paymentMethod: event.header.paymentMethod ?? 'Cash',
              paymentInstrument: event.header.paymentInstrument ?? 0,
              isOrderComplete: false,
              isStockValidated: false,
              isCalculationsComplete: false,
              defaultCustomer: event.header.customerBillToRef,
            ),
      );

      // 5. Trigger Calculations
      // add(const CalculateCompleteOrderTotals());
    } catch (e) {
      emit(state.errorState('Failed to initialize from quotation: $e'));
    }
  }
  /* Future<void> _onLoadAllSalesOrders(
    LoadAllSalesOrders event,
    Emitter<SalesOrderCoordinatorState> emit,
  ) async {
    emit(state.loadingState('load_all_orders'));

    try {
      // Load all headers
      final allSalesOrders = await integrationService.loadAllSalesOrders();

      emit(
        state.successState(
          'All sales orders loaded successfully',
          operation: 'load_all_orders',
        ).copyWith(
          orders: allSalesOrders
          lastSyncTime: DateTime.now(),
          lastOperation: 'All sales orders loaded',
        ),
      );
    } catch (e) {
      emit(
        state.errorState(
          'Failed to load all sales orders: $e',
          operation: 'load_all_orders',
        ),
      );
    }
  }*/

  // 🎯 DETAIL MANAGEMENT HANDLERS

  void _onAddDetailToOrder(
    AddDetailToOrder event,
    Emitter<SalesOrderCoordinatorState> emit,
  ) {
    print('Coordinator: Adding detail to order - ${event.detail.tempId}');

    try {
      // Add to detail bloc first
      detailBloc.add(AddToCreateItemsSalesOrderDetails(item: event.detail));

      // Update coordinator state with the new detail
      final updatedDetails = [...state.currentDetails, event.detail];

      emit(
        state.copyWith(
          currentDetails: updatedDetails,
          isStockValidated: false,
          isCalculationsComplete: false,
          status: SalesOrderCoordinatorStatus.success,
          lastOperation: 'Item added to order',
        ),
      );

      print(
        'Coordinator: Detail added successfully. Total items: ${updatedDetails.length}',
      );

      // Schedule validation and calculation for later to avoid blocking
      Future.delayed(Duration.zero, () {
        if (!isClosed) {
          add(const ValidateCompleteStockAvailability());
          add(const CalculateCompleteOrderTotals());
        }
      });
    } catch (e) {
      print('Coordinator: Error adding detail - $e');
      emit(state.errorState('Failed to add item: $e', operation: 'add_detail'));
    }
  }

  void _onUpdateDetailInOrder(
    UpdateDetailInOrder event,
    Emitter<SalesOrderCoordinatorState> emit,
  ) {
    try {
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
          status: SalesOrderCoordinatorStatus.success,
          lastOperation: 'Item updated in order',
        ),
      );

      // Schedule validation and calculation
      Future.delayed(Duration.zero, () {
        if (!isClosed) {
          add(const ValidateCompleteStockAvailability());
          add(const CalculateCompleteOrderTotals());
        }
      });
    } catch (e) {
      emit(
        state.errorState(
          'Failed to update item: $e',
          operation: 'update_detail',
        ),
      );
    }
  }

  void _onRemoveDetailFromOrder(
    RemoveDetailFromOrder event,
    Emitter<SalesOrderCoordinatorState> emit,
  ) {
    try {
      detailBloc.add(
        RemoveFromCreateItemsSalesOrderDetails(item: event.detail),
      );

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
          status: SalesOrderCoordinatorStatus.success,
          lastOperation: 'Item removed from order',
        ),
      );

      if (updatedDetails.isNotEmpty) {
        // Schedule validation and calculation
        Future.delayed(Duration.zero, () {
          if (!isClosed) {
            add(const ValidateCompleteStockAvailability());
            add(const CalculateCompleteOrderTotals());
          }
        });
      }
    } catch (e) {
      emit(
        state.errorState(
          'Failed to remove item: $e',
          operation: 'remove_detail',
        ),
      );
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
    final previousHeader = state.currentHeader;

    // Always synchronize financial values from the header bloc state,
    // even when the selected header instance itself has not changed.
    emit(
      state.copyWith(
        currentHeader: event.selectedHeader ?? previousHeader,
        lastSubTotal: event.subTotal,
        lastTax: event.tax,
        lastWithholdAmount: event.withholdAmount,
        lastTotalAmount: event.totalAmount,
        lastDiscountAmount: event.discountAmount,
        lastAmountOpen: event.amountOpen,
      ),
    );

    // Only resync details when the header reference actually changes.
    if (event.selectedHeader != null &&
        event.selectedHeader != previousHeader &&
        state.currentDetails.isNotEmpty) {
      add(SyncHeaderToDetails(header: event.selectedHeader));
    }
  }

  void _onDetailStateChangedEvent(
    DetailStateChanged event,
    Emitter<SalesOrderCoordinatorState> emit,
  ) {
    // Prefer the in-progress createItems while editing; once they are saved
    // and cleared, fall back to the persisted items list.
    final sourceDetails = event.createItems.isNotEmpty
        ? event.createItems
        : event.currentDetails;

    if (sourceDetails.length != state.currentDetails.length ||
        !_areDetailsEqual(sourceDetails, state.currentDetails)) {
      emit(state.copyWith(currentDetails: sourceDetails));

      // Update stock validation status
      final allValid = event.stockValidationResults.values.every(
        (result) => result.quantityAvailable! >= 0,
      );

      if (state.isStockValidated != allValid) {
        emit(state.copyWith(isStockValidated: allValid));
      }
    }
  }

  // Helper method to check if detail lists are equal
  bool _areDetailsEqual(
    List<SalesOrderDetail> list1,
    List<SalesOrderDetail> list2,
  ) {
    if (list1.length != list2.length) return false;

    for (int i = 0; i < list1.length; i++) {
      if (list1[i].tempId != list2[i].tempId) return false;
    }

    return true;
  }
  // 🎯 UTILITY HANDLERS

  String _generateTransactionID() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    return 'TXN$timestamp${random.nextInt(1000)}';
  }

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
    if (!isClosed) {
      add(
        HeaderStateChanged(
          selectedHeader: headerState.selected,
          headers: headerState.headers,
          subTotal: headerState.subTotal,
          tax: headerState.tax,
          withholdAmount: headerState.withholdAmount,
          totalAmount: headerState.totalAmount,
          discountAmount: headerState.discountAmount,
          amountOpen: headerState.amountOpen,
        ),
      );
    }
  }

  void _onDetailStateChanged(SalesOrderDetailState detailState) {
    if (!isClosed) {
      add(
        DetailStateChanged(
          currentDetails: detailState.items,
          createItems: detailState.createItems,
          editItems: detailState.editItems,
          stockValidationResults: detailState.stockValidationResults,
        ),
      );

      // Update stock validation status without emitting new events
      if (detailState.stockValidationResults != state.stockValidationResults) {
        final allValid = detailState.stockValidationResults.values.every(
          (result) => result.quantityAvailable! >= 0,
        );

        // Use the current state to avoid race conditions
        final currentState = state;
        if (currentState.isStockValidated != allValid) {
          emit(
            currentState.copyWith(
              isStockValidated: allValid,
              stockValidationResults: detailState.stockValidationResults,
            ),
          );
        }
      }
    }
  }

  void _onSystemConstantsChanged(SystemConstantState systemState) {
    if (!isClosed && systemState.status == SystemConstantStatus.success) {
      // Reload system constants when they change
      add(const LoadFeeSystemConstants());
    }
  }

  @override
  Future<void> close() {
    _headerSubscription?.cancel();
    _detailSubscription?.cancel();
    _headerEventSubscription?.cancel();
    _detailEventSubscription?.cancel();
    _systemConstantSubscription?.cancel();
    return super.close();
  }
  // 🎯 INVOICE GENERATION HANDLERS

  Future<void> _onGenerateInvoiceFromSalesOrder(
    GenerateInvoiceFromSalesOrder event,
    Emitter<SalesOrderCoordinatorState> emit,
  ) async {
    final currentHeader = state.currentHeader;
    final currentDetails = state.currentDetails;

    emit(state.loadingState('generate_invoice'));

    try {
      if (currentHeader == null) {
        throw Exception(
          'Cannot generate invoice: sales order header is missing',
        );
      }

      if (currentDetails.isEmpty) {
        throw Exception('Cannot generate invoice: no sales order details');
      }

      // 🎯 Determine company ID safely for invoice
      final effectiveCompanyId =
          currentHeader.company ?? authBloc.state.companyId;
      if (effectiveCompanyId == null) {
        throw Exception('Cannot generate invoice: company ID is null');
      }

      // Generate next FS number for invoice
      final nextFsNumber = await _generateNextInvoiceFsNumber(
        effectiveCompanyId,
      );

      // Derive customer info safely
      final customerName =
          currentHeader.customerBillToRef?.customerName ??
          state.defaultCustomer?.contactName ??
          '';
      final tinNumber = state.defaultCustomer?.tinNumber ?? '';

      // Create invoice header from sales order header
      final invoiceHeader = InvoiceHistoryHeader(
        company: effectiveCompanyId,
        fsNumber: nextFsNumber,
        mrcNumber: currentHeader.fsNumber, // Link to sales order
        dateTransaction: DateTime.now(),
        customerName: customerName,
        tinNumber: tinNumber,
        city: state.defaultCustomer?.city ?? '',
        country: state.defaultCustomer?.country ?? '',
        region: state.defaultCustomer?.region ?? '',
        // salesPerson: currentDetails.first.,
        totalAmount: state.lastTotalAmount ?? 0.0,
        taxAmount: state.lastTax ?? 0.0,
        withholdAmount: state.lastWithholdAmount ?? 0.0,
        discountAmount: state.lastDiscountAmount ?? 0.0,
        amountBeforeTax: state.subtotal,
      );

      // Create invoice header
      invoiceHeaderBloc.add(CreateInvoiceHistoryHeader(header: invoiceHeader));

      // Wait for header creation
      await Future.delayed(const Duration(milliseconds: 500));

      // Get the created header ID
      final createdHeader = invoiceHeaderBloc.state.selected;
      if (createdHeader == null || createdHeader.id == null) {
        throw Exception('Failed to create invoice header');
      }

      // Create invoice details from sales order details
      final invoiceDetails = currentDetails.map((salesDetail) {
        return InvoiceHistoryDetail(
          invoiceHistory: createdHeader.id!,
          company: effectiveCompanyId,
          item: salesDetail.item?.itemDescription ?? 'Item',
          quantityTransaction: salesDetail.quantity ?? 0.0,
          amountUnitPrice: salesDetail.unitPrice ?? 0.0,
          amountExtendedPrice: salesDetail.extendedPrice ?? 0.0,
          unitOfMeasure: salesDetail.item?.unitOfMeasure ?? 'PCS',
        );
      }).toList();

      // Create all invoice details
      for (final detail in invoiceDetails) {
        invoiceDetailBloc.add(CreateInvoiceHistoryDetail(detail: detail));
      }

      emit(
        state
            .successState(
              'Invoice generated successfully',
              operation: 'generate_invoice',
            )
            .copyWith(
              invoiceGenerated: true,
              invoiceHeader: createdHeader,
              invoiceDetails: invoiceDetails,
              lastOperation: 'Invoice generated - $nextFsNumber',
            ),
      );

      print(
        'Coordinator: Invoice generated - FS Number: $nextFsNumber, Items: ${invoiceDetails.length}',
      );
    } catch (e) {
      emit(
        state.errorState(
          'Failed to generate invoice: $e',
          operation: 'generate_invoice',
        ),
      );
    }
  }

  Future<String> _generateNextInvoiceFsNumber(int companyId) async {
    try {
      // Use the invoice repository to generate next FS number
      final invoiceRepo = invoiceHeaderBloc.repository;
      return await invoiceRepo.generateNextFsNumber(companyId);
    } catch (e) {
      // Fallback: Generate based on timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return 'INV${timestamp.toString().substring(7)}';
    }
  }
}
