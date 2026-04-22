import 'dart:convert';

import 'package:uuid/uuid.dart';

/// Lifecycle states for sync events.
/// PENDING → IN_PROGRESS → SUCCESS / FAILED
class SyncStatus {
  static const String pending = 'PENDING';
  static const String inProgress = 'IN_PROGRESS';
  static const String success = 'SUCCESS';
  static const String failed = 'FAILED';
  static const String initialPending = 'INITIAL_PENDING';
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
  final int? sequenceNumber;

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
    this.sequenceNumber,
  });

  /// Generate a new unique sourceKey.
  static String generateSourceKey(String? sourceNode) {
    const uuid = Uuid();
    final key = uuid.v4();
    return sourceNode != null ? '$sourceNode-$key' : key;
  }

  factory SyncEventModel.fromMap(Map<String, dynamic> map) {
    final rawPayload = map['payload'];

    return SyncEventModel(
      id: map['id'] as int?,
      entityName:
          map['entity_name']?.toString() ?? map['entityName']?.toString() ?? '',
      entityId:
          map['entity_id']?.toString() ?? map['entityId']?.toString(),
      operation: map['operation']?.toString() ?? '',
      payload: rawPayload is String ? rawPayload : jsonEncode(rawPayload ?? {}),
      sourceNode:
          map['source_node']?.toString() ?? map['sourceNode']?.toString(),
      createdAt:
          map['created_at']?.toString() ?? map['createdAt']?.toString(),
      company: map['company']?.toString(),
      sourceKey:
          map['source_key']?.toString() ?? map['sourceKey']?.toString(),
      sourceAddress:
          map['source_address']?.toString() ?? map['sourceAddress']?.toString(),
      sourceId: map['source_id']?.toString() ?? map['sourceId']?.toString(),
      syncStatus:
          map['sync_status']?.toString() ??
          map['syncStatus']?.toString() ??
          SyncStatus.pending,
      sequenceNumber:
          map['sequence_number'] as int? ?? map['sequenceNumber'] as int?,
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
      'sequence_number': sequenceNumber,
    };
    if (id != null) map['id'] = id;
    return map;
  }

  /// Convert to a map suitable for the Java backend (camelCase keys).
  /// Excludes local-only fields (id, syncStatus) that the server doesn't expect.
  /// Strips null values to avoid Jackson deserialization errors.
  Map<String, dynamic> toServerMap({bool useCamelCase = true}) {
    // Fix entityId: convert string "null" to actual null, parse to int if possible
    dynamic resolvedEntityId = entityId;
    if (resolvedEntityId == 'null' || resolvedEntityId == null) {
      resolvedEntityId = null;
    } else {
      resolvedEntityId =
          int.tryParse(resolvedEntityId.toString()) ?? resolvedEntityId;
    }

    final map = <String, dynamic>{
      useCamelCase ? 'entityName' : 'entity_name': entityName,
      useCamelCase ? 'entityId' : 'entity_id': resolvedEntityId,
      'operation': operation,
      // Backend expects payload as a JSON string (not a nested object).
      'payload': payload,
      useCamelCase ? 'sourceNode' : 'source_node': sourceNode,
      useCamelCase ? 'createdAt' : 'created_at': createdAt,
      'company': int.tryParse(company?.toString() ?? '') ?? company,
      useCamelCase ? 'sourceKey' : 'source_key': sourceKey,
      useCamelCase ? 'sourceAddress' : 'source_address': sourceAddress,
      useCamelCase ? 'sourceId' : 'source_id': sourceId,
      useCamelCase ? 'sequenceNumber' : 'sequence_number': sequenceNumber,
    };

    // Remove null entries — Jackson may reject unknown nulls
    map.removeWhere((key, value) => value == null);
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
    int? sequenceNumber,
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
      sequenceNumber: sequenceNumber ?? this.sequenceNumber,
    );
  }

  @override
  String toString() =>
      'SyncEvent(id=$id, entity=$entityName, op=$operation, '
      'status=$syncStatus, key=$sourceKey)';
}
