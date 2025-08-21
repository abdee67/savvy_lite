// Data models
class Customer {
  final String id;
  final String name;
  final String tin;
  final String phone;
  final String country;

  Customer({
    required this.id,
    required this.name,
    required this.tin,
    required this.phone,
    required this.country,
  });

  @override
  String toString() => name;
}
