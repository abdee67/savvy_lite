import 'package:flutter/material.dart';
import 'package:savvy_stock/models/customer.dart';
import 'package:savvy_stock/models/SalesEntry/salesorder.dart';
import 'package:savvy_stock/screens/item_entry.dart';
import 'package:savvy_stock/widgets/salesEntry.dart/salesorder.dart/customer_details_field.dart';
import 'package:savvy_stock/widgets/salesEntry.dart/salesorder.dart/customer_section.dart';

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
  // Shared customer list
  final List<Customer> _customers = [
    Customer(
      id: '1',
      name: 'John Doe',
      tin: '123456789',
      phone: '555-1234',
      country: 'USA',
    ),
    Customer(
      id: '2',
      name: 'Jane Smith',
      tin: '987654321',
      phone: '555-5678',
      country: 'Canada',
    ),
    Customer(
      id: '3',
      name: 'Bob Johnson',
      tin: '111111111',
      phone: '555-9012',
      country: 'UK',
    ),
    Customer(
      id: '4',
      name: 'Alice Brown',
      tin: '222222222',
      phone: '555-3456',
      country: 'Australia',
    ),
    Customer(
      id: '5',
      name: 'Charlie Davis',
      tin: '333333333',
      phone: '555-7890',
      country: 'New Zealand',
    ),
    Customer(
      id: '6',
      name: 'David Wilson',
      tin: '444444444',
      phone: '555-1111',
      country: 'South Africa',
    ),
    Customer(
      id: '7',
      name: 'Emily Davis',
      tin: '555555555',
      phone: '555-2222',
      country: 'Germany',
    ),
    Customer(
      id: '8',
      name: 'Frank Johnson',
      tin: '666666666',
      phone: '555-3333',
      country: 'France',
    ),
    Customer(
      id: '9',
      name: 'Grace Brown',
      tin: '777777777',
      phone: '555-4444',
      country: 'Italy',
    ),
    Customer(
      id: '10',
      name: 'Hannah Davis',
      tin: '888888888',
      phone: '555-5555',
      country: 'Spain',
    ),
    // Add more customers as needed
  ];

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Customer Information',
          style: TextStyle(
            color: Color.fromARGB(255, 21, 88, 136),
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
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
                customers: _customers,
                onChanged: (Customer? value) {
                  setState(() {
                    _selectedBillToCustomer = value;
                    _selectedShipToCustomer = value;
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
                value: _selectedShipToCustomer,
                customers: _customers,
                onChanged: (Customer? value) {
                  setState(() {
                    _selectedShipToCustomer = value;
                  });
                },
                showAddButton: false,
              ),

              const SizedBox(height: 20),

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
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ItemEntryScreen()),
      );
    }
  }
}
