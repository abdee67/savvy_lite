import 'package:flutter/material.dart';
import 'package:savvy_stock/features/sales/invoice/models/invoice_model.dart';

class InvoiceThirdPart extends StatelessWidget {
  final PaymentInfo payment;

  const InvoiceThirdPart({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PAYMENT INFORMATION',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Payment Method', payment.paymentMethod),
            const SizedBox(height: 8),
            _buildInfoRow('Payment Type', payment.paymentType),
            const SizedBox(height: 8),
            _buildInfoRow('Payment Instrument', payment.paymentInstrument),
            if (payment.paymentTerm.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoRow('Payment Term', payment.paymentTerm),
            ],
            const Divider(height: 24),
            _buildAmountRow('Subtotal', payment.subtotal),
            if (payment.discountAmount > 0) ...[
              _buildAmountRow('Discount', -payment.discountAmount),
            ],
            if (payment.withholdingAmount > 0) ...[
              _buildAmountRow('Withholding', payment.withholdingAmount),
            ],
            _buildAmountRow('Tax', payment.taxAmount),
            const Divider(height: 24),
            _buildAmountRow('TOTAL AMOUNT', payment.totalAmount, isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 150,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(value.isNotEmpty ? value : 'N/A')),
      ],
    );
  }

  Widget _buildAmountRow(String label, double amount, {bool isTotal = false}) {
    final isNegative = amount < 0;
    final displayAmount = isNegative ? -amount : amount;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isTotal
                ? const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                : null,
          ),
          Text(
            '${isNegative ? '-' : ''}\$${displayAmount.toStringAsFixed(2)}',
            style: isTotal
                ? const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                : null,
          ),
        ],
      ),
    );
  }
}
