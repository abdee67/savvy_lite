// features/next_number/blocs/next_number_event.dart
import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/next_number/model/next_number_model.dart';

abstract class NextNumberEvent extends Equatable {
  const NextNumberEvent();

  @override
  List<Object> get props => [];
}

class LoadNextNumbers extends NextNumberEvent {
  final int companyId;
  const LoadNextNumbers(this.companyId);

  @override
  List<Object> get props => [companyId];
}

class GenerateNextNumber extends NextNumberEvent {
  final String code;
  const GenerateNextNumber(this.code);

  @override
  List<Object> get props => [code];
}

class GenerateFormattedNumber extends NextNumberEvent {
  final String code;
  const GenerateFormattedNumber(this.code);

  @override
  List<Object> get props => [code];
}

class SaveNextNumber extends NextNumberEvent {
  final NextNumberModel item;
  const SaveNextNumber(this.item);

  @override
  List<Object> get props => [item];
}

class UpdateNextNumber extends NextNumberEvent {
  final NextNumberModel item;
  const UpdateNextNumber(this.item);

  @override
  List<Object> get props => [item];
}

class DeleteNextNumber extends NextNumberEvent {
  final NextNumberModel item;
  const DeleteNextNumber(this.item);

  @override
  List<Object> get props => [item];
}

class BatchSaveNextNumbers extends NextNumberEvent {
  final List<NextNumberModel> items;
  const BatchSaveNextNumbers(this.items);

  @override
  List<Object> get props => [items];
}

class BatchUpdateNextNumbers extends NextNumberEvent {
  final List<NextNumberModel> items;
  const BatchUpdateNextNumbers(this.items);

  @override
  List<Object> get props => [items];
}

class BatchDeleteNextNumbers extends NextNumberEvent {
  final List<NextNumberModel> items;
  const BatchDeleteNextNumbers(this.items);

  @override
  List<Object> get props => [items];
}

class PrepareCreateNextNumber extends NextNumberEvent {
  final int companyId;
  const PrepareCreateNextNumber(this.companyId);

  @override
  List<Object> get props => [companyId];
}

class PrepareCopyNextNumber extends NextNumberEvent {
  final NextNumberModel item;
  const PrepareCopyNextNumber(this.item);

  @override
  List<Object> get props => [item];
}

class PrepareEditNextNumber extends NextNumberEvent {
  const PrepareEditNextNumber();

  @override
  List<Object> get props => [];
}

class SetSelectedNextNumber extends NextNumberEvent {
  final NextNumberModel item;
  const SetSelectedNextNumber(this.item);

  @override
  List<Object> get props => [item];
}

class SetMultiSelectionNextNumbers extends NextNumberEvent {
  final List<NextNumberModel> items;
  const SetMultiSelectionNextNumbers(this.items);

  @override
  List<Object> get props => [items];
}

class AddToCreateList extends NextNumberEvent {
  final NextNumberModel item;
  const AddToCreateList(this.item);

  @override
  List<Object> get props => [item];
}

class RemoveFromCreateList extends NextNumberEvent {
  final NextNumberModel item;
  const RemoveFromCreateList(this.item);

  @override
  List<Object> get props => [item];
}

class ClearCreateList extends NextNumberEvent {}

class CancelCreate extends NextNumberEvent {}

class CancelUpdate extends NextNumberEvent {}

class ResetNextNumber extends NextNumberEvent {
  final String code;
  final int startFrom;
  const ResetNextNumber(this.code, this.startFrom);

  @override
  List<Object> get props => [code, startFrom];
}

class CheckCodeExists extends NextNumberEvent {
  final String code;
  final int? excludeId;
  const CheckCodeExists(this.code, {this.excludeId});

  @override
  List<Object> get props => [code, excludeId ?? 0];
}

class CopyDefaultNextNumbers extends NextNumberEvent {}

class GetNextNumberSummary extends NextNumberEvent {
  final int companyId;
  const GetNextNumberSummary(this.companyId);

  @override
  List<Object> get props => [companyId];
}