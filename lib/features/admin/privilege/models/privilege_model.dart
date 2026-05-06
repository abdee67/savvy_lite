import 'package:savvy_stock/core/constants/privilege_heirarchy.dart';
import 'package:savvy_stock/core/constants/privilege_route_mapper.dart';

class Privilege {
  final int id;
  final String name;
  final String type; // 'link' or 'button'
  final String uri;
  final String description;
  final String? buttonLabel;
  final String? linkLabel;
  final bool vendorOnly;
  final DateTime dateCreated;
  final DateTime? dateUpdated;
  final int? createdBy;
  final int? updatedBy;

  Privilege({
    required this.id,
    required this.name,
    required this.description,
    this.createdBy,
    required this.dateCreated,
    required this.type,
    required this.uri,
    this.vendorOnly = false,
    this.buttonLabel,
    this.linkLabel,
    this.updatedBy,
    this.dateUpdated,
  });

  factory Privilege.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      if (v is String) {
        if (v.isEmpty) return null;
        try {
          return DateTime.parse(v);
        } catch (_) {
          final asInt = int.tryParse(v);
          if (asInt != null) return DateTime.fromMillisecondsSinceEpoch(asInt);
          return null;
        }
      }
      return null;
    }

    int? asInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is String) return int.tryParse(v);
      return null;
    }

    String asString(dynamic v) {
      if (v == null) return '';
      return v.toString();
    }

    bool asVendorOnly(dynamic v) {
      if (v == null) return false;
      if (v is bool) return v;
      if (v is int) return v == 1;
      if (v is String) {
        return v.toUpperCase() == 'Y';
      }
      return false;
    }

    final id = asInt(map['id']) ?? 0;
    final rawUri = asString(map['link'] ?? map['button']);

    return Privilege(
      id: id,
      name: asString(map['name']),
      description: asString(map['description']),
      createdBy: asInt(map['created_by']),
      dateCreated:
          parseDate(map['date_created']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedBy: asInt(map['updated_by']),
      dateUpdated: parseDate(map['date_updated']),
      type: asString(map['type']),
      uri: PrivilegeRouteMapper.toAppRoute(id: id, serverRoute: rawUri),
      linkLabel: asString(map['link_lable']),
      buttonLabel: asString(map['button_lable']),
      vendorOnly: asVendorOnly(map['vendor_only']),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'created_by': createdBy,
    'date_created': dateCreated.toIso8601String(),
    'updated_by': updatedBy,
    'date_updated': dateUpdated?.toIso8601String(),
    'type': type,
    'link': uri,
    'button': uri,
    'link_lable': linkLabel,
    'button_lable': buttonLabel,
    'vendor_only': vendorOnly ? 'Y' : 'N',
  };

  /// Check if this is a dashboard privilege using the hierarchy config
  bool get isDashboardPrivilege => PrivilegeHierarchy.isDashboardPrivilege(uri);

  /// Get parent dashboard using the hierarchy config
  String? get parentDashboard => PrivilegeHierarchy.getParentPrivilege(uri);

  /// Get complete hierarchy required to access this privilege
  List<String> get privilegeHierarchy =>
      PrivilegeHierarchy.getRequiredPrivilegeHierarchy(uri);

  /// Check if user has access to this privilege (including hierarchy)
  bool hasAccess(List<Privilege> userPrivileges) {
    final userUris = userPrivileges.map((p) => p.uri).toList();
    return PrivilegeHierarchy.hasAccessToPrivilege(userUris, uri);
  }

  /// Get child privileges for this privilege
  List<String> getChildPrivileges() {
    return PrivilegeHierarchy.getChildPrivileges(uri);
  }

  Privilege copyWith({
    int? id,
    String? name,
    String? type,
    String? uri,
    String? description,
    String? buttonLabel,
    String? linkLabel,
    bool? vendorOnly,
    DateTime? dateCreated,
    DateTime? dateUpdated,
    int? createdBy,
    int? updatedBy,
  }) {
    return Privilege(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      uri: uri ?? this.uri,
      description: description ?? this.description,
      buttonLabel: buttonLabel ?? this.buttonLabel,
      linkLabel: linkLabel ?? this.linkLabel,
      vendorOnly: vendorOnly ?? this.vendorOnly,
      dateCreated: dateCreated ?? this.dateCreated,
      dateUpdated: dateUpdated ?? this.dateUpdated,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Privilege &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          uri == other.uri;

  @override
  int get hashCode => id.hashCode ^ uri.hashCode;

  @override
  String toString() {
    return 'Privilege{id: $id, name: $name, uri: $uri, type: $type, parent: $parentDashboard}';
  }
}
