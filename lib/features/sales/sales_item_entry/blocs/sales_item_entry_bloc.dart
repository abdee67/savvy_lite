import 'package:bloc/bloc.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/blocs/sales_item_entry_event.dart';
import '../models/confirmed_item.dart';
import '../models/item_in_store.dart';
import '../models/items.dart';
import '../blocs/sales_item_entry_state.dart';

class ItemEntryBloc extends Bloc<ItemEntryEvent, ItemEntryState> {
  ItemEntryBloc() : super(const ItemEntryState()) {
    on<ToggleBarcode>(_onToggleBarcode);
    on<AddBarcodeItems>(_onAddBarcodeItems);
    on<ScanBarcode>(_onScanBarcode);
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

  List<ItemInStore> _getAvailableStoresForItem(Item? item) {
    if (item == null) return [];

    return state.itemsInStores
        .where((itemInStore) => itemInStore.item.id == item.id)
        .toList();
  }

  List<ConfirmedItem> get confirmedItems => state.confirmedItems;
}
