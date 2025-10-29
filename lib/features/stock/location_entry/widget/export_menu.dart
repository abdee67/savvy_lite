// features/stock/location_master/widgets/export_menu.dart
import 'package:flutter/material.dart';

enum ExportFormat { xlsx, csv }

class ExportMenu extends StatelessWidget {
  final Function(ExportFormat) onExport;

  const ExportMenu({super.key, required this.onExport});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ExportFormat>(
      icon: const Icon(Icons.download),
      offset: const Offset(0, 50),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: ExportFormat.xlsx,
          child: const Row(
            children: [
              Icon(Icons.table_chart, color: Colors.green),
              SizedBox(width: 8),
              Text('Export to XLSX'),
            ],
          ),
        ),
        PopupMenuItem(
          value: ExportFormat.csv,
          child: const Row(
            children: [
              Icon(Icons.description, color: Colors.blue),
              SizedBox(width: 8),
              Text('Export to CSV'),
            ],
          ),
        ),
      ],
      onSelected: onExport,
      child: ElevatedButton.icon(
        onPressed: null, // The popup menu will handle the press
        icon: const Icon(Icons.download),
        label: const Text('Export'),
      ),
    );
  }
}
