import 'dart:async';

import 'package:flutter/material.dart';

class OrderProcessingDialog extends StatefulWidget {
  final VoidCallback? onTimeout;

  const OrderProcessingDialog({super.key, this.onTimeout});

  @override
  State<OrderProcessingDialog> createState() => _OrderProcessingDialogState();
}

class _OrderProcessingDialogState extends State<OrderProcessingDialog> {
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    // Set timeout after 30 seconds
    _timeoutTimer = Timer(const Duration(seconds: 30), () {
      widget.onTimeout?.call();
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        // Note: State handling (pop on complete/error) is done by the parent
        // BlocConsumer in invoice_action.dart to avoid double-pop conflicts
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Processing Order',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Finalizing sales order, generating invoice, and updating inventory...',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
