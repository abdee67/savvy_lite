import 'package:flutter/material.dart';
import 'package:savvy_stock/core/theme/colors.dart';
import 'package:savvy_stock/core/theme/text_styles.dart';

/// Button styles for the reusable AppButton widget.
enum AppButtonStyle { primary, secondary, outlined }

/// A highly reusable button widget with support for loading state,
/// icons, width constraints, and three visual styles.
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final AppButtonStyle style;
  final bool isLoading;
  final IconData? icon;
  final double? width;

  /// Default constructor with [AppButtonStyle.primary] style.
  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.style = AppButtonStyle.primary,
    this.isLoading = false,
    this.icon,
    this.width,
  });

  /// Shortcut constructor for primary button style.
  const AppButton.primary({
    Key? key,
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
    IconData? icon,
    double? width,
  }) : this(
         key: key,
         text: text,
         onPressed: onPressed,
         style: AppButtonStyle.primary, // Pass style here instead
         isLoading: isLoading,
         icon: icon,
         width: width,
       );

  const AppButton.secondary({
    Key? key,
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
    IconData? icon,
    double? width,
  }) : this(
         key: key,
         text: text,
         onPressed: onPressed,
         style: AppButtonStyle.secondary,
         isLoading: isLoading,
         icon: icon,
         width: width,
       );

  const AppButton.outlined({
    Key? key,
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
    IconData? icon,
    double? width,
  }) : this(
         key: key,
         text: text,
         onPressed: onPressed,
         style: AppButtonStyle.outlined,
         isLoading: isLoading,
         icon: icon,
         width: width,
       );

  @override
  Widget build(BuildContext context) {
    final buttonStyle = _getButtonStyle();

    return SizedBox(
      width: width,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: buttonStyle,
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(text, style: _getTextStyle()),
                ],
              ),
      ),
    );
  }

  /// Returns button styling based on [AppButtonStyle].
  ButtonStyle _getButtonStyle() {
    switch (style) {
      case AppButtonStyle.primary:
        return ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 2,
        );

      case AppButtonStyle.secondary:
        return ElevatedButton.styleFrom(
          backgroundColor: AppColors.grey100,
          foregroundColor: AppColors.onSurface,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        );

      case AppButtonStyle.outlined:
        return ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: AppColors.primary),
          ),
          elevation: 0,
        );
    }
  }

  /// Returns text styling based on [AppButtonStyle].
  TextStyle _getTextStyle() {
    switch (style) {
      case AppButtonStyle.primary:
        return AppTextStyles.labelLarge.copyWith(color: Colors.white);
      case AppButtonStyle.secondary:
        return AppTextStyles.labelLarge;
      case AppButtonStyle.outlined:
        return AppTextStyles.labelLarge.copyWith(color: AppColors.primary);
    }
  }
}
