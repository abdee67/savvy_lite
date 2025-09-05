import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:savvy_stock/core/widgets/custom_dropdown.dart';
import 'package:savvy_stock/features/sales/customer/blocs/customer_bloc.dart';
import 'package:savvy_stock/features/sales/customer/models/customer_model.dart';
import 'package:savvy_stock/features/sales/customer/widget/add_customer_dialog.dart';

class CustomerSection extends StatelessWidget {
  final String title;
  final Customer selectedCustomer;
  final List<Customer> customers;
  final ValueChanged<Customer> onCustomerSelected;
  final bool showAddButton;

  const CustomerSection({
    super.key,
    required this.title,
    required this.selectedCustomer,
    required this.customers,
    required this.onCustomerSelected,
    required this.showAddButton,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),

        CustomTableDropdown<Customer>(
          title: title,
          items: customers,
          displayText: (customer) => customer.name,
          selectedValue: selectedCustomer.isNotEmpty ? selectedCustomer : null,
          columns: [
            TableColumnConfig(
              header: 'Name',
              cellBuilder: (customer) => Text(customer.name),
            ),
            TableColumnConfig(
              header: 'TIN',
              cellBuilder: (customer) => Text(customer.tin),
            ),
            TableColumnConfig(
              header: 'Phone',
              cellBuilder: (customer) => Text(customer.phone),
            ),
          ],
          onItemSelected: (customer) {
            if (customer != null) {
              onCustomerSelected(customer);
            }
          },
        ),

        if (showAddButton) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _showAddCustomerDialog(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Customer'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF155888),
              side: const BorderSide(color: Color(0xFF155888)),
            ),
          ),
        ],
      ],
    );
  }

  void _showAddCustomerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => BlocProvider.value(
        value: context.read<CustomerBloc>(),
        child: const AddCustomerDialog(),
      ),
    );
  }
}
