import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/sales/invoice/header/model/invoice_header_model.dart';

enum InvoiceHistoryHeaderStatus {
  initial,
  loading,
  loaded,
  creating,
  updating,
  deleting,
  saving,
  success,
  failure,
  filtering,
}

class InvoiceHistoryHeaderState extends Equatable {
  final InvoiceHistoryHeaderStatus status;
  final List<InvoiceHistoryHeader> items;
  final List<InvoiceHistoryHeader> filteredValues;
  final List<InvoiceHistoryHeader> createItems;
  final List<InvoiceHistoryHeader> editItems;
  final List<InvoiceHistoryHeader> multiselectionItems;
  final List<InvoiceHistoryHeader> selectedItems;
  final InvoiceHistoryHeader? selected;
  final InvoiceHistoryHeader? selected1;
  final InvoiceHistoryHeader? selected2;
  final InvoiceHistoryHeader? selected3;
  final String message;
  final String errorMessage;
  final String successMessage;
  final int? companyId;
  final String? searchQuery;
  final bool isSelectionMode;

  const InvoiceHistoryHeaderState({
    this.status = InvoiceHistoryHeaderStatus.initial,
    this.items = const [],
    this.filteredValues = const [],
    this.createItems = const [],
    this.editItems = const [],
    this.multiselectionItems = const [],
    this.selectedItems = const [],
    this.selected,
    this.selected1,
    this.selected2,
    this.selected3,
    this.message = '',
    this.errorMessage = '',
    this.successMessage = '',
    this.companyId,
    this.searchQuery,
    this.isSelectionMode = false,
  });

  InvoiceHistoryHeaderState copyWith({
    InvoiceHistoryHeaderStatus? status,
    List<InvoiceHistoryHeader>? items,
    List<InvoiceHistoryHeader>? filteredValues,
    List<InvoiceHistoryHeader>? createItems,
    List<InvoiceHistoryHeader>? editItems,
    List<InvoiceHistoryHeader>? multiselectionItems,
    List<InvoiceHistoryHeader>? selectedItems,
    InvoiceHistoryHeader? selected,
    InvoiceHistoryHeader? selected1,
    InvoiceHistoryHeader? selected2,
    InvoiceHistoryHeader? selected3,
    String? message,
    String? errorMessage,
    String? successMessage,
    int? companyId,
    String? searchQuery,
    bool? isSelectionMode,
  }) {
    return InvoiceHistoryHeaderState(
      status: status ?? this.status,
      items: items ?? this.items,
      filteredValues: filteredValues ?? this.filteredValues,
      createItems: createItems ?? this.createItems,
      editItems: editItems ?? this.editItems,
      multiselectionItems: multiselectionItems ?? this.multiselectionItems,
      selectedItems: selectedItems ?? this.selectedItems,
      selected: selected ?? this.selected,
      selected1: selected1 ?? this.selected1,
      selected2: selected2 ?? this.selected2,
      selected3: selected3 ?? this.selected3,
      message: message ?? this.message,
      errorMessage: errorMessage ?? this.errorMessage,
      successMessage: successMessage ?? this.successMessage,
      companyId: companyId ?? this.companyId,
      searchQuery: searchQuery ?? this.searchQuery,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
    );
  }

  bool get canEdit => multiselectionItems.length == 1;
  bool get canDelete => multiselectionItems.isNotEmpty;
  bool get hasSelection => selected != null;
  bool get hasCreateItems => createItems.isNotEmpty;
  bool get hasEditItems => editItems.isNotEmpty;

  @override
  List<Object?> get props => [
    status,
    items,
    filteredValues,
    createItems,
    editItems,
    multiselectionItems,
    selectedItems,
    selected,
    selected1,
    selected2,
    selected3,
    message,
    errorMessage,
    successMessage,
    companyId,
    searchQuery,
    isSelectionMode,
  ];
}
