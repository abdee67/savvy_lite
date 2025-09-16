import 'package:flutter/material.dart';
import 'package:savvy_stock/features/sales/invoice/models/invoice_model.dart';

class InvoiceFirstPart extends StatelessWidget {
  final CustomerInfo customer;
  final DateTime date;
  final String invoiceNumber;

  const InvoiceFirstPart({
    super.key,
    required this.customer,
    required this.date,
    required this.invoiceNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'INVOICE',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '#$invoiceNumber',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _buildInfoRow('Date', _formatDate(date)),
            const SizedBox(height: 12),
            _buildInfoRow('Bill To', customer.name),
            const SizedBox(height: 12),
            _buildInfoRow(
              'TIN Number',
              customer.tin.isNotEmpty ? customer.tin : 'N/A',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Address',
              customer.address.isNotEmpty ? customer.address : 'N/A',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Phone',
              customer.phone.isNotEmpty ? customer.phone : 'N/A',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(value)),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
