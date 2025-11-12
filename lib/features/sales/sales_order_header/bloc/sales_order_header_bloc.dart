// bloc/sales_order_header_bloc.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:savvy_stock/features/stock/item_UoM_conversions/repo/item_uom_conv_repo.dart';
import 'package:savvy_stock/features/stock/item_locations/repo/item_location_repo.dart';
import 'package:savvy_stock/features/stock/item_transactions/repo/item_transaction_repo.dart';
import 'package:savvy_stock/features/stock/lot_master/repo/lot_master_repo.dart';
import 'package:savvy_stock/features/stock/item_in_branch/repo/item_in_branch_repo.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_state.dart';
import 'package:savvy_stock/core/repositories/udc_repository.dart';
import 'package:savvy_stock/features/admin/employees/repo/employees_repo.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/sales/customer/repo/customer_repo.dart';
import 'package:savvy_stock/features/sales/sales_order_header/bloc/sales_order_header_event.dart';
import 'package:savvy_stock/features/sales/sales_order_header/bloc/sales_order_header_state.dart';
import 'package:savvy_stock/features/sales/sales_order_header/model/sales_order_header.dart';
import 'package:savvy_stock/features/sales/sales_order_header/repo/sales_order_header_repo.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_bloc.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_bloc.dart';
import 'package:savvy_stock/features/udc_detail/models/udc_details.dart';

class SalesOrderHeaderBloc
    extends Bloc<SalesOrderHeaderEvent, SalesOrderHeaderState> {
  final SalesOrderHeaderRepository repository;
  final AuthBloc authBloc;
  final SystemConstantBloc systemConstantBloc;
  final UdcDetailsBloc udcDetailBloc;
  final UdcRepository udcDetailRepository;
  final CustomerRepository customerRepository;
  final EmployeeRepository employeesRepository;
  final ItemUomConversionsRepository itemUomConversionsRepository;
  final LotMasterRepository lotMasterRepository;
  final StockItemInBranchRepository itemInBranchRepository;
  final ItemLocationsRepository itemLocationRepository;
  final ItemTransactionRepository itemTransactionRepository;

  StreamSubscription? _authSubscription;
  StreamSubscription? _systemConstantsSubscription;
  StreamSubscription? _udcDetailSubscription;
  StreamSubscription? _customerSubscription;
  StreamSubscription? _employeesSubscription;

  SalesOrderHeaderBloc({
    required this.repository,
    required this.authBloc,
    required this.systemConstantBloc,
    required this.udcDetailBloc,
    required this.customerRepository,
    required this.employeesRepository,
    required this.udcDetailRepository,
    required this.itemUomConversionsRepository,
    required this.lotMasterRepository,
    required this.itemInBranchRepository,
    required this.itemLocationRepository,
    required this.itemTransactionRepository,
  }) : super(const SalesOrderHeaderState()) {
    // Listen to authentication state
    _authSubscription = authBloc.stream.listen((authState) {
      if (authState.isAuthenticated &&
          authState.companyId != null &&
          authState.userId != null) {
        add(
          SalesOrderHeaderInitialized(
            companyId: authState.companyId!,
            employeeId: authState.userId!,
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
    on<UpdatePaymentType>(_onUpdatePaymentType);
    on<UpdatePaymentStatus>(_onUpdatePaymentStatus);
    on<SetPaymentTerm>(_onSetPaymentTerm);

    // UI State Management
    on<PrepareCreate>(_onPrepareCreate);
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

    // Recalculate totals if we have existing data
    if (state.selected != null && state.salesOrderDetail!.isNotEmpty) {
      add(
        CalculateOrderTotals(
          header: state.selected!,
          orderDetails: state.salesOrderDetail!,
          applyWithholding: state.applyWithholding,
          discountAmount: state.discountAmount,
        ),
      );
    }
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
        final extendedPrice = detail.extendedPrice ?? 0.0;
        subTotal += extendedPrice;

        // Check if item is taxable (like Java's item.getItemsTableId().getTaxableBoolean())
        if (detail.item?.taxable == 'Y') {
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
      final processedHeader = await _processHeaderBusinessLogic(
        event.header.copyWith(orderNumber: nextOrderNumber),
      );

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
      emit(state.errorState('Failed to create sales order: $e'));
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

      final paymentStatus = await _getPaymentStatus('N');

      final discount = header.discountAmount ?? 0.0;
      final total = header.amountTotal ?? 0.0;
      final openAmount = total - discount;

      processedHeader = processedHeader.copyWith(
        creditDateToPay: dueDate,
        paymentStatus: paymentStatus?.id,
        amountOpen: openAmount,
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
      await repository.voidSalesOrder(event.id, 'V');

      // Update local state
      final updatedHeaders = state.headers.map((h) {
        if (h.id == event.id) {
          return h.copyWith(voidIndicator: 'V');
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
        companyId: state.companyId!,
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
        companyId: state.companyId!,
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
        state.companyId!,
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
      add(LoadSalesOrderHeaders(companyId: state.companyId!));
    }
  }

  // Enhanced Create with System Constants Defaults
  Future<void> _onPrepareCreate(
    PrepareCreate event,
    Emitter<SalesOrderHeaderState> emit,
  ) async {
    try {
      emit(state.copyWith(status: SalesOrderHeaderStatus.preparing));

      // Ensure system constants are loaded
      await systemConstantBloc.systemConstantService.ensureLoaded();

      final nextOrderNumber = await repository.getNextOrderNumber(
        event.companyId,
      );

      // Get default order type from UDC
      final defaultOrderType = await _getDefaultOrderType();

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
        // Set default tax settings from system constants
        tax: 0.0,
        withholdAmount: 0.0,
        discountAmount: 0.0,
      );

      // Set default customer if available
      final defaultCustomer = await customerRepository.getDefaultCustomer(
        event.companyId,
      );
      if (defaultCustomer != null) {
        add(
          UpdateCustomerInfo(
            customer: defaultCustomer,
            currentHeader: newHeader,
          ),
        );
      }

      // Get employee details for sales representative
      final employee = await employeesRepository.getEmployeeById(
        event.employeeId,
        event.companyId,
      );
      final salesRepresent = employee != null
          ? '${employee.nameFirst} ${employee.nameLast}'.trim()
          : null;

      final headerWithSalesRep = newHeader.copyWith(employee: employee);

      emit(
        state.copyWith(
          status: SalesOrderHeaderStatus.loaded,
          createItems: [headerWithSalesRep],
          selected: headerWithSalesRep,
          nextOrderNumber: nextOrderNumber,
          paymentType: 'Cash',
          applyWH: systemConstantBloc.systemConstantService
              .shouldApplyWithholding(0.0),
        ),
      );
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
          paymentType: 'Cash',
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

      if (defaultCustomer != null) {
        add(
          UpdateCustomerInfo(
            customer: defaultCustomer,
            currentHeader: state.selected,
          ),
        );
      }
    } catch (e) {
      emit(state.errorState('Failed to set default customer: $e'));
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
      final paymentStatus = await _getPaymentStatus('N'); // 'N' for Not Paid

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
      emit(state.errorState('Failed to save sales order: $e'));
    }
  }

  void _onUpdatePaymentType(
    UpdatePaymentType event,
    Emitter<SalesOrderHeaderState> emit,
  ) {
    emit(state.copyWith(paymentType: event.paymentType));

    // If switching to credit, ensure payment term is set
    if (event.paymentType == 'Credit' && state.selected != null) {
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
      return '$dollarsInWords Birr Only';
    } else {
      return '$dollarsInWords Birr and $centsInWords Cents Only';
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
        "OT",
        "S",
      );
      if (defaultOrderType.isEmpty) {
        return null;
      }
      return defaultOrderType.first;
    } catch (e) {
      return null;
    }
  }

  Future<UdcDetails?> _getPaymentStatus(String statusCode) async {
    // Get payment status from UDC
    try {
      final paymentStatus = await udcDetailRepository.getUdcDetailsByCode(
        "PS",
        statusCode,
      );
      if (paymentStatus.isEmpty) {
        return null;
      }
    } catch (e) {
      return null;
    }
    return null;
  }
}
