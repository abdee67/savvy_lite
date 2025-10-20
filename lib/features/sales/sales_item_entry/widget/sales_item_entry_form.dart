import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:savvy_stock/core/widgets/custom_table_dropdown.dart';
import 'package:savvy_stock/core/widgets/custom_text_form.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/blocs/sales_item_entry_bloc.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/blocs/sales_item_entry_event.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/blocs/sales_item_entry_state.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/models/item_in_store.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/models/items.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/widget/barcode_section.dart';

class SalesItemEntryForm extends StatefulWidget {
  final int index;
  const SalesItemEntryForm({super.key, required this.index});

  @override
  State<SalesItemEntryForm> createState() => _SalesItemEntryFormState();
}

class _SalesItemEntryFormState extends State<SalesItemEntryForm>
    with SingleTickerProviderStateMixin {
  final List<GlobalKey<FormState>> _formKeys = [];

  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
        );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ItemEntryBloc, ItemEntryState>(
      builder: (context, state) {
        final selectedItem = state.selectedItems[widget.index];
        final availableStores = _getAvailableStoresForItem(selectedItem.item);

        // Sync animation with useBarcode
        if (state.useBarcode) {
          _animController.forward();
        } else {
          _animController.reverse();
        }

        if (widget.index >= _formKeys.length) {
          _formKeys.add(GlobalKey<FormState>());
        }

        final theme = Theme.of(context);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKeys[widget.index],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                /// --- ITEM SELECTION ---
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
                      SelectItem(index: widget.index, item: newValue),
                    );
                  },
                ),
                const SizedBox(height: 16),

                /// --- STORE SELECTION ---
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

                /// --- QUANTITY INPUT ---
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
                    if (quantity == null) return 'Please enter a valid number';

                    final storeAvailability = selectedItem.store?.availability;
                    if (storeAvailability != null &&
                        quantity > storeAvailability) {
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

                /// --- READ-ONLY FIELDS ---
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

                /// --- BARCODE SECTION ---
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Color(0xFF155888),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Checkbox(
                        fillColor: WidgetStatePropertyAll<Color>(
                          Color(0xFF155888),
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                        ),
                        checkColor: Colors.white,

                        value: state.useBarcode,
                        onChanged: (value) {
                          context.read<ItemEntryBloc>().add(
                            ToggleBarcode(useBarcode: value ?? false),
                          );
                        },
                      ),
                    ),
                    if (!state.useBarcode) const Text('Barcode'),
                    const SizedBox(width: 2),

                    /// Animated barcode field (slide in/out)
                    Expanded(
                      child: ClipRect(
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: state.useBarcode
                              ? const Padding(
                                  padding: EdgeInsets.only(top: 8.0),
                                  child: BarcodeSection(),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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
