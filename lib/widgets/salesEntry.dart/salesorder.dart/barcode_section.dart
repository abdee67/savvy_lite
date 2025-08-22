import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:savvy_stock/models/SalesEntry/salesorder.dart';

class BarcodeSection extends StatefulWidget {
  final Function(SalesOrderItem) onItemAdded;

  const BarcodeSection({super.key, required this.onItemAdded});

  @override
  State<BarcodeSection> createState() => _BarcodeSectionState();
}

class _BarcodeSectionState extends State<BarcodeSection> {
  final TextEditingController _barcodeController = TextEditingController();

  void showBarcodeScanner() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Scan Barcode'),
          content: SizedBox(
            height: 200,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.camera_alt, size: 64, color: Colors.blue),
                const SizedBox(height: 20),
                const Text('Barcode scanner would be implemented here'),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // Simulate barcode scan
                    submitBarcode('1234567890123');
                    Navigator.pop(context);
                  },
                  child: const Text('Simulate Scan'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void submitBarcode(String barcode) {
    // Create and add the item via callback
    final newItem = SalesOrderItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Item from barcode $barcode',
      quantity: 1,
      price: 10.99,
    );

    widget.onItemAdded(newItem);

    // Clear the barcode field
    _barcodeController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Item added from barcode: $barcode')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Barcode', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _barcodeController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  hintText: 'Enter barcode',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) {
                  if (value.length == 12 || value.length == 13) {
                    submitBarcode(value);
                  }
                },
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: showBarcodeScanner,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Scan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade200,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
