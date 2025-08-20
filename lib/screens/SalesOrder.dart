import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SalesOrderScreen extends StatefulWidget {
  const SalesOrderScreen({super.key});

  @override
  State<SalesOrderScreen> createState() => _SalesOrderScreenState();
}

class _SalesOrderScreenState extends State<SalesOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _tinController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  // Form state variables
  Customer? _selectedBillToCustomer;
  Customer? _selectedShipToCustomer;
  bool _useBarcode = false;
  List<SalesOrderItem> _items = [];

  // Mock customer data
  final List<Customer> customers = [
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
      name: 'Acme Corp',
      tin: '456123789',
      phone: '555-9012',
      country: 'UK',
    ),
    Customer(
      id: '4',
      name: 'Global Enterprises',
      tin: '789123456',
      phone: '555-3456',
      country: 'Germany',
    ),
    Customer(
      id: '5',
      name: 'Tech Solutions Ltd',
      tin: '321654987',
      phone: '555-7890',
      country: 'Japan',
    ),
  ];
  void _selectDate(BuildContext context) {
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    ).then((date) {
      if (date != null) {
        setState(() {
          _dateController.text = date.toString();
        });
      }
    });
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
              _buildCustomerSection(
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
              _buildCustomerDetailsFields(),

              const SizedBox(height: 20),

              // Customer Ship To section
              _buildCustomerSection(
                title: 'Customer Ship To:',
                value: _selectedShipToCustomer,
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

              // Barcode input (conditionally shown)
              if (_useBarcode) _buildBarcodeSection(),

              const SizedBox(height: 20),

              // Items grid/list
              _buildItemsList(),

              const SizedBox(height: 30),

              // Next button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _goToNextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Next', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerSection({
    required String title,
    required Customer? value,
    required ValueChanged<Customer?> onChanged,
    required bool showAddButton,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        // Use a custom dropdown to handle complex content
        _buildCustomDropdown(value: value, onChanged: onChanged),
        if (showAddButton) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _showAddCustomerDialog,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Customer'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue.shade700,
              side: BorderSide(color: Colors.blue.shade700),
            ),
          ),
        ],
      ],
    );
  }

  // Alternative approach using PopupMenuButton for a scrollable dropdown
  Widget _buildCustomDropdown({
    required Customer? value,
    required ValueChanged<Customer?> onChanged,
  }) {
    return PopupMenuButton<Customer>(
      itemBuilder: (BuildContext context) {
        return customers.map((Customer customer) {
          return PopupMenuItem<Customer>(
            value: customer,
            height: 100, // Set a fixed height for each item
            child: Container(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.credit_card,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        customer.tin,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        customer.phone,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        customer.country,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList();
      },
      onSelected: onChanged,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(30.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value?.name ?? '--Select One--',
              style: TextStyle(
                color: value != null ? Colors.black : Colors.grey,
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerDetailsFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Customer Details:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _tinController,
          decoration: InputDecoration(
            labelText: 'TIN Number',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30.0),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            suffixIcon: const Icon(Icons.credit_card),
          ),
          readOnly: true, // Make it read-only since it's auto-filled
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _phoneController,
          decoration: InputDecoration(
            labelText: 'Phone Number',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30.0),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            suffixIcon: const Icon(Icons.phone),
          ),
          readOnly: true, // Make it read-only since it's auto-filled
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _countryController,
          decoration: InputDecoration(
            labelText: 'Country',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30.0),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            suffixIcon: const Icon(Icons.location_on),
          ),
          readOnly: true, // Make it read-only since it's auto-filled
        ),
        const SizedBox(height: 12),
        TextFormField(
          onTap: () {
            _selectDate(context);
          },
          controller: _dateController,
          decoration: InputDecoration(
            labelText: 'Date',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30.0),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            suffixIcon: const Icon(Icons.calendar_today),
          ),
          readOnly: true, // Make it read-only since it's auto-filled
        ),
      ],
    );
  }

  Widget _buildBarcodeSection() {
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
                    _submitBarcode(value);
                  }
                },
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: _showBarcodeScanner,
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

  Widget _buildItemsList() {
    if (_items.isEmpty) {
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
          itemCount: _items.length,
          itemBuilder: (context, index) {
            final item = _items[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: Text(item.name),
                subtitle: Text(
                  'Qty: ${item.quantity} | Price: \$${item.price.toStringAsFixed(2)}',
                ),
                trailing: Text(
                  '\$${(item.quantity * item.price).toStringAsFixed(2)}',
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showAddCustomerDialog() {
    final formKey = GlobalKey<FormState>();

    // Controllers for the form fields
    final customerNameController = TextEditingController();
    final tinController = TextEditingController();
    final contactNameController = TextEditingController();
    final titleController = TextEditingController();
    final phone1Controller = TextEditingController();
    final phone2Controller = TextEditingController();
    final countryController = TextEditingController(text: 'Ethiopia');
    final stateController = TextEditingController();
    final cityController = TextEditingController();
    final regionController = TextEditingController();
    final addressLine1Controller = TextEditingController();
    final addressLine2Controller = TextEditingController();
    final addressLine3Controller = TextEditingController();
    final addressLine4Controller = TextEditingController();
    final addressLine5Controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Center(
                    child: Text(
                      'Add New Customer',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Customer Information Section
                  const Text(
                    'Customer Information',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: customerNameController,
                    decoration: const InputDecoration(
                      labelText: 'Customer Name *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter customer name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: tinController,
                    decoration: const InputDecoration(
                      labelText: 'TIN *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter TIN';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Contact Details Section
                  const Text(
                    'Contact Details',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: contactNameController,
                    decoration: const InputDecoration(
                      labelText: 'Contact Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: phone1Controller,
                    decoration: const InputDecoration(
                      labelText: 'Phone 1 *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter phone number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: phone2Controller,
                    decoration: const InputDecoration(
                      labelText: 'Phone 2',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 20),

                  // Address Details Section
                  const Text(
                    'Address Details',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: countryController,
                    decoration: const InputDecoration(
                      labelText: 'Country',
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: stateController,
                    decoration: const InputDecoration(
                      labelText: 'State/Region',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: cityController,
                    decoration: const InputDecoration(
                      labelText: 'City',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: regionController,
                    decoration: const InputDecoration(
                      labelText: 'Region/Zone',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Additional Address Section
                  const Text(
                    'Additional Address',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: addressLine1Controller,
                    decoration: const InputDecoration(
                      labelText: 'Address Line 1',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: addressLine2Controller,
                    decoration: const InputDecoration(
                      labelText: 'Address Line 2',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: addressLine3Controller,
                    decoration: const InputDecoration(
                      labelText: 'Address Line 3',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: addressLine4Controller,
                    decoration: const InputDecoration(
                      labelText: 'Address Line 4',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: addressLine5Controller,
                    decoration: const InputDecoration(
                      labelText: 'Address Line 5',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            // Create new customer
                            final newCustomer = Customer(
                              id: DateTime.now().millisecondsSinceEpoch
                                  .toString(),
                              name: customerNameController.text,
                              tin: tinController.text,
                              phone: phone1Controller.text,
                              country: countryController.text,
                            );

                            // Add to customers list
                            setState(() {
                              customers.add(newCustomer);
                            });

                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Customer added successfully'),
                              ),
                            );
                          }
                        },
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showBarcodeScanner() {
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
                    _submitBarcode('1234567890123');
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

  void _submitBarcode(String barcode) {
    // Simulate adding an item based on barcode
    setState(() {
      _items.add(
        SalesOrderItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: 'Item from barcode $barcode',
          quantity: 1,
          price: 10.99,
        ),
      );
    });

    // Clear the barcode field
    _barcodeController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Item added from barcode: $barcode')),
    );
  }

  void _goToNextPage() {
    if (_formKey.currentState!.validate()) {
      // Navigate to next page
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Proceeding to next page')));

      // In a real app, you would navigate to the next screen
      // Navigator.push(context, MaterialPageRoute(builder: (context) => NextPage()));
    }
  }
}

// Data models
class Customer {
  final String id;
  final String name;
  final String tin;
  final String phone;
  final String country;

  Customer({
    required this.id,
    required this.name,
    required this.tin,
    required this.phone,
    required this.country,
  });

  @override
  String toString() => name;
}

class SalesOrderItem {
  final String id;
  final String name;
  final int quantity;
  final double price;

  SalesOrderItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
  });
}
