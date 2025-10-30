import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:savvy_stock/core/blocs/system_constant/system_constant_bloc.dart';
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
import 'package:savvy_stock/features/stock/item_in_branch/models/item_in_branch_model.dart';
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

      // Load transaction type
      if (transaction.transactionType != null) {
        final udcBloc = context.read<UdcDetailsBloc>();
        final transactionType = udcBloc.state.details.firstWhere(
          (udc) => udc.id == transaction.transactionType,
          orElse: () => UdcDetails.empty(),
        );
        if (transactionType.id != null) {
          _selectedTransactionType = transactionType;
        }
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
    context.read<ItemTransactionsBloc>().stream.listen((state) {
      if (state.selected?.lotNumber != null) {
        _transactionNumber = state.selected!.transactionNumber;
      }
    });
    print('Transaction number: $_transactionNumber');
  }

  void _onTransactionTypeChanged(UdcDetails? transactionType) {
    setState(() {
      _selectedTransactionType = transactionType;
      // Reset to branch when transaction type changes (unless it's transfer)
      if (transactionType?.detailCode != 'T') {
        _selectedToBranch = null;
      }
    });
  }

  void _onFromBranchChanged(int? branchId) {
    setState(() {
      _selectedFromBranch = branchId;
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
    });
  }

  void _addNewTransactionItem() {
    setState(() {
      _transactionItems.add(
        ItemTransactionModel(
          tempId: DateTime.now().millisecondsSinceEpoch,
          company: widget.authBloc.state.companyId,
          dateCreated: DateTime.now(),
          quantityTransaction: 0.0,
          beforeStoreQuantityAvailable: 0.0,
          unitCost: 0.0,
          amountCost: 0.0,
          beforeAmountCost: 0.0,
          adjustToIncrease: true, // Default to increase for adjustments
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
      remark: _remark,
      company: widget.authBloc.state.companyId,
      dateCreated: DateTime.now(),
      quantityTransaction: 0.0, // Not used for master
      beforeStoreQuantityAvailable: 0.0,
      unitCost: 0.0,
      amountCost: 0.0,
      beforeAmountCost: 0.0,
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
        actions: [
          IconButton(
            icon: const Icon(Iconsax.tick_circle),
            onPressed: _applyTransactions,
            tooltip: 'Apply',
          ),
        ],
      ),
      body: BlocListener<ItemTransactionsBloc, ItemTransactionsState>(
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
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  labelText: 'Transaction Reference No.',
                  value: _transactionNumber?.toString() ?? '',
                  onChanged: (v) => _transactionNumber = int.tryParse(v),
                  enabled: false, // Auto-generated, not editable
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: BlocBuilder<UdcDetailsBloc, UdcDetailsState>(
                  builder: (context, state) {
                    final transactionTypes = state.details
                        .where((udc) => udc.udcGroup == 'TT')
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
              if (_selectedTransactionType?.detailCode == 'SALE') ...[
                const SizedBox(width: 16),
                Expanded(
                  child: BlocBuilder<BranchBloc, BranchState>(
                    builder: (context, state) => CustomDropdown<int>(
                      labelText: 'To Store *',
                      value: _selectedToBranch,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _buildItemNumberDropdown(item)),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Iconsax.trash, size: 20, color: Colors.red),
                  onPressed: () => _removeTransactionItem(item),
                  tooltip: 'Remove item',
                ),
              ],
            ),
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
                  Expanded(
                    child: Row(
                      children: [
                        Checkbox(
                          value: item.adjustToIncrease,
                          onChanged: (v) =>
                              setState(() => item.adjustToIncrease = v ?? true),
                        ),
                        const Text('Increase'),
                        const SizedBox(width: 16),
                        const Text('Decrease'),
                      ],
                    ),
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
                      if (value == null || value <= 0)
                        return 'Must be greater than 0';
                      return null;
                    },
                  ),
                ),

                const SizedBox(width: 16),

                // Unit of Measure
                Expanded(
                  child: BlocBuilder<UdcDetailsBloc, UdcDetailsState>(
                    builder: (context, state) {
                      final uomList = state.details
                          .where((udc) => udc.udcGroup == 'UM')
                          .toList();

                      return CustomDropdown<int>(
                        labelText: 'UoM *',
                        value: item.unitOfMeasure,
                        items: uomList
                            .map(
                              (udc) => DropdownMenuItem<int>(
                                value: udc.id,
                                child: Text(udc.description1),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => item.unitOfMeasure = v),
                        validator: (v) => v == null ? 'Required' : null,
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemNumberDropdown(ItemTransactionModel item) {
    return BlocBuilder<ItemTransactionsBloc, ItemTransactionsState>(
      builder: (context, state) {
        return CustomTableDropdown<ItemInBranchModel>(
          title: 'Item Number',
          items: state.availableItems,
          displayText: (itemBranch) =>
              '${itemBranch.itemNumber} - ${_getItemDescription(itemBranch.itemNumber)}',
          columns: [
            TableColumnConfig<ItemInBranchModel>(
              header: 'Item',
              flex: 3,
              cellBuilder: (itemBranch) => Text(
                _getItemDescription(itemBranch.itemNumber),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TableColumnConfig<ItemInBranchModel>(
              header: 'Available',
              flex: 2,
              cellBuilder: (itemBranch) => Text(
                '${itemBranch.quantityAvailable?.toStringAsFixed(2) ?? '0.00'}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TableColumnConfig<ItemInBranchModel>(
              header: 'UoM',
              flex: 1,
              cellBuilder: (itemBranch) => Text(
                state.uomDescriptions[itemBranch.unitOfMeasure] ?? 'Loading...',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          onItemSelected: (selectedItemBranch) {
            // Dispatch event instead of handling business logic
            context.read<ItemTransactionsBloc>().add(
              SelectItem(selectedItemBranch?.itemNumber, _selectedFromBranch!),
            );

            // Load UoM description if needed
            if (selectedItemBranch?.unitOfMeasure != null) {
              context.read<ItemTransactionsBloc>().add(
                LoadUoMDescription(selectedItemBranch!.unitOfMeasure!),
              );
            }
          },
          expandedHeight: 200,
          emptyText: 'Select Item',
          selectedValue: state.availableItems.firstWhere(
            (ib) => ib.itemNumber == item.itemNumber,
            orElse: () => ItemInBranchModel.empty(),
          ),
        );
      },
    );
  }

  Widget _buildLocationDropdown(ItemTransactionModel item) {
    return BlocBuilder<ItemTransactionsBloc, ItemTransactionsState>(
      builder: (context, state) {
        return CustomDropdown<int>(
          labelText: 'Location *',
          value: item.itemLocation,
          items: state.availableLocations
              .map(
                (loc) => DropdownMenuItem<int>(
                  value: loc.id,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(loc.location.toString()),
                      Text(
                        'Qty: ${loc.quantityOnHand ?? 0.0}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: (v) {
            setState(() => item.itemLocation = v);

            // Load lots for the selected location
            if (item.itemNumber != null && _selectedFromBranch != null) {
              context.read<LotMasterBloc>().add(
                FilterLotMasters(
                  itemId: item.itemNumber!,
                  branchId: _selectedFromBranch!,
                  locationId: v,
                ),
              );
            }
          },
          validator: (v) => v == null ? 'Required' : null,
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

        return CustomDropdown<int>(
          labelText: 'Lot *',
          value: item.lotNumber,
          items: lots
              .map(
                (lot) => DropdownMenuItem<int>(
                  value: lot.id,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Lot: ${lot.lotNumber}'),
                      Text(
                        'Qty: ${lot.quantityAvailable ?? 0.0}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        'Status: ${lot.lotStatus ?? 'NaN'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      if (lot.dateExpiration != null)
                        Text(
                          'Exp: ${_formatDate(lot.dateExpiration!)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => item.lotNumber = v),
          validator: (v) => v == null ? 'Required' : null,
        );
      },
    );
  }

  Widget _buildToLocationDropdown(ItemTransactionModel item) {
    return BlocBuilder<StockItemLocationBloc, ItemLocationsState>(
      builder: (context, state) {
        final toLocations = state.items
            .where(
              (loc) =>
                  loc.itemNumber == item.itemNumber &&
                  loc.branch == _selectedToBranch,
            )
            .toList();

        return CustomDropdown<int>(
          labelText: 'To Location *',
          value: item.itemLocationsTo,
          items: toLocations
              .map(
                (loc) => DropdownMenuItem<int>(
                  value: loc.id,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(loc.location?.toString() ?? 'NaN'),
                      Text(
                        'Qty: ${loc.quantityOnHand ?? 0.0}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => item.itemLocationsTo = v),
          validator: (v) => v == null ? 'Required' : null,
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _addNewTransactionItem,
              icon: const Icon(Iconsax.add),
              label: const Text('Add New Item'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF155888),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 16),
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
        ],
      ),
    );
  }

  // Helper methods
  String _getItemDescription(int? itemNumber) {
    // This would typically come from your items bloc

    return '';
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
