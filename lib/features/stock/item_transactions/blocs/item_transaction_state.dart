import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/stock/item_transactions/model/item_transaction_model.dart';

enum ItemTransactionsStatus {
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
}

class ItemTransactionsState extends Equatable {
  final ItemTransactionsStatus status;
  final List<ItemTransactionModel> transactions;
  final List<ItemTransactionModel> filteredTransactions;
  final List<ItemTransactionModel> createItems;
  final List<ItemTransactionModel> editItems;
  final String? successmessage;
  final String? error;
  final List<ItemTransactionModel> selectedItems;
  final ItemTransactionModel? selected;
  final ItemTransactionModel? selected1;
  final ItemTransactionModel? selected2;
  final ItemTransactionModel? editingItem;
  final String? searchQuery;
  final bool isSelectionMode;
  final Map<String, dynamic>? filters;
  final double totalQuantity;
  final double totalCost;
  final double openingAmount;
  final double totlaAmount;
  final bool isDuplicate;
  final int? companyId;

  const ItemTransactionsState({
    this.status = ItemTransactionsStatus.initial,
    this.transactions = const [],
    this.filteredTransactions = const [],
    this.createItems = const [],
    this.editItems = const [],
    this.successmessage,
    this.error,
    this.selectedItems = const [],
    this.selected,
    this.selected1,
    this.selected2,
    this.editingItem,
    this.searchQuery,
    this.isSelectionMode = false,
    this.filters,
    this.totalQuantity = 0.0,
    this.totalCost = 0.0,
    this.openingAmount = 0.0,
    this.totlaAmount = 0.0,
    this.companyId,
    this.isDuplicate = false,
  });

  bool get hasError => error != null && error!.isNotEmpty;

  bool get hasSuccess => successmessage != null && successmessage!.isNotEmpty;

  bool get hastransactions => transactions.isNotEmpty;

  bool get hasFilteredTransactions => filteredTransactions.isNotEmpty;

  bool get hasSelectedItems => selectedItems.isNotEmpty;

  bool get hasSearchQuery => searchQuery != null && searchQuery!.isNotEmpty;

  bool isLoading() => status == ItemTransactionsStatus.loading;
  bool isProcessing() => status == ItemTransactionsStatus.processing;
  bool isSaving() => status == ItemTransactionsStatus.saving;
  bool isSuccess() => status == ItemTransactionsStatus.success;
  bool isError() => status == ItemTransactionsStatus.error;
  bool isFailure() => status == ItemTransactionsStatus.failure;
  bool isDeleting() => status == ItemTransactionsStatus.deleting;
  bool isLoaded() => status == ItemTransactionsStatus.loaded;
  bool isInitial() => status == ItemTransactionsStatus.initial;
  bool isCreating() => status == ItemTransactionsStatus.creating;
  bool isUpdating() => status == ItemTransactionsStatus.updating;
  bool isDeletingMultiple() => status == ItemTransactionsStatus.deleting;

  ItemTransactionsState copyWith({
    ItemTransactionsStatus? status,
    List<ItemTransactionModel>? transactions,
    List<ItemTransactionModel>? filteredTransactions,
    List<ItemTransactionModel>? createItems,
    List<ItemTransactionModel>? editItems,
    String? successmessage,
    String? error,
    List<ItemTransactionModel>? selectedItems,
    ItemTransactionModel? selected,
    ItemTransactionModel? selected1,
    ItemTransactionModel? selected2,
    ItemTransactionModel? editingItem,
    String? searchQuery,
    bool? isSelectionMode,
    Map<String, dynamic>? filters,
    double? totalQuantity,
    double? totalCost,
    double? openingAmount,
    double? totlaAmount,
    bool? isDuplicate,
    int? companyId,
  }) {
    return ItemTransactionsState(
      status: status ?? this.status,
      transactions: transactions ?? this.transactions,
      filteredTransactions: filteredTransactions ?? this.filteredTransactions,
      createItems: createItems ?? this.createItems,
      editItems: editItems ?? this.editItems,
      successmessage: successmessage ?? this.successmessage,
      error: error ?? this.error,
      selectedItems: selectedItems ?? this.selectedItems,
      selected: selected ?? this.selected,
      selected1: selected1 ?? this.selected1,
      selected2: selected2 ?? this.selected2,
      editingItem: editingItem ?? this.editingItem,
      searchQuery: searchQuery ?? this.searchQuery,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      filters: filters ?? this.filters,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      totalCost: totalCost ?? this.totalCost,
      openingAmount: openingAmount ?? this.openingAmount,
      totlaAmount: totlaAmount ?? this.totlaAmount,
      companyId: companyId ?? this.companyId,
      isDuplicate: isDuplicate ?? this.isDuplicate,
    );
  }

  @override
  List<Object?> get props => [
        status,
        transactions,
        filteredTransactions,
        successmessage,
        error,
        selectedItems,
        selected,
        selected1,
        selected2,
        editingItem,
        createItems,
        editItems,
        openingAmount,
        totlaAmount,
        companyId,
        searchQuery,
        isSelectionMode,
        filters,
        totalQuantity,
        totalCost,
      ];
}
