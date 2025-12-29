import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/sales/sales_order/invoice/detail/model/invoice_detail_model.dart';

enum InvoiceHistoryDetailStatus {
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

class InvoiceHistoryDetailState extends Equatable {
  final InvoiceHistoryDetailStatus status;
  final List<InvoiceHistoryDetail> items;
  final List<InvoiceHistoryDetail> filteredValues;
  final List<InvoiceHistoryDetail> createItems;
  final List<InvoiceHistoryDetail> editItems;
  final List<InvoiceHistoryDetail> multiselectionItems;
  final List<InvoiceHistoryDetail> selectedItems;
  final InvoiceHistoryDetail? selected;
  final InvoiceHistoryDetail? selected1;
  final InvoiceHistoryDetail? selected2;
  final InvoiceHistoryDetail? selected3;
  final String message;
  final String errorMessage;
  final String successMessage;
  final int? companyId;
  final String? searchQuery;
  final bool isSelectionMode;

  const InvoiceHistoryDetailState({
    this.status = InvoiceHistoryDetailStatus.initial,
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

  InvoiceHistoryDetailState copyWith({
    InvoiceHistoryDetailStatus? status,
    List<InvoiceHistoryDetail>? items,
    List<InvoiceHistoryDetail>? filteredValues,
    List<InvoiceHistoryDetail>? createItems,
    List<InvoiceHistoryDetail>? editItems,
    List<InvoiceHistoryDetail>? multiselectionItems,
    List<InvoiceHistoryDetail>? selectedItems,
    InvoiceHistoryDetail? selected,
    InvoiceHistoryDetail? selected1,
    InvoiceHistoryDetail? selected2,
    InvoiceHistoryDetail? selected3,
    String? message,
    String? errorMessage,
    String? successMessage,
    int? companyId,
    String? searchQuery,
    bool? isSelectionMode,
  }) {
    return InvoiceHistoryDetailState(
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
  bool get hasItems => items.isNotEmpty;
  bool get isLoading => status == InvoiceHistoryDetailStatus.loading;
  bool get isCreating => status == InvoiceHistoryDetailStatus.creating;
  bool get isSaving => status == InvoiceHistoryDetailStatus.saving;

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
