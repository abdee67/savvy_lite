import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:savvy_stock/core/widgets/custom_dropdown.dart';
import 'package:savvy_stock/core/widgets/custom_text_Form.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_bloc.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_event.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_state.dart';
import 'package:savvy_stock/features/stock/item_entry/models/item_entry_model.dart';

class ItemEntryFormPage extends StatefulWidget {
  final ItemEntryModel? item;
  final AuthBloc authBloc;

  const ItemEntryFormPage({super.key, this.item, required this.authBloc});

  @override
  State<ItemEntryFormPage> createState() => _ItemEntryFormPageState();
}

class _ItemEntryFormPageState extends State<ItemEntryFormPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _storeNumberController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _defaultUnitPriceController =
      TextEditingController();
  final TextEditingController _reorderPointController = TextEditingController();
  final TextEditingController _marginRateController = TextEditingController();

  String? _selectedMarginType;
  String? _selectedUom;
  String? _selectedTaxable;

  final List<String> _marginTypes = ['Flat', 'Percentage'];
  final List<String> _uom = ['pices', 'kg', 'g', 'ml', 'ltr'];
  final List<String> _taxable = ['YES', 'NO'];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    if (widget.item != null) {
      context.read<StockItemEntryBloc>().add(SetItemForm(widget.item!));
    }
  }

  void _initializeControllers() {
    final item = widget.item ?? ItemEntryModel.empty();

    _storeNumberController.text = item.itemsId ?? '';
    _descriptionController.text = item.itemDescription ?? '';
    _barcodeController.text = item.barcode ?? '';

    _defaultUnitPriceController.text = item.unitPrice?.toString() ?? '';
    _reorderPointController.text = item.reorderPoint?.toString() ?? '';
    _marginRateController.text = item.marginRate?.toString() ?? '';

    _selectedMarginType = item.marginType;
    _selectedUom = item.unitOfMeasure.toString();
    _selectedTaxable = item.taxable == 'Y'
        ? 'YES'
        : item.taxable == 'N'
        ? 'NO'
        : null;
  }

  // Add this helper method for safe number parsing
  double? _parseDouble(String value) {
    if (value.trim().isEmpty) return null;
    return double.tryParse(value.trim());
  }

  @override
  void dispose() {
    _storeNumberController.dispose();
    _descriptionController.dispose();
    _barcodeController.dispose();
    _defaultUnitPriceController.dispose();
    _reorderPointController.dispose();
    _marginRateController.dispose();
    _selectedMarginType = null;
    _selectedUom = null;
    _selectedTaxable = null;
    super.dispose();
  }

  void _saveItem() {
    if (_formKey.currentState!.validate()) {
      final item = ItemEntryModel(
        id: widget.item?.id ?? 0,
        itemsId: _storeNumberController.text.trim(),
        itemDescription: _descriptionController.text.trim(),
        barcode: _barcodeController.text.trim().isEmpty
            ? null
            : _barcodeController.text.trim(),
        unitPrice: _defaultUnitPriceController.text.trim().isEmpty
            ? null
            : _parseDouble(_defaultUnitPriceController.text),
        reorderPoint: _reorderPointController.text.trim().isEmpty
            ? null
            : _parseDouble(_reorderPointController.text),
        marginRate: _marginRateController.text.trim().isEmpty
            ? null
            : _parseDouble(_marginRateController.text),
        unitOfMeasure: _selectedUom,
        taxable: _selectedTaxable == 'YES' ? 'Y' : 'N',
        marginType: _selectedMarginType,
        company: widget.authBloc.state.companyId,
      );

      if (widget.item == null) {
        context.read<StockItemEntryBloc>().add(CreateItem(item));
      } else {
        context.read<StockItemEntryBloc>().add(UpdateItem(item));
      }

      _showSuccessDialog();
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
              ? 'Item created successfully!'
              : 'Item updated successfully!',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null ? 'Create Item' : 'Edit Item'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
      ),
      body: BlocListener<StockItemEntryBloc, ItemEntryState>(
        listener: (context, state) {
          if (state.status == ItemEntryStatus.failure) {
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
              labelText: 'Store Number *',
              controller: _storeNumberController,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Store Number is required';
                }
                return null;
              },
              onChanged: (value) {
                _storeNumberController.text = value;
              },
              prefixIcon: const Icon(Icons.store),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              labelText: 'Description *',
              controller: _descriptionController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Description is required';
                }
                return null;
              },
              onChanged: (value) {
                _descriptionController.text = value;
              },
              prefixIcon: const Icon(Icons.description),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              labelText: 'Barcode',
              controller: _barcodeController,
              onChanged: (value) {
                _barcodeController.text = value;
              },
              prefixIcon: const Icon(Icons.qr_code),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              labelText: 'Default Unit Price',
              controller: _defaultUnitPriceController,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Default Unit Price is required';
                }
                return null;
              },
              onChanged: (value) {
                _defaultUnitPriceController.text = value;
              },
              prefixIcon: const Icon(Icons.attach_money),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              labelText: 'Reorder Point',
              controller: _reorderPointController,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Reorder Point is required';
                }
                return null;
              },
              onChanged: (value) {
                _reorderPointController.text = value;
              },
              prefixIcon: const Icon(Icons.inventory_2),
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
              prefixIcon: const Icon(Icons.trending_up),
            ),
            const SizedBox(height: 16),
            CustomDropdown(
              labelText: 'Margin Type',
              items: _marginTypes,
              value: _selectedMarginType,
              onChanged: (value) {
                setState(() {
                  _selectedMarginType = value;
                });
              },
            ),
            const SizedBox(height: 16),
            CustomDropdown(
              labelText: 'Unit of Measure',
              items: _uom,
              value: _selectedUom,
              onChanged: (value) {
                setState(() {
                  _selectedUom = value;
                });
              },
            ),
            const SizedBox(height: 16),
            CustomDropdown(
              labelText: 'Taxable',
              items: _taxable,
              value: _selectedTaxable,
              onChanged: (value) {
                setState(() {
                  _selectedTaxable = value;
                });
              },
            ),
            const SizedBox(height: 16),
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
              onPressed: _saveItem,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
