// features/sales/quotation_order/bloc/quotation_order_bloc.dart
import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:savvy_stock/core/repositories/udc_repository.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/sales/customer/repo/customer_repo.dart';
import 'package:savvy_stock/features/sales/quotation_order/bloc/quotation_order_event.dart';
import 'package:savvy_stock/features/sales/quotation_order/bloc/quotation_order_state.dart';
import 'package:savvy_stock/features/sales/quotation_order/model/quotation_order_detail.dart';
import 'package:savvy_stock/features/sales/quotation_order/model/quotation_order_header.dart';
import 'package:savvy_stock/features/sales/quotation_order/repo/quotation_order_repo.dart';
import 'package:savvy_stock/features/sales/sales_order/invoice/detail/bloc/invoice_detail.event.dart';
import 'package:savvy_stock/features/sales/sales_order/invoice/detail/bloc/invoice_detail_bloc.dart';
import 'package:savvy_stock/features/sales/sales_order/invoice/detail/model/invoice_detail_model.dart';
import 'package:savvy_stock/features/sales/sales_order/invoice/detail/repo/invoice_detail_repo.dart';
import 'package:savvy_stock/features/sales/sales_order/invoice/header/bloc/invoice_header_bloc.dart';
import 'package:savvy_stock/features/sales/sales_order/invoice/header/bloc/invoice_header_event.dart';
import 'package:savvy_stock/features/sales/sales_order/invoice/header/model/invoice_header_model.dart';
import 'package:savvy_stock/features/sales/sales_order/invoice/header/repo/invoice_header_repo.dart';
import 'package:savvy_stock/features/stock/item_in_branch/repo/item_in_branch_repo.dart';
import 'package:savvy_stock/features/stock/item_cost/repo/item_cost_repository.dart';
import 'package:savvy_stock/features/stock/item_uom_conversions/repo/item_uom_conv_repo.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_bloc.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_state.dart';
import 'package:savvy_stock/features/sales/sales_order/header/model/sales_order_header.dart';
import 'package:savvy_stock/features/sales/sales_order/detail/model/sales_order_detail.dart';
import 'package:savvy_stock/features/udc_detail/models/udc_details.dart';

class QuotationOrderBloc
    extends Bloc<QuotationOrderEvent, QuotationOrderState> {
  final QuotationOrderRepository repository;
  final AuthBloc authBloc;
  final SystemConstantBloc systemConstantBloc;
  final CustomerRepository customerRepository;
  final ItemUomConversionsRepository uomConversionsRepository;
  final StockItemInBranchRepository itemInBranchRepository;
  final InvoiceHistoryDetailBloc invoiceDetailBloc;
  final InvoiceHistoryHeaderBloc invoiceHeaderBloc;
  final InvoiceHistoryDetailRepository invoiceDetailRepository;
  final InvoiceHistoryHeaderRepository invoiceHeaderRepository;
  final UdcRepository udcRepository;
  final ItemCostRepository itemCostRepository;

  StreamSubscription? _authSubscription;
  StreamSubscription? _systemConstantSubscription;

  QuotationOrderBloc({
    required this.repository,
    required this.authBloc,
    required this.systemConstantBloc,
    required this.customerRepository,
    required this.uomConversionsRepository,
    required this.itemInBranchRepository,
    required this.invoiceDetailBloc,
    required this.invoiceHeaderBloc,
    required this.invoiceDetailRepository,
    required this.invoiceHeaderRepository,
    required this.udcRepository,
    required this.itemCostRepository,
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
    on<ClearQuotationSelection>(_onClearSelection);
    on<CancelQuotationOrder>(_onCancelQuotationOrder);
    on<PrepareCreateQuotationOrder>(_onPrepareCreate);
    on<PrepareEditQuotationOrder>(_onPrepareEdit);
    on<CancelQuotationUpdate>(_onCancelUpdate);
    on<CancelQuotationCreate>(_onCancelCreate);
    on<DiscardQuotationChanges>(_onDiscardChanges);

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
    on<LoadFeeSystemConstants>(_onLoadFeeSystemConstants);

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
    on<ClearQuotationFilters>(_onClearFilters);

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
    on<GenerateInvoiceFromQuotation>(_onGenerateInvoiceFromQuotation);

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
          applyWithholding: state.canApplyWithholding!,
          discountAmount: state.discountAmount!,
        ),
      );
    }
  }

  // ============ HEADER CRUD OPERATIONS ============

  Future<void> _onLoadQuotationOrders(
    LoadQuotationOrders event,
    Emitter<QuotationOrderState> emit,
  ) async {
    emit(state.loadingState('load_quotation_order'));

    try {
      final headers = await repository.getQuotationOrderHeaders(
        companyId: event.companyId,
        fsNumber: state.fsNumber,
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
      if (kDebugMode) {
        emit(state.errorState('Failed to load quotation orders: $e'));
      } else {
        emit(state.errorState('Failed to load quotation orders'));
      }
    }
  }

  Future<void> _onCreateQuotationOrderHeader(
    CreateQuotationOrderHeader event,
    Emitter<QuotationOrderState> emit,
  ) async {
    emit(state.loadingState('create_quotation_order_header'));

    try {
      // Get next order number
      final nextOrderNumber = await repository.getNextOrderNumber(
        event.header.company!,
      );

      // Process header with business logic
      final processedHeader = await _processHeaderBusinessLogic(
        event.header.copyWith(
          orderNumber: nextOrderNumber,
          conversionStatus: 'Proforma Created', // ✅ Set initial status
        ),
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
      if (kDebugMode) {
        emit(state.errorState('Failed to create quotation order: $e'));
      } else {
        emit(state.errorState('Failed to create quotation order'));
      }
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
      discount: header.discountAmount == 0 ? 'N' : 'Y',
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
    emit(state.loadingState('update_quotation_order_header'));

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
        state
            .successState(
              'Quotation order updated successfully',
              operation: 'update_quotation_order_header',
            )
            .copyWith(
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
      if (kDebugMode) {
        emit(state.errorState('Failed to update quotation order: $e'));
      } else {
        emit(state.errorState('Failed to update quotation order'));
      }
    }
  }

  Future<void> _onDeleteQuotationOrderHeader(
    DeleteQuotationOrderHeader event,
    Emitter<QuotationOrderState> emit,
  ) async {
    emit(state.loadingState('delete_quotation_order_header'));

    try {
      await repository.deleteQuotationOrderHeader(event.id);

      final updatedHeaders = state.headers
          .where((h) => h.id != event.id)
          .toList();
      final updatedFilteredHeaders = state.filteredHeaders
          .where((h) => h.id != event.id)
          .toList();

      emit(
        state
            .successState(
              'Quotation order deleted successfully',
              operation: 'delete_quotation_order_header',
            )
            .copyWith(
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
      if (kDebugMode) {
        emit(state.errorState('Failed to delete quotation order: $e'));
      } else {
        emit(state.errorState('Failed to delete quotation order'));
      }
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
      if (kDebugMode) {
        emit(state.errorState('Failed to delete quotation orders: $e'));
      } else {
        emit(state.errorState('Failed to delete quotation orders'));
      }
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
      // emit(state.errorState('Failed to save quotation orders: $e'));
      if (kDebugMode) {
        developer.log('Failed to save quotation orders: $e');
      }
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
    ClearQuotationSelection event,
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
    emit(state.loadingState('cancel_quotation_order'));

    try {
      final cancelledHeader = event.header.copyWith(
        conversionStatus: 'Cancelled',
        commentsReason: event.commentsReason,
        conversionDate: DateTime.now(),
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
      if (kDebugMode) {
        emit(state.errorState('Failed to cancel quotation order: $e'));
      } else {
        emit(state.errorState('Failed to cancel quotation order'));
      }
    }
  }

  // ============ DETAIL OPERATIONS ============

  Future<void> _onLoadQuotationOrderDetails(
    LoadQuotationOrderDetails event,
    Emitter<QuotationOrderState> emit,
  ) async {
    emit(state.loadingState('load_quotation_order_details'));

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
      if (kDebugMode) {
        emit(state.errorState('Failed to load quotation order details: $e'));
      } else {
        emit(state.errorState('Failed to load quotation order details'));
      }
    }
  }

  void _onAddQuotationOrderDetail(
    AddQuotationOrderDetail event,
    Emitter<QuotationOrderState> emit,
  ) {
    try {
      // Check if an item with the same itemsTableId and unitOfMeasure already exists
      final existingIndex = state.createDetailItems.indexWhere(
        (detail) =>
            detail.itemsTableId == event.detail.itemsTableId &&
            detail.unitOfMeasure == event.detail.unitOfMeasure,
      );

      List<QuotationOrderDetail> updatedDetails;

      if (existingIndex != -1) {
        // ✅ Merge with existing item - sum quantities and extended prices
        final existingDetail = state.createDetailItems[existingIndex];
        final mergedQuantity =
            (existingDetail.quantity ?? 0.0) + (event.detail.quantity ?? 0.0);
        final mergedExtendedPrice =
            (existingDetail.extendedPrice ?? 0.0) +
            (event.detail.extendedPrice ?? 0.0);

        final mergedDetail = existingDetail.copyWith(
          quantity: mergedQuantity,
          extendedPrice: mergedExtendedPrice,
        );

        updatedDetails = List.from(state.createDetailItems);
        updatedDetails[existingIndex] = mergedDetail;

        emit(
          state.copyWith(
            createDetailItems: updatedDetails,
            selectedDetail: mergedDetail,
            status: QuotationOrderStatus.success,
            successMessage: 'Item quantity updated',
            lastOperation: 'merge_quotation_order_detail',
          ),
        );
      } else {
        // ✅ Add as new item
        final newDetail = event.detail.copyWith(
          tempId: _getNextTempId(state.createDetailItems),
        );

        updatedDetails = [...state.createDetailItems, newDetail];

        emit(
          state.copyWith(
            createDetailItems: updatedDetails,
            selectedDetail: newDetail,
            status: QuotationOrderStatus.success,
            successMessage: 'Quotation order detail added successfully',
            lastOperation: 'add_quotation_order_detail',
          ),
        );
      }

      // Recalculate totals
      if (state.selectedHeader != null) {
        add(
          CalculateQuotationTotals(
            header: state.selectedHeader!,
            details: updatedDetails,
            applyWithholding: state.canApplyWithholding!,
            discountAmount: state.discountAmount!,
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        emit(
          state.errorState(
            'Failed to add quotation order detail: $e',
            operation: 'add_quotation_order_detail',
          ),
        );
      } else {
        emit(
          state.errorState(
            'Failed to add quotation order detail',
            operation: 'add_quotation_order_detail',
          ),
        );
      }
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
          applyWithholding: state.canApplyWithholding!,
          discountAmount: state.discountAmount!,
        ),
      );
    }
  }

  void _onRemoveQuotationOrderDetail(
    RemoveQuotationOrderDetail event,
    Emitter<QuotationOrderState> emit,
  ) {
    try {
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
            applyWithholding: state.canApplyWithholding!,
            discountAmount: state.discountAmount!,
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        emit(
          state.errorState(
            'Failed to remove quotation order detail: $e',
            operation: 'remove_quotation_order_detail',
          ),
        );
      } else {
        emit(
          state.errorState(
            'Failed to remove quotation order detail',
            operation: 'remove_quotation_order_detail',
          ),
        );
      }
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
      if (kDebugMode) {
        emit(state.errorState('Failed to delete quotation details: $e'));
      } else {
        emit(state.errorState('Failed to delete quotation details'));
      }
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
      //emit(state.errorState('Failed to save row: $e'));
      if (kDebugMode) {
        developer.log('Failed to save row: $e');
      }
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
    emit(state.paymentProcessingState('calculate_quotation_order_totals'));

    try {
      final systemConstants =
          systemConstantBloc.systemConstantService.currentSystemConstant;

      // Get decimal places from system constants (like Java)
      final decimalPlaces = systemConstants?.decimalPlaces ?? 2;

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
      final roundedSubTotal = systemConstantBloc.systemConstantService
          .roundToDecimalPlaces(subTotal, decimalPlaces);

      // Calculate VAT
      final taxAmount = systemConstantBloc.systemConstantService
          .calculateTaxAmount(taxableAmount);

      // Calculate withholding
      double withHoldAmount = 0.0;
      if (event.applyWithholding) {
        withHoldAmount = systemConstantBloc.systemConstantService
            .calculateWithholdingAmount(roundedSubTotal);
      }

      // Ensure discount is not null
      final discountAmount = event.discountAmount;

      // Compute total
      final totalAmount = systemConstantBloc.systemConstantService
          .roundToDecimalPlaces(
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
          canApplyWithholding: event.applyWithholding,
          systemConstants: event.systemConstants,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        emit(state.errorState('Failed to calculate totals: $e'));
      } else {
        emit(state.errorState('Failed to calculate totals'));
      }
    }
  }

  // ✅ ADDING MISSING FINANCIAL SETTINGS
  void _onApplyWithholdingTax(
    ApplyWithholdingTax event,
    Emitter<QuotationOrderState> emit,
  ) {
    emit(state.copyWith(canApplyWithholding: event.applyWithholding));

    // Recalculate totals if withholding tax changes
    if (state.selectedHeader != null && state.createDetailItems.isNotEmpty) {
      add(
        CalculateQuotationTotals(
          header: state.selectedHeader!,
          details: state.createDetailItems,
          applyWithholding: event.applyWithholding,
          discountAmount: state.discountAmount!,
          systemConstants: state.systemConstants,
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
          applyWithholding: state.canApplyWithholding ?? false,
          discountAmount: event.discountAmount,
        ),
      );
    }
  }

  void _onUpdateTaxSettings(
    UpdateTaxSettings event,
    Emitter<QuotationOrderState> emit,
  ) {
    try {
      if (kDebugMode) {
        developer.log(
          'Coordinator: Updating tax and fees - Discount: ${event.discountAmount}, Withholding: ${event.isWithholdingEnabled}',
        );
      }

      // Update withholding in header bloc
      add(ApplyWithholdingTax(applyWithholding: event.isWithholdingEnabled));

      // Update discount in header bloc
      add(ApplyDiscount(discountAmount: event.discountAmount));

      // Check if withholding can be applied
      final canApplyWithholding =
          event.subTotal >= (state.withholdAmount ?? 0.0);

      emit(
        state.copyWith(
          totalAmount: event.discountAmount,
          isWithholdingEnabled: event.isWithholdingEnabled,
          canApplyWithholding: canApplyWithholding,
          lastOperation: 'Tax and fees updated',
        ),
      );

      // Recalculate totals with new settings
      if (state.createDetailItems.isNotEmpty) {
        add(
          CalculateQuotationTotals(
            header: state.selectedHeader!,
            details: state.createDetailItems,
            applyWithholding: event.isWithholdingEnabled,
            discountAmount: event.discountAmount,
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        emit(state.errorState('Failed to update tax and fees: $e'));
      } else {
        emit(state.errorState('Failed to update tax and fees'));
      }
    }
  }

  Future<void> _onLoadFeeSystemConstants(
    LoadFeeSystemConstants event,
    Emitter<QuotationOrderState> emit,
  ) async {
    try {
      final systemConstantsService = systemConstantBloc.systemConstantService;

      // Ensure system constants are loaded
      await systemConstantsService.ensureLoaded();

      final vatRate = systemConstantsService.vatRate;
      final withholdingRate = systemConstantsService.withholdingRate;
      final withholdingInitial = systemConstantsService.withholdingInitial;

      if (kDebugMode) {
        developer.log(
          'Coordinator: Loaded system constants - VAT: $vatRate, Withholding Rate: $withholdingRate, Withholding Initial: $withholdingInitial',
        );
      }

      emit(
        state.copyWith(
          taxRate: vatRate,
          withholdingRate: withholdingRate,
          withholdingInitial: withholdingInitial,
          lastOperation: 'System constants loaded',
        ),
      );

      // Recalculate with new rates if we have existing data
      if (state.createDetailItems.isNotEmpty) {
        add(
          CalculateQuotationTotals(
            header: state.selectedHeader!,
            details: state.createDetailItems,
            applyWithholding: state.canApplyWithholding!,
            discountAmount: state.discountAmount!,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          error: 'Failed to load system constants: ${e.toString()}',
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

      // Build phone numbers string safely (handle null phoneNumber)
      final primaryPhone = customer.phoneNumber ?? '';
      final secondaryPhone = customer.phone2;

      final phoneNumbers = primaryPhone.isNotEmpty
          ? (secondaryPhone != null && secondaryPhone.isNotEmpty
                ? '$primaryPhone, $secondaryPhone'
                : primaryPhone)
          : (secondaryPhone ?? '');

      // Update customer info in state
      final updatedState = state.updateCustomerInfo(
        tinNumber: customer.tinNumber,
        phoneNumbers: phoneNumbers.isNotEmpty ? phoneNumbers : null,
        countryDesc: customer.country,
        stateDesc: customer.state,
        regionDesc: customer.region,
        cityDesc: customer.city,
      );

      // Update selected header with customer
      if (event.currentHeader != null && customer.id != null) {
        final updatedHeader = event.currentHeader!.copyWith(
          customerTableId: customer.id!,
          customerBillTo: customer.id!,
          customerBillToRef: customer,
          customerTableRef: customer,
        );

        emit(updatedState.copyWith(selectedHeader: updatedHeader));
      } else if (state.selectedHeader != null && customer.id != null) {
        // Fallback: use state's selectedHeader if currentHeader not provided
        final updatedHeader = state.selectedHeader!.copyWith(
          customerTableId: customer.id!,
          customerBillTo: customer.id!,
          customerBillToRef: customer,
          customerTableRef: customer,
        );

        emit(updatedState.copyWith(selectedHeader: updatedHeader));
      } else {
        emit(updatedState);
      }
    } catch (e) {
      if (kDebugMode) {
        emit(state.errorState('Failed to update customer info: $e'));
      } else {
        emit(state.errorState('Failed to update customer info'));
      }
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

      //if default customer is not null, update customer info
      if (defaultCustomer != null) {
        add(
          UpdateCustomerInfo(
            customer: defaultCustomer,
            currentHeader: state.selectedHeader,
          ),
        );
      }
      //if default customer is null, just grab the customer from the state
      else if (state.defaultCustomer != null) {
        add(
          UpdateCustomerInfo(
            customer: state.defaultCustomer!,
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
      if (kDebugMode) {
        emit(state.errorState('Failed to set customer: $e'));
      } else {
        emit(state.errorState('Failed to set customer'));
      }
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

    emit(state.loadingState('scan_barcode_for_quotation_order'));

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
            itemsTableId: itemInBranch.itemNumber,
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
      if (kDebugMode) {
        emit(state.errorState('Error scanning barcode: $e'));
      } else {
        emit(state.errorState('Error scanning barcode'));
      }
    }
  }

  Future<void> _onUpdateUnitPriceWithUom(
    UpdateUnitPriceWithUom event,
    Emitter<QuotationOrderState> emit,
  ) async {
    try {
      if (event.detail.unitOfMeasure == null) return;

      // Resolve company id safely
      final companyId = state.companyId ?? authBloc.state.companyId;
      if (companyId == null) return;

      // Get UOM conversion factor using the correct company id
      // Convert from the selected line UOM to the branch/item UOM
      final sourceUomId = event.detail.unitOfMeasure!;
      final targetUomId = event.itemInBranch.unitOfMeasure;

      double conversionFactor = 1.0;
      if (targetUomId != null) {
        conversionFactor = await uomConversionsRepository.fromOtherToAnother(
          event.itemInBranch.itemNumber,
          sourceUomId,
          targetUomId,
          companyId,
        );
      }

      // Convert requested quantity into the branch UOM for stock check
      final convertedQuantity =
          (event.detail.quantity ?? 0.0) * conversionFactor;

      // Check if converted quantity is available
      if (convertedQuantity <= event.itemInBranch.quantityAvailable!) {
        // Apply converted unit price based on branch price and factor,
        // or respect a manually entered unit price from the UI when provided
        final baseUnitPrice = event.itemInBranch.unitPrice ?? 0.0;
        final convertedUnitPrice = conversionFactor * baseUnitPrice;
        final effectiveUnitPrice = event.manualUnitPrice ?? convertedUnitPrice;

        final updatedDetail = event.detail.copyWith(
          unitPrice: effectiveUnitPrice,
          extendedPrice: (event.detail.quantity ?? 0.0) * effectiveUnitPrice,
          itemInBranch: event.itemInBranch.id,
          taxable:
              event.detail.itemTableRef?.taxable, // ✅ Copy taxable from item
        );

        emit(state.copyWith(selectedDetail: updatedDetail));

        // Update in create items if it exists there
        final itemIndex = state.createDetailItems.indexWhere(
          (item) => item.tempId == event.detail.tempId,
        );

        if (itemIndex != -1) {
          add(
            UpdateQuotationOrderDetail(detail: updatedDetail, index: itemIndex),
          );
        }
      } else {
        // Insufficient stock
        final disabledDetail = event.detail.copyWith(
          unitPrice: 0.0,
          extendedPrice: 0.0,
          itemInBranch: null,
        );

        emit(state.copyWith(selectedDetail: disabledDetail));

        final itemIndex = state.createDetailItems.indexWhere(
          (item) => item.tempId == event.detail.tempId,
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
      if (kDebugMode) {
        emit(state.copyWith(error: 'Failed to update unit price: $e'));
      } else {
        emit(state.copyWith(error: 'Failed to update unit price'));
      }
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
      if (kDebugMode) {
        emit(state.errorState('Failed to filter quotation orders: $e'));
      } else {
        emit(state.errorState('Failed to filter quotation orders'));
      }
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
          (header.orderNumber.toString().contains(query));
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

  void _onClearFilters(
    ClearQuotationFilters event,
    Emitter<QuotationOrderState> emit,
  ) {
    emit(state.clearFiltersState());
  }

  // ============ UI STATE MANAGEMENT ============

  Future<void> _onPrepareCreate(
    PrepareCreateQuotationOrder event,
    Emitter<QuotationOrderState> emit,
  ) async {
    emit(state.loadingState('prepare_new_quotation_order'));

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
        conversionStatus: 'Proforma Created',
        quotationValidationInDays: 30,
        currencyCode: 'ETB',
        exchangeRate: 1.0,
        orderType: defaultOrderType?.id,
        salesType: 'Quotation Order',
        // Set default tax settings from system constants
        tax: 0.0,
        withholdAmount: 0.0,
        discountAmount: 0.0,
      );

      // Set default customer if available
      final defaultCustomer = await customerRepository.getDefaultCustomer(
        event.companyId,
      );

      emit(
        state
            .successState(
              'New quotation order prepared',
              operation: 'prepare_new_quotation_order',
            )
            .copyWith(
              status: QuotationOrderStatus.loaded,
              createItems: [newHeader],
              selectedHeader: newHeader,
              createDetailItems: const [], // ✅ Start with empty list
              //selectedDetail: null,
              // Reset financial values
              subTotal: null,
              tax: null,
              withholdAmount: null,
              totalAmount: null,
              discountAmount: null,
              canApplyWithholding: systemConstantBloc.systemConstantService
                  .shouldApplyWithholding(0.0),
              // Reset customer info
              tinNumber: null,
              phoneNumbers: null,
              countryDesc: null,
              stateDesc: null,
              regionDesc: null,
              cityDesc: null,
              defaultCustomer: defaultCustomer,
              // Reset barcode
              useBarcode: false,
              barCode: '',
            ),
      );
      if (kDebugMode) {
        developer.log(
          'Coordinator: New order prepared - Header: ${newHeader.id}, defaultCustomerCount=${defaultCustomer ?? 0}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        emit(state.errorState('Failed to prepare create: $e'));
      } else {
        emit(state.errorState('Failed to prepare create'));
      }
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

  void _onCancelUpdate(
    CancelQuotationUpdate event,
    Emitter<QuotationOrderState> emit,
  ) {
    emit(
      state.copyWith(
        selected1: null,
        editItems: const [],
        editDetailItems: const [],
      ),
    );
  }

  void _onCancelCreate(
    CancelQuotationCreate event,
    Emitter<QuotationOrderState> emit,
  ) {
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
    DiscardQuotationChanges event,
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
    emit(state.loadingState('save_quotation_order'));

    try {
      // ✅ Get current user and timestamp for audit fields
      final currentUser = authBloc.state.userId?.id;
      final currentTime = DateTime.now();

      // ✅ Prepare header with all calculated values from state
      var headerToSave = event.header.copyWith(
        // Financial values from state calculations
        tax: state.tax,
        withholdAmount: state.withholdAmount,
        discountAmount: state.discountAmount ?? 0.0,
        discount: (state.discountAmount ?? 0) == 0 ? 'N' : 'Y',
        discountInPercent:
            (state.discountAmount == null ||
                state.discountAmount == 0 ||
                state.subTotal == null ||
                state.subTotal == 0)
            ? 0
            : (state.discountAmount! / state.subTotal!) * 100,
        addOn: event.header.addOn ?? '0',
        amountTotal: state.totalAmount,
        amountOpen: state.totalAmount, // Initially equals total
        withHoldApply: state.canApplyWithholding == true ? 'Y' : 'N',
        // Cost totals from details
        unitCost: event.details.fold<double>(
          0.0,
          (sum, d) => sum + (d.unitCost ?? 0.0),
        ),
        amountCost: event.details.fold<double>(
          0.0,
          (sum, d) => sum + ((d.unitCost ?? 0.0) * (d.quantity ?? 0.0)),
        ),

        // Audit fields (only override if not already set)
        createdBy: event.header.createdBy ?? currentUser,
        updatedBy: currentUser,
        createdAt: event.header.createdAt ?? currentTime,
        updatedAt: currentTime,
      );

      // ✅ Create or update header SYNCHRONOUSLY to get the ID
      QuotationOrderHeader savedHeader;

      if (event.header.id == null) {
        // ✅ For new orders, generate a unique FS number
        final nextFsNumber = await repository.generateNextFsNumber(
          event.header.company!,
          event.header.branchId!,
        );

        headerToSave = headerToSave.copyWith(fsNumber: nextFsNumber);

        // ✅ Call repository directly and await to get ID
        final headerId = await repository.createQuotationOrderHeader(
          headerToSave,
        );
        savedHeader = headerToSave.copyWith(id: headerId);

        // Update state lists
        final updatedHeaders = [savedHeader, ...state.headers];
        final updatedCreateItems = state.createItems
            .where((item) => item.tempId != savedHeader.tempId)
            .toList();

        emit(
          state.copyWith(
            headers: updatedHeaders,
            filteredHeaders: updatedHeaders,
            createItems: updatedCreateItems,
            selectedHeader: savedHeader,
          ),
        );
      } else {
        // Update existing header
        await repository.updateQuotationOrderHeader(headerToSave);
        savedHeader = headerToSave;

        emit(state.copyWith(selectedHeader: savedHeader));
      }

      // ✅ Now save details with the correct header ID
      if (event.details.isNotEmpty) {
        await _saveQuotationDetails(savedHeader.id!, event.details);
      }

      emit(
        state
            .successState(
              'Quotation order saved successfully',
              operation: 'save_quotation_order',
            )
            .copyWith(
              selectedHeader: savedHeader,
              createDetailItems: event.details,
              isOrderComplete: true,
              isCalculationsComplete: true,
            ),
      );

      add(GenerateInvoiceFromQuotation());
      add(ClearQuotationOrderDetails());
    } catch (e) {
      //emit(state.errorState('Failed to save quotation order: $e'));
      if (kDebugMode) {
        developer.log('Failed to save quotation order: $e');
      }
    }
  }

  Future<void> _onSaveQuotationDetails(
    SaveQuotationDetails event,
    Emitter<QuotationOrderState> emit,
  ) async {
    emit(state.loadingState('save_quotation_details'));

    try {
      await _saveQuotationDetails(event.headerId, state.createDetailItems);
      emit(
        state.successState(
          'Quotation details saved successfully',
          operation: 'save_quotation_details',
        ),
      );
    } catch (e) {
      //emit(state.errorState('Failed to save quotation details: $e'));
      if (kDebugMode) {
        developer.log('Failed to save quotation details: $e');
      }
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
      // 1. Fetch Details
      if (kDebugMode) {
        developer.log(
          'DEBUG: Fetching quotation details for header ID: ${event.quotationHeader.id}',
        );
      }
      final details = await repository.getQuotationOrderDetailsByHeaderId(
        event.quotationHeader.id!,
        event.quotationHeader.company!,
      );
      if (kDebugMode) {
        developer.log('DEBUG: Fetched ${details.length} details');
      }
      if (details.isEmpty) {
        emit(
          state.errorState(
            'No details found for quotation header ID: ${event.quotationHeader.id}',
          ),
        );
        return;
      }

      // 2. Map Header
      if (kDebugMode) {
        developer.log(
          'DEBUG: Mapping header - customerBillTo: ${event.quotationHeader.customerBillTo}, customerTableId: ${event.quotationHeader.customerTableId}, employeesId: ${event.quotationHeader.employeesId}',
        );
      }
      if (kDebugMode) {
        developer.log(
          'DEBUG: Discount character  : ${event.quotationHeader.discount}',
        );
      }

      final salesHeader = SalesOrderHeader(
        orderDate: DateTime.now(),
        requiredDate: DateTime.now(),
        shippedDate: event.quotationHeader.shippedDate,
        salesType: 'Sales Order',
        discount: event.quotationHeader.discountAmount == 0 ? 'N' : 'Y',
        addOn: event.quotationHeader.addOn ?? 'N',
        tax: event.quotationHeader.tax,
        withHoldApply: event.quotationHeader.withHoldApply,
        withholdAmount: event.quotationHeader.withholdAmount,
        discountAmount: event.quotationHeader.discountAmount,
        discountInPercent: event.quotationHeader.discountInPercent,
        referenceNote1: event.quotationHeader.referenceNote1,
        referenceNote2: event.quotationHeader.referenceNote2,
        referenceNote3: event.quotationHeader.referenceNote3,
        referenceNote4: event.quotationHeader.referenceNote4,
        proformaFlag: 'Y',
        proformaReference: event.quotationHeader.fsNumber,
        creditDateToPay: null,
        fsNumber: null, // Will be generated by SalesOrderHeaderBloc
        invoiceNumber: null, // Will be generated by SalesOrderHeaderBloc
        branchValue: event.quotationHeader.branchId,
        customerBillTo: event.quotationHeader.customerBillTo,
        customerTableId: event.quotationHeader.customerTableId,
        employeesId: event.quotationHeader.employeesId, // ✅ CRITICAL FIX
        amountTotal: event.quotationHeader.amountTotal,
        company: event.quotationHeader.company,
        orderNumber: null, // Will be generated by SalesOrderHeaderBloc
        amountOpen: event.quotationHeader.amountTotal,
        orderType: event.quotationHeader.orderType,
        unitCost: event.quotationHeader.unitCost,
        amountCost: event.quotationHeader.amountCost,

        // Reference objects
        customerBillToRef: event.quotationHeader.customerBillToRef,
        customerTableRef: event.quotationHeader.customerTableRef,
        employee: event.quotationHeader.employeeRef,
        paymentInstrumentRef: event.quotationHeader.paymentInstrumentRef,
        paymentStatusRef: event.quotationHeader.paymentStatusRef,
        orderTypeRef: event.quotationHeader.orderTypeRef,
      );
      if (kDebugMode) {
        developer.log('DEBUG: Header mapped successfully');
      }

      // 3. Map Details
      if (kDebugMode) {
        developer.log('DEBUG: Mapping ${details.length} details');
      }
      final salesDetails = details.map((d) {
        return SalesOrderDetail(
          unitPrice: d.unitPrice,
          quantity: d.quantity,
          extendedPrice: d.extendedPrice,
          taxable: d.taxable,
          reference1: d.reference1,
          reference2: d.reference2,
          itemsTableId: d.itemsTableId,
          itemInBranch: d.itemInBranch,
          company: d.company,
          lotNumber: null,
          unitCost: d.unitCost,
          amountCost: d.amountCost,
          unitOfMeasure: d.unitOfMeasure,

          // Reference objects
          item: d.itemTableRef,
          itemBranch: d.itemBranchRef,
          uom: d.uomRef,
        );
      }).toList();
      if (kDebugMode) {
        developer.log('DEBUG: All details mapped successfully');
      }

      emit(
        state.copyWith(
          status: QuotationOrderStatus.success,
          isConverting: false,
          successMessage: 'Quotation converted to sales order successfully',
          convertedSalesHeader: salesHeader,
          convertedSalesDetails: salesDetails,
          lastOperation: 'convert_to_sales',
        ),
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        developer.log('DEBUG: Error during conversion: $e');
        developer.log('DEBUG: Stack trace: $stackTrace');
      }
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
    emit(state.loadingState('get_next_quotation_order_number'));

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
      if (kDebugMode) {
        emit(state.errorState('Failed to get next order number: $e'));
      } else {
        emit(state.errorState('Failed to get next order number'));
      }
    }
  }

  Future<void> _onGenerateNextFsNumber(
    GenerateNextFsNumber event,
    Emitter<QuotationOrderState> emit,
  ) async {
    emit(state.loadingState('generate_next_quotation_order_fs_number'));

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
      if (kDebugMode) {
        emit(state.errorState('Failed to generate FS number: $e'));
      } else {
        emit(state.errorState('Failed to generate FS number'));
      }
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

  void _onResetQuotationState(
    ResetQuotationState event,
    Emitter<QuotationOrderState> emit,
  ) {
    emit(
      state.copyWith(
        status: QuotationOrderStatus.loaded,
        convertedSalesHeader: null,
        convertedSalesDetails: [],
        lastOperation: null,
        successMessage: null,
      ),
    );
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
    // ✅ Get current user and timestamp for audit fields
    final currentUser = authBloc.state.userId?.id;
    final currentTime = DateTime.now();
    final companyId = authBloc.state.companyId;

    // ✅ Calculate total extended price for proportional discount distribution
    final headerDiscountAmount = state.discountAmount ?? 0.0;
    final totalExtendedPrice = details.fold<double>(
      0.0,
      (sum, d) => sum + (d.extendedPrice ?? 0.0),
    );

    for (final detail in details) {
      // ✅ Calculate unit cost from item cost table
      double unitCost = detail.unitCost ?? 0.0;
      if (unitCost == 0.0 && companyId != null) {
        try {
          final itemCosts = await itemCostRepository.findByItemNumberAndCompany(
            detail.itemsTableId,
            companyId,
          );
          if (itemCosts.isNotEmpty) {
            unitCost = itemCosts.first.amountUnitCost ?? 0.0;
          }
        } catch (e) {
          if (kDebugMode) {
            developer.log('Failed to get item cost: $e');
          }
        }
      }
      final amountCost = unitCost * (detail.quantity ?? 0.0);

      // ✅ Distribute header discount proportionally across details
      double lineDiscountAmount = 0.0;
      double lineDiscountPercent = 0.0;
      if (headerDiscountAmount > 0 && totalExtendedPrice > 0) {
        final proportion = (detail.extendedPrice ?? 0.0) / totalExtendedPrice;
        lineDiscountAmount = headerDiscountAmount * proportion;
        lineDiscountPercent = (detail.extendedPrice ?? 0.0) > 0
            ? (lineDiscountAmount / (detail.extendedPrice ?? 1.0)) * 100
            : 0.0;
      }

      final detailToSave = detail.copyWith(
        quoteOrderHeaderId: headerId,
        unitCost: unitCost,
        amountCost: amountCost,
        discountPercent: lineDiscountPercent,
        discountAmount: lineDiscountAmount,
        taxable: detail.taxable ?? 'Y',
        // ✅ Set audit fields
        createdBy: detail.createdBy ?? currentUser,
        updatedBy: currentUser,
        createdAt: detail.createdAt ?? currentTime,
        updatedAt: currentTime,
      );

      if (detail.id == null) {
        await repository.createQuotationOrderDetail(detailToSave);
      } else {
        await repository.updateQuotationOrderDetail(detailToSave);
      }
    }
  }

  Future<UdcDetails?> _getDefaultOrderType() async {
    // Get default quotation order type from UDC
    try {
      final defaultOrderType = await udcRepository.getUdcDetailsByCode(
        'Q',
        'OT',
      );
      if (defaultOrderType.isEmpty) {
        return null;
      }
      return defaultOrderType.first;
    } catch (e) {
      return null;
    }
  }

  Future<void> _onGenerateInvoiceFromQuotation(
    GenerateInvoiceFromQuotation event,
    Emitter<QuotationOrderState> emit,
  ) async {
    final currentHeader = state.selectedHeader;
    final currentDetails = state.createDetailItems;

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
        totalAmount: state.totalAmount ?? 0.0,
        taxAmount: state.tax ?? 0.0,
        withholdAmount: state.withholdAmount ?? 0.0,
        discountAmount: state.discountAmount ?? 0.0,
        amountBeforeTax: state.subTotal,
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
          item: salesDetail.itemTableRef?.itemDescription ?? 'Item',
          quantityTransaction: salesDetail.quantity ?? 0.0,
          amountUnitPrice: salesDetail.unitPrice ?? 0.0,
          amountExtendedPrice: salesDetail.extendedPrice ?? 0.0,
          unitOfMeasure: salesDetail.itemTableRef?.unitOfMeasure ?? 'PC',
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

      if (kDebugMode) {
        developer.log(
          'Coordinator: Invoice generated - FS Number: $nextFsNumber, Items: ${invoiceDetails.length}',
        );
      }
    } catch (e) {
      emit(state.errorState('', operation: 'generate_invoice'));
      if (kDebugMode) {
        developer.log('Failed to generate invoice: $e');
      }
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
