// features/stock/location_master/widgets/location_code_form.dart
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Iconsax.location,
                  size: 20,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Location Hierarchy',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 500;
              return Column(
                children: [
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildColumn(0, 5)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildColumn(5, 10)),
                      ],
                    )
                  else
                    _buildColumn(0, 10),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildColumn(int start, int end) {
    return Column(
      children: List.generate(end - start, (index) {
        final actualIndex = start + index;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildCodeField(actualIndex),
        );
      }),
    );
  }

  Widget _buildCodeField(int index) {
    final isRequired = index == 0;
    final isEnabled = index < isFieldEnabled.length
        ? isFieldEnabled[index]
        : true;
    final label = 'Level ${index + 1}${isRequired ? '*' : ''}';

    return TextFormField(
      controller: controllers[index],
      enabled: isEnabled,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isEnabled ? const Color(0xFF333333) : Colors.grey[400],
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
        filled: true,
        fillColor: isEnabled
            ? Colors.grey[50]
            : Colors.grey[100]!.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1C4292), width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[100]!),
        ),
        prefixIcon: Icon(
          Iconsax.hierarchy,
          size: 18,
          color: isEnabled
              ? const Color(0xFF1C4292).withOpacity(0.5)
              : Colors.grey[300],
        ),
        suffixIcon: isRequired && controllers[index].text.isEmpty
            ? Container(
                margin: const EdgeInsets.all(12),
                child: const CircleAvatar(
                  backgroundColor: Colors.red,
                  radius: 3,
                ),
              )
            : null,
      ),
      maxLength: 30,
      buildCounter:
          (context, {required currentLength, required isFocused, maxLength}) =>
              null,
      onChanged: (value) => onCodeChanged(index, value),
      validator: isRequired
          ? (value) {
              if (value == null || value.isEmpty) {
                return 'Required';
              }
              return null;
            }
          : null,
    );
  }
}
