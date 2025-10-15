import 'package:flutter/material.dart';
import 'package:savvy_stock/core/widgets/custom_text_Form.dart';

class CustomerDetailsField extends StatefulWidget {
  final String tin;
  final String phone;
  final String country;
  final Function(String tin, String phone, String country) onDetailsChanged;

  const CustomerDetailsField({
    super.key,
    required this.tin,
    required this.phone,
    required this.country,
    required this.onDetailsChanged,
  });

  @override
  State<CustomerDetailsField> createState() => _CustomerDetailsFieldState();
}

class _CustomerDetailsFieldState extends State<CustomerDetailsField> {
  late TextEditingController _tinController;
  late TextEditingController _phoneController;
  late TextEditingController _countryController;

  @override
  void initState() {
    super.initState();
    _tinController = TextEditingController(text: widget.tin);
    _phoneController = TextEditingController(text: widget.phone);
    _countryController = TextEditingController(text: widget.country);
  }

  @override
  void didUpdateWidget(CustomerDetailsField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tin != _tinController.text) {
      _tinController.text = widget.tin;
    }
    if (widget.phone != _phoneController.text) {
      _phoneController.text = widget.phone;
    }
    if (widget.country != _countryController.text) {
      _countryController.text = widget.country;
    }
  }

  @override
  void dispose() {
    _tinController.dispose();
    _phoneController.dispose();
    _countryController.dispose();
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
          controller: _tinController,
          labelText: 'TIN',
          onChanged: (value) => _onDetailsChanged(),
        ),
        const SizedBox(height: 8),
        CustomTextField(
          controller: _phoneController,
          labelText: 'Phone',
          onChanged: (value) => _onDetailsChanged(),
        ),
        const SizedBox(height: 8),
        CustomTextField(
          controller: _countryController,
          labelText: 'Country',
          onChanged: (value) => _onDetailsChanged(),
        ),
      ],
    );
  }

  void _onDetailsChanged() {
    widget.onDetailsChanged(
      _tinController.text,
      _phoneController.text,
      _countryController.text,
    );
  }
}
