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
      color: Colors.amber,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Two-column layout for compact information
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column - Date and Bill To
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCompactInfoRow(
                        Icons.calendar_today_outlined,
                        'Date',
                        _formatDate(date),
                        context,
                      ),
                      const SizedBox(height: 8),
                      _buildCompactInfoRow(
                        Icons.person_outline,
                        'Bill To',
                        customer.name,
                        context,
                      ),
                      const SizedBox(height: 8),
                      _buildCompactInfoRow(
                        Icons.location_on_outlined,
                        'Address',
                        customer.address,
                        context,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Right column - TIN and Contact
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (customer.tin.isNotEmpty)
                        _buildCompactInfoRow(
                          Icons.fingerprint_outlined,
                          'TIN',
                          customer.tin,
                          context,
                        ),
                      if (customer.tin.isNotEmpty) const SizedBox(height: 8),
                      if (customer.phone.isNotEmpty)
                        _buildCompactInfoRow(
                          Icons.phone_outlined,
                          'Phone',
                          customer.phone,
                          context,
                        ),
                      const SizedBox(height: 8),
                      _buildCompactInfoRow(
                        Icons.receipt,
                        'Invoice Number',
                        invoiceNumber,
                        context,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactInfoRow(
    IconData icon,
    String label,
    String value,
    BuildContext context,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Color(0xFF155888)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Color(0xFF155888)),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
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
