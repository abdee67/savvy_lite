import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:savvy_stock/core/constants/app_routes.dart';
import 'package:savvy_stock/features/sales/customer/blocs/customer_bloc.dart';
import 'package:savvy_stock/features/sales/payment/blocs/payment_bloc.dart';
import 'package:savvy_stock/features/sales/payment/blocs/payment_state.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/blocs/sales_item_entry_bloc.dart';

class PaymentAction extends StatefulWidget {
  const PaymentAction({super.key});

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

    print('Selected customer: ${customer.id} - ${customer.customerName}');
    print('Confirmed items: ${items.length}');
    // Update this check to properly verify if a customer is selected
    if (customer.id == null) {
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

    context.push(
      AppRoutes.salesInvoice,
      extra: {'confirmedItems': items, 'customer': customer},
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaymentBloc, PaymentState>(
      builder: (context, state) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(40),
                ),
              ),
              child: const Text(
                'Back',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              onPressed: state.status == PaymentStatus.processing
                  ? null
                  : () => _navigateToInvoice(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF155888),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(40),
                ),
              ),
              child: state.status == PaymentStatus.processing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Review',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}
