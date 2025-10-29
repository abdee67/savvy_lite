// features/stock/location_master/widgets/location_list_toolbar.dart
import 'package:flutter/material.dart';
import 'package:savvy_stock/features/stock/location_entry/widget/export_menu.dart';

class LocationListToolbar extends StatelessWidget {
  final VoidCallback onNewLocation;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onRefresh;
  final Function(ExportFormat) onExport;
  final bool isEditEnabled;
  final bool isDeleteEnabled;

  const LocationListToolbar({
    super.key,
    required this.onNewLocation,
    required this.onEdit,
    required this.onDelete,
    required this.onRefresh,
    required this.onExport,
    required this.isEditEnabled,
    required this.isDeleteEnabled,
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
          // Left Group - Primary Actions
          _buildPrimaryActions(),

          const Spacer(),

          // Right Group - Table Actions
          _buildTableActions(),
        ],
      ),
    );
  }

  Widget _buildPrimaryActions() {
    return Row(
      children: [
        // New Location Button
        ElevatedButton.icon(
          onPressed: onNewLocation,
          icon: const Icon(Icons.add),
          label: const Text('New Location'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
        ),
        const SizedBox(width: 8),

        // Edit Split Button (simulated with PopupMenuButton)
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              onEdit();
            } else if (value == 'delete') {
              onDelete();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              enabled: isEditEnabled,
              child: const Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'delete',
              enabled: isDeleteEnabled,
              child: const Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          child: ElevatedButton.icon(
            onPressed: isEditEnabled ? onEdit : null,
            icon: const Icon(Icons.edit),
            label: const Text('Edit'),
          ),
        ),
      ],
    );
  }

  Widget _buildTableActions() {
    return Row(
      children: [
        // Refresh Button
        IconButton(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
        ),
        const SizedBox(width: 8),

        // Export Menu
        // ExportMenu(onExport: onExport),
      ],
    );
  }
}
