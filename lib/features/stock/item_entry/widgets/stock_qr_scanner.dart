import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:savvy_stock/core/widgets/custom_text_Form.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_bloc.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_state.dart';
import 'package:savvy_stock/features/stock/item_entry/widgets/qr_scanner.dart';

class StockItemQRScanner extends StatefulWidget {
  final TextEditingController barcodeController;
  final Function(String) onBarcodeScanned;

  const StockItemQRScanner({
    super.key,
    required this.barcodeController,
    required this.onBarcodeScanned,
  });

  @override
  State<StockItemQRScanner> createState() => _StockItemQRScannerState();
}

class _StockItemQRScannerState extends State<StockItemQRScanner> {
  @override
  void initState() {
    super.initState();
    widget.barcodeController.addListener(_onBarcodeChanged);
  }

  void _onBarcodeChanged() {
    final text = widget.barcodeController.text;
    if (text.length == 12 || text.length == 13) {
      widget.onBarcodeScanned(text);
    }
  }

  Future<void> _openScanner() async {
    final scannedBarcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerScreen()),
    );

    if (scannedBarcode != null && scannedBarcode.isNotEmpty) {
      widget.barcodeController.text = scannedBarcode;
      widget.onBarcodeScanned(scannedBarcode);
    }
  }

  @override
  void dispose() {
    widget.barcodeController.removeListener(_onBarcodeChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<StockItemsEntryBloc, ItemEntryState>(
      listener: (context, state) {
        if (state.message != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message!)));
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: widget.barcodeController,
                  labelText: 'Barcode',
                  hintText: 'Enter 12 or 13 digit barcode',
                  prefixIcon: const Icon(Icons.qr_code),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.camera_alt),
                    onPressed: _openScanner,
                  ),

                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(45),
                  ],
                  onChanged: (value) {
                    // Real-time validation
                    if (value.length == 12 || value.length == 13) {
                      widget.onBarcodeScanned(value);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _buildBarcodeHint(),
        ],
      ),
    );
  }

  Widget _buildBarcodeHint() {
    final text = widget.barcodeController.text;

    if (text.isEmpty) {
      return const Text(
        'Enter barcode manually or scan using camera',
        style: TextStyle(fontSize: 12, color: Colors.grey),
      );
    } else if (text.length < 12) {
      return Text(
        '${12 - text.length} digits remaining for valid barcode',
        style: const TextStyle(fontSize: 12, color: Colors.orange),
      );
    } else if (text.length > 13) {
      return const Text(
        'Barcode too long (max 13 digits)',
        style: TextStyle(fontSize: 12, color: Colors.red),
      );
    } else {
      return const Text(
        'Valid barcode length',
        style: TextStyle(fontSize: 12, color: Colors.green),
      );
    }
  }
}
