class UdcDetails {
  final int id;
  final String detailCode;
  final String description1;
  final String? description2;
  final int? recordHeader;
  final String? udcGroup;

  UdcDetails({
    required this.id,
    required this.detailCode,
    required this.description1,
    this.description2,
    this.recordHeader,
    this.udcGroup,
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

  factory UdcDetails.fromJson(Map<String, dynamic> json) {
    return UdcDetails(
      id: json['id'],
      detailCode: json['detail_code'],
      description1: json['description_1'],
      description2: json['description_2'],
      recordHeader: json['record_header'],
      udcGroup: json['udc_group'],
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
