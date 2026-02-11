import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:ntp/ntp.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/export.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:savvy_stock/features/licensing/model/license_payload_model.dart';
import 'package:savvy_stock/features/licensing/model/license_validation_result_model.dart';
import 'package:x509_plus/x509.dart' as x509;

class LicenseService {
  static const String _licenseStorageKey = 'app_license_key';
  static const String _licensePayloadKey = 'app_license_payload';
  static const String _lastKnownTimeKey = 'license_last_known_time';
  static const String _activationTimeKey = 'license_activation_time';
  static const String _publicKeyPath = 'assets/keys/public_key.cer';

  final FlutterSecureStorage _secureStorage;
  final DeviceInfoPlugin _deviceInfoPlugin;
  PublicKey? _publicKey;
  String? _cachedMachineId;

  LicenseService({
    required FlutterSecureStorage secureStorage,
    required DeviceInfoPlugin deviceInfoPlugin,
  }) : _secureStorage = secureStorage,
       _deviceInfoPlugin = deviceInfoPlugin;

  /// Initialize the service by loading the public key
  Future<void> initialize() async {
    await _loadPublicKey();
  }

  /// Generate machine ID using device info
  Future<String> generateMachineId() async {
    if (_cachedMachineId != null) {
      return _cachedMachineId!;
    }

    try {
      String uniqueId;

      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        uniqueId = androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfoPlugin.iosInfo;
        uniqueId = iosInfo.identifierForVendor ?? _generateFallbackId();
      } else if (Platform.isWindows) {
        final windowsInfo = await _deviceInfoPlugin.windowsInfo;
        uniqueId = windowsInfo.deviceId;
      } else {
        uniqueId = _generateFallbackId();
      }

      // Hash the unique ID with SHA-256
      final hash = await _sha256Hash(uniqueId);
      _cachedMachineId = hash;
      return hash;
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error generating machine ID: $e');
      }
      _cachedMachineId = _generateFallbackId();
      return _cachedMachineId!;
    }
  }

  /// Validate license key
  Future<LicenseValidationResult> validateLicense(String licenseKey) async {
    try {
      if (_publicKey == null) {
        return LicenseValidationResult.invalid(
          'License validation unavailable: Public key certificate not found or failed to load. '
          'Please checks logs for "Warning: Could not load public key certificate" and ensure assets/keys/public_key.cer exists.',
        );
      }

      // 1. Parse the key
      final parts = licenseKey.split('.');
      if (parts.length != 2) {
        return LicenseValidationResult.invalid(
          'Invalid license key format. Expected format: payload.signature',
        );
      }

      // 2. Decode payload and signature
      final payloadBytes = base64.decode(parts[0]);
      final signatureBytes = base64.decode(parts[1]);
      final payloadJson = utf8.decode(payloadBytes);

      // 3. Verify the RSA signature
      final isValidSignature = await _verifySignature(
        payloadBytes,
        signatureBytes,
      );
      if (!isValidSignature) {
        return LicenseValidationResult.invalid(
          'Signature verification failed. The key is counterfeit or has been tampered with.',
        );
      }

      // 4. Deserialize the payload
      final payloadMap = json.decode(payloadJson);
      final payload = LicensePayload.fromJson(payloadMap);

      // 5. Check Machine ID
      final currentMachineId = await generateMachineId();
      if (currentMachineId != payload.machineId) {
        return LicenseValidationResult.invalid(
          'License is not valid for this device. Expected: ${payload.machineId}, Found: $currentMachineId',
        );
      }

      // 6. Check Time Tampering (System clock rollback)
      final now = await _getCurrentTime();
      final lastKnownTimeStr = await _secureStorage.read(
        key: _lastKnownTimeKey,
      );
      if (lastKnownTimeStr != null) {
        final lastKnownTime = DateTime.parse(lastKnownTimeStr).toUtc();
        // Allow 5 minutes buffer for minor clock drifts
        if (now.isBefore(lastKnownTime.subtract(const Duration(minutes: 5)))) {
          return LicenseValidationResult.invalid(
            'System clock rollback detected. Please check your device date and time settings.\n'
            'Current (UTC): $now\n'
            'Last Known (UTC): $lastKnownTime',
          );
        }
      }

      // 7. Check Expiration Date (UTC)
      if (now.isAfter(payload.validTo.toUtc())) {
        if (kDebugMode) {
          developer.log('License expired on ${payload.validTo.toUtc()}');
        }
        return LicenseValidationResult.invalid(
          'License expired on ${payload.validTo.toLocal()}',
        );
      }

      // 8. Update Last Known Time
      // Only update if now is later than the last stored time
      if (lastKnownTimeStr == null ||
          now.isAfter(DateTime.parse(lastKnownTimeStr).toUtc())) {
        await _secureStorage.write(
          key: _lastKnownTimeKey,
          value: now.toIso8601String(),
        );
      }

      // 9. Calculate days remaining (round up to include current partial day)
      final difference = payload.validTo.toUtc().difference(now);
      final daysRemaining = (difference.inSeconds / 86400).ceil();

      return LicenseValidationResult.valid(payload, daysRemaining);
    } catch (e) {
      if (kDebugMode) {
        developer.log('License validation failed: ${e.toString()}');
      }

      return LicenseValidationResult.invalid(
        'License validation failed: ${e.toString()}',
      );
    }
  }

  /// Save license key to secure storage
  Future<void> saveLicense(String licenseKey, LicensePayload payload) async {
    final nowUtc = (await _getCurrentTime()).toIso8601String();
    await Future.wait([
      _secureStorage.write(key: _licenseStorageKey, value: licenseKey),
      _secureStorage.write(
        key: _licensePayloadKey,
        value: json.encode(payload.toJson()),
      ),
      _secureStorage.write(key: _activationTimeKey, value: nowUtc),
      _secureStorage.write(key: _lastKnownTimeKey, value: nowUtc),
    ]);
  }

  /// Load license from secure storage
  Future<LicenseValidationResult> loadAndValidateLicense() async {
    try {
      final licenseKey = await _secureStorage.read(key: _licenseStorageKey);
      if (licenseKey == null || licenseKey.isEmpty) {
        // Check for Free Trial
        final trialActive = await _secureStorage.read(key: 'trial_active');
        if (trialActive == 'true') {
          return await _validateTrial();
        }
        return LicenseValidationResult.invalid('No license found');
      }

      return await validateLicense(licenseKey);
    } catch (e) {
      developer.log('Failed to load license: ${e.toString()}');
      return LicenseValidationResult.invalid('Failed to load license}');
    }
  }

  /// Clear license from storage
  Future<void> clearLicense() async {
    await Future.wait([
      _secureStorage.delete(key: _licenseStorageKey),
      _secureStorage.delete(key: _licensePayloadKey),
      _secureStorage.delete(key: _lastKnownTimeKey),
      _secureStorage.delete(key: _activationTimeKey),
    ]);
    if (kDebugMode) {
      developer.log('all cleared');
    }
  }

  /// Check if license is about to expire (within 15 days)
  Future<bool> isLicenseAboutToExpire() async {
    try {
      final payload = await getLicensePayload();
      if (payload == null) return false;

      final now = await _getCurrentTime();
      final difference = payload.validTo.toUtc().difference(now);
      final daysRemaining = (difference.inSeconds / 86400).ceil();

      return daysRemaining >= 0 && daysRemaining <= 15;
    } catch (e) {
      return false;
    }
  }

  /// Get days remaining for license
  Future<int> getDaysRemaining() async {
    try {
      final payload = await getLicensePayload();
      if (payload == null) return 0;

      final now = await _getCurrentTime();
      final difference = payload.validTo.toUtc().difference(now);
      final daysRemaining = (difference.inSeconds / 86400).ceil();

      return daysRemaining > 0 ? daysRemaining : 0;
    } catch (e) {
      return 0;
    }
  }

  /// Get license payload from storage
  Future<LicensePayload?> getLicensePayload() async {
    try {
      // 1. Try to load paid license payload
      final payloadJson = await _secureStorage.read(key: _licensePayloadKey);
      if (payloadJson != null) {
        final payloadMap = json.decode(payloadJson);
        return LicensePayload.fromJson(payloadMap);
      }

      // 2. Fallback to Trial Payload if active
      final trialActive = await _secureStorage.read(key: 'trial_active');
      if (trialActive == 'true') {
        final startDateStr = await _secureStorage.read(key: 'trial_start_date');
        final daysStr = await _secureStorage.read(key: 'trial_days');

        if (startDateStr != null) {
          final startDate = DateTime.parse(startDateStr);
          final durationDays = int.tryParse(daysStr ?? '5') ?? 5;
          final validTo = startDate.add(Duration(days: durationDays));

          final machineId = await generateMachineId();
          final usersStr = await _secureStorage.read(key: 'trial_users');
          final branchesStr = await _secureStorage.read(key: 'trial_branches');

          return LicensePayload(
            licenseId: 'TRIAL',
            issuedTo: 'Trial User',
            machineId: machineId,
            issueDate: startDateStr,
            validFrom: startDate,
            validTo: validTo,
            userLimit: int.tryParse(usersStr ?? '3') ?? 3,
            branchLimit: int.tryParse(branchesStr ?? '2') ?? 2,
            features: 'TRIAL',
          );
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // Private methods
  Future<void> _loadPublicKey() async {
    try {
      // Load certificate as bytes (DER format is binary)
      final certBytes = await rootBundle.load(_publicKeyPath);
      final certData = certBytes.buffer.asUint8List();

      // Convert DER to PEM format (x509_plus only supports PEM)
      final base64Cert = base64.encode(certData);
      final pem =
          '-----BEGIN CERTIFICATE-----\n'
          '${_splitIntoLines(base64Cert, 64)}\n'
          '-----END CERTIFICATE-----';

      // Parse X.509 certificate from PEM format
      final certs = x509.parsePem(pem);

      if (certs.isEmpty) {
        throw Exception('No certificate found in file');
      }

      // Get the first certificate
      final cert = certs.first;

      // Extract the public key from the certificate
      final publicKeyInfo = cert.tbsCertificate.subjectPublicKeyInfo;

      if (publicKeyInfo.algorithm.algorithm.name != 'rsaEncryption') {
        developer.log(
          'Unsupported public key algorithm: ${publicKeyInfo.algorithm.algorithm.name}',
        );
        throw Exception('Unsupported public key algorithm');
      }

      // The subjectPublicKey is already parsed by x509_plus
      final subjectPublicKey = publicKeyInfo.subjectPublicKey;

      if (subjectPublicKey is! x509.RsaPublicKey) {
        developer.log(
          'Expected RSA public key, but got different ${subjectPublicKey.runtimeType}',
        );
        throw Exception('Expected RSA public key, but got different');
      }

      // x509.RsaPublicKey provides modulus and exponent directly
      final modulus = subjectPublicKey.modulus;
      final exponent = subjectPublicKey.exponent;

      _publicKey = RSAPublicKey(modulus, exponent);
    } catch (e) {
      // Log the error but don't throw - allow app to continue without license validation
      if (kDebugMode) {
        developer.log('Warning: Could not load public key certificate: $e');
      }
      if (kDebugMode) {
        developer.log(
          'License validation will not be available until a valid certificate is added to assets/keys/public_key.cer',
        );
      }
    }
  }

  Future<bool> _verifySignature(List<int> data, List<int> signature) async {
    try {
      if (_publicKey == null) {
        return false;
      }

      final signer = Signer('SHA-256/RSA');
      signer.init(
        false,
        PublicKeyParameter<RSAPublicKey>(_publicKey! as RSAPublicKey),
      );

      final result = signer.verifySignature(
        Uint8List.fromList(data),
        RSASignature(Uint8List.fromList(signature)),
      );

      return result;
    } catch (e) {
      if (kDebugMode) {
        developer.log('Debug: Exception during signature verification: $e');
      }
      return false;
    }
  }

  // Helper to split base64 string into lines of specified length
  String _splitIntoLines(String text, int lineLength) {
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i += lineLength) {
      final end = (i + lineLength < text.length) ? i + lineLength : text.length;
      buffer.write(text.substring(i, end));
      if (end < text.length) {
        buffer.write('\n');
      }
    }
    return buffer.toString();
  }

  Future<String> _sha256Hash(String input) async {
    final bytes = utf8.encode(input);
    final digest = Digest('SHA-256');
    final hash = digest.process(bytes);
    return hash.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Get current time from NTP or fallback to system time
  Future<DateTime> _getCurrentTime() async {
    try {
      // Use a short timeout to avoid blocking offline apps
      final now = await NTP.now(timeout: const Duration(seconds: 2));
      return now.toUtc();
    } catch (e) {
      // Fallback to system time if offline or NTP fails
      return DateTime.now().toUtc();
    }
  }

  String _generateFallbackId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomPart = random.nextInt(1000000);
    return 'fallback_${timestamp}_$randomPart';
  }

  Future<LicenseValidationResult> _validateTrial() async {
    try {
      final startDateStr = await _secureStorage.read(key: 'trial_start_date');
      final daysStr = await _secureStorage.read(key: 'trial_days');
      if (startDateStr == null) {
        return LicenseValidationResult.invalid('Invalid trial data');
      }

      final startDate = DateTime.parse(startDateStr);
      final durationDays = int.tryParse(daysStr ?? '5') ?? 5;
      final now = await _getCurrentTime();
      final validTo = startDate.add(Duration(days: durationDays));

      if (now.isAfter(validTo)) {
        return LicenseValidationResult.invalid('Free trial expired');
      }

      final difference = validTo.difference(now);
      final daysRemaining = (difference.inSeconds / 86400).ceil();

      // Create synthetic payload for trial
      final machineId = await generateMachineId();
      final usersStr = await _secureStorage.read(key: 'trial_users');
      final branchesStr = await _secureStorage.read(key: 'trial_branches');

      final payload = LicensePayload(
        licenseId: 'TRIAL',
        issuedTo: 'Trial User',
        machineId: machineId,
        issueDate: startDateStr,
        validFrom: startDate,
        validTo: validTo,
        userLimit: int.tryParse(usersStr ?? '3') ?? 3,
        branchLimit: int.tryParse(branchesStr ?? '2') ?? 2,
        features: 'TRIAL',
      );

      return LicenseValidationResult.valid(payload, daysRemaining);
    } catch (e) {
      return LicenseValidationResult.invalid('Trial validation error: $e');
    }
  }
}
