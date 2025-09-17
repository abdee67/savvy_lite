import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:savvy_stock/features/sales/customer/blocs/customer_bloc.dart';
import 'package:savvy_stock/features/sales/invoice/blocs/invoice_bloc.dart';
import 'package:savvy_stock/features/sales/invoice/blocs/invoice_state.dart';
import 'package:savvy_stock/features/sales/payment/blocs/payment_bloc.dart';
import 'package:savvy_stock/features/sales/payment/blocs/payment_event.dart';
import 'package:savvy_stock/features/sales/payment/blocs/payment_state.dart';
import 'package:savvy_stock/features/sales/payment/models/payment_model.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/blocs/sales_item_entry_bloc.dart';

class InvoiceAction extends StatefulWidget {
  const InvoiceAction({super.key});

  @override
  State<InvoiceAction> createState() => _InvoiceActionState();
}

class _InvoiceActionState extends State<InvoiceAction> {
  // Add this method to your SalesItemEntryConfirmedItem class
  void _navigateToInvoice(BuildContext context) {
    final customerBloc = context.read<CustomerBloc>();
    final itemEntryBloc = context.read<ItemEntryBloc>();
    final paymentBloc = context.read<PaymentBloc>();

    final customer = customerBloc.state.selectedBillToCustomer;
    final items = itemEntryBloc.state.confirmedItems;

    context.push(
      '/invoice-review-screen',
      extra: {'confirmedItems': items, 'customer': customer},
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InvoiceBloc, InvoiceState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.only(top: 4, right: 4, left: 4, bottom: 0),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: state.status == InvoiceStatus.loading
                      ? null
                      : () => _navigateToInvoice(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF155888),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: state.status == InvoiceStatus.loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Finish',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
