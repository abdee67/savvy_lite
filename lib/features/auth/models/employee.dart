class Employee {
  final int id;
  final String? employeeId;
  final String? nameFirst;
  final String? nameLast;
  final String? nameMiddle;
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
    this.nameFirst,
    this.nameLast,
    this.nameMiddle,
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

  factory Employee.fromMap(Map<String, dynamic> map) => Employee(
    id: map['id'],
    employeeId: map['employee_id'],
    nameFirst: map['name_first'],
    nameLast: map['name_last'],
    nameMiddle: map['name_middle'],
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
