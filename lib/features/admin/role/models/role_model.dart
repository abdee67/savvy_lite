import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/admin/privilege/models/privilege_model.dart';
import 'package:sqflite/sqflite.dart';

class Role extends Equatable {
  final int id;
  final String name;
  final String description;
  final int companyId;
  final DateTime dateCreated;
  final DateTime? dateUpdated;
  final int createdBy;
  final int? updatedBy;
  final List<Privilege> privileges;

  const Role({
    required this.id,
    required this.name,
    required this.description,
    required this.companyId,
    required this.dateCreated,
    required this.privileges,
    this.dateUpdated,
    required this.createdBy,
    this.updatedBy,
  });

  factory Role.fromMap(Map<String, dynamic> map) {
    return Role(
      id: map['id'] as int,
      name: map['name'] as String,
      description: map['description'] as String,
      companyId: map['company'] as int,
      dateCreated: DateTime.parse(map['date_created'] as String),
      dateUpdated: map['date_updated'] != null
          ? DateTime.parse(map['date_updated'] as String)
          : null,
      createdBy: map['created_by'] as int,
      updatedBy: map['updated_by'] as int?,
      privileges: const [], // Initially empty, we'll populate later
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'company': companyId,
      'date_created': dateCreated.toIso8601String(),
      'date_updated': dateUpdated?.toIso8601String(),
      'created_by': createdBy,
      'updated_by': updatedBy,
    };
  }

  // Method to load privileges for this role from role_privilege table
  static Future<Role> withPrivileges(
    Map<String, dynamic> roleData,
    Database db,
  ) async {
    final role = Role.fromMap(roleData);

    // Get privileges through role_privilege table
    final privilegeResults = await db.rawQuery(
      '''
      SELECT p.* FROM privilege_table p
      INNER JOIN role_privilege rp ON rp.privilege_table_id = p.id
      WHERE rp.role_table_id = ?
    ''',
      [role.id],
    );

    final privileges = privilegeResults
        .map((p) => Privilege.fromMap(p))
        .toList();

    return role.copyWith(privileges: privileges);
  }

  Role copyWith({
    int? id,
    String? name,
    String? description,
    int? companyId,
    DateTime? dateCreated,
    DateTime? dateUpdated,
    int? createdBy,
    int? updatedBy,
    List<Privilege>? privileges,
  }) {
    return Role(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      companyId: companyId ?? this.companyId,
      dateCreated: dateCreated ?? this.dateCreated,
      dateUpdated: dateUpdated ?? this.dateUpdated,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      privileges: privileges ?? this.privileges,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    companyId,
    dateCreated,
    dateUpdated,
    createdBy,
    updatedBy,
    privileges,
  ];
}
