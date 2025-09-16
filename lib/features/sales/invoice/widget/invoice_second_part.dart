import 'package:flutter/material.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/models/confirmed_item.dart';

class InvoiceSecondPart extends StatelessWidget {
  final List<ConfirmedItem> items;

  const InvoiceSecondPart({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ORDER ITEMS',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildItemsTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(
            label: Text(
              'Item Name',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold)),
            numeric: true,
          ),
          DataColumn(
            label: Text('UoM', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          DataColumn(
            label: Text(
              'Unit Price',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            numeric: true,
          ),
          DataColumn(
            label: Text(
              'Total Price',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            numeric: true,
          ),
        ],
        rows: items.map((item) {
          final double unitPrice = item.quantity > 0
              ? item.totalPrice / item.quantity
              : 0;
          return DataRow(
            cells: [
              DataCell(
                Text(
                  item.itemName,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataCell(
                Text(
                  item.quantity.toStringAsFixed(2),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataCell(
                const Text(
                  'PCS',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ), // Assuming UoM is always PCS based on your items
              DataCell(
                Text(
                  _formatCurrency(unitPrice),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataCell(Text(_formatCurrency(item.totalPrice))),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }
}
