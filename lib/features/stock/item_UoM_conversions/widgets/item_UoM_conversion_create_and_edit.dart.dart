import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:savvy_stock/core/widgets/custom_searchable_dropdown.dart';
import 'package:savvy_stock/core/widgets/custom_text_form.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/stock/item_entry/models/item_entry_model.dart';
import 'package:savvy_stock/features/stock/item_uom_conversions/blocs/item_uom_conversions_bloc.dart';
import 'package:savvy_stock/features/stock/item_uom_conversions/blocs/item_uom_conversions_event.dart';
import 'package:savvy_stock/features/stock/item_uom_conversions/blocs/item_uom_conversions_state.dart';
import 'package:savvy_stock/features/stock/item_uom_conversions/models/item_uom_conversions_model.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_bloc.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_event.dart'
    hide PrepareCreate;
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_state.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_bloc.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_event.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_state.dart';
import 'package:savvy_stock/features/udc_detail/models/udc_details.dart';

class ItemUomConversionForm extends StatefulWidget {
  final AuthBloc authBloc;
  final ItemUomConversion? editingItem;
  final bool isBatchMode;

  const ItemUomConversionForm({
    super.key,
    required this.authBloc,
    this.editingItem,
    this.isBatchMode = false,
  });

  @override
  State<ItemUomConversionForm> createState() => _ItemUomConversionFormState();
}

class _ItemUomConversionFormState extends State<ItemUomConversionForm> {
  final _formKey = GlobalKey<FormState>();
  late ItemUomConversionBloc _uomConversionBloc;
  StreamSubscription? _stateSubscription;
  StreamSubscription? _itemsSubscription;
  StreamSubscription? _uomSubscription;

  // Controllers
  final TextEditingController _conversionFactorController =
      TextEditingController();
  final TextEditingController _structureLevelController =
      TextEditingController();

  // Form values
  int? _selectedItem;
  int? _fromUom;
  int? _toUom;
  String? _selectedItemDescription;
  String? _fromUomDescription;
  String? _toUomDescription;

  // State management
  bool _isProcessing = false;
  bool _shouldCloseAfterSave = true;
  bool _hasValidationError = false;
  String? _currentErrorMessage;
  ItemUomConversionStatus? _currentStatus;

  // Real-time validation
  Timer? _validationTimer;
  Timer? _duplicationCheckTimer;

  // Data states
  List<ItemEntryModel> _availableItems = [];
  List<UdcDetails> _availableUoms = [];
  bool _isLoadingItems = true;
  bool _isLoadingUoms = true;
  String? _itemsError;
  String? _uomsError;

  // Batch mode state
  List<ItemUomConversion> _batchItems = [];
  int _currentBatchIndex = 0;

  @override
  void initState() {
    super.initState();
    _uomConversionBloc = context.read<ItemUomConversionBloc>();

    // Load necessary data
    _loadInitialData();

    // Initialize based on editing or creating
    if (widget.editingItem != null) {
      _initializeFormWithData(widget.editingItem!);
    } else if (widget.isBatchMode) {
      _initializeBatchMode();
    }

    // Listen to state changes
    _stateSubscription = _uomConversionBloc.stream.listen(_handleStateChange);

    // Listen to items data
    _itemsSubscription = context.read<StockItemsEntryBloc>().stream.listen(
      _handleItemsStateChange,
    );

    // Listen to UoM data
    _uomSubscription = context.read<UdcDetailsBloc>().stream.listen(
      _handleUomsStateChange,
    );
  }

  void _loadInitialData() {
    // Load items with proper error handling
    try {
      context.read<StockItemsEntryBloc>().add(
        LoadItems(widget.authBloc.state.companyId!),
      );
    } catch (e) {
      setState(() {
        _itemsError = 'Failed to load items: $e';
        _isLoadingItems = false;
      });
    }

    // Load UoM units with proper error handling
    try {
      context.read<UdcDetailsBloc>().add(LoadUdcDetailsByGroup('UM'));
    } catch (e) {
      setState(() {
        _uomsError = 'Failed to load UoM units: $e';
        _isLoadingUoms = false;
      });
    }
  }

  void _handleItemsStateChange(ItemEntryState state) {
    if (mounted) {
      setState(() {
        _isLoadingItems = state.status == ItemEntryStatus.loading;
        if (state.status == ItemEntryStatus.loaded) {
          _availableItems = state.items;
          _itemsError = null;
        } else if (state.status == ItemEntryStatus.failure) {
          _itemsError = state.message ?? 'Failed to load items';
        }
      });
    }
  }

  void _handleUomsStateChange(UdcDetailsState state) {
    if (mounted) {
      setState(() {
        _isLoadingUoms = state.status == UdcDetailsStatus.loading;
        if (state.status == UdcDetailsStatus.success) {
          _availableUoms = state.details;
          _uomsError = null;
        } else if (state.status == UdcDetailsStatus.failure) {
          _uomsError = state.message ?? 'Failed to load UoM units';
        }
      });
    }
  }

  void _initializeFormWithData(ItemUomConversion item) {
    setState(() {
      _selectedItem = item.itemNumber;
      _fromUom = item.fromUom;
      _toUom = item.toUom;
      _conversionFactorController.text =
          item.conversionFactor?.toString() ?? '1.0';
      _structureLevelController.text =
          item.uomStructureLevel?.toString() ?? '1';
    });

    // Load descriptions if available
    _loadItemDescription();
    _loadUomDescriptions();
  }

  void _initializeBatchMode() {
    // Prepare first item in batch
    _uomConversionBloc.add(
      PrepareCreateUomConversion(widget.authBloc.state.companyId!),
    );
  }

  void _loadItemDescription() {
    if (_selectedItem != null && _availableItems.isNotEmpty) {
      try {
        final item = _availableItems.firstWhere(
          (item) => item.id == _selectedItem,
          orElse: () => ItemEntryModel.empty(),
        );
        if (item != null) {
          setState(() {
            _selectedItemDescription = item.itemDescription ?? 'Whattt';
          });
        }
      } catch (e) {
        // Silently handle error
      }
    }
  }

  void _loadUomDescriptions() {
    if (_fromUom != null) {
      try {
        final fromUom = _availableUoms.firstWhere(
          (uom) => uom.id == _fromUom,
          orElse: () => UdcDetails.empty(),
        );
        if (fromUom != null) {
          setState(() {
            _fromUomDescription = fromUom.description1;
          });
        }
      } catch (e) {
        // Silently handle error
      }
    }

    if (_toUom != null) {
      try {
        final toUom = _availableUoms.firstWhere(
          (uom) => uom.id == _toUom,
          orElse: () => UdcDetails.empty(),
        );
        if (toUom != null) {
          setState(() {
            _toUomDescription = toUom.description1;
          });
        }
      } catch (e) {
        // Silently handle error
      }
    }
  }

  void _handleStateChange(ItemUomConversionState state) {
    if (!mounted) return;

    setState(() {
      _currentStatus = state.status;

      // Handle processing states
      if (state.status == ItemUomConversionStatus.creating ||
          state.status == ItemUomConversionStatus.updating ||
          state.status == ItemUomConversionStatus.deleting) {
        _isProcessing = true;
        _hasValidationError = false;
        _currentErrorMessage = null;
      } else {
        _isProcessing = false;
      }

      // Handle validation states
      if (state.status == ItemUomConversionStatus.duplication) {
        _hasValidationError = true;
        _currentErrorMessage =
            state.message ?? 'This UoM conversion already exists';
        _showErrorSnackBar(_currentErrorMessage!);
      }

      if (state.status == ItemUomConversionStatus.structureInvalid) {
        _hasValidationError = true;
        _currentErrorMessage =
            state.message ?? 'Invalid structure level configuration';
        _showErrorSnackBar(_currentErrorMessage!);
      }

      if (state.status == ItemUomConversionStatus.validationFailed) {
        _hasValidationError = true;
        _currentErrorMessage = state.message ?? 'Validation failed';
        _showErrorSnackBar(_currentErrorMessage!);
      }

      // Handle success state
      if (state.status == ItemUomConversionStatus.success) {
        _handleSuccess(state);
      }

      // Handle error state
      if (state.status == ItemUomConversionStatus.failure) {
        _handleError(state.message ?? 'An error occurred during the operation');
      }
    });
  }

  void _handleSuccess(ItemUomConversionState state) {
    final message =
        state.message ??
        (widget.editingItem != null
            ? 'UoM conversion updated successfully'
            : 'UoM conversion created successfully');

    _showSuccessSnackBar(message);

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

    // Check for duplication after a longer delay
    _duplicationCheckTimer?.cancel();
    _duplicationCheckTimer = Timer(const Duration(milliseconds: 1000), () {
      _checkForDuplication();
    });
  }

  void _validateBusinessRules() {
    // Clear previous errors
    setState(() {
      _hasValidationError = false;
      _currentErrorMessage = null;
    });

    // Check for same From and To UoM
    if (_fromUom != null && _toUom != null && _fromUom == _toUom) {
      setState(() {
        _hasValidationError = true;
        _currentErrorMessage = 'From UoM and To UoM cannot be the same';
      });
      return;
    }

    // Validate structure level
    final level = int.tryParse(_structureLevelController.text);
    if (level != null && level < 1) {
      setState(() {
        _hasValidationError = true;
        _currentErrorMessage = 'Structure level must be at least 1';
      });
      return;
    }

    // Validate conversion factor
    final factor = double.tryParse(_conversionFactorController.text);
    if (factor != null && factor <= 0) {
      setState(() {
        _hasValidationError = true;
        _currentErrorMessage = 'Conversion factor must be greater than 0';
      });
      return;
    }

    // Check if all required fields are filled
    if (_selectedItem == null || _fromUom == null || _toUom == null) {
      setState(() {
        _hasValidationError = true;
        _currentErrorMessage = 'Please fill all required fields';
      });
      return;
    }
  }

  void _checkForDuplication() {
    if (_selectedItem == null || _fromUom == null || _toUom == null) return;

    final conversion = ItemUomConversion(
      itemNumber: _selectedItem,
      fromUom: _fromUom,
      toUom: _toUom,
      company: widget.authBloc.state.companyId,
    );

    _uomConversionBloc.add(CheckDuplication(conversion));
  }

  void _saveConversion({bool closeAfterSave = true}) {
    if (_isProcessing || _hasValidationError) {
      if (_hasValidationError) {
        _showErrorSnackBar(
          _currentErrorMessage ?? 'Please fix validation errors',
        );
      }
      return;
    }

    if (!_formKey.currentState!.validate()) {
      _showErrorSnackBar('Please fix form errors before saving');
      return;
    }

    // Final business rule validation
    _validateBusinessRules();
    if (_hasValidationError) {
      _showErrorSnackBar(_currentErrorMessage!);
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
      conversionFactor:
          double.tryParse(_conversionFactorController.text) ?? 1.0,
      inverseConversion:
          1 / (double.tryParse(_conversionFactorController.text) ?? 1.0),
      uomStructureLevel: int.tryParse(_structureLevelController.text) ?? 1,
      company: widget.authBloc.state.companyId,
      validCell: true,
      createdBy: widget.editingItem == null
          ? widget.authBloc.state.userId?.id
          : null,
      dateCreated: widget.editingItem == null ? DateTime.now() : null,
      updatedBy: widget.editingItem != null
          ? widget.authBloc.state.userId?.id
          : null,
      dateUpdated: widget.editingItem != null ? DateTime.now() : null,
    );

    if (widget.editingItem == null) {
      _uomConversionBloc.add(
        SaveItemUomConversion(conversion, widget.authBloc.state.userId!.id),
      );
    } else {
      _uomConversionBloc.add(
        UpdateItemUomConversion(conversion, widget.authBloc.state.userId!.id),
      );
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
      // Auto-increment structure level for next entry
      final currentLevel = int.tryParse(_structureLevelController.text) ?? 1;
      _structureLevelController.text = (currentLevel + 1).toString();

      // Keep item and from UoM, clear to UoM for next conversion
      _toUom = null;
      _toUomDescription = null;
      _conversionFactorController.text = '1.0';

      // Clear validation state
      _hasValidationError = false;
      _currentErrorMessage = null;
    });

    _showInfoSnackBar(
      'Ready for next conversion entry. Structure level auto-incremented.',
    );
  }

  void _cancel() {
    if (_isProcessing) {
      _showInfoSnackBar('Please wait for the current operation to complete');
      return;
    }

    // Show confirmation dialog if there are unsaved changes
    if (_hasUnsavedChanges()) {
      _showCancelConfirmationDialog();
    } else {
      Navigator.of(context).pop(false);
    }
  }

  bool _hasUnsavedChanges() {
    return _selectedItem != null ||
        _fromUom != null ||
        _toUom != null ||
        _conversionFactorController.text.isNotEmpty ||
        _structureLevelController.text.isNotEmpty;
  }

  void _showCancelConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text(
          'You have unsaved changes. Are you sure you want to discard them?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Keep Editing'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(false); // Close form
            },
            child: const Text('Discard', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    if (_isProcessing) {
      _showInfoSnackBar('Cannot reset form while processing');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Form'),
        content: const Text('Are you sure you want to reset all fields?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performFormReset();
            },
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _performFormReset() {
    _formKey.currentState?.reset();
    setState(() {
      _selectedItem = null;
      _fromUom = null;
      _toUom = null;
      _selectedItemDescription = null;
      _fromUomDescription = null;
      _toUomDescription = null;
      _conversionFactorController.clear();
      _structureLevelController.clear();
      _hasValidationError = false;
      _currentErrorMessage = null;
    });

    // Clear the create list in bloc if needed
    if (widget.editingItem == null) {
      _uomConversionBloc.add(ClearCreateList());
    }

    _showInfoSnackBar('Form reset successfully');
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
        duration: const Duration(seconds: 3),
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
        duration: const Duration(seconds: 4),
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
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _validationTimer?.cancel();
    _duplicationCheckTimer?.cancel();
    _stateSubscription?.cancel();
    _itemsSubscription?.cancel();
    _uomSubscription?.cancel();
    _conversionFactorController.dispose();
    _structureLevelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isProcessing && !_hasUnsavedChanges(),
      onPopInvoked: (didPop) {
        if (!didPop && _hasUnsavedChanges()) {
          _showCancelConfirmationDialog();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.editingItem != null
                ? 'Edit UoM Conversion'
                : widget.isBatchMode
                ? 'Create UoM Conversions (Batch)'
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
            if (!_isProcessing) ...[
              _buildStatusIndicator(),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _resetForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  side: const BorderSide(color: Colors.white),
                ),
                child: const Text(
                  'Reset',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
        body: _buildFormContent(),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    Color color = Colors.grey;
    IconData icon = Icons.circle;
    String tooltip = 'Ready';

    if (_isProcessing) {
      color = Colors.orange;
      icon = Icons.autorenew;
      tooltip = 'Processing...';
    } else if (_hasValidationError) {
      color = Colors.red;
      icon = Icons.error;
      tooltip = 'Validation Error';
    } else if (_currentStatus == ItemUomConversionStatus.success) {
      color = Colors.green;
      icon = Icons.check_circle;
      tooltip = 'Success';
    }

    return Tooltip(
      message: tooltip,
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildFormContent() {
    return Column(
      children: [
        // Status Banner
        if (_isProcessing) _buildProcessingBanner(),
        if (_hasValidationError && _currentErrorMessage != null)
          _buildErrorBanner(),
        if (_currentStatus == ItemUomConversionStatus.success)
          _buildSuccessBanner(),

        // Progress indicator for batch mode
        if (widget.isBatchMode && _batchItems.isNotEmpty) _buildBatchProgress(),

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
                  const SizedBox(height: 20),
                  _buildHelpSection(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProcessingBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.orange.shade50,
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _currentStatus == ItemUomConversionStatus.creating
                  ? 'Creating UoM conversion...'
                  : _currentStatus == ItemUomConversionStatus.updating
                  ? 'Updating UoM conversion...'
                  : 'Processing...',
              style: const TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.green.shade50,
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _currentStatus == ItemUomConversionStatus.success
                  ? 'Operation completed successfully!'
                  : 'Success',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
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

  Widget _buildBatchProgress() {
    return LinearProgressIndicator(
      value: _currentBatchIndex / _batchItems.length,
      backgroundColor: Colors.grey.shade200,
      valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
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
          'Item UoM Conversion Details',
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
        if (widget.isBatchMode) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.batch_prediction,
                  size: 16,
                  color: Colors.blue.shade700,
                ),
                const SizedBox(width: 6),
                Text(
                  'Batch Mode',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildItemDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Item *'),
        if (_isLoadingItems) _buildLoadingField('Loading items...'),
        if (_itemsError != null) _buildErrorField(_itemsError!),
        if (!_isLoadingItems && _itemsError == null)
          CustomSearchableDropdown(
            labelText: 'Select Item',
            options: _availableItems
                .map((item) => item.itemDescription ?? 'Unknown Item')
                .toList(),
            value: _selectedItemDescription,
            prefixIcon: Iconsax.box,
            allowCustomEntries: false,
            onChanged: _isProcessing
                ? null
                : (newValue) {
                    if (newValue == null) {
                      setState(() {
                        _selectedItem = null;
                        _selectedItemDescription = null;
                      });
                    } else {
                      final selectedItem = _availableItems.firstWhere(
                        (item) => item.itemDescription == newValue,
                      );
                      setState(() {
                        _selectedItem = selectedItem.id;
                        _selectedItemDescription = newValue;
                      });
                    }
                    _performRealTimeValidation();
                  },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select an item';
              }
              return null;
            },
          ),
      ],
    );
  }

  Widget _buildFromUomDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('From UoM *'),
        if (_isLoadingUoms) _buildLoadingField('Loading UoM units...'),
        if (_uomsError != null) _buildErrorField(_uomsError!),
        if (!_isLoadingUoms && _uomsError == null)
          CustomSearchableDropdown(
            labelText: 'Select From UoM',
            options: _availableUoms
                .map((udc) => udc.description1 ?? 'Unknown UoM')
                .toList(),
            value: _fromUomDescription,
            prefixIcon: Iconsax.convert_3d_cube,
            allowCustomEntries: false,
            onChanged: _isProcessing
                ? null
                : (newValue) {
                    if (newValue == null) {
                      setState(() {
                        _fromUom = null;
                        _fromUomDescription = null;
                      });
                    } else {
                      final selectedUom = _availableUoms.firstWhere(
                        (udc) => udc.description1 == newValue,
                      );
                      setState(() {
                        _fromUom = selectedUom.id;
                        _fromUomDescription = newValue;
                      });
                    }
                    _performRealTimeValidation();
                  },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select From UoM';
              }
              return null;
            },
          ),
      ],
    );
  }

  Widget _buildToUomDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('To UoM *'),
        if (_isLoadingUoms) _buildLoadingField('Loading UoM units...'),
        if (_uomsError != null) _buildErrorField(_uomsError!),
        if (!_isLoadingUoms && _uomsError == null)
          CustomSearchableDropdown(
            labelText: 'Select To UoM',
            options: _availableUoms
                .map((udc) => udc.description1 ?? 'Unknown UoM')
                .toList(),
            value: _toUomDescription,
            prefixIcon: Iconsax.convert_3d_cube,
            allowCustomEntries: false,
            onChanged: _isProcessing
                ? null
                : (newValue) {
                    if (newValue == null) {
                      setState(() {
                        _toUom = null;
                        _toUomDescription = null;
                      });
                    } else {
                      final selectedUom = _availableUoms.firstWhere(
                        (udc) => udc.description1 == newValue,
                      );
                      setState(() {
                        _toUom = selectedUom.id;
                        _toUomDescription = newValue;
                      });
                    }
                    _performRealTimeValidation();
                  },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select To UoM';
              }
              if (_fromUom != null && _toUom == _fromUom) {
                return 'To UoM cannot be same as From UoM';
              }
              return null;
            },
          ),
      ],
    );
  }

  Widget _buildLoadingField(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.hourglass_empty, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: const TextStyle(color: Colors.grey)),
          ),
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorField(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.red.shade50,
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade500),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: TextStyle(color: Colors.red.shade700)),
          ),
        ],
      ),
    );
  }

  Widget _buildConversionFactorField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Conversion Factor *'),
        CustomTextField(
          labelText: 'Enter conversion factor (e.g., 2.5)',
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
        _buildFieldLabel('Structure Level *'),
        CustomTextField(
          labelText: 'Enter structure level (e.g., 1, 2, 3...)',
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
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Save & Add New',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
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
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.editingItem != null ? Icons.save : Icons.check,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.editingItem != null ? 'Update' : 'Save & Close',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildHelpSection() {
    return Card(
      color: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.help_outline, color: Colors.blue.shade600, size: 20),
                const SizedBox(width: 8),
                Text(
                  'UoM Conversion Help',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildHelpItem(
              'Conversion Factor',
              'The factor to multiply the From UoM quantity by to get the To UoM quantity',
            ),
            _buildHelpItem(
              'Structure Level',
              'Defines the conversion hierarchy (1 = first conversion, 2 = second, etc.)',
            ),
            _buildHelpItem(
              'Same UoM Restriction',
              'From UoM and To UoM cannot be the same unit',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
          Text(
            description,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
