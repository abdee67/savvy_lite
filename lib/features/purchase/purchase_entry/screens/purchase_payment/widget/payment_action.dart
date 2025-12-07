// features/purchase/purchase_entry/ui/payment/purchase_payment_action.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/bloc/purchase_order_bloc.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/bloc/purchase_order_event.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/bloc/purchase_order_state.dart';

class PurchasePaymentAction extends StatefulWidget {
  final PurchaseOrderState purchaseState;
  final GlobalKey<FormState> formKey;
  final bool isCreditSelected;
  final bool hasPaymentInstrument;

  const PurchasePaymentAction({
    super.key,
    required this.purchaseState,
    required this.formKey,
    required this.isCreditSelected,
    required this.hasPaymentInstrument,
  });

  @override
  State<PurchasePaymentAction> createState() => _PurchasePaymentActionState();
}

class _PurchasePaymentActionState extends State<PurchasePaymentAction> {
  bool _isProcessing = false;

  void _completePurchaseOrder() async {
    // Validate form
    if (!widget.formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix validation errors'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate payment instrument for non-credit payments
    if (!widget.isCreditSelected && !widget.hasPaymentInstrument) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select payment instrument'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Save the complete purchase order
      final purchaseBloc = context.read<PurchaseOrderBloc>();

      // First, update header with final amounts
      await _updateHeaderWithFinalAmounts();

      // Save the purchase order (this includes auto-receipt if enabled)
      purchaseBloc.add(SavePurchaseOrder());

      // Show success message (listener in main screen will handle navigation)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Purchase order saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving purchase order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _updateHeaderWithFinalAmounts() async {
    final purchaseBloc = context.read<PurchaseOrderBloc>();
    final state = purchaseBloc.state;
    final header = state.selectedHeader;

    if (header != null) {
      // Ensure all calculations are up to date
      purchaseBloc.add(CalculatePurchaseOrderTotals());
      purchaseBloc.add(CalculateTaxesAndFees());

      // Get updated state
      final updatedState = purchaseBloc.state;

      final updatedHeader = header.copyWith(
        amountGrandTotalCost: updatedState.amountGrandTotalCost,
        amountGross: updatedState.amountGross,
        amountDiscount: updatedState.amountDiscount,
        amountOtherCosts: updatedState.amountOtherCosts,
        taxAmount: updatedState.taxAmount,
        amountWithhold: updatedState.amountWithhold,
        amountOpenCredit: widget.isCreditSelected
            ? updatedState.amountGrandTotalCost
            : null,
        paymentStatus: widget.isCreditSelected
            ? await _getUdcDetailId('PS', 'N')
            : // Not Paid for credit
              await _getUdcDetailId('PS', 'P'), // Paid for cash
      );

      purchaseBloc.add(UpdatePurchaseOrderHeader(header: updatedHeader));
    }
  }

  Future<int?> _getUdcDetailId(String udcGroup, String detailCode) async {
    // This should be implemented in your UDC repository
    // For now, return null
    return null;
  }

  void _navigateBack() {
    // Check if there are unsaved changes
    if (widget.purchaseState.createDetails.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unsaved Changes'),
          content: const Text(
            'You have unsaved changes. Do you want to save as draft before leaving?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.pop();
              },
              child: const Text('Discard'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final canComplete =
        widget.purchaseState.createDetails.isNotEmpty &&
        (!widget.isCreditSelected ||
            (widget.isCreditSelected && widget.hasPaymentInstrument));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Back Button
        ElevatedButton(
          onPressed: _isProcessing ? null : _navigateBack,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade300,
            foregroundColor: Colors.grey.shade700,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Row(
            children: [
              Icon(Icons.arrow_back),
              SizedBox(width: 8),
              Text('Back', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        // Complete Order Button
        ElevatedButton(
          onPressed: _isProcessing || !canComplete
              ? null
              : _completePurchaseOrder,
          style: ElevatedButton.styleFrom(
            backgroundColor: canComplete
                ? const Color(0xFF155888)
                : Colors.grey.shade400,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isProcessing
              ? const Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text('Processing...'),
                  ],
                )
              : const Row(
                  children: [
                    Icon(Icons.check_circle),
                    SizedBox(width: 8),
                    Text(
                      'Complete Purchase',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
