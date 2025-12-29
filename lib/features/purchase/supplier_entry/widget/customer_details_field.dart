import 'package:flutter/material.dart';
import 'package:savvy_stock/core/widgets/custom_text_Form.dart';

class CustomerDetailsField extends StatefulWidget {
  const CustomerDetailsField({super.key});

  @override
  State<CustomerDetailsField> createState() => _CustomerDetailsFieldState();
}

class _CustomerDetailsFieldState extends State<CustomerDetailsField> {
  late TextEditingController _salesRefController;
  late TextEditingController _orderDateController;
  late TextEditingController _salesPersonController;

  @override
  void initState() {
    super.initState();
    _salesRefController = TextEditingController();
    _orderDateController = TextEditingController();
    _salesPersonController = TextEditingController();
  }

  @override
  void dispose() {
    _salesRefController.dispose();
    _orderDateController.dispose();
    _salesPersonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Customer Details:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        CustomTextField(
          controller: _salesRefController,
          labelText: 'Sales Ref',
          onChanged: (value) => {},
        ),
        const SizedBox(height: 8),
        CustomTextField(
          controller: _orderDateController,
          labelText: 'Order Date',
          onChanged: (value) => {},
        ),
        const SizedBox(height: 8),
        CustomTextField(
          controller: _salesPersonController,
          labelText: 'Sales Person',
          onChanged: (value) => {},
        ),
      ],
    );
  }
}
