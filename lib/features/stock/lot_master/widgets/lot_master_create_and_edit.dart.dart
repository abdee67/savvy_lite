import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_bloc.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_state.dart';
import 'package:savvy_stock/core/widgets/custom_dropdown.dart';
import 'package:savvy_stock/core/widgets/custom_text_Form.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/branch_list/blocs/branch_list_bloc.dart';
import 'package:savvy_stock/features/branch_list/blocs/branch_list_event.dart';
import 'package:savvy_stock/features/branch_list/blocs/branch_list_state.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_bloc.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_event.dart';
import 'package:savvy_stock/features/stock/item_in_branch/blocs/item_in_branch_bloc.dart';
import 'package:savvy_stock/features/stock/item_in_branch/blocs/item_in_branch_event.dart';
import 'package:savvy_stock/features/stock/item_in_branch/blocs/item_in_branch_state.dart';
import 'package:savvy_stock/features/stock/item_in_branch/models/item_in_branch_model.dart';
import 'package:savvy_stock/features/stock/item_locations/blocs/item_locations_bloc.dart';
import 'package:savvy_stock/features/stock/item_locations/blocs/item_locations_event.dart'
    hide LoadItems;
import 'package:savvy_stock/features/stock/item_locations/blocs/item_locations_state.dart';
import 'package:savvy_stock/features/stock/item_locations/models/item_locations_model.dart';
import 'package:savvy_stock/features/stock/location_entry/blocs/location_master_bloc.dart';
import 'package:savvy_stock/features/stock/lot_master/blocs/lot_master_bloc.dart';
import 'package:savvy_stock/features/stock/lot_master/blocs/lot_master_event.dart';
import 'package:savvy_stock/features/stock/lot_master/blocs/lot_master_state.dart';
import 'package:savvy_stock/features/stock/lot_master/models/lot_master_model.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_bloc.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_event.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_state.dart';
import 'package:savvy_stock/features/udc_detail/models/udc_details.dart';

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
  final TextEditingController _unitPriceController = TextEditingController();
  final TextEditingController _supplierBatchController =
      TextEditingController();
  final TextEditingController _availableQuantityController =
      TextEditingController();

  // Date controllers
  final TextEditingController _effectiveDateController =
      TextEditingController();
  final TextEditingController _expirationDateController =
      TextEditingController();
  final TextEditingController _receivedDateController = TextEditingController();

  final TextEditingController _lotNumberController = TextEditingController();

  // Dropdown values
  int? _selectedBranch;
  int? _selectedItem;
  int? _selectedLocation;
  int? _selectedUom;
  int? _selectedLotStatus;

  // Date values
  DateTime? _effectiveDate;
  DateTime? _expirationDate;
  DateTime? _receivedDate;

  // Available data
  List<ItemInBranchModel> _branchItems = [];
  List<ItemLocation> _itemLocations = [];
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
      LoadAllUdcDetails(),
    ); // for Unit of Measure and lot status

    context.read<StockItemInBranchBloc>().add(
      LoadItemsFromBranch(widget.authBloc.state.companyId!),
    );
    context.read<StockItemsEntryBloc>().add(
      LoadItems(widget.authBloc.state.companyId!),
    );

    // Initialize controllers
    _availableQuantityController.text = '0.0';

    _initializeForm();
  }

  void _initializeForm() {
    // For editing - prefill with existing lot data
    if (widget.lot != null) {
      final lot = widget.lot!;

      _selectedBranch = lot.branch;
      _setupLotNumberListener();
      _selectedItem = lot.itemNumber;
      _selectedLocation = lot.location;
      _effectiveDate = lot.dateEffective;
      _expirationDate = lot.dateExpiration;
      _receivedDate = lot.dateReceived;
      _selectedLotStatus = lot.lotStatus;
      _supplierBatchController.text = lot.batchNumberSupplier ?? '';
      _availableQuantityController.text =
          lot.quantityAvailable?.toString() ?? '0.0';
      _unitPriceController.text = lot.unitPrice?.toString() ?? '';

      // Update date controllers
      _updateDateControllers();

      // Load items for the selected branch
      if (lot.branch != null) {
        context.read<StockItemInBranchBloc>().add(
          LoadItemsFromBranch(
            widget.authBloc.state.companyId!,
            branchId: lot.branch!,
          ),
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
      _availableQuantityController.text = '0.0';
    }
  }

  void _updateDateControllers() {
    _effectiveDateController.text = _effectiveDate != null
        ? '${_effectiveDate!.month.toString().padLeft(2, '0')}/${_effectiveDate!.day.toString().padLeft(2, '0')}/${_effectiveDate!.year}'
        : '';

    _expirationDateController.text = _expirationDate != null
        ? '${_expirationDate!.month.toString().padLeft(2, '0')}/${_expirationDate!.day.toString().padLeft(2, '0')}/${_expirationDate!.year}'
        : '';

    _receivedDateController.text = _receivedDate != null
        ? '${_receivedDate!.month.toString().padLeft(2, '0')}/${_receivedDate!.day.toString().padLeft(2, '0')}/${_receivedDate!.year}'
        : '';
  }

  void _setupLotNumberListener() {
    context.read<LotMasterBloc>().stream.listen((state) {
      if (state.selected?.lotNumber != null) {
        _lotNumberController.text = state.selected!.lotNumber.toString();
      }
    });
  }

  void _onBranchChanged(int? branchId) {
    setState(() {
      _selectedBranch = branchId;
      _selectedItem = null;
      _selectedLocation = null;
      _selectedUom = null;
      _branchItems = [];
      _itemLocations = [];
      _availableQuantity = 0.0;
      _availableQuantityController.text = '0.0';
      _unitPriceController.clear();
    });

    if (branchId != null) {
      // Load items for selected branch
      context.read<StockItemInBranchBloc>().add(
        LoadItemsFromBranch(
          widget.authBloc.state.companyId!,
          branchId: branchId,
        ),
      );
    }
  }

  void _onItemChanged(int? itemId) {
    setState(() {
      _selectedItem = itemId;
      _selectedLocation = null;
      _selectedUom = null;
      _itemLocations = [];
      _availableQuantity = 0.0;
      _availableQuantityController.text = '0.0';
      _unitPriceController.clear();
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

      setState(() {
        _itemUom = itemInBranch.unitOfMeasure;
        _selectedUom = itemInBranch.unitOfMeasure;
        _availableQuantity = itemInBranch.quantityAvailable ?? 0.0;
        _availableQuantityController.text = _availableQuantity.toStringAsFixed(
          2,
        );
        _unitPriceController.text = itemInBranch.unitPrice?.toString() ?? '';
      });

      print(
        '🔄 Item selected - UOM: $_itemUom, Available Qty: $_availableQuantity',
      );
    }
  }

  void _onLocationChanged(int? locationId) {
    setState(() {
      _selectedLocation = locationId;
    });
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
        _updateDateControllers();
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
        _updateDateControllers();
      });
    }
  }

  void _selectReceivedDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _receivedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _receivedDate = picked;
        _updateDateControllers();
      });
    }
  }

  void _regenerateLotNumber() {
    final companyId = widget.authBloc.state.companyId;
    if (companyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Company ID not found. Please login again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    } else {
      context.read<LotMasterBloc>().add(RegenerateLotNumber());
    }
  }

  double? _parseDouble(String value) {
    if (value.trim().isEmpty) return null;
    return double.tryParse(value.trim());
  }

  @override
  void dispose() {
    _unitPriceController.dispose();
    _supplierBatchController.dispose();
    _availableQuantityController.dispose();
    _effectiveDateController.dispose();
    _expirationDateController.dispose();
    _receivedDateController.dispose();
    super.dispose();
  }

  void _saveLot() {
    if (_formKey.currentState!.validate()) {
      if (_selectedBranch == null ||
          _selectedItem == null ||
          _selectedLocation == null ||
          _lotNumberController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please select branch, item, location and lot number',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final lot = LotMaster(
        id: widget.lot?.id,
        company: widget.authBloc.state.companyId,
        lotNumber: int.parse(_lotNumberController.text.trim()),
        branch: _selectedBranch!,
        itemNumber: _selectedItem!,
        location: _selectedLocation!,
        quantityAvailable: _parseDouble(
          _availableQuantityController.text.trim(),
        ),
        unitPrice: _parseDouble(_unitPriceController.text.trim()),
        dateEffective: _effectiveDate,
        dateExpiration: _expirationDate,
        lotStatus: _selectedLotStatus,
        batchNumberSupplier: _supplierBatchController.text.trim().isEmpty
            ? null
            : _supplierBatchController.text.trim(),
        dateReceived: _receivedDate ?? DateTime.now(),
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
            remark: 'Lot updated manually',
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
      body: SafeArea(
        child: MultiBlocListener(
          listeners: [
            BlocListener<LotMasterBloc, LotMasterState>(
              listener: (context, state) {
                // Update lot number when it's generated or changed
                if (state.selected?.lotNumber != null &&
                    (() {
                      final txt = _lotNumberController.text.trim();
                      final current = int.tryParse(txt);
                      return current == null ||
                          state.selected!.lotNumber != current;
                    })()) {
                  setState(() {
                    _lotNumberController.text = state.selected!.lotNumber
                        .toString();
                  });
                }
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
                  print('📦 Loaded ${_branchItems.length} items for branch');
                }
              },
            ),
            BlocListener<StockItemLocationBloc, ItemLocationsState>(
              listener: (context, state) {
                if (state.status == ItemLocationsStatus.success) {
                  setState(() {
                    _itemLocations = state.items;
                  });
                  print(
                    '📍 Loaded ${_itemLocations.length} locations for item',
                  );
                }
              },
            ),
          ],
          child: Column(
            children: [
              Expanded(child: _buildForm()),
              _buildBottomNavigation(),
            ],
          ),
        ),
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
            // Lot Number Field (read-only for create, editable for edit if needed)
            CustomTextField(
              labelText: 'Lot Number *',
              controller: _lotNumberController,
              readOnly: widget.lot == null, // Read-only for new lots
              prefixIcon: const Icon(Iconsax.tag),
              suffixIcon: widget.lot == null
                  ? IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _regenerateLotNumber,
                      tooltip: 'Generate New Lot Number',
                    )
                  : null,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Lot number is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
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
                    if (value == null) return 'Please select a branch';
                    return null;
                  },
                );
              },
            ),
            const SizedBox(height: 16),

            // Item Dropdown
            BlocBuilder<StockItemInBranchBloc, ItemInBranchState>(
              builder: (context, state) {
                if (_selectedBranch == null) {
                  return const CustomDropdown(
                    labelText: 'Item *',
                    value: null,
                    prefixIcon: Icon(Iconsax.box),
                    items: [],
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
                    // Load item descriptions from item entry
                    final itemEntryBloc = context.read<StockItemsEntryBloc>();
                    final itemEntryState = itemEntryBloc.state;
                    final itemDescription =
                        itemEntryState.items
                            .where((entry) => entry.id == item.itemNumber)
                            .firstOrNull
                            ?.itemDescription ??
                        'Item ${item.itemNumber}';

                    return DropdownMenuItem<int>(
                      value: item.itemNumber,
                      child: Text(itemDescription),
                    );
                  }).toList(),
                  onChanged: _onItemChanged,
                  validator: (value) {
                    if (value == null) return 'Please select an item';
                    return null;
                  },
                );
              },
            ),
            const SizedBox(height: 16),

            // Location Dropdown
            BlocBuilder<StockItemLocationBloc, ItemLocationsState>(
              builder: (context, state) {
                if (_selectedBranch == null || _selectedItem == null) {
                  return const CustomDropdown(
                    labelText: 'Location *',
                    value: null,
                    prefixIcon: Icon(Iconsax.location),
                    items: [],
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
                    // Load location names from location master
                    final locationMasterBloc = context
                        .read<LocationMasterBloc>();
                    final locationMasterState = locationMasterBloc.state;
                    final locationName =
                        locationMasterState.items
                            .where((loc) => loc.id == location.location)
                            .firstOrNull
                            ?.locationDescription ??
                        'Location ${location.location}';

                    return DropdownMenuItem<int>(
                      value: location.location,
                      child: Text(locationName),
                    );
                  }).toList(),
                  onChanged: _onLocationChanged,
                  validator: (value) {
                    if (value == null) return 'Please select a location';
                    return null;
                  },
                );
              },
            ),
            const SizedBox(height: 16),

            // UOM Field
            BlocBuilder<UdcDetailsBloc, UdcDetailsState>(
              builder: (context, state) {
                final uomItems = state.details
                    .where((udc) => udc.udcGroup == 'UM')
                    .toList();

                return CustomDropdown(
                  labelText: 'Unit of Measure',
                  value: _selectedUom,
                  prefixIcon: const Icon(Iconsax.rulerpen),
                  items: uomItems.map((udc) {
                    return DropdownMenuItem<int>(
                      value: udc.id,
                      child: Text(udc.description1),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedUom = value;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 16),

            // Available Quantity Field
            CustomTextField(
              labelText: 'Available Quantity in Location',
              controller: _availableQuantityController,
              readOnly: true,
              prefixIcon: const Icon(Iconsax.weight),
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

            // Date fields shown based on system constant lot type
            BlocBuilder<SystemConstantBloc, SystemConstantState>(
              builder: (context, sysState) {
                final lotTypeId = sysState.selected?.lotType;
                final udcState = context.watch<UdcDetailsBloc>().state;
                UdcDetails? lotTypeUdc;
                if (lotTypeId != null) {
                  final matches = udcState.details.where(
                    (d) => d.id == lotTypeId,
                  );
                  if (matches.isNotEmpty) lotTypeUdc = matches.first;
                }
                final lotTypeCode = lotTypeUdc?.detailCode.toUpperCase();

                // If lot type is Effective (F) -> show only Effective Date
                if (lotTypeCode == 'F') {
                  return Column(
                    children: [
                      CustomTextField(
                        labelText: 'Effective Date',
                        controller: _effectiveDateController,
                        readOnly: true,
                        prefixIcon: const Icon(Iconsax.calendar_1),
                        suffixIcon: IconButton(
                          icon: const Icon(Iconsax.calendar),
                          onPressed: _selectEffectiveDate,
                        ),
                        onTap: _selectEffectiveDate,
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                }

                // If lot type is Expiration (X) -> show only Expiration Date
                if (lotTypeCode == 'X') {
                  return Column(
                    children: [
                      CustomTextField(
                        labelText: 'Expiration Date',
                        controller: _expirationDateController,
                        readOnly: true,
                        prefixIcon: const Icon(Iconsax.calendar_tick),
                        suffixIcon: IconButton(
                          icon: const Icon(Iconsax.calendar),
                          onPressed: _selectExpirationDate,
                        ),
                        onTap: _selectExpirationDate,
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                }

                // If lot type is Receipt (R) -> show only Received Date
                if (lotTypeCode == 'R') {
                  return Column(
                    children: [
                      CustomTextField(
                        labelText: 'Received Date',
                        controller: _receivedDateController,
                        readOnly: true,
                        prefixIcon: const Icon(Iconsax.calendar),
                        suffixIcon: IconButton(
                          icon: const Icon(Iconsax.calendar),
                          onPressed: _selectReceivedDate,
                        ),
                        onTap: _selectReceivedDate,
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                }

                // Default: show Effective and Expiration
                return Column(
                  children: [
                    CustomTextField(
                      labelText: 'Effective Date',
                      controller: _effectiveDateController,
                      readOnly: true,
                      prefixIcon: const Icon(Iconsax.calendar_1),
                      suffixIcon: IconButton(
                        icon: const Icon(Iconsax.calendar),
                        onPressed: _selectEffectiveDate,
                      ),
                      onTap: _selectEffectiveDate,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      labelText: 'Expiration Date',
                      controller: _expirationDateController,
                      readOnly: true,
                      prefixIcon: const Icon(Iconsax.calendar_tick),
                      suffixIcon: IconButton(
                        icon: const Icon(Iconsax.calendar),
                        onPressed: _selectExpirationDate,
                      ),
                      onTap: _selectExpirationDate,
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),

            // Lot Status Dropdown
            BlocBuilder<UdcDetailsBloc, UdcDetailsState>(
              builder: (context, state) {
                final lotStatusItems = state.details
                    .where((udc) => udc.udcGroup == 'LS')
                    .toList();

                return CustomDropdown(
                  labelText: 'Lot Status',
                  value: _selectedLotStatus,
                  prefixIcon: const Icon(Iconsax.activity),
                  items: lotStatusItems.map((udc) {
                    return DropdownMenuItem<int>(
                      value: udc.id,
                      child: Text(udc.description1),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedLotStatus = value;
                    });
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: Theme.of(context).primaryColor),
              ),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _saveLot,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF155888),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                widget.lot == null ? 'Create Lot' : 'Update Lot',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
