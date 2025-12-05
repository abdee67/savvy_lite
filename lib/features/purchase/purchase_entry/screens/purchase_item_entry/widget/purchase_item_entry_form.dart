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
import 'package:savvy_stock/features/branch_list/blocs/branch_list_state.dart';
import 'package:savvy_stock/features/branch_list/models/branch_list_model.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/bloc/purchase_order_bloc.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/bloc/purchase_order_event.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/bloc/purchase_order_state.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/models/purchase_order_detail_model.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_bloc.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_event.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_state.dart';
import 'package:savvy_stock/features/stock/item_entry/models/item_entry_model.dart';
import 'package:savvy_stock/features/stock/item_locations/blocs/item_locations_bloc.dart';
import 'package:savvy_stock/features/stock/item_locations/blocs/item_locations_event.dart';
import 'package:savvy_stock/features/stock/item_locations/blocs/item_locations_state.dart';
import 'package:savvy_stock/features/stock/item_locations/models/item_locations_model.dart';
import 'package:savvy_stock/features/stock/item_uom_conversions/blocs/item_uom_conversions_bloc.dart';
import 'package:savvy_stock/features/stock/item_uom_conversions/blocs/item_uom_conversions_event.dart';
import 'package:savvy_stock/features/stock/item_uom_conversions/blocs/item_uom_conversions_state.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_bloc.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_event.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_state.dart';
import 'package:savvy_stock/features/udc_detail/models/udc_details.dart';

class PurchaseItemEntryForm extends StatefulWidget {
  final PurchaseOrderDetail? initialDetail;
  final GlobalKey<FormState> formKey;
  final bool isEditing;
  final Function(PurchaseOrderDetail) onUpdate;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final Map<String, dynamic> orderData; // Contains autoReceipt flag

  const PurchaseItemEntryForm({
    super.key,
    this.initialDetail,
    required this.formKey,
    required this.isEditing,
    required this.onUpdate,
    required this.onConfirm,
    this.onCancel,
    required this.orderData,
  });

  @override
  State<PurchaseItemEntryForm> createState() => _PurchaseItemEntryFormState();
}

class _PurchaseItemEntryFormState extends State<PurchaseItemEntryForm> {
  late TextEditingController _quantityController;
  late TextEditingController _unitCostController;
  late TextEditingController _extendedAmountController;
  late TextEditingController _effectiveDateController;
  late TextEditingController _expirationDateController;
  late TextEditingController _batchNumberController;

  ItemEntryModel? _selectedItem;
  Branch? _selectedBranch;
  ItemLocation? _selectedLocation;
  UdcDetails? _selectedUom;

  DateTime? _effectiveDate;
  DateTime? _expirationDate;

  bool _isInitializing = true;
  bool _showBranchLocationFields = false;
  List<ItemLocation> _availableLocations = [];

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    _quantityController = TextEditingController();
    _unitCostController = TextEditingController();
    _extendedAmountController = TextEditingController();
    _effectiveDateController = TextEditingController();
    _expirationDateController = TextEditingController();
    _batchNumberController = TextEditingController();

    // Determine if we should show branch/location fields
    _showBranchLocationFields = widget.orderData['autoReceipt'] != true;

    // Load initial data after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
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
    }

    // Initialize form with existing data
    _initializeForm();
  }

  void _initializeForm() {
    final detail = widget.initialDetail;
    final purchaseState = context.read<PurchaseOrderBloc>().state;

    // Get autoReceipt from state
    final autoReceipt =
        purchaseState.autoReceipt ?? widget.orderData['autoReceipt'] == true;

    setState(() {
      _showBranchLocationFields = !autoReceipt;
    });

    // Set initial values
    if (detail != null) {
      _quantityController.text =
          detail.quantityTransaction?.toStringAsFixed(2) ?? '1.00';
      _unitCostController.text = detail.unitCost?.toStringAsFixed(2) ?? '0.00';
      _extendedAmountController.text =
          detail.amountExtendedCost?.toStringAsFixed(2) ?? '0.00';
      _batchNumberController.text = detail.batchNumberSupplier ?? '';

      // Set dates
      _effectiveDate = detail.dateEffective;
      _expirationDate = detail.dateExpiration;
      _updateDateControllers();

      // If editing, pre-populate item
      if (widget.isEditing && detail.itemNumber != null) {
        _loadItemDetails(detail.itemNumber!);
      }
    } else {
      _quantityController.text = '1.00';
      _unitCostController.text = '0.00';
      _extendedAmountController.text = '0.00';
    }

    setState(() {
      _isInitializing = false;
    });

    // Calculate initial extended amount
    _calculateExtendedAmount();
  }

  void _loadItemDetails(int itemId) {
    final itemsBloc = context.read<StockItemsEntryBloc>();
    final items = itemsBloc.state.items;

    try {
      final existingItem = items.firstWhere((item) => item.id == itemId);
      setState(() {
        _selectedItem = existingItem;
      });

      // Load UOM conversions for this item
      _loadUomConversions(itemId);
    } catch (e) {
      print('Item not found: $itemId');
    }
  }

  void _loadUomConversions(int itemId) {
    final authBloc = context.read<AuthBloc>();
    final companyId = authBloc.state.companyId;

    if (companyId != null) {
      final uomBloc = context.read<ItemUomConversionBloc>();
      uomBloc.add(LoadUomsForItem(itemId: itemId, companyId: companyId));
    }
  }

  void _updateDateControllers() {
    _effectiveDateController.text = _effectiveDate != null
        ? '${_effectiveDate!.year}-${_effectiveDate!.month.toString().padLeft(2, '0')}-${_effectiveDate!.day.toString().padLeft(2, '0')}'
        : '';

    _expirationDateController.text = _expirationDate != null
        ? '${_expirationDate!.year}-${_expirationDate!.month.toString().padLeft(2, '0')}-${_expirationDate!.day.toString().padLeft(2, '0')}'
        : '';
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _unitCostController.dispose();
    _extendedAmountController.dispose();
    _effectiveDateController.dispose();
    _expirationDateController.dispose();
    _batchNumberController.dispose();
    super.dispose();
  }

  void _calculateExtendedAmount() {
    if (_isInitializing) return;

    final quantity = double.tryParse(_quantityController.text) ?? 0;
    final unitCost = double.tryParse(_unitCostController.text) ?? 0;
    final extendedAmount = quantity * unitCost;

    _extendedAmountController.text = extendedAmount.toStringAsFixed(2);

    // Update the detail
    _updateDetail();
  }

  void _updateDetail() {
    if (_isInitializing) return;

    final detail =
        widget.initialDetail ??
        PurchaseOrderDetail(
          tempId: DateTime.now().millisecondsSinceEpoch,
          company: context.read<AuthBloc>().state.companyId,
        );

    final updatedDetail = detail.copyWith(
      itemNumber: _selectedItem?.id,
      // itemDescription: _selectedItem?.itemDescription,
      quantityTransaction: double.tryParse(_quantityController.text),
      unitCost: double.tryParse(_unitCostController.text),
      amountExtendedCost: double.tryParse(_extendedAmountController.text),
      unitOfMeasure: _selectedUom?.id,
      dateEffective: _effectiveDate,
      dateExpiration: _expirationDate,
      batchNumberSupplier: _batchNumberController.text.isNotEmpty
          ? _batchNumberController.text
          : null,
      //itemLocationsSelect: _selectedLocation?.id,
    );

    // Trigger calculation event in bloc
    context.read<PurchaseOrderBloc>().add(
      CalculateExtendedCost(detail: updatedDetail),
    );

    widget.onUpdate(updatedDetail);
  }

  void _onItemSelected(ItemEntryModel? item) {
    setState(() {
      _selectedItem = item;
      _selectedUom = null;

      // If item has default UOM, try to find it
      if (item?.unitOfMeasure != null) {
        _loadDefaultUom(item!.id);
      }

      // Load UOM conversions for this item
      if (item != null) {
        _loadUomConversions(item.id!);
      }
    });

    _calculateExtendedAmount();
  }

  void _loadDefaultUom(int uomCode) {
    final udcBloc = context.read<UdcDetailsBloc>();
    final uomDetails = udcBloc.state.details
        .where((udc) => udc.id == uomCode)
        .toList();

    if (uomDetails.isNotEmpty) {
      setState(() {
        _selectedUom = uomDetails.first;
      });
    }
  }

  void _onBranchSelected(Branch? branch) {
    setState(() {
      _selectedBranch = branch;
      _selectedLocation = null;
      _availableLocations = [];
    });

    if (branch != null) {
      // Load locations for selected branch
      _loadBranchLocations(branch.id!);
    }
  }

  void _loadBranchLocations(int branchId) {
    final authBloc = context.read<AuthBloc>();
    final companyId = authBloc.state.companyId;

    if (companyId != null) {
      final locationsBloc = context.read<StockItemLocationBloc>();
      locationsBloc.add(
        LoadItemLocationsForBranch(branchId: branchId, companyId: companyId),
      );

      // Listen for location data
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final locationsState = locationsBloc.state;
        if (locationsState.status == ItemLocationsStatus.success) {
          setState(() {
            _availableLocations = locationsState.items;
          });
        }
      });
    }
  }

  void _onLocationSelected(ItemLocation? location) {
    setState(() {
      _selectedLocation = location;
    });

    _updateDetail();
  }

  void _onUomSelected(UdcDetails? uom) {
    setState(() {
      _selectedUom = uom;
    });

    _updateDetail();
  }

  Future<void> _selectDate(BuildContext context, bool isEffectiveDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isEffectiveDate
          ? (_effectiveDate ?? DateTime.now())
          : (_expirationDate ?? DateTime.now().add(const Duration(days: 365))),
      firstDate: isEffectiveDate
          ? DateTime.now().subtract(const Duration(days: 365))
          : (_effectiveDate ?? DateTime.now()),
      lastDate: isEffectiveDate
          ? DateTime.now().add(const Duration(days: 365 * 10))
          : DateTime.now().add(const Duration(days: 365 * 10)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF155888),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF155888),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isEffectiveDate) {
          _effectiveDate = picked;
        } else {
          _expirationDate = picked;
        }
        _updateDateControllers();
      });

      _updateDetail();
    }
  }

  String _formatCurrency(double amount) {
    return NumberFormat('#,##0.00').format(amount);
  }

  bool _isFormValid() {
    return _selectedItem != null &&
        _quantityController.text.isNotEmpty &&
        (double.tryParse(_quantityController.text) ?? 0) > 0 &&
        _unitCostController.text.isNotEmpty &&
        (double.tryParse(_unitCostController.text) ?? 0) >= 0;
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Center(child: CircularProgressIndicator());
    }

    return Form(
      key: widget.formKey,
      child: BlocListener<PurchaseOrderBloc, PurchaseOrderState>(
        listener: (context, state) {
          // Listen for calculated extended cost updates
          if (state.selectedDetail != null &&
              state.selectedDetail!.tempId == widget.initialDetail?.tempId) {
            final updatedDetail = state.selectedDetail!;

            if (updatedDetail.amountExtendedCost != null) {
              final newAmount = updatedDetail.amountExtendedCost!
                  .toStringAsFixed(2);
              if (_extendedAmountController.text != newAmount) {
                _extendedAmountController.text = newAmount;
              }
            }

            widget.onUpdate(updatedDetail);
          }
        },
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Icon(
                      widget.isEditing ? Icons.edit : Icons.add,
                      color: widget.isEditing
                          ? Colors.orange
                          : const Color(0xFF155888),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.isEditing ? 'Editing Item' : 'Add Purchase Item',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: widget.isEditing
                            ? Colors.orange
                            : const Color(0xFF155888),
                      ),
                    ),
                    const Spacer(),
                    if (widget.isEditing && widget.onCancel != null)
                      TextButton(
                        onPressed: widget.onCancel,
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ),

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
                    searchHint: 'Search items by name or code...',
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
                                'Code: ${item.itemsId!}',
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                      ),
                      TableColumnConfig(
                        header: 'Default UOM',
                        flex: 1,
                        cellBuilder: (item) => Text(
                          item.unitOfMeasure ?? 'N/A',
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

              // Quantity Input
              CustomTextField(
                controller: _quantityController,
                labelText: 'Quantity *',
                prefixIcon: const Icon(Iconsax.scan_barcode),
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
                  return null;
                },
                onChanged: (value) {
                  _calculateExtendedAmount();
                },
              ),

              const SizedBox(height: 16),

              // UoM Selection
              BlocBuilder<UdcDetailsBloc, UdcDetailsState>(
                builder: (context, udcState) {
                  return BlocBuilder<
                    ItemUomConversionBloc,
                    ItemUomConversionState
                  >(
                    builder: (context, uomState) {
                      // Get available UOMs for the selected item
                      List<UdcDetails> availableUoms = [];

                      if (_selectedItem != null &&
                          uomState.availableUomsForItem.isNotEmpty) {
                        // Get UOM details from UDC
                        availableUoms = udcState.details
                            .where(
                              (udc) => uomState.availableUomsForItem.any(
                                (uom) => uom.id == udc.id,
                              ),
                            )
                            .toList();

                        // Add default UOM if not already in list
                        if (_selectedItem?.unitOfMeasure != null) {
                          final defaultUom = udcState.details.firstWhere(
                            (udc) =>
                                udc.description1 ==
                                _selectedItem!.unitOfMeasure,
                            orElse: () => UdcDetails.empty(),
                          );
                          if (defaultUom.id != null &&
                              !availableUoms.contains(defaultUom)) {
                            availableUoms.add(defaultUom);
                          }
                        }
                      }

                      if (availableUoms.isEmpty && _selectedUom != null) {
                        availableUoms.add(_selectedUom!);
                      }

                      return CustomSearchableDropdown(
                        labelText: 'Unit of Measure *',
                        options: availableUoms
                            .map((uom) => uom.description1)
                            .toList(),
                        value: _selectedUom?.description1,
                        prefixIcon: Iconsax.ruler,
                        allowCustomEntries: false,
                        onChanged: (uom) {
                          _onUomSelected(
                            availableUoms.firstWhere(
                              (uom) => uom.description1 == uom,
                            ),
                          );
                        },
                        validator: (value) {
                          if (_selectedItem != null && _selectedUom == null) {
                            return 'Please select unit of measure';
                          }
                          return null;
                        },
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 16),

              // Branch and Location Fields (only if auto receipt is OFF)
              if (_showBranchLocationFields) ...[
                BlocBuilder<BranchBloc, BranchState>(
                  builder: (context, branchState) {
                    return CustomSearchableDropdown(
                      labelText: 'Branch *',
                      options: branchState.branchs
                          .map((branch) => branch.description ?? 'No Name')
                          .toList(),
                      value: _selectedBranch?.description,
                      prefixIcon: Icons.business,
                      allowCustomEntries: false,
                      onChanged: (branch) {
                        _onBranchSelected(
                          branchState.branchs.firstWhere(
                            (branch) => branch.description == branch,
                          ),
                        );
                      },
                      validator: (value) {
                        if (_showBranchLocationFields &&
                            _selectedBranch == null) {
                          return 'Please select branch';
                        }
                        return null;
                      },
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Location Dropdown (only if branch is selected)
                if (_selectedBranch != null) ...[
                  BlocBuilder<StockItemLocationBloc, ItemLocationsState>(
                    builder: (context, locationState) {
                      return CustomSearchableDropdown(
                        labelText: 'Location',
                        options: locationState.items
                            .map(
                              (location) =>
                                  location.locationDescription ?? 'No Name',
                            )
                            .toList(),
                        value: _selectedLocation?.locationDescription,
                        prefixIcon: Icons.location_on,
                        allowCustomEntries: false,
                        onChanged: (location) {
                          _onLocationSelected(
                            locationState.items.firstWhere(
                              (location) =>
                                  location.locationDescription == location,
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ],

              // Unit Cost and Extended Amount Row
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _unitCostController,
                      labelText: 'Unit Cost *',
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter unit cost';
                        }
                        final cost = double.tryParse(value);
                        if (cost == null || cost < 0) {
                          return 'Please enter valid unit cost';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        _calculateExtendedAmount();
                      },
                      prefixIcon: const Icon(Icons.attach_money),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      controller: _extendedAmountController,
                      labelText: 'Extended Amount',
                      readOnly: true,
                      prefixIcon: const Icon(Icons.calculate),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Effective Date
              CustomTextField(
                controller: _effectiveDateController,
                labelText: 'Effective Date',
                readOnly: true,
                prefixIcon: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context, true),
              ),

              const SizedBox(height: 16),

              // Expiration Date
              CustomTextField(
                controller: _expirationDateController,
                labelText: 'Expiration Date',
                readOnly: true,
                prefixIcon: const Icon(Icons.event_busy),
                onTap: () => _selectDate(context, false),
              ),

              const SizedBox(height: 16),

              // Supplier Batch Number
              CustomTextField(
                controller: _batchNumberController,
                labelText: 'Supplier Batch Number',
                onChanged: (value) {
                  _updateDetail();
                },
                prefixIcon: const Icon(Icons.numbers),
              ),

              const SizedBox(height: 24),

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
                        widget.isEditing ? 'Update Item' : 'Add to Order',
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
