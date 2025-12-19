// features/stock/lot_master/ui/widgets/expiration_filter_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/branch_list/blocs/branch_list_bloc.dart';
import 'package:savvy_stock/features/branch_list/blocs/branch_list_event.dart';
import 'package:savvy_stock/features/onboarding/widgets/custom_text_field.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_bloc.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_event.dart';
import 'package:savvy_stock/features/stock/location_entry/blocs/location_master_bloc.dart';
import 'package:savvy_stock/features/stock/location_entry/blocs/location_master_event.dart';
import 'package:savvy_stock/features/stock/lot_master/models/expiration_report_filters.dart';

class ExpirationFilterDialog extends StatefulWidget {
  final ExpirationReportFilters currentFilters;
  final AuthBloc authBloc;

  const ExpirationFilterDialog({
    super.key,
    required this.currentFilters,
    required this.authBloc,
  });

  @override
  State<ExpirationFilterDialog> createState() => _ExpirationFilterDialogState();
}

class _ExpirationFilterDialogState extends State<ExpirationFilterDialog> {
  late ExpirationReportFilters _filters;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  final _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    _filters = widget.currentFilters;
    _dateFrom = widget.currentFilters.dateFrom;
    _dateTo = widget.currentFilters.dateTo;

    // Load necessary data
    _loadData();
  }

  void _loadData() {
    final companyId = widget.authBloc.state.companyId;
    if (companyId != null) {
      context.read<BranchBloc>().add(LoadBranchs(companyId));
      context.read<StockItemsEntryBloc>().add(LoadItems(companyId));
      context.read<LocationMasterBloc>().add(LoadLocationMasters(companyId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                //for both expired and upcoming expired pages
                Text(
                  _filters.showZeroAvailability
                      ? 'Filter Expiration Report'
                      : 'Filter Upcoming Expiry Report',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Date Range Filter
            if (_filters.dateFrom != null || _filters.dateTo != null)
              _buildDateRangeFilter(),

            const SizedBox(height: 16),

            // Item Filter
            if (_filters.itemId != null) _buildItemFilter(),

            const SizedBox(height: 16),

            // Branch Filter
            _buildBranchFilter(),

            const SizedBox(height: 16),

            // Location Filter
            _buildLocationFilter(),

            const SizedBox(height: 16),

            // Zero Availability Toggle
            if (_filters.showZeroAvailability) _buildZeroAvailabilityToggle(),

            if (_filters.batchNumber != null) _buildBatchNumberFilter(),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _filters = const ExpirationReportFilters();
                        _dateFrom = null;
                        _dateTo = null;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.refresh, size: 16),
                        SizedBox(width: 8),
                        Text('Clear All'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final finalFilters = _filters.copyWith(
                        dateFrom: _dateFrom,
                        dateTo: _dateTo,
                      );
                      Navigator.pop(context, finalFilters);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1C4292),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search, size: 16, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Apply Filters',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Expiration Date Range',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _dateFrom ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    setState(() => _dateFrom = date);
                  }
                },
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(
                  _dateFrom != null
                      ? _dateFormat.format(_dateFrom!)
                      : 'Start Date',
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _dateTo ?? DateTime.now(),
                    firstDate: _dateFrom ?? DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    setState(() => _dateTo = date);
                  }
                },
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(
                  _dateTo != null ? _dateFormat.format(_dateTo!) : 'End Date',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildItemFilter() {
    final itemsState = context.watch<StockItemsEntryBloc>().state;
    final items = itemsState.filteredItems;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Item', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        DropdownButtonFormField<int?>(
          initialValue: _filters.itemId,
          decoration: InputDecoration(
            hintText: '-- Select One --',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('-- Select One --'),
            ),
            ...items.map((item) {
              return DropdownMenuItem<int?>(
                value: item.id,
                child: Text('${item.itemsId} - ${item.itemDescription}'),
              );
            }),
          ],
          onChanged: (value) {
            setState(() {
              _filters = _filters.copyWith(itemId: value);
            });
          },
        ),
      ],
    );
  }

  Widget _buildBranchFilter() {
    final branchesState = context.watch<BranchBloc>().state;
    final branches = branchesState.filteredBranchs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Branch/Store',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int?>(
          initialValue: _filters.branchId,
          decoration: InputDecoration(
            hintText: '-- Select One --',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('-- Select One --'),
            ),
            ...branches.map((branch) {
              return DropdownMenuItem<int?>(
                value: branch.id,
                child: Text('${branch.description}'),
              );
            }),
          ],
          onChanged: (value) {
            setState(() {
              _filters = _filters.copyWith(branchId: value);
            });
          },
        ),
      ],
    );
  }

  Widget _buildLocationFilter() {
    final locationsState = context.watch<LocationMasterBloc>().state;
    final locations = locationsState.filteredItems;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Location', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        DropdownButtonFormField<int?>(
          initialValue: _filters.locationId,
          decoration: InputDecoration(
            hintText: '-- Select One --',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('-- Select One --'),
            ),
            ...locations.map((location) {
              return DropdownMenuItem<int?>(
                value: location.id,
                child: Text(location.locationDescription!),
              );
            }),
          ],
          onChanged: (value) {
            setState(() {
              _filters = _filters.copyWith(locationId: value);
            });
          },
        ),
      ],
    );
  }

  Widget _buildZeroAvailabilityToggle() {
    return Row(
      children: [
        Checkbox(
          value: _filters.showZeroAvailability,
          onChanged: (value) {
            setState(() {
              _filters = _filters.copyWith(
                showZeroAvailability: value ?? false,
              );
            });
          },
        ),
        const SizedBox(width: 8),
        const Expanded(child: Text('Include items with zero availability')),
      ],
    );
  }

  Widget _buildBatchNumberFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Batch Number',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        CustomTextField(
          label: 'Batch Number',
          value: _filters.batchNumber ?? '',
          keyboardType: TextInputType.text,
          readOnly: false,
          onChanged: (value) {
            setState(() {
              _filters = _filters.copyWith(batchNumber: value);
            });
          },
        ),
      ],
    );
  }
}
