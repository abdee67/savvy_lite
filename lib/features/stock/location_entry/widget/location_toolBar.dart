// features/stock/location_master/widgets/location_toolbar.dart
import 'package:flutter/material.dart';

class LocationToolbar extends StatelessWidget {
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final bool isSaveEnabled;

  const LocationToolbar({
    super.key,
    required this.onSave,
    required this.onCancel,
    required this.isSaveEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          // Save Button
          ElevatedButton.icon(
            onPressed: isSaveEnabled ? onSave : null,
            icon: const Icon(Icons.check),
            label: const Text('Save'),
          ),
          const SizedBox(width: 8),

          // Cancel Button
          OutlinedButton.icon(
            onPressed: onCancel,
            icon: const Icon(Icons.close),
            label: const Text('Cancel'),
          ),

          const Spacer(),

          // Status indicator or other widgets can go here
        ],
      ),
    );
  }
}
