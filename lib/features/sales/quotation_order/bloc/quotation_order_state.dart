// features/sales/quotation_order/bloc/quotation_order_state.dart
import 'package:savvy_stock/features/sales/quotation_order/model/quotation_order_detail.dart';
import 'package:savvy_stock/features/sales/quotation_order/model/quotation_order_header.dart';
import 'package:savvy_stock/features/system_constant/models/system_constant.dart';

enum QuotationOrderStatus {
  initial,
  loading,
  loaded,
  creating,
  updating,
  deleting,
  saving,
  calculating,
  converting,
  filtering,
  success,
  failure,
}

class QuotationOrderState {
  final QuotationOrderStatus status;
  final List<QuotationOrderHeader> headers;
  final List<QuotationOrderHeader> filteredHeaders;
  final List<QuotationOrderDetail> details;
  final List<QuotationOrderHeader> createItems;
  final List<QuotationOrderHeader> editItems;
  final List<QuotationOrderHeader> multiselectionItems;
  final List<QuotationOrderDetail> createDetailItems;
  final List<QuotationOrderDetail> editDetailItems;
  final QuotationOrderHeader? selectedHeader;
  final QuotationOrderHeader? selected1;
  final QuotationOrderHeader? selected2;
  final QuotationOrderHeader? selected3;
  final QuotationOrderDetail? selectedDetail;
  final QuotationOrderDetail? selectedDetail1;
  final QuotationOrderDetail? selectedDetail2;
  final int? companyId;
  final String? error;
  final String? successMessage;

  // Financial calculations
  final double? subTotal;
  final double? tax;
  final double? withholdAmount;
  final double? totalAmount;
  final double? discountAmount;
  final bool? applyWH;
  final bool? discountval;

  // Customer info
  final String? tinNumber;
  final String? phoneNumbers;
  final String? countryDesc;
  final String? stateDesc;
  final String? regionDesc;
  final String? cityDesc;

  // Filtering
  final DateTime? dateOrderStart;
  final DateTime? dateOrderEnd;

  // Barcode
  final bool useBarcode;
  final String barCode;

  // Conversion
  final bool isConverting;
  final String? conversionMessage;

  final SystemConstant? systemConstants;
  final int? nextOrderNumber;
  final String? fsNumber;
  final String? searchQuery;

  const QuotationOrderState({
    this.status = QuotationOrderStatus.initial,
    this.headers = const [],
    this.filteredHeaders = const [],
    this.details = const [],
    this.createItems = const [],
    this.editItems = const [],
    this.multiselectionItems = const [],
    this.createDetailItems = const [],
    this.editDetailItems = const [],
    this.selectedHeader,
    this.selected1,
    this.selected2,
    this.selected3,
    this.selectedDetail,
    this.selectedDetail1,
    this.selectedDetail2,
    this.companyId,
    this.error,
    this.successMessage,
    this.subTotal,
    this.tax,
    this.withholdAmount,
    this.totalAmount,
    this.discountAmount,
    this.applyWH,
    this.discountval,
    this.tinNumber,
    this.phoneNumbers,
    this.countryDesc,
    this.stateDesc,
    this.regionDesc,
    this.cityDesc,
    this.dateOrderStart,
    this.dateOrderEnd,
    this.useBarcode = false,
    this.barCode = '',
    this.isConverting = false,
    this.conversionMessage,
    this.systemConstants,
    this.nextOrderNumber,
    this.fsNumber,
    this.searchQuery,
  });

  QuotationOrderState copyWith({
    QuotationOrderStatus? status,
    List<QuotationOrderHeader>? headers,
    List<QuotationOrderHeader>? filteredHeaders,
    List<QuotationOrderDetail>? details,
    List<QuotationOrderHeader>? createItems,
    List<QuotationOrderHeader>? editItems,
    List<QuotationOrderHeader>? multiselectionItems,
    List<QuotationOrderDetail>? createDetailItems,
    List<QuotationOrderDetail>? editDetailItems,
    QuotationOrderHeader? selectedHeader,
    QuotationOrderHeader? selected1,
    QuotationOrderHeader? selected2,
    QuotationOrderHeader? selected3,
    QuotationOrderDetail? selectedDetail,
    QuotationOrderDetail? selectedDetail1,
    QuotationOrderDetail? selectedDetail2,
    int? companyId,
    String? error,
    String? successMessage,
    double? subTotal,
    double? tax,
    double? withholdAmount,
    double? totalAmount,
    double? discountAmount,
    bool? applyWH,
    bool? discountval,
    String? tinNumber,
    String? phoneNumbers,
    String? countryDesc,
    String? stateDesc,
    String? regionDesc,
    String? cityDesc,
    DateTime? dateOrderStart,
    DateTime? dateOrderEnd,
    bool? useBarcode,
    String? barCode,
    bool? isConverting,
    String? conversionMessage,
    SystemConstant? systemConstants,
    int? nextOrderNumber,
    String? fsNumber,
    String? searchQuery,
  }) {
    return QuotationOrderState(
      status: status ?? this.status,
      headers: headers ?? this.headers,
      filteredHeaders: filteredHeaders ?? this.filteredHeaders,
      details: details ?? this.details,
      createItems: createItems ?? this.createItems,
      editItems: editItems ?? this.editItems,
      multiselectionItems: multiselectionItems ?? this.multiselectionItems,
      createDetailItems: createDetailItems ?? this.createDetailItems,
      editDetailItems: editDetailItems ?? this.editDetailItems,
      selectedHeader: selectedHeader ?? this.selectedHeader,
      selected1: selected1 ?? this.selected1,
      selected2: selected2 ?? this.selected2,
      selected3: selected3 ?? this.selected3,
      selectedDetail: selectedDetail ?? this.selectedDetail,
      selectedDetail1: selectedDetail1 ?? this.selectedDetail1,
      selectedDetail2: selectedDetail2 ?? this.selectedDetail2,
      companyId: companyId ?? this.companyId,
      error: error,
      successMessage: successMessage,
      subTotal: subTotal ?? this.subTotal,
      tax: tax ?? this.tax,
      withholdAmount: withholdAmount ?? this.withholdAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      applyWH: applyWH ?? this.applyWH,
      discountval: discountval ?? this.discountval,
      tinNumber: tinNumber ?? this.tinNumber,
      phoneNumbers: phoneNumbers ?? this.phoneNumbers,
      countryDesc: countryDesc ?? this.countryDesc,
      stateDesc: stateDesc ?? this.stateDesc,
      regionDesc: regionDesc ?? this.regionDesc,
      cityDesc: cityDesc ?? this.cityDesc,
      dateOrderStart: dateOrderStart ?? this.dateOrderStart,
      dateOrderEnd: dateOrderEnd ?? this.dateOrderEnd,
      useBarcode: useBarcode ?? this.useBarcode,
      barCode: barCode ?? this.barCode,
      isConverting: isConverting ?? this.isConverting,
      conversionMessage: conversionMessage ?? this.conversionMessage,
      systemConstants: systemConstants ?? this.systemConstants,
      nextOrderNumber: nextOrderNumber ?? this.nextOrderNumber,
      fsNumber: fsNumber ?? this.fsNumber,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  // Helper methods for common state transitions
  QuotationOrderState loadingState() => copyWith(
    status: QuotationOrderStatus.loading,
    error: null,
    successMessage: null,
  );

  QuotationOrderState successState(String message) => copyWith(
    status: QuotationOrderStatus.success,
    successMessage: message,
    error: null,
  );

  QuotationOrderState errorState(String error) => copyWith(
    status: QuotationOrderStatus.failure,
    error: error,
    successMessage: null,
  );

  QuotationOrderState calculatingState() =>
      copyWith(status: QuotationOrderStatus.calculating, error: null);

  QuotationOrderState clearFiltersState() => copyWith(
    selected3: QuotationOrderHeader(
      orderNumber: 0,
      customerBillTo: 0,
      customerTableId: 0,
      employeesId: 0,
    ),
    dateOrderStart: null,
    dateOrderEnd: null,
    filteredHeaders: headers,
  );

  QuotationOrderState updateCustomerInfo({
    String? tinNumber,
    String? phoneNumbers,
    String? countryDesc,
    String? stateDesc,
    String? regionDesc,
    String? cityDesc,
  }) {
    return copyWith(
      tinNumber: tinNumber ?? this.tinNumber,
      phoneNumbers: phoneNumbers ?? this.phoneNumbers,
      countryDesc: countryDesc ?? this.countryDesc,
      stateDesc: stateDesc ?? this.stateDesc,
      regionDesc: regionDesc ?? this.regionDesc,
      cityDesc: cityDesc ?? this.cityDesc,
    );
  }
}
