import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/admin/users/models/user_model.dart';
import 'package:savvy_stock/features/udc_detail/models/udc_details.dart';

class FastSlowNonMovingRule extends Equatable {
  final int? id;
  final int? userId;
  final String? reportFrequency;
  final int? periodInDays;
  final double? fastMovementRuleUnit;
  final double? slowMovementRuleUnit;
  final double? nonMovementRuleUnit;
  final DateTime? createdDate;
  final DateTime? updatedDate;
  final int? company;
  final int? unitOfMeansureDefault;

  final UserModel? userRef;
  final UdcDetails? unitOfMeansureDefaultRef;
  final UdcDetails? reportFrequencyRef;

  const FastSlowNonMovingRule({
    this.id,
    this.userId,
    this.reportFrequency,
    this.periodInDays,
    this.fastMovementRuleUnit,
    this.slowMovementRuleUnit,
    this.nonMovementRuleUnit,
    this.createdDate,
    this.updatedDate,
    this.company,
    this.unitOfMeansureDefault,
    this.userRef,
    this.unitOfMeansureDefaultRef,
    this.reportFrequencyRef,
  });

  factory FastSlowNonMovingRule.empty() {
    return const FastSlowNonMovingRule(
      id: 0,
      userId: null,
      reportFrequency: null,
      periodInDays: null,
      fastMovementRuleUnit: null,
      slowMovementRuleUnit: null,
      nonMovementRuleUnit: null,
      company: null,
      createdDate: null,
      updatedDate: null,
      unitOfMeansureDefault: null,
    );
  }
  //copwith
  FastSlowNonMovingRule copyWith({
    int? id,
    int? userId,
    String? reportFrequency,
    int? periodInDays,
    double? fastMovementRuleUnit,
    double? slowMovementRuleUnit,
    double? nonMovementRuleUnit,
    DateTime? createdDate,
    DateTime? updatedDate,
    int? company,
    int? unitOfMeansureDefault,
    UserModel? userRef,
    UdcDetails? unitOfMeansureDefaultRef,
    UdcDetails? reportFrequencyRef,
  }) {
    return FastSlowNonMovingRule(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      reportFrequency: reportFrequency ?? this.reportFrequency,
      periodInDays: periodInDays ?? this.periodInDays,
      fastMovementRuleUnit: fastMovementRuleUnit ?? this.fastMovementRuleUnit,
      slowMovementRuleUnit: slowMovementRuleUnit ?? this.slowMovementRuleUnit,
      nonMovementRuleUnit: nonMovementRuleUnit ?? this.nonMovementRuleUnit,
      createdDate: createdDate ?? this.createdDate,
      updatedDate: updatedDate ?? this.updatedDate,
      company: company ?? this.company,
      unitOfMeansureDefault:
          unitOfMeansureDefault ?? this.unitOfMeansureDefault,
      userRef: userRef ?? this.userRef,
      unitOfMeansureDefaultRef:
          unitOfMeansureDefaultRef ?? this.unitOfMeansureDefaultRef,
      reportFrequencyRef: reportFrequencyRef ?? this.reportFrequencyRef,
    );
  }

  factory FastSlowNonMovingRule.fromMap(Map<String, dynamic> map) {
    return FastSlowNonMovingRule(
      id: map['id'],
      userId: map['user_id'],
      reportFrequency: map['report_frequency']?.toString(),
      periodInDays: map['period_in_days'],
      fastMovementRuleUnit: (map['fast_movement_rule_unit'] as num?)
          ?.toDouble(),
      slowMovementRuleUnit: (map['slow_movement_rule_unit'] as num?)
          ?.toDouble(),
      nonMovementRuleUnit: (map['non_movement_rule_unit'] as num?)?.toDouble(),
      createdDate: map['created_date'] != null
          ? DateTime.tryParse(map['created_date'])
          : null,
      updatedDate: map['updated_date'] != null
          ? DateTime.tryParse(map['updated_date'])
          : null,
      company: map['company'],
      unitOfMeansureDefault: map['unit_of_meansure_default'],
      userRef: map['user_id'] != null
          ? UserModel(
              id: map['user_id'],
              userName: map['user_name'],
              password: map['password'],
            )
          : null,
      unitOfMeansureDefaultRef: map['unit_of_meansure_default'] != null
          ? UdcDetails(
              id: map['unit_of_meansure_default'],
              detailCode: map['unit_of_meansure_default_code'],
              description1: map['unit_of_meansure_default_description'],
            )
          : null,
      reportFrequencyRef: (map['report_frequency_description'] != null)
          ? UdcDetails(
              id: int.tryParse(map['report_frequency'].toString()) ?? 0,
              detailCode: map['report_frequency_code'],
              description1: map['report_frequency_description'],
            )
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'report_frequency': reportFrequency,
      'period_in_days': periodInDays,
      'fast_movement_rule_unit': fastMovementRuleUnit,
      'slow_movement_rule_unit': slowMovementRuleUnit,
      'non_movement_rule_unit': nonMovementRuleUnit,
      'created_date': createdDate?.toIso8601String(),
      'updated_date': updatedDate?.toIso8601String(),
      'company': company,
      'unit_of_meansure_default': unitOfMeansureDefault,
    };
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    reportFrequency,
    periodInDays,
    fastMovementRuleUnit,
    slowMovementRuleUnit,
    nonMovementRuleUnit,
    createdDate,
    updatedDate,
    company,
    unitOfMeansureDefault,
    userRef,
    unitOfMeansureDefaultRef,
    reportFrequencyRef,
  ];
}
