import 'package:flutter/material.dart';

class CustomTextField extends StatefulWidget {
  final String label;
  final String value;
  final TextInputType keyboardType;
  final bool readOnly;
  final bool isPassword;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final TextEditingController? controller;
  const CustomTextField({
    super.key,
    required this.label,
    required this.value,
    required this.keyboardType,
    required this.readOnly,
    this.isPassword = false,
    this.validator,
    this.onChanged,
    this.controller,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: TextStyle(color: Color.fromARGB(255, 10, 38, 58)),
        fillColor: Color.fromARGB(220, 228, 228, 228),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide(color: Color.fromARGB(255, 10, 38, 58)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
      keyboardType: widget.keyboardType,
      controller: widget.controller,
      readOnly: widget.readOnly,
      onChanged: widget.onChanged,
      obscureText: widget.isPassword,
      validator: widget.validator,
    );
  }
}
