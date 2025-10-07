import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/udc_detail/models/udc_details.dart';

abstract class UdcDetailsEvent extends Equatable {
  const UdcDetailsEvent();

  @override
  List<Object?> get props => [];
}

class LoadUdcDetails extends UdcDetailsEvent {
  final String groupCode;
  const LoadUdcDetails(this.groupCode);

  @override
  List<Object?> get props => [groupCode];
}

class CreateUdcDetail extends UdcDetailsEvent {
  final UdcDetails detail;
  const CreateUdcDetail(this.detail);

  @override
  List<Object?> get props => [detail];
}

class UpdateUdcDetail extends UdcDetailsEvent {
  final UdcDetails detail;
  const UpdateUdcDetail(this.detail);

  @override
  List<Object?> get props => [detail];
}
