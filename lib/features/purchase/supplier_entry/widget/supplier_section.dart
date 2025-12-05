import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:savvy_stock/core/widgets/custom_table_dropdown.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/purchase/supplier_entry/blocs/supplier_bloc.dart';
import 'package:savvy_stock/features/purchase/supplier_entry/models/supplier_model.dart';
import 'package:savvy_stock/features/purchase/supplier_entry/widget/supplier_create_edit.dart';

class SupplierSection extends StatelessWidget {
  final String title;
  final SupplierModel selectedSupplier;
  final List<SupplierModel> suppliers;
  final ValueChanged<SupplierModel> onSupplierSelected;
  final bool showAddButton;
  final AuthBloc authBloc;

  const SupplierSection({
    super.key,
    required this.title,
    required this.selectedSupplier,
    required this.suppliers,
    required this.onSupplierSelected,
    required this.showAddButton,
    required this.authBloc,
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

        CustomTableDropdown<SupplierModel>(
          title: title,
          items: suppliers,
          displayText: (supplier) => supplier.supplierName ?? '',
          selectedValue: selectedSupplier.isNotEmpty ? selectedSupplier : null,
          columns: [
            TableColumnConfig(
              header: 'Name',
              cellBuilder: (supplier) => Text(supplier.supplierName ?? ''),
            ),
            TableColumnConfig(
              header: 'TIN',
              cellBuilder: (supplier) => Text(supplier.tinNumber ?? ''),
            ),
            TableColumnConfig(
              header: 'Phone',
              cellBuilder: (supplier) => Text(supplier.phoneNo1 ?? ''),
            ),
          ],
          onItemSelected: (supplier) {
            if (supplier != null) {
              onSupplierSelected(supplier);
            }
          },
        ),

        if (showAddButton) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _showAddCustomerDialog(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Supplier'),
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
        value: context.read<SupplierBloc>(),
        child: SupplierEntryScreen(authBloc: authBloc),
      ),
    );
  }
}
