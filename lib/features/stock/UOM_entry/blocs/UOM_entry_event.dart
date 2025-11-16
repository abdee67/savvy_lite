import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/sales/customer/models/customer_model.dart';
import 'package:savvy_stock/features/sales/invoice/models/invoice_model.dart';
import 'package:savvy_stock/features/sales/payment/models/payment_model.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/models/confirmed_item.dart';

abstract class InvoiceEvent extends Equatable {
  const InvoiceEvent();

  @override
  List<Object> get props => [];
}

class LoadInvoice extends InvoiceEvent {
  final String orderId;
  final DateTime orderDate;
  final Customer customer;
  final List<ConfirmedItem> confirmedItems;
  final PaymentModel paymentModel;

  const LoadInvoice({
    required this.orderId,
    required this.orderDate,
    required this.customer,
    required this.confirmedItems,
    required this.paymentModel,
  });

  @override
  List<Object> get props => [
    orderId,
    orderDate,
    customer,
    confirmedItems,
    paymentModel,
  ];
}

class PrintInvoice extends InvoiceEvent {
  final InvoiceModel invoice;

  const PrintInvoice({required this.invoice});

  @override
  List<Object> get props => [invoice];
}

class SaveInvoice extends InvoiceEvent {
  final InvoiceModel invoice;

  const SaveInvoice({required this.invoice});

  @override
  List<Object> get props => [invoice];
}

class ExportInvoice extends InvoiceEvent {
  final InvoiceModel invoice;
  final String format; // pdf, excel, etc.

  const ExportInvoice({required this.invoice, required this.format});

  @override
  List<Object> get props => [invoice, format];
}
