import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:savvy_stock/features/branch_list/blocs/branch_list_bloc.dart';
import 'package:savvy_stock/features/branch_list/blocs/branch_list_state.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_bloc.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_state.dart';
import 'package:savvy_stock/features/stock/location_entry/blocs/location_master_bloc.dart';
import 'package:savvy_stock/features/stock/location_entry/blocs/location_master_state.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_bloc.dart';
import 'package:savvy_stock/features/stock/lot_master/models/lot_availability_filters.dart';
import 'package:intl/intl.dart';
import 'package:savvy_stock/core/widgets/custom_searchable_dropdown.dart';

class AvailableLotFilterDialog extends StatefulWidget {
  final LotAvailabilityFilters currentFilters;
  final Function(LotAvailabilityFilters) onApply;
  final Function() onClear;

  const AvailableLotFilterDialog({
    super.key,
    required this.currentFilters,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<AvailableLotFilterDialog> createState() =>
      _AvailableLotFilterDialogState();
}

class _AvailableLotFilterDialogState extends State<AvailableLotFilterDialog> {
  late LotAvailabilityFilters _filters;
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');

  final List<String> _dateFilterOptions = [
    'All',
    'Range',
    'Days Left',
    'Years',
    'Expired',
  ];

  @override
  void initState() {
    super.initState();
    _filters = widget.currentFilters;
  }

  void _updateFilter(LotAvailabilityFilters newFilters) {
    setState(() {
      _filters = newFilters;
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_filters.startDateForFilter ?? DateTime.now())
          : (_filters.endDateForFilter ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      if (isStart) {
        _updateFilter(_filters.copyWith(startDateForFilter: picked));
      } else {
        _updateFilter(_filters.copyWith(endDateForFilter: picked));
      }
    }
  }

  String _getSystemLotTypeHeader() {
    final sysState = context.read<SystemConstantBloc>().state;
    final sysConst = sysState.systemConstants.isNotEmpty
        ? sysState.systemConstants.first
        : null;
    final lotTypeCode = sysConst?.lotTypeRef?.detailCode;

    if (lotTypeCode == null || lotTypeCode == 'X') {
      return 'Expiration';
    } else if (lotTypeCode == 'R') {
      return 'Received';
    } else if (lotTypeCode == 'F') {
      return 'Effective';
    }
    return 'Lot Information';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        //  maxHeight: MediaQuery.of(context).size.height * 0.9,
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGeneralFilters(),
                    const SizedBox(height: 24),
                    _buildDateFilters(),
                  ],
                ),
              ),
            ),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Filter Options',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlocBuilder<StockItemsEntryBloc, ItemEntryState>(
          builder: (context, state) {
            return _buildDropdown<int>(
              label: 'Item',
              value: _filters.itemNumber,
              items: state.items.map((e) {
                return DropdownMenuItem(
                  value: e.id,
                  child: Text(e.itemDescription ?? 'Unknown Item'),
                );
              }).toList(),
              onChanged: (val) =>
                  _updateFilter(_filters.copyWith(itemNumber: val)),
            );
          },
        ),
        const SizedBox(height: 16),
        BlocBuilder<BranchBloc, BranchState>(
          builder: (context, state) {
            return _buildDropdown<int>(
              label: 'Branch/Store',
              value: _filters.branch,
              items: state.branchs.map((e) {
                return DropdownMenuItem(
                  value: e.id,
                  child: Text(e.description ?? 'Unknown Branch'),
                );
              }).toList(),
              onChanged: (val) => _updateFilter(_filters.copyWith(branch: val)),
            );
          },
        ),
        const SizedBox(height: 16),
        BlocBuilder<LocationMasterBloc, LocationMasterState>(
          builder: (context, state) {
            return _buildDropdown<int>(
              label: 'Location',
              value: _filters.locationId,
              items: state.locations.map((e) {
                return DropdownMenuItem(
                  value: e.id,
                  child: Text(e.locationDescription ?? 'Unknown Location'),
                );
              }).toList(),
              onChanged: (val) =>
                  _updateFilter(_filters.copyWith(locationId: val)),
            );
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _filters.batchNumberSupplier,
          decoration: const InputDecoration(
            labelText: 'Batch',
            border: OutlineInputBorder(),
          ),
          onChanged: (val) =>
              _updateFilter(_filters.copyWith(batchNumberSupplier: val)),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Zero/No Availability'),
          value: _filters.noAvailability,
          onChanged: (val) =>
              _updateFilter(_filters.copyWith(noAvailability: val)),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildDateFilters() {
    final headerType = _getSystemLotTypeHeader();
    String currentType = 'All';
    if (_filters.selectFilterDates == 'RANGE') currentType = 'Range';
    if (_filters.selectFilterDates == 'DAYS') currentType = 'Days Left';
    if (_filters.selectFilterDates == 'YEARS') currentType = 'Years';
    if (_filters.selectFilterDates == 'EXPIRED') currentType = 'Expired';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              headerType,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Divider(),
            const SizedBox(height: 8),
            const Text('Select Filter Type:'),
            Wrap(
              spacing: 8,
              children: _dateFilterOptions.map((option) {
                return ChoiceChip(
                  label: Text(option),
                  selected: currentType == option,
                  onSelected: (selected) {
                    if (selected) {
                      String? backendType;
                      if (option == 'All') backendType = 'ALL';
                      if (option == 'Range') backendType = 'RANGE';
                      if (option == 'Days Left') backendType = 'DAYS';
                      if (option == 'Years') backendType = 'YEARS';
                      if (option == 'Expired') backendType = 'EXPIRED';
                      _updateFilter(
                        _filters.copyWith(selectFilterDates: backendType),
                      );
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            if (currentType == 'Range') _buildRangeFilter(),
            if (currentType == 'Days Left') _buildDaysFilter(),
            if (currentType == 'Years') _buildYearsFilter(),
          ],
        ),
      ),
    );
  }

  Widget _buildRangeFilter() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => _selectDate(context, true),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Start Date',
                border: OutlineInputBorder(),
              ),
              child: Text(
                _filters.startDateForFilter != null
                    ? _dateFormat.format(_filters.startDateForFilter!)
                    : 'Select Date',
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: InkWell(
            onTap: () => _selectDate(context, false),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'End Date',
                border: OutlineInputBorder(),
              ),
              child: Text(
                _filters.endDateForFilter != null
                    ? _dateFormat.format(_filters.endDateForFilter!)
                    : 'Select Date',
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDaysFilter() {
    return _buildDropdown<String>(
      label: 'Days Left',
      value: _filters.minDays != null && _filters.maxDays != null
          ? '\${_filters.minDays}-\${_filters.maxDays}'
          : null,
      items: const [
        DropdownMenuItem(value: null, child: Text('--Select One--')),
        DropdownMenuItem(value: '0-7', child: Text('Within 7 Days')),
        DropdownMenuItem(value: '0-15', child: Text('Within 15 Days')),
        DropdownMenuItem(
          value: '0-30',
          child: Text('Within 30 Days (1 Month)'),
        ),
        DropdownMenuItem(
          value: '0-60',
          child: Text('Within 60 Days (2 Months)'),
        ),
        DropdownMenuItem(
          value: '0-90',
          child: Text('Within 90 Days (3 Months)'),
        ),
        DropdownMenuItem(
          value: '0-120',
          child: Text('Within 120 Days (4 Months)'),
        ),
        DropdownMenuItem(
          value: '0-150',
          child: Text('Within 150 Days (5 Months)'),
        ),
        DropdownMenuItem(
          value: '0-180',
          child: Text('Within 180 Days (6 Months)'),
        ),
        DropdownMenuItem(
          value: '0-210',
          child: Text('Within 210 Days (7 Months)'),
        ),
        DropdownMenuItem(value: '0-365', child: Text('Within 1 Year')),
        DropdownMenuItem(value: '0-730', child: Text('Within 2 Years')),
        DropdownMenuItem(value: '0-1825', child: Text('Within 5 Years')),
        DropdownMenuItem(value: '8-15', child: Text('8 to 15 Days')),
        DropdownMenuItem(
          value: '16-30',
          child: Text('16 to 30 Days (1 Month)'),
        ),
        DropdownMenuItem(
          value: '30-60',
          child: Text('30 to 60 Days (2 Months)'),
        ),
        DropdownMenuItem(
          value: '60-90',
          child: Text('60 to 90 Days (3 Months)'),
        ),
        DropdownMenuItem(
          value: '90-120',
          child: Text('90 to 120 Days (4 Months)'),
        ),
        DropdownMenuItem(
          value: '120-150',
          child: Text('120 to 150 Days (5 Months)'),
        ),
        DropdownMenuItem(
          value: '150-180',
          child: Text('150 to 180 Days (6 Months)'),
        ),
        DropdownMenuItem(
          value: '180-210',
          child: Text('180 to 210 Days (7 Months)'),
        ),
        DropdownMenuItem(
          value: '210-365',
          child: Text('210 to 365 Days (8-12 Months)'),
        ),
        DropdownMenuItem(value: '365-730', child: Text('1 Year to 2 Year')),
        DropdownMenuItem(value: '730-1095', child: Text('2 Year to 3 Year')),
        DropdownMenuItem(value: '1096-1825', child: Text('3 Year to 5 Year')),
        DropdownMenuItem(
          value: '1825-36500',
          child: Text('Greater Than 5 Years'),
        ),
      ],
      onChanged: (val) {
        if (val == null) {
          _updateFilter(_filters.copyWith(minDays: null, maxDays: null));
          return;
        }
        final parts = val.split('-');
        if (parts.length == 2) {
          _updateFilter(
            _filters.copyWith(
              minDays: int.tryParse(parts[0]),
              maxDays: int.tryParse(parts[1]),
            ),
          );
        }
      },
    );
  }

  Widget _buildYearsFilter() {
    return TextFormField(
      initialValue: _filters.yearsPut?.toString() ?? '',
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Years',
        border: OutlineInputBorder(),
      ),
      onChanged: (val) =>
          _updateFilter(_filters.copyWith(yearsPut: int.tryParse(val))),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
  }) {
    final Map<String, T> stringToValueMap = {};
    String? currentValueString;
    final List<String> options = [];

    for (var item in items) {
      if (item.value == null) continue;

      String textStr = '';
      if (item.child is Text) {
        textStr = (item.child as Text).data ?? '';
      }

      if (textStr.isNotEmpty &&
          textStr != '--Select One--' &&
          textStr != '-- Select One --') {
        if (!options.contains(textStr)) {
          options.add(textStr);
        }
        // We store the mapping so we can retrieve the generic <T> value when the string is selected
        stringToValueMap[textStr] = item.value as T;
        if (item.value == value) {
          currentValueString = textStr;
        }
      }
    }

    return CustomSearchableDropdown(
      labelText: label,
      options: options,
      value: currentValueString,
      allowCustomEntries: false,
      onChanged: (val) {
        if (val == null || val.isEmpty) {
          onChanged(null);
        } else {
          onChanged(stringToValueMap[val]);
        }
      },
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          OutlinedButton.icon(
            onPressed: () {
              widget.onClear();
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Clear Filters'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.grey[800]),
          ),
          ElevatedButton.icon(
            onPressed: () {
              widget.onApply(_filters);
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.search),
            label: const Text('Search'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
