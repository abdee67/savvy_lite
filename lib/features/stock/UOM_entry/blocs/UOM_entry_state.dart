import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/sales/invoice/models/invoice_model.dart';

enum InvoiceStatus { initial, loading, success, failure }

class InvoiceState extends Equatable {
  final InvoiceStatus status;
  final InvoiceModel? invoice;
  final String? errorMessage;

  const InvoiceState({
    this.status = InvoiceStatus.initial,
    this.invoice,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [status, invoice, errorMessage];

  InvoiceState copyWith({
    InvoiceStatus? status,
    InvoiceModel? invoice,
    String? errorMessage,
  }) {
    return InvoiceState(
      status: status ?? this.status,
      invoice: invoice ?? this.invoice,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
