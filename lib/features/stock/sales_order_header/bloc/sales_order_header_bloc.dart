// bloc/sales_order_header_bloc.dart
import 'dart:async';
import 'dart:math';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/stock/sales_order_header/bloc/sales_order_header_event.dart';
import 'package:savvy_stock/features/stock/sales_order_header/bloc/sales_order_header_state.dart';
import 'package:savvy_stock/features/stock/sales_order_header/model/sales_order_header.dart';
import 'package:savvy_stock/features/stock/sales_order_header/repo/sales_order_header_repo.dart';
class SalesOrderHeaderBloc extends Bloc<SalesOrderHeaderEvent, SalesOrderHeaderState> {
  final SalesOrderHeaderRepository repository;
  final AuthBloc authBloc;

   StreamSubscription? _authSubscription;

  SalesOrderHeaderBloc({ required this.repository, required this.authBloc })
    : super(const SalesOrderHeaderState()) {
    _authSubscription = authBloc.stream.listen((authState) {
      if (authState.isAuthenticated && authState.companyId != null) {
        add(LoadSalesOrderHeaders(companyId:authState.companyId!));
      }
    });
    on<LoadSalesOrderHeaders>(_onLoadSalesOrderHeaders);
    on<LoadCreditSalesOrders>(_onLoadCreditSalesOrders);
    on<CreateSalesOrderHeader>(_onCreateSalesOrderHeader);
    on<UpdateSalesOrderHeader>(_onUpdateSalesOrderHeader);
    on<DeleteSalesOrderHeader>(_onDeleteSalesOrderHeader);
    on<DeleteMultipleSalesOrders>(_onDeleteMultipleSalesOrders);
    on<SelectSalesOrder>(_onSelectSalesOrder);
    on<SelectMultipleSalesOrders>(_onSelectMultipleSalesOrders);
    on<ClearSelection>(_onClearSelection);
    on<FilterSalesOrders>(_onFilterSalesOrders);
    on<SearchSalesOrders>(_onSearchSalesOrders);
    on<ClearFilters>(_onClearFilters);
    on<CalculateOrderTotals>(_onCalculateOrderTotals);
    on<VoidSalesOrder>(_onVoidSalesOrder);
    on<GetNextOrderNumber>(_onGetNextOrderNumber);
    on<ConvertAmountToWords>(_onConvertAmountToWords);
    on<PrepareCreate>(_onPrepareCreate);
    on<SaveSalesOrder>(_onSaveSalesOrder);
    on<UpdateCustomerInfo>(_onUpdateCustomerInfo);
    on<UpdatePaymentType>(_onUpdatePaymentType);
    on<UpdateDateFilters>(_onUpdateDateFilters);
    on<DiscardChanges>(_onDiscardChanges);
  }
    @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
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

      emit(state.copyWith(
        status: SalesOrderHeaderStatus.loaded,
        headers: headers,
        filteredHeaders: headers,
        companyId: event.companyId,
        error: null,
      ));
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

      final creditHeaders = await repository.getCreditSalesOrders(event.companyId);
      
      emit(state.copyWith(
        status: SalesOrderHeaderStatus.loaded,
        creditHeaders: creditHeaders,
        error: null,
      ));
    } catch (e) {
      emit(state.errorState('Failed to load credit sales orders: $e'));
    }
  }

  Future<void> _onCreateSalesOrderHeader(
    CreateSalesOrderHeader event,
    Emitter<SalesOrderHeaderState> emit,
  ) async {
    try {
      emit(state.loadingState());

      final nextOrderNumber = await repository.getNextOrderNumber(event.header.company!);
      final headerWithOrderNumber = event.header.copyWith(orderNumber: nextOrderNumber);
      
      final id = await repository.createSalesOrderHeader(headerWithOrderNumber);
      final createdHeader = headerWithOrderNumber.copyWith(id: id);
      
      // Update the lists
      final updatedHeaders = [createdHeader, ...state.headers];
      final updatedCreateItems = state.createItems
          .where((item) => item.tempId != createdHeader.tempId)
          .toList();

      emit(state.copyWith(
        status: SalesOrderHeaderStatus.success,
        headers: updatedHeaders,
        filteredHeaders: updatedHeaders,
        createItems: updatedCreateItems,
        selected: createdHeader,
        nextOrderNumber: nextOrderNumber + 1,
        successmessage: 'Sales order created successfully',
        error: null,
      ));
    } catch (e) {
      emit(state.errorState('Failed to create sales order: $e'));
    }
  }

  Future<void> _onUpdateSalesOrderHeader(
    UpdateSalesOrderHeader event,
    Emitter<SalesOrderHeaderState> emit,
  ) async {
    try {
      emit(state.loadingState());

      await repository.updateSalesOrderHeader(event.header);
      
      // Update the header in the lists
      final updatedHeaders = state.headers.map((h) => h.id == event.header.id ? event.header : h).toList();
      final updatedEditItems = state.editItems
          .where((item) => item.id != event.header.id)
          .toList();

      emit(state.copyWith(
        status: SalesOrderHeaderStatus.success,
        headers: updatedHeaders,
        filteredHeaders: updatedHeaders,
        editItems: updatedEditItems,
        selected: event.header,
        successmessage: 'Sales order updated successfully',
        error: null,
      ));
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
      
      final updatedHeaders = state.headers.where((h) => h.id != event.id).toList();
      final updatedFilteredHeaders = state.filteredHeaders.where((h) => h.id != event.id).toList();

      emit(state.copyWith(
        status: SalesOrderHeaderStatus.success,
        headers: updatedHeaders,
        filteredHeaders: updatedFilteredHeaders,
        selected: state.selected?.id == event.id ? null : state.selected,
        successmessage: 'Sales order deleted successfully',
        error: null,
      ));
    } catch (e) {
      emit(state.errorState('Failed to delete sales order: $e'));
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
      
      final idsToRemove = event.headers.map((h) => h.id).whereType<int>().toSet();
      final updatedHeaders = state.headers.where((h) => !idsToRemove.contains(h.id)).toList();
      final updatedFilteredHeaders = state.filteredHeaders.where((h) => !idsToRemove.contains(h.id)).toList();

      emit(state.copyWith(
        status: SalesOrderHeaderStatus.success,
        headers: updatedHeaders,
        filteredHeaders: updatedFilteredHeaders,
        multiselectionItems: const [],
        successmessage: '${event.headers.length} sales orders deleted successfully',
        error: null,
      ));
    } catch (e) {
      emit(state.errorState('Failed to delete sales orders: $e'));
    }
  }

  void _onSelectSalesOrder(
    SelectSalesOrder event,
    Emitter<SalesOrderHeaderState> emit,
  ) {
    emit(state.copyWith(
      selected: event.header,
      selected1: event.header,
    ));
  }

  void _onSelectMultipleSalesOrders(
    SelectMultipleSalesOrders event,
    Emitter<SalesOrderHeaderState> emit,
  ) {
    emit(state.copyWith(
      multiselectionItems: event.headers,
      isSelectionMode: event.headers.isNotEmpty,
    ));
  }



  void _onClearSelection(
    ClearSelection event,
    Emitter<SalesOrderHeaderState> emit,
  ) {
    emit(state.copyWith(
      selectedItems: const [],
      multiselectionItems: const [],
      isSelectionMode: false,
    ));
  }

  Future<void> _onFilterSalesOrders(
    FilterSalesOrders event,
    Emitter<SalesOrderHeaderState> emit,
  ) async {
    try {
      emit(state.copyWith(status: SalesOrderHeaderStatus.filtering));

      final filteredHeaders = await repository.getSalesOrderHeaders(
        companyId: state.companyId!,
        customerBillTo: event.filter.customerBillTo,
        fsNumber: event.filter.fsNumber,
        startDate: event.startDate,
        endDate: event.endDate,
        voidIndicator: false,
      );

      emit(state.copyWith(
        status: SalesOrderHeaderStatus.loaded,
        filteredHeaders: filteredHeaders,
        selected3: event.filter,
        dateOrderStart: event.startDate,
        dateOrderEnd: event.endDate,
        error: null,
      ));
    } catch (e) {
      emit(state.errorState('Failed to filter sales orders: $e'));
    }
  }

  void _onSearchSalesOrders(
    SearchSalesOrders event,
    Emitter<SalesOrderHeaderState> emit,
  ) {
    if (event.query.isEmpty) {
      emit(state.copyWith(
        searchQuery: null,
        filteredHeaders: state.headers,
      ));
      return;
    }

    final query = event.query.toLowerCase();
    final filtered = state.headers.where((header) {
      return header.fsNumber?.toLowerCase().contains(query) == true ||
          header.referenceNote1?.toLowerCase().contains(query) == true ||
          header.referenceNote2?.toLowerCase().contains(query) == true ||
          header.referenceNote3?.toLowerCase().contains(query) == true ||
          (header.orderNumber != null && header.orderNumber.toString().contains(query));
    }).toList();

    emit(state.copyWith(
      searchQuery: event.query,
      filteredHeaders: filtered,
    ));
  }

  void _onClearFilters(
    ClearFilters event,
    Emitter<SalesOrderHeaderState> emit,
  ) {
    emit(state.clearFilters());
  }

  void _onCalculateOrderTotals(
    CalculateOrderTotals event,
    Emitter<SalesOrderHeaderState> emit,
  ) {
    try {
      emit(state.calculatingState());

      final decimalPlaces = event.systemConstants?.decimalPlaces ?? 2;
      
      // Calculate subtotal
      double subTotal = 0.0;
      double taxableAmount = 0.0;
      
      for (final detail in event.orderDetails) {
        final extendedPrice = detail.extendedPrice ?? 0.0;
        subTotal += extendedPrice;
        
        if (detail.item?.taxable == 'Y') {
          taxableAmount += extendedPrice;
        }
      }
      
      // Calculate tax
      final vatRate = (event.systemConstants?.rateVatPercentage ?? 0.0) / 100.0;
      final tax = _round(taxableAmount * vatRate, decimalPlaces);
      
      // Calculate withholding tax
      final withHoldRate = (event.systemConstants?.rateWithholdingPercentage ?? 0.0) / 100.0;
      final withHoldInitials = event.systemConstants?.withHoldInitials ?? 0.0;
      double withholdAmount = 0.0;
      
      if (event.applyWithholding && subTotal >= withHoldInitials) {
        withholdAmount = _round(subTotal * withHoldRate, decimalPlaces);
      }
      
      // Calculate total
      final discountAmount = state.discountAmount;
      final totalAmount = _round(
        subTotal + tax - withholdAmount - discountAmount, 
        decimalPlaces
      );
      
      final amountOpen = totalAmount - discountAmount;

      emit(state.copyWith(
        status: SalesOrderHeaderStatus.loaded,
        subTotal: _round(subTotal, decimalPlaces),
        tax: tax,
        withholdAmount: withholdAmount,
        totalAmount: totalAmount,
        amountOpen: amountOpen,
        applyWH: event.applyWithholding,
        error: null,
      ));
    } catch (e) {
      emit(state.errorState('Failed to calculate totals: $e'));
    }
  }

  Future<void> _onVoidSalesOrder(
    VoidSalesOrder event,
    Emitter<SalesOrderHeaderState> emit,
  ) async {
    try {
      emit(state.copyWith(status: SalesOrderHeaderStatus.voiding));

      await repository.voidSalesOrder(event.id, 'V');
      
      // Update the header in the lists
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

      emit(state.copyWith(
        status: SalesOrderHeaderStatus.success,
        headers: updatedHeaders,
        filteredHeaders: updatedFilteredHeaders,
        selected: state.selected?.id == event.id ? 
            state.selected!.copyWith(voidIndicator: 'V') : state.selected,
        successmessage: 'Sales order voided successfully',
        error: null,
      ));
    } catch (e) {
      emit(state.errorState('Failed to void sales order: $e'));
    }
  }

  Future<void> _onGetNextOrderNumber(
    GetNextOrderNumber event,
    Emitter<SalesOrderHeaderState> emit,
  ) async {
    try {
      emit(state.processingState());

      final nextOrderNumber = await repository.getNextOrderNumber(event.companyId);
      
      emit(state.copyWith(
        status: SalesOrderHeaderStatus.loaded,
        nextOrderNumber: nextOrderNumber,
        error: null,
      ));
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
      
      emit(state.copyWith(
        status: SalesOrderHeaderStatus.loaded,
        amountInWords: amountInWords,
        error: null,
      ));
    } catch (e) {
      emit(state.errorState('Failed to convert amount to words: $e'));
    }
  }

  Future<void> _onPrepareCreate(
    PrepareCreate event,
    Emitter<SalesOrderHeaderState> emit,
  ) async {
    try {
      emit(state.copyWith(status: SalesOrderHeaderStatus.preparing));

      final nextOrderNumber = await repository.getNextOrderNumber(event.companyId);
      
      final newHeader = SalesOrderHeader(
        orderDate: DateTime.now(),
        customerBillTo: 0,
        customerTableId: 0,
        employeesId: event.employeeId,
        company: event.companyId,
        tempId: 1,
        orderNumber: nextOrderNumber,
        paymentMethod: 'Cash',
      );

      emit(state.copyWith(
        status: SalesOrderHeaderStatus.loaded,
        createItems: [newHeader],
        selected: newHeader,
        nextOrderNumber: nextOrderNumber,
        paymentType: 'Cash',
        error: null,
      ));
    } catch (e) {
      emit(state.errorState('Failed to prepare create: $e'));
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

  void _onUpdateCustomerInfo(
    UpdateCustomerInfo event,
    Emitter<SalesOrderHeaderState> emit,
  ) {
    final customer = event.customer;
    final phoneNumbers = customer.phoneNumber! + (customer.phone2 != null && customer.phone2!.isNotEmpty ? ', ${customer.phone2}' : '');

    final updatedState = state.updateCustomerInfo(
      tinNumber: customer.tinNumber,
      phoneNumbers: phoneNumbers,
      countryDesc: customer.country,
      stateDesc: customer.state,
      regionDesc: customer.region,
      cityDesc: customer.city,
    );

    if (event.currentHeader != null) {
      final updatedHeader = event.currentHeader!.copyWith(
        customerTableId: customer.id!,
        customerBillTo: customer.id!,
      );
      
      emit(updatedState.copyWith(
        selected: updatedHeader,
      ));
    } else {
      emit(updatedState);
    }
  }

  void _onUpdatePaymentType(
    UpdatePaymentType event,
    Emitter<SalesOrderHeaderState> emit,
  ) {
    emit(state.copyWith(
      paymentType: event.paymentType,
    ));
  }

  void _onUpdateDateFilters(
    UpdateDateFilters event,
    Emitter<SalesOrderHeaderState> emit,
  ) {
    emit(state.copyWith(
      dateOrderStart: event.startDate,
      dateOrderEnd: event.endDate,
    ));
  }

  void _onDiscardChanges(
    DiscardChanges event,
    Emitter<SalesOrderHeaderState> emit,
  ) {
    // Remove unsaved create items
    final unsavedCreateItems = state.createItems.where((item) => item.id == null).toList();
    
    if (unsavedCreateItems.isNotEmpty) {
      // In a real app, you might want to actually delete these from the database
      // if they were temporarily saved
      final updatedCreateItems = state.createItems
          .where((item) => item.id != null)
          .toList();

      emit(state.copyWith(
        createItems: updatedCreateItems,
        selected: updatedCreateItems.isNotEmpty ? updatedCreateItems.first : null,
        successmessage: 'All unsaved records are removed',
      ));
    } else {
      emit(state.copyWith(
        successmessage: 'No unsaved records to remove',
      ));
    }
  }

  // Helper methods
  double _round(double value, int decimalPlaces) {
    final factor = pow(10, decimalPlaces);
    return (value * factor).round() / factor;
  }

  String _convertAmountToWords(double amount) {
    // Implementation from your Java code
    final dollars = amount.floor();
    final cents = ((amount - dollars) * 100).round();
    
    final dollarsInWords = _convertNumberToWords(dollars.toInt());
    final centsInWords = _convertNumberToWords(cents);
    
    if (cents == 0) {
      return '$dollarsInWords Birr Only';
    } else {
      return '$dollarsInWords Birr and $centsInWords Cents Only';
    }
  }

  String _convertNumberToWords(int number) {
    // Full implementation of your Java number to words conversion
    if (number == 0) return 'Zero';
    
    const List<String> units = [
      '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
      'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen', 
      'Seventeen', 'Eighteen', 'Nineteen'
    ];
    
    const List<String> tens = [
      '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'
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
      if (remainder == 0) {
        return '$hundred Hundred';
      }
      return '$hundred Hundred ${_convertNumberToWords(remainder)}';
    }
    
    if (number < 1000000) {
      final thousand = _convertNumberToWords(number ~/ 1000);
      final remainder = number % 1000;
      if (remainder == 0) {
        return '$thousand Thousand';
      }
      return '$thousand Thousand ${_convertNumberToWords(remainder)}';
    }
    
    if (number < 1000000000) {
      final million = _convertNumberToWords(number ~/ 1000000);
      final remainder = number % 1000000;
      if (remainder == 0) {
        return '$million Million';
      }
      return '$million Million ${_convertNumberToWords(remainder)}';
    }
    
    return number.toString();
  }
}