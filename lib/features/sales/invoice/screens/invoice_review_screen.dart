import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:savvy_stock/features/sales/customer/blocs/customer_bloc.dart';
import 'package:savvy_stock/features/sales/customer/blocs/customer_state.dart';
import 'package:savvy_stock/features/sales/customer/models/customer_model.dart';
import 'package:savvy_stock/features/sales/invoice/blocs/invoice_bloc.dart';
import 'package:savvy_stock/features/sales/invoice/blocs/invoice_event.dart';
import 'package:savvy_stock/features/sales/invoice/blocs/invoice_state.dart';
import 'package:savvy_stock/features/sales/invoice/models/invoice_model.dart';
import 'package:savvy_stock/features/sales/invoice/widget/invoice_first_part.dart';
import 'package:savvy_stock/features/sales/invoice/widget/invoice_second_part.dart';
import 'package:savvy_stock/features/sales/invoice/widget/invoice_third_part.dart';
import 'package:savvy_stock/features/sales/payment/blocs/payment_bloc.dart';
import 'package:savvy_stock/features/sales/payment/blocs/payment_state.dart';
import 'package:savvy_stock/features/sales/payment/models/payment_model.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/blocs/sales_item_entry_bloc.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/blocs/sales_item_entry_state.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/models/confirmed_item.dart';

class InvoiceReviewScreen extends StatelessWidget {
  final String orderId;
  final DateTime orderDate;

  const InvoiceReviewScreen({
    super.key,
    required this.orderId,
    required this.orderDate,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<CustomerBloc, CustomerState>(
          listener: (context, customerState) {
            // Handle customer state changes if needed
          },
        ),
        BlocListener<ItemEntryBloc, ItemEntryState>(
          listener: (context, itemState) {
            // Handle item state changes if needed
          },
        ),
        BlocListener<PaymentBloc, PaymentState>(
          listener: (context, paymentState) {
            // Handle payment state changes if needed
          },
        ),
      ],
      child: BlocBuilder<CustomerBloc, CustomerState>(
        builder: (context, customerState) {
          return BlocBuilder<ItemEntryBloc, ItemEntryState>(
            builder: (context, itemState) {
              return BlocBuilder<PaymentBloc, PaymentState>(
                builder: (context, paymentState) {
                  final customer = customerState.selectedBillToCustomer;
                  final confirmedItems = itemState.confirmedItems;
                  print(customer);
                  print(confirmedItems);
                  print(paymentState);
                  final paymentModel = PaymentModel.fromPaymentState(
                    id: 'PAY-$orderId',
                    transactionID:
                        paymentState.transactionID ??
                        'TXN-${DateTime.now().millisecondsSinceEpoch}',
                    state: paymentState,
                    paymentStatus: 'Completed',
                  );

                  return BlocProvider(
                    create: (context) => InvoiceBloc()
                      ..add(
                        LoadInvoice(
                          orderId: orderId,
                          orderDate: orderDate,
                          customer: customer,
                          confirmedItems: confirmedItems,
                          paymentModel: paymentModel,
                        ),
                      ),
                    child: Scaffold(
                      appBar: AppBar(
                        title: const Text('Invoice Preview'),
                        actions: [
                          IconButton(
                            icon: const Icon(Icons.print),
                            onPressed: () {
                              final invoice = InvoiceModel.fromOrderAndPayment(
                                orderId: orderId,
                                orderDate: orderDate,
                                customer: customer,
                                confirmedItems: confirmedItems,
                                paymentModel: paymentModel,
                              );
                              context.read<InvoiceBloc>().add(
                                PrintInvoice(invoice: invoice),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Printing invoice...'),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.save),
                            onPressed: () {
                              final invoice = InvoiceModel.fromOrderAndPayment(
                                orderId: orderId,
                                orderDate: orderDate,
                                customer: customer,
                                confirmedItems: confirmedItems,
                                paymentModel: paymentModel,
                              );
                              context.read<InvoiceBloc>().add(
                                SaveInvoice(invoice: invoice),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Invoice saved successfully!'),
                                ),
                              );
                            },
                          ),
                          PopupMenuButton<String>(
                            onSelected: (format) {
                              final invoice = InvoiceModel.fromOrderAndPayment(
                                orderId: orderId,
                                orderDate: orderDate,
                                customer: customer,
                                confirmedItems: confirmedItems,
                                paymentModel: paymentModel,
                              );
                              context.read<InvoiceBloc>().add(
                                ExportInvoice(invoice: invoice, format: format),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Exporting as $format...'),
                                ),
                              );
                            },
                            itemBuilder: (BuildContext context) => [
                              const PopupMenuItem<String>(
                                value: 'pdf',
                                child: Text('Export as PDF'),
                              ),
                              const PopupMenuItem<String>(
                                value: 'excel',
                                child: Text('Export as Excel'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      body: BlocBuilder<InvoiceBloc, InvoiceState>(
                        builder: (context, state) {
                          if (state.status == InvoiceStatus.loading) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          } else if (state.status == InvoiceStatus.failure) {
                            return Center(
                              child: Text('Error: ${state.errorMessage}'),
                            );
                          } else if (state.status == InvoiceStatus.success &&
                              state.invoice != null) {
                            return SingleChildScrollView(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  InvoiceFirstPart(
                                    customer: state.invoice!.customer,
                                    date: state.invoice!.date,
                                    invoiceNumber: state.invoice!.id,
                                  ),
                                  InvoiceSecondPart(
                                    items: state.invoice!.items,
                                  ),
                                  InvoiceThirdPart(
                                    payment: state.invoice!.payment,
                                  ),
                                ],
                              ),
                            );
                          } else {
                            return const Center(
                              child: Text('No invoice data available'),
                            );
                          }
                        },
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
