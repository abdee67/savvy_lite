import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:savvy_stock/features/purchase/other_expenses/bloc/other_expenses_bloc.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/models/other_expenses.dart';

class OtherExpenseFormDialog extends StatefulWidget {
  final OtherExpense? expense;

  const OtherExpenseFormDialog({super.key, this.expense});

  @override
  State<OtherExpenseFormDialog> createState() => _OtherExpenseFormDialogState();
}

class _OtherExpenseFormDialogState extends State<OtherExpenseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _reasonController;
  DateTime _selectedDate = DateTime.now();
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.expense?.paymentAmount?.toString() ?? '',
    );
    _reasonController = TextEditingController(
      text: widget.expense?.reasonDescription ?? '',
    );
    if (widget.expense?.datePayment != null) {
      _selectedDate = widget.expense!.datePayment!;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final amount = double.tryParse(_amountController.text) ?? 0.0;
      final reason = _reasonController.text;

      final expense =
          (widget.expense ??
                  OtherExpense(
                    company:
                        context.read<OtherExpensesBloc>().state.items.isEmpty
                        ? null
                        : context
                              .read<OtherExpensesBloc>()
                              .state
                              .items
                              .first
                              .company, // Fallback if needed
                  ))
              .copyWith(
                paymentAmount: amount,
                reasonDescription: reason,
                datePayment: _selectedDate,
              );

      context.read<OtherExpensesBloc>().add(SaveOtherExpense(expense));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.expense?.id != null;
    return AlertDialog(
      title: Text(isEditing ? 'Edit Expense' : 'New Expense Entry'),
      content: Container(
        width: MediaQuery.of(context).size.width * 0.4,
        constraints: const BoxConstraints(minWidth: 300, maxWidth: 600),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Amount Field
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount (ETB)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter amount';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Date Field
                InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _dateFormat.format(_selectedDate),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Reason Field
                TextFormField(
                  controller: _reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Reason / Description',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a reason';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            context.read<OtherExpensesBloc>().add(const CancelCreate());
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
