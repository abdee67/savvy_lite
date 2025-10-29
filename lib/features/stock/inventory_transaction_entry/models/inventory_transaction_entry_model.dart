import 'package:equatable/equatable.dart';

class Customer extends Equatable {
  final String id;
  final String name;
  final String tin;
  final String phone;
  final String country;
  final String? email;
  final String? contactName;
  final String? title;
  final String? phone2;
  final String? state;
  final String? city;
  final String? region;
  final String? addressLine1;
  final String? addressLine2;
  final String? addressLine3;
  final String? addressLine4;
  final String? addressLine5;

  const Customer({
    required this.id,
    required this.name,
    required this.tin,
    required this.phone,
    required this.country,
    required this.email,
    this.contactName,
    this.title,
    this.phone2,
    this.state,
    this.city,
    this.region,
    this.addressLine1,
    this.addressLine2,
    this.addressLine3,
    this.addressLine4,
    this.addressLine5,
  });

  Customer copyWith({
    String? id,
    String? name,
    String? tin,
    String? phone,
    String? country,
    String? email,
    String? contactName,
    String? title,
    String? phone2,
    String? state,
    String? city,
    String? region,
    String? addressLine1,
    String? addressLine2,
    String? addressLine3,
    String? addressLine4,
    String? addressLine5,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      tin: tin ?? this.tin,
      phone: phone ?? this.phone,
      country: country ?? this.country,
      email: email ?? this.email,
      contactName: contactName ?? this.contactName,
      title: title ?? this.title,
      phone2: phone2 ?? this.phone2,
      state: state ?? this.state,
      city: city ?? this.city,
      region: region ?? this.region,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      addressLine3: addressLine3 ?? this.addressLine3,
      addressLine4: addressLine4 ?? this.addressLine4,
      addressLine5: addressLine5 ?? this.addressLine5,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    tin,
    phone,
    country,
    email,
    contactName,
    title,
    phone2,
    state,
    city,
    region,
    addressLine1,
    addressLine2,
    addressLine3,
    addressLine4,
    addressLine5,
  ];

  static const empty = Customer(
    id: 'empty', // Changed from '' to 'empty'
    name: '',
    tin: '',
    phone: '',
    country: '',
    email: '',
  );

  bool get isEmpty => id == 'empty'; // Use this for checking
  bool get isNotEmpty => id != 'empty';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Customer &&
        other.id == id &&
        other.name == name &&
        other.tin == tin &&
        other.phone == phone &&
        other.country == country &&
        other.email == email;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, tin, phone, country, email);
  }
}
