import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:savvy_stock/core/widgets/custom_dropdown.dart';
import 'package:savvy_stock/core/widgets/custom_text_Form.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/branch_list/blocs/branch_list_bloc.dart';
import 'package:savvy_stock/features/branch_list/blocs/branch_list_event.dart';
import 'package:savvy_stock/features/branch_list/blocs/branch_list_state.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_bloc.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_event.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_state.dart';
import 'package:savvy_stock/features/stock/item_entry/models/item_entry_model.dart';
import 'package:savvy_stock/features/stock/item_in_branch/blocs/item_in_branch_bloc.dart';
import 'package:savvy_stock/features/stock/item_in_branch/blocs/item_in_branch_event.dart';
import 'package:savvy_stock/features/stock/item_in_branch/blocs/item_in_branch_state.dart';
import 'package:savvy_stock/features/stock/item_in_branch/models/item_in_branch_model.dart';
import 'package:savvy_stock/features/stock/item_locations/blocs/item_locations_bloc.dart';
import 'package:savvy_stock/features/stock/item_locations/blocs/item_locations_event.dart'
    hide LoadItems;
import 'package:savvy_stock/features/stock/item_locations/blocs/item_locations_state.dart';
import 'package:savvy_stock/features/stock/lot_master/blocs/lot_master_bloc.dart';
import 'package:savvy_stock/features/stock/lot_master/blocs/lot_master_event.dart';
import 'package:savvy_stock/features/stock/lot_master/blocs/lot_master_state.dart';
import 'package:savvy_stock/features/stock/lot_master/models/lot_master_model.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_bloc.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_event.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_state.dart';

class LotMasterFormPage extends StatefulWidget {
  final LotMaster? lot;
  final AuthBloc authBloc;

  const LotMasterFormPage({super.key, this.lot, required this.authBloc});

  @override
  State<LotMasterFormPage> createState() => _LotMasterFormPageState();
}

class _LotMasterFormPageState extends State<LotMasterFormPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _quantityAvailableController =
      TextEditingController();
  final TextEditingController _unitPriceController = TextEditingController();
  final TextEditingController _supplierBatchController =
      TextEditingController();

  // Dropdown values
  int? _selectedBranch;
  int? _selectedItem;
  int? _selectedLocation;
  int? _selectedUom;
  int? _selectedLotStatus;

  // Date values
  DateTime? _effectiveDate;
  DateTime? _expirationDate;

  // Available data
  List<ItemInBranchModel> _branchItems = [];
  List<dynamic> _itemLocations = [];
  double _availableQuantity = 0.0;
  int? _itemUom;

  @override
  void initState() {
    super.initState();

    // Load initial data
    context.read<BranchBloc>().add(
      LoadBranchs(widget.authBloc.state.companyId!),
    );
    context.read<UdcDetailsBloc>().add(
      LoadUdcDetailsByGroup('LS'),
    ); // Lot Status

    _initializeForm();
  }

  void _initializeForm() {
    // For editing - prefill with existing lot data
    if (widget.lot != null) {
      final lot = widget.lot!;

      _selectedBranch = lot.branch;
      _selectedItem = lot.itemNumber;
      _effectiveDate = lot.dateEffective;
      _expirationDate = lot.dateExpiration;
      _selectedLotStatus = lot.lotStatus;
      _supplierBatchController.text = lot.batchNumberSupplier ?? '';
      _quantityAvailableController.text =
          lot.quantityAvailable?.toString() ?? '0.0';
      _unitPriceController.text = lot.unitPrice?.toString() ?? '';

      // Load items for the selected branch
      if (lot.branch != null) {
        context.read<StockItemInBranchBloc>().add(
          LoadItemsFromBranch(lot.branch!),
        );
      }

      // Load locations for the selected item and branch
      if (lot.branch != null && lot.itemNumber != null) {
        context.read<StockItemLocationBloc>().add(
          LoadItemLocationsByBranchAndItem(
            branchId: lot.branch!,
            itemId: lot.itemNumber!,
            companyId: widget.authBloc.state.companyId!,
          ),
        );
      }
    } else {
      // For creating - set default values
      _quantityAvailableController.text = '0.0';
    }
  }

  void _onBranchChanged(int? branchId) {
    setState(() {
      _selectedBranch = branchId;
      _selectedItem = null;
      _selectedLocation = null;
      _branchItems = [];
      _itemLocations = [];
      _availableQuantity = 0.0;
      _itemUom = null;
    });

    if (branchId != null) {
      // Load items for selected branch
      context.read<StockItemInBranchBloc>().add(LoadItemsFromBranch(branchId));
    }
  }

  String _getItemDescription(int? itemId) {
    if (itemId == null) return '';

    // You might want to get this from your item entry bloc
    // For now, we'll return a placeholder
    final itemInBranch = _branchItems.firstWhere(
      (item) => item.itemNumber == itemId,
      orElse: () => ItemInBranchModel.empty(),
    );

    // load item descriptions from item_entry bloc
    final itemEntryBloc = context.read<StockItemEntryBloc>();
    itemEntryBloc.add(LoadItems(widget.authBloc.state.companyId!));

    final itemEntryState = itemEntryBloc.state;
    if (itemEntryState.status == ItemEntryStatus.success) {
      final item = itemEntryState.items.firstWhere(
        (item) => item.id == itemId,
        orElse: () => ItemEntryModel.empty(),
      );
      return item.itemDescription ?? 'Item $itemId';
    }

    return 'Item $itemId';
  }

  void _onItemChanged(int? itemId) {
    setState(() {
      _selectedItem = itemId;
      _selectedLocation = null;
      _itemLocations = [];
      _availableQuantity = 0.0;
    });

    if (_selectedBranch != null && itemId != null) {
      // Load locations for selected item and branch
      context.read<StockItemLocationBloc>().add(
        LoadItemLocationsByBranchAndItem(
          branchId: _selectedBranch!,
          itemId: itemId,
          companyId: widget.authBloc.state.companyId!,
        ),
      );

      // Get item details for UOM and available quantity
      final itemInBranch = _branchItems.firstWhere(
        (item) => item.itemNumber == itemId,
        orElse: () => ItemInBranchModel.empty(),
      );

      if (itemInBranch.itemNumber != null) {
        setState(() {
          _itemUom = itemInBranch.unitOfMeasure;
          _availableQuantity = itemInBranch.quantityAvailable ?? 0.0;
          _unitPriceController.text = itemInBranch.unitPrice?.toString() ?? '';
        });
      }
    }
  }

  void _onLocationChanged(int? locationId) {
    setState(() {
      _selectedLocation = locationId;
    });

    // Update available quantity based on location
    if (locationId != null) {
      final location = _itemLocations.firstWhere(
        (loc) => loc['id'] == locationId,
        orElse: () => {'quantity_on_hand': 0.0},
      );

      setState(() {
        _availableQuantity =
            (location['quantity_on_hand'] as num?)?.toDouble() ?? 0.0;
      });
    }
  }

  void _selectEffectiveDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _effectiveDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _effectiveDate = picked;
      });
    }
  }

  void _selectExpirationDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _expirationDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _expirationDate = picked;
      });
    }
  }

  double? _parseDouble(String value) {
    if (value.trim().isEmpty) return null;
    return double.tryParse(value.trim());
  }

  int? _parseInt(String value) {
    if (value.trim().isEmpty) return null;
    return int.tryParse(value.trim());
  }

  @override
  void dispose() {
    _quantityAvailableController.dispose();
    _unitPriceController.dispose();
    _supplierBatchController.dispose();
    super.dispose();
  }

  void _saveLot() {
    if (_formKey.currentState!.validate()) {
      if (_selectedBranch == null ||
          _selectedItem == null ||
          _selectedLocation == null ||
          _selectedLotStatus == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill all required fields'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final lot = LotMaster(
        id: widget.lot?.id ?? 0,
        company: widget.authBloc.state.companyId,
        branch: _selectedBranch!,
        itemNumber: _selectedItem!,
        location: _selectedLocation!,
        quantityAvailable: _parseDouble(
          _quantityAvailableController.text.trim(),
        ),
        unitPrice: _parseDouble(_unitPriceController.text.trim()),
        dateEffective: _effectiveDate,
        dateExpiration: _expirationDate,
        lotStatus: _selectedLotStatus!,
        batchNumberSupplier: _supplierBatchController.text.trim().isEmpty
            ? null
            : _supplierBatchController.text.trim(),
        // unitOfMeasure: _itemUom,
        dateReceived: DateTime.now(), // Current date for received
      );

      if (widget.lot == null) {
        // Create new lot
        context.read<LotMasterBloc>().add(
          SaveLotMaster(
            lot,
            transactionType: 'C', // Creation
            transactionNumber: null,
            remark: 'Lot created manually',
          ),
        );
      } else {
        // Update existing lot
        context.read<LotMasterBloc>().add(
          UpdateLotMaster(
            lot,
            transactionType: 'U', // Update
            transactionNumber: null,
            remark: 'Lot updated',
          ),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Success'),
          ],
        ),
        content: Text(
          widget.lot == null
              ? 'Lot created successfully!'
              : 'Lot updated successfully!',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Go back to previous screen
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lot == null ? 'Create Lot' : 'Edit Lot'),
        backgroundColor: const Color(0xFF155888),
        elevation: 0,
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<LotMasterBloc, LotMasterState>(
            listener: (context, state) {
              if (state.status == LotMasterStatus.success) {
                _showSuccessDialog();
              } else if (state.status == LotMasterStatus.failure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message ?? 'An error occurred'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
          BlocListener<StockItemInBranchBloc, ItemInBranchState>(
            listener: (context, state) {
              if (state.status == ItemInBranchStatus.loaded) {
                setState(() {
                  _branchItems = state.items;
                });
              }
            },
          ),
          BlocListener<StockItemLocationBloc, ItemLocationsState>(
            listener: (context, state) {
              if (state.status == ItemLocationsStatus.success) {
                setState(() {
                  _itemLocations = state.items;
                });
              }
            },
          ),
        ],
        child: Column(children: [_buildForm(), _buildBottomNavigation()]),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Branch Dropdown
            BlocBuilder<BranchBloc, BranchState>(
              builder: (context, state) {
                if (state.status == BranchStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }

                return CustomDropdown(
                  labelText: 'Branch *',
                  value: _selectedBranch,
                  prefixIcon: const Icon(Iconsax.building),
                  items: state.branchs.map((branch) {
                    return DropdownMenuItem<int>(
                      value: branch.id,
                      child: Text(branch.description ?? 'Unknown Branch'),
                    );
                  }).toList(),
                  onChanged: _onBranchChanged,
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a branch';
                    }
                    return null;
                  },
                );
              },
            ),
            const SizedBox(height: 16),

            // Item Dropdown (depends on selected branch)
            BlocBuilder<StockItemInBranchBloc, ItemInBranchState>(
              builder: (context, state) {
                if (_selectedBranch == null) {
                  return const CustomDropdown(
                    labelText: 'Item *',
                    value: null,
                    prefixIcon: Icon(Iconsax.box),
                    items: [],
                    onChanged: null,
                    hintText: 'Please select a branch first',
                  );
                }

                if (state.status == ItemInBranchStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }

                return CustomDropdown(
                  labelText: 'Item *',
                  value: _selectedItem,
                  prefixIcon: const Icon(Iconsax.box),
                  items: _branchItems.map((item) {
                    return DropdownMenuItem<int>(
                      value: item.itemNumber,
                      child: Text(
                        '${item.itemNumber} - ${_getItemDescription(item.itemNumber)}',
                      ),
                    );
                  }).toList(),
                  onChanged: _onItemChanged,
                  validator: (value) {
                    if (value == null) {
                      return 'Please select an item';
                    }
                    return null;
                  },
                );
              },
            ),
            const SizedBox(height: 16),

            // Location Dropdown (depends on selected branch and item)
            BlocBuilder<StockItemLocationBloc, ItemLocationsState>(
              builder: (context, state) {
                if (_selectedBranch == null || _selectedItem == null) {
                  return const CustomDropdown(
                    labelText: 'Location *',
                    value: null,
                    prefixIcon: Icon(Iconsax.location),
                    items: [],
                    onChanged: null,
                    hintText: 'Please select branch and item first',
                  );
                }

                if (state.status == ItemLocationsStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }

                return CustomDropdown(
                  labelText: 'Location *',
                  value: _selectedLocation,
                  prefixIcon: const Icon(Iconsax.location),
                  items: _itemLocations.map((location) {
                    return DropdownMenuItem<int>(
                      value: location['id'] as int,
                      child: Text(
                        location['location_name'] ?? 'Unknown Location',
                      ),
                    );
                  }).toList(),
                  onChanged: _onLocationChanged,
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a location';
                    }
                    return null;
                  },
                );
              },
            ),
            const SizedBox(height: 16),

            // UOM Field (read-only, from selected item)
            BlocBuilder<UdcDetailsBloc, UdcDetailsState>(
              builder: (context, state) {
                if (state.status == UdcDetailsStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }

                return CustomDropdown(
                  labelText: 'Unit of Measure',
                  value: _selectedUom,
                  prefixIcon: const Icon(Iconsax.rulerpen),
                  items: state.details.where((udc) => udc.udcGroup == 'UM').map(
                    (udc) {
                      return DropdownMenuItem<int>(
                        value: udc.id,
                        child: Text(udc.description1),
                      );
                    },
                  ).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedUom = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select unit of measure';
                    }
                    return null;
                  },
                );
              },
            ),
            const SizedBox(height: 16),

            // Available Quantity Field (read-only, from selected item/location)
            CustomTextField(
              labelText: 'Available Quantity in Location',
              controller: TextEditingController(
                text: _availableQuantity.toStringAsFixed(2),
              ),
              readOnly: true,
              prefixIcon: const Icon(Iconsax.weight),
            ),
            const SizedBox(height: 16),

            // Quantity Available for Lot
            CustomTextField(
              labelText: 'Lot Quantity *',
              controller: _quantityAvailableController,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Lot quantity is required';
                }
                final quantity = _parseDouble(value);
                if (quantity == null || quantity <= 0) {
                  return 'Please enter a valid quantity';
                }
                if (quantity > _availableQuantity) {
                  return 'Quantity cannot exceed available quantity ($_availableQuantity)';
                }
                return null;
              },
              prefixIcon: const Icon(Iconsax.weight_1),
            ),
            const SizedBox(height: 16),

            // Unit Price
            CustomTextField(
              labelText: 'Unit Price',
              controller: _unitPriceController,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Unit price is required';
                }
                final price = _parseDouble(value);
                if (price == null || price < 0) {
                  return 'Please enter a valid price';
                }
                return null;
              },
              prefixIcon: const Icon(Iconsax.dollar_circle),
            ),
            const SizedBox(height: 16),

            // Effective Date
            GestureDetector(
              onTap: _selectEffectiveDate,
              child: CustomTextField(
                labelText: 'Effective Date',
                controller: TextEditingController(
                  text: _effectiveDate != null
                      ? '${_effectiveDate!.month}/${_effectiveDate!.day}/${_effectiveDate!.year}'
                      : '',
                ),
                readOnly: true,
                prefixIcon: const Icon(Iconsax.calendar_1),
                suffixIcon: IconButton(
                  icon: const Icon(Iconsax.calendar),
                  onPressed: _selectEffectiveDate,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Expiration Date
            GestureDetector(
              onTap: _selectExpirationDate,
              child: CustomTextField(
                labelText: 'Expiration Date',
                controller: TextEditingController(
                  text: _expirationDate != null
                      ? '${_expirationDate!.month}/${_expirationDate!.day}/${_expirationDate!.year}'
                      : '',
                ),
                readOnly: true,
                prefixIcon: const Icon(Iconsax.calendar_tick),
                suffixIcon: IconButton(
                  icon: const Icon(Iconsax.calendar),
                  onPressed: _selectExpirationDate,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Lot Status Dropdown
            BlocBuilder<UdcDetailsBloc, UdcDetailsState>(
              builder: (context, state) {
                if (state.status == UdcDetailsStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }

                return CustomDropdown(
                  labelText: 'Lot Status *',
                  value: _selectedLotStatus,
                  prefixIcon: const Icon(Iconsax.activity),
                  items: state.details
                      .where((udc) => udc.detailCode == 'LS')
                      .map((udc) {
                        return DropdownMenuItem<int>(
                          value: udc.id,
                          child: Text(udc.description1),
                        );
                      })
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedLotStatus = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select lot status';
                    }
                    return null;
                  },
                );
              },
            ),
            const SizedBox(height: 16),

            // Supplier Batch Number
            CustomTextField(
              labelText: 'Supplier Batch Number',
              controller: _supplierBatchController,
              prefixIcon: const Icon(Iconsax.barcode),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: const Icon(Iconsax.backward),
            style: IconButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          ElevatedButton(
            onPressed: _saveLot,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF155888),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              widget.lot == null ? 'Create Lot' : 'Update Lot',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
