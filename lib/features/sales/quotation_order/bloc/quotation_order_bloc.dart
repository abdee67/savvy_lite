// features/sales/quotation_order/bloc/quotation_order_bloc.dart
import 'dart:async';
import 'dart:math';
import 'package:bloc/bloc.dart';
import 'package:savvy_stock/core/repositories/udc_repository.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/sales/customer/repo/customer_repo.dart';
import 'package:savvy_stock/features/sales/quotation_order/bloc/quotation_order_event.dart';
import 'package:savvy_stock/features/sales/quotation_order/bloc/quotation_order_state.dart';
import 'package:savvy_stock/features/sales/quotation_order/model/quotation_order_detail.dart';
import 'package:savvy_stock/features/sales/quotation_order/model/quotation_order_header.dart';
import 'package:savvy_stock/features/sales/quotation_order/repo/quotation_order_repo.dart';
import 'package:savvy_stock/features/stock/item_in_branch/repo/item_in_branch_repo.dart';
import 'package:savvy_stock/features/stock/item_uom_conversions/repo/item_uom_conv_repo.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_bloc.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_state.dart';
import 'package:savvy_stock/features/udc_detail/models/udc_details.dart';

class QuotationOrderBloc
    extends Bloc<QuotationOrderEvent, QuotationOrderState> {
  final QuotationOrderRepository repository;
  final AuthBloc authBloc;
  final SystemConstantBloc systemConstantBloc;
  final CustomerRepository customerRepository;
  final ItemUomConversionsRepository uomConversionsRepository;
  final StockItemInBranchRepository itemInBranchRepository;
  final UdcRepository udcRepository;

  StreamSubscription? _authSubscription;
  StreamSubscription? _systemConstantSubscription;

  QuotationOrderBloc({
    required this.repository,
    required this.authBloc,
    required this.systemConstantBloc,
    required this.customerRepository,
    required this.uomConversionsRepository,
    required this.itemInBranchRepository,
    required this.udcRepository,
  }) : super(const QuotationOrderState()) {
    _authSubscription = authBloc.stream.listen((authState) {
      if (authState.isAuthenticated &&
          authState.companyId != null &&
          authState.userId != null) {
        add(
          QuotationOrderInitialized(
            companyId: authState.companyId!,
            employeeId: authState.userId!.id,
          ),
        );
      }
    });

    _systemConstantSubscription = systemConstantBloc.stream.listen((
      systemState,
    ) {
      if (systemState.status == SystemConstantStatus.success &&
          systemState.systemConstants.isNotEmpty) {
        add(
          SystemConstantsUpdated(
            systemConstants: systemState.systemConstants.first,
          ),
        );
      }
    });

    // Event handlers - ADDING MISSING ONES
    on<QuotationOrderInitialized>(_onInitialized);
    on<SystemConstantsUpdated>(_onSystemConstantsUpdated);
    on<LoadQuotationOrders>(_onLoadQuotationOrders);
    on<CreateQuotationOrderHeader>(_onCreateQuotationOrderHeader);
    on<UpdateQuotationOrderHeader>(_onUpdateQuotationOrderHeader);
    on<DeleteQuotationOrderHeader>(_onDeleteQuotationOrderHeader);

    // ✅ ADDING MISSING BATCH OPERATIONS
    on<DeleteMultipleQuotationOrders>(_onDeleteMultipleQuotationOrders);
    on<SaveMultipleQuotationOrders>(_onSaveMultipleQuotationOrders);

    on<SelectQuotationOrder>(_onSelectQuotationOrder);
    on<SelectMultipleQuotationOrders>(_onSelectMultipleQuotationOrders);
    on<ClearSelection>(_onClearSelection);
    on<CancelQuotationOrder>(_onCancelQuotationOrder);
    on<PrepareCreateQuotationOrder>(_onPrepareCreate);
    on<PrepareEditQuotationOrder>(_onPrepareEdit);
    on<CancelUpdate>(_onCancelUpdate);
    on<CancelCreate>(_onCancelCreate);
    on<DiscardChanges>(_onDiscardChanges);

    // Detail events
    on<LoadQuotationOrderDetails>(_onLoadQuotationOrderDetails);
    on<AddQuotationOrderDetail>(_onAddQuotationOrderDetail);
    on<UpdateQuotationOrderDetail>(_onUpdateQuotationOrderDetail);
    on<RemoveQuotationOrderDetail>(_onRemoveQuotationOrderDetail);
    on<ClearQuotationOrderDetails>(_onClearQuotationOrderDetails);

    // ✅ ADDING MISSING DETAIL BATCH OPERATIONS
    on<DeleteQuotationOrderDetailBatch>(_onDeleteQuotationOrderDetailBatch);
    on<SaveQuotationDetailRow>(_onSaveQuotationDetailRow);

    // Financial events
    on<CalculateQuotationTotals>(_onCalculateQuotationTotals);
    on<UpdateCustomerInfo>(_onUpdateCustomerInfo);
    on<UpdateUnitPriceWithUom>(_onUpdateUnitPriceWithUom);
    on<CalculateExtendedPrice>(_onCalculateExtendedPrice);

    // ✅ ADDING MISSING FINANCIAL EVENTS
    on<ApplyWithholdingTax>(_onApplyWithholdingTax);
    on<ApplyDiscount>(_onApplyDiscount);
    on<UpdateTaxSettings>(_onUpdateTaxSettings);

    // Barcode events
    on<SetUseBarcode>(_onSetUseBarcode);
    on<SetBarcode>(_onSetBarcode);
    on<ScanBarcode>(_onScanBarcode);

    // Conversion events
    on<ConvertToSalesOrder>(_onConvertToSalesOrder);
    on<PrepareInvoiceReview>(_onPrepareInvoiceReview);

    // Filter events
    on<FilterQuotationOrders>(_onFilterQuotationOrders);
    on<ClearFilters>(_onClearFilters);

    // ✅ ADDING MISSING FILTER EVENTS
    on<SearchQuotationOrders>(_onSearchQuotationOrders);
    on<UpdateDateFilters>(_onUpdateDateFilters);

    // Batch operations
    on<SaveQuotationOrder>(_onSaveQuotationOrder);
    on<SaveQuotationDetails>(_onSaveQuotationDetails);

    // Utility events
    on<GetNextOrderNumber>(_onGetNextOrderNumber);
    on<GenerateNextFsNumber>(_onGenerateNextFsNumber);
    on<RefreshQuotationOrders>(_onRefreshQuotationOrders);

    // ✅ ADDING MISSING UTILITY EVENTS
    on<SetDefaultCustomer>(_onSetDefaultCustomer);
    on<ResetQuotationState>(_onResetQuotationState);
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    _systemConstantSubscription?.cancel();
    return super.close();
  }

  // ============ INITIALIZATION & SYSTEM CONSTANTS ============

  Future<void> _onInitialized(
    QuotationOrderInitialized event,
    Emitter<QuotationOrderState> emit,
  ) async {
    emit(
      state.copyWith(
        companyId: event.companyId,
        status: QuotationOrderStatus.loading,
      ),
    );

    // Ensure system constants are loaded
    await systemConstantBloc.systemConstantService.ensureLoaded();

    add(LoadQuotationOrders(companyId: event.companyId));
    add(GetNextOrderNumber(companyId: event.companyId));
  }

  Future<void> _onSystemConstantsUpdated(
    SystemConstantsUpdated event,
    Emitter<QuotationOrderState> emit,
  ) async {
    emit(state.copyWith(systemConstants: event.systemConstants));

    // Recalculate totals if we have existing data
    if (state.selectedHeader != null && state.createDetailItems.isNotEmpty) {
      add(
        CalculateQuotationTotals(
          header: state.selectedHeader!,
          details: state.createDetailItems,
          applyWithholding: state.applyWH,
          discountAmount: state.discountAmount,
        ),
      );
    }
  }

  // ============ HEADER CRUD OPERATIONS ============

  Future<void> _onLoadQuotationOrders(
    LoadQuotationOrders event,
    Emitter<QuotationOrderState> emit,
  ) async {
    emit(state.loadingState());

    try {
      final headers = await repository.getQuotationOrderHeaders(
        companyId: event.companyId,
        startDate: event.startDate ?? state.dateOrderStart,
        endDate: event.endDate ?? state.dateOrderEnd,
      );

      emit(
        state.copyWith(
          status: QuotationOrderStatus.loaded,
          headers: headers,
          filteredHeaders: headers,
          companyId: event.companyId,
          error: null,
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to load quotation orders: $e'));
    }
  }

  Future<void> _onCreateQuotationOrderHeader(
    CreateQuotationOrderHeader event,
    Emitter<QuotationOrderState> emit,
  ) async {
    emit(state.loadingState());

    try {
      // Get next order number
      final nextOrderNumber = await repository.getNextOrderNumber(
        event.header.company!,
      );

      // Process header with business logic
      final processedHeader = await _processHeaderBusinessLogic(
        event.header.copyWith(orderNumber: nextOrderNumber),
      );

      final id = await repository.createQuotationOrderHeader(processedHeader);
      final createdHeader = processedHeader.copyWith(id: id);

      // Update state
      final updatedHeaders = [createdHeader, ...state.headers];
      final updatedCreateItems = state.createItems
          .where((item) => item.tempId != createdHeader.tempId)
          .toList();

      emit(
        state.copyWith(
          status: QuotationOrderStatus.success,
          headers: updatedHeaders,
          filteredHeaders: updatedHeaders,
          createItems: updatedCreateItems,
          selectedHeader: createdHeader,
          nextOrderNumber: nextOrderNumber + 1,
          successMessage: 'Quotation order created successfully',
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to create quotation order: $e'));
    }
  }

  Future<QuotationOrderHeader> _processHeaderBusinessLogic(
    QuotationOrderHeader header,
  ) async {
    // Set default values from system constants
    var processedHeader = header.copyWith(
      tax: header.tax ?? 0.0,
      withholdAmount: header.withholdAmount ?? 0.0,
      discountAmount: header.discountAmount ?? 0.0,
      quotationValidationInDays: header.quotationValidationInDays ?? 30,
      currencyCode: header.currencyCode ?? 'ETB',
      exchangeRate: header.exchangeRate ?? 1.0,
      orderStatus: header.orderStatus ?? 'Draft',
    );

    return processedHeader;
  }

  Future<void> _onUpdateQuotationOrderHeader(
    UpdateQuotationOrderHeader event,
    Emitter<QuotationOrderState> emit,
  ) async {
    emit(state.loadingState());

    try {
      await repository.updateQuotationOrderHeader(event.header);

      // Update the header in the lists
      final updatedHeaders = state.headers
          .map((h) => h.id == event.header.id ? event.header : h)
          .toList();
      final updatedEditItems = state.editItems
          .where((item) => item.id != event.header.id)
          .toList();

      emit(
        state.copyWith(
          status: QuotationOrderStatus.success,
          headers: updatedHeaders,
          filteredHeaders: updatedHeaders,
          editItems: updatedEditItems,
          selectedHeader: event.header,
          successMessage: 'Quotation order updated successfully',
          error: null,
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to update quotation order: $e'));
    }
  }

  Future<void> _onDeleteQuotationOrderHeader(
    DeleteQuotationOrderHeader event,
    Emitter<QuotationOrderState> emit,
  ) async {
    emit(state.copyWith(status: QuotationOrderStatus.deleting));

    try {
      await repository.deleteQuotationOrderHeader(event.id);

      final updatedHeaders = state.headers
          .where((h) => h.id != event.id)
          .toList();
      final updatedFilteredHeaders = state.filteredHeaders
          .where((h) => h.id != event.id)
          .toList();

      emit(
        state.copyWith(
          status: QuotationOrderStatus.success,
          headers: updatedHeaders,
          filteredHeaders: updatedFilteredHeaders,
          selectedHeader: state.selectedHeader?.id == event.id
              ? null
              : state.selectedHeader,
          successMessage: 'Quotation order deleted successfully',
          error: null,
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to delete quotation order: $e'));
    }
  }

  // ✅ ADDING MISSING BATCH DELETE OPERATION
  Future<void> _onDeleteMultipleQuotationOrders(
    DeleteMultipleQuotationOrders event,
    Emitter<QuotationOrderState> emit,
  ) async {
    emit(state.copyWith(status: QuotationOrderStatus.deleting));

    try {
      for (final header in event.headers) {
        if (header.id != null) {
          await repository.deleteQuotationOrderHeader(header.id!);
        }
      }

      final idsToRemove = event.headers
          .map((h) => h.id)
          .whereType<int>()
          .toSet();
      final updatedHeaders = state.headers
          .where((h) => !idsToRemove.contains(h.id))
          .toList();
      final updatedFilteredHeaders = state.filteredHeaders
          .where((h) => !idsToRemove.contains(h.id))
          .toList();

      emit(
        state.copyWith(
          status: QuotationOrderStatus.success,
          headers: updatedHeaders,
          filteredHeaders: updatedFilteredHeaders,
          multiselectionItems: const [],
          successMessage:
              '${event.headers.length} quotation orders deleted successfully',
          error: null,
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to delete quotation orders: $e'));
    }
  }

  // ✅ ADDING MISSING BATCH SAVE OPERATION
  Future<void> _onSaveMultipleQuotationOrders(
    SaveMultipleQuotationOrders event,
    Emitter<QuotationOrderState> emit,
  ) async {
    emit(state.copyWith(status: QuotationOrderStatus.saving));

    try {
      for (final header in event.headers) {
        if (header.id == null) {
          await repository.createQuotationOrderHeader(header);
        } else {
          await repository.updateQuotationOrderHeader(header);
        }
      }

      emit(
        state.copyWith(
          status: QuotationOrderStatus.success,
          successMessage:
              '${event.headers.length} quotation orders saved successfully',
          editItems: const [],
        ),
      );

      add(RefreshQuotationOrders());
    } catch (e) {
      emit(state.errorState('Failed to save quotation orders: $e'));
    }
  }

  // ============ SELECTION MANAGEMENT ============

  void _onSelectQuotationOrder(
    SelectQuotationOrder event,
    Emitter<QuotationOrderState> emit,
  ) {
    emit(state.copyWith(selectedHeader: event.header, selected1: event.header));
  }

  // ✅ ADDING MISSING MULTI-SELECTION
  void _onSelectMultipleQuotationOrders(
    SelectMultipleQuotationOrders event,
    Emitter<QuotationOrderState> emit,
  ) {
    emit(
      state.copyWith(
        multiselectionItems: event.headers,
        //isSelectionMode: event.headers.isNotEmpty,
      ),
    );
  }

  void _onClearSelection(
    ClearSelection event,
    Emitter<QuotationOrderState> emit,
  ) {
    emit(
      state.copyWith(
        //selectedItems: const [],
        multiselectionItems: const [],
        //isSelectionMode: false,
      ),
    );
  }

  Future<void> _onCancelQuotationOrder(
    CancelQuotationOrder event,
    Emitter<QuotationOrderState> emit,
  ) async {
    emit(state.loadingState());

    try {
      final cancelledHeader = event.header.copyWith(
        conversionStatus: 'Cancelled',
        commentsReason: event.commentsReason,
      );

      await repository.updateQuotationOrderHeader(cancelledHeader);

      final updatedHeaders = state.headers
          .map((h) => h.id == event.header.id ? cancelledHeader : h)
          .toList();

      emit(
        state.copyWith(
          status: QuotationOrderStatus.success,
          headers: updatedHeaders,
          filteredHeaders: updatedHeaders,
          selectedHeader: cancelledHeader,
          successMessage: 'Quotation order cancelled successfully',
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to cancel quotation order: $e'));
    }
  }

  // ============ DETAIL OPERATIONS ============

  Future<void> _onLoadQuotationOrderDetails(
    LoadQuotationOrderDetails event,
    Emitter<QuotationOrderState> emit,
  ) async {
    emit(state.loadingState());

    try {
      final details = await repository.getQuotationOrderDetailsByHeaderId(
        event.headerId,
        event.companyId,
      );

      emit(
        state.copyWith(
          status: QuotationOrderStatus.loaded,
          details: details,
          createDetailItems: details, // Load into create items for editing
          error: null,
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to load quotation order details: $e'));
    }
  }

  void _onAddQuotationOrderDetail(
    AddQuotationOrderDetail event,
    Emitter<QuotationOrderState> emit,
  ) {
    final newDetail = event.detail.copyWith(
      tempId: _getNextTempId(state.createDetailItems),
    );

    final updatedDetails = [...state.createDetailItems, newDetail];

    emit(
      state.copyWith(
        createDetailItems: updatedDetails,
        selectedDetail: newDetail,
      ),
    );

    // Recalculate totals
    if (state.selectedHeader != null) {
      add(
        CalculateQuotationTotals(
          header: state.selectedHeader!,
          details: updatedDetails,
          applyWithholding: state.applyWH,
          discountAmount: state.discountAmount,
        ),
      );
    }
  }

  void _onUpdateQuotationOrderDetail(
    UpdateQuotationOrderDetail event,
    Emitter<QuotationOrderState> emit,
  ) {
    final updatedDetails = List<QuotationOrderDetail>.from(
      state.createDetailItems,
    );
    if (event.index < updatedDetails.length) {
      updatedDetails[event.index] = event.detail;
    }

    emit(state.copyWith(createDetailItems: updatedDetails));

    // Recalculate totals
    if (state.selectedHeader != null) {
      add(
        CalculateQuotationTotals(
          header: state.selectedHeader!,
          details: updatedDetails,
          applyWithholding: state.applyWH,
          discountAmount: state.discountAmount,
        ),
      );
    }
  }

  void _onRemoveQuotationOrderDetail(
    RemoveQuotationOrderDetail event,
    Emitter<QuotationOrderState> emit,
  ) {
    final updatedDetails = state.createDetailItems.where((detail) {
      if (detail.id == null) {
        return detail.tempId != event.detail.tempId;
      } else {
        return detail.id != event.detail.id;
      }
    }).toList();

    emit(state.copyWith(createDetailItems: updatedDetails));

    // Recalculate totals
    if (state.selectedHeader != null && updatedDetails.isNotEmpty) {
      add(
        CalculateQuotationTotals(
          header: state.selectedHeader!,
          details: updatedDetails,
          applyWithholding: state.applyWH,
          discountAmount: state.discountAmount,
        ),
      );
    }
  }

  // ✅ ADDING MISSING BATCH DETAIL DELETE
  Future<void> _onDeleteQuotationOrderDetailBatch(
    DeleteQuotationOrderDetailBatch event,
    Emitter<QuotationOrderState> emit,
  ) async {
    emit(state.copyWith(status: QuotationOrderStatus.deleting));

    try {
      await repository.deleteQuotationOrderDetailBatch(event.ids);

      final updatedDetails = state.createDetailItems
          .where((detail) => !event.ids.contains(detail.id))
          .toList();

      emit(
        state.copyWith(
          status: QuotationOrderStatus.success,
          createDetailItems: updatedDetails,
          successMessage:
              '${event.ids.length} quotation details deleted successfully',
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to delete quotation details: $e'));
    }
  }

  // ✅ ADDING MISSING ROW SAVE (Java saveRow equivalent)
  Future<void> _onSaveQuotationDetailRow(
    SaveQuotationDetailRow event,
    Emitter<QuotationOrderState> emit,
  ) async {
    emit(state.copyWith(status: QuotationOrderStatus.saving));

    try {
      for (final detail in state.editDetailItems) {
        if (detail.id == null) {
          await repository.createQuotationOrderDetail(detail);
        } else {
          await repository.updateQuotationOrderDetail(detail);
        }
      }

      emit(
        state.copyWith(
          status: QuotationOrderStatus.success,
          successMessage: 'Row saved successfully',
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to save row: $e'));
    }
  }

  void _onClearQuotationOrderDetails(
    ClearQuotationOrderDetails event,
    Emitter<QuotationOrderState> emit,
  ) {
    emit(
      state.copyWith(
        createDetailItems: const [],
        details: const [],
        subTotal: null,
        tax: null,
        withholdAmount: null,
        totalAmount: null,
      ),
    );
  }

  // ============ FINANCIAL CALCULATIONS ============

  Future<void> _onCalculateQuotationTotals(
    CalculateQuotationTotals event,
    Emitter<QuotationOrderState> emit,
  ) async {
    emit(state.calculatingState());

    try {
      final systemConstant = systemConstantBloc.state.selected;

      // Get decimal places from system constants
      final decimalPlaces = systemConstant?.decimalPlaces ?? 2;
      final vatRate = (systemConstant?.rateVatPercentage ?? 0.0) / 100.0;
      final withHoldRate =
          (systemConstant?.rateWithholdingPercentage ?? 0.0) / 100.0;
      final withHoldInitials = systemConstant?.withHoldInitials ?? 0.0;

      double subTotal = 0.0;
      double taxableAmount = 0.0;

      // Calculate subtotal and taxable amount
      for (final detail in event.details) {
        final extendedPrice = detail.extendedPrice ?? 0.0;
        subTotal += extendedPrice;

        // Check if item is taxable (like Java's item.getItemsTableId().getTaxableBoolean())
        if (detail.taxable == 'Y') {
          taxableAmount += extendedPrice;
        }
      }

      // Round subtotal
      final roundedSubTotal = _roundToDecimalPlaces(subTotal, decimalPlaces);

      // Calculate VAT
      final taxAmount = _roundToDecimalPlaces(
        taxableAmount * vatRate,
        decimalPlaces,
      );

      // Calculate withholding
      double withHoldAmount = 0.0;
      final applyWithholding = event.applyWithholding ?? state.applyWH ?? false;
      if (applyWithholding && roundedSubTotal >= withHoldInitials) {
        withHoldAmount = _roundToDecimalPlaces(
          roundedSubTotal * withHoldRate,
          decimalPlaces,
        );
      }

      // Ensure discount is not null
      final discountAmount =
          event.discountAmount ?? state.discountAmount ?? 0.0;

      // Compute total
      final totalAmount = _roundToDecimalPlaces(
        roundedSubTotal + taxAmount - withHoldAmount - discountAmount,
        decimalPlaces,
      );

      emit(
        state.copyWith(
          status: QuotationOrderStatus.loaded,
          subTotal: roundedSubTotal,
          tax: taxAmount,
          withholdAmount: withHoldAmount,
          totalAmount: totalAmount,
          discountAmount: discountAmount,
          applyWH: applyWithholding,
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to calculate totals: $e'));
    }
  }

  // ✅ ADDING MISSING FINANCIAL SETTINGS
  void _onApplyWithholdingTax(
    ApplyWithholdingTax event,
    Emitter<QuotationOrderState> emit,
  ) {
    emit(state.copyWith(applyWH: event.applyWithholding));

    // Recalculate totals if withholding tax changes
    if (state.selectedHeader != null && state.createDetailItems.isNotEmpty) {
      add(
        CalculateQuotationTotals(
          header: state.selectedHeader!,
          details: state.createDetailItems,
          applyWithholding: event.applyWithholding,
          discountAmount: state.discountAmount,
        ),
      );
    }
  }

  void _onApplyDiscount(
    ApplyDiscount event,
    Emitter<QuotationOrderState> emit,
  ) {
    emit(state.copyWith(discountAmount: event.discountAmount));

    // Recalculate totals if discount changes
    if (state.selectedHeader != null && state.createDetailItems.isNotEmpty) {
      add(
        CalculateQuotationTotals(
          header: state.selectedHeader!,
          details: state.createDetailItems,
          applyWithholding: state.applyWH ?? false,
          discountAmount: event.discountAmount,
        ),
      );
    }
  }

  void _onUpdateTaxSettings(
    UpdateTaxSettings event,
    Emitter<QuotationOrderState> emit,
  ) {
    // Recalculate totals when tax settings change
    if (state.createDetailItems.isNotEmpty) {
      add(
        CalculateQuotationTotals(
          header: state.selectedHeader!,
          details: state.createDetailItems,
          applyWithholding: event.applyWithholding,
          discountAmount: state.discountAmount,
        ),
      );
    }
  }

  // ============ CUSTOMER MANAGEMENT ============

  Future<void> _onUpdateCustomerInfo(
    UpdateCustomerInfo event,
    Emitter<QuotationOrderState> emit,
  ) async {
    try {
      final customer = event.customer;

      // Build phone numbers string (like Java)
      final phoneNumbers =
          customer.phoneNumber! +
          (customer.phone2 != null && customer.phone2!.isNotEmpty
              ? ', ${customer.phone2}'
              : '');

      // Update customer info in state
      final updatedState = state.updateCustomerInfo(
        tinNumber: customer.tinNumber,
        phoneNumbers: phoneNumbers,
        countryDesc: customer.country,
        stateDesc: customer.state,
        regionDesc: customer.region,
        cityDesc: customer.city,
      );

      // Update selected header with customer
      if (event.currentHeader != null) {
        final updatedHeader = event.currentHeader!.copyWith(
          customerTableId: customer.id!,
          customerBillTo: customer.id!,
        );

        emit(updatedState.copyWith(selectedHeader: updatedHeader));
      } else {
        emit(updatedState);
      }
    } catch (e) {
      emit(state.errorState('Failed to update customer info: $e'));
    }
  }

  // ✅ ADDING MISSING DEFAULT CUSTOMER SETTING
  Future<void> _onSetDefaultCustomer(
    SetDefaultCustomer event,
    Emitter<QuotationOrderState> emit,
  ) async {
    try {
      final defaultCustomer = await customerRepository.getDefaultCustomer(
        event.companyId,
      );

      if (defaultCustomer != null) {
        add(
          UpdateCustomerInfo(
            customer: defaultCustomer,
            currentHeader: state.selectedHeader,
          ),
        );
      }

      emit(
        state.copyWith(
          status: QuotationOrderStatus.loaded,
          selectedHeader: state.selectedHeader,
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to set customer: $e'));
    }
  }

  // ============ BARCODE & UOM OPERATIONS ============

  void _onSetUseBarcode(
    SetUseBarcode event,
    Emitter<QuotationOrderState> emit,
  ) {
    emit(state.copyWith(useBarcode: event.useBarcode));
  }

  void _onSetBarcode(SetBarcode event, Emitter<QuotationOrderState> emit) {
    emit(state.copyWith(barCode: event.barcode));
  }

  Future<void> _onScanBarcode(
    ScanBarcode event,
    Emitter<QuotationOrderState> emit,
  ) async {
    if (state.barCode.isEmpty) return;

    emit(state.loadingState());

    try {
      // Find item by barcode
      final itemsInBranch = await itemInBranchRepository.findByBarcode(
        state.barCode,
        state.companyId!,
      );

      if (itemsInBranch.isNotEmpty) {
        final itemInBranch = itemsInBranch.first;

        QuotationOrderDetail newDetail;

        if (state.createDetailItems.length == 1 &&
            state.createDetailItems.first.itemsTableId == 0) {
          // Update the first empty item
          newDetail = state.createDetailItems.first.copyWith(
            itemsTableId: itemInBranch.itemNumber,
            itemInBranch: itemInBranch.id,
            quantity: 1.0,
            unitOfMeasure: itemInBranch.unitOfMeasure,
          );

          final updatedDetails = [newDetail];
          emit(
            state.copyWith(
              createDetailItems: updatedDetails,
              selectedDetail: newDetail,
            ),
          );
        } else {
          // Add new item
          newDetail = QuotationOrderDetail(
            tempId: _getNextTempId(state.createDetailItems),
            itemsTableId: itemInBranch.itemNumber!,
            itemInBranch: itemInBranch.id,
            quantity: 1.0,
            unitOfMeasure: itemInBranch.unitOfMeasure,
            company: state.companyId,
            quoteOrderHeaderId: state.selectedHeader?.id ?? 0,
            taxable: itemInBranch.itemRef!.taxable,
          );

          final updatedDetails = [...state.createDetailItems, newDetail];
          emit(
            state.copyWith(
              createDetailItems: updatedDetails,
              selectedDetail: newDetail,
            ),
          );
        }

        // Update unit price
        add(
          UpdateUnitPriceWithUom(detail: newDetail, itemInBranch: itemInBranch),
        );
      }

      emit(state.copyWith(barCode: '', status: QuotationOrderStatus.loaded));
    } catch (e) {
      emit(state.errorState('Error scanning barcode: $e'));
    }
  }

  Future<void> _onUpdateUnitPriceWithUom(
    UpdateUnitPriceWithUom event,
    Emitter<QuotationOrderState> emit,
  ) async {
    try {
      final itemInBranch = event.itemInBranch;
      final detail = event.detail;

      if (itemInBranch.itemNumber == null) return;

      // Get UOM conversion factor
      final factor = await uomConversionsRepository.fromOtherToAnother(
        itemInBranch.itemNumber!,
        detail.unitOfMeasure ?? itemInBranch.unitOfMeasure!,
        itemInBranch.unitOfMeasure!,
        state.companyId!,
      );

      final convertedQuantity = (detail.quantity ?? 0.0) * factor;

      // Check stock availability (for quotation, we might just validate without deducting)
      if (convertedQuantity <= (itemInBranch.quantityAvailable ?? 0.0)) {
        final unitPrice = itemInBranch.unitPrice != null
            ? (factor * itemInBranch.unitPrice!)
            : 0.0;
        final effectiveUnitPrice = event.manualUnitPrice ?? unitPrice;

        final updatedDetail = detail.copyWith(
          unitPrice: effectiveUnitPrice,
          extendedPrice: (detail.quantity ?? 0.0) * effectiveUnitPrice,
          itemInBranch: itemInBranch.id,
          unitOfMeasure: detail.unitOfMeasure ?? itemInBranch.unitOfMeasure,
        );

        emit(state.copyWith(selectedDetail: updatedDetail));

        // Update in create items if it exists there
        final itemIndex = state.createDetailItems.indexWhere(
          (item) => item.tempId == detail.tempId,
        );

        if (itemIndex != -1) {
          add(
            UpdateQuotationOrderDetail(detail: updatedDetail, index: itemIndex),
          );
        }
      } else {
        // Insufficient stock
        final disabledDetail = detail.copyWith(
          unitPrice: 0.0,
          extendedPrice: 0.0,
          itemInBranch: null,
        );

        emit(state.copyWith(selectedDetail: disabledDetail));

        final itemIndex = state.createDetailItems.indexWhere(
          (item) => item.tempId == detail.tempId,
        );

        if (itemIndex != -1) {
          add(
            UpdateQuotationOrderDetail(
              detail: disabledDetail,
              index: itemIndex,
            ),
          );
        }
      }
    } catch (e) {
      emit(state.copyWith(error: 'Failed to update unit price: $e'));
    }
  }

  void _onCalculateExtendedPrice(
    CalculateExtendedPrice event,
    Emitter<QuotationOrderState> emit,
  ) {
    final unitPrice = event.detail.unitPrice ?? 0;
    final quantity = event.detail.quantity ?? 0;
    final extendedPrice = unitPrice * quantity;

    final updatedDetail = event.detail.copyWith(extendedPrice: extendedPrice);

    // Update in create items if it exists there
    final itemIndex = state.createDetailItems.indexWhere(
      (item) => item.tempId == updatedDetail.tempId,
    );

    if (itemIndex != -1) {
      add(UpdateQuotationOrderDetail(detail: updatedDetail, index: itemIndex));
    }
  }

  // ============ FILTERING & SEARCH ============

  Future<void> _onFilterQuotationOrders(
    FilterQuotationOrders event,
    Emitter<QuotationOrderState> emit,
  ) async {
    emit(state.copyWith(status: QuotationOrderStatus.filtering));

    try {
      final filteredHeaders = await repository.filterQuotationOrders(
        companyId: state.companyId!,
        customerBillTo: event.customerBillTo,
        fsNumber: event.fsNumber,
        conversionStatus: event.conversionStatus,
        startDate: event.startDate ?? state.dateOrderStart,
        endDate: event.endDate ?? state.dateOrderEnd,
      );

      emit(
        state.copyWith(
          status: QuotationOrderStatus.loaded,
          filteredHeaders: filteredHeaders,
          selected3: QuotationOrderHeader(
            orderNumber: 0,
            customerBillTo: event.customerBillTo ?? 0,
            customerTableId: 0,
            employeesId: 0,
            fsNumber: event.fsNumber,
            conversionStatus: event.conversionStatus,
          ),
          dateOrderStart: event.startDate,
          dateOrderEnd: event.endDate,
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to filter quotation orders: $e'));
    }
  }

  // ✅ ADDING MISSING SEARCH FUNCTIONALITY
  void _onSearchQuotationOrders(
    SearchQuotationOrders event,
    Emitter<QuotationOrderState> emit,
  ) {
    if (event.query.isEmpty) {
      emit(state.copyWith(searchQuery: null, filteredHeaders: state.headers));
      return;
    }

    final query = event.query.toLowerCase();
    final filtered = state.headers.where((header) {
      return header.fsNumber?.toLowerCase().contains(query) == true ||
          header.referenceNote1?.toLowerCase().contains(query) == true ||
          header.referenceNote2?.toLowerCase().contains(query) == true ||
          header.referenceNote3?.toLowerCase().contains(query) == true ||
          (header.orderNumber != null &&
              header.orderNumber.toString().contains(query));
    }).toList();

    emit(state.copyWith(searchQuery: event.query, filteredHeaders: filtered));
  }

  void _onUpdateDateFilters(
    UpdateDateFilters event,
    Emitter<QuotationOrderState> emit,
  ) {
    emit(
      state.copyWith(
        dateOrderStart: event.startDate,
        dateOrderEnd: event.endDate,
      ),
    );
  }

  void _onClearFilters(ClearFilters event, Emitter<QuotationOrderState> emit) {
    emit(state.clearFiltersState());
  }

  // ============ UI STATE MANAGEMENT ============

  Future<void> _onPrepareCreate(
    PrepareCreateQuotationOrder event,
    Emitter<QuotationOrderState> emit,
  ) async {
    emit(state.loadingState());

    try {
      final nextOrderNumber = await repository.getNextOrderNumber(
        event.companyId,
      );
      final nextFsNumber = await repository.generateNextFsNumber(
        event.companyId,
        event.branchId,
      );

      // Get default order type from UDC
      final defaultOrderType = await _getDefaultOrderType();

      // Create new header
      final newHeader = QuotationOrderHeader(
        orderDate: DateTime.now(),
        orderNumber: nextOrderNumber,
        fsNumber: nextFsNumber,
        customerBillTo: 0,
        customerTableId: 0,
        employeesId: event.employeeId,
        company: event.companyId,
        branchId: event.branchId,
        tempId: _getNextHeaderTempId(state.createItems),
        salesRepresent: _getEmployeeFullName(event.employeeId),
        orderStatus: 'Draft',
        quotationValidationInDays: 30,
        currencyCode: 'ETB',
        exchangeRate: 1.0,
        orderType: defaultOrderType?.id,
        // Set default tax settings from system constants
        tax: 0.0,
        withholdAmount: 0.0,
        discountAmount: 0.0,
      );

      // Set default customer if available
      final defaultCustomer = await customerRepository.getDefaultCustomer(
        event.companyId,
      );

      // Create initial detail
      final newDetail = QuotationOrderDetail(
        tempId: 1,
        quoteOrderHeaderId: 0,
        itemsTableId: 0,
        company: event.companyId,
        quantity: 1.0,
        lineStatus: 'Open',
      );

      emit(
        state.copyWith(
          status: QuotationOrderStatus.loaded,
          createItems: [newHeader],
          selectedHeader: newHeader,
          createDetailItems: [newDetail],
          selectedDetail: newDetail,
          // Reset financial values
          subTotal: null,
          tax: null,
          withholdAmount: null,
          totalAmount: null,
          discountAmount: null,
          applyWH: systemConstantBloc.systemConstantService
              .shouldApplyWithholding(0.0),
          // Reset customer info
          tinNumber: null,
          phoneNumbers: null,
          countryDesc: null,
          stateDesc: null,
          regionDesc: null,
          cityDesc: null,
          // defaultCustomer: defaultCustomer,
          // Reset barcode
          useBarcode: false,
          barCode: '',
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to prepare create: $e'));
    }
  }

  void _onPrepareEdit(
    PrepareEditQuotationOrder event,
    Emitter<QuotationOrderState> emit,
  ) {
    if (state.multiselectionItems.isEmpty) return;

    emit(
      state.copyWith(
        editItems: [state.multiselectionItems.first],
        selectedHeader: state.multiselectionItems.first,
      ),
    );

    // Load details for the selected header
    if (state.multiselectionItems.first.id != null && state.companyId != null) {
      add(
        LoadQuotationOrderDetails(
          headerId: state.multiselectionItems.first.id!,
          companyId: state.companyId!,
        ),
      );
    }
  }

  void _onCancelUpdate(CancelUpdate event, Emitter<QuotationOrderState> emit) {
    emit(
      state.copyWith(
        selected1: null,
        editItems: const [],
        editDetailItems: const [],
      ),
    );
  }

  void _onCancelCreate(CancelCreate event, Emitter<QuotationOrderState> emit) {
    emit(
      state.copyWith(
        selectedHeader: null,
        createItems: const [],
        createDetailItems: const [],
        details: const [],
      ),
    );
  }

  void _onDiscardChanges(
    DiscardChanges event,
    Emitter<QuotationOrderState> emit,
  ) {
    final unsavedCreateItems = state.createItems
        .where((item) => item.id == null)
        .toList();

    if (unsavedCreateItems.isNotEmpty) {
      final updatedCreateItems = state.createItems
          .where((item) => item.id != null)
          .toList();

      emit(
        state.copyWith(
          createItems: updatedCreateItems,
          selectedHeader: updatedCreateItems.isNotEmpty
              ? updatedCreateItems.first
              : null,
          createDetailItems: const [],
          successMessage: 'All unsaved records are removed',
        ),
      );
    } else {
      emit(state.copyWith(successMessage: 'No unsaved records to remove'));
    }
  }

  // ============ BATCH OPERATIONS ============

  Future<void> _onSaveQuotationOrder(
    SaveQuotationOrder event,
    Emitter<QuotationOrderState> emit,
  ) async {
    emit(state.copyWith(status: QuotationOrderStatus.saving));

    try {
      if (event.header.id == null) {
        add(CreateQuotationOrderHeader(header: event.header));
      } else {
        add(UpdateQuotationOrderHeader(header: event.header));
      }

      // Save details
      if (event.details.isNotEmpty) {
        await _saveQuotationDetails(event.header.id ?? 0, event.details);
      }

      emit(state.successState('Quotation order saved successfully'));
    } catch (e) {
      emit(state.errorState('Failed to save quotation order: $e'));
    }
  }

  Future<void> _onSaveQuotationDetails(
    SaveQuotationDetails event,
    Emitter<QuotationOrderState> emit,
  ) async {
    emit(state.copyWith(status: QuotationOrderStatus.saving));

    try {
      await _saveQuotationDetails(event.headerId, state.createDetailItems);
      emit(state.successState('Quotation details saved successfully'));
    } catch (e) {
      emit(state.errorState('Failed to save quotation details: $e'));
    }
  }

  // ============ CONVERSION & INVOICE ============

  Future<void> _onConvertToSalesOrder(
    ConvertToSalesOrder event,
    Emitter<QuotationOrderState> emit,
  ) async {
    emit(
      state.copyWith(
        status: QuotationOrderStatus.converting,
        isConverting: true,
      ),
    );

    try {
      // This would integrate with SalesOrderBloc to create a sales order from quotation
      // For now, we'll just mark the quotation as converted
      final convertedHeader = event.quotationHeader.copyWith(
        conversionStatus: 'Converted',
        conversionDate: DateTime.now(),
      );

      await repository.updateQuotationOrderHeader(convertedHeader);

      final updatedHeaders = state.headers
          .map((h) => h.id == event.quotationHeader.id ? convertedHeader : h)
          .toList();

      emit(
        state.copyWith(
          status: QuotationOrderStatus.success,
          headers: updatedHeaders,
          filteredHeaders: updatedHeaders,
          selectedHeader: convertedHeader,
          isConverting: false,
          successMessage: 'Quotation converted to sales order successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: QuotationOrderStatus.failure,
          isConverting: false,
          error: 'Failed to convert to sales order: $e',
        ),
      );
    }
  }

  Future<void> _onPrepareInvoiceReview(
    PrepareInvoiceReview event,
    Emitter<QuotationOrderState> emit,
  ) async {
    // This would prepare invoice data for review
    // Implementation would depend on your invoice system
    emit(state.successState('Invoice review prepared successfully'));
  }

  // ============ UTILITY OPERATIONS ============

  Future<void> _onGetNextOrderNumber(
    GetNextOrderNumber event,
    Emitter<QuotationOrderState> emit,
  ) async {
    emit(state.loadingState());

    try {
      final nextOrderNumber = await repository.getNextOrderNumber(
        event.companyId,
      );

      emit(
        state.copyWith(
          status: QuotationOrderStatus.loaded,
          nextOrderNumber: nextOrderNumber,
          error: null,
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to get next order number: $e'));
    }
  }

  Future<void> _onGenerateNextFsNumber(
    GenerateNextFsNumber event,
    Emitter<QuotationOrderState> emit,
  ) async {
    emit(state.loadingState());

    try {
      final nextFsNumber = await repository.generateNextFsNumber(
        event.companyId,
        event.branchId,
      );

      final updatedHeader = state.selectedHeader?.copyWith(
        fsNumber: nextFsNumber,
      );

      emit(
        state.copyWith(
          status: QuotationOrderStatus.loaded,
          selectedHeader: updatedHeader,
          fsNumber: nextFsNumber,
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to generate FS number: $e'));
    }
  }

  void _onRefreshQuotationOrders(
    RefreshQuotationOrders event,
    Emitter<QuotationOrderState> emit,
  ) {
    if (state.companyId != null) {
      add(LoadQuotationOrders(companyId: state.companyId!));
    }
  }

  // ✅ ADDING MISSING STATE RESET
  void _onResetQuotationState(
    ResetQuotationState event,
    Emitter<QuotationOrderState> emit,
  ) {
    emit(const QuotationOrderState());
  }

  // ============ HELPER METHODS ============

  int _getNextTempId(List<QuotationOrderDetail> items) {
    if (items.isEmpty) return 1;
    final maxTempId = items
        .map((e) => e.tempId ?? 0)
        .reduce((a, b) => a > b ? a : b);
    return maxTempId + 1;
  }

  int _getNextHeaderTempId(List<QuotationOrderHeader> items) {
    if (items.isEmpty) return 1;
    final maxTempId = items
        .map((e) => e.tempId ?? 0)
        .reduce((a, b) => a > b ? a : b);
    return maxTempId + 1;
  }

  double _roundToDecimalPlaces(double value, int decimalPlaces) {
    final factor = pow(10, decimalPlaces);
    return (value * factor).roundToDouble() / factor;
  }

  String _getEmployeeFullName(int employeeId) {
    // This would fetch employee details from repository
    // For now, return placeholder
    return 'Employee $employeeId';
  }

  Future<void> _saveQuotationDetails(
    int headerId,
    List<QuotationOrderDetail> details,
  ) async {
    for (final detail in details) {
      final detailWithHeader = detail.copyWith(quoteOrderHeaderId: headerId);
      if (detail.id == null) {
        await repository.createQuotationOrderDetail(detailWithHeader);
      } else {
        await repository.updateQuotationOrderDetail(detailWithHeader);
      }
    }
  }

  Future<UdcDetails?> _getDefaultOrderType() async {
    // Get default quotation order type from UDC
    try {
      final defaultOrderType = await udcRepository.getUdcDetailsByCode(
        'OT',
        'Q',
      );
      if (defaultOrderType.isEmpty) {
        return null;
      }
      return defaultOrderType.first;
    } catch (e) {
      return null;
    }
  }
}
