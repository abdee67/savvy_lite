import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:savvy_stock/features/sales/customer/blocs/customer_bloc.dart';
import 'package:savvy_stock/features/sales/customer/models/customer_model.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/blocs/sales_item_entry_event.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/confirmed_item.dart';
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

    on<DeleteConfirmedItem>(_onDeleteConfirmedItem);
    on<UndoDelete>(_onUndoDelete);

    on<MoveToEdit>(_onMoveToEdit);
    on<ConfirmOrder>(_onConfirmOrder);
    on<ClearSelectedItems>(_onClearSelectedItems);

    on<ToggleBarcode>(_onToggleBarcode);
    on<AddBarcodeItems>(_onAddBarcodeItems);
    on<ScanBarcode>(_onScanBarcode);
  }

  Future<void> _onLoadItemsAndStores(
    LoadItemsAndStores event,
    Emitter<ItemEntryState> emit,
  ) async {
    emit(state.copyWith(status: ItemEntryStatus.loading));

    try {
      // Simulate API/database call
      // await Future.delayed(const Duration(milliseconds: 500));
      final prefs = await SharedPreferences.getInstance();
      final customerBloc = event.customerBloc;
      final customer = customerBloc.state.selectedBillToCustomer;
      final items = [
        const Item(
          id: 'ITM-001',
          description: 'Laptop Computer',
          uom: 'PCS',
          barcode: 123456789000,
        ),
        const Item(
          id: 'ITM-002',
          description: 'Wireless Mouse',
          uom: 'PCS',
          barcode: 987654321000,
        ),
        const Item(
          id: 'ITM-003',
          description: 'Keyboard',
          uom: 'PCS',
          barcode: 112233445000,
        ),
        const Item(
          id: 'ITM-004',
          description: 'Monitor 24"',
          uom: 'PCS',
          barcode: 556677889000,
        ),
        const Item(
          id: 'ITM-005',
          description: 'Webcam HD',
          uom: 'PCS',
          barcode: 334455667000,
        ),
      ];

      // Create stores (NO prices or availability here)
      final stores = [
        const Store(id: 'STR-001', branchName: 'Main Branch'),
        const Store(id: 'STR-002', branchName: 'Downtown Branch'),
        const Store(id: 'STR-003', branchName: 'Westside Branch'),
        const Store(id: 'STR-004', branchName: 'North Branch'),
      ];

      // Create relationships with proper prices and availability
      final itemsInStores = [
        // Laptop (ITM-001) in different stores with different prices
        ItemInStore(
          item: items[0],
          store: stores[0],
          unitPrice: 99999.99,
          availability: 15,
        ),
        ItemInStore(
          item: items[0],
          store: stores[1],
          unitPrice: 1029.99,
          availability: 8,
        ),
        ItemInStore(
          item: items[0],
          store: stores[2],
          unitPrice: 949.99,
          availability: 3,
        ),

        // Mouse (ITM-002) in different stores with different prices
        ItemInStore(
          item: items[1],
          store: stores[0],
          unitPrice: 24.99,
          availability: 100,
        ),
        ItemInStore(
          item: items[1],
          store: stores[3],
          unitPrice: 26.99,
          availability: 50,
        ),

        // Keyboard (ITM-003) in different stores
        ItemInStore(
          item: items[2],
          store: stores[1],
          unitPrice: 49.99,
          availability: 25,
        ),
        ItemInStore(
          item: items[2],
          store: stores[2],
          unitPrice: 45.99,
          availability: 15,
        ),
        ItemInStore(
          item: items[2],
          store: stores[3],
          unitPrice: 52.99,
          availability: 10,
        ),

        // Monitor (ITM-004) - out of stock in all stores
        // No ItemInStore entries for this item

        // Webcam (ITM-005) in all stores with different prices
        ItemInStore(
          item: items[4],
          store: stores[0],
          unitPrice: 89.99,
          availability: 30,
        ),
        ItemInStore(
          item: items[4],
          store: stores[1],
          unitPrice: 92.99,
          availability: 20,
        ),
        ItemInStore(
          item: items[4],
          store: stores[2],
          unitPrice: 85.99,
          availability: 15,
        ),
        ItemInStore(
          item: items[4],
          store: stores[3],
          unitPrice: 87.99,
          availability: 10,
        ),
      ];

      final uniqueItemsMap = <String, Item>{};
      for (final itemInStore in itemsInStores) {
        uniqueItemsMap[itemInStore.item.id] = itemInStore.item;
      }
      final uniqueItems = uniqueItemsMap.values.toList()
        ..sort(
          (a, b) => a.description.toLowerCase().compareTo(
            b.description.toLowerCase(),
          ),
        );

      emit(
        state.copyWith(
          status: ItemEntryStatus.success,
          itemsInStores: itemsInStores,
          uniqueItems: uniqueItems,
          selectedItems: [SelectedItem()], // Start with one empty item
          customer: customer,
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
        store: event.itemInStore,
      );
    }

    emit(state.copyWith(selectedItems: updatedItems));
  }

  void _onMoveToEdit(MoveToEdit event, Emitter<ItemEntryState> emit) {
    if (event.confirmedIndex >= state.confirmedItems.length) return;

    final confirmedItem = state.confirmedItems[event.confirmedIndex];
    final selectedItem = _confirmedItemToSelectedItem(confirmedItem);

    // Remove from confirmed items
    final updatedConfirmedItems = List<ConfirmedItem>.from(
      state.confirmedItems,
    );
    updatedConfirmedItems.removeAt(event.confirmedIndex);

    // Clear all selected items and add only this one
    final updatedSelectedItems = [selectedItem];

    // Recalculate total amount
    final newTotalAmount = updatedConfirmedItems.fold(
      0.0,
      (sum, item) => sum + item.totalPrice,
    );

    emit(
      state.copyWith(
        selectedItems: updatedSelectedItems,
        confirmedItems: updatedConfirmedItems,
        totalAmount: newTotalAmount,
      ),
    );
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

  void _onDeleteConfirmedItem(
    DeleteConfirmedItem event,
    Emitter<ItemEntryState> emit,
  ) {
    final confirmedItems = List<ConfirmedItem>.from(state.confirmedItems);

    if (event.index < confirmedItems.length) {
      final deletedItem = confirmedItems.removeAt(event.index);

      final totalAmount = state.totalAmount - deletedItem.totalPrice;

      emit(
        state.copyWith(
          confirmedItems: confirmedItems,
          totalAmount: totalAmount,
        ),
      );
    } else {}
  }

  void _onUndoDelete(UndoDelete event, Emitter<ItemEntryState> emit) {
    final updateConfirmedItems = List<ConfirmedItem>.from(state.confirmedItems);
    updateConfirmedItems.insert(event.deletedIndex, event.deletedItem);

    final newTotalAmount = state.totalAmount + event.deletedItem.totalPrice;

    emit(
      state.copyWith(
        confirmedItems: updateConfirmedItems,
        totalAmount: newTotalAmount,
      ),
    );
  }

  void _onConfirmOrder(ConfirmOrder event, Emitter<ItemEntryState> emit) {
    final confirmedItems = List<ConfirmedItem>.from(state.confirmedItems);
    final validItems = state.selectedItems.where((item) => item.isValid);

    for (final selectedItem in validItems) {
      if (selectedItem.item != null && selectedItem.store != null) {
        // Check if item already exists in confirmed items with same store
        final existingIndex = confirmedItems.indexWhere(
          (confirmedItem) =>
              confirmedItem.itemId == selectedItem.item!.id &&
              confirmedItem.storeId == selectedItem.store!.store.id,
        );

        if (existingIndex >= 0) {
          // Update quantity and total price if item exists
          final existingItem = confirmedItems[existingIndex];
          confirmedItems[existingIndex] = ConfirmedItem(
            itemId: existingItem.itemId,
            itemName: existingItem.itemName,
            quantity: existingItem.quantity + selectedItem.quantity,
            totalPrice: existingItem.totalPrice + selectedItem.extendedPrice,
            storeId: existingItem.storeId,
            uom: existingItem.uom,
          );
        } else {
          // Add new item if it doesn't exist
          confirmedItems.add(
            ConfirmedItem(
              itemId: selectedItem.item!.id,
              itemName: selectedItem.item!.description,
              quantity: selectedItem.quantity,
              totalPrice: selectedItem.extendedPrice,
              storeId: selectedItem.store!.store.id,
              uom: selectedItem.item!.uom,
            ),
          );
        }
      }
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

    print(
      'Order confirmed- Items: ${confirmedItems.length}, Total Amount: $totalAmount',
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
        final itemInStore = List<ItemInStore>.from(state.itemsInStores);
        confirmedItems[existingIndex] = ConfirmedItem(
          itemId: itemInStore.first.item.id,
          itemName: existingItem.itemName,
          quantity: existingItem.quantity + 1,
          totalPrice: existingItem.totalPrice + (itemInStore.first.unitPrice),
          storeId: itemInStore.first.store.id,
          uom: itemInStore.first.item.uom,
        );
      } else {
        // Add new item
        final availableStores = _getAvailableStoresForItem(foundItem);
        final double unitPrice = availableStores.isNotEmpty
            ? availableStores.first.unitPrice
            : 0;

        confirmedItems.add(
          ConfirmedItem(
            itemId: foundItem.id,
            itemName: foundItem.description,
            quantity: 1,
            totalPrice: unitPrice,
            storeId: availableStores.first.store.id,
            uom: foundItem.uom,
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

  SelectedItem _confirmedItemToSelectedItem(ConfirmedItem confirmedItem) {
    if (confirmedItem.storeId != null) {
      for (final itemInStore in state.itemsInStores) {
        if (itemInStore.item.id == confirmedItem.itemId &&
            itemInStore.store.id == confirmedItem.storeId) {
          return SelectedItem(
            item: itemInStore.item,
            store: itemInStore,
            quantity: confirmedItem.quantity,
            isOutOfStock: itemInStore.availability == 0,
          );
        }
      }
    }
    //fallback:try byt item ID only
    for (final itemInStore in state.itemsInStores) {
      if (itemInStore.item.id == confirmedItem.itemId) {
        final unitPrice = confirmedItem.totalPrice / confirmedItem.quantity;
        if ((itemInStore.unitPrice - unitPrice).abs() < 0.001) {
          return SelectedItem(
            item: itemInStore.item,
            store: itemInStore,
            quantity: confirmedItem.quantity,
            isOutOfStock: itemInStore.availability == 0,
          );
        }
      }
    }

    // Find the original item from itemsInStores by name and price
    final unitPrice = confirmedItem.totalPrice / confirmedItem.quantity;
    for (final itemInStore in state.itemsInStores) {
      if (itemInStore.item.description == confirmedItem.itemName &&
          (itemInStore.unitPrice - unitPrice).abs() < 0.001) {
        return SelectedItem(
          item: itemInStore.item,
          store: itemInStore,
          quantity: confirmedItem.quantity,
          isOutOfStock: itemInStore.availability == 0,
        );
      }
    }

    // Fallback if item not found return with just qunatity
    return SelectedItem(quantity: confirmedItem.quantity);
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

  void _onClearSelectedItems(
    ClearSelectedItems event,
    Emitter<ItemEntryState> emit,
  ) {
    emit(state.copyWith(selectedItems: [SelectedItem()]));
  }

  List<ItemInStore> _getAvailableStoresForItem(Item? item) {
    if (item == null) return [];

    return state.itemsInStores
        .where((itemInStore) => itemInStore.item.id == item.id)
        .toList();
  }

  List<ConfirmedItem> get confirmedItems => state.confirmedItems;
}
