// features/stock/location_master/widgets/location_context_menu.dart
import 'package:flutter/material.dart';
import '../models/location_master_model.dart';

class LocationContextMenu extends StatelessWidget {
  final LocationMaster location;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onNewLocation;
  final bool canEdit;
  final bool canDelete;
  final bool canCreate;

  const LocationContextMenu({
    super.key,
    required this.location,
    required this.onEdit,
    required this.onDelete,
    required this.onNewLocation,
    required this.canEdit,
    required this.canDelete,
    required this.canCreate,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'edit':
            onEdit();
            break;
          case 'delete':
            onDelete();
            break;
          case 'new':
            onNewLocation();
            break;
        }
      },
      itemBuilder: (context) => [
        if (canEdit) ...[
          PopupMenuItem(
            value: 'edit',
            child: const Row(
              children: [
                Icon(Icons.edit, size: 20),
                SizedBox(width: 8),
                Text('Edit Selected'),
              ],
            ),
          ),
        ],
        if (canDelete) ...[
          PopupMenuItem(
            value: 'delete',
            child: const Row(
              children: [
                Icon(Icons.delete, size: 20, color: Colors.red),
                SizedBox(width: 8),
                Text('Delete Selected', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
          const PopupMenuDivider(),
        ],
        if (canCreate) ...[
          PopupMenuItem(
            value: 'new',
            child: const Row(
              children: [
                Icon(Icons.add, size: 20),
                SizedBox(width: 8),
                Text('New Location'),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
