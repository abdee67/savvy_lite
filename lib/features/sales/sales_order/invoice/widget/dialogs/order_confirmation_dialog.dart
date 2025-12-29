import 'package:flutter/material.dart';

class OrderConfirmationDialog extends StatelessWidget {
  final String? orderNumber;
  final double? totalAmount;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const OrderConfirmationDialog({
    super.key,
    this.orderNumber,
    this.totalAmount,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Finalize Order'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (orderNumber != null)
            Text(
              'Order: $orderNumber',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          if (totalAmount != null)
            Text('Total: ETB ${totalAmount!.toStringAsFixed(2)}'),
          const SizedBox(height: 16),
          const Text(
            'This will complete the order, generate an invoice, and update inventory. This action cannot be undone.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: onCancel, child: const Text('Cancel')),
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF155888),
          ),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
