import 'package:savvy_stock/features/licensing/model/license_payload_model.dart';

class LicenseValidationResult {
  final bool isValid;
  final LicensePayload? payload;
  final String? errorMessage;
  final int daysRemaining;

  LicenseValidationResult({
    required this.isValid,
    this.payload,
    this.errorMessage,
    this.daysRemaining = 0,
  });

  factory LicenseValidationResult.valid(
    LicensePayload payload,
    int daysRemaining,
  ) {
    return LicenseValidationResult(
      isValid: true,
      payload: payload,
      daysRemaining: daysRemaining,
    );
  }

  factory LicenseValidationResult.invalid(String errorMessage) {
    return LicenseValidationResult(isValid: false, errorMessage: errorMessage);
  }
}
