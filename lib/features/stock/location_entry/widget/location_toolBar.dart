// features/stock/location_master/widgets/location_toolbar.dart
import 'package:flutter/material.dart';

class LocationToolbar extends StatelessWidget {
  final VoidCallback onSave;
  final VoidCallback onSaveAndClose;
  final VoidCallback onSaveAndAddNew;
  final bool isSaveEnabled;

  const LocationToolbar({
    super.key,
    required this.onSave,
    required this.onSaveAndClose,
    required this.onSaveAndAddNew,
    required this.isSaveEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
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

          // Save and Close Button
          ElevatedButton.icon(
            onPressed: isSaveEnabled ? onSaveAndClose : null,
            icon: const Icon(Icons.check),
            label: const Text('SaveNClose'),
          ),
          const SizedBox(width: 8),

          // Save and Add New Button
          ElevatedButton.icon(
            onPressed: isSaveEnabled ? onSaveAndAddNew : null,
            icon: const Icon(Icons.check),
            label: const Text('SaveNAdd'),
          ),
          const SizedBox(width: 8),

          // Status indicator or other widgets can go here
        ],
      ),
    );
  }
}
