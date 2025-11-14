// features/sales/sales_item_entry/widgets/sales_item_entry_form.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:savvy_stock/core/widgets/custom_dropdown.dart';
import 'package:savvy_stock/core/widgets/custom_searchable_dropdown.dart';
import 'package:savvy_stock/core/widgets/custom_table_dropdown.dart';
import 'package:savvy_stock/core/widgets/custom_text_form.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/branch_list/blocs/branch_list_bloc.dart';
import 'package:savvy_stock/features/branch_list/blocs/branch_list_event.dart';
import 'package:savvy_stock/features/branch_list/models/branch_list_model.dart';
import 'package:savvy_stock/features/sales/sales_order/detail/model/sales_order_detail.dart';
import 'package:savvy_stock/features/sales/sales_order/integration/bloc/sales_order_coordinator_bloc.dart';
import 'package:savvy_stock/features/sales/sales_order/integration/bloc/sales_order_coordinator_event.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_bloc.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_event.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_state.dart';
import 'package:savvy_stock/features/stock/item_entry/models/item_entry_model.dart';
import 'package:savvy_stock/features/stock/item_in_branch/blocs/item_in_branch_bloc.dart';
import 'package:savvy_stock/features/stock/item_in_branch/blocs/item_in_branch_event.dart';
import 'package:savvy_stock/features/stock/item_in_branch/models/item_in_branch_model.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_bloc.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_event.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_state.dart';

class SalesItemEntryForm extends StatefulWidget {
  final SalesOrderDetail detail;
  final int index;
  final GlobalKey<FormState> formKey;
  final VoidCallback onRemove;
  final VoidCallback onConfirm;

  const SalesItemEntryForm({
    super.key,
    required this.detail,
    required this.index,
    required this.formKey,
    required this.onRemove,
    required this.onConfirm,
  });

  @override
  State<SalesItemEntryForm> createState() => _SalesItemEntryFormState();
}

class _SalesItemEntryFormState extends State<SalesItemEntryForm> {
  late TextEditingController _quantityController;
  late TextEditingController _unitPriceController;
  late TextEditingController _extendedPriceController;
  late TextEditingController _availableQuantityController;

  ItemEntryModel? _selectedItem;
  Branch? _selectedBranch;
  ItemInBranchModel? _selectedItemInBranch;
  int? _selectedUom;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    _quantityController = TextEditingController();
    _unitPriceController = TextEditingController();
    _extendedPriceController = TextEditingController();
    _availableQuantityController = TextEditingController();

    // Load initial data
    _loadInitialData();

    // Initialize form with existing detail data
    _initializeForm();
  }

  void _loadInitialData() {
    final authBloc = context.read<AuthBloc>();
    final companyId = authBloc.state.companyId;

    if (companyId != null) {
      // Load branches
      context.read<BranchBloc>().add(LoadBranchs(companyId));

      // Load UDC details for UOM
      context.read<UdcDetailsBloc>().add(LoadAllUdcDetails());

      // Load items
      context.read<StockItemsEntryBloc>().add(LoadItems(companyId));

      // Load items in branches
      context.read<StockItemInBranchBloc>().add(LoadItemsFromBranch(companyId));
    }
  }

  void _initializeForm() {
    final detail = widget.detail;

    // Pre-fill with existing data
    if (detail.quantity != null) {
      _quantityController.text = detail.quantity.toString();
    }

    if (detail.unitPrice != null) {
      _unitPriceController.text = detail.unitPrice.toString();
    }

    if (detail.extendedPrice != null) {
      _extendedPriceController.text = detail.extendedPrice.toString();
    }

    // Load item and branch if they exist
    if (detail.itemsTableId != null) {
      final itemsBloc = context.read<StockItemsEntryBloc>();
      final item = itemsBloc.state.items.firstWhere(
        (item) => item.id == detail.itemsTableId,
        orElse: () => ItemEntryModel.empty(),
      );
      if (item.id != null) {
        _selectedItem = item;
      }
    }

    if (detail.itemInBranch != null) {
      final itemsInBranchBloc = context.read<StockItemInBranchBloc>();
      final itemInBranch = itemsInBranchBloc.state.availableItems.firstWhere(
        (item) => item.id == detail.itemInBranch,
        orElse: () => ItemInBranchModel.empty(),
      );
      if (itemInBranch.id != null) {
        _selectedItemInBranch = itemInBranch;
        _selectedBranch = itemInBranch.branchRef;
        _selectedUom = itemInBranch.unitOfMeasure;
        _availableQuantityController.text =
            (itemInBranch.quantityAvailable ?? 0).toString();
        _unitPriceController.text = (itemInBranch.unitPrice ?? 0).toString();
      }
    }

    // Calculate initial extended price
    _calculateExtendedPrice();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _unitPriceController.dispose();
    _extendedPriceController.dispose();
    _availableQuantityController.dispose();
    super.dispose();
  }

  void _calculateExtendedPrice() {
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    final unitPrice = double.tryParse(_unitPriceController.text) ?? 0;
    final extendedPrice = quantity * unitPrice;

    _extendedPriceController.text = extendedPrice.toStringAsFixed(2);

    // Update the detail in coordinator
    _updateDetailInCoordinator();
  }

  void _updateDetailInCoordinator() {
    final updatedDetail = widget.detail.copyWith(
      itemsTableId: _selectedItem?.id,
      itemInBranch: _selectedItemInBranch?.id,
      quantity: double.tryParse(_quantityController.text),
      unitPrice: double.tryParse(_unitPriceController.text),
      extendedPrice: double.tryParse(_extendedPriceController.text),
      unitOfMeasure: _selectedUom,
    );

    context.read<SalesOrderCoordinatorBloc>().add(
      UpdateDetailInOrder(detail: updatedDetail, index: widget.index),
    );
  }

  void _onItemSelected(ItemEntryModel? item) {
    setState(() {
      _selectedItem = item;
      _selectedBranch = null;
      _selectedItemInBranch = null;
      _selectedUom = null;
      _availableQuantityController.text = '0.0';
      _unitPriceController.text = '0.0';
    });

    if (item != null) {
      // Load available branches for this item
      final itemsInBranchBloc = context.read<StockItemInBranchBloc>();
      final availableBranches = itemsInBranchBloc.state.availableItems
          .where((itemInBranch) => itemInBranch.itemNumber == item.id)
          .toList();

      if (availableBranches.isNotEmpty) {
        // Auto-select the first available branch
        _onBranchSelected(
          availableBranches.first.branchRef,
          availableBranches.first,
        );
      }
    }

    _updateDetailInCoordinator();
  }

  void _onBranchSelected(Branch? branch, ItemInBranchModel? itemInBranch) {
    setState(() {
      _selectedBranch = branch;
      _selectedItemInBranch = itemInBranch;

      if (itemInBranch != null) {
        _selectedUom = itemInBranch.unitOfMeasure;
        _availableQuantityController.text =
            (itemInBranch.quantityAvailable ?? 0).toString();
        _unitPriceController.text = (itemInBranch.unitPrice ?? 0).toString();
      } else {
        _selectedUom = null;
        _availableQuantityController.text = '0.0';
        _unitPriceController.text = '0.0';
      }
    });

    _calculateExtendedPrice();
  }

  List<ItemInBranchModel> _getAvailableBranchesForItem() {
    if (_selectedItem == null) return [];

    final itemsInBranchBloc = context.read<StockItemInBranchBloc>();
    return itemsInBranchBloc.state.availableItems
        .where((itemInBranch) => itemInBranch.itemNumber == _selectedItem!.id)
        .toList();
  }

  String _formatCurrency(double amount) {
    return NumberFormat('#,##0.00').format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final availableBranches = _getAvailableBranchesForItem();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Form(
        key: widget.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with remove button
            Row(
              children: [
                Text(
                  'Item ${widget.index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF155888),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: widget.onRemove,
                  tooltip: 'Remove Item',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Item Selection
            BlocBuilder<StockItemsEntryBloc, ItemEntryState>(
              builder: (context, itemsState) {
                return CustomTableDropdown<ItemEntryModel>(
                  title: 'Item *',
                  items: itemsState.items,
                  displayText: (item) =>
                      item.itemDescription ?? 'No Description',
                  selectedValue: _selectedItem,
                  showSearch: true,
                  searchHint: 'Search items...',
                  leadingIcon: const Icon(Icons.inventory_2, size: 16),
                  columns: [
                    TableColumnConfig(
                      header: 'Item Name',
                      flex: 3,
                      cellBuilder: (item) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.itemDescription ?? 'No Description',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TableColumnConfig(
                      header: 'Item ID',
                      flex: 2,
                      cellBuilder: (item) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.itemsId ?? 'No ID',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  onItemSelected: _onItemSelected,
                );
              },
            ),

            const SizedBox(height: 16),

            // Branch Selection (only show if item is selected)
            if (_selectedItem != null) ...[
              CustomTableDropdown<ItemInBranchModel>(
                title: 'Branch *',
                items: availableBranches,
                displayText: (itemInBranch) =>
                    itemInBranch.branchRef?.description ?? 'No Branch',
                selectedValue: _selectedItemInBranch,
                columns: [
                  TableColumnConfig(
                    header: 'Branch',
                    cellBuilder: (itemInBranch) =>
                        Text(itemInBranch.branchRef?.description ?? ''),
                  ),
                  TableColumnConfig(
                    header: 'Available Qty',
                    cellBuilder: (itemInBranch) =>
                        Text((itemInBranch.quantityAvailable ?? 0).toString()),
                  ),
                  TableColumnConfig(
                    header: 'Unit Price',
                    cellBuilder: (itemInBranch) =>
                        Text(_formatCurrency(itemInBranch.unitPrice ?? 0)),
                  ),
                ],
                onItemSelected: (itemInBranch) {
                  if (itemInBranch != null) {
                    _onBranchSelected(itemInBranch.branchRef, itemInBranch);
                  }
                },
              ),
              const SizedBox(height: 16),
            ],

            // Quantity Input
            CustomTextField(
              controller: _quantityController,
              labelText: 'Quantity *',
              keyboardType: TextInputType.number,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter quantity';
                }
                final quantity = double.tryParse(value);
                if (quantity == null || quantity <= 0) {
                  return 'Please enter valid quantity';
                }

                // Check stock availability
                if (_selectedItemInBranch != null) {
                  final availableQty =
                      _selectedItemInBranch!.quantityAvailable ?? 0;
                  if (quantity > availableQty) {
                    return 'Quantity exceeds available stock ($availableQty)';
                  }
                }

                return null;
              },
              onChanged: (value) {
                _calculateExtendedPrice();
              },
            ),

            const SizedBox(height: 16),

            // Available Quantity (Read-only)
            CustomTextField(
              controller: _availableQuantityController,
              labelText: 'Available Quantity',
              readOnly: true,
            ),

            const SizedBox(height: 16),

            // Unit Price (Read-only from branch)
            CustomTextField(
              controller: _unitPriceController,
              labelText: 'Unit Price',
              readOnly: true,
            ),

            const SizedBox(height: 16),

            // Extended Price (Read-only, calculated)
            CustomTextField(
              controller: _extendedPriceController,
              labelText: 'Line Total',
              readOnly: true,
            ),

            const SizedBox(height: 16),

            // UOM Selection (from branch)
            if (_selectedItemInBranch != null)
              BlocBuilder<UdcDetailsBloc, UdcDetailsState>(
                builder: (context, udcState) {
                  final uomOptions = udcState.details
                      .where(
                        (detail) =>
                            detail.id == _selectedItemInBranch!.unitOfMeasure,
                      )
                      .toList();

                  final uomDescription = uomOptions.isNotEmpty
                      ? uomOptions.first.description1
                      : 'N/A';

                  return CustomTextField(
                    labelText: 'Unit of Measure',
                    value: uomDescription,
                    readOnly: true,
                  );
                },
              ),

            const SizedBox(height: 16),

            // Confirm Item Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (widget.formKey.currentState!.validate()) {
                    widget.onConfirm();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF155888),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.check_circle, size: 20),
                label: const Text('Confirm Item'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
