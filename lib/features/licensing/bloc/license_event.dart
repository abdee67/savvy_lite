import 'package:equatable/equatable.dart';

abstract class LicenseEvent extends Equatable {
  const LicenseEvent();

  @override
  List<Object> get props => [];
}

class LoadLicense extends LicenseEvent {
  const LoadLicense();
}

class GenerateMachineId extends LicenseEvent {
  const GenerateMachineId();
}

class ValidateLicense extends LicenseEvent {
  final String licenseKey;

  const ValidateLicense(this.licenseKey);

  @override
  List<Object> get props => [licenseKey];
}

class SaveLicense extends LicenseEvent {
  final String licenseKey;

  const SaveLicense(this.licenseKey);

  @override
  List<Object> get props => [licenseKey];
}

class ClearLicense extends LicenseEvent {
  const ClearLicense();
}

class CheckLicenseExpiration extends LicenseEvent {
  const CheckLicenseExpiration();
}
