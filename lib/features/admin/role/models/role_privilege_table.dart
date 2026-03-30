class RolePrivilegeTable {
  final int? id;
  final int roleTableId;
  final int privilegeTableId;
  final int createdBy;
  final String dateCreated;
  final int? updatedBy;
  final String? dateUpdated;
  final String? syncKey;

  RolePrivilegeTable({
    this.id,
    required this.roleTableId,
    required this.privilegeTableId,
    required this.createdBy,
    required this.dateCreated,
    this.updatedBy,
    this.dateUpdated,
    this.syncKey,
  });

  factory RolePrivilegeTable.fromMap(Map<String, dynamic> map) {
    return RolePrivilegeTable(
      id: map['id'],
      roleTableId: map['role_table_id'],
      privilegeTableId: map['privilege_table_id'],
      createdBy: map['created_by'],
      dateCreated: map['date_created'],
      updatedBy: map['updated_by'],
      dateUpdated: map['date_updated'],
      syncKey: map['sync_key'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'role_table_id': roleTableId,
      'privilege_table_id': privilegeTableId,
      'created_by': createdBy,
      'date_created': dateCreated,
      'updated_by': updatedBy,
      'date_updated': dateUpdated,
      'sync_key': syncKey,
    };
  }
}
