import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:savvy_stock/core/widgets/custom_dropdown.dart';
import 'package:savvy_stock/core/widgets/custom_text_form.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/stock/item_UoM_conversions/blocs/item_UoM_conversions_bloc.dart';
import 'package:savvy_stock/features/stock/item_UoM_conversions/blocs/item_UoM_conversions_event.dart';
import 'package:savvy_stock/features/stock/item_UoM_conversions/blocs/item_UoM_conversions_state.dart';
import 'package:savvy_stock/features/stock/item_UoM_conversions/models/item_UoM_conversions_model.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_bloc.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_event.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_state.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_bloc.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_event.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_state.dart';

class ItemUomConversionForm extends StatefulWidget {
  final AuthBloc authBloc;
  final ItemUomConversion? editingItem;

  const ItemUomConversionForm({
    super.key,
    required this.authBloc,
    this.editingItem,
  });

  @override
  State<ItemUomConversionForm> createState() => _ItemUomConversionFormState();
}

class _ItemUomConversionFormState extends State<ItemUomConversionForm> {
  final _formKey = GlobalKey<FormState>();
  late ItemUomConversionBloc _uomConversionBloc;

  // For single conversion form (not multiple rows)
  final TextEditingController _conversionFactorController =
      TextEditingController();
  final TextEditingController _structureLevelController =
      TextEditingController();
  int? _selectedItem;
  int? _fromUom;
  int? _toUom;

  @override
  void initState() {
    super.initState();
    _uomConversionBloc = context.read<ItemUomConversionBloc>();
    context.read<StockItemsEntryBloc>().add(
      LoadItems(widget.authBloc.state.companyId!),
    );
    context.read<UdcDetailsBloc>().add(LoadUdcDetailsByGroup('UM'));

    // Initialize form based on whether we're editing or creating
    if (widget.editingItem != null) {
      _initializeFormWithData(widget.editingItem!);
    } else {
      // For creating, prepare create state
      _uomConversionBloc.add(
        PrepareCreateUomConversion(widget.authBloc.state.companyId!),
      );
    }
  }

  void _initializeFormWithData(ItemUomConversion item) {
    setState(() {
      _selectedItem = item.itemNumber;
      _fromUom = item.fromUom;
      _toUom = item.toUom;
      _conversionFactorController.text =
          item.conversionFactor?.toString() ?? '';
      _structureLevelController.text = item.uomStructureLevel?.toString() ?? '';
    });
  }

  void _saveConversion() {
    if (_formKey.currentState!.validate()) {
      if (_selectedItem == null || _fromUom == null || _toUom == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select item, from UoM, and to UoM'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final conversion = ItemUomConversion(
        id: widget.editingItem?.id,
        itemNumber: _selectedItem,
        fromUom: _fromUom,
        toUom: _toUom,
        conversionFactor: double.tryParse(_conversionFactorController.text),
        uomStructureLevel: int.tryParse(_structureLevelController.text),
        company: widget.authBloc.state.companyId,
      );

      if (widget.editingItem == null) {
        // Create new conversion
        _uomConversionBloc.add(
          SaveItemUomConversion(conversion, widget.authBloc.state.userId!),
        );
      } else {
        // Update existing conversion
        _uomConversionBloc.add(
          UpdateItemUomConversion(conversion, widget.authBloc.state.userId),
        );
      }
    }
  }

  void _cancel() {
    Navigator.of(context).pop();
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      _selectedItem = null;
      _fromUom = null;
      _toUom = null;
      _conversionFactorController.clear();
      _structureLevelController.clear();
    });
  }

  @override
  void dispose() {
    _conversionFactorController.dispose();
    _structureLevelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.editingItem != null
              ? 'Edit UoM Conversion'
              : 'Create UoM Conversion',
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _cancel,
        ),
      ),
      body: BlocConsumer<ItemUomConversionBloc, ItemUomConversionState>(
        listener: (context, state) {
          if (state.status == ItemUomConversionStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.message ?? 'Operation completed successfully',
                ),
                backgroundColor: Colors.green,
              ),
            );

            // Navigate back on success after a short delay
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (mounted) {
                Navigator.of(context).pop(true); // Return success
              }
            });
          } else if (state.status == ItemUomConversionStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message ?? 'An error occurred'),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state.status == ItemUomConversionStatus.duplication) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message ?? 'Duplicate record found'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        },
        builder: (context, state) {
          return _buildForm();
        },
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'UoM Conversion Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Item Selection
                    BlocBuilder<StockItemsEntryBloc, ItemEntryState>(
                      builder: (context, state) {
                        if (state.status == ItemEntryStatus.loading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (state.items.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'No items available ',
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        }

                        // Safe employee list with null check
                        final items = state.items.toList();
                        if (items.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'No valid items found',
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        }

                        return CustomDropdown(
                          labelText: 'Item Number *',
                          value: _selectedItem,
                          prefixIcon: const Icon(Iconsax.aave_aave),
                          items: state.items.map((item) {
                            return DropdownMenuItem<int>(
                              value: item.id,
                              child: Text('${item.itemDescription}'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedItem = value;
                            });
                          },
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

                    // From UoM
                    BlocBuilder<UdcDetailsBloc, UdcDetailsState>(
                      builder: (context, state) {
                        if (state.status == UdcDetailsStatus.loading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (state.groupCode == null || state.details.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'No UoM available ',
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        }

                        // Safe udc list with null check
                        final items = state.details.toList();
                        if (items.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'No valid UoM found',
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        }

                        return CustomDropdown(
                          labelText: 'From UoM *',
                          value: _fromUom,
                          prefixIcon: const Icon(Iconsax.aave_aave),
                          items: state.details.map((item) {
                            return DropdownMenuItem<int>(
                              value: item.id,
                              child: Text(item.description1),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _fromUom = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Please select an UoM';
                            }
                            return null;
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    // Conversion Factor
                    CustomTextField(
                      labelText: 'Conversion Factor *',
                      controller: _conversionFactorController,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Conversion Factor is required';
                        }
                        final factor = double.tryParse(value);
                        if (factor == null) {
                          return 'Must be a valid number';
                        }
                        if (factor <= 0) {
                          return 'Must be greater than 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // To UoM
                    BlocBuilder<UdcDetailsBloc, UdcDetailsState>(
                      builder: (context, state) {
                        if (state.status == UdcDetailsStatus.loading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (state.groupCode == null || state.details.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'No UoM available ',
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        }

                        // Safe employee list with null check
                        final items = state.details.toList();
                        if (items.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'No valid UoM found',
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        }

                        return CustomDropdown(
                          labelText: 'To UoM *',
                          value: _toUom,
                          prefixIcon: const Icon(Iconsax.aave_aave),
                          items: state.details.map((item) {
                            return DropdownMenuItem<int>(
                              value: item.id,
                              child: Text(item.description1),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _toUom = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Please select an UoM';
                            }
                            return null;
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // Structure Level
                    CustomTextField(
                      labelText: 'Structure Level *',
                      controller: _structureLevelController,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Structure Level is required';
                        }
                        final level = int.tryParse(value);
                        if (level == null) {
                          return 'Must be a valid integer';
                        }
                        if (level <= 0) {
                          return 'Must be greater than 0';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Action Buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return BlocBuilder<ItemUomConversionBloc, ItemUomConversionState>(
      builder: (context, state) {
        final isLoading =
            state.status == ItemUomConversionStatus.creating ||
            state.status == ItemUomConversionStatus.updating;

        return Row(
          children: [
            // Back Button
            Expanded(
              child: OutlinedButton(
                onPressed: isLoading ? null : _cancel,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 16),

            // Reset Button
            Expanded(
              child: OutlinedButton(
                onPressed: isLoading ? null : _resetForm,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Reset'),
              ),
            ),
            const SizedBox(width: 16),

            // Save Button
            Expanded(
              child: ElevatedButton(
                onPressed: isLoading ? null : _saveConversion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(widget.editingItem != null ? 'Update' : 'Create'),
              ),
            ),
          ],
        );
      },
    );
  }
}
