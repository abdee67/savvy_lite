import 'package:equatable/equatable.dart';

class Customer extends Equatable {
  final int? id;
  final int? customerId;
  final String? customerName;
  final String? phoneNumber;
  final String? address;
  final String? country;
  final String? state;
  final String? region;
  final String? city;
  final String? tinNumber;
  final String? address1;
  final String? address2;
  final String? address3;
  final String? address4;
  final String? fax;
  final String? phone2;
  final String? contactName;
  final String? contactTitle;
  final int? company;
  final String? defaultsValue;
  final int? tempId;

  const Customer({
    this.id,
    this.customerId,
    this.customerName,
    this.phoneNumber,
    this.address,
    this.country,
    this.state,
    this.region,
    this.city,
    this.tinNumber,
    this.address1,
    this.address2,
    this.address3,
    this.address4,
    this.fax,
    this.phone2,
    this.contactName,
    this.contactTitle,
    this.company,
    this.defaultsValue,
    this.tempId,
  });

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      customerId: map['customer_id'],
      customerName: map['customer_name'],
      phoneNumber: map['phone_number'],
      address: map['address'],
      country: map['country'],
      state: map['state'],
      region: map['region'],
      city: map['city'],
      tinNumber: map['tin_number'],
      address1: map['address1'],
      address2: map['address2'],
      address3: map['address3'],
      address4: map['address4'],
      fax: map['fax'],
      phone2: map['phone_2'],
      contactName: map['contact_name'],
      contactTitle: map['contact_title'],
      company: map['company'],
      defaultsValue: map['defaults_value'],
      tempId: map['temp_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'customer_name': customerName,
      'phone_number': phoneNumber,
      'address': address,
      'country': 'Ethiopia',
      'state': state,
      'region': region,
      'city': city,
      'tin_number': tinNumber,
      'address1': address1,
      'address2': address2,
      'address3': address3,
      'address4': address4,
      'fax': fax,
      'phone_2': phone2,
      'contact_name': contactName,
      'contact_title': contactTitle,
      'company': company,
      'defaults_value': defaultsValue,
      if (tempId != null) 'temp_id': tempId,
    };
  }

  static const empty = Customer(
    id: 0,
    customerId: 0,
    customerName: '',
    phoneNumber: '',
    address: '',
    country: 'Ethiopia',
    state: '',
    region: '',
    city: '',
    tinNumber: '',
    address1: '',
    address2: '',
    address3: '',
    address4: '',
    fax: '',
    phone2: '',
    contactName: '',
    contactTitle: '',
    company: 0,
    defaultsValue: 'N',
    tempId: null,
  );

  bool get isEmpty => id == 'empty'; // Use this for checking
  bool get isNotEmpty => id != 'empty';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Customer &&
        other.id == id &&
        other.customerId == customerId &&
        other.customerName == customerName &&
        other.phoneNumber == phoneNumber &&
        other.address == address &&
        other.country == country &&
        other.state == state &&
        other.region == region &&
        other.city == city &&
        other.tinNumber == tinNumber &&
        other.address1 == address1 &&
        other.address2 == address2 &&
        other.address3 == address3 &&
        other.address4 == address4 &&
        other.fax == fax &&
        other.phone2 == phone2 &&
        other.contactName == contactName &&
        other.contactTitle == contactTitle &&
        other.company == company &&
        other.defaultsValue == defaultsValue &&
        other.tempId == tempId;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      customerId,
      customerName,
      phoneNumber,
      address,
      country,
      state,
      region,
      city,
      tinNumber,
      address1,
      address2,
      address3,
      address4,
      fax,
      phone2,
      contactName,
      contactTitle,
      company,
      defaultsValue,
    );
  }

  Customer copyWith({
    int? id,
    int? customerId,
    String? customerName,
    String? phoneNumber,
    String? address,
    String? country,
    String? state,
    String? region,
    String? city,
    String? tinNumber,
    String? address1,
    String? address2,
    String? address3,
    String? address4,
    String? fax,
    String? phone2,
    String? contactName,
    String? contactTitle,
    int? company,
    String? defaultsValue,
    int? tempId,
  }) {
    return Customer(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      country: country ?? this.country,
      state: state ?? this.state,
      region: region ?? this.region,
      city: city ?? this.city,
      tinNumber: tinNumber ?? this.tinNumber,
      address1: address1 ?? this.address1,
      address2: address2 ?? this.address2,
      address3: address3 ?? this.address3,
      address4: address4 ?? this.address4,
      fax: fax ?? this.fax,
      phone2: phone2 ?? this.phone2,
      contactName: contactName ?? this.contactName,
      contactTitle: contactTitle ?? this.contactTitle,
      company: company ?? this.company,
      defaultsValue: defaultsValue ?? this.defaultsValue,
      tempId: tempId ?? this.tempId,
    );
  }

  @override
  List<Object?> get props => [
    id,
    customerId,
    customerName,
    phoneNumber,
    address,
    country,
    state,
    region,
    city,
    tinNumber,
    address1,
    address2,
    address3,
    address4,
    fax,
    phone2,
    contactName,
    contactTitle,
    company,
    defaultsValue,
    tempId,
  ];
}
