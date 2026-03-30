// features/sales/sales_return/bloc/sales_return_bloc.dart
import 'dart:async';
import 'dart:developer' as developer;
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/sales/sales_order/header/repo/sales_order_header_repo.dart';
import 'package:savvy_stock/features/sales/sales_return/bloc/sales_return_event.dart';
import 'package:savvy_stock/features/sales/sales_return/bloc/sales_return_state.dart';
import 'package:savvy_stock/features/sales/sales_return/models/void_sales_details.dart';
import 'package:savvy_stock/features/sales/sales_return/models/void_sales_header.dart';
import 'package:savvy_stock/features/sales/sales_return/repos/sales_return_repository.dart';
import 'package:savvy_stock/features/sales/sales_return/services/sales_return_stock_service.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_bloc.dart';

class SalesReturnBloc extends Bloc<SalesReturnEvent, SalesReturnState> {
  final SalesReturnRepository repository;
  final SalesOrderHeaderRepository salesOrderHeaderRepository;
  final AuthBloc authBloc;
  final SystemConstantBloc systemConstantBloc;
  final SalesReturnStockService salesReturnStockService;

  StreamSubscription? _authSubscription;

  SalesReturnBloc({
    required this.repository,
    required this.salesOrderHeaderRepository,
    required this.authBloc,
    required this.systemConstantBloc,
    required this.salesReturnStockService,
  }) : super(const SalesReturnState()) {
    _authSubscription = authBloc.stream.listen((authState) {
      if (authState.isAuthenticated && authState.companyId != null) {
        add(
          SalesReturnInitialized(
            companyId: authState.companyId!,
            employeeId: authState.userId!.id,
          ),
        );
      }
    });

    // Event Handlers
    on<SalesReturnInitialized>(_onInitialized);
    on<LoadSalesReturns>(_onLoadSalesReturns);
    on<LoadSalesReturnByFsNumber>(_onLoadSalesReturnByFsNumber);

    // Header Operations
    on<CreateSalesReturnHeader>(_onCreateSalesReturnHeader);
    on<UpdateSalesReturnHeader>(_onUpdateSalesReturnHeader);
    on<DeleteSalesReturnHeader>(_onDeleteSalesReturnHeader);
    on<VoidSalesReturn>(_onVoidSalesReturn);

    // Detail Operations
    on<AddSalesReturnDetail>(_onAddSalesReturnDetail);
    on<UpdateSalesReturnDetail>(_onUpdateSalesReturnDetail);
    on<RemoveSalesReturnDetail>(_onRemoveSalesReturnDetail);
    on<SaveAllSalesReturnDetails>(_onSaveAllSalesReturnDetails);

    // UI State
    on<PrepareCreateSalesReturn>(_onPrepareCreateSalesReturn);
    on<SetSelectedHeader>(_onSetSelectedHeader);
    on<SetSelectedDetail>(_onSetSelectedDetail);

    // Financial Calculations
    on<CalculateReturnTotals>(_onCalculateReturnTotals);
    on<CalculateExtendedPrice>(_onCalculateExtendedPrice);
    // Return Submission
    on<SubmitSalesReturn>(_onSubmitSalesReturn);

    // Search & Filter
    on<SearchSalesReturns>(_onSearchSalesReturns);
    on<FilterSalesReturns>(_onFilterSalesReturns);

    // Utility
    on<RefreshSalesReturns>(_onRefreshSalesReturns);
    on<ResetSalesReturnState>(_onResetSalesReturnState);
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }

  // Initialization
  Future<void> _onInitialized(
    SalesReturnInitialized event,
    Emitter<SalesReturnState> emit,
  ) async {
    emit(state.copyWith(companyId: event.companyId));
    add(LoadSalesReturns(companyId: event.companyId));
  }

  Future<void> _onLoadSalesReturns(
    LoadSalesReturns event,
    Emitter<SalesReturnState> emit,
  ) async {
    emit(state.loadingState());

    try {
      final headers = await repository.getSalesReturnHeaders(event.companyId);
      emit(
        state.copyWith(
          status: SalesReturnStatus.loaded,
          headers: headers,
          filteredHeaders: headers,
        ),
      );
    } catch (e) {
      if (kDebugMode) developer.log('Failed to load sales returns: $e');
      emit(state.errorState('Failed to load sales returns: $e'));
    }
  }

  Future<void> _onLoadSalesReturnByFsNumber(
    LoadSalesReturnByFsNumber event,
    Emitter<SalesReturnState> emit,
  ) async {
    emit(state.loadingState());

    try {
      final salesOrder = await salesOrderHeaderRepository
          .getSalesOrderByFsNumberAndInvoiceNumber(
            event.fsNumber,
            event.companyId,
            invoiceNumber: event.invoiceNumber,
          );

      if (salesOrder != null) {
        // Populate return header from sales order
        final returnHeader = SalesReturnHeader(
          orderDate: salesOrder.orderDate,
          customerBillTo: salesOrder.customerBillTo ?? 0,
          customerTableId: salesOrder.customerTableId ?? 0,
          employeesId: salesOrder.employeesId ?? 0,
          company: event.companyId,
          fsNumber: salesOrder.fsNumber, //  1
          amountTotal: salesOrder.amountTotal,
          tax: salesOrder.tax,
          withholdAmount: salesOrder.withholdAmount,
          discountAmount: salesOrder.discountAmount,
          orderNumber: salesOrder.orderNumber,
          orderType: salesOrder.orderType,
          paymentMethod: salesOrder.paymentMethod,
          paymentInstrument: salesOrder.paymentInstrument,
          amountOpen:
              salesOrder.amountTotal, // Initialize open amount to total amount
          unitCost:
              salesOrder.unitCost, // Map unit cost from header if available
          amountCost:
              salesOrder.amountCost, // Map amount cost from header if available
          //commentsSales: salesOrder.commentsSales,
        );

        // Load sales order details for return
        final orderDetails = await salesReturnStockService
            .salesOrderDetailRepository
            .getSalesOrderDetailsWithRelationsByHeaderId(
              salesOrder.id!,
              event.companyId,
            );

        final returnDetails = orderDetails
            .map(
              (detail) => SalesReturnDetails(
                itemsTableId: detail.itemsTableId!,
                salesReturnHeaderId: returnHeader.id,
                company: event.companyId,
                unitPrice: detail.unitPrice,
                quantity: detail.quantity,
                extendedPrice: detail.extendedPrice,
                unitCost: detail.unitCost ?? 0.0,
                itemInBranch: detail.itemInBranch,
                unitOfMeasure: detail.unitOfMeasure,
                taxable: detail.taxable, // 2
                // Populate refs
                itemEntryRef: detail.item,
                itemInBranchRef: detail.itemBranch,
                unitOfMeasureRef: detail.uom,
                lotNumber: detail.lotNumber,
                amountCost:
                    detail.amountCost ??
                    ((detail.unitCost ?? 0) * (detail.quantity ?? 0)),
                returnQuantity: detail.quantity,
              ),
            )
            .toList();

        emit(
          state.copyWith(
            status: SalesReturnStatus.loaded,
            selectedHeader: returnHeader,
            createDetails: returnDetails,
            createItems: [returnHeader],
          ),
        );
      }
    } catch (e) {
      emit(state.errorState('Failed to load sales order for return: $e'));
      if (kDebugMode) {
        developer.log('Sales Return State: ${state.status} $e');
      }
    }
    if (kDebugMode) {
      developer.log('Sales Return State: ${state.status} ');
    }
  }

  // Header CRUD Operations
  Future<void> _onCreateSalesReturnHeader(
    CreateSalesReturnHeader event,
    Emitter<SalesReturnState> emit,
  ) async {
    emit(state.processingState());

    try {
      final id = await repository.createSalesReturnHeader(event.header);
      final createdHeader = event.header.copyWith(id: id);

      final updatedHeaders = [createdHeader, ...state.headers];

      emit(
        state
            .successState('Sales return created successfully')
            .copyWith(
              headers: updatedHeaders,
              filteredHeaders: updatedHeaders,
              selectedHeader: createdHeader,
            ),
      );
    } catch (e) {
      emit(state.errorState('Failed to create sales return: $e'));
    }
  }

  Future<void> _onUpdateSalesReturnHeader(
    UpdateSalesReturnHeader event,
    Emitter<SalesReturnState> emit,
  ) async {
    emit(state.processingState());

    try {
      await repository.updateSalesReturnHeader(event.header);

      final updatedHeaders = state.headers
          .map((h) => h.id == event.header.id ? event.header : h)
          .toList();

      emit(
        state
            .successState('Sales return updated successfully')
            .copyWith(
              headers: updatedHeaders,
              filteredHeaders: updatedHeaders,
              selectedHeader: event.header,
            ),
      );
    } catch (e) {
      emit(state.errorState('Failed to update sales return: $e'));
    }
  }

  Future<void> _onDeleteSalesReturnHeader(
    DeleteSalesReturnHeader event,
    Emitter<SalesReturnState> emit,
  ) async {
    emit(state.processingState());

    try {
      await repository.deleteSalesReturnHeader(event.id);

      final updatedHeaders = state.headers
          .where((h) => h.id != event.id)
          .toList();

      emit(
        state
            .successState('Sales return deleted successfully')
            .copyWith(
              headers: updatedHeaders,
              filteredHeaders: updatedHeaders,
              selectedHeader: state.selectedHeader?.id == event.id
                  ? null
                  : state.selectedHeader,
            ),
      );
    } catch (e) {
      emit(state.errorState('Failed to delete sales return: $e'));
    }
  }

  Future<void> _onVoidSalesReturn(
    VoidSalesReturn event,
    Emitter<SalesReturnState> emit,
  ) async {
    emit(state.processingState());

    try {
      await repository.voidSalesReturn(event.id, event.voidIndicator);

      final updatedHeaders = state.headers.map((h) {
        if (h.id == event.id) {
          return h.copyWith(voidIndicator: event.voidIndicator);
        }
        return h;
      }).toList();

      emit(
        state
            .successState('Sales return voided successfully')
            .copyWith(headers: updatedHeaders, filteredHeaders: updatedHeaders),
      );
    } catch (e) {
      emit(state.errorState('Failed to void sales return: $e'));
    }
  }

  // Detail Operations
  void _onAddSalesReturnDetail(
    AddSalesReturnDetail event,
    Emitter<SalesReturnState> emit,
  ) {
    final newDetail = event.detail.copyWith(
      tempId: _getNextTempId(state.createDetails),
    );

    final updatedDetails = [...state.createDetails, newDetail];

    emit(
      state.copyWith(createDetails: updatedDetails, selectedDetail: newDetail),
    );
  }

  void _onUpdateSalesReturnDetail(
    UpdateSalesReturnDetail event,
    Emitter<SalesReturnState> emit,
  ) {
    final updatedDetails = state.createDetails
        .map((d) => d.tempId == event.detail.tempId ? event.detail : d)
        .toList();

    emit(
      state.copyWith(
        createDetails: updatedDetails,
        selectedDetail: event.detail,
      ),
    );
  }

  void _onRemoveSalesReturnDetail(
    RemoveSalesReturnDetail event,
    Emitter<SalesReturnState> emit,
  ) {
    final updatedDetails = state.createDetails
        .where((d) => d.tempId != event.detail.tempId)
        .toList();

    emit(state.copyWith(createDetails: updatedDetails));
  }

  Future<void> _onSaveAllSalesReturnDetails(
    SaveAllSalesReturnDetails event,
    Emitter<SalesReturnState> emit,
  ) async {
    emit(state.processingState());

    try {
      await repository.createSalesReturnDetailsBatch(event.details);

      emit(
        state
            .successState('Sales return details saved successfully')
            .copyWith(createDetails: const []),
      );
    } catch (e) {
      //emit(state.errorState('Failed to save sales return details: $e'));
      if (kDebugMode) {
        developer.log('Failed to save sales return details: $e');
      }
    }
  }

  // UI State Management
  Future<void> _onPrepareCreateSalesReturn(
    PrepareCreateSalesReturn event,
    Emitter<SalesReturnState> emit,
  ) async {
    try {
      final nextOrderNumber = await repository.getNextOrderNumber(
        event.companyId,
      );
      final nextFsNumber = await repository.generateNextFsNumber(
        event.companyId,
        event.branchId,
      );

      final newHeader = SalesReturnHeader(
        orderDate: DateTime.now(),
        returnDate: DateTime.now(),
        customerBillTo: 0,
        customerTableId: 0,
        employeesId: event.employeeId,
        company: event.companyId,
        tempId: _getNextTempId(state.createItems),
        orderNumber: nextOrderNumber,
        paymentMethod: 'Cash',
        fsNumber: nextFsNumber,
        tax: 0.0,
        withholdAmount: 0.0,
        discountAmount: 0.0,
      );

      emit(
        state.copyWith(
          status: SalesReturnStatus.loaded,
          createItems: [newHeader],
          selectedHeader: newHeader,
          createDetails: const [],
          paymentType: 'Cash',
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to prepare sales return: $e'));
    }
  }

  void _onSetSelectedHeader(
    SetSelectedHeader event,
    Emitter<SalesReturnState> emit,
  ) {
    emit(state.copyWith(selectedHeader: event.header));
  }

  void _onSetSelectedDetail(
    SetSelectedDetail event,
    Emitter<SalesReturnState> emit,
  ) {
    emit(state.copyWith(selectedDetail: event.detail));
  }

  // Financial Calculations
  Future<void> _onCalculateReturnTotals(
    CalculateReturnTotals event,
    Emitter<SalesReturnState> emit,
  ) async {
    try {
      final systemConstants = systemConstantBloc.state.selected;
      final decimalPlaces = systemConstants?.decimalPlaces ?? 2;

      double subTotal = 0.0;
      double taxableAmount = 0.0;

      for (final detail in event.details) {
        final extendedPrice = detail.extendedPrice ?? 0.0;
        subTotal += extendedPrice;

        // Check if item is taxable
        if (detail.taxable == 'Y') {
          taxableAmount += extendedPrice;
        }
      }

      // Calculate VAT
      final vatRate = (systemConstants?.rateVatPercentage ?? 0.0) / 100.0;
      final tax = taxableAmount * vatRate;

      // Calculate withholding tax
      double withholdAmount = 0.0;
      if (event.applyWithholding) {
        final withHoldRate =
            (systemConstants?.rateWithholdingPercentage ?? 0.0) / 100.0;
        final withHoldInitials = systemConstants?.withHoldInitials ?? 0.0;

        if (subTotal >= withHoldInitials) {
          withholdAmount = subTotal * withHoldRate;
        }
      }

      // Calculate total amount
      final totalAmount =
          subTotal + tax - withholdAmount - event.discountAmount;

      emit(
        state.copyWith(
          subTotal: subTotal,
          tax: tax,
          withholdAmount: withholdAmount,
          totalAmount: totalAmount,
          discountAmount: event.discountAmount,
          applyWH: event.applyWithholding,
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to calculate totals: $e'));
    }
  }

  void _onCalculateExtendedPrice(
    CalculateExtendedPrice event,
    Emitter<SalesReturnState> emit,
  ) {
    final unitPrice = event.detail.unitPrice ?? 0;
    final quantity = event.detail.quantity ?? 0;
    final extendedPrice = unitPrice * quantity;

    final updatedDetail = event.detail.copyWith(extendedPrice: extendedPrice);

    // Update in create details
    final detailIndex = state.createDetails.indexWhere(
      (d) => d.tempId == updatedDetail.tempId,
    );

    if (detailIndex != -1) {
      add(UpdateSalesReturnDetail(detail: updatedDetail));
    }
  }

  // Return Submission
  Future<void> _onSubmitSalesReturn(
    SubmitSalesReturn event,
    Emitter<SalesReturnState> emit,
  ) async {
    emit(state.processingState());

    try {
      // Validate return reason (like Java version)
      if (event.header.returnStatus == null) {
        throw Exception('Return reason must be provided');
      }
      // Find original sales order by FS number (like Java version)
      final originalSalesOrder = await salesOrderHeaderRepository
          .getSalesOrderByFsNumberAndInvoiceNumber(
            event.header.fsNumber!,
            authBloc.state.companyId!,
          );

      if (originalSalesOrder == null) {
        emit(state.errorState('Original sales order not found'));
        return;
      }

      // Generate reference note (like Java's generateReferenceNote3)
      final newRefNote3 = await repository.generateReferenceNote3(
        event.header.company ?? authBloc.state.companyId!,
      );

      // Set return date if not set and merge missing original order data
      final returnHeaderWithRef = event.header.copyWith(
        referenceNote3: newRefNote3,
        returnDate: event.header.returnDate ?? DateTime.now(),
        // Ensure robust data saving from original order if missing in event
        paymentMethod:
            event.header.paymentMethod ?? originalSalesOrder.paymentMethod,
        paymentInstrument:
            event.header.paymentInstrument ??
            originalSalesOrder.paymentInstrument,
        orderNumber: event.header.orderNumber ?? originalSalesOrder.orderNumber,
        orderType: event.header.orderType ?? originalSalesOrder.orderType,
        amountOpen: event.header.amountOpen ?? originalSalesOrder.amountOpen,
        unitCost: event.header.unitCost ?? originalSalesOrder.unitCost,
        amountCost: event.header.amountCost ?? originalSalesOrder.amountCost,
      );

      // Create return header
      final headerId = await repository.createSalesReturnHeader(
        returnHeaderWithRef,
      );
      final createdHeader = returnHeaderWithRef.copyWith(id: headerId);

      // Update details with header ID and save
      final detailsWithHeader = event.details
          .map((detail) => detail.copyWith(salesReturnHeaderId: headerId))
          .toList();

      await repository.createSalesReturnDetailsBatch(detailsWithHeader);

      // 🎯 PROCESS RETURN THROUGH SERVICE (like Java's returnSubmission)
      await salesReturnStockService.processSalesReturnSubmission(
        returnHeader: returnHeaderWithRef,
        returnDetails: detailsWithHeader,
        originalSalesOrder: originalSalesOrder,
        companyId: authBloc.state.companyId!,
      );
      emit(
        state
            .successState('Sales return submitted successfully')
            .copyWith(
              selectedHeader: createdHeader,
              createItems: const [],
              createDetails: const [],
            ),
      );

      // add(RefreshSalesReturns(companyId: authBloc.state.companyId ?? 0));
    } catch (e) {
      emit(state.errorState('Failed to submit sales return: $e'));
    }
  }

  // Search & Filter
  void _onSearchSalesReturns(
    SearchSalesReturns event,
    Emitter<SalesReturnState> emit,
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

  Future<void> _onFilterSalesReturns(
    FilterSalesReturns event,
    Emitter<SalesReturnState> emit,
  ) async {
    emit(state.loadingState());

    try {
      final filtered = await repository.filterSalesReturns(
        companyId: event.companyId,
        fsNumber: event.fsNumber,
        startDate: event.startDate,
        endDate: event.endDate,
      );

      emit(
        state.copyWith(
          status: SalesReturnStatus.loaded,
          filteredHeaders: filtered,
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to filter sales returns: $e'));
    }
  }

  // Utility Methods
  Future<void> _onRefreshSalesReturns(
    RefreshSalesReturns event,
    Emitter<SalesReturnState> emit,
  ) async {
    add(LoadSalesReturns(companyId: event.companyId));
  }

  void _onResetSalesReturnState(
    ResetSalesReturnState event,
    Emitter<SalesReturnState> emit,
  ) {
    emit(const SalesReturnState());
  }

  // Helper Methods
  int _getNextTempId(List<dynamic> items) {
    if (items.isEmpty) return 1;
    final maxTempId = items
        .map((e) => (e as dynamic).tempId ?? 0)
        .reduce((a, b) => a > b ? a : b);
    return maxTempId + 1;
  }
}
