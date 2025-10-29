import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:savvy_stock/features/sales/customer/blocs/customer_bloc.dart';
import 'package:savvy_stock/features/sales/customer/models/customer_model.dart';
import 'package:savvy_stock/features/sales/invoice/blocs/invoice_bloc.dart';
import 'package:savvy_stock/features/sales/invoice/blocs/invoice_event.dart';
import 'package:savvy_stock/features/sales/invoice/blocs/invoice_state.dart';
import 'package:savvy_stock/features/sales/invoice/models/invoice_model.dart';
import 'package:savvy_stock/features/sales/invoice/widget/invoice_action.dart';
import 'package:savvy_stock/features/sales/invoice/widget/invoice_first_part.dart';
import 'package:savvy_stock/features/sales/invoice/widget/invoice_second_part.dart';
import 'package:savvy_stock/features/sales/invoice/widget/invoice_third_part.dart';
import 'package:savvy_stock/features/sales/payment/blocs/payment_bloc.dart';
import 'package:savvy_stock/features/sales/payment/models/payment_model.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/blocs/sales_item_entry_bloc.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/models/confirmed_item.dart';

class InvoiceReviewScreen extends StatelessWidget {
  const InvoiceReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get data from global blocs
    final customerBloc = context.read<CustomerBloc>();
    final itemEntryBloc = context.read<ItemEntryBloc>();
    final paymentBloc = context.read<PaymentBloc>();

    final customer = customerBloc.state.selectedBillToCustomer;
    final confirmedItems = itemEntryBloc.state.confirmedItems;
    final paymentState = paymentBloc.state;

    if (confirmedItems.isEmpty) {
      debugPrint('Error: No items in the order');
      return const Scaffold(
        body: Center(child: Text('Error: No items in the order')),
      );
    }

    // Create invoice data
    try {
      final paymentModel = PaymentModel.fromPaymentState(
        id: 'PAY-${DateTime.now().millisecondsSinceEpoch}',
        transactionID:
            paymentState.transactionID ??
            'TXN-${DateTime.now().millisecondsSinceEpoch}',
        state: paymentState,
        paymentStatus: 'Completed',
      );

      debugPrint('Creating invoice with:');
      debugPrint('- Customer ID: ${customer.id}');
      debugPrint('- Items count: ${confirmedItems.length}');
      debugPrint('- Payment Type: ${paymentState.paymentType}');

      return BlocProvider(
        create: (context) => InvoiceBloc()
          ..add(
            LoadInvoice(
              orderId: DateTime.now().millisecondsSinceEpoch.toString(),
              orderDate: DateTime.now(),
              customer: customer,
              confirmedItems: confirmedItems,
              paymentModel: paymentModel,
            ),
          ),
        child: _InvoiceReviewContent(
          customer: customer,
          confirmedItems: confirmedItems,
          paymentModel: paymentModel,
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('Error creating invoice: $e');
      debugPrint('Stack trace: $stackTrace');
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Failed to create invoice:'),
              const SizedBox(height: 8),
              Text(
                e.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }
  }
}

class _InvoiceReviewContent extends StatelessWidget {
  final Customer customer;
  final List<ConfirmedItem> confirmedItems;
  final PaymentModel paymentModel;

  const _InvoiceReviewContent({
    required this.customer,
    required this.confirmedItems,
    required this.paymentModel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Invoice Preview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () =>
                _printInvoice(context, customer, confirmedItems, paymentModel),
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () =>
                _saveInvoice(context, customer, confirmedItems, paymentModel),
          ),
          PopupMenuButton<String>(
            onSelected: (format) => _exportInvoice(
              context,
              customer,
              confirmedItems,
              paymentModel,
              format,
            ),
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
      body: SafeArea(
        child: BlocBuilder<InvoiceBloc, InvoiceState>(
          builder: (context, state) {
            if (state.status == InvoiceStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state.status == InvoiceStatus.failure) {
              return Center(child: Text('Error: ${state.errorMessage}'));
            } else if (state.status == InvoiceStatus.success &&
                state.invoice != null) {
              return _buildInvoiceContent(state.invoice!);
            } else {
              return const Center(child: Text('No invoice data available'));
            }
          },
        ),
      ),
    );
  }

  Widget _buildInvoiceContent(InvoiceModel invoice) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          InvoiceFirstPart(
            customer: invoice.customer,
            date: invoice.date,
            invoiceNumber: invoice.id,
          ),
          const SizedBox(height: 16),
          InvoiceSecondPart(items: invoice.items),
          const SizedBox(height: 16),
          InvoiceThirdPart(payment: invoice.payment),
          const SizedBox(height: 16),
          const InvoiceAction(),
        ],
      ),
    );
  }

  void _printInvoice(
    BuildContext context,
    Customer customer,
    List<ConfirmedItem> confirmedItems,
    PaymentModel paymentModel,
  ) {
    final invoice = InvoiceModel.fromOrderAndPayment(
      orderId: DateTime.now().millisecondsSinceEpoch.toString(),
      orderDate: DateTime.now(),
      customer: customer,
      confirmedItems: confirmedItems,
      paymentModel: paymentModel,
    );
    context.read<InvoiceBloc>().add(PrintInvoice(invoice: invoice));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Printing invoice...')));
  }

  void _saveInvoice(
    BuildContext context,
    Customer customer,
    List<ConfirmedItem> confirmedItems,
    PaymentModel paymentModel,
  ) {
    final invoice = InvoiceModel.fromOrderAndPayment(
      orderId: DateTime.now().millisecondsSinceEpoch.toString(),
      orderDate: DateTime.now(),
      customer: customer,
      confirmedItems: confirmedItems,
      paymentModel: paymentModel,
    );
    context.read<InvoiceBloc>().add(SaveInvoice(invoice: invoice));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invoice saved successfully!')),
    );
  }

  void _exportInvoice(
    BuildContext context,
    Customer customer,
    List<ConfirmedItem> confirmedItems,
    PaymentModel paymentModel,
    String format,
  ) {
    final invoice = InvoiceModel.fromOrderAndPayment(
      orderId: DateTime.now().millisecondsSinceEpoch.toString(),
      orderDate: DateTime.now(),
      customer: customer,
      confirmedItems: confirmedItems,
      paymentModel: paymentModel,
    );
    context.read<InvoiceBloc>().add(
      ExportInvoice(invoice: invoice, format: format),
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Exporting as $format...')));
  }
}
