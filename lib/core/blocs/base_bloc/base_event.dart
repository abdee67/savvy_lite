/*import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

@immutable
abstract class BaseEvent extends Equatable {
  const BaseEvent();

  @override
  List<Object> get props => [];
}

class LoadBaseData<T> extends BaseEvent {
  final List<T> data;
  const LoadBaseData(this.data);
}

class CreateBaseData<T> extends BaseEvent {
  final T data;
  const CreateBaseData(this.data);
}

class UpdateBaseData<T> extends BaseEvent {
  final T data;
  const UpdateBaseData(this.data);

}

class SearchBaseData<T> extends BaseEvent {
  final String query;
  const SearchBaseData(this.query);
}

class SelectBaseData<T> extends BaseEvent {
  final T data;
  final bool isSelected;
  const SelectBaseData(this.data, {this.isSelected = true});

}

class SelectAllBaseData<T> extends BaseEvent {
  final bool selectAll;
  const SelectAllBaseData(this.selectAll);

  @override
  List<Object> get props => [selectAll];
}

class ClearSelection extends BaseEvent {}

class DeleteSelectedBaseData<T> extends BaseEvent {
  final List<T> selectedItems;
  const DeleteSelectedBaseData(this.selectedItems);
}

class UndoDelete<T> extends BaseEvent {
  final T deletedItem;
  final int deletedIndex;

  const UndoDelete({required this.deletedItem, required this.deletedIndex});
}

class ShowBaseData<T> extends BaseEvent {
  final T data;
  const ShowBaseData(this.data);

}

class HideBaseData<T> extends BaseEvent {
  final T data;
  const HideBaseData(this.data);
}

class AddBaseData<T> extends BaseEvent {
  final T data;
  const AddBaseData(this.data);
}


class ExportBaseData<T> extends BaseEvent {
  final T data;
  const ExportBaseData(this.data);

}
*/
