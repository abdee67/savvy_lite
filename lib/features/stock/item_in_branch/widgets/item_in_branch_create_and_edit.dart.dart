import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:savvy_stock/core/widgets/custom_searchable_dropdown.dart';
import 'package:savvy_stock/core/widgets/custom_dropdown.dart';
import 'package:savvy_stock/core/widgets/custom_text_Form.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/branch_list/blocs/branch_list_bloc.dart';
import 'package:savvy_stock/features/branch_list/blocs/branch_list_event.dart';
import 'package:savvy_stock/features/branch_list/blocs/branch_list_state.dart';
import 'package:savvy_stock/features/stock/item_in_branch/blocs/item_in_branch_bloc.dart';
import 'package:savvy_stock/features/stock/item_in_branch/blocs/item_in_branch_event.dart';
import 'package:savvy_stock/features/stock/item_in_branch/blocs/item_in_branch_state.dart';
import 'package:savvy_stock/features/stock/item_in_branch/models/item_in_branch_model.dart';
import 'package:savvy_stock/features/stock/item_entry/models/item_entry_model.dart';
import 'package:savvy_stock/features/stock/item_uom_conversions/blocs/item_uom_conversions_bloc.dart';
import 'package:savvy_stock/features/stock/item_uom_conversions/blocs/item_uom_conversions_state.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_bloc.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_event.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_state.dart';

class ItemInBranchFormPage extends StatefulWidget {
  final ItemInBranchModel? item;
  final ItemEntryModel? itemEntry;
  final AuthBloc authBloc;

  const ItemInBranchFormPage({
    super.key,
    this.item,
    this.itemEntry,
    required this.authBloc,
  });

  @override
  State<ItemInBranchFormPage> createState() => _ItemInBranchFormPageState();
}

class _ItemInBranchFormPageState extends State<ItemInBranchFormPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _itemNumberController = TextEditingController();
  final TextEditingController _quantityAvailableController =
      TextEditingController();
  final TextEditingController _unitPriceController = TextEditingController();
  final TextEditingController _marginRateController = TextEditingController();

  String? _selectedMarginType;
  int? _selectedUom;
  int? _branch;
  // Track the underlying ItemEntry DB id when available (used for itemNumber)
  int? _itemEntryId;

  final List<String> _marginTypes = ['Flat', 'Percentage'];

  @override
  void initState() {
    super.initState();
    context.read<BranchBloc>().add(
      LoadBranchs(widget.authBloc.state.companyId!),
    );
    context.read<UdcDetailsBloc>().add(LoadUdcDetailsByGroup('UM'));
    _initializeControllers();
    if (widget.item != null) {
      context.read<StockItemInBranchBloc>().add(
        SetItemFormFromBranch(widget.item!),
      );
    }
  }

  void _initializeControllers() {
    // Editing existing ItemInBranch
    if (widget.item != null) {
      final item = widget.item!;
      // item.itemNumber stores the ItemEntry.id (DB PK)
      _itemEntryId = item.itemNumber;
      // Prefer to display the human-friendly itemsId if available
      _itemNumberController.text =
          item.itemRef?.itemsId?.toString() ?? item.itemNumber.toString();
      _quantityAvailableController.text =
          item.quantityAvailable?.toString() ?? '';
      _unitPriceController.text = item.unitPrice?.toString() ?? '';
      _marginRateController.text = item.marginRate?.toString() ?? '';
      final marginType = item.marginType;
      if (marginType != null) {
        _selectedMarginType = marginType;
      } else {
        _selectedMarginType = null;
      }
      _selectedUom = item.unitOfMeasure;
      _branch = item.branch;
    }
    // Creating from an ItemEntry
    else if (widget.itemEntry != null) {
      final entry = widget.itemEntry!;
      _itemEntryId = entry.id;
      _itemNumberController.text =
          entry.itemsId?.toString() ?? entry.id.toString();
      _quantityAvailableController.text = '0';
      _unitPriceController.text = entry.unitPrice?.toString() ?? '';
      _marginRateController.text = entry.marginRate?.toString() ?? '';
      final marginType = entry.marginType;
      if (marginType != null &&
          marginType.isNotEmpty &&
          _marginTypes.contains(marginType)) {
        _selectedMarginType = marginType;
      } else {
        _selectedMarginType = null;
      }
      _selectedUom = int.tryParse(entry.unitOfMeasure ?? '');
    }
    // Empty/new
    else {
      _itemEntryId = null;
      _itemNumberController.text = '';
      _quantityAvailableController.text = '0';
      _unitPriceController.text = '';
      _marginRateController.text = '';
      _selectedMarginType = null;
      _selectedUom = null;
      _branch = null;
    }
  }

  // Add this method to properly reset the form
  void _resetForm() {
    // Clear all text controllers
    _quantityAvailableController.clear();
    _unitPriceController.clear();
    _marginRateController.clear();

    // Reset dropdown selections
    setState(() {
      _selectedMarginType = null;
      _selectedUom = null;
      _branch = null;
    });

    // Reset form validation state
    _formKey.currentState?.reset();

    // Note: Item number stays prefilled if it came from item entry
    // This allows adding the same item to multiple branches
  }

  // Add this helper method for safe number parsing
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
    _itemNumberController.dispose();
    _quantityAvailableController.dispose();
    _unitPriceController.dispose();
    _marginRateController.dispose();
    super.dispose();
  }

  void _saveItem(ItemInBranchState state) {
    if (_formKey.currentState!.validate()) {
      if (_selectedUom == null || _branch == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please select unit of measure and branch'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      // Determine the ItemEntry id to store in itemNumber.
      // Priority: tracked _itemEntryId (set when initialized from models) ->
      // widget.itemEntry (creating) -> widget.item.itemNumber (editing) ->
      // fallback parse from text field.
      final int? parsedFromText = int.tryParse(
        _itemNumberController.text.trim(),
      );
      final int? resolvedItemEntryId =
          _itemEntryId ??
          widget.itemEntry?.id ??
          widget.item?.itemNumber ??
          parsedFromText;
      if (resolvedItemEntryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid or missing item entry id'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      final int itemNumber = resolvedItemEntryId;
      final item = ItemInBranchModel(
        id: widget.item?.id ?? 0,
        itemNumber: itemNumber,
        quantityAvailable: _parseDouble(
          _quantityAvailableController.text.trim(),
        ),
        unitPrice: _parseDouble(_unitPriceController.text.trim()),
        marginRate: _parseDouble(_marginRateController.text.trim()),
        unitOfMeasure: _selectedUom,
        branch: _branch!,
        marginType: _selectedMarginType,
        company: widget.authBloc.state.companyId,
      );

      if (widget.item == null) {
        context.read<StockItemInBranchBloc>().add(AddItemToBranch(item));
      } else {
        context.read<StockItemInBranchBloc>().add(UpdateItem(item));
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
          widget.item == null
              ? 'Item added to branch successfully!'
              : 'Branch item updated successfully!',
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
        title: Text(
          widget.item == null ? 'Add Item to Branch' : 'Edit Item in Branch',
        ),
        backgroundColor: const Color(0xFF155888),
        elevation: 0,
      ),
      body: BlocListener<StockItemInBranchBloc, ItemInBranchState>(
        listener: (context, state) {
          if (state.status == ItemInBranchStatus.duplication) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message!),
                backgroundColor: Colors.red,
              ),
            );
            return;
          } else if (state.status == ItemInBranchStatus.success) {
            _showSuccessDialog();
          } else if (state.status == ItemInBranchStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message ?? 'An error occurred'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            child: Expanded(
              child: Column(children: [_buildForm(), _buildBottomNavigation()]),
            ),
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
            CustomTextField(
              labelText: 'Item Number *',
              controller: _itemNumberController,
              keyboardType: TextInputType.number,
              readOnly: widget.itemEntry != null,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Item Number is required';
                }
                return null;
              },
              onChanged: (value) {
                // If user edits the shown item number, clear any stored ItemEntry id
                // so we don't accidentally save the previous ItemEntry id.
                _itemEntryId = null;
              },
              prefixIcon: const Icon(Icons.numbers),
            ),
            const SizedBox(height: 16),
            // Branch
            BlocBuilder<BranchBloc, BranchState>(
              builder: (context, state) {
                if (state.status == BranchStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                // Safe employee list with null check
                final branch = state.branchs.toList();
                if (branch.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'No valid branch found',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                // Use CustomSearchableDropdown which works with String options.
                // We map branch descriptions to ids when selection changes.
                return Builder(
                  builder: (context) {
                    String? currentBranchDesc;
                    if (_branch != null) {
                      final match = branch.where((b) => b.id == _branch);
                      if (match.isNotEmpty) {
                        currentBranchDesc = match.first.description;
                      }
                    }

                    return CustomSearchableDropdown(
                      labelText: 'Branch *',
                      options: branch.map((b) => b.description ?? '').toList(),
                      value: currentBranchDesc,
                      prefixIcon: Iconsax.profile_circle,
                      allowCustomEntries: false,
                      onChanged: (value) {
                        setState(() {
                          if (value == null) {
                            _branch = null;
                          } else {
                            final matches = branch.where(
                              (b) => b.description == value,
                            );
                            _branch = matches.isNotEmpty
                                ? matches.first.id
                                : null;
                          }
                        });
                      },
                      validator: (value) {
                        if (_branch == null) {
                          return 'Please select a branch';
                        }
                        return null;
                      },
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            // Unit of Measure
            BlocBuilder<ItemUomConversionBloc, ItemUomConversionState>(
              builder: (context, state) {
                if (state.status == ItemUomConversionStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'No unit of measure available',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }
                final udcList = state.availableUomsForItem;

                return Builder(
                  builder: (context) {
                    String? currentUomDesc;
                    if (_selectedUom != null) {
                      final match = udcList.where((u) => u.id == _selectedUom);
                      if (match.isNotEmpty) {
                        currentUomDesc = match.first.description1;
                      }
                    }

                    return CustomSearchableDropdown(
                      labelText: 'Unit of Measure *',
                      options: udcList
                          .map((u) => u.description1 ?? '')
                          .toList(),
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
            const SizedBox(height: 16),
            CustomTextField(
              labelText: 'Available Quantity',
              controller: _quantityAvailableController,
              readOnly: true,
              onChanged: (value) {
                _quantityAvailableController.text = value;
              },
              prefixIcon: const Icon(Icons.description),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              labelText: 'Unit Price',
              controller: _unitPriceController,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Unit Price is required';
                }
                return null;
              },
              onChanged: (value) {
                _unitPriceController.text = value;
              },
              prefixIcon: const Icon(Icons.attach_money),
            ),
            const SizedBox(height: 16),
            CustomDropdown(
              labelText: 'Margin Type',
              prefixIcon: const Icon(Iconsax.aave_aave),
              value: _selectedMarginType,
              items: _marginTypes.map((marginType) {
                return DropdownMenuItem<String>(
                  value: marginType,
                  child: Text(marginType),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedMarginType = value;
                });
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              labelText: 'Margin Rate',
              controller: _marginRateController,
              keyboardType: TextInputType.number,
              onChanged: (value) {
                _marginRateController.text = value;
              },
              prefixIcon: _selectedMarginType == 'Percentage'
                  ? const Icon(Icons.percent)
                  : const Icon(Icons.attach_money),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(20),
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
            onPressed: () =>
                _saveItem(context.read<StockItemInBranchBloc>().state),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF155888),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              widget.item == null
                  ? 'Add Item to Branch'
                  : 'Update Item in Branch',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
