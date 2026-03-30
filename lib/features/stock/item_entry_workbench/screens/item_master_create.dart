import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:savvy_stock/features/stock/item_entry_workbench/blocs/item_master_bloc.dart';
import 'package:savvy_stock/features/stock/item_entry_workbench/blocs/item_master_state.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/stock/item_entry_workbench/widgets/batch_upload_section.dart';
import 'package:savvy_stock/features/stock/item_entry_workbench/widgets/single_item_entry_form.dart';

class ItemMasterCreatePage extends StatefulWidget {
  final AuthBloc authBloc;
  const ItemMasterCreatePage({super.key, required this.authBloc});

  @override
  State<ItemMasterCreatePage> createState() => _ItemMasterCreatePageState();
}

class _ItemMasterCreatePageState extends State<ItemMasterCreatePage> {
  String _selectedMode = 'S'; // 'S' for Single, 'B' for Batch

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Entry Workbench'),
        backgroundColor: const Color(0xFF155888),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
            tooltip: 'Help',
          ),
        ],
      ),
      body: SafeArea(
        child: BlocListener<ItemMasterBloc, ItemMasterState>(
          listener: (context, state) {
            if (state.status == ItemMasterStatus.success) {
              _showSuccessMessage(
                state.message ?? 'Operation completed successfully',
              );
            } else if (state.status == ItemMasterStatus.failure) {
              _showErrorMessage(state.message ?? 'An error occurred');
            }
          },
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mode Selection
                  _buildModeSelection(),
                  const SizedBox(height: 24),

                  // Content based on selection
                  SizedBox(
                    height: MediaQuery.of(context).size.height - 300,
                    child: _selectedMode == 'S'
                        ? SingleItemEntryForm(authBloc: widget.authBloc)
                        : BatchUploadSection(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeSelection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Migration Type',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF155888),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildModeOption(
                    value: 'S',
                    title: 'Single Entry',
                    subtitle: 'Add items one by one',
                    icon: Icons.create,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildModeOption(
                    value: 'B',
                    title: 'Batch Upload',
                    subtitle: 'Upload Excel file',
                    icon: Icons.upload_file,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeOption({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMode = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _selectedMode == value
              ? const Color(0xFF155888).withOpacity(0.1)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedMode == value
                ? const Color(0xFF155888)
                : Colors.grey[300]!,
            width: _selectedMode == value ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: _selectedMode == value
                  ? const Color(0xFF155888)
                  : Colors.grey[600],
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _selectedMode == value
                    ? const Color(0xFF155888)
                    : Colors.grey[800],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: _selectedMode == value
                    ? const Color(0xFF155888)
                    : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help, color: Color(0xFF155888)),
            SizedBox(width: 8),
            Text('Item Entry Help'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Single Entry:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('• Add items one by one with detailed information'),
            Text('• Suitable for small quantities'),
            SizedBox(height: 12),
            Text(
              'Batch Upload:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('• Upload Excel file with multiple items'),
            Text('• Download template first for correct format'),
            Text('• Suitable for bulk operations'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
