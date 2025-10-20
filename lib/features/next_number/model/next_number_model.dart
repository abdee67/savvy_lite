import 'package:equatable/equatable.dart';

class NextNumberModel extends Equatable {
  final int? id;
  final String nextNumberCode;
  final String nextNumberDescription;
  final int? nextNumber;
  final int? company;
  final int? tempId;

  const NextNumberModel({
    this.id,
    required this.nextNumberCode,
    required this.nextNumberDescription,
    this.nextNumber = 1,
    this.company,
    this.tempId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'next_number_code': nextNumberCode,
      'next_number_description': nextNumberDescription,
      'next_number': nextNumber,
      'company': company,
    };
  }

  factory NextNumberModel.fromMap(Map<String, dynamic> map) {
    return NextNumberModel(
      id: map['id'] as int?,
      nextNumberCode: map['next_number_code'] ?? '',
      nextNumberDescription: map['next_number_description'] ?? '',
      nextNumber: map['next_number'] ?? 1,
      company: map['company'] as int?,
    );
  }

  NextNumberModel copyWith({
    int? id,
    String? nextNumberCode,
    String? nextNumberDescription,
    int? nextNumber,
    int? company,
    int? tempId,
  }) {
    return NextNumberModel(
      id: id ?? this.id,
      nextNumberCode: nextNumberCode ?? this.nextNumberCode,
      nextNumberDescription:
          nextNumberDescription ?? this.nextNumberDescription,
      nextNumber: nextNumber ?? this.nextNumber,
      company: company ?? this.company,
      tempId: tempId ?? this.tempId,
    );
  }

  @override
  List<Object?> get props => [
    id,
    nextNumberCode,
    nextNumberDescription,
    nextNumber,
    company,
    tempId,
  ];
}
