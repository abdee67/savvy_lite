import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/sales/customer/blocs/customer_bloc.dart';
import 'package:savvy_stock/features/sales/customer/blocs/customer_event.dart';
import 'package:savvy_stock/features/sales/sales_order/header/model/sales_transaction_filtering_model.dart';

class AgedCreditReceiptFilterDialog extends StatefulWidget {
  final SalesTransactionReportFilters currentFilters;
  final AuthBloc authBloc;

  const AgedCreditReceiptFilterDialog({
    super.key,
    required this.currentFilters,
    required this.authBloc,
  });

  @override
  State<AgedCreditReceiptFilterDialog> createState() =>
      _AgedCreditReceiptFilterDialogState();
}

class _AgedCreditReceiptFilterDialogState
    extends State<AgedCreditReceiptFilterDialog> {
  late SalesTransactionReportFilters _filters;
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

  @override
  void dispose() {
    super.dispose();
  }

  void _loadData() {
    final companyId = widget.authBloc.state.companyId;
    if (companyId != null) {
      context.read<CustomerBloc>().add(LoadCustomers(companyId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
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
                  'Filter Aged Credit Receipts',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Order Date Range
                    _buildDateRangeFilter(),
                    const SizedBox(height: 16),

                    // Customer Filter
                    _buildCustomerFilter(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _filters = const SalesTransactionReportFilters();
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
          'Order Date Range',
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

  Widget _buildCustomerFilter() {
    final customerState = context.watch<CustomerBloc>().state;
    final customers = customerState.filteredCustomers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Customer', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        DropdownButtonFormField<int?>(
          initialValue: _filters.customerId,
          decoration: InputDecoration(
            hintText: '-- Select One --',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('-- Select One --'),
            ),
            ...customers.map((customer) {
              return DropdownMenuItem<int?>(
                value: customer.id,
                child: Text(customer.customerName ?? 'Unknown'),
              );
            }),
          ],
          onChanged: (value) {
            setState(() {
              _filters = _filters.copyWith(customerId: value);
            });
          },
        ),
      ],
    );
  }
}
