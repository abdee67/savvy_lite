class UdcHeader {
  final int? id;
  final String udcCode;
  final String udcDescription;
  final String? syncKey;

  UdcHeader({
    this.id,
    required this.udcCode,
    required this.udcDescription,
    this.syncKey,
  });

  factory UdcHeader.fromJson(Map<String, dynamic> json) {
    return UdcHeader(
      id: json['id'],
      udcCode: json['udc_code'],
      udcDescription: json['udc_description'],
      syncKey: json['sync_key'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'udc_code': udcCode,
      'udc_description': udcDescription,
      'sync_key': syncKey,
    };
  }

  Map<String, dynamic> toDatabaseMap() {
    return {
      'id': id,
      'udc_code': udcCode,
      'udc_description': udcDescription,
      'sync_key': syncKey,
    };
  }
}
