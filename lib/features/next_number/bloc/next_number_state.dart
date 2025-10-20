// features/stock/next_number/blocs/next_number_state.dart

import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/next_number/model/next_number_model.dart';

enum NextNumberStatus {
  initial,
  loading,
  loaded,
  generating,
  creating,
  updating,
  deleting,
  success,
  failure,
}

class NextNumberState extends Equatable {
  final NextNumberStatus status;
  final List<NextNumberModel> items;
  final List<NextNumberModel> createItems;
  final List<NextNumberModel> editItems;
  final List<NextNumberModel> multiSelectionItems;
  final NextNumberModel? selected;
  final NextNumberModel? selected1;
  final NextNumberModel? selected2;
  final String message;
  final String? error;
  final int companyId;
  final int? generatedNumber;

  const NextNumberState({
    this.status = NextNumberStatus.initial,
    this.items = const [],
    this.createItems = const [],
    this.editItems = const [],
    this.multiSelectionItems = const [],
    this.selected,
    this.selected1,
    this.selected2,
    this.message = '',
    this.error,
    this.companyId = 0,
    this.generatedNumber,
  });

  bool get isLoaded => status == NextNumberStatus.loaded;
  bool get isLoading => status == NextNumberStatus.loading;
  bool get isSuccess => status == NextNumberStatus.success;
  bool get isFailure => status == NextNumberStatus.failure;
  bool get isGenerating => status == NextNumberStatus.generating;
  bool get isCreating => status == NextNumberStatus.creating;
  bool get isUpdating => status == NextNumberStatus.updating;
  bool get isDeleting => status == NextNumberStatus.deleting;

  NextNumberState copyWith({
    NextNumberStatus? status,
    List<NextNumberModel>? items,
    List<NextNumberModel>? createItems,
    List<NextNumberModel>? editItems,
    List<NextNumberModel>? multiSelectionItems,
    NextNumberModel? selected,
    NextNumberModel? selected1,
    NextNumberModel? selected2,
    String? message,
    String? error,
    int? companyId,
    int? generatedNumber,
  }) {
    return NextNumberState(
      status: status ?? this.status,
      items: items ?? this.items,
      createItems: createItems ?? this.createItems,
      editItems: editItems ?? this.editItems,
      multiSelectionItems: multiSelectionItems ?? this.multiSelectionItems,
      selected: selected ?? this.selected,
      selected1: selected1 ?? this.selected1,
      selected2: selected2 ?? this.selected2,
      message: message ?? this.message,
      error: error ?? this.error,
      companyId: companyId ?? this.companyId,
      generatedNumber: generatedNumber ?? this.generatedNumber,
    );
  }

  @override
  List<Object?> get props => [
    status,
    items,
    createItems,
    editItems,
    multiSelectionItems,
    selected,
    selected1,
    selected2,
    message,
    error,
    companyId,
    generatedNumber,
  ];
}
