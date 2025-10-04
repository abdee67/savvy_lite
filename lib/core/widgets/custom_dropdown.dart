import 'dart:async';
import 'package:flutter/material.dart';

class CustomDropdown<T> extends StatefulWidget {
  final String labelText;
  final bool isTablet;
  final bool isDarkTheme;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;
  final String? Function(T?)? validator;
  final T? value;
  final AutovalidateMode autovalidateMode;
  final bool enabled;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final String? hintText;
  final FocusNode? focusNode;
  final bool isDense;

  const CustomDropdown({
    super.key,
    required this.labelText,
    this.isTablet = false,
    this.isDarkTheme = false,
    required this.items,
    this.validator,
    this.onChanged,
    this.value,
    this.autovalidateMode = AutovalidateMode.disabled,
    this.enabled = true,
    this.suffixIcon,
    this.prefixIcon,
    this.hintText,
    this.focusNode,
    this.isDense = false,
  });

  @override
  State<CustomDropdown<T>> createState() => _CustomDropdownState<T>();
}

class _CustomDropdownState<T> extends State<CustomDropdown<T>> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.isTablet ? 60 : 56,
      child: DropdownButtonFormField<T>(
        value: widget.value,
        items: widget.items,
        validator: widget.validator,
        autovalidateMode: widget.autovalidateMode,
        focusNode: widget.focusNode,
        style: TextStyle(
          color: widget.isDarkTheme ? Colors.white : Colors.black,
        ),
        onChanged: widget.enabled
            ? (value) {
                if (widget.onChanged != null) {
                  widget.onChanged!(value);
                }
              }
            : null,
        decoration: InputDecoration(
          suffixIcon: widget.suffixIcon,
          prefixIcon: widget.prefixIcon,
          labelText: widget.labelText,
          hintText: widget.hintText,
          alignLabelWithHint: true,
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
