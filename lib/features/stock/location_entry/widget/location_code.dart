// features/stock/location_master/widgets/location_code_form.dart
import 'package:flutter/material.dart';

class LocationCodeForm extends StatelessWidget {
  final List<TextEditingController> controllers;
  final Function(int index, String value) onCodeChanged;
  final List<bool> isFieldEnabled;

  const LocationCodeForm({
    super.key,
    required this.controllers,
    required this.onCodeChanged,
    required this.isFieldEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Location Codes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildLeftColumn()),
                const SizedBox(width: 16),
                Expanded(child: _buildRightColumn()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftColumn() {
    return Column(
      children: [
        _buildCodeField(0, 'Code 1*'),
        const SizedBox(height: 8),
        _buildCodeField(1, 'Code 2'),
        const SizedBox(height: 8),
        _buildCodeField(2, 'Code 3'),
        const SizedBox(height: 8),
        _buildCodeField(3, 'Code 4'),
        const SizedBox(height: 8),
        _buildCodeField(4, 'Code 5'),
      ],
    );
  }

  Widget _buildRightColumn() {
    return Column(
      children: [
        _buildCodeField(5, 'Code 6'),
        const SizedBox(height: 8),
        _buildCodeField(6, 'Code 7'),
        const SizedBox(height: 8),
        _buildCodeField(7, 'Code 8'),
        const SizedBox(height: 8),
        _buildCodeField(8, 'Code 9'),
        const SizedBox(height: 8),
        _buildCodeField(9, 'Code 10'),
      ],
    );
  }

  Widget _buildCodeField(int index, String label) {
    final isRequired = index == 0; // Only Code 1 is required
    final isEnabled = index < isFieldEnabled.length
        ? isFieldEnabled[index]
        : true;

    return TextFormField(
      controller: controllers[index],
      enabled: isEnabled,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: isRequired
            ? const Icon(Icons.star, color: Colors.red, size: 12)
            : null,
      ),
      maxLength: 30,
      onChanged: (value) => onCodeChanged(index, value),
      validator: isRequired
          ? (value) {
              if (value == null || value.isEmpty) {
                return 'Code 1 is required';
              }
              return null;
            }
          : null,
    );
  }
}
