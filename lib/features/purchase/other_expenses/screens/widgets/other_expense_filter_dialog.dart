import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:savvy_stock/features/purchase/other_expenses/bloc/other_expenses_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OtherExpenseFilterDialog extends StatefulWidget {
  final DateTime? initialDateFrom;
  final DateTime? initialDateTo;

  const OtherExpenseFilterDialog({
    super.key,
    this.initialDateFrom,
    this.initialDateTo,
  });

  @override
  State<OtherExpenseFilterDialog> createState() =>
      _OtherExpenseFilterDialogState();
}

class _OtherExpenseFilterDialogState extends State<OtherExpenseFilterDialog> {
  DateTime? _dateFrom;
  DateTime? _dateTo;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    _dateFrom = widget.initialDateFrom;
    _dateTo = widget.initialDateTo;
  }

  Future<void> _selectDate(BuildContext context, bool isFrom) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFrom
          ? (_dateFrom ?? DateTime.now())
          : (_dateTo ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _dateFrom = picked;
        } else {
          _dateTo = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter Expenses'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Date From'),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _selectDate(context, true),
              child: InputDecorator(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  _dateFrom != null
                      ? _dateFormat.format(_dateFrom!)
                      : 'Select Date',
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Date To'),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _selectDate(context, false),
              child: InputDecorator(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  _dateTo != null
                      ? _dateFormat.format(_dateTo!)
                      : 'Select Date',
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            // Clear filters
            setState(() {
              _dateFrom = null;
              _dateTo = null;
            });
            context.read<OtherExpensesBloc>().add(
              UpdateDateFilters(dateFrom: null, dateTo: null),
            );
            context.read<OtherExpensesBloc>().add(
              const LoadPaginatedExpenses(page: 1, pageSize: 20),
            );
            Navigator.of(context).pop();
          },
          child: const Text('Clear'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            context.read<OtherExpensesBloc>().add(
              UpdateDateFilters(dateFrom: _dateFrom, dateTo: _dateTo),
            );
            context.read<OtherExpensesBloc>().add(
              LoadPaginatedExpenses(
                page: 1,
                pageSize: 20,
                dateFrom: _dateFrom,
                dateTo: _dateTo,
              ),
            );
            Navigator.of(context).pop();
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
