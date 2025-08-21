import 'package:flutter/material.dart';

class CustomerDetailScreen extends StatefulWidget {
  final TextEditingController tinController;
  final TextEditingController phoneController;
  final TextEditingController countryController;
  final TextEditingController dateController;

  const CustomerDetailScreen({
    super.key,
    required this.tinController,
    required this.phoneController,
    required this.countryController,
    required this.dateController,
  });

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  final TextEditingController _dateController = TextEditingController();

  void selectDate(BuildContext context) {
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text(
          'Customer Details:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: widget.tinController,
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
          controller: widget.phoneController,
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
          controller: widget.countryController,
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
            selectDate(context);
          },
          controller: widget.dateController,
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
}
