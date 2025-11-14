import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:savvy_stock/features/stock/item_entry_workbench/blocs/item_master_bloc.dart';
import 'package:savvy_stock/features/stock/item_entry_workbench/blocs/item_master_events.dart';
import 'package:savvy_stock/features/stock/item_entry_workbench/blocs/item_master_state.dart';
import 'package:savvy_stock/features/stock/item_entry_workbench/models/item_master_model.dart';

class BatchUploadSection extends StatelessWidget {
  const BatchUploadSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ItemMasterBloc, ItemMasterState>(
      listener: (context, state) {
        if (state.status == ItemMasterStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File uploaded successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructions
            _buildInstructionsCard(),
            const SizedBox(height: 24),

            // Actions
            Row(
              children: [
                Expanded(child: _buildDownloadTemplateButton(context)),
                const SizedBox(width: 16),
                Expanded(child: _buildUploadButton(context, state)),
              ],
            ),
            const SizedBox(height: 24),

            // Upload Status
            _buildUploadStatus(),
            // Migration Panel (show when items are loaded)
            if (state.showMigrationPanel) _buildMigrationPanel(context, state),
          ],
        );
      },
    );
  }

  Widget _buildInstructionsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Colors.blue[600]),
                const SizedBox(width: 8),
                Text(
                  'Batch Upload Instructions',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '1. Download the template file first',
              style: TextStyle(fontSize: 14),
            ),
            const Text(
              '2. Fill in your item data following the template format',
              style: TextStyle(fontSize: 14),
            ),
            const Text(
              '3. Upload the completed Excel file',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Supported format: .xlsx',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadTemplateButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        // Trigger template download
        context.read<ItemMasterBloc>().add(
          const PrepareExcelTemplate('ItemMaster', 'stock'),
        );
        _showTemplateDownloadMessage(context);
      },
      icon: const Icon(Icons.download, size: 20),
      label: const Text('Download Template'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildUploadButton(BuildContext context, ItemMasterState state) {
    final isProcessing =
        state.status == ItemMasterStatus.processingFile ||
        state.status == ItemMasterStatus.migrating;

    return ElevatedButton.icon(
      onPressed: isProcessing ? null : () => _pickAndUploadFile(context),
      icon: isProcessing
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            )
          : const Icon(Icons.upload, size: 20),
      label: Text(isProcessing ? 'Processing...' : 'Upload File'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF155888),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildUploadStatus() {
    return BlocBuilder<ItemMasterBloc, ItemMasterState>(
      builder: (context, state) {
        if (state.status == ItemMasterStatus.migrating) {
          return Card(
            color: Colors.blue[50],
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Processing your file... Please wait.',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (state.message?.contains('Upload') == true) {
          return Card(
            color: Colors.green[50],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[600]),
                  const SizedBox(width: 16),
                  Expanded(child: Text(state.message!)),
                ],
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Future<void> _pickAndUploadFile(BuildContext context) async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final bloc = context.read<ItemMasterBloc>();
        final state = bloc.state;

        // Here you would typically process the file
        // For now, we'll simulate processing
        bloc.add(
          ProcessExcelFile(
            excelFile: file,
            columns: state.migrationColumns,
            columnLabels: state.migrationColumnLabels,
          ),
        );

        // Show success message after a delay to simulate processing
        await Future.delayed(const Duration(seconds: 2));

        _showUploadSuccessMessage(context);
      }
    } catch (e) {
      _showUploadErrorMessage(context, 'Failed to upload file: $e');
    }
  }

  Widget _buildMigrationPanel(BuildContext context, ItemMasterState state) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Uploaded Items (${state.uploadedItems.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        context.read<ItemMasterBloc>().add(
                          const DataMigrationStock(),
                        );
                      },
                      child: const Text('Apply Migration'),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        context.read<ItemMasterBloc>().add(
                          const CancelCreate(),
                        );
                      },
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildUploadedItemsTable(state.uploadedItems),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadedItemsTable(List<ItemMaster> items) {
    if (items.isEmpty) {
      return const Center(child: Text('No items to display'));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Item Description')),
          DataColumn(label: Text('Branch')),
          DataColumn(label: Text('UoM')),
          DataColumn(label: Text('Quantity')),
          DataColumn(label: Text('Unit Price')),
        ],
        rows: items.map((item) {
          return DataRow(
            cells: [
              DataCell(Text(item.itemDescription!)),
              DataCell(Text(item.branchDescription!)),
              DataCell(Text(item.defualtUomDescription!)),
              DataCell(Text(item.quantity?.toString() ?? '0')),
              DataCell(Text(item.unitPrice?.toStringAsFixed(2) ?? '0.00')),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _showTemplateDownloadMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.download_done, color: Colors.white),
            SizedBox(width: 8),
            Text('Template download started'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showUploadSuccessMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('File uploaded successfully'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showUploadErrorMessage(BuildContext context, String message) {
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
