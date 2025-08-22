import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:savvy_stock/models/selectedItem.dart';

class SummaryPaymentPage extends StatefulWidget {
  final List<SelectedItem> selectedItems;
  final double totalAmount;

  const SummaryPaymentPage({
    super.key,
    required this.selectedItems,
    required this.totalAmount,
  });

  @override
  _SummaryPaymentPageState createState() => _SummaryPaymentPageState();
}

class _SummaryPaymentPageState extends State<SummaryPaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final NumberFormat currencyFormat = NumberFormat('#,##0.00');

  bool applyWithhold = false;
  bool applyDiscount = false;
  double taxAmount = 0.0;
  double withholdAmount = 0.0;
  double discountAmount = 0.0;
  String paymentType = 'Cash';
  String paymentMethod = '';
  String paymentInstrument = '';
  String paymentTerm = '';

  @override
  void initState() {
    super.initState();
    // Calculate tax (10% of total amount as an example)
    taxAmount = widget.totalAmount * 0.1;
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = widget.totalAmount;
    final totalAmount = subtotal + taxAmount - discountAmount - withholdAmount;

    return Scaffold(
      body: Column(
        children: [
          // Upper part - White background
          Expanded(
            child: Container(
              color: Colors.white,
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildSummaryRow('Subtotal:', subtotal),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Apply Withhold',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Checkbox(
                          value: applyWithhold,
                          onChanged: (value) {
                            setState(() {
                              applyWithhold = value ?? false;
                              if (!applyWithhold) withholdAmount = 0.0;
                            });
                          },
                        ),
                        Expanded(
                          child: TextFormField(
                            enabled: applyWithhold,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Withhold Amount',
                            ),
                            onChanged: (value) {
                              setState(() {
                                withholdAmount = double.tryParse(value) ?? 0.0;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    _buildSummaryRow('Tax:', taxAmount),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Discount',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Checkbox(
                          value: applyDiscount,
                          onChanged: (value) {
                            setState(() {
                              applyDiscount = value ?? false;
                              if (!applyDiscount) discountAmount = 0.0;
                            });
                          },
                        ),
                        Expanded(
                          child: TextFormField(
                            enabled: applyDiscount,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Discount Amount',
                            ),
                            onChanged: (value) {
                              setState(() {
                                discountAmount = double.tryParse(value) ?? 0.0;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    Divider(),
                    _buildSummaryRow(
                      'Total Amount:',
                      totalAmount,
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Lower part - Black background
          Container(
            height: MediaQuery.of(context).size.height * 0.4,
            color: Colors.black,
            padding: EdgeInsets.all(8),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        title: Text(
                          'Cash',
                          style: TextStyle(color: Colors.white),
                        ),
                        leading: Radio(
                          value: 'Cash',
                          groupValue: paymentType,
                          onChanged: (value) {
                            setState(() {
                              paymentType = value.toString();
                            });
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        title: Text(
                          'Credit',
                          style: TextStyle(color: Colors.white),
                        ),
                        leading: Radio(
                          value: 'Credit',
                          groupValue: paymentType,
                          onChanged: (value) {
                            setState(() {
                              paymentType = value.toString();
                            });
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        title: Text(
                          'Advance',
                          style: TextStyle(color: Colors.white),
                        ),
                        leading: Radio(
                          value: 'Advance',
                          groupValue: paymentType,
                          onChanged: (value) {
                            setState(() {
                              paymentType = value.toString();
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Payment Term',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white70),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  style: TextStyle(color: Colors.white),
                  onChanged: (value) {
                    setState(() {
                      paymentTerm = value;
                    });
                  },
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Payment Instrument',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white70),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  style: TextStyle(color: Colors.white),
                  dropdownColor: Colors.grey[900],
                  value: paymentInstrument.isNotEmpty
                      ? paymentInstrument
                      : null,
                  items: ['Cash', 'Check Payment', 'Card'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      paymentInstrument = newValue ?? '';
                    });
                  },
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Process payment
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Payment processed successfully!'),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: Text('Complete Payment'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value, {bool isBold = false}) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
          textAlign: TextAlign.left,
        ),
        TextFormField(
          initialValue: '${currencyFormat.format(value)} ETB',
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
          readOnly: true,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          ),
        ),
      ],
    );
  }
}
