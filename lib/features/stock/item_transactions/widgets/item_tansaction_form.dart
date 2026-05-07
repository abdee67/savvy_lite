import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:savvy_stock/core/widgets/custom_searchable_dropdown.dart';
import 'package:savvy_stock/features/stock/item_uom_conversions/blocs/item_uom_conversions_bloc.dart';
import 'package:savvy_stock/features/stock/item_uom_conversions/blocs/item_uom_conversions_event.dart';
import 'package:savvy_stock/features/stock/item_uom_conversions/blocs/item_uom_conversions_state.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_bloc.dart';
import 'package:savvy_stock/core/widgets/custom_dropdown.dart';
import 'package:savvy_stock/core/widgets/custom_table_dropdown.dart';
import 'package:savvy_stock/core/widgets/custom_text_Form.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/branch_list/blocs/branch_list_bloc.dart';
import 'package:savvy_stock/features/branch_list/blocs/branch_list_event.dart';
import 'package:savvy_stock/features/branch_list/blocs/branch_list_state.dart';
import 'package:savvy_stock/features/stock/item_in_branch/blocs/item_in_branch_bloc.dart';
import 'package:savvy_stock/features/stock/item_in_branch/blocs/item_in_branch_event.dart';
import 'package:savvy_stock/features/stock/item_in_branch/blocs/item_in_branch_state.dart';
import 'package:savvy_stock/features/stock/item_locations/blocs/item_locations_bloc.dart';
import 'package:savvy_stock/features/stock/item_locations/blocs/item_locations_event.dart';
import 'package:savvy_stock/features/stock/item_locations/blocs/item_locations_state.dart';
import 'package:savvy_stock/features/stock/item_locations/models/item_locations_model.dart';
import 'package:savvy_stock/features/stock/item_transactions/blocs/item_transaction_bloc.dart';
import 'package:savvy_stock/features/stock/item_transactions/blocs/item_transaction_event.dart';
import 'package:savvy_stock/features/stock/item_transactions/blocs/item_transaction_state.dart';
import 'package:savvy_stock/features/stock/item_transactions/model/item_transaction_model.dart';
import 'package:savvy_stock/features/stock/lot_master/blocs/lot_master_bloc.dart';
import 'package:savvy_stock/features/stock/lot_master/blocs/lot_master_event.dart';
import 'package:savvy_stock/features/stock/lot_master/blocs/lot_master_state.dart';
import 'package:savvy_stock/features/stock/lot_master/models/lot_master_model.dart';
import 'package:savvy_stock/features/stock/lot_coloring/model/lot_coloring_model.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_bloc.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_event.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_state.dart';
import 'package:savvy_stock/features/udc_detail/models/udc_details.dart';

class ItemTransactionsFormPage extends StatefulWidget {
  final AuthBloc authBloc;
  final ItemTransactionModel? existingTransaction; // null = create mode

  const ItemTransactionsFormPage({
    super.key,
    required this.authBloc,
    this.existingTransaction,
  });

  @override
  State<ItemTransactionsFormPage> createState() =>
      _ItemTransactionsFormPageState();
}

class _ItemTransactionsFormPageState extends State<ItemTransactionsFormPage> {
  StreamSubscription? _trxNoSub;
  final _formKey = GlobalKey<FormState>();

  // Master transaction fields
  int? _transactionNumber;
  UdcDetails? _selectedTransactionType;
  int? _selectedFromBranch;
  int? _selectedToBranch;
  String? _remark;

  // System configuration
  bool _applyLocationMgmt = false;
  bool _applyLotMgmt = false;

  // Transaction items list
  final List<ItemTransactionModel> _transactionItems = [];
  int? _selectedUom;

  @override
  void initState() {
    super.initState();

    // Initialize BLoCs
    _initializeBlocs();

    // Load system configuration
    _loadSystemConfiguration();

    // Set up existing transaction or prepare new one
    if (widget.existingTransaction != null) {
      _setupEditMode();
    } else {
      _setupCreateMode();
    }
  }

  void _initializeBlocs() {
    final companyId = widget.authBloc.state.companyId;
    if (companyId != null) {
      context.read<BranchBloc>().add(LoadBranchs(companyId));
      context.read<UdcDetailsBloc>().add(
        LoadAllUdcDetails(),
      ); // Transaction Types
      context.read<StockItemInBranchBloc>().add(LoadItemsFromBranch(companyId));
    }
  }

  void _loadSystemConfiguration() {
    final systemConstant = context.read<SystemConstantBloc>().state.selected;
    setState(() {
      _applyLocationMgmt = systemConstant?.applyLocationMgmBoolean ?? false;
      _applyLotMgmt = systemConstant?.applyLotMgmBoolean ?? false;
    });
  }

  void _setupEditMode() {
    final transaction = widget.existingTransaction!;
    setState(() {
      _transactionNumber = transaction.transactionNumber;
      _selectedFromBranch = transaction.branch;
      _remark = transaction.remark;
      _selectedUom = transaction.unitOfMeasure;

      // Load transaction type
      if (transaction.transactionType != null) {
        final udcBloc = context.read<UdcDetailsBloc>();
        final transactionType = udcBloc.state.details.firstWhere(
          (udc) => udc.id == transaction.transactionType,
          orElse: () => UdcDetails.empty(),
        );
        _selectedTransactionType = transactionType;
      }

      // For transfer transactions, load to branch
      if (_selectedTransactionType?.detailCode == 'T') {
        _selectedToBranch = transaction
            .branch; // This would need adjustment based on your data model
      }
    });

    // Load transaction items
    context.read<ItemTransactionsBloc>().add(
      LoadItemTransactions(companyId: widget.authBloc.state.companyId!),
    );
  }

  void _setupCreateMode() {
    // Generate transaction number and prepare empty item
    context.read<ItemTransactionsBloc>().add(PrepareCreate());
    _setupTransactionNumberListener();

    // Start with one empty transaction item
    _addNewTransactionItem();
  }

  void _setupTransactionNumberListener() {
    _trxNoSub = context.read<ItemTransactionsBloc>().stream.listen((state) {
      if (state.selected?.transactionNumber != null) {
        if (!mounted) return;
        setState(() {
          _transactionNumber = state.selected!.transactionNumber;
        });
      }
    });
    if (kDebugMode) {
      developer.log('Transaction number: $_transactionNumber');
    }
  }

  void _onTransactionTypeChanged(UdcDetails? transactionType) {
    setState(() {
      _selectedTransactionType = transactionType;
      // Reset to branch when transaction type changes (unless it's transfer)
      if (transactionType?.detailCode != 'T') {
        _selectedToBranch = null;
        _selectedFromBranch = null;
        _remark = null;
        _transactionItems.clear();
        _addNewTransactionItem();
      }
    });
  }

  void _onFromBranchChanged(int? branchId) {
    setState(() {
      _selectedFromBranch = branchId;
      // Reset To Branch if it matches From Branch to prevent Dropdown error
      if (_selectedToBranch == branchId) {
        _selectedToBranch = null;
      }
      _transactionItems.clear();
      _addNewTransactionItem();
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

  void _onToBranchChanged(int? branchId) {
    setState(() {
      _selectedToBranch = branchId;
      // Reset From Branch if it matches To Branch to prevent Dropdown error
      if (_selectedFromBranch == branchId) {
        _selectedFromBranch = null;
      }
      _transactionItems.clear();
      _addNewTransactionItem();
    });
  }

  void _addNewTransactionItem() {
    setState(() {
      _transactionItems.add(
        ItemTransactionModel(
          tempId: DateTime.now().millisecondsSinceEpoch,
          transactionNumber: _transactionNumber,
          transactionType: _selectedTransactionType?.id,
          branch: _selectedFromBranch,
          remark: _remark,
          company: widget.authBloc.state.companyId,
          dateCreated: DateTime.now(),
          quantityTransaction: 0.0,
          beforeStoreQuantityAvailable: 0.0,
          unitCost: 0.0,
          amountCost: 0.0,
          beforeAmountCost: 0.0,
          adjustToIncrease: true, // Default to increase for adjustments
          unitOfMeasure: _selectedUom,
        ),
      );
    });
  }

  void _removeTransactionItem(ItemTransactionModel item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text('Do you want to delete this record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              setState(() => _transactionItems.remove(item));
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Transaction item removed'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  void _applyTransactions() {
    if (_formKey.currentState?.validate() != true) return;

    // Validate required fields
    if (_selectedTransactionType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a transaction type'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedFromBranch == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a from branch'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedTransactionType?.detailCode == 'T' &&
        _selectedToBranch == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a to branch for transfer'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate transaction items
    for (final item in _transactionItems) {
      if (item.itemNumber == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please select item number for all transaction items',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Check for Over-Deduction (Decrease)
      if (!item.adjustToIncrease &&
          _selectedTransactionType?.detailCode == 'A') {
        if (item.quantityTransaction > item.beforeStoreQuantityAvailable) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Insufficient quantity for item ${item.itemNumber} (Available: ${item.beforeStoreQuantityAvailable})',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      if (item.quantityTransaction <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid quantity for all items'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (item.unitOfMeasure == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select unit of measure for all items'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Validate location if location management is enabled
      if (_applyLocationMgmt && item.itemLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please select location for all items (location management enabled)',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Validate lot if lot management is enabled
      if (_applyLotMgmt && item.lotNumber == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please select lot for all items (lot management enabled)',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Validate to location for transfer transactions with location management
      if (_selectedTransactionType?.detailCode == 'T' &&
          _applyLocationMgmt &&
          item.itemLocationsTo == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select to location for transfer items'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Create master transaction
    final masterTransaction = ItemTransactionModel(
      transactionNumber: _transactionNumber,
      transactionType: _selectedTransactionType?.id,
      branch: _selectedFromBranch,
      branchTo: _selectedToBranch,
      remark: _remark,
      company: widget.authBloc.state.companyId,
      dateCreated: DateTime.now(),
      quantityTransaction: 0.0, // Not used for master
      beforeStoreQuantityAvailable: 0.0,
      unitCost: 0.0,
      amountCost: 0.0,
      beforeAmountCost: 0.0,
      unitOfMeasure: _selectedUom,
    );

    // Execute inventory transactions
    context.read<ItemTransactionsBloc>().add(
      ExecuteInventoryTransaction(
        masterTransaction: masterTransaction,
        detailTransactions: _transactionItems,
      ),
    );
  }

  void _cancelCreate() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text(
          'Are you sure you want to cancel? All unsaved changes will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to list
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.existingTransaction != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditMode ? 'Edit Item Transaction' : 'Create Item Transaction',
        ),
        backgroundColor: const Color(0xFF155888),
      ),
      body: SafeArea(
        child: BlocListener<ItemTransactionsBloc, ItemTransactionsState>(
          listener: (context, state) {
            if (state.status == ItemTransactionsStatus.success) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.successmessage ?? 'Transaction successfully created!',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pop(context); // Go back to list
            }

            if (state.status == ItemTransactionsStatus.error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.error ?? 'Error occurred, please contact vendor!',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: [
                _buildMasterTransactionCard(),
                const SizedBox(height: 16),
                const Divider(thickness: 1),
                const SizedBox(height: 8),
                const Text(
                  'Transaction Items',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ..._transactionItems.map(_buildTransactionItemCard),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildMasterTransactionCard() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Transaction Details',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              CustomTextField(
                labelText: 'Transaction Reference No.',
                value: _transactionNumber?.toString() ?? '',
                onChanged: (v) => _transactionNumber = int.tryParse(v),
                enabled: false, // Auto-generated, not editable
              ),
              const SizedBox(height: 16),
              BlocBuilder<UdcDetailsBloc, UdcDetailsState>(
                builder: (context, state) {
                  final transactionTypes = state.details
                      .where((udc) => udc.udcGroupRef!.udcCode == 'TT')
                      .toList();

                  return CustomDropdown<UdcDetails>(
                    labelText: 'Transaction Type *',
                    value: _selectedTransactionType,
                    items: transactionTypes
                        .map(
                          (udc) => DropdownMenuItem<UdcDetails>(
                            value: udc,
                            child: Text(udc.description1),
                          ),
                        )
                        .toList(),
                    onChanged: _onTransactionTypeChanged,
                    validator: (v) => v == null ? 'Required' : null,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: BlocBuilder<BranchBloc, BranchState>(
                  builder: (context, state) => CustomDropdown<int>(
                    labelText:
                        '${_selectedTransactionType == null || _selectedTransactionType?.detailCode != 'A' ? '' : 'From'} Store *',
                    value: _selectedFromBranch,
                    items: state.branchs
                        .map(
                          (b) => DropdownMenuItem<int>(
                            value: b.id,
                            child: Text(b.description ?? ''),
                          ),
                        )
                        .toList(),
                    onChanged: _onFromBranchChanged,
                    validator: (v) => v == null ? 'Required' : null,
                  ),
                ),
              ),
              if (_selectedTransactionType?.detailCode == 'T') ...[
                const SizedBox(width: 8),
                Expanded(
                  child: BlocBuilder<BranchBloc, BranchState>(
                    builder: (context, state) => CustomDropdown<int>(
                      labelText: 'To Store *',
                      // Ensure value exists in items to avoid "There should be exactly one item with DropdownButton's value" error
                      value:
                          state.branchs.any(
                            (b) =>
                                b.id == _selectedToBranch &&
                                b.id != _selectedFromBranch,
                          )
                          ? _selectedToBranch
                          : null,
                      items: state.branchs
                          .where(
                            (b) => b.id != _selectedFromBranch,
                          ) // Don't allow same branch
                          .map(
                            (b) => DropdownMenuItem<int>(
                              value: b.id,
                              child: Text(b.description ?? ''),
                            ),
                          )
                          .toList(),
                      onChanged: _onToBranchChanged,
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          CustomTextField(
            labelText: 'Remark',
            value: _remark ?? '',
            onChanged: (v) => _remark = v,
            maxLines: 4,
            inputFormatters: [LengthLimitingTextInputFormatter(50)],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItemCard(ItemTransactionModel item) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Iconsax.trash, size: 20, color: Colors.red),
                  onPressed: () => _removeTransactionItem(item),
                  tooltip: 'Remove item',
                ),
              ],
            ),
            _buildItemNumberDropdown(item),

            const SizedBox(height: 16),

            // Location selection (if location management enabled)
            if (_applyLocationMgmt) ...[
              _buildLocationDropdown(item),
              const SizedBox(height: 16),
            ],

            // Lot selection (if lot management enabled)
            if (_applyLotMgmt) ...[
              _buildLotDropdown(item),
              const SizedBox(height: 16),
            ],

            // To Location selection (for transfer transactions with location management)
            if (_selectedTransactionType?.detailCode == 'T' &&
                _applyLocationMgmt) ...[
              _buildToLocationDropdown(item),
              const SizedBox(height: 16),
            ],

            Row(
              children: [
                // Increase/Decrease checkbox for adjustment transactions
                if (_selectedTransactionType?.detailCode == 'A') ...[
                  Column(
                    children: [
                      Checkbox(
                        value: item.adjustToIncrease,
                        onChanged: (v) =>
                            setState(() => item.adjustToIncrease = v ?? true),
                        //when enabled
                        tristate: false,
                        checkColor: Colors.white,
                        activeColor: Color(0xFF155888),
                      ),
                      if (item.adjustToIncrease)
                        const Text('Increase')
                      else
                        const Text('Decrease'),
                      const SizedBox(width: 16),
                    ],
                  ),
                  const SizedBox(width: 16),
                ],

                // Quantity
                Expanded(
                  child: CustomTextField(
                    labelText:
                        '${_selectedTransactionType?.description1 ?? ''} Quantity *',
                    value: item.quantityTransaction.toString(),
                    keyboardType: TextInputType.number,
                    onChanged: (v) =>
                        item.quantityTransaction = double.tryParse(v) ?? 0.0,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final value = double.tryParse(v);
                      if (value == null || value <= 0) {
                        return 'Must be greater than 0';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            BlocBuilder<ItemUomConversionBloc, ItemUomConversionState>(
              builder: (context, state) {
                if (state.isLoadingUomsForItem ||
                    state.status == ItemUomConversionStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final udcList = state.availableUomsForItem;

                if (udcList.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'No unit of measure available',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

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
                      options: udcList.map((u) => u.description1).toList(),
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
                            item.unitOfMeasure = _selectedUom;
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
          ],
        ),
      ),
    );
  }

  Widget _buildItemNumberDropdown(ItemTransactionModel item) {
    return BlocBuilder<StockItemInBranchBloc, ItemInBranchState>(
      builder: (context, state) {
        // Filter items by selected branch
        final branchItems = state.items
            .where((ib) => ib.branch == _selectedFromBranch)
            .toList();

        return CustomDropdown<int>(
          labelText: 'Item Number *',
          value: item.itemNumber,
          items: branchItems
              .map(
                (ib) => DropdownMenuItem<int>(
                  value: ib.itemNumber,
                  child: Text(
                    '${ib.itemNumber} - ${ib.itemRef?.itemDescription}',
                  ),
                ),
              )
              .toList(),
          onChanged: (v) {
            setState(() {
              item.itemNumber = v;
              item.itemLocation = null; // Reset location when item changes
              item.lotNumber = null; // Reset lot when item changes

              // Set limit from Item Branch if no other management is active
              if (v != null) {
                final match = branchItems.where((b) => b.itemNumber == v);
                if (match.isNotEmpty) {
                  item.beforeStoreQuantityAvailable =
                      match.first.quantityAvailable ?? 0.0;
                }
              }
            });

            // Load locations for the selected item (across all branches)
            if (v != null) {
              context.read<StockItemLocationBloc>().add(
                LoadItemLocationsByItemNumber(
                  itemId: v,
                  companyId: widget.authBloc.state.companyId!,
                ),
              );

              // Load lots for the selected item
              if (_selectedFromBranch != null) {
                context.read<LotMasterBloc>().add(
                  FilterLotMasters(itemId: v, branchId: _selectedFromBranch!),
                );
              }
              //load uom for item default from iteminbranch and its conversion from item uom conversion
              context.read<ItemUomConversionBloc>().add(
                LoadUomsForItem(
                  itemId: v,
                  companyId: widget.authBloc.state.companyId!,
                ),
              );
            }
          },
          validator: (v) => v == null ? 'Required' : null,
        );
      },
    );
  }

  Widget _buildLocationDropdown(ItemTransactionModel item) {
    return BlocBuilder<StockItemLocationBloc, ItemLocationsState>(
      builder: (context, state) {
        final locations = state.items
            .where(
              (loc) =>
                  loc.itemNumber == item.itemNumber &&
                  loc.branch == _selectedFromBranch,
            )
            .toList();

        // Find selected location object
        final selectedLocation = locations.firstWhere(
          (loc) => loc.id == item.itemLocation,
          orElse: () => locations.isNotEmpty ? locations.first : ItemLocation(),
        );

        return CustomTableDropdown<ItemLocation>(
          title: 'Location *',
          items: locations,
          displayText: (loc) =>
              loc.locationDescription?.locationDescription ?? 'No Description',
          selectedValue: selectedLocation,
          showSearch: true,
          searchHint: 'Search locations...',
          leadingIcon: Icon(Icons.location_on, size: 16),
          columns: [
            TableColumnConfig(
              header: 'Location',
              flex: 3,
              cellBuilder: (loc) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.locationDescription?.locationDescription ??
                        'No Description',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'ID: ${loc.id}',
                    style: TextStyle(fontSize: 8, color: Colors.grey),
                  ),
                ],
              ),
            ),
            TableColumnConfig(
              header: 'Quantity',
              flex: 2,
              cellBuilder: (loc) => Text(
                '${loc.quantityOnHand ?? 0.0}',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
              ),
            ),
            TableColumnConfig(
              header: 'UOM',
              flex: 1,
              cellBuilder: (loc) => Text(
                loc.itemRef?.unitOfMeasure ?? 'N/A',
                style: TextStyle(fontSize: 10),
              ),
            ),
          ],
          onItemSelected: (selectedLoc) {
            if (selectedLoc != null) {
              setState(() {
                item.itemLocation = selectedLoc.id;
                item.beforeStoreQuantityAvailable =
                    selectedLoc.quantityOnHand ?? 0.0;
              });

              // Load lots for the selected location
              if (item.itemNumber != null && _selectedFromBranch != null) {
                context.read<LotMasterBloc>().add(
                  FilterLotMasters(
                    itemId: item.itemNumber!,
                    branchId: _selectedFromBranch!,
                    locationId: selectedLoc.id,
                  ),
                );
              }
            }
          },
        );
      },
    );
  }

  Widget _buildLotDropdown(ItemTransactionModel item) {
    return BlocBuilder<LotMasterBloc, LotMasterState>(
      builder: (context, state) {
        final lots = state.filteredItems
            .where(
              (lot) =>
                  lot.itemNumber == item.itemNumber &&
                  lot.branch == _selectedFromBranch &&
                  (item.itemLocation == null ||
                      lot.location == item.itemLocation),
            )
            .toList();

        // Find selected lot object
        final selectedLot = lots.firstWhere(
          (lot) => lot.id == item.lotNumber,
          orElse: () => lots.isNotEmpty ? lots.first : LotMaster(),
        );

        return CustomTableDropdown<LotMaster>(
          title: 'Lot *',
          items: lots,
          displayText: (lot) => lot.lotNumber.toString(),
          selectedValue: selectedLot,
          showSearch: true,
          searchHint: 'Search lots...',
          leadingIcon: Icon(Icons.inventory_2, size: 16),
          rowBackgroundColor: (lot, isSelected) =>
              _getColorFromType(lot.tempColorType),
          columns: [
            TableColumnConfig(
              header: 'Lot No',
              flex: 2,
              cellBuilder: (lot) => Text(
                lot.lotNumber.toString(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
            TableColumnConfig(
              header: 'Qty',
              flex: 1,
              cellBuilder: (lot) => Text(
                '${lot.quantityAvailable ?? 0.0}',
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
            ),
            TableColumnConfig(
              header: 'Status',
              flex: 1,
              cellBuilder: (lot) => Text(
                lot.statusDescription?.toString() ?? 'N/A',
                style: const TextStyle(
                  fontSize: 8,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TableColumnConfig(
              header: 'UoM',
              flex: 1,
              cellBuilder: (lot) => Text(
                lot.itemRef?.unitOfMeasureDescription?.detailCode ??
                    lot.itemRef?.unitOfMeasure ??
                    'N/A',
                style: const TextStyle(
                  fontSize: 8,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (selectedLot.dateExpiration != null)
              TableColumnConfig(
                header: 'Expiration',
                flex: 2,
                cellBuilder: (lot) => Text(
                  lot.dateExpiration != null
                      ? _formatDate(lot.dateExpiration!)
                      : '-',
                  style: const TextStyle(
                    fontSize: 9,
                    overflow: TextOverflow.ellipsis,
                    color: Colors.white,
                  ),
                ),
              ),
            if (selectedLot.dateEffective != null)
              TableColumnConfig(
                header: 'Effective',
                flex: 2,
                cellBuilder: (lot) => Text(
                  lot.dateEffective != null
                      ? _formatDate(lot.dateEffective!)
                      : '-',
                  style: const TextStyle(
                    fontSize: 9,
                    overflow: TextOverflow.ellipsis,
                    color: Colors.white,
                  ),
                ),
              ),
            if (selectedLot.dateReceived != null)
              TableColumnConfig(
                header: 'Received',
                flex: 2,
                cellBuilder: (lot) => Text(
                  lot.dateReceived != null
                      ? _formatDate(lot.dateReceived!)
                      : '-',
                  style: const TextStyle(
                    fontSize: 9,
                    overflow: TextOverflow.ellipsis,
                    color: Colors.black,
                  ),
                ),
              ),
          ],
          onItemSelected: (selectedLot) {
            if (selectedLot != null) {
              setState(() {
                item.lotNumber = selectedLot.id;
                item.beforeStoreQuantityAvailable =
                    selectedLot.quantityAvailable ?? 0.0;
              });
            }
          },
        );
      },
    );
  }

  Widget _buildToLocationDropdown(ItemTransactionModel item) {
    return BlocConsumer<StockItemLocationBloc, ItemLocationsState>(
      listener: (context, state) {},
      builder: (context, state) {
        final toLocations = state.items
            .where(
              (loc) =>
                  loc.itemNumber == item.itemNumber &&
                  loc.branch == _selectedToBranch,
            )
            .toList();

        // Find selected to location object (ItemLocation)
        // itemLocationsTo is storing the LocationMaster ID (loc.location)
        final selectedToLocation = toLocations.firstWhere(
          (loc) => loc.location == item.itemLocationsTo,
          orElse: () =>
              toLocations.isNotEmpty ? toLocations.first : ItemLocation(),
        );

        return CustomTableDropdown<ItemLocation>(
          title: 'To Location *',
          items: toLocations,
          displayText: (loc) =>
              loc.locationDescription?.locationDescription ?? 'No Description',
          selectedValue: selectedToLocation,
          showSearch: true,
          searchHint: 'Search to locations...',
          leadingIcon: const Icon(Iconsax.arrow_right_3, size: 16),
          columns: [
            TableColumnConfig(
              header: 'To Location',
              flex: 3,
              cellBuilder: (loc) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.locationDescription?.locationDescription ??
                        'No Description',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Branch: ${loc.branch}', // Or branch name if available
                    style: const TextStyle(fontSize: 8, color: Colors.grey),
                  ),
                ],
              ),
            ),
            TableColumnConfig(
              header: 'Quantity',
              flex: 2,
              cellBuilder: (loc) => Text(
                '${loc.quantityOnHand ?? 0.0}',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
              ),
            ),
            TableColumnConfig(
              header: 'UOM',
              flex: 1,
              cellBuilder: (loc) => Text(
                loc.itemRef?.unitOfMeasure ?? 'N/A',
                style: TextStyle(fontSize: 10),
              ),
            ),
          ],
          onItemSelected: (selectedLoc) {
            if (selectedLoc != null) {
              setState(() => item.itemLocationsTo = selectedLoc.location);
            }
          },
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _cancelCreate,
                icon: const Icon(Iconsax.close_circle),
                label: const Text('Cancel'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _applyTransactions,
                icon: const Icon(Iconsax.tick_circle),
                label: const Text('Apply'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF155888),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  Color _getColorFromType(LotExpirationColor? color) {
    if (color == null) return Colors.transparent;

    final code = (color.colorTypeCode ?? '').trim().toUpperCase();
    final name = (color.colorTypeName ?? '').trim().toLowerCase();

    const double opacity = 0.8;

    if (code == '01' || name.contains('red')) {
      return Colors.red.withOpacity(opacity);
    }
    if (code == '11' || name.contains('blue')) {
      return Colors.blue.withOpacity(opacity);
    }
    if (code == '04' || name.contains('green')) {
      return Colors.green.withOpacity(opacity);
    }
    if (code == '07' || name.contains('yellow')) {
      return Colors.yellow.withOpacity(opacity);
    }
    if (code == '02' || name.contains('orange')) {
      return Colors.orange.withOpacity(opacity);
    }
    if (code == '16' || name.contains('black')) {
      return Colors.black.withOpacity(opacity);
    }
    if (code == '03' || name.contains('grey')) {
      return Colors.grey.withOpacity(opacity);
    }
    if (code == '08' || name.contains('purple')) {
      return Colors.purple.withOpacity(opacity);
    }
    if (code == '06' || name.contains('olive')) {
      return const Color.fromARGB(255, 14, 90, 4).withOpacity(opacity);
    }
    if (code == '05' || name.contains('lime')) {
      return Colors.lime.withOpacity(opacity);
    }

    return Colors.transparent;
  }
}
