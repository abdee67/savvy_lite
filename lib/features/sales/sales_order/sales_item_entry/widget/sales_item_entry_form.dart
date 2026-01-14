// features/sales/sales_item_entry/widgets/sales_item_entry_form.dart
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:savvy_stock/core/widgets/custom_searchable_dropdown.dart';
import 'package:savvy_stock/core/widgets/custom_table_dropdown.dart';
import 'package:savvy_stock/core/widgets/custom_text_form.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/branch_list/blocs/branch_list_bloc.dart';
import 'package:savvy_stock/features/branch_list/blocs/branch_list_event.dart';
import 'package:savvy_stock/features/branch_list/models/branch_list_model.dart';
import 'package:savvy_stock/features/sales/sales_order/detail/bloc/sales_order_detail_bloc.dart';
import 'package:savvy_stock/features/sales/sales_order/detail/bloc/sales_order_detail_event.dart';
import 'package:savvy_stock/features/sales/sales_order/detail/bloc/sales_order_detail_state.dart';
import 'package:savvy_stock/features/sales/sales_order/detail/model/sales_order_detail.dart';
import 'package:savvy_stock/features/sales/sales_order/integration/bloc/sales_order_coordinator_bloc.dart';
import 'package:savvy_stock/features/sales/sales_order/integration/bloc/sales_order_coordinator_state.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_bloc.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_event.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_state.dart';
import 'package:savvy_stock/features/stock/item_entry/models/item_entry_model.dart';
import 'package:savvy_stock/features/stock/item_in_branch/blocs/item_in_branch_bloc.dart';
import 'package:savvy_stock/features/stock/item_in_branch/blocs/item_in_branch_event.dart';
import 'package:savvy_stock/features/stock/item_in_branch/blocs/item_in_branch_state.dart';
import 'package:savvy_stock/features/stock/item_in_branch/models/item_in_branch_model.dart';
import 'package:savvy_stock/features/stock/item_uom_conversions/blocs/item_uom_conversions_bloc.dart';
import 'package:savvy_stock/features/stock/item_uom_conversions/blocs/item_uom_conversions_event.dart';
import 'package:savvy_stock/features/stock/item_uom_conversions/blocs/item_uom_conversions_state.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_bloc.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_bloc.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_event.dart';
import 'package:savvy_stock/features/udc_detail/models/udc_details.dart';

class SalesItemEntryForm extends StatefulWidget {
  final SalesOrderDetail detail;
  final GlobalKey<FormState> formKey;
  final bool isEditing;
  final Function(SalesOrderDetail) onUpdate;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  const SalesItemEntryForm({
    super.key,
    required this.detail,
    required this.formKey,
    required this.isEditing,
    required this.onUpdate,
    required this.onConfirm,
    this.onCancel,
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
  bool _isInitializing = true;
  late int? decimalPlace;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    _quantityController = TextEditingController();
    _unitPriceController = TextEditingController();
    _extendedPriceController = TextEditingController();
    _availableQuantityController = TextEditingController();

    // Load initial data after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
    decimalPlace = context
        .read<SystemConstantBloc>()
        .state
        .selected
        ?.decimalPlaces;
  }

  void _loadInitialData() {
    final authBloc = context.read<AuthBloc>();
    final companyId = authBloc.state.companyId;

    if (companyId != null) {
      // Load branches
      final branchBloc = context.read<BranchBloc>();
      if (branchBloc.state.branchs.isEmpty) {
        branchBloc.add(LoadBranchs(companyId));
      }

      // Load UDC details for UOM
      final udcDetailsBloc = context.read<UdcDetailsBloc>();
      if (udcDetailsBloc.state.details.isEmpty) {
        udcDetailsBloc.add(LoadAllUdcDetails());
      }

      // Load items
      final stockItemsEntryBloc = context.read<StockItemsEntryBloc>();
      if (stockItemsEntryBloc.state.items.isEmpty) {
        stockItemsEntryBloc.add(LoadItems(companyId));
      }

      // Load items in branches
      final stockItemInBranchBloc = context.read<StockItemInBranchBloc>();
      if (stockItemInBranchBloc.state.items.isEmpty) {
        stockItemInBranchBloc.add(LoadItemsFromBranch(companyId));
      }
    }

    // Initialize form with existing data
    _initializeForm();
  }

  void _initializeForm() {
    final detail = widget.detail;

    // Set initial values
    if (detail.quantity != null) {
      _quantityController.text = detail.quantity!.toStringAsFixed(2);
    } else {
      _quantityController.text = '1.00';
    }

    if (detail.unitPrice != null) {
      _unitPriceController.text = detail.unitPrice!.toStringAsFixed(2);
    } else {
      _unitPriceController.text = '0.00';
    }

    if (detail.extendedPrice != null) {
      _extendedPriceController.text = detail.extendedPrice!.toStringAsFixed(2);
    } else {
      _extendedPriceController.text = '0.00';
    }

    _availableQuantityController.text = '0.00';

    // If editing, try to pre-populate item and branch
    if (widget.isEditing) {
      _populateExistingData(detail);
    }

    setState(() {
      _isInitializing = false;
    });

    // Calculate initial extended price
    _calculateExtendedPrice();
  }

  void _populateExistingData(SalesOrderDetail detail) {
    // Try to find the item from ItemEntryBloc
    final itemsBloc = context.read<StockItemsEntryBloc>();
    final items = itemsBloc.state.items;

    if (detail.itemsTableId != null && items.isNotEmpty) {
      try {
        final existingItem = items.firstWhere(
          (item) => item.id == detail.itemsTableId,
        );
        _selectedItem = existingItem;
      } catch (e) {
        // Item not found, continue without pre-selection
        if (kDebugMode) {
          developer.log('Item not found: ${detail.itemsTableId}');
        }
      }
    }

    // Try to find the item in branch
    final itemsInBranchBloc = context.read<StockItemInBranchBloc>();
    final availableItems = itemsInBranchBloc.state.availableItems;

    if (detail.itemInBranch != null && availableItems.isNotEmpty) {
      try {
        final existingItemInBranch = availableItems.firstWhere(
          (item) => item.id == detail.itemInBranch,
        );
        _selectedItemInBranch = existingItemInBranch;
        _selectedBranch = existingItemInBranch.branchRef;
        _selectedUom = existingItemInBranch.unitOfMeasure;

        // Update controllers with branch data
        _availableQuantityController.text =
            (existingItemInBranch.quantityAvailable ?? 0).toStringAsFixed(2);

        // Only update unit price if not already set from detail
        if (detail.unitPrice == null) {
          _unitPriceController.text = (existingItemInBranch.unitPrice ?? 0)
              .toStringAsFixed(2);
        }
      } catch (e) {
        // Item in branch not found
        if (kDebugMode) {
          developer.log('Item in branch not found: ${detail.itemInBranch}');
        }
      }
    }
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
    if (_isInitializing) return;
    // Let blocs handle extended price calculation; just push the updated detail
    _updateDetail();
  }

  UdcDetails? _resolveSelectedUomDetail() {
    if (_selectedUom == null) return null;

    // Prefer UOMs loaded specifically for this item
    final itemUomState = context.read<ItemUomConversionBloc>().state;
    final fromItemUoms = itemUomState.availableUomsForItem
        .where((u) => u.id == _selectedUom)
        .toList();
    if (fromItemUoms.isNotEmpty) {
      return fromItemUoms.first;
    }

    // Fallback to global UDC details list
    final udcDetailsBloc = context.read<UdcDetailsBloc>();
    final fromAllUoms = udcDetailsBloc.state.details
        .where((u) => u.id == _selectedUom)
        .toList();
    if (fromAllUoms.isNotEmpty) {
      return fromAllUoms.first;
    }

    return null;
  }

  void _updateDetail() {
    if (_isInitializing) return;

    final selectedUomDetail = _resolveSelectedUomDetail();

    final updatedDetail = widget.detail.copyWith(
      itemsTableId: _selectedItem?.id,
      itemInBranch: _selectedItemInBranch?.id,
      itemBranch: _selectedItemInBranch,
      quantity: double.tryParse(_quantityController.text),
      unitPrice: double.tryParse(_unitPriceController.text),
      extendedPrice: double.tryParse(_extendedPriceController.text),
      unitOfMeasure: _selectedUom,
      uom: selectedUomDetail,
      item: _selectedItem, // Include the full item object
    );

    widget.onUpdate(updatedDetail);
  }

  void _onItemSelected(ItemEntryModel? item) {
    setState(() {
      _selectedItem = item;
      _selectedBranch = null;
      _selectedItemInBranch = null;
      _selectedUom = null;
      _availableQuantityController.text = '0.00';

      // Only reset unit price if we're not editing an existing item
      if (!widget.isEditing || widget.detail.unitPrice == null) {
        _unitPriceController.text = '0.00';
      }
    });

    if (item != null) {
      // Find available branches for this item
      final availableBranches = _getAvailableBranchesForItem();

      if (availableBranches.isNotEmpty) {
        // Auto-select the first available branch
        final firstBranch = availableBranches.first;
        _onBranchSelected(firstBranch.branchRef, firstBranch);
      } else {
        // No branches available for this item
        _showNoBranchesSnackbar();
      }
    }

    _calculateExtendedPrice();
  }

  void _onBranchSelected(Branch? branch, ItemInBranchModel? itemInBranch) {
    final authBloc = context.read<AuthBloc>();

    setState(() {
      _selectedBranch = branch;
      _selectedItemInBranch = itemInBranch;

      if (itemInBranch != null) {
        // Load available UOMs for this item via bloc
        final uomBloc = context.read<ItemUomConversionBloc>();
        uomBloc.add(
          LoadUomsForItem(
            itemId: itemInBranch.itemNumber,
            companyId: authBloc.state.companyId!,
          ),
        );

        _selectedUom = itemInBranch.unitOfMeasure;
        _selectedUom = itemInBranch.unitOfMeasure;

        // Update price first
        if (!widget.isEditing || widget.detail.unitPrice == null) {
          _unitPriceController.text = (itemInBranch.unitPrice ?? 0)
              .toStringAsFixed(2);
        }

        // Then update effective quantity
        _updateEffectiveAvailableQuantity();
      } else {
        _selectedUom = null;
        _availableQuantityController.text = '0.00';
        // Don't reset unit price if we're editing and have a value
        if (!widget.isEditing || widget.detail.unitPrice == null) {
          _unitPriceController.text = '0.00';
        }
      }
    });

    // Dispatch event to calculate price with UOM
    if (itemInBranch != null) {
      // Create a temporary detail with current values to send for calculation
      final selectedUomDetail = _resolveSelectedUomDetail();

      final currentDetail = widget.detail.copyWith(
        itemsTableId: _selectedItem?.id,
        itemInBranch: itemInBranch.id,
        itemBranch: itemInBranch,
        quantity: double.tryParse(_quantityController.text) ?? 0.0,
        unitOfMeasure: _selectedUom,
        uom: selectedUomDetail,
        item: _selectedItem,
      );

      context.read<SalesOrderDetailBloc>().add(
        UpdateUnitPriceWithUom(
          salesOrderDetail: currentDetail,
          itemsInBranch: itemInBranch,
        ),
      );
    } else {
      _calculateExtendedPrice();
    }
  }

  void _showNoBranchesSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No branches available for selected item'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  List<ItemInBranchModel> _getAvailableBranchesForItem() {
    if (_selectedItem == null) return [];
    if (kDebugMode) {
      developer.log('selectedItem: ${_selectedItem!.id}');
    }
    final itemsInBranchBloc = context.read<StockItemInBranchBloc>();
    return itemsInBranchBloc.state.items
        .where((itemInBranch) => itemInBranch.itemNumber == _selectedItem!.id)
        .toList();
  }

  String _formatCurrency(double amount) {
    return NumberFormat('#,##0.00').format(amount);
  }

  bool _isFormValid() {
    return _selectedItem != null &&
        _selectedItemInBranch != null &&
        _quantityController.text.isNotEmpty &&
        (double.tryParse(_quantityController.text) ?? 0) > 0;
  }

  /// Calculates the total quantity already reserved in the confirmed items list
  /// for a specific item in branch combination.
  /// This excludes the current item being edited to allow full quantity access.
  double _getPendingQuantityForItem(int itemInBranchId) {
    final coordinatorState = context.read<SalesOrderCoordinatorBloc>().state;

    return coordinatorState.currentDetails
        .where((detail) {
          // Match by itemInBranch ID
          final matches = detail.itemInBranch == itemInBranchId;

          // If we're editing, exclude the current item from pending calculation
          // so user can access the full quantity of the item being edited
          if (widget.isEditing && widget.detail.tempId != null) {
            return matches && detail.tempId != widget.detail.tempId;
          }
          if (widget.isEditing && widget.detail.id != null) {
            return matches && detail.id != widget.detail.id;
          }

          return matches;
        })
        .fold<double>(0.0, (sum, detail) => sum + (detail.quantity ?? 0.0));
  }

  /// Returns the effective available quantity for the selected item in branch.
  /// This is the stock quantity minus quantities already confirmed in the order.
  double _getEffectiveAvailableQuantity() {
    if (_selectedItemInBranch == null) return 0.0;

    final stockQty = _selectedItemInBranch!.quantityAvailable ?? 0.0;
    final pendingQty = _getPendingQuantityForItem(_selectedItemInBranch!.id);

    return (stockQty - pendingQty).clamp(0.0, double.infinity);
  }

  /// Updates the available quantity controller with the effective quantity
  void _updateEffectiveAvailableQuantity() {
    final effectiveQty = _getEffectiveAvailableQuantity();
    _availableQuantityController.text = effectiveQty.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final availableBranches = _getAvailableBranchesForItem();

    if (_isInitializing) {
      return const Center(child: CircularProgressIndicator());
    }

    return Form(
      key: widget.formKey,
      child: BlocListener<SalesOrderDetailBloc, SalesOrderDetailState>(
        listener: (context, state) {
          // Listen for updates to selected1 (which holds the calculated detail)
          if (state.selected1 != null &&
              state.selected1!.tempId == widget.detail.tempId) {
            final updatedDetail = state.selected1!;

            // Update controllers if values changed
            if (updatedDetail.unitPrice != null) {
              final newPrice = updatedDetail.unitPrice!.toStringAsFixed(2);
              if (_unitPriceController.text != newPrice) {
                _unitPriceController.text = newPrice;
              }
            }

            if (updatedDetail.extendedPrice != null) {
              final newExtended = updatedDetail.extendedPrice!.toStringAsFixed(
                2,
              );
              if (_extendedPriceController.text != newExtended) {
                _extendedPriceController.text = newExtended;
              }
            }

            // Also call onUpdate to propagate changes up
            widget.onUpdate(updatedDetail);
          }
        },
        child: BlocListener<SalesOrderCoordinatorBloc, SalesOrderCoordinatorState>(
          listener: (context, state) {
            // Update available quantity when coordinator state (confirmed items) changes
            if (_selectedItemInBranch != null) {
              _updateEffectiveAvailableQuantity();
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item Selection
              BlocBuilder<StockItemsEntryBloc, ItemEntryState>(
                builder: (context, itemsState) {
                  return CustomTableDropdown<ItemEntryModel>(
                    title: 'Select Item *',
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
                            if (item.itemsId != null)
                              Text(
                                'ID: ${item.itemsId!}',
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                      ),
                      TableColumnConfig(
                        header: 'Price',
                        flex: 1,
                        cellBuilder: (item) => Text(
                          NumberFormat.currency(
                            decimalDigits: decimalPlace,
                            symbol: 'ETB ',
                          ).format(item.unitPrice),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
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
                BlocBuilder<StockItemInBranchBloc, ItemInBranchState>(
                  builder: (context, branchState) {
                    return CustomTableDropdown<ItemInBranchModel>(
                      title: 'Select Branch *',
                      items: availableBranches,
                      displayText: (itemInBranch) =>
                          itemInBranch.branchRef?.description ?? 'No Branch',
                      selectedValue: _selectedItemInBranch,
                      // emptyMessage: 'No branches available for selected item',
                      columns: [
                        TableColumnConfig(
                          header: 'Branch',
                          flex: 2,
                          cellBuilder: (itemInBranch) => Text(
                            itemInBranch.branchRef?.description ?? 'No Branch',
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                        TableColumnConfig(
                          header: 'Available',
                          flex: 1,
                          cellBuilder: (itemInBranch) {
                            // Calculate effective availability for this branch item
                            final stockQty =
                                itemInBranch.quantityAvailable ?? 0.0;
                            final pendingQty = _getPendingQuantityForItem(
                              itemInBranch.id,
                            );
                            final effectiveQty = (stockQty - pendingQty).clamp(
                              0.0,
                              double.infinity,
                            );

                            return Text(
                              effectiveQty.toStringAsFixed(0),
                              style: TextStyle(
                                fontSize: 10,
                                color: effectiveQty > 0
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                        TableColumnConfig(
                          header: 'Price',
                          flex: 1,
                          cellBuilder: (itemInBranch) => Text(
                            NumberFormat.currency(
                              decimalDigits: decimalPlace,
                              symbol: 'ETB ',
                            ).format(itemInBranch.unitPrice),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                      onItemSelected: (itemInBranch) {
                        _onBranchSelected(
                          itemInBranch?.branchRef,
                          itemInBranch,
                        );
                      },
                    );
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
                  // Check stock availability
                  if (_selectedItemInBranch != null) {
                    final availableQty = _getEffectiveAvailableQuantity();
                    if (quantity > availableQty) {
                      return 'Quantity exceeds available stock ($availableQty)';
                    }
                  }

                  return null;
                },
                onChanged: (value) {
                  // Dispatch update for price recalculation
                  if (_selectedItemInBranch != null) {
                    final selectedUomDetail = _resolveSelectedUomDetail();

                    final currentDetail = widget.detail.copyWith(
                      itemsTableId: _selectedItem?.id,
                      itemInBranch: _selectedItemInBranch?.id,
                      itemBranch: _selectedItemInBranch,
                      quantity: double.tryParse(value) ?? 0.0,
                      unitOfMeasure: _selectedUom,
                      uom: selectedUomDetail,
                      item: _selectedItem,
                    );

                    context.read<SalesOrderDetailBloc>().add(
                      UpdateUnitPriceWithUom(
                        salesOrderDetail: currentDetail,
                        itemsInBranch: _selectedItemInBranch,
                        manualUnitPrice: double.tryParse(
                          _unitPriceController.text,
                        ),
                      ),
                    );
                  } else {
                    _calculateExtendedPrice();
                  }
                },
              ),

              const SizedBox(height: 16),
              // UOM Selection (from branch)
              if (_selectedItemInBranch != null)
                BlocBuilder<ItemUomConversionBloc, ItemUomConversionState>(
                  builder: (context, state) {
                    if (state.isLoadingUomsForItem ||
                        state.status == ItemUomConversionStatus.loading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final udcList = state.availableUomsForItem;

                    if (udcList.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'No unit of measure available',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    return Builder(
                      builder: (context) {
                        String? currentUomDesc;
                        if (_selectedUom != null) {
                          final match = udcList.where(
                            (u) => u.id == _selectedUom,
                          );
                          if (match.isNotEmpty) {
                            currentUomDesc = match.first.description1;
                          }
                        }

                        return CustomSearchableDropdown(
                          labelText: 'Unit of Measure *',
                          options: udcList.map((u) => u.description1).toList(),
                          value: currentUomDesc,
                          prefixIcon: Iconsax.ruler,
                          allowCustomEntries: false,
                          onChanged: (value) {
                            setState(() {
                              if (value == null) {
                                _selectedUom = null;
                              } else {
                                final matches = udcList.where(
                                  (u) => u.description1 == value,
                                );
                                _selectedUom = matches.isNotEmpty
                                    ? matches.first.id
                                    : null;
                              }
                            });

                            // Dispatch update for price recalculation
                            if (_selectedItemInBranch != null) {
                              final selectedUomDetail =
                                  _resolveSelectedUomDetail();

                              final currentDetail = widget.detail.copyWith(
                                itemsTableId: _selectedItem?.id,
                                itemInBranch: _selectedItemInBranch?.id,
                                itemBranch: _selectedItemInBranch,
                                quantity:
                                    double.tryParse(_quantityController.text) ??
                                    0.0,
                                unitOfMeasure: _selectedUom,
                                uom: selectedUomDetail,
                                item: _selectedItem,
                              );

                              context.read<SalesOrderDetailBloc>().add(
                                UpdateUnitPriceWithUom(
                                  salesOrderDetail: currentDetail,
                                  itemsInBranch: _selectedItemInBranch,
                                ),
                              );
                            } else {
                              _updateDetail();
                            }
                          },
                          validator: (value) {
                            if (_selectedUom == null) {
                              return 'Please select a unit of measure';
                            }
                            return null;
                          },
                        );
                      },
                    );
                  },
                ),

              const SizedBox(height: 24),

              // Available Quantity (Read-only)
              CustomTextField(
                controller: _availableQuantityController,
                labelText: 'Available Quantity',
                readOnly: true,
              ),

              const SizedBox(height: 16),

              // Unit Price (read-only, driven by SalesOrderDetailBloc)
              BlocBuilder<SalesOrderDetailBloc, SalesOrderDetailState>(
                builder: (context, detailState) {
                  SalesOrderDetail effectiveDetail = widget.detail;

                  // Prefer the in-progress selected1 detail (for unconfirmed edits)
                  final selectedDetail = detailState.selected1;
                  if (selectedDetail != null &&
                      ((selectedDetail.id != null &&
                              selectedDetail.id == widget.detail.id) ||
                          (selectedDetail.tempId != null &&
                              selectedDetail.tempId == widget.detail.tempId))) {
                    effectiveDetail = selectedDetail;
                  } else {
                    final matching = detailState.createItems.firstWhere(
                      (d) =>
                          (d.id != null && d.id == widget.detail.id) ||
                          (d.tempId != null &&
                              d.tempId == widget.detail.tempId),
                      orElse: () => widget.detail,
                    );

                    effectiveDetail = matching;
                  }

                  final unitPrice =
                      effectiveDetail.unitPrice ??
                      double.tryParse(_unitPriceController.text) ??
                      0.0;
                  final formatted = unitPrice.toStringAsFixed(2);
                  if (_unitPriceController.text != formatted) {
                    _unitPriceController.text = formatted;
                  }

                  return CustomTextField(
                    controller: _unitPriceController,
                    labelText: 'Unit Price',
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      if (_selectedItemInBranch != null) {
                        final selectedUomDetail = _resolveSelectedUomDetail();

                        final currentDetail = widget.detail.copyWith(
                          itemsTableId: _selectedItem?.id,
                          itemInBranch: _selectedItemInBranch?.id,
                          itemBranch: _selectedItemInBranch,
                          quantity:
                              double.tryParse(_quantityController.text) ?? 0.0,
                          unitOfMeasure: _selectedUom,
                          uom: selectedUomDetail,
                          item: _selectedItem,
                        );

                        context.read<SalesOrderDetailBloc>().add(
                          UpdateUnitPriceWithUom(
                            salesOrderDetail: currentDetail,
                            itemsInBranch: _selectedItemInBranch,
                            manualUnitPrice: double.tryParse(value) ?? 0.0,
                          ),
                        );
                      }
                    },
                  );
                },
              ),

              const SizedBox(height: 16),

              // Extended Price (read-only, driven by SalesOrderDetailBloc)
              BlocBuilder<SalesOrderDetailBloc, SalesOrderDetailState>(
                builder: (context, detailState) {
                  SalesOrderDetail effectiveDetail = widget.detail;

                  // Prefer the in-progress selected1 detail (for unconfirmed edits)
                  final selectedDetail = detailState.selected1;
                  if (selectedDetail != null &&
                      ((selectedDetail.id != null &&
                              selectedDetail.id == widget.detail.id) ||
                          (selectedDetail.tempId != null &&
                              selectedDetail.tempId == widget.detail.tempId))) {
                    effectiveDetail = selectedDetail;
                  } else {
                    final matching = detailState.createItems.firstWhere(
                      (d) =>
                          (d.id != null && d.id == widget.detail.id) ||
                          (d.tempId != null &&
                              d.tempId == widget.detail.tempId),
                      orElse: () => widget.detail,
                    );

                    effectiveDetail = matching;
                  }

                  final lineTotal =
                      effectiveDetail.extendedPrice ??
                      double.tryParse(_extendedPriceController.text) ??
                      0.0;
                  final formatted = lineTotal.toStringAsFixed(2);
                  if (_extendedPriceController.text != formatted) {
                    _extendedPriceController.text = formatted;
                  }

                  return CustomTextField(
                    controller: _extendedPriceController,
                    labelText: 'Line Total',
                    readOnly: true,
                  );
                },
              ),

              const SizedBox(height: 16),

              // Confirm Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isFormValid()
                      ? () {
                          if (widget.formKey.currentState!.validate()) {
                            widget.onConfirm();
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFormValid()
                        ? const Color(0xFF155888)
                        : Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.isEditing ? Icons.save : Icons.check_circle,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.isEditing ? 'Update Item' : 'Confirm Item',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Help text
              Text(
                widget.isEditing
                    ? 'Item will be updated in the confirmed list below'
                    : 'Item will be added to the confirmed list below',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
