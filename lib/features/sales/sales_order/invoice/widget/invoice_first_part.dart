import 'package:flutter/material.dart';
import 'package:savvy_stock/features/sales/customer/models/customer_model.dart';

class InvoiceFirstPart extends StatelessWidget {
  final Customer customer;
  final DateTime date;
  final String invoiceNumber;
  final String salesOrderNumber;
  final String? salesRepresent;
  final String? commentsSo;

  const InvoiceFirstPart({
    super.key,
    required this.customer,
    required this.date,
    required this.invoiceNumber,
    required this.salesOrderNumber,
    this.salesRepresent,
    this.commentsSo,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: Colors.amber,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.business, color: Color(0xFF155888)),
                const SizedBox(width: 8),
                const Text(
                  'INVOICE DETAILS',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF155888),
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                if (salesOrderNumber != 'N/A')
                  Text(
                    'SO: $salesOrderNumber',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Two-column layout
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column - Customer Information
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('BILL TO'),
                      const SizedBox(height: 8),
                      _buildInfoRow('Name', customer.customerName ?? 'N/A'),
                      if (customer.tinNumber != null &&
                          customer.tinNumber!.isNotEmpty)
                        _buildInfoRow('TIN', customer.tinNumber!),
                      if (customer.phoneNumber != null &&
                          customer.phoneNumber!.isNotEmpty)
                        _buildInfoRow('Phone', customer.phoneNumber!),
                      if (customer.country != null &&
                          customer.country!.isNotEmpty)
                        _buildInfoRow('Country', customer.country!),
                      if (customer.region != null &&
                          customer.region!.isNotEmpty)
                        _buildInfoRow('Region', customer.region!),
                      if (customer.city != null && customer.city!.isNotEmpty)
                        _buildInfoRow('City', customer.city!),
                    ],
                  ),
                ),

                const SizedBox(width: 24),

                // Right column - Invoice Information
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('INVOICE INFO'),
                      const SizedBox(height: 8),
                      _buildInfoRow('Sales Order', salesOrderNumber),
                      _buildInfoRow('Date', _formatDate(date)),
                      if (salesRepresent != null && salesRepresent!.isNotEmpty)
                        _buildInfoRow('Sales Rep', salesRepresent!),
                      _buildInfoRow('Status', 'Pending'),
                    ],
                  ),
                ),
              ],
            ),
            if (commentsSo != null && commentsSo!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              _buildSectionTitle('COMMENTS'),
              const SizedBox(height: 4),
              Text(
                commentsSo!,
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.black87,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Color(0xFF155888),
        fontSize: 12,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
