import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/udc_detail/models/udc_details.dart';

enum UdcDetailsStatus {
  initial,
  loading,
  success,
  failure,
  creating,
  updating,
  deleting,
}

class UdcDetailsState extends Equatable {
  final UdcDetailsStatus status;
  final String? message;
  final String? groupCode;
  final List<UdcDetails> details;
  final UdcDetails? selectedDetail;

  const UdcDetailsState({
    this.status = UdcDetailsStatus.initial,
    this.message,
    this.groupCode,
    this.details = const [],
    this.selectedDetail,
  });

  UdcDetailsState copyWith({
    UdcDetailsStatus? status,
    String? message,
    String? groupCode,
    List<UdcDetails>? details,
    UdcDetails? selectedDetail,
  }) {
    return UdcDetailsState(
      status: status ?? this.status,
      message: message ?? this.message,
      groupCode: groupCode ?? this.groupCode,
      details: details ?? this.details,
      selectedDetail: selectedDetail ?? this.selectedDetail,
    );
  }

  @override
  List<Object?> get props => [
    status,
    message,
    groupCode,
    details,
    selectedDetail,
  ];
}
