import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:savvy_stock/core/widgets/custom_searchable_dropdown.dart';
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
  StreamSubscription? _stateSubscription;

  // Controllers
  final TextEditingController _conversionFactorController =
      TextEditingController();
  final TextEditingController _structureLevelController =
      TextEditingController();

  // Form values
  int? _selectedItem;
  int? _fromUom;
  int? _toUom;

  // Track previous values for "Save and Add New"
  int? _previousSelectedItem;
  int? _previousToUom;
  int? _previousStructureLevel;

  // State management
  bool _isProcessing = false;
  bool _shouldCloseAfterSave = true;
  bool _hasValidationError = false;
  String? _currentErrorMessage;

  // Real-time validation
  Timer? _validationTimer;

  @override
  void initState() {
    super.initState();
    _uomConversionBloc = context.read<ItemUomConversionBloc>();

    // Load necessary data
    _loadInitialData();

    // Initialize based on editing or creating
    if (widget.editingItem != null) {
      _initializeFormWithData(widget.editingItem!);
    }

    // Listen to state changes
    _stateSubscription = _uomConversionBloc.stream.listen(_handleStateChange);
  }

  void _loadInitialData() {
    context.read<StockItemsEntryBloc>().add(
      LoadItems(widget.authBloc.state.companyId!),
    );
    context.read<UdcDetailsBloc>().add(LoadUdcDetailsByGroup('UM'));
  }

  void _initializeFormWithData(ItemUomConversion item) {
    setState(() {
      _selectedItem = item.itemNumber;
      _fromUom = item.fromUom;
      _toUom = item.toUom;
      _conversionFactorController.text =
          item.conversionFactor?.toString() ?? '';
      _structureLevelController.text = item.uomStructureLevel?.toString() ?? '';

      _previousSelectedItem = item.itemNumber;
      _previousToUom = item.toUom;
      _previousStructureLevel = item.uomStructureLevel;
    });
  }

  void _handleStateChange(ItemUomConversionState state) {
    // Handle processing states
    if (state.isCreating || state.isUpdating) {
      setState(() {
        _isProcessing = true;
        _hasValidationError = false;
        _currentErrorMessage = null;
      });
    } else {
      setState(() {
        _isProcessing = false;
      });
    }

    // Handle success state
    if (state.isSuccess) {
      _handleSuccess(state);
    }

    // Handle error states
    if (state.isFailure) {
      _handleError(state.message ?? 'An error occurred during the operation');
    }

    if (state.isDuplicated) {
      _handleError(state.message ?? 'This UoM conversion already exists');
    }

    if (state.status == ItemUomConversionStatus.structureInvalid) {
      _handleError(state.message ?? 'Invalid structure level configuration');
    }
  }

  void _handleSuccess(ItemUomConversionState state) {
    _showSuccessSnackBar(state.message ?? 'Operation completed successfully');

    if (_shouldCloseAfterSave) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      });
    } else {
      _prepareNextEntry();
      // Reset the bloc status to allow future saves
      _uomConversionBloc.add(ResetUomConversionStatus());
    }
  }

  void _handleError(String message) {
    setState(() {
      _hasValidationError = true;
      _currentErrorMessage = message;
    });
    _showErrorSnackBar(message);
  }

  void _performRealTimeValidation() {
    // Debounce validation to avoid excessive checks
    _validationTimer?.cancel();
    _validationTimer = Timer(const Duration(milliseconds: 500), () {
      if (_formKey.currentState?.validate() ?? false) {
        _validateBusinessRules();
      }
    });
  }

  void _validateBusinessRules() {
    // Check for same From and To UoM
    if (_fromUom != null && _toUom != null && _fromUom == _toUom) {
      setState(() {
        _hasValidationError = true;
        _currentErrorMessage = 'From UoM and To UoM cannot be the same';
      });
      return;
    }

    // Check structure level progression
    if (_selectedItem == _previousSelectedItem &&
        _previousStructureLevel != null &&
        _structureLevelController.text.isNotEmpty) {
      final currentLevel = int.tryParse(_structureLevelController.text);
      if (currentLevel != null &&
          currentLevel != _previousStructureLevel! + 1) {
        setState(() {
          _hasValidationError = true;
          _currentErrorMessage =
              'Structure level should be ${_previousStructureLevel! + 1} for consecutive conversion';
        });
        return;
      }
    }

    setState(() {
      _hasValidationError = false;
      _currentErrorMessage = null;
    });
  }

  void _saveConversion({bool closeAfterSave = true}) {
    if (_isProcessing || _hasValidationError) return;

    if (_formKey.currentState!.validate()) {
      if (_selectedItem == null || _fromUom == null || _toUom == null) {
        _showErrorSnackBar('Please select item, from UoM, and to UoM');
        return;
      }

      // Final business rule validation
      if (_fromUom == _toUom) {
        _showErrorSnackBar('From UoM and To UoM cannot be the same');
        return;
      }

      setState(() {
        _isProcessing = true;
        _shouldCloseAfterSave = closeAfterSave;
      });

      final conversion = ItemUomConversion(
        id: widget.editingItem?.id,
        itemNumber: _selectedItem,
        fromUom: _fromUom,
        toUom: _toUom,
        conversionFactor: double.tryParse(_conversionFactorController.text),
        uomStructureLevel: int.tryParse(_structureLevelController.text),
        company: widget.authBloc.state.companyId,
        validCell: true,
      );

      if (widget.editingItem == null) {
        _uomConversionBloc.add(
          SaveItemUomConversion(conversion, widget.authBloc.state.userId!),
        );
      } else {
        _uomConversionBloc.add(
          UpdateItemUomConversion(conversion, widget.authBloc.state.userId),
        );
      }

      // Store current values for "Save and Add New" before they change
      if (!closeAfterSave) {
        setState(() {
          _previousSelectedItem = _selectedItem;
          _previousToUom = _toUom;
          _previousStructureLevel = int.tryParse(
            _structureLevelController.text,
          );
        });
      }
    }
  }

  void _saveAndClose() {
    _saveConversion(closeAfterSave: true);
  }

  void _saveAndAddNew() {
    _saveConversion(closeAfterSave: false);
  }

  void _prepareNextEntry() {
    setState(() {
      // Keep the same item if it hasn't changed, otherwise clear everything
      if (_selectedItem == _previousSelectedItem) {
        // Set fromUOM to the previous toUOM value
        _fromUom = _previousToUom;
        // Increment structure level by 1
        final nextLevel = (_previousStructureLevel ?? 0) + 1;
        _structureLevelController.text = nextLevel.toString();

        // Clear other fields for new entry
        _toUom = null;
        _conversionFactorController.clear();
      } else {
        // If item changed, clear all fields
        _fromUom = null;
        _toUom = null;
        _conversionFactorController.clear();
        _structureLevelController.clear();
      }

      // Clear validation state
      _hasValidationError = false;
      _currentErrorMessage = null;
    });
  }

  void _cancel() {
    if (_isProcessing) {
      _showInfoSnackBar('Please wait for the current operation to complete');
      return;
    }
    Navigator.of(context).pop();
  }

  void _resetForm() {
    if (_isProcessing) {
      _showInfoSnackBar('Cannot reset form while processing');
      return;
    }

    _formKey.currentState?.reset();
    setState(() {
      _selectedItem = null;
      _fromUom = null;
      _toUom = null;
      _conversionFactorController.clear();
      _structureLevelController.clear();
      _previousSelectedItem = null;
      _previousToUom = null;
      _previousStructureLevel = null;
      _hasValidationError = false;
      _currentErrorMessage = null;
    });

    // Clear the create list in bloc if needed
    if (widget.editingItem == null) {
      _uomConversionBloc.add(ClearCreateList());
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _validationTimer?.cancel();
    _stateSubscription?.cancel();
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
        backgroundColor: const Color(0xFF155888),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isProcessing ? null : _cancel,
          tooltip: 'Cancel',
        ),
        actions: [
          ElevatedButton(
            onPressed: _isProcessing ? null : _resetForm,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: Colors.white),
            ),
            child: Text(
              'Reset',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: _buildFormContent(),
    );
  }

  Widget _buildFormContent() {
    return Column(
      children: [
        // Validation Error Banner
        if (_hasValidationError && _currentErrorMessage != null)
          _buildErrorBanner(),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFormCard(),
                  const SizedBox(height: 20),
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.red.shade50,
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: Colors.red, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _currentErrorMessage!,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: Colors.red),
            onPressed: () {
              setState(() {
                _hasValidationError = false;
                _currentErrorMessage = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFormHeader(),
            const SizedBox(height: 24),
            _buildItemDropdown(),
            const SizedBox(height: 16),
            _buildFromUomDropdown(),
            const SizedBox(height: 16),
            _buildConversionFactorField(),
            const SizedBox(height: 16),
            _buildToUomDropdown(),
            const SizedBox(height: 16),
            _buildStructureLevelField(),
          ],
        ),
      ),
    );
  }

  Widget _buildFormHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'UoM Conversion Details',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF155888),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.editingItem != null
              ? 'Update the unit of measurement conversion'
              : 'Create a new unit of measurement conversion',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildItemDropdown() {
    return BlocBuilder<StockItemsEntryBloc, ItemEntryState>(
      builder: (context, state) {
        return _buildDropdownWithState(
          label: 'Item *',
          value: _selectedItem,
          loading: state.status == ItemEntryStatus.loading,
          error: state.status == ItemEntryStatus.failure,
          empty: state.items.isEmpty,
          items: state.items,
          getDisplayText: (item) => item.itemDescription ?? 'Unknown Item',
          getId: (item) => item.id,
          onChanged: _handleItemChanged,
          emptyMessage: 'No items available',
          errorMessage: 'Failed to load items',
          icon: Iconsax.box,
        );
      },
    );
  }

  Widget _buildFromUomDropdown() {
    return BlocBuilder<UdcDetailsBloc, UdcDetailsState>(
      builder: (context, state) {
        return _buildDropdownWithState(
          label: 'From UoM *',
          value: _fromUom,
          loading: state.status == UdcDetailsStatus.loading,
          error: state.status == UdcDetailsStatus.failure,
          empty: state.details.isEmpty,
          items: state.details,
          getDisplayText: (udc) => udc.description1 ?? 'Unknown UoM',
          getId: (udc) => udc.id,
          onChanged: _handleFromUomChanged,
          emptyMessage: 'No UoM units available',
          errorMessage: 'Failed to load UoM units',
          icon: Iconsax.convert_3d_cube,
        );
      },
    );
  }

  Widget _buildToUomDropdown() {
    return BlocBuilder<UdcDetailsBloc, UdcDetailsState>(
      builder: (context, state) {
        return _buildDropdownWithState(
          label: 'To UoM *',
          value: _toUom,
          loading: state.status == UdcDetailsStatus.loading,
          error: state.status == UdcDetailsStatus.failure,
          empty: state.details.isEmpty,
          items: state.details,
          getDisplayText: (udc) => udc.description1 ?? 'Unknown UoM',
          getId: (udc) => udc.id,
          onChanged: _handleToUomChanged,
          emptyMessage: 'No UoM units available',
          errorMessage: 'Failed to load UoM units',
          icon: Iconsax.convert_3d_cube,
        );
      },
    );
  }

  Widget _buildDropdownWithState<T>({
    required String label,
    required int? value,
    required bool loading,
    required bool error,
    required bool empty,
    required List<T> items,
    required String Function(T) getDisplayText,
    required int Function(T) getId,
    required Function(int?) onChanged,
    required String emptyMessage,
    required String errorMessage,
    required IconData icon,
  }) {
    if (loading) {
      return _buildLoadingDropdown(label: label, icon: icon);
    }

    if (error) {
      return _buildErrorDropdown(
        label: label,
        message: errorMessage,
        icon: icon,
      );
    }

    if (empty) {
      return _buildEmptyDropdown(
        label: label,
        message: emptyMessage,
        icon: icon,
      );
    }

    return _buildSearchableDropdown(
      label: label,
      value: value,
      items: items,
      getDisplayText: getDisplayText,
      getId: getId,
      onChanged: onChanged,
      icon: icon,
    );
  }

  Widget _buildLoadingDropdown({
    required String label,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDropdownLabel(label),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.grey.shade500),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Loading...', style: TextStyle(color: Colors.grey)),
              ),
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorDropdown({
    required String label,
    required String message,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDropdownLabel(label),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.red.shade300),
            borderRadius: BorderRadius.circular(8),
            color: Colors.red.shade50,
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.red.shade500),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
              Icon(Icons.error_outline, color: Colors.red.shade500),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyDropdown({
    required String label,
    required String message,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDropdownLabel(label),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.grey.shade500),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              const Icon(Icons.info_outline, color: Colors.grey),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchableDropdown<T>({
    required String label,
    required int? value,
    required List<T> items,
    required String Function(T) getDisplayText,
    required int Function(T) getId,
    required Function(int?) onChanged,
    required IconData icon,
  }) {
    String? currentDisplayValue;
    if (value != null) {
      final item = items.firstWhere(
        (item) => getId(item) == value,
        orElse: () => items.isNotEmpty ? items.first : null as T,
      );
      currentDisplayValue = getDisplayText(item);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDropdownLabel(label),
        const SizedBox(height: 8),
        CustomSearchableDropdown(
          labelText: 'Select $label',
          options: items.map(getDisplayText).toList(),
          value: currentDisplayValue,
          prefixIcon: (icon),
          allowCustomEntries: false,
          onChanged: _isProcessing
              ? null
              : (newValue) {
                  if (newValue == null) {
                    onChanged(null);
                  } else {
                    final selectedItem = items.firstWhere(
                      (item) => getDisplayText(item) == newValue,
                    );
                    onChanged(getId(selectedItem));
                  }
                  _performRealTimeValidation();
                },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a $label';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDropdownLabel(String label) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(width: 4),
        const Text(
          '*',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildConversionFactorField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Conversion Factor'),
        CustomTextField(
          labelText: 'Enter conversion factor',
          controller: _conversionFactorController,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          readOnly: _isProcessing,
          onChanged: (value) => _performRealTimeValidation(),
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
          prefixIcon: const Icon(Iconsax.convert_card),
        ),
      ],
    );
  }

  Widget _buildStructureLevelField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Structure Level'),
        CustomTextField(
          labelText: 'Enter structure level',
          controller: _structureLevelController,
          keyboardType: TextInputType.number,
          readOnly: _isProcessing,
          onChanged: (value) => _performRealTimeValidation(),
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
          prefixIcon: const Icon(Iconsax.layer),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            '*',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _handleItemChanged(int? newItemId) {
    setState(() {
      final previousItem = _selectedItem;
      _selectedItem = newItemId;

      // If item changed from previous, clear dependent fields
      if (newItemId != previousItem) {
        _fromUom = null;
        _toUom = null;
        _conversionFactorController.clear();
        _structureLevelController.clear();
        _hasValidationError = false;
        _currentErrorMessage = null;
      }
    });
    _performRealTimeValidation();
  }

  void _handleFromUomChanged(int? newFromUom) {
    setState(() {
      _fromUom = newFromUom;
    });
    _performRealTimeValidation();
  }

  void _handleToUomChanged(int? newToUom) {
    setState(() {
      _toUom = newToUom;
    });
    _performRealTimeValidation();
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Save and Add New Button (only for create mode)
        if (widget.editingItem == null) ...[
          Expanded(
            child: ElevatedButton(
              onPressed: _isProcessing || _hasValidationError
                  ? null
                  : _saveAndAddNew,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 2,
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Save & Add New',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
            ),
          ),
          const SizedBox(width: 16),
        ],

        // Save and Close Button
        Expanded(
          child: ElevatedButton(
            onPressed: _isProcessing || _hasValidationError
                ? null
                : _saveAndClose,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF155888),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 2,
            ),
            child: _isProcessing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    widget.editingItem != null ? 'Update' : 'Save & Close',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }
}
