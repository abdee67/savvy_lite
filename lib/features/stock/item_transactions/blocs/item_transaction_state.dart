import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/stock/item_transactions/model/item_transaction_model.dart';

enum ItemTransactionsStatus {
  initial,
  loading,
  loaded,
  saving,
  deleting,
  success,
  failure,
}

class ItemTransactionsState extends Equatable {
  final ItemTransactionsStatus status;
  final List<ItemTransactionModel> items;
  final List<ItemTransactionModel> filteredItems;
  final List<ItemTransactionModel> createItems;
  final List<ItemTransactionModel> editItems;
  final String? message;
  final List<ItemTransactionModel> selectedItems;
  final ItemTransactionModel? selected;
  final ItemTransactionModel? editingItem;
  final String? searchQuery;
  final bool isSelectionMode;
  final Map<String, dynamic>? filters;
  final double totalQuantity;
  final double totalCost;
  final double openingBalance;
  final bool isDuplicate;

  const ItemTransactionsState({
    this.status = ItemTransactionsStatus.initial,
    this.items = const [],
    this.filteredItems = const [],
    this.createItems = const [],
    this.editItems = const [],
    this.message,
    this.selectedItems = const [],
    this.selected,
    this.editingItem,
    this.searchQuery,
    this.isSelectionMode = false,
    this.filters,
    this.totalQuantity = 0.0,
    this.totalCost = 0.0,
    this.openingBalance = 0.0,
    this.isDuplicate = false,
  });

  ItemTransactionsState copyWith({
    ItemTransactionsStatus? status,
    List<ItemTransactionModel>? items,
    List<ItemTransactionModel>? filteredItems,
    List<ItemTransactionModel>? createItems,
    List<ItemTransactionModel>? editItems,
    String? message,
    List<ItemTransactionModel>? selectedItems,
    ItemTransactionModel? selected,
    ItemTransactionModel? editingItem,
    String? searchQuery,
    bool? isSelectionMode,
    Map<String, dynamic>? filters,
    double? totalQuantity,
    double? totalCost,
    double? openingBalance,
    bool? isDuplicate,
  }) {
    return ItemTransactionsState(
      status: status ?? this.status,
      items: items ?? this.items,
      filteredItems: filteredItems ?? this.filteredItems,
      createItems: createItems ?? this.createItems,
      editItems: editItems ?? this.editItems,
      message: message ?? this.message,
      selectedItems: selectedItems ?? this.selectedItems,
      selected: selected ?? this.selected,
      editingItem: editingItem ?? this.editingItem,
      searchQuery: searchQuery ?? this.searchQuery,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      filters: filters ?? this.filters,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      totalCost: totalCost ?? this.totalCost,
      openingBalance: openingBalance ?? this.openingBalance,
      isDuplicate: isDuplicate ?? this.isDuplicate,
    );
  }

  @override
  List<Object?> get props => [
        status,
        items,
        filteredItems,
        message,
        selectedItems,
        searchQuery,
        isSelectionMode,
        filters,
        totalQuantity,
        totalCost,
      ];
}
