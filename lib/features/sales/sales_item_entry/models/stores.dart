import 'package:equatable/equatable.dart';

class Store extends Equatable {
  final String id;
  final String branchName;
  final double unitPrice;
  final int availability;

  const Store({
    required this.id,
    required this.branchName,
    required this.unitPrice,
    required this.availability,
  });
  @override
  List<Object?> get props => [id, branchName, unitPrice, availability];
  static const empty = Store(
    id: '',
    branchName: '',
    unitPrice: 0,
    availability: 0,
  );
  bool get isEmpty => this == empty;
  bool get isNotEmpty => this != empty;
}
