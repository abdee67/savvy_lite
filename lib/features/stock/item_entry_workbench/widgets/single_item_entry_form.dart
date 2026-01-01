import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_bloc.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_event.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_state.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_bloc.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_event.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_state.dart';
import 'package:savvy_stock/core/widgets/custom_dropdown.dart';
import 'package:savvy_stock/core/widgets/custom_searchable_dropdown.dart';
import 'package:savvy_stock/core/widgets/custom_text_form.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/branch_list/blocs/branch_list_bloc.dart';
import 'package:savvy_stock/features/branch_list/blocs/branch_list_event.dart';
import 'package:savvy_stock/features/branch_list/blocs/branch_list_state.dart';
import 'package:savvy_stock/features/stock/item_entry_workbench/blocs/item_master_bloc.dart';
import 'package:savvy_stock/features/stock/item_entry_workbench/blocs/item_master_events.dart';
import 'package:savvy_stock/features/stock/item_entry_workbench/blocs/item_master_state.dart';
import 'package:savvy_stock/features/stock/item_entry_workbench/models/item_master_model.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_bloc.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_event.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_state.dart';
import 'package:savvy_stock/features/udc_detail/models/udc_details.dart';
import 'package:dropdown_search/dropdown_search.dart';

class SingleItemEntryForm extends StatefulWidget {
  final AuthBloc authBloc;
  const SingleItemEntryForm({super.key, required this.authBloc});

  @override
  State<SingleItemEntryForm> createState() => _SingleItemEntryFormState();
}

class _SingleItemEntryFormState extends State<SingleItemEntryForm> {
  final List<ItemMaster> _items = [ItemMaster(itemDescription: '')];
  final _formKey = GlobalKey<FormState>();
  final dropDownKey = GlobalKey<DropdownSearchState>();

  // Date controllers
  final TextEditingController _effectiveDateController =
      TextEditingController();
  final TextEditingController _expirationDateController =
      TextEditingController();
  final TextEditingController _receivedDateController = TextEditingController();

  DateTime? _effectiveDate;
  DateTime? _expirationDate;
  DateTime? _receivedDate;

  String? _selectedItem;

  @override
  void initState() {
    super.initState();
    // Load necessary data
    _loadInitialData();
    _updateDateControllers();
  }

  void _loadInitialData() {
    final authState = widget.authBloc.state;
    if (authState.isAuthenticated) {
      // Load branches
      context.read<BranchBloc>().add(
        LoadBranchs(widget.authBloc.state.companyId!),
      );

      // Load UoM
      context.read<UdcDetailsBloc>().add(LoadUdcDetailsByGroup('UM'));

      // Load system constants
      context.read<SystemConstantBloc>().add(
        LoadSystemConstants(widget.authBloc.state.companyId!),
      );

      // Load items table
      context.read<StockItemsEntryBloc>().add(
        LoadItems(widget.authBloc.state.companyId!),
      );

      context.read<ItemMasterBloc>().add(
        LoadItemMasters(widget.authBloc.state.companyId),
      );
    }
  }

  void _addNewItem() {
    setState(() {
      _items.add(ItemMaster(itemDescription: ''));
    });
  }

  void _removeItem(int index) {
    if (_items.length > 1) {
      setState(() {
        _items.removeAt(index);
      });
    } else {
      // Clear the only item instead of removing
      setState(() {
        _items[0] = ItemMaster(itemDescription: '');
      });
    }
  }

  void _saveItem(int index) {
    if (_formKey.currentState!.validate()) {
      final item = _items[index];
      context.read<ItemMasterBloc>().add(ApplyMigration(item));
    }
  }

  void _resetForm() {
    setState(() {
      _items.clear();
      _items.add(ItemMaster(itemDescription: ''));
      _effectiveDate = null;
      _expirationDate = null;
      _receivedDate = null;
      _selectedItem = null;
      _updateDateControllers();
    });
  }

  void _onItemDescriptionChanged(int index, String value) {
    setState(() {
      _items[index] = _items[index].copyWith(itemDescription: value);
    });

    // Auto-fill defaults if item description exists
    if (value.isNotEmpty) {
      context.read<ItemMasterBloc>().add(SettingDefaults(_items[index]));
    }
  }

  void _updateDateControllers() {
    _effectiveDateController.text = _effectiveDate != null
        ? '${_effectiveDate!.month.toString().padLeft(2, '0')}/${_effectiveDate!.day.toString().padLeft(2, '0')}/${_effectiveDate!.year}'
        : '';

    _expirationDateController.text = _expirationDate != null
        ? '${_expirationDate!.month.toString().padLeft(2, '0')}/${_expirationDate!.day.toString().padLeft(2, '0')}/${_expirationDate!.year}'
        : '';

    _receivedDateController.text = _receivedDate != null
        ? '${_receivedDate!.month.toString().padLeft(2, '0')}/${_receivedDate!.day.toString().padLeft(2, '0')}/${_receivedDate!.year}'
        : '';
  }

  void _selectEffectiveDate(int index) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _effectiveDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _effectiveDate = picked;
        // Map to migration field used by MigrationService
        _items[index] = _items[index].copyWith(dateExpired: picked);
        _updateDateControllers();
      });
    }
  }

  void _selectExpirationDate(int index) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _expirationDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _expirationDate = picked;
        // Map to migration field used by MigrationService
        _items[index] = _items[index].copyWith(dateExpired: picked);
        _updateDateControllers();
      });
    }
  }

  void _selectReceivedDate(int index) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _receivedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _receivedDate = picked;
        // Map to migration field used by MigrationService
        _items[index] = _items[index].copyWith(dateExpired: picked);
        _updateDateControllers();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ItemMasterBloc, ItemMasterState>(
      listener: (context, state) {
        if (state.status == ItemMasterStatus.success) {
          _resetForm();
          // The message is already shown by BlocConsumer in the parent or should be here
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message ?? 'Item saved successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state.status == ItemMasterStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message ?? 'Failed to save item'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Column(
        children: [
          // Header with Add button
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Item Entries',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF155888),
                  ),
                ),
              ],
            ),
          ),

          // Items List
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView.builder(
                itemCount: _items.length,
                itemBuilder: (context, index) => _buildItemCard(index),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(int index) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with delete button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Item ${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF155888),
                  ),
                ),
                if (_items.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeItem(index),
                    tooltip: 'Remove Item',
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Form Fields
            _buildItemForm(index),

            // Save Button
            const SizedBox(height: 16),
            BlocBuilder<ItemMasterBloc, ItemMasterState>(
              builder: (context, state) {
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: state.status == ItemMasterStatus.migrating
                        ? null
                        : () => _saveItem(index),
                    icon: state.status == ItemMasterStatus.migrating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Icon(Icons.save, size: 20),
                    label: Text(
                      state.status == ItemMasterStatus.migrating
                          ? 'Saving...'
                          : 'Save Item',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF155888),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemForm(int index) {
    return Column(
      children: [
        // Item Description with Autocomplete
        _buildItemDescriptionField(index),
        const SizedBox(height: 16),

        // Store Dropdown
        _buildStoreField(index),
        const SizedBox(height: 16),

        // UoM Dropdown
        _buildUomField(index),
        const SizedBox(height: 16),

        // Taxable Checkbox
        _buildTaxableField(index),
        const SizedBox(height: 16),

        // Price and Cost
        Row(
          children: [
            Expanded(child: _buildUnitPriceField(index)),
            const SizedBox(width: 16),
            Expanded(child: _buildUnitCostField(index)),
          ],
        ),
        const SizedBox(height: 16),

        // Location Fields
        _buildLocationFields(index),
        const SizedBox(height: 16),

        // Quantity
        _buildQuantityField(index),
        const SizedBox(height: 16),

        // Lot Management Fields (conditionally shown)
        BlocBuilder<SystemConstantBloc, SystemConstantState>(
          builder: (context, state) {
            if (state.selected?.applyLotMgmBoolean == true) {
              return Column(
                children: [
                  _buildDateField(index),
                  const SizedBox(height: 16),
                  _buildBatchNumberField(index),
                  const SizedBox(height: 16),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildItemDescriptionField(int index) {
    return BlocBuilder<ItemMasterBloc, ItemMasterState>(
      builder: (context, masterState) {
        return BlocBuilder<StockItemsEntryBloc, ItemEntryState>(
          builder: (context, entryState) {
            if (masterState.status == ItemMasterStatus.loading ||
                entryState.status == ItemEntryStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            // Combine descriptions from both sources
            final Set<String> descriptions = {};

            // Add from ItemMaster (Workbench)
            for (var item in masterState.items) {
              if (item.itemDescription != null &&
                  item.itemDescription!.isNotEmpty) {
                descriptions.add(item.itemDescription!);
              }
            }

            // Add from ItemEntry (Main Items table)
            for (var item in entryState.items) {
              if (item.itemDescription != null &&
                  item.itemDescription!.isNotEmpty) {
                descriptions.add(item.itemDescription!);
              }
            }

            final sortedDescriptions = descriptions.toList()..sort();

            return CustomSearchableDropdown(
              labelText: 'Item Description',
              options: sortedDescriptions,
              value: _items[index].itemDescription,
              onChanged: (value) {
                setState(() {
                  _items[index] = _items[index].copyWith(
                    itemDescription: value,
                  );
                });
                print('Selected: $value');
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select or enter an item description';
                }
                return null;
              },
              prefixIcon: Icons.description,
              allowCustomEntries: true,
            );
          },
        );
      },
    );
  }

  Widget _buildStoreField(int index) {
    return BlocBuilder<BranchBloc, BranchState>(
      builder: (context, state) {
        if (state.status == BranchStatus.loading) {
          return const CustomDropdown(
            labelText: 'Store *',
            items: [],
            prefixIcon: Icon(Icons.store),
            enabled: false,
            hintText: 'Loading stores...',
          );
        }

        final branches = state.branchs;
        return CustomDropdown(
          labelText: 'Store *',
          prefixIcon: const Icon(Icons.store),
          value: _items[index].branch?.toString(),
          items: branches.map((branch) {
            return DropdownMenuItem(
              value: branch.id.toString(),
              child: Text(branch.description ?? 'Unknown'),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _items[index] = _items[index].copyWith(branch: int.parse(value!));
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Store is required';
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildUomField(int index) {
    return BlocBuilder<UdcDetailsBloc, UdcDetailsState>(
      builder: (context, state) {
        if (state.status == UdcDetailsStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.details.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'No unit of measure available',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }
        final udcList = state.details.toList();
        if (udcList.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'No valid unit of measure found',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return Builder(
          builder: (context) {
            String? currentUomDesc;
            final selectedUomId = _items[index].defualtUom;
            if (selectedUomId != null) {
              final match = udcList.where((u) => u.id == selectedUomId);
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
                    _items[index] = _items[index].copyWith(defualtUom: null);
                  } else {
                    final matches = udcList.where(
                      (u) => u.description1 == value,
                    );
                    final selected = matches.isNotEmpty ? matches.first : null;
                    _items[index] = _items[index].copyWith(
                      defualtUom: selected?.id,
                    );
                  }
                });
              },
              validator: (value) {
                if (_items[index].defualtUom == null) {
                  return 'Please select a unit of measure';
                }
                return null;
              },
            );
          },
        );
      },
    );
  }

  Widget _buildTaxableField(int index) {
    return Row(
      children: [
        Checkbox(
          value: _items[index].taxableFlag == 'Y',
          onChanged: (value) {
            setState(() {
              _items[index] = _items[index].copyWith(
                taxableFlag: value == true ? 'Y' : 'N',
              );
            });
          },
        ),
        const SizedBox(width: 8),
        const Text('Taxable'),
      ],
    );
  }

  Widget _buildUnitPriceField(int index) {
    return CustomTextField(
      labelText: 'Unit Price',
      value: _items[index].unitPrice?.toString(),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (value) {
        setState(() {
          _items[index] = _items[index].copyWith(
            unitPrice: double.tryParse(value),
          );
        });
      },
      prefixIcon: const Icon(Icons.attach_money),
    );
  }

  Widget _buildUnitCostField(int index) {
    return CustomTextField(
      labelText: 'Unit Cost',
      value: _items[index].unitCost?.toString(),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (value) {
        setState(() {
          _items[index] = _items[index].copyWith(
            unitCost: double.tryParse(value),
          );
        });
      },
      prefixIcon: const Icon(Icons.money_off),
    );
  }

  Widget _buildLocationFields(int index) {
    return BlocBuilder<SystemConstantBloc, SystemConstantState>(
      builder: (context, state) {
        final level = state.selected?.locationCategoryLevel ?? 1;
        final locationFields = <Widget>[];

        for (int i = 1; i <= level; i++) {
          if (i <= 10) {
            // Maximum 10 location fields as per table
            locationFields.addAll([
              _buildLocationField(index, i),
              if (i < level) const SizedBox(height: 16),
            ]);
          }
        }

        return Column(children: locationFields);
      },
    );
  }

  Widget _buildLocationField(int index, int locationNumber) {
    String? locationValue;
    switch (locationNumber) {
      case 1:
        locationValue = _items[index].locationCode1;
        break;
      case 2:
        locationValue = _items[index].locationCode2;
        break;
      case 3:
        locationValue = _items[index].locationCode3;
        break;
      case 4:
        locationValue = _items[index].locationCode4;
        break;
      case 5:
        locationValue = _items[index].locationCode5;
        break;
      case 6:
        locationValue = _items[index].locationCode6;
        break;
      case 7:
        locationValue = _items[index].locationCode7;
        break;
      case 8:
        locationValue = _items[index].locationCode8;
        break;
      case 9:
        locationValue = _items[index].locationCode9;
        break;
      case 10:
        locationValue = _items[index].locationCode10;
        break;
    }

    return CustomTextField(
      labelText: 'Location $locationNumber *',
      value: locationValue,
      onChanged: (value) {
        setState(() {
          switch (locationNumber) {
            case 1:
              _items[index] = _items[index].copyWith(locationCode1: value);
              break;
            case 2:
              _items[index] = _items[index].copyWith(locationCode2: value);
              break;
            case 3:
              _items[index] = _items[index].copyWith(locationCode3: value);
              break;
            case 4:
              _items[index] = _items[index].copyWith(locationCode4: value);
              break;
            case 5:
              _items[index] = _items[index].copyWith(locationCode5: value);
              break;
            case 6:
              _items[index] = _items[index].copyWith(locationCode6: value);
              break;
            case 7:
              _items[index] = _items[index].copyWith(locationCode7: value);
              break;
            case 8:
              _items[index] = _items[index].copyWith(locationCode8: value);
              break;
            case 9:
              _items[index] = _items[index].copyWith(locationCode9: value);
              break;
            case 10:
              _items[index] = _items[index].copyWith(locationCode10: value);
              break;
          }
        });
      },
      prefixIcon: const Icon(Icons.location_on),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Location $locationNumber is required';
        }
        return null;
      },
    );
  }

  Widget _buildQuantityField(int index) {
    return CustomTextField(
      labelText: 'Quantity *',
      value: _items[index].quantity?.toString(),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (value) {
        setState(() {
          _items[index] = _items[index].copyWith(
            quantity: double.tryParse(value),
          );
        });
      },
      prefixIcon: const Icon(Icons.inventory),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Quantity is required';
        }
        if (double.tryParse(value) == null) {
          return 'Please enter a valid number';
        }
        return null;
      },
    );
  }

  Widget _buildDateField(int index) {
    // Date fields shown based on system constant lot type
    return BlocBuilder<SystemConstantBloc, SystemConstantState>(
      builder: (context, sysState) {
        final lotTypeId = sysState.selected?.lotType;
        final udcState = context.watch<UdcDetailsBloc>().state;
        UdcDetails? lotTypeUdc;
        if (lotTypeId != null) {
          final matches = udcState.details.where((d) => d.id == lotTypeId);
          if (matches.isNotEmpty) lotTypeUdc = matches.first;
        }
        final lotTypeCode = lotTypeUdc?.detailCode.toUpperCase();

        // If lot type is Effective (F) -> show only Effective Date
        if (lotTypeCode == 'F') {
          return Column(
            children: [
              CustomTextField(
                labelText: 'Effective Date *',
                controller: _effectiveDateController,
                readOnly: true,
                prefixIcon: const Icon(Iconsax.calendar_1),
                suffixIcon: IconButton(
                  icon: const Icon(Iconsax.calendar),
                  onPressed: () => _selectEffectiveDate(index),
                ),
                onTap: () => _selectEffectiveDate(index),
              ),
              const SizedBox(height: 16),
            ],
          );
        }

        // If lot type is Expiration (X) -> show only Expiration Date
        if (lotTypeCode == 'X') {
          return Column(
            children: [
              CustomTextField(
                labelText: 'Expiration Date *',
                controller: _expirationDateController,
                readOnly: true,
                prefixIcon: const Icon(Iconsax.calendar_tick),
                suffixIcon: IconButton(
                  icon: const Icon(Iconsax.calendar),
                  onPressed: () => _selectExpirationDate(index),
                ),
                onTap: () => _selectExpirationDate(index),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Expiration date is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
            ],
          );
        }

        // If lot type is Receipt (R) -> show only Received Date
        if (lotTypeCode == 'R') {
          return Column(
            children: [
              CustomTextField(
                labelText: 'Received Date *',
                controller: _receivedDateController,
                readOnly: true,
                prefixIcon: const Icon(Iconsax.calendar),
                suffixIcon: IconButton(
                  icon: const Icon(Iconsax.calendar),
                  onPressed: () => _selectReceivedDate(index),
                ),
                onTap: () => _selectReceivedDate(index),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Received date is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
            ],
          );
        }
        // Default: show Effective and Expiration
        return CustomTextField(
          labelText: 'Expiration Date *',
          controller: _expirationDateController,
          readOnly: true,
          prefixIcon: const Icon(Iconsax.calendar_tick),
          suffixIcon: IconButton(
            icon: const Icon(Iconsax.calendar),
            onPressed: () => _selectExpirationDate(index),
          ),
          onTap: () => _selectExpirationDate(index),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Expiration date is required';
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildBatchNumberField(int index) {
    return CustomTextField(
      labelText: 'Batch Number',
      value: _items[index].batchNumber,
      onChanged: (value) {
        setState(() {
          _items[index] = _items[index].copyWith(batchNumber: value);
        });
      },
      prefixIcon: const Icon(Icons.confirmation_number),
    );
  }

  Future<void> _selectDate(BuildContext context, int index) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _items[index] = _items[index].copyWith(dateExpired: picked);
      });
    }
  }
}
