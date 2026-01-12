import 'package:intl/intl.dart';

class LicensePayload {
  final String licenseId;
  final String issuedTo;
  final String machineId;
  final String issueDate;
  final DateTime validFrom;
  final DateTime validTo;
  final String features;
  final int userLimit;
  final int branchLimit;

  LicensePayload({
    required this.licenseId,
    required this.issuedTo,
    required this.machineId,
    required this.issueDate,
    required this.validFrom,
    required this.validTo,
    required this.features,
    required this.userLimit,
    required this.branchLimit,
  });

  factory LicensePayload.fromJson(Map<String, dynamic> json) {
    return LicensePayload(
      licenseId: json['licenseId'] ?? '',
      issuedTo: json['issuedTo'] ?? '',
      machineId: json['machineId'] ?? '',
      issueDate: json['issueDate'] ?? '',
      validFrom: _parseDate(json['validFrom']),
      validTo: _parseDate(json['validTo']),
      features: json['features'] ?? '',
      userLimit: json['userLimit'] ?? 0,
      branchLimit: json['branchLimit'] ?? 0,
    );
  }

  static DateTime _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return DateTime.now();
    try {
      // Try standard ISO parsing first
      return DateTime.parse(dateStr);
    } catch (e) {
      try {
        // Handle localized formats like "Jan 12, 2026, 12:00:00 AM"
        // Normalize spaces (U+202F -> space)
        final normalized = dateStr.replaceAll(RegExp(r'[\u202F\u00A0]'), ' ');
        return DateFormat('MMM d, yyyy, h:mm:ss a', 'en_US').parse(normalized);
      } catch (e2) {
        print('Error parsing date: $dateStr - $e2');
        return DateTime.now(); // Fallback
      }
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'licenseId': licenseId,
      'issuedTo': issuedTo,
      'machineId': machineId,
      'issueDate': issueDate,
      'validFrom': validFrom.toIso8601String(),
      'validTo': validTo.toIso8601String(),
      'features': features,
      'userLimit': userLimit,
      'branchLimit': branchLimit,
    };
  }

  @override
  String toString() {
    return 'LicensePayload{licenseId: $licenseId, validTo: $validTo, userLimit: $userLimit, branchLimit: $branchLimit}';
  }
}
