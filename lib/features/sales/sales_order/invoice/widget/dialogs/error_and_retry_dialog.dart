import 'package:flutter/material.dart';

class ErrorDialog extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  final VoidCallback onCancel;

  const ErrorDialog({
    super.key,
    required this.error,
    required this.onRetry,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red),
          SizedBox(width: 8),
          Text('Operation Failed'),
        ],
      ),
      content: Text(error),
      actions: [
        TextButton(onPressed: onCancel, child: const Text('Cancel')),
        ElevatedButton(
          onPressed: onRetry,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF155888),
          ),
          child: const Text('Retry'),
        ),
      ],
    );
  }
}

class RetryDialog extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  final VoidCallback onCancel;

  const RetryDialog({
    super.key,
    required this.error,
    required this.onRetry,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.warning_amber, color: Colors.orange),
          SizedBox(width: 8),
          Text('Retry Operation'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(error),
          const SizedBox(height: 8),
          const Text(
            'Would you like to try again?',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: onCancel, child: const Text('Cancel')),
        ElevatedButton(
          onPressed: onRetry,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF155888),
          ),
          child: const Text('Retry'),
        ),
      ],
    );
  }
}
