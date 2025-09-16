import 'package:bloc/bloc.dart';
import 'package:savvy_stock/features/sales/invoice/blocs/invoice_event.dart';
import 'package:savvy_stock/features/sales/invoice/blocs/invoice_state.dart';
import 'package:savvy_stock/features/sales/invoice/models/invoice_model.dart';

class InvoiceBloc extends Bloc<InvoiceEvent, InvoiceState> {
  InvoiceBloc() : super(const InvoiceState()) {
    on<LoadInvoice>(_onLoadInvoice);
    on<PrintInvoice>(_onPrintInvoice);
    on<SaveInvoice>(_onSaveInvoice);
    on<ExportInvoice>(_onExportInvoice);
  }

  void _onLoadInvoice(LoadInvoice event, Emitter<InvoiceState> emit) {
    emit(state.copyWith(status: InvoiceStatus.loading));

    try {
      final invoice = InvoiceModel.fromOrderAndPayment(
        orderId: event.orderId,
        orderDate: event.orderDate,
        customer: event.customer,
        confirmedItems: event.confirmedItems,
        paymentModel: event.paymentModel,
      );

      emit(state.copyWith(status: InvoiceStatus.success, invoice: invoice));
    } catch (error) {
      emit(
        state.copyWith(
          status: InvoiceStatus.failure,
          errorMessage: 'Failed to load invoice: ${error.toString()}',
        ),
      );
    }
  }

  void _onPrintInvoice(PrintInvoice event, Emitter<InvoiceState> emit) {
    // Implement printing logic here
    print('Printing invoice: ${event.invoice.id}');
    // You might want to integrate with a printing package like printing: ^x.x.x
  }

  void _onSaveInvoice(SaveInvoice event, Emitter<InvoiceState> emit) {
    // Implement saving logic here (to database, cloud, etc.)
    print('Saving invoice: ${event.invoice.id}');
  }

  void _onExportInvoice(ExportInvoice event, Emitter<InvoiceState> emit) {
    // Implement export logic here
    print('Exporting invoice ${event.invoice.id} as ${event.format}');
  }
}
