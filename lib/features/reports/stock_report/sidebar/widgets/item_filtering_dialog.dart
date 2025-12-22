// features/stock/lot_master/ui/widgets/expiration_filter_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_bloc.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_event.dart';
import 'package:savvy_stock/features/stock/item_entry/models/item_report_filter.model.dart';

class ItemFilterDialog extends StatefulWidget {
  final ItemReportFilters currentFilters;
  final AuthBloc authBloc;

  const ItemFilterDialog({
    super.key,
    required this.currentFilters,
    required this.authBloc,
  });

  @override
  State<ItemFilterDialog> createState() => _ItemFilterDialogState();
}

class _ItemFilterDialogState extends State<ItemFilterDialog> {
  late ItemReportFilters _filters;
  DateTime? _dateFrom;
  DateTime? _dateTo;

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
      context.read<StockItemsEntryBloc>().add(LoadItems(companyId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter Options',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Date Range Filter
              _buildDateRangeFilter(),

              const SizedBox(height: 16),

              // Action Buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Date Range', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: [
            if (_filters.dateFrom != null)
              Expanded(
                child: OutlinedButton(
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
                  child: Text(
                    _dateFrom != null
                        ? 'From: ${_dateFrom!.toLocal().toString().split(' ')[0]}'
                        : 'Select Start Date',
                  ),
                ),
              ),
            const SizedBox(width: 8),
            if (_filters.dateTo != null)
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _dateTo ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setState(() => _dateTo = date);
                    }
                  },
                  child: Text(
                    _dateTo != null
                        ? 'To: ${_dateTo!.toLocal().toString().split(' ')[0]}'
                        : 'Select End Date',
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
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
                child: Text(
                  _dateTo != null
                      ? 'To: ${_dateTo!.toLocal().toString().split(' ')[0]}'
                      : 'Select End Date',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              setState(() {
                _filters = const ItemReportFilters();
                _dateFrom = null;
                _dateTo = null;
              });
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
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
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search, size: 16, color: Colors.white),
                SizedBox(width: 8),
                Text('Apply Filters', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
