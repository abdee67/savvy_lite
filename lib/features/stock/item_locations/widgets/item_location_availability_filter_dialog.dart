import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:savvy_stock/features/branch_list/blocs/branch_list_bloc.dart';
import 'package:savvy_stock/features/branch_list/blocs/branch_list_state.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_bloc.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_state.dart';
import 'package:savvy_stock/features/stock/item_locations/models/item_location_filters.dart';
import 'package:savvy_stock/features/stock/location_entry/blocs/location_master_bloc.dart';
import 'package:savvy_stock/features/stock/location_entry/blocs/location_master_state.dart';
import 'package:savvy_stock/core/widgets/custom_searchable_dropdown.dart';

class ItemLocationAvailabilityFilterDialog extends StatefulWidget {
  final ItemLocationFilters currentFilters;
  final Function(ItemLocationFilters) onApply;
  final Function() onClear;

  const ItemLocationAvailabilityFilterDialog({
    super.key,
    required this.currentFilters,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<ItemLocationAvailabilityFilterDialog> createState() =>
      _ItemLocationAvailabilityFilterDialogState();
}

class _ItemLocationAvailabilityFilterDialogState
    extends State<ItemLocationAvailabilityFilterDialog> {
  late ItemLocationFilters _filters;

  @override
  void initState() {
    super.initState();
    _filters = widget.currentFilters;
  }

  void _updateFilter(ItemLocationFilters newFilters) {
    setState(() {
      _filters = newFilters;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [_buildGeneralFilters()],
              ),
            ),
          ),
          _buildActions(),
        ],
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
              value: _filters.branchId,
              items: state.branchs.map((e) {
                return DropdownMenuItem(
                  value: e.id,
                  child: Text(e.description ?? 'Unknown Branch'),
                );
              }).toList(),
              onChanged: (val) =>
                  _updateFilter(_filters.copyWith(branchId: val)),
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
        SwitchListTile(
          title: const Text('Zero/No Availability'),
          value: _filters.noAvailable,
          onChanged: (val) =>
              _updateFilter(_filters.copyWith(noAvailable: val)),
          contentPadding: EdgeInsets.zero,
        ),
      ],
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
