import 'package:equatable/equatable.dart';
import 'package:savvy_stock/core/models/system_constant.dart';

enum SystemConstantStatus { initial, loading, success, failure, syncing }

class SystemConstantState extends Equatable {
  final SystemConstantStatus status;
  final List<SystemConstant> systemConstants;
  final List<SystemConstant> createItems;
  final List<SystemConstant> editItems;
  final List<SystemConstant> multiselectionItems;
  final SystemConstant? selected;
  final SystemConstant? selected1;
  final SystemConstant? selected2;
  final String? errorMessage;
  final int unsyncedCount;

  const SystemConstantState({
    this.status = SystemConstantStatus.initial,
    this.systemConstants = const [],
    this.createItems = const [],
    this.editItems = const [],
    this.multiselectionItems = const [],
    this.selected,
    this.selected1,
    this.selected2,
    this.errorMessage,
    this.unsyncedCount = 0,
  });

  SystemConstantState copyWith({
    SystemConstantStatus? status,
    List<SystemConstant>? systemConstants,
    List<SystemConstant>? createItems,
    List<SystemConstant>? editItems,
    List<SystemConstant>? multiselectionItems,
    SystemConstant? selected,
    SystemConstant? selected1,
    SystemConstant? selected2,
    String? errorMessage,
    int? unsyncedCount,
  }) {
    return SystemConstantState(
      status: status ?? this.status,
      systemConstants: systemConstants ?? this.systemConstants,
      createItems: createItems ?? this.createItems,
      editItems: editItems ?? this.editItems,
      multiselectionItems: multiselectionItems ?? this.multiselectionItems,
      selected: selected ?? this.selected,
      selected1: selected1 ?? this.selected1,
      selected2: selected2 ?? this.selected2,
      errorMessage: errorMessage ?? this.errorMessage,
      unsyncedCount: unsyncedCount ?? this.unsyncedCount,
    );
  }

  @override
  List<Object?> get props => [
    status,
    systemConstants,
    createItems,
    editItems,
    multiselectionItems,
    selected,
    selected1,
    selected2,
    errorMessage,
    unsyncedCount,
  ];
}
