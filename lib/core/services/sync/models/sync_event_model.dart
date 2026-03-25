import 'package:uuid/uuid.dart';

/// Lifecycle states for sync events.
/// PENDING → IN_PROGRESS → SUCCESS / FAILED
class SyncStatus {
  static const String pending = 'PENDING';
  static const String inProgress = 'IN_PROGRESS';
  static const String success = 'SUCCESS';
  static const String failed = 'FAILED';
}

/// Model representing a sync event that captures a local CRUD operation
/// to be synced to the server.
///
/// Each event has:
/// - A unique [sourceKey] (UUID-based) for idempotency
/// - A [version] number for conflict resolution (last-write-wins)
/// - Lifecycle state tracking via [syncStatus]
class SyncEventModel {
  final int? id;
  final String entityName;
  final String? entityId;
  final String operation; // INSERT, UPDATE, DELETE
  final String payload; // JSON string of the entity data
  final String? sourceNode;
  final String? createdAt; // ISO8601 string
  final String? company;
  final String? sourceKey; // UUID — ensures idempotency
  final String? sourceAddress;
  final String? sourceId;
  final String syncStatus; // PENDING, IN_PROGRESS, SUCCESS, FAILED

  SyncEventModel({
    this.id,
    required this.entityName,
    this.entityId,
    required this.operation,
    required this.payload,
    this.sourceNode,
    this.createdAt,
    this.company,
    this.sourceKey,
    this.sourceAddress,
    this.sourceId,
    this.syncStatus = SyncStatus.pending,
  });

  /// Generate a new unique sourceKey.
  static String generateSourceKey(String? sourceNode) {
    const uuid = Uuid();
    final key = uuid.v4();
    return sourceNode != null ? '$sourceNode-$key' : key;
  }

  factory SyncEventModel.fromMap(Map<String, dynamic> map) {
    return SyncEventModel(
      id: map['id'] as int?,
      entityName: map['entity_name'] as String? ?? '',
      entityId: map['entity_id'] as String?,
      operation: map['operation'] as String? ?? '',
      payload: map['payload'] as String? ?? '',
      sourceNode: map['source_node'] as String?,
      createdAt: map['created_at'] as String?,
      company: map['company'] as String?,
      sourceKey: map['source_key'] as String?,
      sourceAddress: map['source_address'] as String?,
      sourceId: map['source_id'] as String?,
      syncStatus: map['sync_status'] as String? ?? SyncStatus.pending,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'entity_name': entityName,
      'entity_id': entityId,
      'operation': operation,
      'payload': payload,
      'source_node': sourceNode,
      'created_at': createdAt,
      'company': company,
      'source_key': sourceKey,
      'source_address': sourceAddress,
      'source_id': sourceId,
      'sync_status': syncStatus,
    };
    if (id != null) map['id'] = id;
    return map;
  }

  SyncEventModel copyWith({
    int? id,
    String? entityName,
    String? entityId,
    String? operation,
    String? payload,
    String? sourceNode,
    String? createdAt,
    String? company,
    String? sourceKey,
    String? sourceAddress,
    String? sourceId,
    String? syncStatus,
  }) {
    return SyncEventModel(
      id: id ?? this.id,
      entityName: entityName ?? this.entityName,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      payload: payload ?? this.payload,
      sourceNode: sourceNode ?? this.sourceNode,
      createdAt: createdAt ?? this.createdAt,
      company: company ?? this.company,
      sourceKey: sourceKey ?? this.sourceKey,
      sourceAddress: sourceAddress ?? this.sourceAddress,
      sourceId: sourceId ?? this.sourceId,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  @override
  String toString() =>
      'SyncEvent(id=$id, entity=$entityName, op=$operation, '
      'status=$syncStatus, key=$sourceKey)';
}
