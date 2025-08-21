import 'package:flutter/material.dart';
import 'package:savvy_stock/models/salesorder.dart';

class ItemList extends StatelessWidget {
  final List<SalesOrderItem> items;
  final Function(int) onItemRemoved;
  
  const ItemList({
    super.key,
    required this.items,
    required this.onItemRemoved,
  });
  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            'No items added yet',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Items',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: Text(item.name),
                subtitle: Text(
                  'Qty: ${item.quantity} | Price: \$${item.price.toStringAsFixed(2)}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '\$${(item.quantity * item.price).toStringAsFixed(2)}',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => onItemRemoved(index),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
