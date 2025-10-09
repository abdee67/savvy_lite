import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
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
  final TextEditingController _qunatityAvailableController =
      TextEditingController();
  final TextEditingController _unitPriceController = TextEditingController();
  final TextEditingController _marginRateController = TextEditingController();

  String? _selectedMarginType;
  int? _selectedUom;
  int? _branch;

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
    //for editing
    if (widget.item != null) {
      final item = widget.item ?? ItemInBranchModel.empty();
      _itemNumberController.text = item.itemNumber.toString();
      _qunatityAvailableController.text =
          item.quantityAvailable?.toString() ?? '';
      _unitPriceController.text = item.unitPrice?.toString() ?? '';
      _marginRateController.text = item.marginRate?.toString() ?? '';
      _marginRateController.text = item.marginRate?.toString() ?? '';
      _selectedMarginType = item.marginType;
      _selectedUom = item.unitOfMeasure;
      _branch = item.branch;
    }
    //for creating
    else if (widget.itemEntry != null) {
      final item = widget.itemEntry ?? ItemEntryModel.empty();

      _itemNumberController.text = item.itemsId.toString();
      _qunatityAvailableController.text = '0';
      _unitPriceController.text = item.unitPrice?.toString() ?? '';
      _marginRateController.text = item.marginRate?.toString() ?? '';
      _marginRateController.text = item.marginRate?.toString() ?? '';
    }
    //for empty(may be for creating new item)
    else {
      _itemNumberController.text = '';
      _qunatityAvailableController.text = '0';
      _unitPriceController.text = '';
      _marginRateController.text = '';
    }
  }

  // Add this method to properly reset the form
  void _resetForm() {
    // Clear all text controllers
    _qunatityAvailableController.clear();
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
    _qunatityAvailableController.dispose();
    _unitPriceController.dispose();
    _marginRateController.dispose();
    super.dispose();
  }

  void _saveItem(ItemInBranchState state) {
    if (_formKey.currentState!.validate()) {
      if (_selectedMarginType == null ||
          _selectedUom == null ||
          _branch == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Please select margin type, unit of measure, and branch',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      final item = ItemInBranchModel(
        id: widget.item?.id ?? 0,
        itemNumber: _parseInt(_itemNumberController.text.trim())!,
        quantityAvailable: _parseDouble(
          _qunatityAvailableController.text.trim(),
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
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
                _itemNumberController.text = value;
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
                if (state.branchs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'No branch available for item to add',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
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

                return CustomDropdown(
                  labelText: 'Branch *',
                  value: _branch,
                  prefixIcon: const Icon(Iconsax.profile_circle),
                  items: state.branchs.map((branch) {
                    return DropdownMenuItem<int>(
                      value: branch.id,
                      child: Text('${branch.description}'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _branch = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select an branch';
                    }
                    return null;
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            BlocBuilder<UdcDetailsBloc, UdcDetailsState>(
              builder: (context, state) {
                if (state.status == UdcDetailsStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.details.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'No udc available for item to add',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                // Safe employee list with null check
                final udc = state.details.toList();
                if (udc.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'No valid udc found',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return CustomDropdown(
                  labelText: 'Udc *',
                  value: _selectedUom,
                  prefixIcon: const Icon(Iconsax.profile_circle),
                  items: state.details.map((udc) {
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
                  validator: (value) {
                    if (value == null) {
                      return 'Please select an udc';
                    }
                    return null;
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              labelText: 'Available Quantity *',
              controller: _qunatityAvailableController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Available Quantity is required';
                }
                return null;
              },
              onChanged: (value) {
                _qunatityAvailableController.text = value;
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
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Margin Rate is required';
                }
                return null;
              },
              onChanged: (value) {
                _marginRateController.text = value;
              },
              prefixIcon: const Icon(Icons.attach_money),
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
            child: ElevatedButton(
              onPressed: () =>
                  _saveItem(context.read<StockItemInBranchBloc>().state),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                widget.item == null
                    ? 'Add Item to Branch'
                    : 'Update Item in Branch',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
