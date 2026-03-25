/// Model representing the status of a sync node (a target server/device).
class SyncNodeStatusModel {
  final int? id;
  final String? nodeId;
  final String? lastSeen; // ISO8601 string
  final String company;
  final String? sourceNode;

  SyncNodeStatusModel({
    this.id,
    this.nodeId,
    this.lastSeen,
    required this.company,
    this.sourceNode,
  });

  factory SyncNodeStatusModel.fromMap(Map<String, dynamic> map) {
    return SyncNodeStatusModel(
      id: map['id'] as int?,
      nodeId: map['node_id'] as String?,
      lastSeen: map['last_seen'] as String?,
      company: map['company'] as String? ?? '',
      sourceNode: map['source_node'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'node_id': nodeId,
      'last_seen': lastSeen,
      'company': company,
      'source_node': sourceNode,
    };
    if (id != null) map['id'] = id;
    return map;
  }

  @override
  String toString() =>
      'SyncNodeStatusModel(id=$id, nodeId=$nodeId, company=$company)';
}
