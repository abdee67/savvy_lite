// bloc/sales_order_header_state.dart

import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/stock/sales_order_header/model/sales_order_header.dart';

enum SalesOrderHeaderStatus {
  initial,
  loading,
  loaded,
  creating,
  updating,
  deleting,
  saving,
  processing,
  success,
  error,
  failure,
  calculating,
  filtering,
  voiding,
  converting,
  preparing,
  copying,
}

class SalesOrderHeaderState extends Equatable {
  final SalesOrderHeaderStatus status;
  final List<SalesOrderHeader> headers;
  final List<SalesOrderHeader> filteredHeaders;
  final List<SalesOrderHeader> createItems;
  final List<SalesOrderHeader> editItems;
  final List<SalesOrderHeader> creditHeaders;
  final String? successmessage;
  final String? error;
  final List<SalesOrderHeader> selectedItems;
  final List<SalesOrderHeader> multiselectionItems;
  final List<SalesOrderHeader> multiselectionItemsForVoid;
  final SalesOrderHeader? selected;
  final SalesOrderHeader? selected1;
  final SalesOrderHeader? selected2;
  final SalesOrderHeader? selected3;
  final SalesOrderHeader? editingItem;
  final String? searchQuery;
  final bool isSelectionMode;
  final Map<String, dynamic>? filters;
  
  // Calculated totals
  final double subTotal;
  final double tax;
  final double withholdAmount;
  final double totalAmount;
  final double discountAmount;
  final double amountOpen;
  
  // Filter and configuration fields
  final DateTime? startDateForSales;
  final DateTime? thruDateForSales;
  final DateTime? dateOrderStart;
  final DateTime? dateOrderEnd;
  final String? paymentType;
  final String? orderStatus;
  final bool applyWH;
  final bool discountval;
  final bool allDetailTransactions;
  final String? fsRefrence;
  
  // Customer information
  final String? tinNumber;
  final String? phoneNumbers;
  final String? countryDesc;
  final String? stateDesc;
  final String? regionDesc;
  final String? cityDesc;
  
  // Business data
  final int? companyId;
  final int? nextOrderNumber;
  final String? amountInWords;
  final bool isDuplicate;

    const SalesOrderHeaderState({
    this.status = SalesOrderHeaderStatus.initial,
    this.headers = const [],
    this.filteredHeaders = const [],
    this.createItems = const [],
    this.editItems = const [],
    this.creditHeaders = const [],
    this.successmessage,
    this.error,
    this.selectedItems = const [],
    this.multiselectionItems = const [],
    this.multiselectionItemsForVoid = const [],
    this.selected,
    this.selected1,
    this.selected2,
    this.selected3,
    this.editingItem,
    this.searchQuery,
    this.isSelectionMode = false,
    this.filters,
    this.subTotal = 0.0,
    this.tax = 0.0,
    this.withholdAmount = 0.0,
    this.totalAmount = 0.0,
    this.discountAmount = 0.0,
    this.amountOpen = 0.0,
    this.startDateForSales,
    this.thruDateForSales,
    this.dateOrderStart,
    this.dateOrderEnd,
    this.paymentType,
    this.orderStatus,
    this.applyWH = false,
    this.discountval = false,
    this.allDetailTransactions = false,
    this.fsRefrence,
    this.tinNumber,
    this.phoneNumbers,
    this.countryDesc,
    this.stateDesc,
    this.regionDesc,
    this.cityDesc,
    this.companyId,
    this.nextOrderNumber,
    this.amountInWords,
    this.isDuplicate = false,
  });

  // Getters for status checks
  bool get hasError => error != null && error!.isNotEmpty;
  bool get hasSuccess => successmessage != null && successmessage!.isNotEmpty;
  bool get hasHeaders => headers.isNotEmpty;
  bool get hasFilteredHeaders => filteredHeaders.isNotEmpty;
  bool get hasCreateItems => createItems.isNotEmpty;
  bool get hasEditItems => editItems.isNotEmpty;
  bool get hasCreditHeaders => creditHeaders.isNotEmpty;
  bool get hasSelectedItems => selectedItems.isNotEmpty;
  bool get hasMultiSelectionItems => multiselectionItems.isNotEmpty;
  bool get hasSearchQuery => searchQuery != null && searchQuery!.isNotEmpty;
  bool get hasFilters => filters != null && filters!.isNotEmpty;

  // Status check methods
  bool isLoading() => status == SalesOrderHeaderStatus.loading;
  bool isProcessing() => status == SalesOrderHeaderStatus.processing;
  bool isSaving() => status == SalesOrderHeaderStatus.saving;
  bool isSuccess() => status == SalesOrderHeaderStatus.success;
  bool isError() => status == SalesOrderHeaderStatus.error;
  bool isFailure() => status == SalesOrderHeaderStatus.failure;
  bool isDeleting() => status == SalesOrderHeaderStatus.deleting;
  bool isLoaded() => status == SalesOrderHeaderStatus.loaded;
  bool isInitial() => status == SalesOrderHeaderStatus.initial;
  bool isCreating() => status == SalesOrderHeaderStatus.creating;
  bool isUpdating() => status == SalesOrderHeaderStatus.updating;
  bool isCalculating() => status == SalesOrderHeaderStatus.calculating;
  bool isFiltering() => status == SalesOrderHeaderStatus.filtering;
  bool isVoiding() => status == SalesOrderHeaderStatus.voiding;
  bool isConverting() => status == SalesOrderHeaderStatus.converting;
  bool isPreparing() => status == SalesOrderHeaderStatus.preparing;
  bool isCopying() => status == SalesOrderHeaderStatus.copying;

  // Helper getters for UI
  bool get hasSelected => selected != null;
  bool get hasSelected1 => selected1 != null;
  bool get hasSelected2 => selected2 != null;
  bool get hasSelected3 => selected3 != null;
  bool get hasEditingItem => editingItem != null;

  // Default date getters (similar to Java controller logic)
  DateTime get effectiveStartDateForSales => startDateForSales ?? DateTime(DateTime.now().year, 1, 1);
  DateTime get effectiveThruDateForSales => thruDateForSales ?? DateTime.now();
  DateTime get effectiveDateOrderStart => dateOrderStart ?? DateTime(DateTime.now().year, 1, 1);
  DateTime get effectiveDateOrderEnd => dateOrderEnd ?? DateTime.now();
  bool get effectiveDiscountval => discountval;
  bool get effectiveApplyWH => applyWH;

  SalesOrderHeaderState copyWith({
    SalesOrderHeaderStatus? status,
    List<SalesOrderHeader>? headers,
    List<SalesOrderHeader>? filteredHeaders,
    List<SalesOrderHeader>? createItems,
    List<SalesOrderHeader>? editItems,
    List<SalesOrderHeader>? creditHeaders,
    String? successmessage,
    String? error,
    List<SalesOrderHeader>? selectedItems,
    List<SalesOrderHeader>? multiselectionItems,
    List<SalesOrderHeader>? multiselectionItemsForVoid,
    SalesOrderHeader? selected,
    SalesOrderHeader? selected1,
    SalesOrderHeader? selected2,
    SalesOrderHeader? selected3,
    SalesOrderHeader? editingItem,
    String? searchQuery,
    bool? isSelectionMode,
    Map<String, dynamic>? filters,
    double? subTotal,
    double? tax,
    double? withholdAmount,
    double? totalAmount,
    double? discountAmount,
    double? amountOpen,
    DateTime? startDateForSales,
    DateTime? thruDateForSales,
    DateTime? dateOrderStart,
    DateTime? dateOrderEnd,
    String? paymentType,
    String? orderStatus,
    bool? applyWH,
    bool? discountval,
    bool? allDetailTransactions,
    String? fsRefrence,
    String? tinNumber,
    String? phoneNumbers,
    String? countryDesc,
    String? stateDesc,
    String? regionDesc,
    String? cityDesc,
    int? companyId,
    int? nextOrderNumber,
    String? amountInWords,
    bool? isDuplicate,
  }) {
    return SalesOrderHeaderState(
      status: status ?? this.status,
      headers: headers ?? this.headers,
      filteredHeaders: filteredHeaders ?? this.filteredHeaders,
      createItems: createItems ?? this.createItems,
      editItems: editItems ?? this.editItems,
      creditHeaders: creditHeaders ?? this.creditHeaders,
      successmessage: successmessage ?? this.successmessage,
      error: error ?? this.error,
      selectedItems: selectedItems ?? this.selectedItems,
      multiselectionItems: multiselectionItems ?? this.multiselectionItems,
      multiselectionItemsForVoid: multiselectionItemsForVoid ?? this.multiselectionItemsForVoid,
      selected: selected ?? this.selected,
      selected1: selected1 ?? this.selected1,
      selected2: selected2 ?? this.selected2,
      selected3: selected3 ?? this.selected3,
      editingItem: editingItem ?? this.editingItem,
      searchQuery: searchQuery ?? this.searchQuery,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      filters: filters ?? this.filters,
      subTotal: subTotal ?? this.subTotal,
      tax: tax ?? this.tax,
      withholdAmount: withholdAmount ?? this.withholdAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      amountOpen: amountOpen ?? this.amountOpen,
      startDateForSales: startDateForSales ?? this.startDateForSales,
      thruDateForSales: thruDateForSales ?? this.thruDateForSales,
      dateOrderStart: dateOrderStart ?? this.dateOrderStart,
      dateOrderEnd: dateOrderEnd ?? this.dateOrderEnd,
      paymentType: paymentType ?? this.paymentType,
      orderStatus: orderStatus ?? this.orderStatus,
      applyWH: applyWH ?? this.applyWH,
      discountval: discountval ?? this.discountval,
      allDetailTransactions: allDetailTransactions ?? this.allDetailTransactions,
      fsRefrence: fsRefrence ?? this.fsRefrence,
      tinNumber: tinNumber ?? this.tinNumber,
      phoneNumbers: phoneNumbers ?? this.phoneNumbers,
      countryDesc: countryDesc ?? this.countryDesc,
      stateDesc: stateDesc ?? this.stateDesc,
      regionDesc: regionDesc ?? this.regionDesc,
      cityDesc: cityDesc ?? this.cityDesc,
      companyId: companyId ?? this.companyId,
      nextOrderNumber: nextOrderNumber ?? this.nextOrderNumber,
      amountInWords: amountInWords ?? this.amountInWords,
      isDuplicate: isDuplicate ?? this.isDuplicate,
    );
  }

  // Helper methods for common state transitions
  SalesOrderHeaderState loadingState() => copyWith(
        status: SalesOrderHeaderStatus.loading,
        error: null,
        successmessage: null,
      );

  SalesOrderHeaderState successState(String message) => copyWith(
        status: SalesOrderHeaderStatus.success,
        successmessage: message,
        error: null,
      );

  SalesOrderHeaderState errorState(String errorMessage) => copyWith(
        status: SalesOrderHeaderStatus.error,
        error: errorMessage,
        successmessage: null,
      );

  SalesOrderHeaderState processingState() => copyWith(
        status: SalesOrderHeaderStatus.processing,
        error: null,
        successmessage: null,
      );

  SalesOrderHeaderState calculatingState() => copyWith(
        status: SalesOrderHeaderStatus.calculating,
        error: null,
        successmessage: null,
      );

  SalesOrderHeaderState clearMessages() => copyWith(
        error: null,
        successmessage: null,
      );

  SalesOrderHeaderState clearFilters() => copyWith(
        selected3: null,
        dateOrderStart: null,
        dateOrderEnd: null,
        filteredHeaders: headers,
        filters: null,
      );

  SalesOrderHeaderState updateCustomerInfo({
    String? tinNumber,
    String? phoneNumbers,
    String? countryDesc,
    String? stateDesc,
    String? regionDesc,
    String? cityDesc,
  }) =>
      copyWith(
        tinNumber: tinNumber,
        phoneNumbers: phoneNumbers,
        countryDesc: countryDesc,
        stateDesc: stateDesc,
        regionDesc: regionDesc,
        cityDesc: cityDesc,
      );

  @override
  List<Object?> get props => [
        status,
        headers,
        filteredHeaders,
        createItems,
        editItems,
        creditHeaders,
        successmessage,
        error,
        selectedItems,
        multiselectionItems,
        multiselectionItemsForVoid,
        selected,
        selected1,
        selected2,
        selected3,
        editingItem,
        searchQuery,
        isSelectionMode,
        filters,
        subTotal,
        tax,
        withholdAmount,
        totalAmount,
        discountAmount,
        amountOpen,
        startDateForSales,
        thruDateForSales,
        dateOrderStart,
        dateOrderEnd,
        paymentType,
        orderStatus,
        applyWH,
        discountval,
        allDetailTransactions,
        fsRefrence,
        tinNumber,
        phoneNumbers,
        countryDesc,
        stateDesc,
        regionDesc,
        cityDesc,
        companyId,
        nextOrderNumber,
        amountInWords,
        isDuplicate,
      ];
}