class Employee {
  final int id;
  final String? employeeId;
  final String nameFirst;
  final String nameLast;
  final String nameMiddle;
  final String? nationality;
  final String email;
  final String phone;
  final String? title;
  final String? birthDate;
  final String? hireDate;
  final String? address;
  final String? city;
  final String? region;
  final String? country;
  final String? phoneHome;
  final String? gender;
  final int? company;
  final int? branch;

  Employee({
    required this.id,
    this.employeeId,
    required this.nameFirst,
    required this.nameLast,
    required this.nameMiddle,
    this.nationality,
    required this.email,
    required this.phone,
    this.title,
    this.birthDate,
    this.hireDate,
    this.address,
    this.city,
    this.region,
    this.country,
    this.phoneHome,
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
    String? nationality,
    String? email,
    String? phone,
    String? title,
    String? birthDate,
    String? hireDate,
    String? address,
    String? city,
    String? region,
    String? country,
    String? phoneHome,
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
      nationality: nationality ?? this.nationality,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      title: title ?? this.title,
      birthDate: birthDate ?? this.birthDate,
      hireDate: hireDate ?? this.hireDate,
      address: address ?? this.address,
      city: city ?? this.city,
      region: region ?? this.region,
      country: country ?? this.country,
      phoneHome: phoneHome ?? this.phoneHome,
      gender: gender ?? this.gender,
      company: company ?? this.company,
      branch: branch ?? this.branch,
    );
  }

  @override
  List<Object?> get props => [
    id,
    employeeId,
    nameFirst,
    nameLast,
    nameMiddle,
    nationality,
    email,
    phone,
    title,
    birthDate,
    hireDate,
    address,
    city,
    region,
    country,
    phoneHome,
    gender,
    company,
    branch,
  ];

  factory Employee.fromMap(Map<String, dynamic> map) => Employee(
    id: map['id'],
    employeeId: map['employee_id'],
    nameFirst: map['name_first'],
    nameLast: map['name_last'],
    nameMiddle: map['name_middle'],
    nationality: map['nationality'],
    email: map['email'],
    phone: map['phone'],
    title: map['title'],
    birthDate: map['birth_date'],
    hireDate: map['hire_date'],
    address: map['address'],
    city: map['city'],
    region: map['region'],
    country: map['country'],
    phoneHome: map['phone_home'],
    gender: map['gender'],
    company: map['company'],
    branch: map['branch'],
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'employee_id': employeeId,
    'name_first': nameFirst,
    'name_last': nameLast,
    'name_middle': nameMiddle,
    'nationality': nationality,
    'email': email,
    'phone': phone,
    'title': title,
    'birth_date': birthDate,
    'hire_date': hireDate,
    'address': address,
    'city': city,
    'region': region,
    'country': country,
    'phone_home': phoneHome,
    'gender': gender,
    'company': company,
    'branch': branch,
  };
}
