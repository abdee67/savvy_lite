import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:savvy_stock/core/constants/app_routes.dart';
import 'package:savvy_stock/features/sales/customer/blocs/customer_bloc.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/blocs/sales_item_entry_bloc.dart';
import 'package:savvy_stock/features/sales/sales_order/integration/bloc/sales_order_coordinator_bloc.dart';
import 'package:savvy_stock/features/sales/sales_order/integration/bloc/sales_order_coordinator_event.dart';
import 'package:savvy_stock/features/sales/sales_order/integration/bloc/sales_order_coordinator_state.dart';

class PaymentAction extends StatefulWidget {
  const PaymentAction({super.key});

  @override
  State<PaymentAction> createState() => _PaymentActionState();
}

class _PaymentActionState extends State<PaymentAction> {
  // Add this method to your SalesItemEntryConfirmedItem class
  void _navigateToInvoice(
    BuildContext context,
    SalesOrderCoordinatorState state,
  ) {
    final coordinatorBloc = context.read<SalesOrderCoordinatorBloc>();

    // Validate final calculations
    coordinatorBloc.add(const CalculateCompleteOrderTotals());

    // Create the complete sales order
    coordinatorBloc.add(GenerateInvoiceFromSalesOrder());

    // Show processing state
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Prepapring your invoice...'),
        duration: Duration(seconds: 3),
      ),
    );
    // Listen for completion
    coordinatorBloc.stream
        .firstWhere(
          (state) =>
              state.isOrderComplete ||
              state.status == SalesOrderCoordinatorStatus.error,
        )
        .then((finalState) {
          if (finalState.isOrderComplete && finalState.invoiceGenerated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Payment completed! Invoice: ${finalState.invoiceFsNumber}',
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 5),
              ),
            );

            // Navigate to success screen or invoice preview
            _viewInvoice(context, finalState);
          }
        });
  }

  void _viewInvoice(BuildContext context, SalesOrderCoordinatorState state) {
    final customerBloc = context.read<CustomerBloc>();
    final selectedCustomer = customerBloc.state.selectedBillToCustomer;

    if (selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer first')),
      );
      return;
    }

    context.push(
      AppRoutes.salesInvoice,
      extra: {
        'confirmedItems': state.currentDetails,
        'customer': selectedCustomer,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SalesOrderCoordinatorBloc, SalesOrderCoordinatorState>(
      builder: (context, state) {
        final isValid =
            state.lastTotalAmount != null &&
            state.lastTotalAmount! > 0 &&
            state.paymentType.isNotEmpty &&
            state.paymentInstrument.isNotEmpty &&
            (state.paymentType != 'Credit' || state.paymentTerm.isNotEmpty);

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
              onPressed:
                  isValid &&
                      state.status == SalesOrderCoordinatorStatus.processing
                  ? null
                  : () => _navigateToInvoice(context, state),
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
              child: state.status == SalesOrderCoordinatorStatus.processing
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Processing Payment...'),
                      ],
                    )
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
