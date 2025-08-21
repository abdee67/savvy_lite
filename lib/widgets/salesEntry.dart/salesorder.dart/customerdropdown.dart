import 'package:flutter/material.dart';
import 'package:savvy_stock/models/customer.dart';

class CustomerDropdown extends StatefulWidget {
  final Customer? value;
  final ValueChanged<Customer?> onChanged;
  const CustomerDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  State<CustomerDropdown> createState() => _CustomerDropdownState();
}

class _CustomerDropdownState extends State<CustomerDropdown> {
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

  @override
  Widget build(BuildContext context) {
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
      onSelected: widget.onChanged,
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
              widget.value?.name ?? '--Select One--',
              style: TextStyle(
                color: widget.value != null ? Colors.black : Colors.grey,
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
