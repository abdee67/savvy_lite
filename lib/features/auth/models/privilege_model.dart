class Privilege {
  final int id;
  final String? name;
  final String? description;
  final int? createdBy;
  final DateTime? dateCreated;
  final int? updatedBy;
  final DateTime? dateUpdated;
  final String? type;
  final String? link;
  final String? button;
  final String? linkLabel;
  final String? buttonLabel;
  final bool vendorOnly;

  Privilege({
    required this.id,
    this.name,
    this.description,
    this.createdBy,
    this.dateCreated,
    this.updatedBy,
    this.dateUpdated,
    this.type,
    this.link,
    this.button,
    this.linkLabel,
    this.buttonLabel,
    required this.vendorOnly,
  });

  factory Privilege.fromMap(Map<String, dynamic> map) {
    DateTime? _parseDate(dynamic v) {
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

    int? _asInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is String) return int.tryParse(v);
      return null;
    }

    String? _asString(dynamic v) {
      if (v == null) return null;
      return v.toString();
    }

    bool _asVendorOnly(dynamic v) {
      if (v == null) return false;
      if (v is bool) return v;
      if (v is int) return v == 1;
      if (v is String)
        return v.toUpperCase() == 'Y' || v == '1' || v.toLowerCase() == 'true';
      return false;
    }

    return Privilege(
      id: _asInt(map['id']) ?? 0,
      name: _asString(map['name']),
      description: _asString(map['description']),
      createdBy: _asInt(map['created_by']),
      dateCreated: _parseDate(map['date_created']),
      updatedBy: _asInt(map['updated_by']),
      dateUpdated: _parseDate(map['date_updated']),
      type: _asString(map['type']),
      link: _asString(map['link']),
      button: _asString(map['button']),
      linkLabel: _asString(map['link_lable']),
      buttonLabel: _asString(map['button_lable']),
      vendorOnly: _asVendorOnly(map['vendor_only']),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'created_by': createdBy,
    'date_created': dateCreated?.toIso8601String(),
    'updated_by': updatedBy,
    'date_updated': dateUpdated?.toIso8601String(),
    'type': type,
    'link': link,
    'button': button,
    'link_lable': linkLabel,
    'button_lable': buttonLabel,
    'vendor_only': vendorOnly ? 'Y' : 'N',
  };

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    createdBy,
    dateCreated,
    updatedBy,
    dateUpdated,
    type,
    link,
    button,
    linkLabel,
    buttonLabel,
    vendorOnly,
  ];

  @override
  String toString() {
    return 'Privilege{id: $id, name: $name, description: $description, createdBy: $createdBy, dateCreated: $dateCreated, updatedBy: $updatedBy, dateUpdated: $dateUpdated, type: $type, link: $link, button: $button, linkLabel: $linkLabel, buttonLabel: $buttonLabel, vendorOnly: $vendorOnly}';
  }
}
