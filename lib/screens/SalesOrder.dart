import 'package:flutter/material.dart';
import 'package:savvy_stock/models/customer.dart';
import 'package:savvy_stock/models/SalesEntry/salesorder.dart';
import 'package:savvy_stock/screens/item_entry.dart';
import 'package:savvy_stock/widgets/salesEntry.dart/salesorder.dart/barcode_section.dart';
import 'package:savvy_stock/widgets/salesEntry.dart/salesorder.dart/customer_details_field.dart';
import 'package:savvy_stock/widgets/salesEntry.dart/salesorder.dart/customer_section.dart';
import 'package:savvy_stock/widgets/salesEntry.dart/salesorder.dart/item_list.dart';

class SalesOrderScreen extends StatefulWidget {
  const SalesOrderScreen({super.key});

  @override
  State<SalesOrderScreen> createState() => _SalesOrderScreenState();
}

class _SalesOrderScreenState extends State<SalesOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _tinController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  // Form state variables
  Customer? _selectedBillToCustomer;
  Customer? _selectedShipToCustomer;
  bool _useBarcode = false;
  final List<SalesOrderItem> _items = [];

  @override
  void dispose() {
    _tinController.dispose();
    _phoneController.dispose();
    _countryController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Order'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Customer Bill To section
              CustomerSectionScreen(
                title: 'Customer Bill To:',
                value: _selectedBillToCustomer,
                onChanged: (Customer? value) {
                  setState(() {
                    _selectedBillToCustomer = value;
                    if (value != null) {
                      _tinController.text = value.tin;
                      _phoneController.text = value.phone;
                      _countryController.text = value.country;
                    } else {
                      _tinController.clear();
                      _phoneController.clear();
                      _countryController.clear();
                    }
                  });
                },
                showAddButton: true,
              ),

              const SizedBox(height: 16),

              // Customer details fields
              CustomerDetailScreen(
                tinController: _tinController,
                phoneController: _phoneController,
                countryController: _countryController,
                dateController: TextEditingController(),
              ),

              const SizedBox(height: 20),

              // Customer Ship To section
              CustomerSectionScreen(
                title: 'Customer Ship To:',
                value: _selectedBillToCustomer,
                onChanged: (Customer? value) {
                  setState(() {
                    _selectedShipToCustomer = value;
                  });
                },
                showAddButton: false,
              ),

              const SizedBox(height: 20),

              // Barcode toggle
              Row(
                children: [
                  Checkbox(
                    value: _useBarcode,
                    onChanged: (value) {
                      setState(() {
                        _useBarcode = value ?? false;
                      });
                    },
                  ),
                  const Text('Use Barcode'),
                ],
              ),

              const SizedBox(height: 10),

              // Barcode section (conditionally shown)
              if (_useBarcode)
                BarcodeSection(
                  onItemAdded: (item) {
                    setState(() {
                      _items.add(item);
                    });
                  },
                ),

              const SizedBox(height: 20),

              // Items list
              ItemList(
                items: _items,
                onItemRemoved: (index) {
                  setState(() {
                    _items.removeAt(index);
                  });
                },
              ),
              // Next button
              Container(
                alignment: Alignment.bottomRight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: goToNextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF155888),
                        foregroundColor: Colors.white,
                        alignment: Alignment.center,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text('Next', style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void goToNextPage() {
    if (_formKey.currentState!.validate()) {
      // Navigate to next page
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Proceeding to next page')));

      // In a real app, you would navigate to the next screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ItemEntryScreen()),
      );
    }
  }
}
