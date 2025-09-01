import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/models/item_in_store.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/models/confirmed_items.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/models/selected_item.dart';

enum ItemEntryStatus { initial, loading, success, failure }

class ItemEntryState extends Equatable {
  final ItemEntryStatus status;
  final List<ItemInStore> itemsInStores;
  final List<SelectedItem> selectedItems;
  final List<ConfirmedItem> confirmedItems;
  final bool useBarcode;
  final String? errorMessage;
  final double totalAmount;

  const ItemEntryState({
    this.status = ItemEntryStatus.initial,
    this.itemsInStores = const [],
    this.selectedItems = const [],
    this.confirmedItems = const [],
    this.useBarcode = false,
    this.errorMessage,
    this.totalAmount = 0,
  });

  ItemEntryState copyWith({
    ItemEntryStatus? status,
    List<ItemInStore>? itemsInStores,
    List<SelectedItem>? selectedItems,
    List<ConfirmedItem>? confirmedItems,
    bool? useBarcode,
    String? errorMessage,
    double? totalAmount,
  }) {
    return ItemEntryState(
      status: status ?? this.status,
      itemsInStores: itemsInStores ?? this.itemsInStores,
      selectedItems: selectedItems ?? this.selectedItems,
      confirmedItems: confirmedItems ?? this.confirmedItems,
      useBarcode: useBarcode ?? this.useBarcode,
      errorMessage: errorMessage ?? this.errorMessage,
      totalAmount: totalAmount ?? this.totalAmount,
    );
  }

  bool get hasValidItems => selectedItems.any((item) => item.isValid);
  bool get hasConfirmedItems => confirmedItems.isNotEmpty;

  @override
  List<Object?> get props => [
    status,
    itemsInStores,
    selectedItems,
    confirmedItems,
    useBarcode,
    errorMessage,
    totalAmount,
  ];
}
