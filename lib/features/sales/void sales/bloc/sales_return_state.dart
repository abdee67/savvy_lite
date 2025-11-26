// features/sales/sales_return/bloc/sales_return_state.dart

import 'package:savvy_stock/features/sales/void%20sales/models/void_sales_details.dart';
import 'package:savvy_stock/features/sales/void%20sales/models/void_sales_header.dart';

enum SalesReturnStatus {
  initial,
  loading,
  loaded,
  creating,
  updating,
  deleting,
  submitting,
  success,
  failure,
  validatingStock,
}

class SalesReturnState {
  final SalesReturnStatus status;
  final List<SalesReturnHeader> headers;
  final List<SalesReturnDetails> details;
  final List<SalesReturnHeader> filteredHeaders;
  final List<SalesReturnHeader> createItems;
  final List<SalesReturnDetails> createDetails;
  final SalesReturnHeader? selectedHeader;
  final SalesReturnDetails? selectedDetail;
  final int? companyId;
  final String? errorMessage;
  final String? successMessage;

  // Financials
  final double subTotal;
  final double tax;
  final double withholdAmount;
  final double totalAmount;
  final double discountAmount;
  final bool applyWH;

  // UI State
  final String? fsNumber;
  final String? paymentType;
  final int first;
  final String? searchQuery;

  const SalesReturnState({
    this.status = SalesReturnStatus.initial,
    this.headers = const [],
    this.details = const [],
    this.filteredHeaders = const [],
    this.createItems = const [],
    this.createDetails = const [],
    this.selectedHeader,
    this.selectedDetail,
    this.companyId,
    this.errorMessage,
    this.successMessage,
    this.subTotal = 0.0,
    this.tax = 0.0,
    this.withholdAmount = 0.0,
    this.totalAmount = 0.0,
    this.discountAmount = 0.0,
    this.applyWH = false,
    this.fsNumber,
    this.paymentType = 'Cash',
    this.first = 0,
    this.searchQuery,
  });

  SalesReturnState copyWith({
    SalesReturnStatus? status,
    List<SalesReturnHeader>? headers,
    List<SalesReturnDetails>? details,
    List<SalesReturnHeader>? filteredHeaders,
    List<SalesReturnHeader>? createItems,
    List<SalesReturnDetails>? createDetails,
    SalesReturnHeader? selectedHeader,
    SalesReturnDetails? selectedDetail,
    int? companyId,
    String? errorMessage,
    String? successMessage,
    double? subTotal,
    double? tax,
    double? withholdAmount,
    double? totalAmount,
    double? discountAmount,
    bool? applyWH,
    String? fsNumber,
    String? paymentType,
    int? first,
    String? searchQuery,
  }) {
    return SalesReturnState(
      status: status ?? this.status,
      headers: headers ?? this.headers,
      details: details ?? this.details,
      filteredHeaders: filteredHeaders ?? this.filteredHeaders,
      createItems: createItems ?? this.createItems,
      createDetails: createDetails ?? this.createDetails,
      selectedHeader: selectedHeader ?? this.selectedHeader,
      selectedDetail: selectedDetail ?? this.selectedDetail,
      companyId: companyId ?? this.companyId,
      errorMessage: errorMessage ?? this.errorMessage,
      successMessage: successMessage ?? this.successMessage,
      subTotal: subTotal ?? this.subTotal,
      tax: tax ?? this.tax,
      withholdAmount: withholdAmount ?? this.withholdAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      applyWH: applyWH ?? this.applyWH,
      fsNumber: fsNumber ?? this.fsNumber,
      paymentType: paymentType ?? this.paymentType,
      first: first ?? this.first,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  SalesReturnState loadingState() {
    return copyWith(status: SalesReturnStatus.loading, errorMessage: null);
  }

  SalesReturnState successState(String message) {
    return copyWith(
      status: SalesReturnStatus.success,
      successMessage: message,
      errorMessage: null,
    );
  }

  SalesReturnState errorState(String error) {
    return copyWith(
      status: SalesReturnStatus.failure,
      errorMessage: error,
      successMessage: null,
    );
  }

  SalesReturnState processingState() {
    return copyWith(status: SalesReturnStatus.submitting, errorMessage: null);
  }
}
