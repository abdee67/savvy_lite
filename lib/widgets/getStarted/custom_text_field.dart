import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String labelText;
  final bool isTablet;
  final bool isDarkTheme;
  final bool isPassword;
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
    this.controller,
    this.validator,
    this.onChanged,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: isTablet ? 60 : 56,
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        validator: validator,
        onChanged: onChanged,
        keyboardType: keyboardType,
        style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black),
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(
            color: isDarkTheme ? Colors.white70 : Colors.grey[600],
            fontSize: isTablet ? 16 : 14,
          ),
          filled: true,
          fillColor: isDarkTheme ? Colors.grey[800] : Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
            borderSide: const BorderSide(color: Color(0xFF4DE89F), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: isTablet ? 16 : 12,
            vertical: isTablet ? 16 : 12,
          ),
        ),
      ),
    );
  }
}
