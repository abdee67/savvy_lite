// features/stock/next_number/blocs/next_number_event.dart

import 'package:flutter/material.dart';
import 'package:savvy_stock/features/next_number/model/next_number_model.dart';
import 'package:equatable/equatable.dart';

@immutable
abstract class NextNumberEvent extends Equatable {
  const NextNumberEvent();

  @override
  List<Object?> get props => [];
}

class LoadNextNumbers extends NextNumberEvent {
  final int companyId;
  const LoadNextNumbers(this.companyId);

  @override
  List<Object?> get props => [companyId];
}

class GenerateNextNumber extends NextNumberEvent {
  final String code;
  const GenerateNextNumber(this.code);

  @override
  List<Object?> get props => [code];
}

class SaveNextNumber extends NextNumberEvent {
  final NextNumberModel item;
  const SaveNextNumber(this.item);

  @override
  List<Object?> get props => [item];
}

class UpdateNextNumber extends NextNumberEvent {
  final NextNumberModel item;
  const UpdateNextNumber(this.item);

  @override
  List<Object?> get props => [item];
}

class DeleteNextNumber extends NextNumberEvent {
  final NextNumberModel item;
  const DeleteNextNumber(this.item);

  @override
  List<Object?> get props => [item];
}

class PrepareCreateNextNumber extends NextNumberEvent {
  final int companyId;
  const PrepareCreateNextNumber(this.companyId);

  @override
  List<Object?> get props => [companyId];
}

class PrepareCopyNextNumber extends NextNumberEvent {
  final NextNumberModel item;
  const PrepareCopyNextNumber(this.item);

  @override
  List<Object?> get props => [item];
}

class PrepareEditNextNumber extends NextNumberEvent {
  const PrepareEditNextNumber();

  @override
  List<Object?> get props => [];
}

class SetSelectedNextNumber extends NextNumberEvent {
  final NextNumberModel? item;
  const SetSelectedNextNumber(this.item);

  @override
  List<Object?> get props => [item];
}

class SetMultiSelectionNextNumbers extends NextNumberEvent {
  final List<NextNumberModel> items;
  const SetMultiSelectionNextNumbers(this.items);

  @override
  List<Object?> get props => [items];
}

class AddToCreateList extends NextNumberEvent {
  final NextNumberModel item;
  const AddToCreateList(this.item);

  @override
  List<Object?> get props => [item];
}

class RemoveFromCreateList extends NextNumberEvent {
  final NextNumberModel item;
  const RemoveFromCreateList(this.item);

  @override
  List<Object?> get props => [item];
}

class ClearCreateList extends NextNumberEvent {
  const ClearCreateList();

  @override
  List<Object?> get props => [];
}

class CancelCreate extends NextNumberEvent {
  const CancelCreate();

  @override
  List<Object?> get props => [];
}

class CancelUpdate extends NextNumberEvent {
  const CancelUpdate();

  @override
  List<Object?> get props => [];
}
