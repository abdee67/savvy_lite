import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:savvy_stock/core/widgets/custom_dropdown.dart';
import 'package:savvy_stock/core/widgets/custom_text_form.dart';
import 'package:savvy_stock/features/sales/payment/screens/paymentSummary.dart';
import 'package:savvy_stock/features/sales/payment/screens/summaryAndPaymentPage.dart';
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

class ScanBarcode extends ItemEntryEvent {
  final String barcode;

  const ScanBarcode({required this.barcode});

  @override
  List<Object> get props => [barcode];
}

class ItemEntryScreenView extends StatelessWidget {
  const ItemEntryScreenView({super.key});

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
    final availableStores = _getAvailableStoresForItem(
      context,
      selectedItem.item,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Item selection
          CustomTableDropdown<Item>(
            title: 'Item',
            items: state.itemsInStores
                .map((itemInStore) => itemInStore.item)
                .toList(),
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
              CustomTableDropdown<Store>(
                title: 'Store',
                items: availableStores,
                displayText: (store) => store.branchName,
                selectedValue: selectedItem.store,
                columns: [
                  TableColumnConfig(
                    header: 'Branch',
                    cellBuilder: (store) => Text(store.branchName),
                  ),
                  TableColumnConfig(
                    header: 'Item',
                    cellBuilder: (store) =>
                        Text(selectedItem.item?.description ?? ''),
                  ),
                  TableColumnConfig(
                    header: 'Available',
                    cellBuilder: (store) => Text(store.availability.toString()),
                  ),
                  TableColumnConfig(
                    header: 'Unit Price',
                    cellBuilder: (store) =>
                        Text(_formatCurrency(store.unitPrice)),
                  ),
                ],
                onItemSelected: (Store? store) {
                  context.read<ItemEntryBloc>().add(
                    SelectStore(index: index, store: store),
                  );
                },
              ),
          ],
          const SizedBox(height: 16),

          // Quantity input
          CustomTextField(
            labelText: 'Quantity',
            keyboardType: TextInputType.number,
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
                top: 30,
                left: 16,
                right: 16,
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
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.white,
                                ),
                                child: GestureDetector(
                                  onLongPress: () {
                                    PopupMenuButton(
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Text('Edit Item'),
                                        ),
                                        const PopupMenuItem(
                                          value: 'remove',
                                          child: Text('Remove Item'),
                                        ),
                                      ],
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          context.read<ItemEntryBloc>().add(
                                            EditItem(
                                              index: index,
                                              quantity: item.quantity,
                                              store: item.store,
                                              item: item.item,
                                            ),
                                          );
                                        } else if (value == 'remove') {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: Text('Remove Item'),
                                              content: Text(item.itemName),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: const Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    context
                                                        .read<ItemEntryBloc>()
                                                        .add(
                                                          RemoveItem(
                                                            index: index,
                                                          ),
                                                        );
                                                    Navigator.pop(context);
                                                  },
                                                  child: const Text('Remove'),
                                                ),
                                              ],
                                            ),
                                          );
                                        }
                                      },
                                    );
                                  },
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
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
                                          item.quantity.toStringAsFixed(2),
                                          style: const TextStyle(fontSize: 14),
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

  List<Store> _getAvailableStoresForItem(BuildContext context, Item? item) {
    if (item == null) return [];

    final state = context.read<ItemEntryBloc>().state;
    final itemInStore = state.itemsInStores.firstWhere(
      (element) => element.item.id == item.id,
      orElse: () => ItemInStore(item: item, availableStores: []),
    );

    return itemInStore.availableStores;
  }

  String _formatCurrency(double amount) {
    return NumberFormat('#,##0.00').format(amount);
  }

  void _confirmOrder(BuildContext context) {
    context.read<ItemEntryBloc>().add(ConfirmOrder());
  }

  void _navigateToSummary(BuildContext context) {
    final state = context.read<ItemEntryBloc>().state;
    context.push('/paymentScreen', extra: state);
  }
}
