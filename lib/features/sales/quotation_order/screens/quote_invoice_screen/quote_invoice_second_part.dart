import 'package:flutter/material.dart';
import 'package:savvy_stock/features/sales/quotation_order/model/quotation_order_detail.dart';

class QuotationInvoiceSecondPart extends StatelessWidget {
  final List<QuotationOrderDetail> items;
  final double subtotal;

  const QuotationInvoiceSecondPart({
    super.key,
    required this.items,
    required this.subtotal,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.list_alt, size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'QUOTATION ORDER ITEMS',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Scrollable content area with maximum height constraint
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: _buildScrollableContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollableContent(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // For very small screens, use a simplified view
        if (constraints.maxWidth < 400) {
          return _buildCompactItemList();
        }

        // For medium screens, use a more compact table
        if (constraints.maxWidth < 600) {
          return _buildMediumTable();
        }

        // For larger screens, use the full table
        return _buildFullTable();
      },
    );
  }

  Widget _buildCompactItemList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (context, index) => const Divider(height: 16),
      itemBuilder: (context, index) {
        final item = items[index];
        final double unitPrice = item.quantity! > 0
            ? item.extendedPrice! / item.quantity!
            : 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.itemTableRef?.itemDescription ?? 'N/A',
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${item.quantity!.toStringAsFixed(2)} ${item.uomRef?.description1}',
                ),
                Text(
                  '${unitPrice.toStringAsFixed(2)} Birr/${item.uomRef?.description1}',
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  _formatCurrency(item.extendedPrice!),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildMediumTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 16,
          horizontalMargin: 0,
          headingRowHeight: 36,
          dataRowHeight: 40,
          columns: [
            DataColumn(label: Text('Item', style: _headerTextStyle())),
            DataColumn(
              label: Text('Qty', style: _headerTextStyle()),
              numeric: true,
            ),
            DataColumn(
              label: Text('Price', style: _headerTextStyle()),
              numeric: true,
            ),
            DataColumn(
              label: Text('Total', style: _headerTextStyle()),
              numeric: true,
            ),
          ],
          rows: items.map((item) {
            final double unitPrice = item.quantity! > 0
                ? item.extendedPrice! / item.quantity!
                : 0;

            return DataRow(
              cells: [
                DataCell(
                  SizedBox(
                    width: 100, // Fixed width for item name
                    child: Text(
                      item.itemTableRef?.itemDescription ?? 'N/A',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                DataCell(
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${item.quantity!.toStringAsFixed(2)} ${item.uomRef?.description1 ?? ''}',
                    ),
                  ),
                ),
                DataCell(
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(_formatCurrency(unitPrice)),
                  ),
                ),
                DataCell(
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      _formatCurrency(item.extendedPrice!),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFullTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 20,
          horizontalMargin: 0,
          headingRowHeight: 40,
          dataRowHeight: 40,
          columns: [
            DataColumn(label: Text('Item Name', style: _headerTextStyle())),
            DataColumn(
              label: Text('Quantity', style: _headerTextStyle()),
              numeric: true,
            ),
            DataColumn(label: Text('UoM', style: _headerTextStyle())),
            DataColumn(
              label: Text('Unit Price', style: _headerTextStyle()),
              numeric: true,
            ),
            DataColumn(
              label: Text('Total Price', style: _headerTextStyle()),
              numeric: true,
            ),
          ],
          rows: items.map((item) {
            final double unitPrice = item.quantity! > 0
                ? item.extendedPrice! / item.quantity!
                : 0;

            return DataRow(
              cells: [
                DataCell(
                  Text(
                    item.itemTableRef?.itemDescription ?? 'N/A',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                DataCell(
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(item.quantity!.toStringAsFixed(2)),
                  ),
                ),
                DataCell(
                  Text(
                    item.uomRef?.description1 ??
                        item.itemTableRef?.unitOfMeasure ??
                        'N/A',
                  ),
                ),
                DataCell(
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(_formatCurrency(unitPrice)),
                  ),
                ),
                DataCell(
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      _formatCurrency(item.extendedPrice!),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  TextStyle _headerTextStyle() {
    return const TextStyle(fontWeight: FontWeight.bold, fontSize: 13);
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(2)} Birr';
  }
}
