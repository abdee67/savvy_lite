// features/purchase_order/bloc/purchase_order_state.dart
import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/models/purchase_order_detail_model.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/models/purchase_order_header_model.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/models/purchase_order_receiver_model.dart';
import 'package:savvy_stock/features/system_constant/models/system_constant.dart';

enum PurchaseOrderStatus {
  initial,
  loading,
  loaded,
  creating,
  updating,
  deleting,
  saving,
  filtering,
  success,
  failure,
  preparing,
  processing,
  receiving,
  error,
  partialError,
}

class PurchaseOrderState extends Equatable {
  final PurchaseOrderStatus status;

  // Header data
  final List<PurchaseOrderHeader> headers;
  final List<PurchaseOrderHeader> filteredHeaders;
  final List<PurchaseOrderHeader> creditHeaders;
  final List<PurchaseOrderHeader> createHeaders;
  final List<PurchaseOrderHeader> editHeaders;
  final List<PurchaseOrderHeader> multiselectionHeaders;
  final PurchaseOrderHeader? selectedHeader;
  final PurchaseOrderHeader? selectedHeader1;
  final PurchaseOrderHeader? selectedHeader2;
  final List<PurchaseOrderHeader>? selectedHeaders;

  // Detail data
  final List<PurchaseOrderDetail> details;
  final List<PurchaseOrderDetail> filteredDetails;
  final List<PurchaseOrderDetail> createDetails;
  final List<PurchaseOrderDetail> editDetails;
  final List<PurchaseOrderDetail> multiselectionDetails;
  final PurchaseOrderDetail? selectedDetail;
  final PurchaseOrderDetail? selectedDetail1;
  final PurchaseOrderDetail? selectedDetail2;
  final List<PurchaseOrderDetail>? selectedDetails;

  final PurchaseOrderDetail? selectedOpApply;

  // Receiver data
  final List<PurchaseOrderReceiver> receivers;
  final List<PurchaseOrderReceiver> createReceivers;
  final List<PurchaseOrderReceiver> editReceivers;
  final List<PurchaseOrderReceiver> multiselectionReceivers;
  final PurchaseOrderReceiver? selectedReceiver;
  final PurchaseOrderReceiver? selectedReceiver1;
  final PurchaseOrderReceiver? selectedReceiver2;
  final List<PurchaseOrderReceiver>? selectedReceivers;

  // Company and user info
  final int? companyId;
  final int? userId;

  // Financial data
  final double? totalAmount;
  final double? taxableAmount;
  final double? taxAmount;
  final double? amountWithhold;
  final double? amountDiscount;
  final double? amountGross;
  final double? amountOtherCosts;
  final double? amountGrandTotalCost;
  final double? amountOpenCredit;

  // Filtering data
  final DateTime? dateOrderStart;
  final DateTime? dateOrderEnd;
  final DateTime? startdateForPO;
  final DateTime? thrudateForPO;
  final DateTime? creditDueDate;
  final DateTime? receivingDates;
  final String? purchaseType;
  final String? invoiceNumber;
  final String? invoiceNumberSelection;
  final int? supplierId;
  final int? supplierTableSelection;
  final int? itemNumber;
  final String? dataFetchBy;
  final String? paymentType;

  // System data
  final SystemConstant? systemConstants;
  final int? nextOrderNumber;
  final bool? autoReceipt;
  final bool? isDuplicate;
  final bool? isValidReceipt;

  // Search and filter
  final String? searchQuery;
  final String? dataName;
  final int first;

  // UI state
  final String? error;
  final String? successMessage;
  final String? lastOperation;
  final Set<String> pendingOperations;
  final String? conversionMessage;

  // Branch and location
  final int? branchReceive;
  final int? itemLocationsSelect;

  // Statistics and reports
  final Map<String, dynamic>? statistics;
  final List<Map<String, dynamic>>? agingReport;
  final List<Map<String, dynamic>>? supplierSummary;

  const PurchaseOrderState({
    this.status = PurchaseOrderStatus.initial,
    this.headers = const [],
    this.filteredHeaders = const [],
    this.creditHeaders = const [],
    this.createHeaders = const [],
    this.editHeaders = const [],
    this.multiselectionHeaders = const [],
    this.selectedHeader,
    this.selectedHeader1,
    this.selectedHeader2,
    this.details = const [],
    this.filteredDetails = const [],
    this.createDetails = const [],
    this.editDetails = const [],
    this.multiselectionDetails = const [],
    this.selectedDetail,
    this.selectedDetail1,
    this.selectedDetail2,
    this.selectedOpApply,
    this.receivers = const [],
    this.createReceivers = const [],
    this.editReceivers = const [],
    this.multiselectionReceivers = const [],
    this.selectedReceiver,
    this.selectedReceiver1,
    this.selectedReceiver2,
    this.companyId,
    this.userId,
    this.totalAmount,
    this.taxableAmount,
    this.taxAmount,
    this.amountWithhold,
    this.amountDiscount,
    this.amountGross,
    this.amountOtherCosts,
    this.amountGrandTotalCost,
    this.amountOpenCredit,
    this.dateOrderStart,
    this.dateOrderEnd,
    this.startdateForPO,
    this.thrudateForPO,
    this.creditDueDate,
    this.receivingDates,
    this.purchaseType,
    this.invoiceNumber,
    this.invoiceNumberSelection,
    this.supplierId,
    this.supplierTableSelection,
    this.itemNumber,
    this.dataFetchBy,
    this.paymentType,
    this.systemConstants,
    this.nextOrderNumber,
    this.autoReceipt,
    this.isDuplicate,
    this.isValidReceipt,
    this.searchQuery,
    this.dataName = 'PurchaseOrder',
    this.first = 0,
    this.error,
    this.successMessage,
    this.lastOperation,
    this.pendingOperations = const {},
    this.conversionMessage,
    this.branchReceive,
    this.itemLocationsSelect,
    this.statistics,
    this.agingReport,
    this.supplierSummary,
    this.selectedDetails = const [],
    this.selectedHeaders = const [],
    this.selectedReceivers = const [],
  });

  @override
  List<Object?> get props => [
    status,
    headers,
    filteredHeaders,
    creditHeaders,
    createHeaders,
    editHeaders,
    multiselectionHeaders,
    selectedHeader,
    selectedHeader1,
    selectedHeader2,
    details,
    filteredDetails,
    createDetails,
    editDetails,
    multiselectionDetails,
    selectedDetail,
    selectedDetail1,
    selectedDetail2,
    selectedOpApply,
    receivers,
    createReceivers,
    editReceivers,
    multiselectionReceivers,
    selectedReceiver,
    selectedReceiver1,
    selectedReceiver2,
    selectedDetails,
    selectedHeaders,
    selectedReceivers,
    companyId,
    userId,
    totalAmount,
    taxableAmount,
    taxAmount,
    amountWithhold,
    amountDiscount,
    amountGross,
    amountOtherCosts,
    amountGrandTotalCost,
    amountOpenCredit,
    dateOrderStart,
    dateOrderEnd,
    startdateForPO,
    thrudateForPO,
    creditDueDate,
    receivingDates,
    purchaseType,
    invoiceNumber,
    invoiceNumberSelection,
    supplierId,
    supplierTableSelection,
    itemNumber,
    dataFetchBy,
    paymentType,
    systemConstants,
    nextOrderNumber,
    autoReceipt,
    isDuplicate,
    isValidReceipt,
    searchQuery,
    dataName,
    first,
    error,
    successMessage,
    lastOperation,
    pendingOperations,
    conversionMessage,
    branchReceive,
    itemLocationsSelect,
    statistics,
    agingReport,
    supplierSummary,
  ];

  PurchaseOrderState copyWith({
    PurchaseOrderStatus? status,
    List<PurchaseOrderHeader>? headers,
    List<PurchaseOrderHeader>? filteredHeaders,
    List<PurchaseOrderHeader>? creditHeaders,
    List<PurchaseOrderHeader>? createHeaders,
    List<PurchaseOrderHeader>? editHeaders,
    List<PurchaseOrderHeader>? multiselectionHeaders,
    PurchaseOrderHeader? selectedHeader,
    PurchaseOrderHeader? selectedHeader1,
    PurchaseOrderHeader? selectedHeader2,
    List<PurchaseOrderDetail>? details,
    List<PurchaseOrderDetail>? filteredDetails,
    List<PurchaseOrderDetail>? createDetails,
    List<PurchaseOrderDetail>? editDetails,
    List<PurchaseOrderDetail>? multiselectionDetails,
    PurchaseOrderDetail? selectedDetail,
    PurchaseOrderDetail? selectedDetail1,
    PurchaseOrderDetail? selectedDetail2,
    PurchaseOrderDetail? selectedOpApply,
    List<PurchaseOrderReceiver>? receivers,
    List<PurchaseOrderReceiver>? createReceivers,
    List<PurchaseOrderReceiver>? editReceivers,
    List<PurchaseOrderReceiver>? multiselectionReceivers,
    PurchaseOrderReceiver? selectedReceiver,
    PurchaseOrderReceiver? selectedReceiver1,
    PurchaseOrderReceiver? selectedReceiver2,
    List<PurchaseOrderHeader>? selectedHeaders,
    List<PurchaseOrderReceiver>? selectedReceivers,
    List<PurchaseOrderDetail>? selectedDetails,

    int? companyId,
    int? userId,
    double? totalAmount,
    double? taxableAmount,
    double? taxAmount,
    double? amountWithhold,
    double? amountDiscount,
    double? amountGross,
    double? amountOtherCosts,
    double? amountGrandTotalCost,
    double? amountOpenCredit,
    DateTime? dateOrderStart,
    DateTime? dateOrderEnd,
    DateTime? startdateForPO,
    DateTime? thrudateForPO,
    DateTime? creditDueDate,
    DateTime? receivingDates,
    String? purchaseType,
    String? invoiceNumber,
    String? invoiceNumberSelection,
    int? supplierId,
    int? supplierTableSelection,
    int? itemNumber,
    String? dataFetchBy,
    String? paymentType,
    SystemConstant? systemConstants,
    int? nextOrderNumber,
    bool? autoReceipt,
    bool? isDuplicate,
    bool? isValidReceipt,
    String? searchQuery,
    String? dataName,
    int? first,
    String? error,
    String? successMessage,
    String? lastOperation,
    Set<String>? pendingOperations,
    String? conversionMessage,
    int? branchReceive,
    int? itemLocationsSelect,
    Map<String, dynamic>? statistics,
    List<Map<String, dynamic>>? agingReport,
    List<Map<String, dynamic>>? supplierSummary,
  }) {
    return PurchaseOrderState(
      status: status ?? this.status,
      headers: headers ?? this.headers,
      filteredHeaders: filteredHeaders ?? this.filteredHeaders,
      creditHeaders: creditHeaders ?? this.creditHeaders,
      createHeaders: createHeaders ?? this.createHeaders,
      editHeaders: editHeaders ?? this.editHeaders,
      multiselectionHeaders:
          multiselectionHeaders ?? this.multiselectionHeaders,
      selectedHeader: selectedHeader ?? this.selectedHeader,
      selectedHeader1: selectedHeader1 ?? this.selectedHeader1,
      selectedHeader2: selectedHeader2 ?? this.selectedHeader2,
      details: details ?? this.details,
      filteredDetails: filteredDetails ?? this.filteredDetails,
      createDetails: createDetails ?? this.createDetails,
      editDetails: editDetails ?? this.editDetails,
      multiselectionDetails:
          multiselectionDetails ?? this.multiselectionDetails,
      selectedDetail: selectedDetail ?? this.selectedDetail,
      selectedDetail1: selectedDetail1 ?? this.selectedDetail1,
      selectedDetail2: selectedDetail2 ?? this.selectedDetail2,
      selectedOpApply: selectedOpApply ?? this.selectedOpApply,
      receivers: receivers ?? this.receivers,
      createReceivers: createReceivers ?? this.createReceivers,
      editReceivers: editReceivers ?? this.editReceivers,
      multiselectionReceivers:
          multiselectionReceivers ?? this.multiselectionReceivers,
      selectedReceiver: selectedReceiver ?? this.selectedReceiver,
      selectedReceiver1: selectedReceiver1 ?? this.selectedReceiver1,
      selectedReceiver2: selectedReceiver2 ?? this.selectedReceiver2,
      companyId: companyId ?? this.companyId,
      userId: userId ?? this.userId,
      totalAmount: totalAmount ?? this.totalAmount,
      taxableAmount: taxableAmount ?? this.taxableAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      amountWithhold: amountWithhold ?? this.amountWithhold,
      amountDiscount: amountDiscount ?? this.amountDiscount,
      amountGross: amountGross ?? this.amountGross,
      amountOtherCosts: amountOtherCosts ?? this.amountOtherCosts,
      amountGrandTotalCost: amountGrandTotalCost ?? this.amountGrandTotalCost,
      amountOpenCredit: amountOpenCredit ?? this.amountOpenCredit,
      dateOrderStart: dateOrderStart ?? this.dateOrderStart,
      dateOrderEnd: dateOrderEnd ?? this.dateOrderEnd,
      startdateForPO: startdateForPO ?? this.startdateForPO,
      thrudateForPO: thrudateForPO ?? this.thrudateForPO,
      creditDueDate: creditDueDate ?? this.creditDueDate,
      receivingDates: receivingDates ?? this.receivingDates,
      purchaseType: purchaseType ?? this.purchaseType,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      invoiceNumberSelection:
          invoiceNumberSelection ?? this.invoiceNumberSelection,
      supplierId: supplierId ?? this.supplierId,
      supplierTableSelection:
          supplierTableSelection ?? this.supplierTableSelection,
      itemNumber: itemNumber ?? this.itemNumber,
      dataFetchBy: dataFetchBy ?? this.dataFetchBy,
      paymentType: paymentType ?? this.paymentType,
      systemConstants: systemConstants ?? this.systemConstants,
      nextOrderNumber: nextOrderNumber ?? this.nextOrderNumber,
      autoReceipt: autoReceipt ?? this.autoReceipt,
      isDuplicate: isDuplicate ?? this.isDuplicate,
      isValidReceipt: isValidReceipt ?? this.isValidReceipt,
      searchQuery: searchQuery ?? this.searchQuery,
      dataName: dataName ?? this.dataName,
      first: first ?? this.first,
      error: error,
      successMessage: successMessage,
      lastOperation: lastOperation ?? this.lastOperation,
      pendingOperations: pendingOperations ?? this.pendingOperations,
      conversionMessage: conversionMessage ?? this.conversionMessage,
      branchReceive: branchReceive ?? this.branchReceive,
      itemLocationsSelect: itemLocationsSelect ?? this.itemLocationsSelect,
      statistics: statistics ?? this.statistics,
      agingReport: agingReport ?? this.agingReport,
      supplierSummary: supplierSummary ?? this.supplierSummary,
      selectedDetails: selectedDetails ?? this.selectedDetails,
      selectedHeaders: selectedHeaders ?? this.selectedHeaders,
      selectedReceivers: selectedReceivers ?? this.selectedReceivers,
    );
  }

  // Helper methods for state transitions
  PurchaseOrderState loadingState(String operation) {
    return copyWith(
      status: PurchaseOrderStatus.loading,
      pendingOperations: {...pendingOperations, operation},
      error: null,
      successMessage: null,
    );
  }

  PurchaseOrderState successState(String message) {
    return copyWith(
      status: PurchaseOrderStatus.success,
      successMessage: message,
      error: null,
    );
  }

  PurchaseOrderState errorState(String error) {
    return copyWith(
      status: PurchaseOrderStatus.error,
      error: error,
      successMessage: null,
    );
  }

  PurchaseOrderState processingState(String operation) {
    return copyWith(
      status: PurchaseOrderStatus.processing,
      pendingOperations: {...pendingOperations, operation},
      lastOperation: operation,
    );
  }

  PurchaseOrderState receivingState() {
    return copyWith(status: PurchaseOrderStatus.receiving);
  }

  PurchaseOrderState clearFiltersState() {
    return copyWith(
      filteredHeaders: headers,
      filteredDetails: details,
      dateOrderStart: null,
      dateOrderEnd: null,
      startdateForPO: null,
      thrudateForPO: null,
      purchaseType: null,
      invoiceNumber: null,
      invoiceNumberSelection: null,
      supplierId: null,
      supplierTableSelection: null,
      itemNumber: null,
      searchQuery: null,
      selectedHeader2: PurchaseOrderHeader(orderNumber: 0, company: companyId),
    );
  }
}
