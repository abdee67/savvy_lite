// features/sales/invoice/widgets/invoice_action.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:savvy_stock/core/constants/app_routes.dart';
import 'package:savvy_stock/features/sales/sales_order/invoice/widget/dialogs/error_and_retry_dialog.dart';
import 'package:savvy_stock/features/sales/sales_order/invoice/widget/dialogs/order_confirmation_dialog.dart';
import 'package:savvy_stock/features/sales/sales_order/invoice/widget/dialogs/order_processing_dialog.dart';
import 'package:savvy_stock/features/sales/sales_order/invoice/widget/dialogs/order_success_dialog.dart';
import 'package:savvy_stock/features/sales/quotation_order/bloc/quotation_order_bloc.dart';
import 'package:savvy_stock/features/sales/quotation_order/bloc/quotation_order_event.dart';
import 'package:savvy_stock/features/sales/quotation_order/bloc/quotation_order_state.dart';

// features/sales/invoice/widgets/invoice_action.dart
import 'package:go_router/go_router.dart';

class QuoteInvoiceAction extends StatefulWidget {
  const QuoteInvoiceAction({super.key});

  @override
  State<QuoteInvoiceAction> createState() => _QuoteInvoiceActionState();
}

class _QuoteInvoiceActionState extends State<QuoteInvoiceAction> {
  //final _logger = AppLogger('InvoiceAction');
  StreamSubscription<QuotationOrderState>? _orderSubscription;

  @override
  void dispose() {
    _orderSubscription?.cancel(); // 🎯 Critical: Prevent memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<QuotationOrderBloc, QuotationOrderState>(
      listener: _handleStateChanges, // 🎯 Better than manual stream listening
      builder: (context, state) {
        final isProcessing =
            state.status == QuotationOrderStatus.processing ||
            state.status == QuotationOrderStatus.paymentProcessing;

        return _buildActionBar(context, isProcessing, state);
      },
    );
  }

  void _handleStateChanges(BuildContext context, QuotationOrderState state) {
    // 🎯 Centralized state handling prevents race conditions
    if (state.isOrderComplete && state.invoiceGenerated) {
      _showSuccessDialog(context, state);
    } else if (state.status == QuotationOrderStatus.error &&
        state.error != null) {
      _showErrorDialog(context, state.error ?? 'Unknown error occurred');
    }
  }

  Widget _buildActionBar(
    BuildContext context,
    bool isProcessing,
    QuotationOrderState state,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _buildContainerDecoration(),
      child: Row(
        children: [
          _buildBackButton(context, isProcessing),
          const SizedBox(width: 12),
          _buildFinishButton(context, isProcessing, state),
        ],
      ),
    );
  }

  Widget _buildBackButton(BuildContext context, bool isProcessing) {
    return Expanded(
      child: OutlinedButton(
        onPressed: isProcessing ? null : () => _handleBack(context),
        style: _outlinedButtonStyle,
        child: const Text('Back', style: TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _buildFinishButton(
    BuildContext context,
    bool isProcessing,
    QuotationOrderState state,
  ) {
    return Expanded(
      child: ElevatedButton(
        onPressed: isProcessing ? null : () => _finalizeOrder(context, state),
        style: _elevatedButtonStyle,
        child: isProcessing
            ? _buildLoadingIndicator()
            : const Text(
                'Finish Order',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  void _handleBack(BuildContext context) {
    Navigator.of(context).pop();
  }

  void _finalizeOrder(BuildContext context, QuotationOrderState state) {
    if (!_validateOrder(state)) {
      return;
    }

    _showConfirmationDialog(context, state);
  }

  bool _validateOrder(QuotationOrderState state) {
    return state.selectedHeader != null &&
        state.createDetailItems.isNotEmpty &&
        state.createDetailItems.every((detail) => detail.isValid);
  }

  void _showConfirmationDialog(
    BuildContext context,
    QuotationOrderState state,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false, // 🎯 Prevent accidental dismissal
      builder: (context) => OrderConfirmationDialog(
        orderNumber: state.selectedHeader?.fsNumber,
        totalAmount: state.totalAmount,
        onConfirm: () => _processFinalization(context),
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }

  void _processFinalization(BuildContext context) {
    final coordinatorBloc = context.read<QuotationOrderBloc>();
    final state = coordinatorBloc.state;

    if (!_validateOrder(state)) {
      return;
    }

    // Close confirmation dialog
    Navigator.of(context).pop();

    // 🎯 Dispatch the event - this is what was missing!
    coordinatorBloc.add(
      SaveQuotationOrder(
        header: state.selectedHeader!,
        details: state.createDetailItems,
      ),
    );

    // Show processing dialog that will auto-close based on state changes
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BlocConsumer<QuotationOrderBloc, QuotationOrderState>(
        listener: (context, state) {
          // ✅ Only close dialog and show result when order is complete OR there's an error
          if (state.isOrderComplete && state.invoiceGenerated) {
            Navigator.of(context).pop(); // Close processing dialog
            _showSuccessDialog(context, state);
          } else if (state.status == QuotationOrderStatus.error &&
              state.error != null) {
            Navigator.of(context).pop(); // Close processing dialog
            _showErrorDialog(context, state.error!);
          }
          // ✅ Don't do anything for intermediate states (processing, etc.)
        },

        builder: (context, state) {
          return OrderProcessingDialog();
        },
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, QuotationOrderState state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => OrderSuccessDialog(
        orderNumber: state.selectedHeader?.fsNumber,
        invoiceNumber: state.invoiceFsNumber,
        totalAmount: state.totalAmount,
        onDone: () => _navigateToHome(context),
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (context) => ErrorDialog(
        error: error,
        onRetry: () => _processFinalization(context),
        onCancel: () => _navigateToHome(context),
      ),
    );
  }

  void _showRetryDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (context) => RetryDialog(
        error: error,
        onRetry: () => _processFinalization(context),
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }

  void _navigateToHome(BuildContext context) {
    // 🎯 Use GoRouter for proper navigation stack management
    context.go(AppRoutes.homePage);

    // 🎯 Clear state after successful navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuotationOrderBloc>().add(ClearQuotationOrderDetails());
      context.read<QuotationOrderBloc>().add(ResetQuotationState());
    });
  }
}

// 🎯 Extract reusable styles and constants
final _elevatedButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: const Color(0xFF155888),
  foregroundColor: Colors.white,
  padding: const EdgeInsets.symmetric(vertical: 16),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
);

final _outlinedButtonStyle = OutlinedButton.styleFrom(
  padding: const EdgeInsets.symmetric(vertical: 16),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
);

BoxDecoration _buildContainerDecoration() {
  return BoxDecoration(
    color: Colors.white,
    border: Border(top: BorderSide(color: Colors.grey.shade300)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 4,
        offset: const Offset(0, -2),
      ),
    ],
  );
}

Widget _buildLoadingIndicator() {
  return const SizedBox(
    width: 20,
    height: 20,
    child: CircularProgressIndicator(
      strokeWidth: 2,
      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
    ),
  );
}
