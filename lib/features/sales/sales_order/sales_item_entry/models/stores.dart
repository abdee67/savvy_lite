import 'package:equatable/equatable.dart';

class Store extends Equatable {
  final String id;
  final String branchName;
  const Store({required this.id, required this.branchName});
  @override
  List<Object?> get props => [id, branchName];
  static const empty = Store(id: '', branchName: '');
  bool get isEmpty => this == empty;
  bool get isNotEmpty => this != empty;
}
