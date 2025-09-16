import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/sales/customer/models/customer_model.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/models/item_in_store.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/models/confirmed_item.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/models/items.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/models/selected_item.dart';

enum ItemEntryStatus { initial, loading, success, failure }

class ItemEntryState extends Equatable {
  final ItemEntryStatus status;
  final List<Item> uniqueItems;
  final List<ItemInStore> itemsInStores;
  final List<SelectedItem> selectedItems;
  final List<ConfirmedItem> confirmedItems;
  final bool useBarcode;
  final String? errorMessage;
  final double totalAmount;
  final Customer customer;
  final List<int> selectedConfirmedItemIndices;

  const ItemEntryState({
    this.status = ItemEntryStatus.initial,
    this.itemsInStores = const [],
    this.selectedItems = const [],
    this.confirmedItems = const [],
    this.uniqueItems = const [],
    this.useBarcode = false,
    this.errorMessage,
    this.totalAmount = 0,
    this.customer = const Customer(
      id: '',
      name: '',
      tin: '',
      phone: '',
      country: '',
    ),
    this.selectedConfirmedItemIndices = const [],
  });

  ItemEntryState copyWith({
    ItemEntryStatus? status,
    List<ItemInStore>? itemsInStores,
    List<SelectedItem>? selectedItems,
    List<ConfirmedItem>? confirmedItems,
    List<Item>? uniqueItems,
    Customer? customer,
    bool? useBarcode,
    String? errorMessage,
    double? totalAmount,
    List<int>? selectedConfirmedItemIndices,
  }) {
    return ItemEntryState(
      status: status ?? this.status,
      itemsInStores: itemsInStores ?? this.itemsInStores,
      selectedItems: selectedItems ?? this.selectedItems,
      confirmedItems: confirmedItems ?? this.confirmedItems,
      customer: customer ?? this.customer,
      uniqueItems: uniqueItems ?? this.uniqueItems,
      useBarcode: useBarcode ?? this.useBarcode,
      errorMessage: errorMessage ?? this.errorMessage,
      totalAmount: totalAmount ?? this.totalAmount,
      selectedConfirmedItemIndices:
          selectedConfirmedItemIndices ?? this.selectedConfirmedItemIndices,
    );
  }

  bool get hasValidItems => selectedItems.any((item) => item.isValid);

  bool get hasConfirmedItems => confirmedItems.isNotEmpty;
  bool get hasItems => uniqueItems.isNotEmpty;
  bool get hasSelectedConfirmedItems => selectedConfirmedItemIndices.isNotEmpty;

  @override
  List<Object?> get props => [
    status,
    itemsInStores,
    selectedItems,
    confirmedItems,
    customer,
    uniqueItems,
    useBarcode,
    errorMessage,
    totalAmount,
    selectedConfirmedItemIndices,
  ];
}
