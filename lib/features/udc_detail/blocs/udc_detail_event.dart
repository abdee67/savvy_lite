import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/udc_detail/models/udc_details.dart';

sealed class UdcDetailsEvent extends Equatable {
  const UdcDetailsEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load UDC details filtered by a specific group code (e.g., "UM").
final class LoadUdcDetailsByGroup extends UdcDetailsEvent {
  final String groupCode;

  const LoadUdcDetailsByGroup(this.groupCode);

  @override
  List<Object> get props => [groupCode];
}

final class CreateUdcDetail extends UdcDetailsEvent {
  final UdcDetails detail;
  const CreateUdcDetail(this.detail);

  @override
  List<Object?> get props => [detail];
}

final class UpdateUdcDetail extends UdcDetailsEvent {
  final UdcDetails detail;
  const UpdateUdcDetail(this.detail);

  @override
  List<Object?> get props => [detail];
}

/// Event to load all UDC details without any filtering.
final class LoadAllUdcDetails extends UdcDetailsEvent {}

/// Event to delete one or more UDC details using their IDs.
final class DeleteSelectedUdcDetails extends UdcDetailsEvent {
  final List<int> ids;

  const DeleteSelectedUdcDetails(this.ids);

  @override
  List<Object> get props => [ids];
}
