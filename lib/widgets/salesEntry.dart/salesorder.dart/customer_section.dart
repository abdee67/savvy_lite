import 'package:flutter/material.dart';
import 'package:savvy_stock/models/customer.dart';
import 'package:savvy_stock/widgets/salesEntry.dart/salesorder.dart/customerdropdown.dart';

class CustomerSectionScreen extends StatefulWidget {
  final String title;
  final Customer? value;
  final ValueChanged<Customer?> onChanged;
  final bool showAddButton;
  const CustomerSectionScreen({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    required this.showAddButton,
  });

  @override
  State<CustomerSectionScreen> createState() => _CustomerSectionScreenState();
}

class _CustomerSectionScreenState extends State<CustomerSectionScreen> {
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
  void showAddCustomerDialog() {
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
                              // customers.add(newCustomer);
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        // Use a custom dropdown to handle complex content
        CustomerDropdown(value: widget.value, onChanged: widget.onChanged),
        if (widget.showAddButton) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: showAddCustomerDialog,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Customer'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Color.fromARGB(255, 21, 88, 136),
              side: BorderSide(color: Color.fromARGB(255, 21, 88, 136)),
            ),
          ),
        ],
      ],
    );
  }
}
