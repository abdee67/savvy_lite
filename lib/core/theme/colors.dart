import 'package:flutter/material.dart';

class AppColors {
  // Primary colors
  static const Color primary = Color(0xFF0066FF);
  static const Color primaryDark = Color(0xFF0052D4);
  static const Color primaryLight = Color(0xFF3385FF);

  // Secondary colors
  static const Color secondary = Color(0xFF6B7280);
  static const Color secondaryDark = Color(0xFF374151);
  static const Color secondaryLight = Color(0xFF9CA3AF);

  // Semantic colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Grey scale (modern palette)
  static const Color grey50 = Color(0xFFF9FAFB);
  static const Color grey100 = Color(0xFFF3F4F6);
  static const Color grey200 = Color(0xFFE5E7EB);
  static const Color grey300 = Color(0xFFD1D5DB);
  static const Color grey400 = Color(0xFF9CA3AF);
  static const Color grey500 = Color(0xFF6B7280);
  static const Color grey600 = Color(0xFF4B5563);
  static const Color grey700 = Color(0xFF374151);
  static const Color grey800 = Color(0xFF1F2937);
  static const Color grey900 = Color(0xFF111827);

  // Additional modern colors
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF8FAFC);
  static const Color onSurface = Color(0xFF1F2937);

  // Gradient colors
  static const Gradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0066FF), Color(0xFF0052D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
