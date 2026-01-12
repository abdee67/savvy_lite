import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/licensing/model/license_payload_model.dart';
import 'package:savvy_stock/features/licensing/model/license_validation_result_model.dart';

enum LicenseStatus {
  initial,
  loading,
  loaded,
  validating,
  valid,
  invalid,
  saving,
  saved,
  cleared,
  error,
}

class LicenseState extends Equatable {
  final LicenseStatus status;
  final String? machineId;
  final LicenseValidationResult? validationResult;
  final LicensePayload? licensePayload;
  final String? errorMessage;
  final bool isLicenseAboutToExpire;
  final int daysRemaining;

  const LicenseState({
    this.status = LicenseStatus.initial,
    this.machineId,
    this.validationResult,
    this.licensePayload,
    this.errorMessage,
    this.isLicenseAboutToExpire = false,
    this.daysRemaining = 0,
  });

  bool get isLicenseValid => validationResult?.isValid ?? false;
  bool get hasLicense => licensePayload != null;
  bool get showExpirationWarning => isLicenseAboutToExpire && daysRemaining > 0;

  LicenseState copyWith({
    LicenseStatus? status,
    String? machineId,
    LicenseValidationResult? validationResult,
    LicensePayload? licensePayload,
    String? errorMessage,
    bool? isLicenseAboutToExpire,
    int? daysRemaining,
  }) {
    return LicenseState(
      status: status ?? this.status,
      machineId: machineId ?? this.machineId,
      validationResult: validationResult ?? this.validationResult,
      licensePayload: licensePayload ?? this.licensePayload,
      errorMessage: errorMessage ?? this.errorMessage,
      isLicenseAboutToExpire:
          isLicenseAboutToExpire ?? this.isLicenseAboutToExpire,
      daysRemaining: daysRemaining ?? this.daysRemaining,
    );
  }

  @override
  List<Object?> get props => [
    status,
    machineId,
    validationResult,
    licensePayload,
    errorMessage,
    isLicenseAboutToExpire,
    daysRemaining,
  ];
}
