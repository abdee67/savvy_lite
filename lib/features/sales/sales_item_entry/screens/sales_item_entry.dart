import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:savvy_stock/core/widgets/custom_dropdown.dart';
import 'package:savvy_stock/core/widgets/custom_text_form.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/blocs/sales_item_entry_bloc.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/blocs/sales_item_entry_event.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/blocs/sales_item_entry_state.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/models/item_in_store.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/models/items.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/models/stores.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/widget/barcode_section.dart';

class ItemEntryScreen extends StatelessWidget {
  const ItemEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ItemEntryBloc()..add(LoadItemsAndStores()),
      child: const ItemEntryScreenView(),
    );
  }
}

class ItemEntryScreenView extends StatefulWidget {
  const ItemEntryScreenView({super.key});

  @override
  State<ItemEntryScreenView> createState() => _ItemEntryScreenViewState();
}

class _ItemEntryScreenViewState extends State<ItemEntryScreenView> {
  final List<GlobalKey<FormState>> _formKeys = [];
  final ScrollController _upperScrollController = ScrollController();
  final ScrollController _lowerScrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Initialize form keys based on initial selectedItems
    _initializeFormKeys();
  }

  void _initializeFormKeys() {
    final state = context.read<ItemEntryBloc>().state;
    _formKeys.clear();
    _formKeys.addAll(
      List.generate(
        state.selectedItems.length,
        (index) => GlobalKey<FormState>(),
      ),
    );
  }

  void _safeDeleteItem(BuildContext context, int index) {
    final bloc = context.read<ItemEntryBloc>();
    final state = bloc.state;

    // Validate the index
    if (index < 0 || index >= state.confirmedItems.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete item. Invalid index.')),
      );
      return;
    }

    final itemToDelete = state.confirmedItems[index];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${itemToDelete.itemName}"?'),
        content: Text(
          'Are you sure you want to delete "${itemToDelete.itemName}"?',
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              bloc.add(DeleteConfirmedItem(index: index));
              // Show undo snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('"${itemToDelete.itemName}" deleted'),
                  action: SnackBarAction(
                    label: 'UNDO',
                    onPressed: () {
                      // Add undo functionality if needed
                      bloc.add(
                        UndoDelete(
                          deletedItem: itemToDelete,
                          deletedIndex: index,
                        ),
                      );
                    },
                  ),
                  duration: const Duration(seconds: 5),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _moveToEdit(BuildContext context, int index) {
    final bloc = context.read<ItemEntryBloc>();
    bloc.add(MoveToEdit(confirmedIndex: index));

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Item moved to edit section')));
  }

  final Map<int, double> _dragOffset = {};

  void _onHorizontalDragUpdate(int index, DragUpdateDetails details) {
    setState(() {
      final current = _dragOffset[index] ?? 0;
      var newOffset = current + details.delta.dx;

      // only allow left swipe
      if (newOffset > 0) newOffset = 0;
      _dragOffset[index] = newOffset;
    });
  }

  void _onHorizontalDragEnd(
    BuildContext context,
    int index,
    DragEndDetails details,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final threshold = screenWidth * 0.3; // ✅ 30% of screen width
    final current = _dragOffset[index] ?? 0;
    if (current.abs() > threshold) {
      // Swipe far enough → delete
      setState(() {
        _dragOffset[index] = -screenWidth; // slide fully left
      });

      Future.delayed(const Duration(milliseconds: 300), () {
        _safeDeleteItem(context, index);
        setState(() {
          _dragOffset.remove(index);
        });
      });
    } else {
      // Not far enough → snap back
      setState(() {
        _dragOffset[index] = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: BlocConsumer<ItemEntryBloc, ItemEntryState>(
          listener: (context, state) {
            if (state.status == ItemEntryStatus.failure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage ?? 'An error occurred'),
                ),
              );
            }
            if (_formKeys.length != state.selectedItems.length) {
              setState(() {
                if (_formKeys.length < state.selectedItems.length) {
                  // Add new keys for new items
                  for (
                    int i = _formKeys.length;
                    i < state.selectedItems.length;
                    i++
                  ) {
                    _formKeys.add(GlobalKey<FormState>());
                  }
                } else {
                  // Remove excess keys
                  _formKeys.removeRange(
                    state.selectedItems.length,
                    _formKeys.length,
                  );
                }
              });
            }
          },
          builder: (context, state) {
            return Column(
              children: [
                // Upper Section - Order Items
                Expanded(
                  flex: 1,
                  child: Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: state.selectedItems.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4.0),
                                child: _buildItemEntry(context, state, index),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Lower Section - Order Summary
                _buildLowerSection(context, state),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 48,
            color: Color(0xFF155888),
          ),
          SizedBox(height: 16),
          Text(
            'No items added yet',
            style: TextStyle(fontSize: 16, color: Color(0xFF155888)),
          ),
        ],
      ),
    );
  }

  Widget _buildItemEntry(
    BuildContext context,
    ItemEntryState state,
    int index,
  ) {
    final selectedItem = state.selectedItems[index];
    final availableStores = _getAvailableStoresForItem(selectedItem.item);
    if (index >= _formKeys.length) {
      // Ensure form key exists
      _formKeys.add(GlobalKey<FormState>());
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKeys[index],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Item selection
            CustomTableDropdown<Item>(
              title: 'Item',
              items: state.uniqueItems,
              displayText: (item) => item.description,
              selectedValue: selectedItem.item,
              columns: [
                TableColumnConfig(
                  header: 'ID',
                  cellBuilder: (item) => Text(item.id),
                ),
                TableColumnConfig(
                  header: 'Description',
                  cellBuilder: (item) => Text(item.description),
                ),
              ],
              onItemSelected: (Item? newValue) {
                context.read<ItemEntryBloc>().add(
                  SelectItem(index: index, item: newValue),
                );
              },
            ),
            const SizedBox(height: 16),

            // Store selection or Out of Stock message
            if (selectedItem.item != null) ...[
              if (selectedItem.isOutOfStock)
                Text(
                  'Out of Stock',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                )
              else
                CustomTableDropdown<ItemInStore>(
                  title: 'Store',
                  items: availableStores,
                  displayText: (store) => store.store.branchName,
                  selectedValue: selectedItem.store,
                  columns: [
                    TableColumnConfig(
                      header: 'Branch',
                      cellBuilder: (store) => Text(store.store.branchName),
                    ),
                    TableColumnConfig(
                      header: 'Item',
                      cellBuilder: (store) =>
                          Text(selectedItem.item?.description ?? ''),
                    ),
                    TableColumnConfig(
                      header: 'Available',
                      cellBuilder: (store) =>
                          Text(store.availability.toString()),
                    ),
                    TableColumnConfig(
                      header: 'Unit Price',
                      cellBuilder: (store) =>
                          Text(_formatCurrency(store.unitPrice)),
                    ),
                  ],
                  onItemSelected: (ItemInStore? itemInStore) {
                    context.read<ItemEntryBloc>().add(
                      SelectStore(index: index, itemInStore: itemInStore),
                    );
                  },
                ),
            ],
            const SizedBox(height: 16),

            // Quantity input
            CustomTextField(
              labelText: 'Quantity',
              keyboardType: TextInputType.number,
              value: selectedItem.quantity.toString(),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a quantity';
                }

                final quantity = double.tryParse(value);
                if (quantity == null) {
                  return 'Please enter a valid number';
                }

                final storeAvailability = selectedItem.store?.availability;
                if (storeAvailability != null && quantity > storeAvailability) {
                  return 'Quantity exceeds available stock ($storeAvailability)';
                }

                return null;
              },
              onChanged: (value) {
                final quantity = double.tryParse(value) ?? 0;
                context.read<ItemEntryBloc>().add(
                  UpdateQuantity(index: index, quantity: quantity),
                );
              },
            ),
            const SizedBox(height: 16),

            // Read-only fields
            CustomTextField(
              labelText: 'UoM',
              value: selectedItem.item?.uom ?? '',
              readOnly: true,
            ),
            const SizedBox(height: 16),

            CustomTextField(
              labelText: 'Unit Price',
              value: selectedItem.store != null
                  ? _formatCurrency(selectedItem.store!.unitPrice)
                  : '',
              readOnly: true,
            ),
            const SizedBox(height: 16),

            CustomTextField(
              labelText: 'Line Total',
              value: selectedItem.extendedPrice > 0
                  ? _formatCurrency(selectedItem.extendedPrice)
                  : '',
              readOnly: true,
            ),
            const SizedBox(height: 16),

            // Barcode toggle
            Row(
              children: [
                Checkbox(
                  value: state.useBarcode,
                  onChanged: (value) {
                    context.read<ItemEntryBloc>().add(
                      ToggleBarcode(useBarcode: value ?? false),
                    );
                  },
                ),
                const Text('Use Barcode'),
              ],
            ),
            const SizedBox(height: 10),

            // Barcode section
            if (state.useBarcode) const BarcodeSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildLowerSection(BuildContext context, ItemEntryState state) {
    return Expanded(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade500,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.only(
                top: 30, //spacing for confirm button
                left: 10,
                right: 10,
                bottom: 16,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 4),
                  Expanded(
                    child: state.confirmedItems.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            itemCount: state.confirmedItems.length,
                            itemBuilder: (context, index) {
                              final item = state.confirmedItems[index];
                              final isSelected = state
                                  .selectedConfirmedItemIndices
                                  .contains(index);
                              final offset = _dragOffset[index] ?? 0.0;
                              return GestureDetector(
                                onDoubleTap: () => _moveToEdit(context, index),
                                onHorizontalDragUpdate: (details) =>
                                    _onHorizontalDragUpdate(index, details),
                                onHorizontalDragEnd: (details) =>
                                    _onHorizontalDragEnd(
                                      context,
                                      index,
                                      details,
                                    ),
                                child: Stack(
                                  children: [
                                    // 🔴 Background (delete indicator)
                                    Positioned.fill(
                                      child: Container(
                                        alignment: Alignment.centerRight,
                                        decoration: BoxDecoration(
                                          color: Colors.redAccent,
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(20),
                                            topRight: Radius.circular(20),
                                            bottomLeft: Radius.circular(20),
                                            bottomRight: Radius.circular(20),
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                        ),
                                        margin: const EdgeInsets.only(
                                          bottom: 2,
                                        ),
                                        child: const Icon(
                                          Icons.delete,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),
                                    ),

                                    // 🟢 Foreground (draggable card)
                                    AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      transform: Matrix4.translationValues(
                                        offset,
                                        0,
                                        0,
                                      ),
                                      curve: Curves.easeOut,
                                      margin: const EdgeInsets.only(bottom: 10),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Colors.grey.shade200
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.1,
                                            ),
                                            blurRadius: 6,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                        border: isSelected
                                            ? Border.all(color: Colors.black)
                                            : null,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item.itemName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                item.quantity.toStringAsFixed(
                                                  2,
                                                ),
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                '\$${item.totalPrice.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                                textAlign: TextAlign.end,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: const Color.fromARGB(255, 29, 91, 134),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Grand Total',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          '\$${state.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: ElevatedButton(
                      onPressed: state.totalAmount > 0
                          ? () => _navigateToSummary(context)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(
                          255,
                          24,
                          103,
                          160,
                        ),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Save & Continue'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Confirm Order Button
          Positioned(
            right: 16,
            top: -20,
            child: SizedBox(
              width: 150,
              height: 40,
              child: ElevatedButton(
                onPressed: state.hasValidItems
                    ? () => _confirmOrder(context)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: state.hasValidItems
                      ? const Color.fromARGB(255, 29, 110, 168)
                      : Colors.grey,
                  foregroundColor: state.hasValidItems
                      ? Colors.white
                      : Colors.black,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 4,
                ),
                child: Text(
                  state.hasValidItems ? 'Confirm Order' : 'Select item',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<ItemInStore> _getAvailableStoresForItem(Item? item) {
    if (item == null) return [];

    return context
        .read<ItemEntryBloc>()
        .state
        .itemsInStores
        .where((itemInStore) => itemInStore.item.id == item.id)
        .toList();
  }

  String _formatCurrency(double amount) {
    return NumberFormat('#,##0.00').format(amount);
  }

  void _confirmOrder(BuildContext context) {
    // Validate all forms
    bool allValid = true;
    for (int i = 0; i < _formKeys.length; i++) {
      if (_formKeys[i].currentState != null &&
          !_formKeys[i].currentState!.validate()) {
        allValid = false;

        // Scroll to the first invalid field
        _upperScrollController.animateTo(
          i * 300.0, // Adjust based on your item height
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        break;
      }
    }

    if (allValid) {
      context.read<ItemEntryBloc>().add(ConfirmOrder());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix validation errors')),
      );
    }
  }

  void _navigateToSummary(BuildContext context) {
    final state = context.read<ItemEntryBloc>().state;
    context.push('/payment-screen', extra: state);
  }
}
