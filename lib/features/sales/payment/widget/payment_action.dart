import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:savvy_stock/features/sales/customer/blocs/customer_bloc.dart';
import 'package:savvy_stock/features/sales/invoice/screens/invoice_review_screen.dart';
import 'package:savvy_stock/features/sales/payment/blocs/payment_bloc.dart';
import 'package:savvy_stock/features/sales/payment/blocs/payment_event.dart';
import 'package:savvy_stock/features/sales/payment/blocs/payment_state.dart';
import 'package:savvy_stock/features/sales/payment/models/payment_model.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/blocs/sales_item_entry_bloc.dart';

class PaymentAction extends StatefulWidget {
  final PaymentState state;
  const PaymentAction({super.key, required this.state});

  @override
  State<PaymentAction> createState() => _PaymentActionState();
}

class _PaymentActionState extends State<PaymentAction> {
  // Add this method to your SalesItemEntryConfirmedItem class
  void _navigateToInvoice(BuildContext context) {
    final customerBloc = context.read<CustomerBloc>();
    final itemEntryBloc = context.read<ItemEntryBloc>();
    final paymentBloc = context.read<PaymentBloc>();

    final customer = customerBloc.state.selectedBillToCustomer;
    final items = itemEntryBloc.state.confirmedItems;

    print('Selected customer: ${customer.id} - ${customer.name}');
    print('Confirmed items: ${items.length}');
    // Update this check to properly verify if a customer is selected
    if (customer.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer first')),
      );
      return;
    }

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add items to the order')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: customerBloc),
            BlocProvider.value(value: itemEntryBloc),
            BlocProvider.value(value: paymentBloc),
          ],
          child: InvoiceReviewScreen(
            orderId: 'ORD-${DateTime.now().millisecondsSinceEpoch}',
            orderDate: DateTime.now(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              onPressed: widget.state.status == PaymentStatus.processing
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
              child: widget.state.status == PaymentStatus.processing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'REVIEW PAYMENT',
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
  }
}
