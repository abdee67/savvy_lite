import 'package:flutter/material.dart';

class CustomTextField extends StatefulWidget {
  final String labelText;
  final bool isTablet;
  final bool isDarkTheme;
  final bool isPassword;
  final bool readOnly;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final TextInputType? keyboardType;

  const CustomTextField({
    super.key,
    required this.labelText,
    this.isTablet = false,
    this.isDarkTheme = false,
    this.isPassword = false,
    this.readOnly = false,
    this.controller,
    this.validator,
    this.onChanged,
    this.keyboardType,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.isTablet ? 60 : 56,
      child: TextFormField(
        obscureText: widget.isPassword,
        validator: widget.validator,
        onChanged: widget.onChanged,
        keyboardType: widget.keyboardType,
        readOnly: widget.readOnly,
        style: TextStyle(
          color: widget.isDarkTheme ? Colors.white : Colors.black,
        ),
        decoration: InputDecoration(
          labelText: widget.labelText,
          labelStyle: TextStyle(
            color: widget.isDarkTheme
                ? Colors.amber
                : const Color.fromARGB(255, 34, 102, 179),
            fontSize: widget.isTablet ? 16 : 14,
          ),
          filled: true,
          fillColor: widget.isDarkTheme ? Colors.grey[800] : Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(widget.isTablet ? 12 : 50),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(widget.isTablet ? 12 : 10),
            borderSide: const BorderSide(
              color: Color.fromARGB(255, 35, 117, 175),
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(widget.isTablet ? 12 : 10),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(widget.isTablet ? 12 : 10),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: widget.isTablet ? 16 : 12,
            vertical: widget.isTablet ? 16 : 12,
          ),
        ),
      ),
    );
  }
}
