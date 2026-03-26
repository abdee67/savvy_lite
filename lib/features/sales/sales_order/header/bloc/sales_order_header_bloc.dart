// bloc/sales_order_header_bloc.dart
import 'dart:async';
import 'dart:developer' as developer;
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:savvy_stock/features/sales/sales_order/detail/model/sales_order_detail.dart';
import 'package:savvy_stock/features/sales/sales_order/header/model/aged_credit_receipt_totals_mode.dart';
import 'package:savvy_stock/features/sales/sales_order/header/model/credit_receipt_model.dart';
import 'package:savvy_stock/features/sales/sales_order/header/model/sales_transaction_filtering_model.dart';
import 'package:savvy_stock/features/sales/sales_order/header/repo/sales_order_report_repo.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_state.dart';
import 'package:savvy_stock/core/repositories/udc_repository.dart';
import 'package:savvy_stock/features/admin/employees/repo/employees_repo.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/sales/customer/repo/customer_repo.dart';
import 'package:savvy_stock/features/stock/item_in_branch/repo/item_in_branch_repo.dart';
import 'package:savvy_stock/features/stock/item_uom_conversions/repo/item_uom_conv_repo.dart';
import 'package:savvy_stock/features/sales/sales_order/header/bloc/sales_order_header_event.dart';
import 'package:savvy_stock/features/sales/sales_order/header/bloc/sales_order_header_state.dart';
import 'package:savvy_stock/features/sales/sales_order/header/model/sales_order_header.dart';
import 'package:savvy_stock/features/sales/sales_order/header/model/sales_transaction_report_totals.dart';
import 'package:savvy_stock/features/sales/sales_order/header/repo/sales_order_header_repo.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_bloc.dart';
import 'package:savvy_stock/features/udc_detail/models/udc_details.dart';

class SalesOrderHeaderBloc
    extends Bloc<SalesOrderHeaderEvent, SalesOrderHeaderState> {
  final SalesOrderHeaderRepository repository;
  final AuthBloc authBloc;
  final SystemConstantBloc systemConstantBloc;
  final UdcRepository udcDetailRepository;
  final CustomerRepository customerRepository;
  final EmployeeRepository employeesRepository;
  final ItemUomConversionsRepository uomConversionsRepository;
  final StockItemInBranchRepository itemInBranchRepository;
  final SalesOrderReportRepository salesOrderReportRepository;

  StreamSubscription? _authSubscription;
  StreamSubscription? _systemConstantsSubscription;
  StreamSubscription? _udcDetailSubscription;
  StreamSubscription? _customerSubscription;
  StreamSubscription? _employeesSubscription;

  SalesOrderHeaderBloc({
    required this.repository,
    required this.authBloc,
    required this.systemConstantBloc,
    required this.customerRepository,
    required this.employeesRepository,
    required this.udcDetailRepository,
    required this.uomConversionsRepository,
    required this.itemInBranchRepository,
    required this.salesOrderReportRepository,
  }) : super(const SalesOrderHeaderState()) {
    // Listen to authentication state
    _authSubscription = authBloc.stream.listen((authState) {
      if (authState.isAuthenticated &&
          authState.companyId != null &&
          authState.userId != null) {
        add(
          SalesOrderHeaderInitialized(
            companyId: authState.companyId!,
            employeeId: authState.userId!.id,
          ),
        );
      }
    });

    // Listen to system constants changes
    _systemConstantsSubscription = systemConstantBloc.stream.listen((
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
    // Event handlers
    on<SalesOrderHeaderInitialized>(_onInitialized);
    on<SystemConstantsUpdated>(_onSystemConstantsUpdated);
    on<LoadSalesOrderHeaders>(_onLoadSalesOrderHeaders);
    on<LoadCreditSalesOrders>(_onLoadCreditSalesOrders);
    on<LoadVoidedSalesOrders>(_onLoadVoidedSalesOrders);
    on<CreateSalesOrderHeader>(_onCreateSalesOrderHeader);
    on<UpdateSalesOrderHeader>(_onUpdateSalesOrderHeader);
    on<DeleteSalesOrderHeader>(_onDeleteSalesOrderHeader);
    on<DeleteMultipleSalesOrders>(_onDeleteMultipleSalesOrders);
    on<VoidSalesOrder>(_onVoidSalesOrder);
    on<UnvoidSalesOrder>(_onUnvoidSalesOrder);
    on<SaveSalesOrder>(_onSaveSalesOrder);

    // Selection Management
    on<SelectSalesOrder>(_onSelectSalesOrder);
    on<SelectMultipleSalesOrders>(_onSelectMultipleSalesOrders);
    on<ClearSelection>(_onClearSelection);

    // Filtering & Search
    on<FilterSalesOrders>(_onFilterSalesOrders);
    on<FilterCreditSalesOrders>(_onFilterCreditSalesOrders);
    on<FilterVoidedSalesOrders>(_onFilterVoidedSalesOrders);
    on<SearchSalesOrders>(_onSearchSalesOrders);
    on<ClearFilters>(_onClearFilters);
    on<UpdateDateFilters>(_onUpdateDateFilters);

    // Financial Calculations (Enhanced with System Constants)
    on<CalculateOrderTotals>(_onCalculateOrderTotals);
    on<CalculateCreditDueDate>(_onCalculateCreditDueDate);
    on<ApplyWithholdingTax>(_onApplyWithholdingTax);
    on<ApplyDiscount>(_onApplyDiscount);
    on<UpdateTaxSettings>(_onUpdateTaxSettings);

    // Customer Management
    on<UpdateCustomerInfo>(_onUpdateCustomerInfo);
    on<SetDefaultCustomer>(_onSetDefaultCustomer);

    // Payment & Workflow
    on<UpdatePaymentMethod>(_onUpdatePaymentMethod);
    on<UpdatePaymentStatus>(_onUpdatePaymentStatus);
    on<SetPaymentTerm>(_onSetPaymentTerm);

    // UI State Management
    on<PrepareCreateSalesOrderHeader>(_onPrepareCreate);
    on<PrepareCreateAfterCreate>(_onPrepareCreateAfterCreate);
    on<PrepareEdit>(_onPrepareEdit);
    on<CancelUpdate>(_onCancelUpdate);
    on<CancelCreate>(_onCancelCreate);
    on<DiscardChanges>(_onDiscardChanges);

    // Utility
    on<GetNextOrderNumber>(_onGetNextOrderNumber);
    on<ConvertAmountToWords>(_onConvertAmountToWords);
    on<GenerateNextFsNumber>(_onGenerateNextFsNumber);
    on<RefreshSalesOrderHeaders>(_onRefreshSalesOrderHeaders);
    on<ExportSaleOrder>(_onExportTransactions);

    // In SalesOrderHeaderBloc constructor, add these:
    on<LoadCreditReceipts>(_onLoadCreditReceipts);
    on<PrepareCreditReceipt>(_onPrepareCreditReceipt);
    on<UpdateCreditReceipt>(_onUpdateCreditReceipt);
    on<SaveCreditReceipt>(_onSaveCreditReceipt);
    on<DeleteCreditReceipt>(_onDeleteCreditReceipt);
    on<SelectCreditReceipt>(_onSelectCreditReceipt);
    on<FilterCreditReceipts>(_onFilterCreditReceipts);
    on<ClearCreditReceiptFilters>(_onClearCreditReceiptFilters);
    on<LoadMoreCreditReceiptsReport>(_onLoadMoreCreditReceiptsReport);
    on<UpdateCreditReceiptReportFilters>(_onUpdateCreditReceiptReportFilters);
    on<ClearCreditReceiptsReportFilters>(_onClearCreditReceiptsReportFilters);
    on<ExportCreditReceiptReportToExcel>(_onExportCreditReceiptReportToExcel);
    on<ExportCreditReceiptReportToPDF>(_onExportCreditReceiptReportToPDF);
    on<LoadCreditReceiptsReport>(_onLoadCreditReceiptsReport);

    // Sales Transaction Report
    on<LoadSalesTransactionReport>(_onLoadSalesTransactionReport);
    on<LoadMoreSalesTransactionReport>(_onLoadMoreSalesTransactionReport);
    on<UpdateSalesTransactionFilters>(_onUpdateSalesTransactionFilters);
    on<ClearSalesTransactionFilters>(_onClearSalesTransactionFilters);
    on<ExportSalesTransactionToExcel>(_onExportSalesTransactionToExcel);
    on<ExportSalesTransactionToPDF>(_onExportSalesTransactionToPDF);

    // Aged Credit Receipt Report
    on<LoadAgedCreditReceiptReport>(_onLoadAgedCreditReceiptReport);
    on<LoadMoreAgedCreditReceiptReport>(_onLoadMoreAgedCreditReceiptReport);
    on<UpdateAgedCreditReceiptReportFilters>(_onUpdateAgedCreditReceiptFilters);
    on<ClearAgedCreditReceiptReportFilters>(_onClearAgedCreditReceiptFilters);
    on<ExportAgedCreditReceiptReportToExcel>(_onExportAgedCreditReceiptToExcel);
    on<ExportAgedCreditReceiptReportToPDF>(_onExportAgedCreditReceiptToPDF);
  }
  @override
  Future<void> close() {
    _authSubscription?.cancel();
    _systemConstantsSubscription?.cancel();
    _udcDetailSubscription?.cancel();
    _customerSubscription?.cancel();
    _employeesSubscription?.cancel();
    return super.close();
  }

  // Initialization
  Future<void> _onInitialized(
    SalesOrderHeaderInitialized event,
    Emitter<SalesOrderHeaderState> emit,
  ) async {
    emit(
      state.copyWith(
        companyId: event.companyId,
        status: SalesOrderHeaderStatus.loading,
      ),
    );

    // Ensure system constants are loaded
    await systemConstantBloc.systemConstantService.ensureLoaded();

    // Load initial data
    add(LoadSalesOrderHeaders(companyId: event.companyId));
    add(GetNextOrderNumber(companyId: event.companyId));
  }

  Future<void> _onSystemConstantsUpdated(
    SystemConstantsUpdated event,
    Emitter<SalesOrderHeaderState> emit,
  ) async {
    emit(state.copyWith(systemConstants: event.systemConstants));

    /*// Recalculate totals if we have existing data
    if (state.selected != null && state.salesOrderDetail!.isNotEmpty) {
      add(
        CalculateOrderTotals(
          header: state.selected!,
          orderDetails: state.salesOrderDetail!,
          applyWithholding: state.applyWithholding,
          discountAmount: state.discountAmount,
        ),
      );
    }*/
  }

  // Enhanced Financial Calculations using System Constants
  Future<void> _onCalculateOrderTotals(
    CalculateOrderTotals event,
    Emitter<SalesOrderHeaderState> emit,
  ) async {
    try {
      emit(state.copyWith(status: SalesOrderHeaderStatus.calculating));

      // Use system constants service for tax calculations
      final systemConstants =
          systemConstantBloc.systemConstantService.currentSystemConstant;

      // Get decimal places from system constants (like Java)
      final decimalPlaces = systemConstants?.decimalPlaces ?? 2;

      double subTotal = 0.0;
      double taxableAmount = 0.0;

      // Calculate subtotal and taxable amount (equivalent to Java's calQtyWithAmt)
      for (final detail in event.orderDetails) {
        // Rely on each line's extendedPrice already including any UOM
        // conversion done by the detail bloc/repositories.
        final extendedPrice = detail.extendedPrice ?? 0.0;

        subTotal += extendedPrice;

        // Check if item is taxable (like Java's item.getItemsTableId().getTaxableBoolean())
        // Use detail.taxable as fallback if detail.item is not populated
        final isTaxable = detail.item?.taxable == 'Y' || detail.taxable == 'Y';
        if (isTaxable) {
          taxableAmount += extendedPrice;
        }
      }

      // Round subtotal with system constant decimal places
      final roundedSubTotal = systemConstantBloc.systemConstantService
          .roundToDecimalPlaces(subTotal, decimalPlaces);

      // Calculate VAT/Tax using system constants (like Java)
      final tax = systemConstantBloc.systemConstantService.calculateTaxAmount(
        taxableAmount,
      );

      // Calculate withholding tax using system constants (like Java)
      double withholdAmount = 0.0;
      if (event.applyWithholding) {
        withholdAmount = systemConstantBloc.systemConstantService
            .calculateWithholdingAmount(roundedSubTotal);
      }

      // Calculate total amount (like Java's bdTotal calculation)
      final discountAmount = event.discountAmount;
      final totalAmount = systemConstantBloc.systemConstantService
          .roundToDecimalPlaces(
            roundedSubTotal + tax - withholdAmount - discountAmount,
            decimalPlaces,
          );

      final amountOpen = totalAmount - discountAmount;

      emit(
        state.copyWith(
          status: SalesOrderHeaderStatus.loaded,
          subTotal: roundedSubTotal,
          tax: tax,
          withholdAmount: withholdAmount,
          totalAmount: totalAmount,
          amountOpen: amountOpen,
          discountAmount: discountAmount,
          applyWH: event.applyWithholding,
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to calculate order totals: $e'));
    }
  }

  // Enhanced Customer Management with System Constants Integration
  Future<void> _onUpdateCustomerInfo(
    UpdateCustomerInfo event,
    Emitter<SalesOrderHeaderState> emit,
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

        emit(updatedState.copyWith(selected: updatedHeader));
      } else {
        emit(updatedState);
      }
    } catch (e) {
      emit(state.errorState('Failed to update customer info: $e'));
    }
  }

  Future<void> _onLoadSalesOrderHeaders(
    LoadSalesOrderHeaders event,
    Emitter<SalesOrderHeaderState> emit,
  ) async {
    try {
      emit(state.loadingState());

      final headers = await repository.getSalesOrderHeaders(
        companyId: event.companyId,
        startDate: state.effectiveDateOrderStart,
        endDate: state.effectiveDateOrderEnd,
        includeVoided: false,
      );

      emit(
        state.copyWith(
          status: SalesOrderHeaderStatus.loaded,
          headers: headers,
          filteredHeaders: headers,
          companyId: event.companyId,
          error: null,
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to load sales orders: $e'));
    }
  }

  Future<void> _onLoadCreditSalesOrders(
    LoadCreditSalesOrders event,
    Emitter<SalesOrderHeaderState> emit,
  ) async {
    try {
      emit(state.processingState());

      final creditHeaders = await repository.getCreditSalesOrders(
        event.companyId,
      );

      emit(
        state.copyWith(
          status: SalesOrderHeaderStatus.loaded,
          creditHeaders: creditHeaders,
          error: null,
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to load credit sales orders: $e'));
    }
  }

  Future<void> _onLoadVoidedSalesOrders(
    LoadVoidedSalesOrders event,
    Emitter<SalesOrderHeaderState> emit,
  ) async {
    try {
      emit(state.processingState());

      final voidedHeaders = await repository.filterVoidedSalesOrders(
        companyId: event.companyId,
        customerBillTo: event.customerBillTo,
        fsNumber: event.fsNumber,
      );

      emit(
        state.copyWith(
          status: SalesOrderHeaderStatus.loaded,
          voidedHeaders: voidedHeaders,
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to load voided sales orders: $e'));
    }
  }

  Future<void> _onCreateSalesOrderHeader(
    CreateSalesOrderHeader event,
    Emitter<SalesOrderHeaderState> emit,
  ) async {
    try {
      emit(state.loadingState());

      // Get next order number
      final nextOrderNumber = await repository.getNextOrderNumber(
        event.header.company!,
      );

      // Process header with business logic
      var headerToCreate = event.header.copyWith(orderNumber: nextOrderNumber);

      // Ensure branchValue is set
      final branchId =
          headerToCreate.branchValue ?? authBloc.state.branchId ?? 1;
      headerToCreate = headerToCreate.copyWith(branchValue: branchId);

      // Generate FS Number if missing (e.g. during conversion)
      if (headerToCreate.fsNumber == null || headerToCreate.fsNumber!.isEmpty) {
        final nextFsNumber = await repository.generateNextFsNumber(
          headerToCreate.company!,
          branchId,
        );
        headerToCreate = headerToCreate.copyWith(fsNumber: nextFsNumber);
      }

      // Generate Invoice Number if missing (e.g. during conversion)
      if (headerToCreate.invoiceNumber == null ||
          headerToCreate.invoiceNumber!.isEmpty) {
        final nextInvoiceNumber = await repository.generateInvoiceNumber(
          headerToCreate.company!,
          branchId,
          'sales_order_header',
        );
        headerToCreate = headerToCreate.copyWith(
          invoiceNumber: nextInvoiceNumber,
        );
      }

      final processedHeader = await _processHeaderBusinessLogic(headerToCreate);

      final id = await repository.createSalesOrderHeader(processedHeader);
      final createdHeader = processedHeader.copyWith(id: id);

      // Update state
      final updatedHeaders = [createdHeader, ...state.headers];
      final updatedCreateItems = state.createItems
          .where((item) => item.tempId != createdHeader.tempId)
          .toList();

      emit(
        state.copyWith(
          status: SalesOrderHeaderStatus.success,
          headers: updatedHeaders,
          filteredHeaders: updatedHeaders,
          createItems: updatedCreateItems,
          selected: createdHeader,
          nextOrderNumber: nextOrderNumber + 1,
          successmessage: 'Sales order created successfully',
        ),
      );
    } catch (e) {
      // emit(state.errorState('Failed to create sales order: $e'));
      if (kDebugMode) {
        developer.log('Failed to create sales order: $e');
      }
    }
  }

  Future<SalesOrderHeader> _processHeaderBusinessLogic(
    SalesOrderHeader header,
  ) async {
    // Set default values from system constants
    var processedHeader = header.copyWith(
      tax: header.tax ?? 0.0,
      withholdAmount: header.withholdAmount ?? 0.0,
      discountAmount: header.discountAmount ?? 0.0,
    );

    // Handle credit sales logic
    if (header.paymentTerm != null) {
      final dueDate = await _calculateCreditDueDate(
        header.paymentTerm!,
        header.orderDate!,
      );
      final orderType = await udcDetailRepository.getSingleUdcDetailsByCode(
        'SO',
        "OT",
      );

      final discount = header.discountAmount ?? 0.0;
      final total = header.amountTotal ?? 0.0;
      final openAmount = total - discount;

      processedHeader = processedHeader.copyWith(
        //creditDateToPay: dueDate,
        amountOpen: openAmount,
        orderType: orderType?.id,
      );
    }

    return processedHeader;
  }

  Future<void> _onUpdateSalesOrderHeader(
    UpdateSalesOrderHeader event,
    Emitter<SalesOrderHeaderState> emit,
  ) async {
    try {
      emit(state.loadingState());

      await repository.updateSalesOrderHeader(event.header);

      // Update the header in the lists
      final updatedHeaders = state.headers
          .map((h) => h.id == event.header.id ? event.header : h)
          .toList();
      final updatedEditItems = state.editItems
          .where((item) => item.id != event.header.id)
          .toList();

      emit(
        state.copyWith(
          status: SalesOrderHeaderStatus.success,
          headers: updatedHeaders,
          filteredHeaders: updatedHeaders,
          editItems: updatedEditItems,
          selected: event.header,
          successmessage: 'Sales order updated successfully',
          error: null,
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to update sales order: $e'));
    }
  }

  Future<void> _onDeleteSalesOrderHeader(
    DeleteSalesOrderHeader event,
    Emitter<SalesOrderHeaderState> emit,
  ) async {
    try {
      emit(state.copyWith(status: SalesOrderHeaderStatus.deleting));

      await repository.deleteSalesOrderHeader(event.id);

      final updatedHeaders = state.headers
          .where((h) => h.id != event.id)
          .toList();
      final updatedFilteredHeaders = state.filteredHeaders
          .where((h) => h.id != event.id)
          .toList();

      emit(
        state.copyWith(
          status: SalesOrderHeaderStatus.success,
          headers: updatedHeaders,
          filteredHeaders: updatedFilteredHeaders,
          selected: state.selected?.id == event.id ? null : state.selected,
          successmessage: 'Sales order deleted successfully',
          error: null,
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to delete sales order: $e'));
    }
  }

  Future<void> _onVoidSalesOrder(
    VoidSalesOrder event,
    Emitter<SalesOrderHeaderState> emit,
  ) async {
    try {
      emit(state.copyWith(status: SalesOrderHeaderStatus.voiding));
      // Void in repository
      await repository.voidSalesOrder(
        event.id,
        event.voidIndicator,
        commentIfVoid: event.commentIfVoid,
      );

      // Update local state
      final updatedHeaders = state.headers.map((h) {
        if (h.id == event.id) {
          return h.copyWith(
            voidIndicator: event.voidIndicator,
            commentIfVoid: event.commentIfVoid,
          );
        }
        return h;
      }).toList();

      final updatedFilteredHeaders = state.filteredHeaders.map((h) {
        if (h.id == event.id) {
          return h.copyWith(voidIndicator: 'V');
        }
        return h;
      }).toList();

      emit(
        state.copyWith(
          status: SalesOrderHeaderStatus.success,
          headers: updatedHeaders,
          filteredHeaders: updatedFilteredHeaders,
          selected: state.selected?.id == event.id
              ? state.selected!.copyWith(voidIndicator: 'V')
              : state.selected,
          successmessage: 'Sales order voided successfully',
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to void sales order: $e'));
    }
  }

  Future<void> _onUnvoidSalesOrder(
    UnvoidSalesOrder event,
    Emitter<SalesOrderHeaderState> emit,
  ) async {
    try {
      emit(state.copyWith(status: SalesOrderHeaderStatus.voiding));

      await repository.voidSalesOrder(event.id, 'Unvoided');

      final updatedHeaders = state.headers.map((h) {
        if (h.id == event.id) {
          return h.copyWith(voidIndicator: null);
        }
        return h;
      }).toList();

      final updatedFilteredHeaders = state.filteredHeaders.map((h) {
        if (h.id == event.id) {
          return h.copyWith(voidIndicator: null);
        }
        return h;
      }).toList();

      emit(
        state.copyWith(
          status: SalesOrderHeaderStatus.success,
          headers: updatedHeaders,
          filteredHeaders: updatedFilteredHeaders,
          selected: state.selected?.id == event.id
              ? state.selected!.copyWith(voidIndicator: null)
              : state.selected,
          successmessage: 'Sales order unvoided successfully',
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to unvoid sales order: $e'));
    }
  }

  Future<void> _onDeleteMultipleSalesOrders(
    DeleteMultipleSalesOrders event,
    Emitter<SalesOrderHeaderState> emit,
  ) async {
    try {
      emit(state.copyWith(status: SalesOrderHeaderStatus.deleting));

      for (final header in event.headers) {
        if (header.id != null) {
          await repository.deleteSalesOrderHeader(header.id!);
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
          status: SalesOrderHeaderStatus.success,
          headers: updatedHeaders,
          filteredHeaders: updatedFilteredHeaders,
          multiselectionItems: const [],
          successmessage:
              '${event.headers.length} sales orders deleted successfully',
          error: null,
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to delete sales orders: $e'));
    }
  }

  void _onSelectSalesOrder(
    SelectSalesOrder event,
    Emitter<SalesOrderHeaderState> emit,
  ) {
    emit(state.copyWith(selected: event.header, selected1: event.header));
  }

  void _onSelectMultipleSalesOrders(
    SelectMultipleSalesOrders event,
    Emitter<SalesOrderHeaderState> emit,
  ) {
    emit(
      state.copyWith(
        multiselectionItems: event.headers,
        isSelectionMode: event.headers.isNotEmpty,
      ),
    );
  }

  void _onClearSelection(
    ClearSelection event,
    Emitter<SalesOrderHeaderState> emit,
  ) {
    emit(
      state.copyWith(
        selectedItems: const [],
        multiselectionItems: const [],
        isSelectionMode: false,
      ),
    );
  }

  Future<void> _onFilterSalesOrders(
    FilterSalesOrders event,
    Emitter<SalesOrderHeaderState> emit,
  ) async {
    try {
      emit(state.copyWith(status: SalesOrderHeaderStatus.filtering));

      final filteredHeaders = await repository.getSalesOrdersWithDateRange(
        companyId: state.companyId ?? authBloc.state.companyId!,
        customerBillTo: event.filter.customerBillTo,
        fsNumber: event.filter.fsNumber,
        proformaReference: event.filter.fsNumber, //this is proformaReference
        startDate: event.startDate ?? state.dateOrderStart,
        endDate: event.endDate ?? state.dateOrderEnd,
        includeVoided: false,
      );

      emit(
        state.copyWith(
          status: SalesOrderHeaderStatus.loaded,
          filteredHeaders: filteredHeaders,
          selected3: event.filter,
          dateOrderStart: event.startDate,
          dateOrderEnd: event.endDate,
          error: null,
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to filter sales orders: $e'));
    }
  }

  Future<void> _onFilterCreditSalesOrders(
    FilterCreditSalesOrders event,
    Emitter<SalesOrderHeaderState> emit,
  ) async {
    try {
      emit(state.copyWith(status: SalesOrderHeaderStatus.filtering));

      final creditHeaders = await repository.getCreditSalesWithOpenAmount(
        companyId: state.companyId ?? authBloc.state.companyId!,
        minOpenAmount: event.filter.amountOpen,
      );

      emit(
        state.copyWith(
          status: SalesOrderHeaderStatus.loaded,
          creditHeaders: creditHeaders,
          selected2: event.filter,
          dateForCreditFrom: event.startDate,
          dateForCreditTo: event.endDate,
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to filter credit sales orders: $e'));
    }
  }

  Future<void> _onFilterVoidedSalesOrders(
    FilterVoidedSalesOrders event,
    Emitter<SalesOrderHeaderState> emit,
  ) async {
    try {
      emit(state.copyWith(status: SalesOrderHeaderStatus.filtering));

      final voidedHeaders = await repository.getVoidedSalesOrders(
        state.companyId ?? authBloc.state.companyId!,
      );

      emit(
        state.copyWith(
          status: SalesOrderHeaderStatus.loaded,
          voidedHeaders: voidedHeaders,
          selected4: event.filter,
          dateOrderStart: event.startDate,
          dateOrderEnd: event.endDate,
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to filter voided sales orders: $e'));
    }
  }

  void _onSearchSalesOrders(
    SearchSalesOrders event,
    Emitter<SalesOrderHeaderState> emit,
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

  void _onClearFilters(
    ClearFilters event,
    Emitter<SalesOrderHeaderState> emit,
  ) {
    emit(state.clearFilters());
  }

  void _onUpdateDateFilters(
    UpdateDateFilters event,
    Emitter<SalesOrderHeaderState> emit,
  ) {
    emit(
      state.copyWith(
        dateOrderStart: event.startDate,
        dateOrderEnd: event.endDate,
      ),
    );
  }

  // UI State Management
  void _onCancelUpdate(
    CancelUpdate event,
    Emitter<SalesOrderHeaderState> emit,
  ) {
    emit(state.copyWith(selected1: null, editItems: const []));
  }

  void _onCancelCreate(
    CancelCreate event,
    Emitter<SalesOrderHeaderState> emit,
  ) {
    emit(state.copyWith(selected: null, createItems: const []));
  }

  void _onDiscardChanges(
    DiscardChanges event,
    Emitter<SalesOrderHeaderState> emit,
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
          selected: updatedCreateItems.isNotEmpty
              ? updatedCreateItems.first
              : null,
          successmessage: 'All unsaved records are removed',
        ),
      );
    } else {
      emit(state.copyWith(successmessage: 'No unsaved records to remove'));
    }
  }

  // Enhanced Void Processing with System Constants

  // Tax Settings Update with System Constants
  void _onUpdateTaxSettings(
    UpdateTaxSettings event,
    Emitter<SalesOrderHeaderState> emit,
  ) {
    // Recalculate totals when tax settings change
    if (state.salesOrderDetail?.isNotEmpty ?? false) {
      add(
        CalculateOrderTotals(
          header: state.selected!,
          orderDetails: state.salesOrderDetail!,
          applyWithholding: event.applyWithholding,
          discountAmount: state.discountAmount,
        ),
      );
    }
  }

  Future<void> _onGetNextOrderNumber(
    GetNextOrderNumber event,
    Emitter<SalesOrderHeaderState> emit,
  ) async {
    try {
      emit(state.processingState());

      final nextOrderNumber = await repository.getNextOrderNumber(
        event.companyId,
      );

      emit(
        state.copyWith(
          status: SalesOrderHeaderStatus.loaded,
          nextOrderNumber: nextOrderNumber,
          error: null,
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to get next order number: $e'));
    }
  }

  void _onConvertAmountToWords(
    ConvertAmountToWords event,
    Emitter<SalesOrderHeaderState> emit,
  ) {
    try {
      emit(state.copyWith(status: SalesOrderHeaderStatus.converting));

      final amountInWords = _convertAmountToWords(event.amount);

      emit(
        state.copyWith(
          status: SalesOrderHeaderStatus.loaded,
          amountInWords: amountInWords,
          error: null,
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to convert amount to words: $e'));
    }
  }

  Future<void> _onGenerateNextFsNumber(
    GenerateNextFsNumber event,
    Emitter<SalesOrderHeaderState> emit,
  ) async {
    try {
      emit(state.processingState());

      final nextFsNumber = await repository.generateNextFsNumber(
        event.companyId,
        event.branchId,
      );

      final updatedHeader = state.selected?.copyWith(fsNumber: nextFsNumber);

      emit(
        state.copyWith(
          status: SalesOrderHeaderStatus.loaded,
          selected: updatedHeader,
          fsNumber: nextFsNumber,
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to generate FS number: $e'));
    }
  }

  Future<void> _onRefreshSalesOrderHeaders(
    RefreshSalesOrderHeaders event,
    Emitter<SalesOrderHeaderState> emit,
  ) async {
    if (state.companyId != null) {
      add(
        LoadSalesOrderHeaders(
          companyId: state.companyId ?? authBloc.state.companyId!,
        ),
      );
    }
  }

  // Enhanced Create with System Constants Defaults
  Future<void> _onPrepareCreate(
    PrepareCreateSalesOrderHeader event,
    Emitter<SalesOrderHeaderState> emit,
  ) async {
    try {
      emit(state.copyWith(status: SalesOrderHeaderStatus.preparing));

      // Ensure system constants are loaded
      await systemConstantBloc.systemConstantService.ensureLoaded();

      final nextOrderNumber = await repository.getNextOrderNumber(
        event.companyId,
      );
      final nextFsNumber = await repository.generateNextFsNumber(
        event.companyId,
        event.branchId,
      );

      // Get default order type from UDC
      final defaultOrderType = await _getDefaultOrderType();

      // Generate invoice number using fs_table prefix/postfix
      final invoiceNumber = await repository.generateInvoiceNumber(
        event.companyId,
        event.branchId,
        'sales_order_header',
      );

      // Create new header with system constant defaults
      final newHeader = SalesOrderHeader(
        orderDate: DateTime.now(),
        customerBillTo: 0,
        customerTableId: 0,
        employeesId: event.employeeId,
        company: event.companyId,
        tempId: _getNextTempId(state.createItems),
        orderNumber: nextOrderNumber,
        paymentMethod: 'Cash',
        orderType: defaultOrderType?.id,
        fsNumber: nextFsNumber,
        invoiceNumber: invoiceNumber,
        branchValue: event.branchId,
        // Set default tax settings from system constants
        tax: 0.0,
        withholdAmount: 0.0,
        discountAmount: 0.0,
      );

      // Set default customer if available

      final defaultCustomer = await customerRepository.getDefaultCustomer(
        event.companyId,
      );
      if (defaultCustomer == null) {
        emit(
          state.copyWith(
            status: SalesOrderHeaderStatus.loaded,
            createItems: [newHeader],
            selected: newHeader,
            nextOrderNumber: nextOrderNumber,
            paymentMethod: 'Cash',
            applyWH: systemConstantBloc.systemConstantService
                .shouldApplyWithholding(0.0),
            defaultCustomer: state.defaultCustomer,
            successmessage:
                'header defaultCustomer: company=${event.companyId}, count=${defaultCustomer ?? 0}',
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: SalesOrderHeaderStatus.loaded,
            createItems: [newHeader],
            selected: newHeader,
            nextOrderNumber: nextOrderNumber,
            paymentMethod: 'Cash',
            applyWH: systemConstantBloc.systemConstantService
                .shouldApplyWithholding(0.0),
            defaultCustomer: defaultCustomer,
            successmessage:
                'header defaultCustomer: company=${event.companyId}, count=${defaultCustomer ?? 0}',
          ),
        );
        if (kDebugMode) {
          developer.log(
            'header defaultCustomer: company=${event.companyId}, count=${defaultCustomer ?? 0}',
          );
        }
        if (kDebugMode) {
          developer.log(
            'header company=${event.companyId}, Header=${newHeader.id}',
          );
        }
      }
    } catch (e) {
      emit(state.errorState('Failed to prepare create: $e'));
    }
  }

  Future<void> _onPrepareCreateAfterCreate(
    PrepareCreateAfterCreate event,
    Emitter<SalesOrderHeaderState> emit,
  ) async {
    try {
      emit(state.copyWith(status: SalesOrderHeaderStatus.preparing));

      final nextOrderNumber = await repository.getNextOrderNumber(
        event.companyId,
      );

      final newHeader = SalesOrderHeader(
        orderDate: DateTime.now(),
        customerBillTo: 0,
        customerTableId: 0,
        employeesId: event.employeeId,
        company: event.companyId,
        tempId: _getNextTempId(state.createItems),
        orderNumber: nextOrderNumber,
        paymentMethod: 'Cash',
      );

      emit(
        state.copyWith(
          status: SalesOrderHeaderStatus.loaded,
          createItems: [newHeader],
          selected: newHeader,
          nextOrderNumber: nextOrderNumber,
          paymentMethod: 'Cash',
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to prepare create after create: $e'));
    }
  }

  Future<void> _onPrepareEdit(
    PrepareEdit event,
    Emitter<SalesOrderHeaderState> emit,
  ) async {
    if (state.multiselectionItems.isEmpty) return;

    emit(
      state.copyWith(
        editItems: [state.multiselectionItems.first],
        selected: state.multiselectionItems.first,
      ),
    );
  }

  Future<void> _onSetDefaultCustomer(
    SetDefaultCustomer event,
    Emitter<SalesOrderHeaderState> emit,
  ) async {
    try {
      final defaultCustomer = await customerRepository.getDefaultCustomer(
        event.companyId,
      );
      //if defaultCustomer is not null, set defaultCustomer to first customer
      if (defaultCustomer != null) {
        add(
          UpdateCustomerInfo(
            customer: defaultCustomer,
            currentHeader: state.selected,
          ),
        );
      }
      //if defaultCustomer is null, set defaultCustomer to first customer
      if (defaultCustomer == null) {
        add(
          UpdateCustomerInfo(
            customer: state.defaultCustomer!,
            currentHeader: state.selected,
          ),
        );
      }
      emit(
        state.copyWith(
          status: SalesOrderHeaderStatus.loaded,
          selected: state.selected,
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to set customer: $e'));
    }
  }

  // Credit Management with System Constants Integration
  Future<void> _onCalculateCreditDueDate(
    CalculateCreditDueDate event,
    Emitter<SalesOrderHeaderState> emit,
  ) async {
    try {
      if (event.paymentTerm == null || event.orderDate == null) return;

      final dueDate = await _calculateCreditDueDate(
        event.paymentTerm!,
        event.orderDate!,
      );

      // Update payment status for credit sales
      final paymentStatus = await udcDetailRepository.getSingleUdcDetailsByCode(
        'N',
        "PS",
      ); // 'N' for Not Paid

      final updatedHeader = state.selected?.copyWith(
        creditDateToPay: dueDate,
        paymentStatus: paymentStatus?.id,
        paymentTerm: event.paymentTerm,
      );

      // Calculate open amount for credit sales
      if (updatedHeader != null) {
        final discount = updatedHeader.discountAmount ?? 0.0;
        final total = updatedHeader.amountTotal ?? 0.0;
        final openAmount = total - discount;

        final headerWithOpenAmount = updatedHeader.copyWith(
          amountOpen: openAmount,
        );

        emit(
          state.copyWith(selected: headerWithOpenAmount, dateOrderEnd: dueDate),
        );
      }
    } catch (e) {
      emit(state.errorState('Failed to calculate credit due date: $e'));
    }
  }

  Future<void> _onSaveSalesOrder(
    SaveSalesOrder event,
    Emitter<SalesOrderHeaderState> emit,
  ) async {
    try {
      emit(state.copyWith(status: SalesOrderHeaderStatus.saving));

      if (event.header.id == null) {
        add(CreateSalesOrderHeader(header: event.header));
      } else {
        add(UpdateSalesOrderHeader(header: event.header));
      }
    } catch (e) {
      //emit(state.errorState('Failed to save sales order: $e'));
      if (kDebugMode) {
        developer.log('Failed to save sales order: $e');
      }
    }
  }

  void _onUpdatePaymentMethod(
    UpdatePaymentMethod event,
    Emitter<SalesOrderHeaderState> emit,
  ) {
    emit(state.copyWith(paymentMethod: event.paymentMethod));

    // If switching to credit, ensure payment term is set
    if (event.paymentMethod == 'Credit' && state.selected != null) {
      // Trigger credit due date calculation
      add(
        CalculateCreditDueDate(
          paymentTerm: state.selected!.paymentTerm,
          orderDate: state.selected!.orderDate!,
        ),
      );
    }
  }

  void _onUpdatePaymentStatus(
    UpdatePaymentStatus event,
    Emitter<SalesOrderHeaderState> emit,
  ) {
    final updatedHeader = state.selected?.copyWith(
      paymentStatus: event.paymentStatusId,
    );
    emit(state.copyWith(selected: updatedHeader));
  }

  void _onSetPaymentTerm(
    SetPaymentTerm event,
    Emitter<SalesOrderHeaderState> emit,
  ) {
    final updatedHeader = state.selected?.copyWith(
      paymentTerm: event.paymentTermId,
    );
    emit(state.copyWith(selected: updatedHeader));

    // Calculate due date if order date is available
    if (updatedHeader?.orderDate != null) {
      add(
        CalculateCreditDueDate(
          paymentTerm: event.paymentTermId,
          orderDate: updatedHeader!.orderDate!,
        ),
      );
    }
  }

  void _onApplyWithholdingTax(
    ApplyWithholdingTax event,
    Emitter<SalesOrderHeaderState> emit,
  ) {
    emit(state.copyWith(applyWH: event.applyWithholding));

    // Recalculate totals if withholding tax changes
    if (state.selected != null &&
        state.salesOrderDetail != null &&
        state.salesOrderDetail!.isNotEmpty) {
      add(
        CalculateOrderTotals(
          header: state.selected!,
          orderDetails: state.salesOrderDetail!,
          applyWithholding: event.applyWithholding,
          discountAmount: state.discountAmount,
        ),
      );
    }
  }

  void _onApplyDiscount(
    ApplyDiscount event,
    Emitter<SalesOrderHeaderState> emit,
  ) {
    emit(state.copyWith(discountAmount: event.discountAmount));

    // Recalculate totals if discount changes
    if (state.selected != null &&
        state.salesOrderDetail != null &&
        state.salesOrderDetail!.isNotEmpty) {
      add(
        CalculateOrderTotals(
          header: state.selected!,
          orderDetails: state.salesOrderDetail!,
          applyWithholding: state.applyWH ?? false,
          discountAmount: event.discountAmount,
        ),
      );
    }
  }

  void _onExportTransactions(
    ExportSaleOrder event,
    Emitter<SalesOrderHeaderState> emit,
  ) {
    emit(state.copyWith(status: SalesOrderHeaderStatus.exporting));

    // Simulate export process
    Future.delayed(const Duration(seconds: 2), () {
      emit(
        state.copyWith(
          status: SalesOrderHeaderStatus.success,
          exportedSales: event.salesOrder,
          successmessage: 'Exported ${event.salesOrder} sales successfully',
        ),
      );
    });
  }

  // Add these methods to SalesOrderHeaderBloc class:

  // ============ CREDIT RECEIPT OPERATIONS ============

  Future<void> _onLoadCreditReceipts(
    LoadCreditReceipts event,
    Emitter<SalesOrderHeaderState> emit,
  ) async {
    try {
      emit(state.copyWith(status: SalesOrderHeaderStatus.loading));

      final receipts = await repository.getCreditReceipts(
        companyId: event.companyId,
        soHeaderId: event.soHeaderId,
        startDate: event.startDate,
        endDate: event.endDate,
      );

      emit(
        state.copyWith(
          status: SalesOrderHeaderStatus.loaded,
          creditReceipts: receipts,
          filteredCreditReceipts: receipts,
          error: null,
        ),
      );
    } catch (e) {
      //emit(state.errorState('Failed to load credit receipts: $e'));
      if (kDebugMode) {
        developer.log('Failed to load credit receipts: $e');
      }
    }
  }

  Future<void> _onPrepareCreditReceipt(
    PrepareCreditReceipt event,
    Emitter<SalesOrderHeaderState> emit,
  ) async {
    try {
      emit(state.copyWith(status: SalesOrderHeaderStatus.preparing));

      // Get the sales order header
      final header = await repository.getSalesOrderHeaderById(event.soHeaderId);
      if (header == null) {
        emit(state.errorState('Sales order not found'));
        return;
      }

      // Check if there's open amount
      if (header.amountOpen == null || header.amountOpen! <= 0) {
        emit(state.errorState('No open amount available for receipt'));
        return;
      }

      // Create new credit receipt
      final newReceipt = CreditReceipt(
        soHeader: header.id,
        receiptAmount: 0.0, // Start with 0, user will enter amount
        dateReceipt: DateTime.now(),
        company: header.company,
        userId: authBloc.state.userId?.id,
        dateUpdated: DateTime.now(),
        tempId: _getNextCreditReceiptTempId(state.creditReceipts),
      );

      emit(
        state.copyWith(
          status: SalesOrderHeaderStatus.loaded,
          selectedCreditReceipt: newReceipt,
          creditReceiptSuccess: null,
          creditReceiptError: null,
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to prepare credit receipt: $e'));
    }
  }

  Future<void> _onUpdateCreditReceipt(
    UpdateCreditReceipt event,
    Emitter<SalesOrderHeaderState> emit,
  ) async {
    emit(state.copyWith(selectedCreditReceipt: event.receipt));
  }

  // MAIN CREDIT RECEIPT SAVE FUNCTION (Based on Java logic)
  Future<void> _onSaveCreditReceipt(
    SaveCreditReceipt event,
    Emitter<SalesOrderHeaderState> emit,
  ) async {
    try {
      emit(state.copyWith(status: SalesOrderHeaderStatus.saving));

      final receipt = event.receipt;

      // Validate receipt amount (from Java logic)
      if (receipt.receiptAmount! <= 0.0) {
        emit(
          state.copyWith(
            status: SalesOrderHeaderStatus.error,
            creditReceiptError: 'Receipt amount must be greater than 0',
            creditReceiptSuccess: false,
          ),
        );
        return;
      }

      // Get the sales order header
      final header = await repository.getSalesOrderHeaderById(
        receipt.soHeader!,
      );
      if (header == null) {
        emit(
          state.copyWith(
            status: SalesOrderHeaderStatus.error,
            creditReceiptError: 'Sales order header not found',
            creditReceiptSuccess: false,
          ),
        );
        return;
      }

      // Calculate remaining amount (from Java logic)
      final amountRemain = (header.amountOpen ?? 0.0) - receipt.receiptAmount!;

      // Validate receipt amount doesn't exceed open amount
      if (amountRemain < 0) {
        emit(
          state.copyWith(
            status: SalesOrderHeaderStatus.error,
            creditReceiptError: 'Receipt amount exceeds open amount',
            creditReceiptSuccess: false,
          ),
        );
        return;
      }

      // Get UDC for payment status
      final paidStatus = await udcDetailRepository.getUdcDetailsByCode(
        "P",
        "PS",
      );
      final partiallyPaidStatus = await udcDetailRepository.getUdcDetailsByCode(
        "S",
        "PS",
      );

      if (receipt.id == null) {
        // Create credit receipt record
        final receiptId = await repository.createCreditReceipt(receipt);
        final savedReceipt = receipt.copyWith(id: receiptId);

        // Update sales order header (from Java logic)
        final updatedHeader = header.copyWith(
          amountOpen: amountRemain,
          paymentStatus: amountRemain == 0.0
              ? paidStatus.isNotEmpty
                    ? paidStatus.first.id
                    : null // Paid
              : partiallyPaidStatus.isNotEmpty
              ? partiallyPaidStatus.first.id
              : null, // Partially Paid
        );

        // Save updated header
        await repository.updateSalesOrderHeader(updatedHeader);

        // Update state with new lists
        final updatedHeaders = state.headers
            .map((h) => h.id == updatedHeader.id ? updatedHeader : h)
            .toList();

        final updatedFilteredHeaders = state.filteredHeaders
            .map((h) => h.id == updatedHeader.id ? updatedHeader : h)
            .toList();

        final updatedCreditReceipts = [...state.creditReceipts, savedReceipt];
        final updatedFilteredCreditReceipts = [
          ...state.filteredCreditReceipts,
          savedReceipt,
        ];

        emit(
          state.copyWith(
            status: SalesOrderHeaderStatus.success,
            headers: updatedHeaders,
            filteredHeaders: updatedFilteredHeaders,
            selected: updatedHeader,
            selected1: updatedHeader,
            creditReceipts: updatedCreditReceipts,
            filteredCreditReceipts: updatedFilteredCreditReceipts,
            selectedCreditReceipt: savedReceipt,
            creditReceiptSuccess: true,
            creditReceiptError: null,
            successmessage: 'Credit receipt saved successfully',
          ),
        );

        // Refresh credit receipts list
        add(LoadCreditReceipts(companyId: event.companyId));
      } else {
        // For existing receipts, just update (though typically receipts shouldn't be edited)
        await repository.updateCreditReceipt(receipt);

        emit(
          state.copyWith(
            creditReceiptSuccess: true,
            creditReceiptError: null,
            successmessage: 'Credit receipt updated successfully',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: SalesOrderHeaderStatus.error,
          //creditReceiptError: 'Failed to save credit receipt: $e',
          creditReceiptSuccess: false,
        ),
      );
      if (kDebugMode) {
        developer.log('Failed to save credit receipt: $e');
      }
    }
  }

  Future<void> _onDeleteCreditReceipt(
    DeleteCreditReceipt event,
    Emitter<SalesOrderHeaderState> emit,
  ) async {
    try {
      emit(state.copyWith(status: SalesOrderHeaderStatus.deleting));

      // Get receipt details first
      final receipt = state.creditReceipts.firstWhere(
        (r) => r.id == event.receiptId,
        orElse: () => throw Exception('Receipt not found'),
      );

      // Get header to restore open amount
      final header = await repository.getSalesOrderHeaderById(
        receipt.soHeader!,
      );
      if (header != null) {
        // Restore the receipt amount to open amount
        final restoredAmount =
            (header.amountOpen ?? 0.0) + receipt.receiptAmount!;

        // Update payment status (may need to revert to partial or not paid)
        int? newPaymentStatus;
        if (restoredAmount == (header.amountTotal ?? 0.0)) {
          // All amount restored, back to not paid
          final notPaidStatus = await udcDetailRepository.getUdcDetailsByCode(
            "N",
            "PS",
          );
          newPaymentStatus = notPaidStatus.isNotEmpty
              ? notPaidStatus.first.id
              : null;
        } else if (restoredAmount > 0) {
          // Partial amount restored, back to partially paid
          final partiallyPaidStatus = await udcDetailRepository
              .getUdcDetailsByCode("S", "PS");
          newPaymentStatus = partiallyPaidStatus.isNotEmpty
              ? partiallyPaidStatus.first.id
              : null;
        }

        final updatedHeader = header.copyWith(
          amountOpen: restoredAmount,
          paymentStatus: newPaymentStatus,
        );

        await repository.updateSalesOrderHeader(updatedHeader);

        // Update state headers
        final updatedHeaders = state.headers
            .map((h) => h.id == updatedHeader.id ? updatedHeader : h)
            .toList();

        final updatedFilteredHeaders = state.filteredHeaders
            .map((h) => h.id == updatedHeader.id ? updatedHeader : h)
            .toList();

        emit(
          state.copyWith(
            headers: updatedHeaders,
            filteredHeaders: updatedFilteredHeaders,
            selected: state.selected?.id == updatedHeader.id
                ? updatedHeader
                : state.selected,
          ),
        );
      }

      // Delete the receipt
      await repository.deleteCreditReceipt(event.receiptId, authBloc.state.companyId!);

      // Update state
      final updatedReceipts = state.creditReceipts
          .where((r) => r.id != event.receiptId)
          .toList();

      final updatedFilteredReceipts = state.filteredCreditReceipts
          .where((r) => r.id != event.receiptId)
          .toList();

      emit(
        state.copyWith(
          status: SalesOrderHeaderStatus.success,
          creditReceipts: updatedReceipts,
          filteredCreditReceipts: updatedFilteredReceipts,
          selectedCreditReceipt:
              state.selectedCreditReceipt?.id == event.receiptId
              ? null
              : state.selectedCreditReceipt,
          successmessage: 'Credit receipt deleted successfully',
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to delete credit receipt: $e'));
    }
  }

  void _onSelectCreditReceipt(
    SelectCreditReceipt event,
    Emitter<SalesOrderHeaderState> emit,
  ) {
    emit(state.copyWith(selectedCreditReceipt: event.receipt));
  }

  Future<void> _onFilterCreditReceipts(
    FilterCreditReceipts event,
    Emitter<SalesOrderHeaderState> emit,
  ) async {
    try {
      emit(state.copyWith(status: SalesOrderHeaderStatus.filtering));

      final filteredReceipts = await repository.filterCreditReceipts(
        companyId: event.companyId,
        customerId: event.customerId,
        fsNumber: event.fsNumber,
      );

      emit(
        state.copyWith(
          status: SalesOrderHeaderStatus.loaded,
          filteredCreditReceipts: filteredReceipts,
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to filter credit receipts: $e'));
    }
  }

  Future<void> _onClearCreditReceiptFilters(
    ClearCreditReceiptFilters event,
    Emitter<SalesOrderHeaderState> emit,
  ) async {
    emit(
      state.copyWith(status: SalesOrderHeaderStatus.loadingCreditReceiptReport),
    );

    try {
      emit(
        state.copyWith(
          status: SalesOrderHeaderStatus.loadedCreditReceiptReport,
          filteredCreditReceipts: [],
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to clear credit receipts filters: $e'));
    }
  }

  // Helper method for temp IDs
  int _getNextCreditReceiptTempId(List<CreditReceipt> items) {
    if (items.isEmpty) return 1;
    final maxTempId = items
        .map((e) => e.tempId ?? 0)
        .reduce((a, b) => a > b ? a : b);
    return maxTempId + 1;
  }

  // Helper Methods
  int _getNextTempId(List<SalesOrderHeader> items) {
    if (items.isEmpty) return 1;
    final maxTempId = items
        .map((e) => e.tempId ?? 0)
        .reduce((a, b) => a > b ? a : b);
    return maxTempId + 1;
  }

  String _convertAmountToWords(double amount) {
    double amt = amount;
    int dollars = amt.floor();
    int cents = ((amt - dollars) * 100).round();

    final dollarsInWords = _convertNumberToWords(dollars);
    final centsInWords = _convertNumberToWords(cents);

    if (cents == 0) {
      return '$dollarsInWords ETB Only';
    } else {
      return '$dollarsInWords ETB and $centsInWords Cents Only';
    }
  }

  String _convertNumberToWords(int number) {
    if (number == 0) return 'Zero';

    const List<String> units = [
      '',
      'One',
      'Two',
      'Three',
      'Four',
      'Five',
      'Six',
      'Seven',
      'Eight',
      'Nine',
      'Ten',
      'Eleven',
      'Twelve',
      'Thirteen',
      'Fourteen',
      'Fifteen',
      'Sixteen',
      'Seventeen',
      'Eighteen',
      'Nineteen',
    ];

    const List<String> tens = [
      '',
      '',
      'Twenty',
      'Thirty',
      'Forty',
      'Fifty',
      'Sixty',
      'Seventy',
      'Eighty',
      'Ninety',
    ];

    if (number < 20) {
      return units[number];
    }

    if (number < 100) {
      return '${tens[number ~/ 10]} ${units[number % 10]}'.trim();
    }

    if (number < 1000) {
      final hundred = units[number ~/ 100];
      final remainder = number % 100;
      if (remainder == 0) return '$hundred Hundred';
      return '$hundred Hundred ${_convertNumberToWords(remainder)}';
    }

    if (number < 1000000) {
      final thousand = _convertNumberToWords(number ~/ 1000);
      final remainder = number % 1000;
      if (remainder == 0) return '$thousand Thousand';
      return '$thousand Thousand ${_convertNumberToWords(remainder)}';
    }

    if (number < 1000000000) {
      final million = _convertNumberToWords(number ~/ 1000000);
      final remainder = number % 1000000;
      if (remainder == 0) return '$million Million';
      return '$million Million ${_convertNumberToWords(remainder)}';
    }

    return number.toString();
  }

  // Helper Methods for Business Logic(it supposed to be come from purchase order)
  Future<DateTime> _calculateCreditDueDate(
    int paymentTerm,
    DateTime orderDate,
  ) async {
    // For now, use fixed 30 days as default
    // In a real implementation, you'd look up payment term details from UDC
    return orderDate.add(Duration(days: paymentTerm));
  }

  Future<UdcDetails?> _getDefaultOrderType() async {
    // Get default sales order type from UDC
    try {
      final defaultOrderType = await udcDetailRepository.getUdcDetailsByCode(
        "S",
        "OT",
      );
      if (defaultOrderType.isEmpty) {
        return null;
      }
      return defaultOrderType.first;
    } catch (e) {
      return null;
    }
  }

  // ============================================================================
  // SALES TRANSACTION REPORT EVENT HANDLERS
  // ============================================================================

  Future<void> _onLoadSalesTransactionReport(
    LoadSalesTransactionReport event,
    Emitter<SalesOrderHeaderState> emit,
  ) async {
    try {
      emit(state.copyWith(status: SalesOrderHeaderStatus.loading));

      // Fetch paginated data based on filter view type
      final result = event.filters.isDetailView
          ? await salesOrderReportRepository.getSalesTransactionDetailReport(
              companyId: event.companyId,
              page: event.page,
              pageSize: event.pageSize,
              customerId: event.filters.customerId,
              itemId: event.filters.itemId,
              fsNumber: event.filters.fsNumber,
              proformaReference: event.filters.proformaReference,
              startDate: event.filters.dateFrom,
              endDate: event.filters.dateTo,
              salesType: event.filters.salesType,
              voidIndicator: event.filters.voidIndicator,
            )
          : await salesOrderReportRepository.getSalesTransactionReport(
              companyId: event.companyId,
              page: event.page,
              pageSize: event.pageSize,
              customerId: event.filters.customerId,
              itemId: event.filters.itemId,
              fsNumber: event.filters.fsNumber,
              proformaReference: event.filters.proformaReference,
              startDate: event.filters.dateFrom,
              endDate: event.filters.dateTo,
              salesType: event.filters.salesType,
              voidIndicator: event.filters.voidIndicator,
            );

      // Calculate totals
      final totalsResult = await salesOrderReportRepository
          .calculateSalesTransactionTotals(
            companyId: event.companyId,
            customerId: event.filters.customerId,
            itemId: event.filters.itemId,
            fsNumber: event.filters.fsNumber,
            proformaReference: event.filters.proformaReference,
            startDate: event.filters.dateFrom,
            endDate: event.filters.dateTo,
            salesType: event.filters.salesType,
            voidIndicator: event.filters.voidIndicator,
            isDetailView: event.filters.isDetailView,
          );

      final totals = SalesTransactionReportTotals(
        withholdTotal: totalsResult['withholdTotal'] as double,
        vatTotal: totalsResult['vatTotal'] as double,
        discountTotal: totalsResult['discountTotal'] as double,
        revenueTotal: totalsResult['revenueTotal'] as double,
        cogsTotal: totalsResult['cogsTotal'] as double,
        grossProfitTotal: totalsResult['grossProfitTotal'] as double,
        totalCount: totalsResult['totalCount'] as int,
        currentPage: result['currentPage'] as int,
        totalPages: result['totalPages'] as int,
      );

      emit(
        state.copyWith(
          status: SalesOrderHeaderStatus.loaded,
          salesTransactionHeaders: event.filters.isDetailView
              ? []
              : (result['headers'] as List<SalesOrderHeader>),
          salesTransactionDetails: event.filters.isDetailView
              ? (result['details'] as List<SalesOrderDetail>)
              : [],
          salesTransactionFilters: event.filters,
          salesTransactionTotals: totals,
          salesTransactionPage: result['currentPage'] as int,
          salesTransactionPageSize: event.pageSize,
          salesTransactionTotalCount: result['totalCount'] as int,
          salesTransactionTotalPages: result['totalPages'] as int,
          hasMoreSalesTransaction:
              (result['currentPage'] as int) < (result['totalPages'] as int),
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to load sales transaction report: $e'));
    }
  }

  Future<void> _onLoadMoreSalesTransactionReport(
    LoadMoreSalesTransactionReport event,
    Emitter<SalesOrderHeaderState> emit,
  ) async {
    if (!state.hasMoreSalesTransaction) return;

    try {
      emit(state.loadingMoreState());
      final nextPage = state.salesTransactionPage + 1;
      final filters = state.salesTransactionFilters;

      // Fetch next page
      final result = filters.isDetailView
          ? await salesOrderReportRepository.getSalesTransactionDetailReport(
              companyId: state.companyId ?? authBloc.state.companyId!,
              page: nextPage,
              pageSize: state.salesTransactionPageSize,
              customerId: filters.customerId,
              itemId: filters.itemId,
              fsNumber: filters.fsNumber,
              proformaReference: filters.proformaReference,
              startDate: filters.dateFrom,
              endDate: filters.dateTo,
              salesType: filters.salesType,
              voidIndicator: filters.voidIndicator,
            )
          : await salesOrderReportRepository.getSalesTransactionReport(
              companyId: state.companyId ?? authBloc.state.companyId!,
              page: nextPage,
              pageSize: state.salesTransactionPageSize,
              customerId: filters.customerId,
              itemId: filters.itemId,
              fsNumber: filters.fsNumber,
              proformaReference: filters.proformaReference,
              startDate: filters.dateFrom,
              endDate: filters.dateTo,
              salesType: filters.salesType,
              voidIndicator: filters.voidIndicator,
            );

      emit(
        state.copyWith(
          status: SalesOrderHeaderStatus.loaded,
          salesTransactionHeaders: filters.isDetailView
              ? state.salesTransactionHeaders
              : [
                  ...state.salesTransactionHeaders,
                  ...(result['headers'] as List<SalesOrderHeader>),
                ],
          salesTransactionDetails: filters.isDetailView
              ? [
                  ...state.salesTransactionDetails,
                  ...(result['details'] as List<SalesOrderDetail>),
                ]
              : state.salesTransactionDetails,
          salesTransactionPage: result['currentPage'] as int,
          hasMoreSalesTransaction:
              (result['currentPage'] as int) < (result['totalPages'] as int),
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to load more transactions: $e'));
    }
  }

  Future<void> _onUpdateSalesTransactionFilters(
    UpdateSalesTransactionFilters event,
    Emitter<SalesOrderHeaderState> emit,
  ) async {
    // Reload data with new filters
    add(
      LoadSalesTransactionReport(
        companyId: state.companyId ?? authBloc.state.companyId!,
        page: 1,
        pageSize: state.salesTransactionPageSize,
        filters: event.filters,
      ),
    );
  }

  void _onClearSalesTransactionFilters(
    ClearSalesTransactionFilters event,
    Emitter<SalesOrderHeaderState> emit,
  ) {
    // Reload with empty filters
    add(
      LoadSalesTransactionReport(
        companyId: state.companyId ?? authBloc.state.companyId!,
        page: 1,
        pageSize: state.salesTransactionPageSize,
        filters: const SalesTransactionReportFilters(),
      ),
    );
  }

  Future<void> _onExportSalesTransactionToExcel(
    ExportSalesTransactionToExcel event,
    Emitter<SalesOrderHeaderState> emit,
  ) async {
    try {
      emit(state.copyWith(status: SalesOrderHeaderStatus.exporting));

      // TODO: Implement Excel export logic
      // This will be similar to _onExportTransactions but for the report data
      // You'll need to fetch all data (not paginated) and create Excel file

      emit(
        state.copyWith(
          status: SalesOrderHeaderStatus.loaded,
          exportSalesTransactionMessage:
              'Excel export functionality coming soon',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: SalesOrderHeaderStatus.loaded,
          exportSalesTransactionMessage: 'Failed to export to Excel: $e',
        ),
      );
    }
  }

  Future<void> _onExportSalesTransactionToPDF(
    ExportSalesTransactionToPDF event,
    Emitter<SalesOrderHeaderState> emit,
  ) async {
    try {
      emit(state.copyWith(status: SalesOrderHeaderStatus.exporting));

      // TODO: Implement PDF export logic
      // This will be similar to Excel export but generate PDF

      emit(
        state.copyWith(
          status: SalesOrderHeaderStatus.loaded,
          exportSalesTransactionMessage: 'PDF export functionality coming soon',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: SalesOrderHeaderStatus.loaded,
          exportSalesTransactionMessage: 'Failed to export to PDF: $e',
        ),
      );
    }
  }

  Future<void> _onLoadCreditReceiptsReport(
    LoadCreditReceiptsReport event,
    Emitter<SalesOrderHeaderState> emit,
  ) async {
    try {
      emit(
        state.copyWith(
          status: SalesOrderHeaderStatus.loadingCreditReceiptReport,
          creditReceiptReportPage: event.page,
          creditReceiptReportFilters: event.filters,
        ),
      );

      final int offset = (event.page - 1) * event.pageSize;

      final receipts = await salesOrderReportRepository.getCreditReceiptsReport(
        companyId: event.companyId,
        customerBillTo: event.filters.customerId,
        fsNumber: event.filters.fsNumber,
        sortBy: event.sortBy,
        limit: event.pageSize,
        offset: offset,
      );

      // Post-processing logic (Same as before but on the fetched page)
      // Group by Sales Order Header
      final Map<int, List<CreditReceipt>> groupedReceipts = {};
      for (var receipt in receipts) {
        if (receipt.soHeaderRef?.id != null) {
          if (!groupedReceipts.containsKey(receipt.soHeaderRef!.id)) {
            groupedReceipts[receipt.soHeaderRef!.id!] = [];
          }
          groupedReceipts[receipt.soHeaderRef!.id]!.add(receipt);
        }
      }

      final List<CreditReceipt> processedReceipts = [];

      groupedReceipts.forEach((soId, soReceipts) {
        // Sort by date receipt (Ascending for calculation?)
        // Java code sorts retrieving by DESC, then in memory compares by DateReceipt.
        // Assuming DateReceipt is comparable.
        soReceipts.sort((a, b) {
          final aDate = a.dateReceipt ?? DateTime(0);
          final bDate = b.dateReceipt ?? DateTime(0);
          return aDate.compareTo(bDate);
        });

        // Calculate Remaining Values
        // remaining starts at SO Amount Total
        double remaining = soReceipts.isNotEmpty
            ? (soReceipts.first.soHeaderRef?.amountTotal ?? 0.0)
            : 0.0;

        for (var receipt in soReceipts) {
          remaining -= (receipt.receiptAmount ?? 0.0);
          receipt.setRemainingValues(remaining);
          processedReceipts.add(receipt);
        }
      });
      processedReceipts.sort(
        (a, b) => (b.dateReceipt ?? DateTime(0)).compareTo(
          a.dateReceipt ?? DateTime(0),
        ),
      );

      emit(
        state.copyWith(
          status: SalesOrderHeaderStatus.loadedCreditReceiptReport,
          creditReceiptsReport: processedReceipts,
          hasMoreCreditReceiptReport: receipts.length == event.pageSize,
          creditReceiptReportTotalCount: 0, // Should fetch count if needed
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to load credit receipts report: $e'));
    }
  }

  Future<void> _onLoadMoreCreditReceiptsReport(
    LoadMoreCreditReceiptsReport event,
    Emitter<SalesOrderHeaderState> emit,
  ) async {
    if (state.hasMoreCreditReceiptReport &&
        state.status != SalesOrderHeaderStatus.loadingMoreCreditReceiptReport) {
      final nextPage = state.creditReceiptReportPage + 1;
      emit(
        state.copyWith(
          status: SalesOrderHeaderStatus.loadingMoreCreditReceiptReport,
        ),
      );

      // Trigger load for next page. But wait, reusing _onLoad replaces the list.
      // I need to append.
      // So I should implement the logic here, or make _onLoad handle appending (if I passed a flag).
      // Standard pattern: Separate handler or helper.
      // I will implement helper logic here.

      try {
        final int offset = (nextPage - 1) * state.creditReceiptReportPageSize;
        final receipts = await salesOrderReportRepository
            .getCreditReceiptsReport(
              companyId: state.companyId ?? 1, // Default or generic
              customerBillTo: state.creditReceiptReportFilters.customerId,
              fsNumber: state.creditReceiptReportFilters.fsNumber,
              limit: state.creditReceiptReportPageSize,
              offset: offset,
            );

        // Process newly fetched receipts
        // Note: Remaining value calculation is PER PAGE here as per logic discussion.
        final Map<int, List<CreditReceipt>> groupedReceipts = {};
        for (var receipt in receipts) {
          if (receipt.soHeaderRef?.id != null) {
            if (!groupedReceipts.containsKey(receipt.soHeaderRef!.id)) {
              groupedReceipts[receipt.soHeaderRef!.id!] = [];
            }
            groupedReceipts[receipt.soHeaderRef!.id]!.add(receipt);
          }
        }

        final List<CreditReceipt> processedReceipts = [];
        groupedReceipts.forEach((soId, soReceipts) {
          soReceipts.sort(
            (a, b) => (a.dateReceipt ?? DateTime(0)).compareTo(
              b.dateReceipt ?? DateTime(0),
            ),
          );
          double remaining = soReceipts.isNotEmpty
              ? (soReceipts.first.soHeaderRef?.amountTotal ?? 0.0)
              : 0.0;
          for (var receipt in soReceipts) {
            remaining -= (receipt.receiptAmount ?? 0.0);
            receipt.setRemainingValues(remaining);
            processedReceipts.add(receipt);
          }
        });
        processedReceipts.sort(
          (a, b) => (b.dateReceipt ?? DateTime(0)).compareTo(
            a.dateReceipt ?? DateTime(0),
          ),
        );

        emit(
          state.copyWith(
            status: SalesOrderHeaderStatus.loadedCreditReceiptReport,
            creditReceiptsReport: List.of(state.creditReceiptsReport)
              ..addAll(processedReceipts),
            creditReceiptReportPage: nextPage,
            hasMoreCreditReceiptReport:
                receipts.length == state.creditReceiptReportPageSize,
          ),
        );
      } catch (e) {
        emit(state.errorState('Failed to load more credit receipts: $e'));
      }
    }
  }

  Future<void> _onUpdateCreditReceiptReportFilters(
    UpdateCreditReceiptReportFilters event,
    Emitter<SalesOrderHeaderState> emit,
  ) async {
    emit(state.copyWith(creditReceiptReportFilters: event.filters));
    add(
      LoadCreditReceiptsReport(
        companyId: state.companyId ?? 1,
        filters: event.filters,
        page: 1,
        pageSize: state.creditReceiptReportPageSize,
      ),
    );
  }

  Future<void> _onClearCreditReceiptsReportFilters(
    ClearCreditReceiptsReportFilters event,
    Emitter<SalesOrderHeaderState> emit,
  ) async {
    emit(
      state.copyWith(
        creditReceiptReportFilters: const SalesTransactionReportFilters(),
      ),
    );
    add(
      LoadCreditReceiptsReport(
        companyId: state.companyId ?? 1,
        filters: const SalesTransactionReportFilters(),
        page: 1,
        pageSize: state.creditReceiptReportPageSize,
      ),
    );
  }

  Future<void> _onExportCreditReceiptReportToExcel(
    ExportCreditReceiptReportToExcel event,
    Emitter<SalesOrderHeaderState> emit,
  ) async {
    // Placeholder for export logic
    emit(state.successState('Export to Excel not implemented yet'));
  }

  Future<void> _onExportCreditReceiptReportToPDF(
    ExportCreditReceiptReportToPDF event,
    Emitter<SalesOrderHeaderState> emit,
  ) async {
    // Placeholder for export logic
    emit(state.successState('Export to PDF not implemented yet'));
  }
  // ============================================================================
  // Aged Credit Receipt REPORT EVENT HANDLERS
  // ============================================================================

  Future<void> _onLoadAgedCreditReceiptReport(
    LoadAgedCreditReceiptReport event,
    Emitter<SalesOrderHeaderState> emit,
  ) async {
    try {
      emit(
        state.copyWith(
          status: SalesOrderHeaderStatus.loadingAgedCreditReceiptReport,
        ),
      );

      // Fetch paginated data based on filter view type
      final result = await salesOrderReportRepository
          .getAgedCreditReceiptReport(
            companyId: event.companyId,
            page: event.page,
            pageSize: event.pageSize,
            customerId: event.filters.customerId,
            startDate: event.filters.dateFrom,
            endDate: event.filters.dateTo,
          );

      // Calculate totals
      final totalsResult = await salesOrderReportRepository
          .calculateAgedCreditReceiptTotals(
            companyId: event.companyId,
            customerId: event.filters.customerId,
            startDate: event.filters.dateFrom,
            endDate: event.filters.dateTo,
          );

      final totals = AgedCreditReceiptTotals(
        totalAmountprice: totalsResult['totalAmountprice'] as double,
        paidpriceAmount: totalsResult['paidpriceAmount'] as double,
        remainingPriceAmount: totalsResult['remainingPriceAmount'] as double,
        totalCount:
            totalsResult['totalCount'] as int? ??
            0, // Adjusted as repo calc doesn't return count, but report result does
        currentPage: result['currentPage'] as int,
        totalPages: result['totalPages'] as int,
      );

      emit(
        state.copyWith(
          status: SalesOrderHeaderStatus.loadedAgedCreditReceiptReport,
          agedCreditReceiptReport: result['headers'] as List<SalesOrderHeader>,
          agedCreditReceiptReportFilters: event.filters,
          agedCreditReceiptReportTotals: totals,
          agedCreditReceiptReportPage: result['currentPage'] as int,
          agedCreditReceiptReportPageSize: event.pageSize,
          agedCreditReceiptReportTotalCount: result['totalCount'] as int,
          agedCreditReceiptReportTotalPages: result['totalPages'] as int,
          hasMoreAgedCreditReceiptReport:
              (result['currentPage'] as int) < (result['totalPages'] as int),
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to load aged credit receipt report: $e'));
    }
  }

  Future<void> _onLoadMoreAgedCreditReceiptReport(
    LoadMoreAgedCreditReceiptReport event,
    Emitter<SalesOrderHeaderState> emit,
  ) async {
    if (!state.hasMoreAgedCreditReceiptReport) return;

    try {
      emit(
        state.copyWith(
          status: SalesOrderHeaderStatus.loadingMoreAgedCreditReceiptReport,
        ),
      );
      final nextPage = state.agedCreditReceiptReportPage + 1;
      final filters = state.agedCreditReceiptReportFilters;

      // Fetch next page
      final result = await salesOrderReportRepository
          .getAgedCreditReceiptReport(
            companyId: state.companyId ?? authBloc.state.companyId!,
            page: nextPage,
            pageSize: state.agedCreditReceiptReportPageSize,
            customerId: filters.customerId,
            startDate: filters.dateFrom,
            endDate: filters.dateTo,
          );

      emit(
        state.copyWith(
          status: SalesOrderHeaderStatus.loadedAgedCreditReceiptReport,
          agedCreditReceiptReport: [
            ...state.agedCreditReceiptReport,
            ...(result['headers'] as List<SalesOrderHeader>),
          ],
          agedCreditReceiptReportPage: result['currentPage'] as int,
          hasMoreAgedCreditReceiptReport:
              (result['currentPage'] as int) < (result['totalPages'] as int),
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to load more aged credit receipts: $e'));
    }
  }

  Future<void> _onUpdateAgedCreditReceiptFilters(
    UpdateAgedCreditReceiptReportFilters event,
    Emitter<SalesOrderHeaderState> emit,
  ) async {
    // Reload data with new filters
    add(
      LoadAgedCreditReceiptReport(
        companyId: state.companyId ?? authBloc.state.companyId!,
        page: 1,
        pageSize: state.agedCreditReceiptReportPageSize,
        filters: event.filters,
      ),
    );
  }

  void _onClearAgedCreditReceiptFilters(
    ClearAgedCreditReceiptReportFilters event,
    Emitter<SalesOrderHeaderState> emit,
  ) {
    // Reload with empty filters
    add(
      LoadAgedCreditReceiptReport(
        companyId: state.companyId ?? authBloc.state.companyId!,
        page: 1,
        pageSize: state.agedCreditReceiptReportPageSize,
        filters: const SalesTransactionReportFilters(),
      ),
    );
  }

  Future<void> _onExportAgedCreditReceiptToExcel(
    ExportAgedCreditReceiptReportToExcel event,
    Emitter<SalesOrderHeaderState> emit,
  ) async {
    try {
      emit(state.copyWith(status: SalesOrderHeaderStatus.exporting));

      // TODO: Implement Excel export logic
      // This will be similar to _onExportTransactions but for the report data
      // You'll need to fetch all data (not paginated) and create Excel file

      emit(
        state.copyWith(
          status: SalesOrderHeaderStatus.loaded,
          exportSalesTransactionMessage:
              'Excel export functionality coming soon',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: SalesOrderHeaderStatus.loaded,
          exportSalesTransactionMessage: 'Failed to export to Excel: $e',
        ),
      );
    }
  }

  Future<void> _onExportAgedCreditReceiptToPDF(
    ExportAgedCreditReceiptReportToPDF event,
    Emitter<SalesOrderHeaderState> emit,
  ) async {
    try {
      emit(state.copyWith(status: SalesOrderHeaderStatus.exporting));

      // TODO: Implement PDF export logic
      // This will be similar to Excel export but generate PDF

      emit(
        state.copyWith(
          status: SalesOrderHeaderStatus.loaded,
          exportSalesTransactionMessage: 'PDF export functionality coming soon',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: SalesOrderHeaderStatus.loaded,
          exportSalesTransactionMessage: 'Failed to export to PDF: $e',
        ),
      );
    }
  }
}
