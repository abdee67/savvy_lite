// features/sales/invoice/widgets/invoice_action.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:savvy_stock/core/constants/app_routes.dart';
import 'package:savvy_stock/features/sales/sales_order/invoice/widget/dialogs/error_and_retry_dialog.dart';
import 'package:savvy_stock/features/sales/sales_order/invoice/widget/dialogs/order_confirmation_dialog.dart';
import 'package:savvy_stock/features/sales/sales_order/invoice/widget/dialogs/order_processing_dialog.dart';
import 'package:savvy_stock/features/sales/sales_order/invoice/widget/dialogs/order_success_dialog.dart';
import 'package:savvy_stock/features/sales/sales_order/integration/bloc/sales_order_coordinator_bloc.dart';
import 'package:savvy_stock/features/sales/sales_order/integration/bloc/sales_order_coordinator_event.dart';
import 'package:savvy_stock/features/sales/sales_order/integration/bloc/sales_order_coordinator_state.dart';

// features/sales/invoice/widgets/invoice_action.dart
import 'package:go_router/go_router.dart';

class InvoiceAction extends StatefulWidget {
  const InvoiceAction({super.key});

  @override
  State<InvoiceAction> createState() => _InvoiceActionState();
}

class _InvoiceActionState extends State<InvoiceAction> {
  //final _logger = AppLogger('InvoiceAction');
  StreamSubscription<SalesOrderCoordinatorState>? _orderSubscription;

  @override
  void dispose() {
    _orderSubscription?.cancel(); // 🎯 Critical: Prevent memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SalesOrderCoordinatorBloc, SalesOrderCoordinatorState>(
      listener: _handleStateChanges, // 🎯 Better than manual stream listening
      builder: (context, state) {
        final isProcessing =
            state.status == SalesOrderCoordinatorStatus.processing ||
            state.status == SalesOrderCoordinatorStatus.paymentProcessing;

        return _buildActionBar(context, isProcessing, state);
      },
    );
  }

  void _handleStateChanges(
    BuildContext context,
    SalesOrderCoordinatorState state,
  ) {
    // 🎯 Centralized state handling prevents race conditions
    _showSuccessDialog(context, state);
  }

  Widget _buildActionBar(
    BuildContext context,
    bool isProcessing,
    SalesOrderCoordinatorState state,
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
    SalesOrderCoordinatorState state,
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

  void _finalizeOrder(BuildContext context, SalesOrderCoordinatorState state) {
    if (!_validateOrder(state)) {
      return;
    }

    _showConfirmationDialog(context, state);
  }

  bool _validateOrder(SalesOrderCoordinatorState state) {
    return state.currentHeader != null &&
        state.currentDetails.isNotEmpty &&
        state.currentDetails.every((detail) => detail.isValid);
  }

  void _showConfirmationDialog(
    BuildContext context,
    SalesOrderCoordinatorState state,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false, // 🎯 Prevent accidental dismissal
      builder: (context) => OrderConfirmationDialog(
        orderNumber: state.currentHeader?.fsNumber,
        totalAmount: state.lastTotalAmount,
        onConfirm: () => _processFinalization(context),
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }

  void _processFinalization(BuildContext context) {
    final coordinatorBloc = context.read<SalesOrderCoordinatorBloc>();
    final state = coordinatorBloc.state;

    if (!_validateOrder(state)) {
      return;
    }

    // Close confirmation dialog
    Navigator.of(context).pop();

    // 🎯 Dispatch the event - this is what was missing!
    coordinatorBloc.add(
      CreateCompleteSalesOrder(
        header: state.currentHeader!,
        details: state.currentDetails,
      ),
    );

    // Show processing dialog that will auto-close based on state changes
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          BlocConsumer<SalesOrderCoordinatorBloc, SalesOrderCoordinatorState>(
            listener: (context, state) {
              Navigator.of(context).pop(); // Close processing dialog
              _showSuccessDialog(context, state);
              //print(state.error!);
            },

            builder: (context, state) {
              return OrderProcessingDialog();
            },
          ),
    );
  }

  void _showSuccessDialog(
    BuildContext context,
    SalesOrderCoordinatorState state,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => OrderSuccessDialog(
        orderNumber: state.currentHeader?.fsNumber,
        invoiceNumber: state.invoiceFsNumber,
        totalAmount: state.lastTotalAmount,
        onDone: () => _navigateToHome(context),
      ),
    );
  }

  void _navigateToHome(BuildContext context) {
    // 🎯 Use GoRouter for proper navigation stack management
    context.push(AppRoutes.homePage);

    // 🎯 Clear state after successful navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SalesOrderCoordinatorBloc>().add(ClearOrderDetails());
      context.read<SalesOrderCoordinatorBloc>().add(ResetCoordinatorState());
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
