import 'package:flutter/material.dart';

class PaymentScreen extends StatelessWidget {
  final double totalAmount;

  const PaymentScreen({super.key, required this.totalAmount});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Summary & Payment'),
        backgroundColor: const Color(0xFF155888),
        foregroundColor: Colors.white,
      ),
      body: const PaymentContent(),
    );
  }
}

class PaymentContent extends StatefulWidget {
  const PaymentContent({super.key});

  @override
  State<PaymentContent> createState() => _PaymentContentState();
}

class _PaymentContentState extends State<PaymentContent> {
  double subtotal = 1250.00;
  double tax = 125.00;
  double discountAmount = 0.0;
  double withholdAmount = 0.0;
  double totalAmount = 1375.00;

  bool applyWithhold = false;
  bool applyDiscount = false;

  String paymentType = 'Cash';
  String? paymentMethod;
  String? paymentInstrument;

  final List<String> paymentMethods = [
    'Credit Card',
    'Bank Transfer',
    'Cash on Delivery',
  ];
  final List<String> paymentInstruments = ['Cash', 'Check', 'Bank Transfer'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Upper part - White background
        Expanded(
          flex: 6,
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Order Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildSummaryRow(
                  'Subtotal:',
                  '\$${subtotal.toStringAsFixed(2)}',
                ),
                const SizedBox(height: 12),
                _buildWithholdSection(),
                const SizedBox(height: 12),
                _buildSummaryRow('Tax:', '\$${tax.toStringAsFixed(2)}'),
                const SizedBox(height: 12),
                _buildDiscountSection(),
                const SizedBox(height: 16),
                _buildSummaryRow(
                  'Total Amount:',
                  '\$${totalAmount.toStringAsFixed(2)}',
                  isBold: true,
                ),
              ],
            ),
          ),
        ),

        // Lower part - Black background
        Expanded(
          flex: 4,
          child: Container(
            color: Colors.black,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payment Method & Instrument',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildPaymentTypeSelector(),
                const SizedBox(height: 16),
                _buildPaymentMethodDropdown(),
                const SizedBox(height: 16),
                _buildPaymentInstrumentDropdown(),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Process payment
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Payment processed successfully!'),
                        ),
                      );
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF155888),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Complete Payment'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildWithholdSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Apply Withhold', style: TextStyle(fontSize: 16)),
        Row(
          children: [
            Checkbox(
              value: applyWithhold,
              onChanged: (value) {
                setState(() {
                  applyWithhold = value!;
                  if (!applyWithhold) {
                    withholdAmount = 0.0;
                    _recalculateTotal();
                  }
                });
              },
            ),
            SizedBox(
              width: 100,
              child: TextFormField(
                enabled: applyWithhold,
                initialValue: withholdAmount.toStringAsFixed(2),
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 16),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    setState(() {
                      withholdAmount = double.parse(value);
                      _recalculateTotal();
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDiscountSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Discount', style: TextStyle(fontSize: 16)),
        Row(
          children: [
            Checkbox(
              value: applyDiscount,
              onChanged: (value) {
                setState(() {
                  applyDiscount = value!;
                  if (!applyDiscount) {
                    discountAmount = 0.0;
                    _recalculateTotal();
                  }
                });
              },
            ),
            SizedBox(
              width: 100,
              child: TextFormField(
                enabled: applyDiscount,
                initialValue: discountAmount.toStringAsFixed(2),
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 16),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    setState(() {
                      discountAmount = double.parse(value);
                      _recalculateTotal();
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Type:',
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildPaymentTypeChip('Cash', 'Cash'),
            const SizedBox(width: 12),
            _buildPaymentTypeChip('Credit', 'Credit'),
            const SizedBox(width: 12),
            _buildPaymentTypeChip('Advance', 'Advance'),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentTypeChip(String label, String value) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: paymentType == value ? Colors.white : Colors.black,
        ),
      ),
      selected: paymentType == value,
      selectedColor: const Color(0xFF155888),
      onSelected: (selected) {
        setState(() {
          paymentType = value;
        });
      },
    );
  }

  Widget _buildPaymentMethodDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Method:',
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButton<String>(
            value: paymentMethod,
            isExpanded: true,
            underline: const SizedBox(),
            hint: const Text('Select Payment Method'),
            items: paymentMethods.map((String value) {
              return DropdownMenuItem<String>(value: value, child: Text(value));
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                paymentMethod = newValue;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentInstrumentDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Instrument:',
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButton<String>(
            value: paymentInstrument,
            isExpanded: true,
            underline: const SizedBox(),
            hint: const Text('Select Payment Instrument'),
            items: paymentInstruments.map((String value) {
              return DropdownMenuItem<String>(value: value, child: Text(value));
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                paymentInstrument = newValue;
              });
            },
          ),
        ),
      ],
    );
  }

  void _recalculateTotal() {
    setState(() {
      totalAmount = subtotal + tax - discountAmount - withholdAmount;
    });
  }
}
