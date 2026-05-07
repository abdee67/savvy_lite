import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:savvy_stock/core/constants/app_routes.dart';
import 'package:savvy_stock/features/sales/sales_order/integration/bloc/sales_order_coordinator_bloc.dart';
import 'package:savvy_stock/features/sales/sales_order/integration/bloc/sales_order_coordinator_event.dart';
import 'package:savvy_stock/features/sales/sales_order/integration/bloc/sales_order_coordinator_state.dart';
import 'package:savvy_stock/features/sales/sales_order/invoice/screens/invoice_review_screen.dart';

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

    /* Create the complete sales order
    coordinatorBloc.add(GenerateInvoiceFromSalesOrder());

    // Show processing state
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Prepapring your invoice...'),
        duration: Duration(seconds: 3),
      ),
    );*/
    // Listen for completion
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const InvoiceReviewScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SalesOrderCoordinatorBloc, SalesOrderCoordinatorState>(
      builder: (context, state) {
        final isValid =
            state.lastTotalAmount != null &&
            state.lastTotalAmount! > 0 &&
            state.paymentMethod.isNotEmpty &&
            (state.paymentMethod != 'Credit' || state.paymentTerm.isNotEmpty);

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 24,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Back',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
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
                    borderRadius: BorderRadius.circular(20),
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
            ),
          ],
        );
      },
    );
  }
}
