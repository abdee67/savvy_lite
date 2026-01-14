// features/purchase/purchase_entry/ui/receiving/purchase_receiving_screen.dart
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:savvy_stock/core/widgets/custom_searchable_dropdown.dart';
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
import 'package:savvy_stock/features/purchase/purchase_entry/models/purchase_order_receiver_model.dart';
import 'package:savvy_stock/features/stock/item_in_branch/blocs/item_in_branch_bloc.dart';
import 'package:savvy_stock/features/stock/item_in_branch/blocs/item_in_branch_event.dart';
import 'package:savvy_stock/features/stock/item_locations/blocs/item_locations_bloc.dart';
import 'package:savvy_stock/features/stock/item_locations/blocs/item_locations_event.dart';
import 'package:savvy_stock/features/stock/item_locations/blocs/item_locations_state.dart';
import 'package:savvy_stock/features/stock/item_locations/models/item_locations_model.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_bloc.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_state.dart';

class PurchaseReceivingScreen extends StatefulWidget {
  final AuthBloc authBloc;
  final PurchaseOrderDetail detail;
  final Map<String, dynamic> orderData;

  const PurchaseReceivingScreen({
    super.key,
    required this.detail,
    required this.orderData,
    required this.authBloc,
  });

  @override
  State<PurchaseReceivingScreen> createState() =>
      _PurchaseReceivingScreenState();
}

class _PurchaseReceivingScreenState extends State<PurchaseReceivingScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late List<PurchaseOrderReceiver> _receivers;
  int _selectedReceiverIndex = 0;
  bool _isLoading = true;
  bool _applyLocationManagement = false;
  bool _applyLotManagement = false;
  String? _lotType;
  Branch? _selectedBranch;
  ItemLocation? _selectedLocation;

  @override
  void initState() {
    super.initState();

    _receivers = [];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeReceiving();
    });
  }

  void _initializeReceiving() async {
    try {
      final authState = context.read<AuthBloc>().state;
      final companyId = authState.companyId;
      final userId = authState.userId?.id;

      if (companyId != null) {
        // Check system constants
        final systemBloc = context.read<SystemConstantBloc>();
        _updateSystemConstants(systemBloc.state);

        // Load branches
        context.read<BranchBloc>().add(LoadBranchs(companyId));

        // Load items in branch for the selected item
        context.read<StockItemInBranchBloc>().add(
          LoadItemsFromBranch(companyId),
        );

        // Check for existing receivers
        final purchaseState = context.read<PurchaseOrderBloc>().state;
        if (purchaseState.editReceivers.isNotEmpty) {
          setState(() {
            _receivers = List.from(purchaseState.editReceivers);
          });
        } else {
          // Create initial receiver
          final initialReceiver = PurchaseOrderReceiver(
            tempId: DateTime.now().millisecondsSinceEpoch,
            poDetail: widget.detail.id,
            itemNumber: widget.detail.itemNumber,
            quantityTransaction: widget.detail.quantityTransaction,
            unitCost: widget.detail.unitCost,
            amountExtendedCost: widget.detail.amountExtendedCost,
            quantityOpen:
                widget.detail.quantityOpen ?? widget.detail.quantityTransaction,
            amountOpen:
                widget.detail.amountOpen ?? widget.detail.amountExtendedCost,
            company: companyId,
            userId: userId,
            dateUpdated: DateTime.now(),
            unitOfMeasure: widget.detail.unitOfMeasure,
            dateReceived: DateTime.now(),
            dateEffective: widget.detail.dateEffective,
            dateExpiration: widget.detail.dateExpiration,
          );

          setState(() {
            _receivers = [initialReceiver];
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error initializing receiving: $e');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateSystemConstants(SystemConstantState state) {
    final systemConstant =
        state.systemConstant ??
        state.selected ??
        (state.systemConstants.isNotEmpty ? state.systemConstants.first : null);

    if (systemConstant != null) {
      setState(() {
        _applyLocationManagement = systemConstant.applyLocationMgmBoolean;
        _applyLotManagement = systemConstant.applyLotMgmBoolean;
        _lotType = systemConstant.lotTypeRef?.detailCode;
      });
    }
  }

  void _onBranchSelected(Branch? branch) {
    if (branch != null && _receivers.isNotEmpty) {
      // Load locations for selected branch
      setState(() {
        _selectedBranch = branch;
        _selectedLocation = null;
      });

      // Load locations for selected branch
      if (kDebugMode) {
        developer.log('📍 Loading locations for branch ID: ${branch.id}');
      }
      _loadBranchLocations(branch.id);

      // Update current receiver
      final updated = _receivers[_selectedReceiverIndex].copyWith(
        branchRecieved: branch.id,
        location: null, // Clear location when branch changes
      );

      _updateReceiver(updated);
    }
  }

  void _loadBranchLocations(int branchId) {
    final authBloc = context.read<AuthBloc>();
    final companyId = authBloc.state.companyId;

    if (companyId != null) {
      if (kDebugMode) {
        developer.log(
          '🔄 Dispatching LoadItemLocationsForBranch - Branch: $branchId, Company: $companyId',
        );
      }
      final locationsBloc = context.read<StockItemLocationBloc>();
      locationsBloc.add(
        LoadItemLocationsForBranch(branchId: branchId, companyId: companyId),
      );
    } else {
      if (kDebugMode) {
        developer.log('❌ Company ID is null');
      }
    }
  }

  void _onLocationSelected(ItemLocation? location) {
    setState(() {
      _selectedLocation = location;
    });

    if (location != null && _receivers.isNotEmpty) {
      final updated = _receivers[_selectedReceiverIndex].copyWith(
        location: location.id,
        branchRecieved: location.branch ?? _selectedBranch?.id,
      );

      _updateReceiver(updated);
    }
  }

  void _addReceiver() {
    final authState = context.read<AuthBloc>().state;
    final companyId = authState.companyId;
    final userId = authState.userId?.id;

    if (companyId != null && userId != null) {
      final newReceiver = PurchaseOrderReceiver(
        tempId: DateTime.now().millisecondsSinceEpoch + _receivers.length,
        poDetail: widget.detail.id,
        itemNumber: widget.detail.itemNumber,
        quantityTransaction: widget.detail.quantityTransaction,
        unitCost: widget.detail.unitCost,
        amountExtendedCost: widget.detail.amountExtendedCost,
        quantityOpen:
            widget.detail.quantityOpen ?? widget.detail.quantityTransaction,
        amountOpen:
            widget.detail.amountOpen ?? widget.detail.amountExtendedCost,
        company: companyId,
        userId: userId,
        dateUpdated: DateTime.now(),
        unitOfMeasure: widget.detail.unitOfMeasure,
        dateReceived: DateTime.now(),
        dateEffective: widget.detail.dateEffective,
        dateExpiration: widget.detail.dateExpiration,
      );

      setState(() {
        _receivers = [..._receivers, newReceiver];
        _selectedReceiverIndex = _receivers.length - 1;
      });
    }
  }

  void _removeCurrentReceiver() {
    if (_receivers.isEmpty) return;

    final currentReceiver = _getCurrentReceiver();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Record'),
        content: const Text('Do you want to delete this record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _receivers.removeAt(_selectedReceiverIndex);
                if (_receivers.isNotEmpty) {
                  if (_selectedReceiverIndex >= _receivers.length) {
                    _selectedReceiverIndex = _receivers.length - 1;
                  }
                } else {
                  _selectedReceiverIndex = 0;
                }
              });
              Navigator.pop(context);
            },
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _updateReceiver(PurchaseOrderReceiver receiver) {
    // Mark validity locally based on quantity vs open quantity
    final quantityRecieved = receiver.quantityRecieved ?? 0;
    final quantityOpen = receiver.quantityOpen ?? 0;
    final isValid = quantityRecieved > 0 && quantityRecieved <= quantityOpen;

    final updatedReceiver = receiver.copyWith(validCell: isValid);

    setState(() {
      _receivers[_selectedReceiverIndex] = updatedReceiver;
    });

    // Validate receipt quantity in bloc (keeps editReceivers in sync)
    context.read<PurchaseOrderBloc>().add(
      ValidateReceiptQuantity(receiver: updatedReceiver),
    );
  }

  void _saveReceivers() async {
    if (_formKey.currentState?.validate() ?? false) {
      // Validate all receivers
      bool allValid = true;
      for (final receiver in _receivers) {
        if (receiver.quantityRecieved == null ||
            receiver.quantityRecieved! <= 0 ||
            receiver.quantityRecieved! > (receiver.quantityOpen ?? 0)) {
          allValid = false;
          break;
        }
      }

      if (!allValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fix validation errors in all receivers'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Ensure branch and (if enabled) location are selected for all receivers
      bool locationDataMissing = false;
      for (final receiver in _receivers) {
        if (receiver.branchRecieved == null ||
            (_applyLocationManagement && receiver.location == null)) {
          locationDataMissing = true;
          break;
        }
      }

      if (locationDataMissing) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select branch and location for all receipts'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Update BLoC with all receivers so bloc.editReceivers matches UI
      final purchaseBloc = context.read<PurchaseOrderBloc>();
      for (var i = 0; i < _receivers.length; i++) {
        purchaseBloc.add(
          UpdatePurchaseOrderReceiver(receiver: _receivers[i], index: i),
        );
      }

      // Save receipt with stock update
      purchaseBloc.add(const SavePurchaseOrderReceipt());
      purchaseBloc.add(
        LoadPurchaseOrders(companyId: widget.authBloc.state.companyId!),
      );
    }
  }

  void _closeDialog() {
    context.pop();
  }

  PurchaseOrderReceiver? _getCurrentReceiver() {
    if (_receivers.isEmpty) return null;
    if (_selectedReceiverIndex >= _receivers.length) {
      _selectedReceiverIndex = 0;
    }
    return _receivers[_selectedReceiverIndex];
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PurchaseOrderBloc, PurchaseOrderState>(
      listener: (context, state) {
        // Listen for system constants updates
        if (state.systemConstants != null) {
          _updateSystemConstants(
            SystemConstantState(systemConstant: state.systemConstants!),
          );
        }

        // Handle errors
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!), backgroundColor: Colors.red),
          );
        }

        // Handle successful save
        if (state.status == PurchaseOrderStatus.success &&
            state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: Colors.green,
            ),
          );

          // Close dialog after successful save
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) {
              _closeDialog();
            }
          });
        }
      },
      builder: (context, state) {
        return Dialog(
          insetPadding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800, maxHeight: 700),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildReceivingForm(context, state),
          ),
        );
      },
    );
  }

  Widget _buildReceivingForm(BuildContext context, PurchaseOrderState state) {
    final currentReceiver = _getCurrentReceiver();

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Item Details Card
          _buildItemDetailsCard(),

          // Receiver Navigation (if multiple receivers)
          if (_receivers.length > 1) _buildReceiverNavigation(),

          // Receiver Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: currentReceiver != null
                  ? _buildReceiverForm(currentReceiver, state)
                  : _buildEmptyReceivers(),
            ),
          ),

          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _closeDialog,
                    icon: const Icon(Icons.close),
                    label: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saveReceivers,
                    icon: const Icon(Icons.check),
                    label: const Text('Save'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF155888),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemDetailsCard() {
    final detail = widget.detail;
    final itemName =
        detail.itemNumberRef?.itemDescription ?? 'Item #${detail.itemNumber}';
    final quantityTransaction = detail.quantityTransaction ?? 0;
    final quantityOpen = detail.quantityOpen ?? quantityTransaction;
    final unitCost = detail.unitCost ?? 0;
    final extendedCost = detail.amountExtendedCost ?? 0;
    final uom = detail.unitOfMeasureRef?.description1 ?? 'EA';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          // Left side - Item info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Item',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                Text(
                  itemName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildDetailItem(label: 'UoM', value: uom),
                    const SizedBox(width: 24),
                    _buildDetailItem(
                      label: 'Qty Transaction',
                      value: quantityTransaction.toStringAsFixed(2),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 6),

          // Right side - Open quantities
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Quantity Not-Received',
                  style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                ),
                const SizedBox(height: 4),
                Text(
                  quantityOpen.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Open to Receive',
                  style: TextStyle(fontSize: 10, color: Colors.orange.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildReceiverNavigation() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border(bottom: BorderSide(color: Colors.blue.shade100)),
      ),
      child: Row(
        children: [
          const Icon(Icons.list, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          const Text(
            'Receivers:',
            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_receivers.length, (index) {
                  final receiver = _receivers[index];
                  final isSelected = index == _selectedReceiverIndex;
                  final hasError = receiver.validCell == false;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedReceiverIndex = index;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF155888)
                            : hasError
                            ? Colors.red.shade100
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF155888)
                              : hasError
                              ? Colors.red.shade300
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Receiver ${index + 1}',
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : hasError
                                  ? Colors.red.shade700
                                  : Colors.grey.shade700,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          if (hasError)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Icon(
                                Icons.error,
                                size: 14,
                                color: Colors.red.shade700,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiverForm(
    PurchaseOrderReceiver receiver,
    PurchaseOrderState state,
  ) {
    final isNewReceiver = receiver.id == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Received Branch
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
              onChanged: (selectedBranchDesc) {
                if (kDebugMode) {
                  developer.log(
                    '🔹 Branch dropdown changed to: $selectedBranchDesc',
                  );
                }
                _onBranchSelected(
                  branchState.branchs.firstWhere(
                    (branch) => branch.description == selectedBranchDesc,
                  ),
                );
              },
              validator: (value) {
                if (_selectedBranch == null) {
                  return 'Please select branch';
                }
                return null;
              },
            );
          },
        ),

        const SizedBox(height: 16),

        // Location (if location management enabled)
        if (_applyLocationManagement) ...[
          // Location Dropdown (only if branch is selected)
          if (_selectedBranch != null) ...[
            BlocBuilder<StockItemLocationBloc, ItemLocationsState>(
              builder: (context, locationState) {
                if (kDebugMode) {
                  developer.log(
                    '📋 BlocBuilder rebuilt - Status: ${locationState.status}, Items count: ${locationState.items.length}',
                  );
                }
                return CustomSearchableDropdown(
                  labelText: 'Location',
                  options: locationState.items
                      .map(
                        (location) =>
                            location.locationDescription?.locationDescription ??
                            'No Name',
                      )
                      .toList(),
                  value: _selectedLocation
                      ?.locationDescription
                      ?.locationDescription,
                  prefixIcon: Icons.location_on,
                  allowCustomEntries: false,
                  onChanged: (selectedLocationDesc) {
                    if (kDebugMode) {
                      developer.log(
                        '🔹 Location dropdown changed to: $selectedLocationDesc',
                      );
                    }
                    _onLocationSelected(
                      locationState.items.firstWhere(
                        (location) =>
                            location.locationDescription?.locationDescription ==
                            selectedLocationDesc,
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ],

        // Received Date
        CustomTextField(
          labelText: 'Received Date *',
          controller: TextEditingController(
            text: receiver.dateReceived != null
                ? DateFormat('yyyy-MM-dd').format(receiver.dateReceived!)
                : DateFormat('yyyy-MM-dd').format(DateTime.now()),
          ),
          readOnly: true,
          onTap: isNewReceiver
              ? () => _selectDate(receiver.dateReceived ?? DateTime.now(), (
                  newDate,
                ) {
                  final updated = receiver.copyWith(dateReceived: newDate);
                  _updateReceiver(updated);
                })
              : null,
          prefixIcon: const Icon(Icons.calendar_today),
          validator: (value) {
            if (isNewReceiver && (value == null || value.isEmpty)) {
              return 'Please select received date';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Quantity Received
        CustomTextField(
          labelText: 'Quantity Received *',
          controller: TextEditingController(
            text: receiver.quantityRecieved?.toStringAsFixed(2) ?? '',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: isNewReceiver
              ? (value) {
                  final qty = double.tryParse(value) ?? 0;
                  final amount = qty * (receiver.unitCost ?? 0);
                  final updated = receiver.copyWith(
                    quantityRecieved: qty,
                    amountReceived: amount,
                  );
                  _updateReceiver(updated);
                }
              : null,
          prefixIcon: const Icon(Icons.scale),
          validator: (value) {
            if (isNewReceiver) {
              if (value == null || value.isEmpty) {
                return 'Please enter quantity';
              }
              final qty = double.tryParse(value);
              if (qty == null || qty <= 0) {
                return 'Please enter valid quantity';
              }
              if (qty > (receiver.quantityOpen ?? 0)) {
                return 'Quantity exceeds open amount';
              }
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Amount Received (read-only)
        CustomTextField(
          labelText: 'Amount Received',
          controller: TextEditingController(
            text: '\$${(widget.detail.amountReceived ?? 0).toStringAsFixed(2)}',
          ),
          readOnly: true,
          prefixIcon: const Icon(Icons.attach_money),
        ),

        const SizedBox(height: 16),

        // UoM (read-only)
        CustomTextField(
          labelText: 'UoM',
          controller: TextEditingController(
            text:
                receiver.unitOfMeasureRef?.description1 ??
                widget.detail.unitOfMeasureRef?.description1 ??
                'EA',
          ),
          readOnly: true,
          prefixIcon: const Icon(Icons.straighten),
        ),

        // Lot Management Fields
        if (_applyLotManagement) ...[
          const SizedBox(height: 16),

          // Effective Date
          CustomTextField(
            labelText: 'Effective Date${_lotType == 'F' ? ' *' : ''}',
            controller: TextEditingController(
              text: receiver.dateEffective != null
                  ? DateFormat('yyyy-MM-dd').format(receiver.dateEffective!)
                  : '',
            ),
            readOnly: true,
            onTap: isNewReceiver
                ? () => _selectDate(receiver.dateEffective ?? DateTime.now(), (
                    newDate,
                  ) {
                    final updated = receiver.copyWith(dateEffective: newDate);
                    _updateReceiver(updated);
                  })
                : null,
            prefixIcon: const Icon(Icons.calendar_today),
            validator: (value) {
              if (isNewReceiver &&
                  _lotType == 'F' &&
                  (value == null || value.isEmpty)) {
                return 'Effective date is required';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Expiration Date
          CustomTextField(
            labelText:
                'Expiration Date${_lotType == null || _lotType == 'X' ? ' *' : ''}',
            controller: TextEditingController(
              text: receiver.dateExpiration != null
                  ? DateFormat('yyyy-MM-dd').format(receiver.dateExpiration!)
                  : '',
            ),
            readOnly: true,
            onTap: isNewReceiver
                ? () => _selectDate(
                    receiver.dateExpiration ??
                        DateTime.now().add(const Duration(days: 365)),
                    (newDate) {
                      final updated = receiver.copyWith(
                        dateExpiration: newDate,
                      );
                      _updateReceiver(updated);
                    },
                  )
                : null,
            prefixIcon: const Icon(Icons.event_busy),
            validator: (value) {
              if (isNewReceiver &&
                  (_lotType == null || _lotType == 'X') &&
                  (value == null || value.isEmpty)) {
                return 'Expiration date is required';
              }
              return null;
            },
          ),
        ],

        const SizedBox(height: 16),

        // Batch Number
        CustomTextField(
          labelText: 'Batch Number',
          controller: TextEditingController(
            text: receiver.batchNumberSupplier ?? '',
          ),
          onChanged: isNewReceiver
              ? (value) {
                  final updated = receiver.copyWith(batchNumberSupplier: value);
                  _updateReceiver(updated);
                }
              : null,
          prefixIcon: const Icon(Icons.numbers),
        ),
      ],
    );
  }

  Future<void> _selectDate(
    DateTime initialDate,
    Function(DateTime) onDateSelected,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF155888)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      onDateSelected(picked);
    }
  }

  Widget _buildEmptyReceivers() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'No Receivers Added',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Click "Add Receiver" to start receiving items',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addReceiver,
            icon: const Icon(Icons.add),
            label: const Text('Add First Receiver'),
          ),
        ],
      ),
    );
  }
}
