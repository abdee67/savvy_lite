import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:savvy_stock/core/theme/colors.dart';
import 'package:savvy_stock/core/theme/text_styles.dart';
import 'package:savvy_stock/core/widgets/app_button.dart';

class ReportSetupTab extends StatelessWidget {
  const ReportSetupTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Movement Report Setup',
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.grey800,
            ),
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Icon(Iconsax.chart_1, size: 64, color: AppColors.grey400),
                  const SizedBox(height: 16),
                  Text(
                    'Report Configuration',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Fast/Slow/Non-moving rules setup will be implemented here',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.grey600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppButton.primary(
                    text: 'Configure Reports',
                    onPressed: () {
                      // TODO: Implement report configuration
                    },
                    width: double.infinity,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
