import 'package:flutter/foundation.dart';

class NumberFormatter {
  static int decimalPlaces = 2;

  static void initialize(int places) {
    decimalPlaces = places;
  }

  static String format(double value) {
    return value.toStringAsFixed(decimalPlaces);
  }

  static String formatCurrency(double value) {
    return '\$${value.toStringAsFixed(decimalPlaces)}';
  }

  static String formatPercentage(double value) {
    return '${value.toStringAsFixed(decimalPlaces)}%';
  }
}
