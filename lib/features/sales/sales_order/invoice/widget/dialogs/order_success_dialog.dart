import 'package:flutter/material.dart';

class OrderSuccessDialog extends StatelessWidget {
  final String? orderNumber;
  final String? invoiceNumber;
  final double? totalAmount;
  final VoidCallback onDone;

  const OrderSuccessDialog({
    super.key,
    this.orderNumber,
    this.invoiceNumber,
    this.totalAmount,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green),
          SizedBox(width: 8),
          Text('Order Completed'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (orderNumber != null) Text('Sales Order: $orderNumber'),
          if (invoiceNumber != null) Text('Invoice: $invoiceNumber'),
          if (totalAmount != null)
            Text('Total: ETB ${totalAmount!.toStringAsFixed(2)}'),
          const SizedBox(height: 16),
          const Text('The order has been completed successfully!'),
        ],
      ),
      actions: [TextButton(onPressed: onDone, child: const Text('Done'))],
    );
  }
}
