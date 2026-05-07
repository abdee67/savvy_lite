import 'package:savvy_stock/features/udc_detail/models/udc_header.dart';

class UdcDetails {
  int id;
  String detailCode;
  final String description1;
  final String? description2;
  final int? recordHeader;
  final String? udcGroup;
  final UdcHeader? udcGroupRef;

  UdcDetails({
    required this.id,
    required this.detailCode,
    required this.description1,
    this.description2,
    this.recordHeader,
    this.udcGroup,
    this.udcGroupRef,
  });

  factory UdcDetails.empty() {
    return UdcDetails(
      id: 0,
      detailCode: '',
      description1: '',
      description2: '',
      recordHeader: 0,
      udcGroup: '',
    );
  }
  static int? asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    return null;
  }

  factory UdcDetails.fromJson(Map<String, dynamic> json) {
    return UdcDetails(
      id: asInt(json['id']) ?? 0,
      detailCode: json['detail_code']?.toString() ?? '',
      description1: json['description_1']?.toString() ?? '',
      description2: json['description_2']?.toString(),
      recordHeader: asInt(json['record_header']),
      udcGroup: json['udc_group']?.toString(),
      udcGroupRef: json['record_header'] != null
          ? UdcHeader(
              id: asInt(json['record_header']),
              udcCode: json['udc_code']?.toString() ?? '',
              udcDescription: json['udc_description']?.toString() ?? '',
              syncKey: json['sync_key']?.toString(),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'detail_code': detailCode,
      'description_1': description1,
      'description_2': description2,
      'record_header': recordHeader,
      'udc_group': udcGroup,
    };
  }

  Map<String, dynamic> toDatabaseMap() {
    return {
      'id': id,
      'detail_code': detailCode,
      'description_1': description1,
      'description_2': description2,
      'record_header': recordHeader,
      'udc_group': udcGroup,
    };
  }
}
