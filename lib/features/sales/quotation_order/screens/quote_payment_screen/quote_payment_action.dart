import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:savvy_stock/core/constants/app_routes.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/sales/quotation_order/bloc/quotation_order_bloc.dart';
import 'package:savvy_stock/features/sales/quotation_order/bloc/quotation_order_event.dart';
import 'package:savvy_stock/features/sales/quotation_order/bloc/quotation_order_state.dart';

class QuotePaymentAction extends StatefulWidget {
  const QuotePaymentAction({super.key});

  @override
  State<QuotePaymentAction> createState() => _QuotePaymentActionState();
}

class _QuotePaymentActionState extends State<QuotePaymentAction> {
  // Add this method to your SalesItemEntryConfirmedItem class
  void _navigateToInvoice(BuildContext context, QuotationOrderState state) {
    final coordinatorBloc = context.read<QuotationOrderBloc>();
    final coordinatorState = coordinatorBloc.state;

    // Validate final calculations
    coordinatorBloc.add(
      CalculateQuotationTotals(
        header: coordinatorState.selectedHeader!,
        details: coordinatorState.createDetailItems,
        applyWithholding: coordinatorState.canApplyWithholding!,
        discountAmount: coordinatorState.discountAmount!,
        systemConstants: coordinatorState.systemConstants!,
      ),
    );

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

    if (context.read<AuthBloc>().state.hasAccessToPrivilege(
      AppRoutes.quotationInvoiceReview,
    )) {
      if (mounted) {
        context.push(AppRoutes.quotationInvoiceReview);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No access to quotation invoice review')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QuotationOrderBloc, QuotationOrderState>(
      builder: (context, state) {
        final isValid = state.totalAmount != null && state.totalAmount! > 0;

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed:
                  isValid && state.status == QuotationOrderStatus.processing
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
              child: state.status == QuotationOrderStatus.processing
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
