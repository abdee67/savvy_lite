import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/blocs/sales_item_entry_event.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/screens/sales_item_entry.dart';
import '../models/confirmed_items.dart';
import '../models/item_in_store.dart';
import '../models/items.dart';
import '../models/selected_item.dart';
import '../models/stores.dart';
import '../blocs/sales_item_entry_state.dart';

class ItemEntryBloc extends Bloc<ItemEntryEvent, ItemEntryState> {
  ItemEntryBloc() : super(const ItemEntryState()) {
    on<LoadItemsAndStores>(_onLoadItemsAndStores);
    on<SelectItem>(_onSelectItem);
    on<SelectStore>(_onSelectStore);
    on<UpdateQuantity>(_onUpdateQuantity);
    on<AddNewItem>(_onAddNewItem);
    on<RemoveItem>(_onRemoveItem);
    on<EditItem>(_onEditItem);
    on<ConfirmOrder>(_onConfirmOrder);
    on<ToggleBarcode>(_onToggleBarcode);
    on<AddBarcodeItems>(_onAddBarcodeItems);
    on<ClearSelectedItems>(_onClearSelectedItems);
    on<ScanBarcode>(_onScanBarcode);
  }

  Future<void> _onLoadItemsAndStores(
    LoadItemsAndStores event,
    Emitter<ItemEntryState> emit,
  ) async {
    emit(state.copyWith(status: ItemEntryStatus.loading));

    try {
      // Simulate API/database call
      await Future.delayed(const Duration(milliseconds: 500));

      final items = [
        const Item(
          id: 'ITM-001',
          description: 'Laptop Computer',
          uom: 'PCS',
          barcode: 123456789000,
          unitPrice: 1000,
        ),
        const Item(
          id: 'ITM-002',
          description: 'Wireless Mouse',
          uom: 'PCS',
          barcode: 987654321000,
          unitPrice: 999.99,
        ),
        const Item(
          id: 'ITM-003',
          description: 'Keyboard',
          uom: 'PCS',
          barcode: 112233445000,
          unitPrice: 24.99,
        ),
        const Item(
          id: 'ITM-004',
          description: 'Monitor 24"',
          uom: 'PCS',
          barcode: 556677889000,
          unitPrice: 249.99,
        ),
        const Item(
          id: 'ITM-005',
          description: 'Webcam HD',
          uom: 'PCS',
          barcode: 334455667000,
          unitPrice: 149.99,
        ),
      ];

      final stores = [
        const Store(
          id: 'STR-001',
          branchName: 'Main Branch',
          unitPrice: 999.99,
          availability: 15,
        ),
        const Store(
          id: 'STR-002',
          branchName: 'Downtown Branch',
          unitPrice: 1029.99,
          availability: 8,
        ),
        const Store(
          id: 'STR-003',
          branchName: 'Westside Branch',
          unitPrice: 949.99,
          availability: 3,
        ),
        const Store(
          id: 'STR-004',
          branchName: 'North Branch',
          unitPrice: 979.99,
          availability: 0,
        ),
      ];

      final itemsInStores = [
        ItemInStore(
          item: items[0],
          availableStores: [stores[0], stores[1], stores[2]],
        ),
        ItemInStore(item: items[1], availableStores: [stores[0], stores[3]]),
        ItemInStore(
          item: items[2],
          availableStores: [stores[1], stores[2], stores[3]],
        ),
        ItemInStore(item: items[3], availableStores: []),
        ItemInStore(
          item: items[4],
          availableStores: [stores[0], stores[1], stores[2], stores[3]],
        ),
      ];

      emit(
        state.copyWith(
          status: ItemEntryStatus.success,
          itemsInStores: itemsInStores,
          selectedItems: [SelectedItem()], // Start with one empty item
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: ItemEntryStatus.failure,
          errorMessage: 'Failed to load items and stores',
        ),
      );
    }
  }

  void _onSelectItem(SelectItem event, Emitter<ItemEntryState> emit) {
    final updatedItems = List<SelectedItem>.from(state.selectedItems);

    if (event.index < updatedItems.length) {
      final availableStores = _getAvailableStoresForItem(event.item);
      final isOutOfStock = availableStores.isEmpty && event.item != null;

      updatedItems[event.index] = updatedItems[event.index].copyWith(
        item: event.item,
        store: availableStores.isNotEmpty ? availableStores.first : null,
        isOutOfStock: isOutOfStock,
      );
    }

    emit(state.copyWith(selectedItems: updatedItems));
  }

  void _onSelectStore(SelectStore event, Emitter<ItemEntryState> emit) {
    final updatedItems = List<SelectedItem>.from(state.selectedItems);

    if (event.index < updatedItems.length) {
      updatedItems[event.index] = updatedItems[event.index].copyWith(
        store: event.store,
      );
    }

    emit(state.copyWith(selectedItems: updatedItems));
  }

  void _onUpdateQuantity(UpdateQuantity event, Emitter<ItemEntryState> emit) {
    final updatedItems = List<SelectedItem>.from(state.selectedItems);

    if (event.index < updatedItems.length) {
      updatedItems[event.index] = updatedItems[event.index].copyWith(
        quantity: event.quantity,
      );
    }

    emit(state.copyWith(selectedItems: updatedItems));
  }

  void _onAddNewItem(AddNewItem event, Emitter<ItemEntryState> emit) {
    final updatedItems = List<SelectedItem>.from(state.selectedItems)
      ..add(SelectedItem());

    emit(state.copyWith(selectedItems: updatedItems));
  }

  void _onRemoveItem(RemoveItem event, Emitter<ItemEntryState> emit) {
    final updatedItems = List<SelectedItem>.from(state.selectedItems);

    if (event.index < updatedItems.length) {
      updatedItems.removeAt(event.index);
      if (updatedItems.isEmpty) {
        updatedItems.add(SelectedItem());
      }
    }

    emit(state.copyWith(selectedItems: updatedItems));
  }

  void _onEditItem(EditItem event, Emitter<ItemEntryState> emit) {
    final updatedItems = List<SelectedItem>.from(state.selectedItems);

    if (event.index < updatedItems.length) {
      updatedItems[event.index] = updatedItems[event.index].copyWith(
        item: event.item,
        store: event.store,
        quantity: event.quantity,
      );
    }

    emit(state.copyWith(selectedItems: updatedItems));
  }

  void _onConfirmOrder(ConfirmOrder event, Emitter<ItemEntryState> emit) {
    final confirmedItems = List<ConfirmedItem>.from(state.confirmedItems);
    final validItems = state.selectedItems.where((item) => item.isValid);

    for (final item in validItems) {
      confirmedItems.add(
        ConfirmedItem(
          itemName: item.item!.description,
          quantity: item.quantity,
          totalPrice: item.extendedPrice,
        ),
      );
    }

    final totalAmount = confirmedItems.fold(
      0.0,
      (sum, item) => sum + item.totalPrice,
    );

    emit(
      state.copyWith(
        confirmedItems: confirmedItems,
        selectedItems: [SelectedItem()],
        useBarcode: false,
        totalAmount: totalAmount,
      ),
    );
  }

  void _onToggleBarcode(ToggleBarcode event, Emitter<ItemEntryState> emit) {
    emit(state.copyWith(useBarcode: event.useBarcode));
  }

  void _onAddBarcodeItems(AddBarcodeItems event, Emitter<ItemEntryState> emit) {
    final confirmedItems = List<ConfirmedItem>.from(state.confirmedItems)
      ..addAll(event.items);

    final totalAmount = confirmedItems.fold(
      0.0,
      (sum, item) => sum + item.totalPrice,
    );

    emit(
      state.copyWith(confirmedItems: confirmedItems, totalAmount: totalAmount),
    );
  }

  void _onScanBarcode(ScanBarcode event, Emitter<ItemEntryState> emit) {
    final scannedBarcode = event.barcode;

    // Find item by barcode
    Item? foundItem;
    for (final itemInStore in state.itemsInStores) {
      if (itemInStore.item.barcode.toString() == scannedBarcode) {
        foundItem = itemInStore.item;
        break;
      }
    }

    if (foundItem != null) {
      // Check if item already exists in confirmed items
      final existingIndex = state.confirmedItems.indexWhere(
        (item) => item.itemName == foundItem!.description,
      );

      final confirmedItems = List<ConfirmedItem>.from(state.confirmedItems);
      final totalAmount = state.totalAmount;

      if (existingIndex >= 0) {
        // Update quantity if item exists
        final existingItem = confirmedItems[existingIndex];
        confirmedItems[existingIndex] = ConfirmedItem(
          itemName: existingItem.itemName,
          quantity: existingItem.quantity + 1,
          totalPrice: existingItem.totalPrice + (foundItem.unitPrice ?? 0),
        );
      } else {
        // Add new item
        final availableStores = _getAvailableStoresForItem(foundItem);
        final double unitPrice = availableStores.isNotEmpty
            ? availableStores.first.unitPrice
            : 0;

        confirmedItems.add(
          ConfirmedItem(
            itemName: foundItem.description,
            quantity: 1,
            totalPrice: unitPrice,
          ),
        );
      }

      // Calculate new total amount
      final newTotalAmount = confirmedItems.fold(
        0.0,
        (sum, item) => sum + item.totalPrice,
      );

      emit(
        state.copyWith(
          confirmedItems: confirmedItems,
          totalAmount: newTotalAmount,
        ),
      );
    } else {
      // Item not found
      emit(
        state.copyWith(
          errorMessage: 'Item with barcode $scannedBarcode not found',
        ),
      );
    }
  }

  void _onClearSelectedItems(
    ClearSelectedItems event,
    Emitter<ItemEntryState> emit,
  ) {
    emit(state.copyWith(selectedItems: [SelectedItem()]));
  }

  List<Store> _getAvailableStoresForItem(Item? item) {
    if (item == null) return [];

    final itemInStore = state.itemsInStores.firstWhere(
      (element) => element.item.id == item.id,
      orElse: () => ItemInStore(item: item!, availableStores: []),
    );

    return itemInStore.availableStores;
  }
}
