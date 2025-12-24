// bloc/sales_order_header_state.dart

import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/sales/customer/models/customer_model.dart';
import 'package:savvy_stock/features/sales/sales_order/detail/model/sales_order_detail.dart';
import 'package:savvy_stock/features/sales/sales_order/header/model/aged_credit_receipt_totals_mode.dart';
import 'package:savvy_stock/features/sales/sales_order/header/model/credit_receipt_model.dart';
import 'package:savvy_stock/features/sales/sales_order/header/model/sales_order_header.dart';
import 'package:savvy_stock/features/sales/sales_order/header/model/sales_transaction_filtering_model.dart';
import 'package:savvy_stock/features/sales/sales_order/header/model/sales_transaction_report_totals.dart';
import 'package:savvy_stock/features/stock/lot_master/models/lot_master_model.dart';
import 'package:savvy_stock/features/system_constant/models/system_constant.dart';

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
  validatingItemInBranch,
  validatingLot,
  exporting,
  loadingMore,
  loadingCreditReceiptReport,
  filteringCreditReceiptReport,
  loadedCreditReceiptReport,
  loadingMoreCreditReceiptReport,
  exportCreditReceiptReportSuccess,

  // Aged Credit Receipt Report
  loadingAgedCreditReceiptReport,
  loadedAgedCreditReceiptReport,
  loadingMoreAgedCreditReceiptReport,
  exportAgedCreditReceiptReportSuccess,
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
  final SalesOrderHeader? selected4;
  final SalesOrderHeader? editingItem;
  final String? searchQuery;
  final bool isSelectionMode;
  final Map<String, dynamic>? filters;
  final List<SalesOrderHeader> voidedHeaders;
  final String? fsNumber;
  final SystemConstant? systemConstants;
  final SalesOrderHeader? exportedSales;

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
  final DateTime? dateForCreditFrom;
  final DateTime? dateForCreditTo;
  final String? paymentMethod;
  final String? orderStatus;
  final bool applyWH;
  final bool discountval;
  final bool allDetailTransactions;

  // Customer information
  final String? tinNumber;
  final String? phoneNumbers;
  final String? countryDesc;
  final String? stateDesc;
  final String? regionDesc;
  final String? cityDesc;
  final Customer? defaultCustomer;

  // Business data
  final int? companyId;
  final int? nextOrderNumber;
  final String? amountInWords;
  final bool isDuplicate;

  // Tax settings
  final bool applyWithholding;
  final List<SalesOrderDetail>? salesOrderDetail;

  // UOM Conversion
  final UOMConversionResult? uomConversionResult;
  final LotValidationResult? lotValidationResult;
  final ValidationResult? validationResult;

  final CreditReceipt? selectedCreditReceipt;
  final List<CreditReceipt> creditReceipts;
  final List<CreditReceipt> filteredCreditReceipts;

  final SalesTransactionReportFilters creditReceiptReportFilters;
  final bool? creditReceiptSuccess;
  final String? creditReceiptError;
  final List<CreditReceipt> creditReceiptsReport;
  final int creditReceiptReportPage;
  final int creditReceiptReportPageSize;
  final int creditReceiptReportTotalCount;
  final int creditReceiptReportTotalPages;
  final bool hasMoreCreditReceiptReport;

  // Sales Transaction Report fields
  final List<SalesOrderHeader> salesTransactionHeaders;
  final List<SalesOrderDetail> salesTransactionDetails;
  final SalesTransactionReportFilters salesTransactionFilters;
  final SalesTransactionReportTotals? salesTransactionTotals;
  final int salesTransactionPage;
  final int salesTransactionPageSize;
  final int salesTransactionTotalCount;
  final int salesTransactionTotalPages;
  final bool hasMoreSalesTransaction;
  final String? exportSalesTransactionMessage;

  // Aged Credit Receipt Report fields
  final List<SalesOrderHeader> agedCreditReceiptReport;
  final SalesTransactionReportFilters agedCreditReceiptReportFilters;
  final AgedCreditReceiptTotals? agedCreditReceiptReportTotals;
  final int agedCreditReceiptReportPage;
  final int agedCreditReceiptReportPageSize;
  final int agedCreditReceiptReportTotalCount;
  final int agedCreditReceiptReportTotalPages;
  final bool hasMoreAgedCreditReceiptReport;
  final String? exportAgedCreditReceiptReportMessage;

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
    this.selected4,
    this.editingItem,
    this.searchQuery,
    this.isSelectionMode = false,
    this.filters,
    this.voidedHeaders = const [],
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
    this.dateForCreditFrom,
    this.dateForCreditTo,
    this.paymentMethod,
    this.orderStatus,
    this.applyWH = false,
    this.discountval = false,
    this.allDetailTransactions = false,
    this.fsNumber,
    this.systemConstants,
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
    this.applyWithholding = false,
    this.salesOrderDetail,
    this.uomConversionResult,
    this.lotValidationResult,
    this.validationResult,
    this.defaultCustomer,
    this.exportedSales,
    this.selectedCreditReceipt,
    this.creditReceipts = const [],
    this.filteredCreditReceipts = const [],

    this.creditReceiptSuccess,
    this.creditReceiptError,
    this.salesTransactionHeaders = const [],
    this.salesTransactionDetails = const [],
    this.salesTransactionFilters = const SalesTransactionReportFilters(),
    this.salesTransactionTotals,
    this.salesTransactionPage = 1,
    this.salesTransactionPageSize = 25,
    this.salesTransactionTotalCount = 0,
    this.salesTransactionTotalPages = 1,
    this.hasMoreSalesTransaction = false,
    this.exportSalesTransactionMessage,
    this.creditReceiptReportFilters = const SalesTransactionReportFilters(),
    this.creditReceiptsReport = const [],
    this.creditReceiptReportPage = 1,
    this.creditReceiptReportPageSize = 20,
    this.creditReceiptReportTotalCount = 0,
    this.creditReceiptReportTotalPages = 1,
    this.hasMoreCreditReceiptReport = false,

    this.agedCreditReceiptReport = const [],
    this.agedCreditReceiptReportFilters = const SalesTransactionReportFilters(),
    this.agedCreditReceiptReportTotals,
    this.agedCreditReceiptReportPage = 1,
    this.agedCreditReceiptReportPageSize = 20,
    this.agedCreditReceiptReportTotalCount = 0,
    this.agedCreditReceiptReportTotalPages = 1,
    this.hasMoreAgedCreditReceiptReport = false,
    this.exportAgedCreditReceiptReportMessage,
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
  bool get hasSalesOrderDetail => salesOrderDetail != null;
  bool get hasVoidedHeaders => voidedHeaders.isNotEmpty;
  bool get hasSystemConstants => systemConstants != null;
  bool get hasUOMConversionResult => uomConversionResult != null;
  bool get hasLotValidationResult => lotValidationResult != null;
  bool get hasValidationResult => validationResult != null;
  bool get hasDefaultCustomer => defaultCustomer != null;
  bool get hasExportedSales => exportedSales != null;

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
  DateTime get effectiveStartDateForSales =>
      startDateForSales ?? DateTime(DateTime.now().year, 1, 1);
  DateTime get effectiveThruDateForSales => thruDateForSales ?? DateTime.now();
  DateTime get effectiveDateOrderStart =>
      dateOrderStart ?? DateTime(DateTime.now().year, 1, 1);
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
    SalesOrderHeader? selected4,
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
    DateTime? dateForCreditFrom,
    DateTime? dateForCreditTo,
    String? paymentMethod,
    String? orderStatus,
    bool? applyWH,
    bool? discountval,
    bool? allDetailTransactions,
    List<SalesOrderHeader>? voidedHeaders,
    String? fsNumber,
    SystemConstant? systemConstants,
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
    bool? applyWithholding,
    List<SalesOrderDetail>? salesOrderDetail,
    UOMConversionResult? uomConversionResult,
    LotValidationResult? lotValidationResult,
    ValidationResult? validationResult,
    Customer? defaultCustomer,
    SalesOrderHeader? exportedSales,
    CreditReceipt? selectedCreditReceipt,
    List<CreditReceipt>? creditReceipts,
    List<CreditReceipt>? filteredCreditReceipts,

    List<SalesOrderHeader>? salesTransactionHeaders,
    List<SalesOrderDetail>? salesTransactionDetails,
    SalesTransactionReportFilters? salesTransactionFilters,
    SalesTransactionReportTotals? salesTransactionTotals,
    int? salesTransactionPage,
    int? salesTransactionPageSize,
    int? salesTransactionTotalCount,
    int? salesTransactionTotalPages,
    bool? hasMoreSalesTransaction,
    String? exportSalesTransactionMessage,
    SalesTransactionReportFilters? creditReceiptReportFilters,
    List<CreditReceipt>? creditReceiptsReport,
    bool? creditReceiptSuccess,
    String? creditReceiptError,
    int? creditReceiptReportPage,
    int? creditReceiptReportPageSize,
    int? creditReceiptReportTotalCount,
    int? creditReceiptReportTotalPages,
    bool? hasMoreCreditReceiptReport,

    SalesTransactionReportFilters? agedCreditReceiptReportFilters,
    List<SalesOrderHeader>? agedCreditReceiptReport,
    AgedCreditReceiptTotals? agedCreditReceiptReportTotals,
    int? agedCreditReceiptReportPage,
    int? agedCreditReceiptReportPageSize,
    int? agedCreditReceiptReportTotalCount,
    int? agedCreditReceiptReportTotalPages,
    bool? hasMoreAgedCreditReceiptReport,
    String? exportAgedCreditReceiptReportMessage,
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
      multiselectionItemsForVoid:
          multiselectionItemsForVoid ?? this.multiselectionItemsForVoid,
      selected: selected ?? this.selected,
      selected1: selected1 ?? this.selected1,
      selected2: selected2 ?? this.selected2,
      selected3: selected3 ?? this.selected3,
      selected4: selected4 ?? this.selected4,
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
      dateForCreditFrom: dateForCreditFrom ?? this.dateForCreditFrom,
      dateForCreditTo: dateForCreditTo ?? this.dateForCreditTo,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      orderStatus: orderStatus ?? this.orderStatus,
      applyWH: applyWH ?? this.applyWH,
      discountval: discountval ?? this.discountval,
      allDetailTransactions:
          allDetailTransactions ?? this.allDetailTransactions,
      voidedHeaders: voidedHeaders ?? this.voidedHeaders,
      fsNumber: fsNumber ?? this.fsNumber,
      systemConstants: systemConstants ?? this.systemConstants,
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
      applyWithholding: applyWithholding ?? this.applyWithholding,
      salesOrderDetail: salesOrderDetail ?? this.salesOrderDetail,
      uomConversionResult: uomConversionResult ?? this.uomConversionResult,
      lotValidationResult: lotValidationResult ?? this.lotValidationResult,
      validationResult: validationResult ?? this.validationResult,
      defaultCustomer: defaultCustomer ?? this.defaultCustomer,
      exportedSales: exportedSales ?? this.exportedSales,
      selectedCreditReceipt:
          selectedCreditReceipt ?? this.selectedCreditReceipt,
      creditReceipts: creditReceipts ?? this.creditReceipts,
      filteredCreditReceipts:
          filteredCreditReceipts ?? this.filteredCreditReceipts,

      creditReceiptSuccess: creditReceiptSuccess ?? this.creditReceiptSuccess,
      creditReceiptError: creditReceiptError ?? this.creditReceiptError,
      salesTransactionHeaders:
          salesTransactionHeaders ?? this.salesTransactionHeaders,
      salesTransactionDetails:
          salesTransactionDetails ?? this.salesTransactionDetails,
      salesTransactionFilters:
          salesTransactionFilters ?? this.salesTransactionFilters,
      salesTransactionTotals:
          salesTransactionTotals ?? this.salesTransactionTotals,
      salesTransactionPage: salesTransactionPage ?? this.salesTransactionPage,
      salesTransactionPageSize:
          salesTransactionPageSize ?? this.salesTransactionPageSize,
      salesTransactionTotalCount:
          salesTransactionTotalCount ?? this.salesTransactionTotalCount,
      salesTransactionTotalPages:
          salesTransactionTotalPages ?? this.salesTransactionTotalPages,
      hasMoreSalesTransaction:
          hasMoreSalesTransaction ?? this.hasMoreSalesTransaction,
      exportSalesTransactionMessage:
          exportSalesTransactionMessage ?? this.exportSalesTransactionMessage,
      creditReceiptsReport: creditReceiptsReport ?? this.creditReceiptsReport,
      creditReceiptReportFilters:
          creditReceiptReportFilters ?? this.creditReceiptReportFilters,
      creditReceiptReportPage:
          creditReceiptReportPage ?? this.creditReceiptReportPage,
      creditReceiptReportPageSize:
          creditReceiptReportPageSize ?? this.creditReceiptReportPageSize,
      creditReceiptReportTotalCount:
          creditReceiptReportTotalCount ?? this.creditReceiptReportTotalCount,
      creditReceiptReportTotalPages:
          creditReceiptReportTotalPages ?? this.creditReceiptReportTotalPages,
      hasMoreCreditReceiptReport:
          hasMoreCreditReceiptReport ?? this.hasMoreCreditReceiptReport,

      agedCreditReceiptReport:
          agedCreditReceiptReport ?? this.agedCreditReceiptReport,
      agedCreditReceiptReportFilters:
          agedCreditReceiptReportFilters ?? this.agedCreditReceiptReportFilters,
      agedCreditReceiptReportPage:
          agedCreditReceiptReportPage ?? this.agedCreditReceiptReportPage,
      agedCreditReceiptReportPageSize:
          agedCreditReceiptReportPageSize ??
          this.agedCreditReceiptReportPageSize,
      agedCreditReceiptReportTotalCount:
          agedCreditReceiptReportTotalCount ??
          this.agedCreditReceiptReportTotalCount,
      agedCreditReceiptReportTotalPages:
          agedCreditReceiptReportTotalPages ??
          this.agedCreditReceiptReportTotalPages,
      hasMoreAgedCreditReceiptReport:
          hasMoreAgedCreditReceiptReport ?? this.hasMoreAgedCreditReceiptReport,
      exportAgedCreditReceiptReportMessage:
          exportAgedCreditReceiptReportMessage ??
          this.exportAgedCreditReceiptReportMessage,
    );
  }

  // Helper methods for common state transitions
  SalesOrderHeaderState loadingState() => copyWith(
    status: SalesOrderHeaderStatus.loading,
    error: null,
    successmessage: null,
  );

  SalesOrderHeaderState loadingMoreState() => copyWith(
    status: SalesOrderHeaderStatus.loadingMore,
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

  SalesOrderHeaderState clearMessages() =>
      copyWith(error: null, successmessage: null);

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
    Customer? defaultCustomer,
  }) => copyWith(
    tinNumber: tinNumber,
    phoneNumbers: phoneNumbers,
    countryDesc: countryDesc,
    stateDesc: stateDesc,
    regionDesc: regionDesc,
    cityDesc: cityDesc,
    defaultCustomer: defaultCustomer,
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
    selected4,
    editingItem,
    searchQuery,
    isSelectionMode,
    filters,
    voidedHeaders,
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
    dateForCreditFrom,
    dateForCreditTo,
    paymentMethod,
    orderStatus,
    applyWH,
    discountval,
    allDetailTransactions,
    fsNumber,
    systemConstants,
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
    applyWithholding,
    salesOrderDetail,
    lotValidationResult,
    validationResult,
    defaultCustomer,
    exportedSales,
    selectedCreditReceipt,
    creditReceipts,
    filteredCreditReceipts,

    salesTransactionHeaders,
    salesTransactionDetails,
    salesTransactionFilters,
    salesTransactionTotals,
    salesTransactionPage,
    salesTransactionPageSize,
    salesTransactionTotalCount,
    salesTransactionTotalPages,
    hasMoreSalesTransaction,

    exportSalesTransactionMessage,
    creditReceiptReportFilters,
    creditReceiptSuccess,
    creditReceiptError,
    creditReceiptsReport,
    creditReceiptReportPage,
    creditReceiptReportPageSize,
    creditReceiptReportTotalCount,
    creditReceiptReportTotalPages,
    hasMoreCreditReceiptReport,

    agedCreditReceiptReport,
    agedCreditReceiptReportFilters,
    agedCreditReceiptReportPage,
    agedCreditReceiptReportPageSize,
    agedCreditReceiptReportTotalCount,
    agedCreditReceiptReportTotalPages,
    hasMoreAgedCreditReceiptReport,
    exportAgedCreditReceiptReportMessage,
  ];
}

class UOMConversionResult {
  final double convertedQuantity;
  final double conversionFactor;
  final int fromUOM;
  final int toUOM;
  final bool isSuccess;

  const UOMConversionResult({
    required this.convertedQuantity,
    required this.conversionFactor,
    required this.fromUOM,
    required this.toUOM,
    required this.isSuccess,
  });
}

class LotValidationResult {
  final bool isValid;
  final LotMaster? recommendedLot;
  final double availableQuantity;
  final String message;
  final List<LotMaster> availableLots;

  const LotValidationResult({
    required this.isValid,
    this.recommendedLot,
    required this.availableQuantity,
    required this.message,
    required this.availableLots,
  });
}

class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  final Map<int, double>
  availableQuantities; // item_in_branch_id -> available_qty

  const ValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
    required this.availableQuantities,
  });

  String get combinedErrorMessage => errors.join('\n');
  String get combinedWarningMessage => warnings.join('\n');
}
