import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatefulWidget {
  final String labelText;
  final bool isTablet;
  final bool isDarkTheme;
  final bool isPassword;
  final bool readOnly;
  final TextEditingController? controller;
  final void Function(String)? onChanged;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final String? value;
  final AutovalidateMode autovalidateMode;
  final bool enabled;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final TextInputAction? textInputAction;
  final String? hintText;
  final FocusNode? focusNode;
  final bool obscureText;
  final String? suffixText;

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
    this.value,
    this.autovalidateMode = AutovalidateMode.disabled,
    this.enabled = true,
    this.inputFormatters,
    this.suffixIcon,
    this.prefixIcon,
    this.hintText,
    this.textInputAction,
    this.focusNode,
    this.obscureText = false,
    this.suffixText,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late TextEditingController _controller;
  Timer? _debounce;
  String? _lastValue;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _lastValue = widget.value;

    // Schedule the initial value setting for after the build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.value != null && !_initialized) {
        _controller.text = widget.value!;
        _lastValue = widget.value;
        _initialized = true;
      }
    });
  }

  @override
  void didUpdateWidget(CustomTextField oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Use post-frame callback to avoid setState during build
    if (widget.value != _lastValue) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _lastValue = widget.value;
            _controller.text = widget.value ?? '';
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.isTablet ? 60 : 56,
      child: TextFormField(
        controller: _controller,
        obscureText: widget.obscureText,
        validator: widget.validator,
        autovalidateMode: widget.autovalidateMode,
        keyboardType: widget.keyboardType,
        readOnly: widget.readOnly,
        enabled: widget.enabled,
        inputFormatters: widget.inputFormatters,
        textInputAction: widget.textInputAction,
        focusNode: widget.focusNode,
        style: TextStyle(
          color: widget.isDarkTheme ? Colors.white : Colors.black,
        ),
        textAlign: TextAlign.center,
        onChanged: (value) {
          // Cancel previous timer
          if (_debounce?.isActive ?? false) _debounce!.cancel();

          // Start a new timer
          _debounce = Timer(const Duration(milliseconds: 500), () {
            if (widget.onChanged != null) {
              widget.onChanged!(value);
            }
          });
        },
        decoration: InputDecoration(
          suffixIcon: widget.suffixIcon,
          suffixText: widget.suffixText,
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
