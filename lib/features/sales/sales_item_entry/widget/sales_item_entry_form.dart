import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:savvy_stock/core/widgets/custom_dropdown.dart';
import 'package:savvy_stock/core/widgets/custom_text_form.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/blocs/sales_item_entry_bloc.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/blocs/sales_item_entry_event.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/blocs/sales_item_entry_state.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/models/item_in_store.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/models/items.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/widget/barcode_section.dart';

class SalesItemEntryForm extends StatefulWidget {
  final ItemEntryState state;
  final int index;
  const SalesItemEntryForm({
    super.key,
    required this.state,
    required this.index,
  });

  @override
  State<SalesItemEntryForm> createState() => _SalesItemEntryFormState();
}

class _SalesItemEntryFormState extends State<SalesItemEntryForm> {
  final List<GlobalKey<FormState>> _formKeys = [];

  @override
  Widget build(BuildContext context) {
    final selectedItem = widget.state.selectedItems[widget.index];
    final availableStores = _getAvailableStoresForItem(selectedItem.item);
    if (widget.index >= _formKeys.length) {
      // Ensure form key exists
      _formKeys.add(GlobalKey<FormState>());
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKeys[widget.index],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Item selection
            CustomTableDropdown<Item>(
              title: 'Item',
              items: widget.state.uniqueItems,
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
                  SelectItem(index: widget.index, item: newValue),
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
                      SelectStore(
                        index: widget.index,
                        itemInStore: itemInStore,
                      ),
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
                  UpdateQuantity(index: widget.index, quantity: quantity),
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
                  value: widget.state.useBarcode,
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
            if (widget.state.useBarcode) const BarcodeSection(),
          ],
        ),
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
}
