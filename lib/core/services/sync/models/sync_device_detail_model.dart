import 'package:savvy_stock/core/services/sync/models/sync_event_model.dart';

/// Model representing a sync delivery target — tracks the sync status
/// for a specific event to a specific device/server address.
///
/// Supports:
/// - Retry tracking with [retryCount] and [nextRetryAt]
/// - Error logging via [lastError]
/// - Exponential backoff timing via [nextRetryAt]
class SyncDeviceDetailModel {
  final int? id;
  final String syncStatus; // PENDING, IN_PROGRESS, SUCCESS, FAILED
  final String? lastAttempt; // ISO8601 string
  final String? lastError;
  final int? deviceAddress; // FK → system_url_config.id
  final int retryCount;
  final int? syncEvent; // FK → sync_event.id
  final String? company;
  final String? nextRetryAt; // ISO8601 — exponential backoff target time

  /// Maximum number of retries before giving up.
  static const int maxRetries = 10;

  SyncDeviceDetailModel({
    this.id,
    this.syncStatus = SyncStatus.pending,
    this.lastAttempt,
    this.lastError,
    this.deviceAddress,
    this.retryCount = 0,
    this.syncEvent,
    this.company,
    this.nextRetryAt,
  });

  /// Calculate exponential backoff delay for the next retry.
  /// Delays: 2s, 4s, 8s, 16s, 32s, 64s, 128s, 256s, 512s, 1024s
  static Duration calculateBackoff(int retryCount) {
    final seconds = 1 << (retryCount + 1); // 2^(retry+1)
    return Duration(seconds: seconds.clamp(2, 1024));
  }

  /// Whether this detail is eligible for retry.
  bool get isRetryable =>
      (syncStatus == SyncStatus.pending || syncStatus == SyncStatus.failed) &&
      retryCount < maxRetries;

  /// Whether the backoff period has elapsed and we can retry now.
  bool get isReadyForRetry {
    if (nextRetryAt == null) return true;
    final retryTime = DateTime.tryParse(nextRetryAt!);
    if (retryTime == null) return true;
    return DateTime.now().isAfter(retryTime);
  }

  factory SyncDeviceDetailModel.fromMap(Map<String, dynamic> map) {
    return SyncDeviceDetailModel(
      id: map['id'] as int?,
      syncStatus: map['sync_status'] as String? ?? SyncStatus.pending,
      lastAttempt: map['last_attempt'] as String?,
      lastError: map['last_error'] as String?,
      deviceAddress: map['device_address'] as int?,
      retryCount: (map['retry_count'] as int?) ?? 0,
      syncEvent: map['sync_event'] as int?,
      company: map['company'] as String?,
      nextRetryAt: map['next_retry_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'sync_status': syncStatus,
      'last_attempt': lastAttempt,
      'last_error': lastError,
      'device_address': deviceAddress,
      'retry_count': retryCount,
      'sync_event': syncEvent,
      'company': company,
    };
    if (id != null) map['id'] = id;
    return map;
  }

  SyncDeviceDetailModel copyWith({
    int? id,
    String? syncStatus,
    String? lastAttempt,
    String? lastError,
    int? deviceAddress,
    int? retryCount,
    int? syncEvent,
    String? company,
    String? nextRetryAt,
  }) {
    return SyncDeviceDetailModel(
      id: id ?? this.id,
      syncStatus: syncStatus ?? this.syncStatus,
      lastAttempt: lastAttempt ?? this.lastAttempt,
      lastError: lastError ?? this.lastError,
      deviceAddress: deviceAddress ?? this.deviceAddress,
      retryCount: retryCount ?? this.retryCount,
      syncEvent: syncEvent ?? this.syncEvent,
      company: company ?? this.company,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
    );
  }

  @override
  String toString() =>
      'SyncDeviceDetail(id=$id, event=$syncEvent, status=$syncStatus, '
      'retries=$retryCount/$maxRetries)';
}
