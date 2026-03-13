class Employee {
  final int id;
  final String? employeeId;
  final String nameFirst;
  final String nameLast;
  final String nameMiddle;
  final String email;
  final String phoneHome;
  final String? title;
  final String? birthDate;
  final String? hireDate;
  final String? address;
  final String? city;
  final String? region;
  final String? country;
  final String? gender;
  final int? company;
  final int? branch;

  bool get isUser => employeeId != null;

  Employee({
    required this.id,
    this.employeeId,
    required this.nameFirst,
    required this.nameLast,
    required this.nameMiddle,
    required this.email,
    required this.phoneHome,
    this.title,
    this.birthDate,
    this.hireDate,
    this.address,
    this.city,
    this.region,
    this.country,
    this.gender,
    this.company,
    this.branch,
  });

  String get fullName => '$nameFirst $nameLast';
  String get fullNameWithMiddle => '$nameFirst $nameMiddle $nameLast';

  Employee copyWith({
    int? id,
    String? employeeId,
    String? nameFirst,
    String? nameLast,
    String? nameMiddle,
    String? email,
    String? phoneHome,
    String? title,
    String? birthDate,
    String? hireDate,
    String? address,
    String? city,
    String? region,
    String? country,
    String? gender,
    int? company,
    int? branch,
  }) {
    return Employee(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      nameFirst: nameFirst ?? this.nameFirst,
      nameLast: nameLast ?? this.nameLast,
      nameMiddle: nameMiddle ?? this.nameMiddle,
      email: email ?? this.email,
      phoneHome: phoneHome ?? this.phoneHome,
      title: title ?? this.title,
      birthDate: birthDate ?? this.birthDate,
      hireDate: hireDate ?? this.hireDate,
      address: address ?? this.address,
      city: city ?? this.city,
      region: region ?? this.region,
      country: country ?? this.country,
      gender: gender ?? this.gender,
      company: company ?? this.company,
      branch: branch ?? this.branch,
    );
  }

  static Employee empty() {
    return Employee(
      id: 0,
      nameFirst: '',
      nameLast: '',
      nameMiddle: '',
      email: '',
      phoneHome: '',
    );
  }

  bool get isEmpty => id == 0;
  bool get isNotEmpty => id != 0;

  @override
  List<Object?> get props => [
    id,
    employeeId,
    nameFirst,
    nameLast,
    nameMiddle,
    email,
    phoneHome,
    title,
    birthDate,
    hireDate,
    address,
    city,
    region,
    country,
    gender,
    company,
    branch,
  ];

  factory Employee.fromMap(Map<String, dynamic> map) => Employee(
    id: (map['id'] as num?)?.toInt() ?? 0,
    employeeId: map['employee_id']?.toString(),
    nameFirst: map['name_first']?.toString() ?? '',
    nameLast: map['name_last']?.toString() ?? '',
    nameMiddle: map['name_middle']?.toString() ?? '',
    email: map['email']?.toString() ?? '',
    phoneHome: map['phone_home']?.toString() ?? '',
    title: map['title']?.toString(),
    birthDate: map['birth_date']?.toString(),
    hireDate: map['hire_date']?.toString(),
    address: map['address']?.toString(),
    city: map['city']?.toString(),
    region: map['region']?.toString(),
    country: map['country']?.toString(),
    gender: map['gender']?.toString(),
    company: (map['company'] as num?)?.toInt(),
    branch: (map['branch'] as num?)?.toInt(),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'employee_id': employeeId,
    'name_first': nameFirst,
    'name_last': nameLast,
    'name_middle': nameMiddle,
    'email': email,
    'phone_home': phoneHome,
    'title': title,
    'birth_date': birthDate,
    'hire_date': hireDate,
    'address': address,
    'city': city,
    'region': region,
    'country': country,
    'gender': gender,
    'company': company,
    'branch': branch,
  };
  Employee copyWithField(String field, dynamic value) {
    switch (field) {
      case 'nameFirst':
        return copyWith(nameFirst: value as String);
      case 'nameLast':
        return copyWith(nameLast: value as String);
      case 'nameMiddle':
        return copyWith(nameMiddle: value as String);
      case 'employeeId':
        return copyWith(employeeId: value as String);
      case 'phoneHome':
        return copyWith(phoneHome: value as String);
      case 'email':
        return copyWith(email: value as String);
      case 'title':
        return copyWith(title: value as String);
      case 'gender':
        return copyWith(gender: value as String);
      case 'city':
        return copyWith(city: value as String);
      case 'address':
        return copyWith(address: value as String);
      case 'birthDate':
        return copyWith(birthDate: value as String);
      case 'hireDate':
        return copyWith(hireDate: value as String);
      case 'country':
        return copyWith(country: value as String);
      default:
        return this;
    }
  }
}
