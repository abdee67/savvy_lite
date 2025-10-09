import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:savvy_stock/core/blocs/system_constant/system_constant_bloc.dart';
import 'package:savvy_stock/core/blocs/system_constant/system_constant_event.dart';
import 'package:savvy_stock/core/blocs/system_constant/system_constant_state.dart';
import 'package:savvy_stock/core/widgets/custom_dropdown.dart';
import 'package:savvy_stock/core/widgets/custom_text_Form.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_bloc.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_event.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_state.dart';
import 'package:savvy_stock/features/stock/item_entry/models/item_entry_model.dart';
import 'package:savvy_stock/features/stock/item_entry/widgets/stock_qr_scanner.dart';

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
  final TextEditingController _itemNumberController = TextEditingController();
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
  final List<String> _uom = ['pices', 'kg', 'gggg', 'ml', 'ltr'];
  final List<String> _taxable = ['YES', 'NO'];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    context.read<SystemConstantBloc>().add(
      LoadSystemConstantsForCompany(widget.authBloc.state.companyId!),
    );
    if (widget.item != null) {
      context.read<StockItemEntryBloc>().add(SetItemForm(widget.item!));
    }
  }

  void _initializeControllers() {
    final item = widget.item ?? ItemEntryModel.empty();

    _itemNumberController.text = item.itemsId ?? '';
    _descriptionController.text = item.itemDescription ?? '';
    _barcodeController.text = item.barcode ?? '';

    _defaultUnitPriceController.text = item.unitPrice?.toString() ?? '';
    _reorderPointController.text = item.reorderPoint?.toString() ?? '';
    _marginRateController.text = item.marginRate?.toString() ?? '';

    _selectedMarginType = item.marginType;
    _selectedUom = item.unitOfMeasure;
    _selectedTaxable = item.taxable == 'Y'
        ? 'YES'
        : item.taxable == 'N'
        ? 'NO'
        : null;
  }

  // Handle barcode scanning
  void _scanBarcode() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StockItemQRScanner(
          barcodeController: _barcodeController,
          onBarcodeScanned: (barcode) {
            setState(() {
              _barcodeController.text = barcode;
            });
          },
        ),
      ),
    );
  }

  // Add this helper method for safe number parsing
  double? _parseDouble(String value) {
    if (value.trim().isEmpty) return null;
    return double.tryParse(value.trim());
  }

  // Enhanced barcode generation
  String _generateBarcode() {
    final companyId = widget.authBloc.state.companyId ?? 0;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecondsSinceEpoch % 10000;

    // Format: COMPANY_TIMESTAMP_RANDOM
    return 'C${companyId}_T${timestamp}_R$random';
  }

  @override
  void dispose() {
    _itemNumberController.dispose();
    _descriptionController.dispose();
    _barcodeController.dispose();
    _defaultUnitPriceController.dispose();
    _reorderPointController.dispose();
    _marginRateController.dispose();
    super.dispose();
  }

  void _saveItem() {
    if (_formKey.currentState!.validate()) {
      final systemConstantState = context.read<SystemConstantBloc>().state;
      final systemConstant = systemConstantState.systemConstant;
      String? finalBarcode = _barcodeController.text.trim();
      //if it is auto is on
      if (systemConstant?.shouldAutoGenerateBarcodeForItem == true) {
        if (finalBarcode.isEmpty) {
          finalBarcode = _generateBarcode();
        }
      } else {
        //if filed is empty
        if (finalBarcode.isEmpty) {
          finalBarcode = null;
        }
        //filed has  user input there
      }
      final item = ItemEntryModel(
        id: widget.item?.id ?? 0,
        itemsId: _itemNumberController.text.trim(),
        itemDescription: _descriptionController.text.trim(),
        barcode: finalBarcode,
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
      body: MultiBlocListener(
        listeners: [
          BlocListener<StockItemEntryBloc, ItemEntryState>(
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
          ),
          BlocListener<SystemConstantBloc, SystemConstantState>(
            listener: (context, state) {
              if (state.status == SystemConstantStatus.failure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.errorMessage ?? 'An error occurred'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ],
        child: Column(
          children: [
            _buildBarcodeInfo(),
            Expanded(child: _buildForm()),
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  // Barcode information widget
  Widget _buildBarcodeInfo() {
    return BlocBuilder<SystemConstantBloc, SystemConstantState>(
      builder: (context, state) {
        final isAutoGenerateEnabled =
            state.systemConstant?.shouldAutoGenerateBarcodeForItem == true;

        if (isAutoGenerateEnabled) {
          return Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.blue[600], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Auto-barcode generation is ENABLED',
                        style: TextStyle(
                          color: Colors.blue[800],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Empty field will auto-generate barcode',
                        style: TextStyle(color: Colors.blue[700], fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        } else {
          return Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.orange[600], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Auto-barcode generation is DISABLED',
                        style: TextStyle(
                          color: Colors.orange[800],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Empty field will be saved as empty',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  // In your ItemEntryFormPage
  Widget _buildBarcodeField() {
    return BlocBuilder<SystemConstantBloc, SystemConstantState>(
      builder: (context, state) {
        final isAutoGenerateEnabled =
            state.systemConstant?.shouldAutoGenerateBarcodeForItem == true;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StockItemQRScanner(
              barcodeController: _barcodeController,
              onBarcodeScanned: (barcode) {
                // Handle the scanned barcode
                setState(() {});
              },
            ),
            const SizedBox(height: 8),
            if (isAutoGenerateEnabled && _barcodeController.text.isEmpty)
              Text(
                '• Leave empty for auto-generation',
                style: TextStyle(fontSize: 12, color: Colors.green[700]),
              ),
          ],
        );
      },
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
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Item Number is required';
                }
                return null;
              },
              onChanged: (value) {
                _itemNumberController.text = value;
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
            _buildBarcodeField(),
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
              items: _marginTypes
                  .map(
                    (marginType) => DropdownMenuItem(
                      value: marginType,
                      child: Text(marginType),
                    ),
                  )
                  .toList(),
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
              items: _uom
                  .map((uom) => DropdownMenuItem(value: uom, child: Text(uom)))
                  .toList(),
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
              items: _taxable
                  .map(
                    (taxable) =>
                        DropdownMenuItem(value: taxable, child: Text(taxable)),
                  )
                  .toList(),
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
