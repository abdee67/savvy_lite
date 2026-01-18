// features/sales/invoice/widgets/invoice_action.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:savvy_stock/core/constants/app_routes.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/sales/sales_order/invoice/widget/dialogs/error_and_retry_dialog.dart';
import 'package:savvy_stock/features/sales/sales_order/invoice/widget/dialogs/order_confirmation_dialog.dart';
import 'package:savvy_stock/features/sales/sales_order/invoice/widget/dialogs/order_processing_dialog.dart';
// features/sales/invoice/widgets/invoice_action.dart
import 'package:go_router/go_router.dart';
import 'package:savvy_stock/features/sales/sales_order/invoice/widget/dialogs/order_success_dialog.dart';
import 'package:savvy_stock/features/sales/sales_order/integration/bloc/sales_order_coordinator_bloc.dart';
import 'package:savvy_stock/features/sales/sales_order/integration/bloc/sales_order_coordinator_event.dart';
import 'package:savvy_stock/features/sales/sales_order/integration/bloc/sales_order_coordinator_state.dart';

class InvoiceAction extends StatefulWidget {
  final AuthBloc authBloc;
  const InvoiceAction({super.key, required this.authBloc});

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
    if (state.status == SalesOrderCoordinatorStatus.error &&
        state.error != null &&
        !state.pendingOperations.contains('create_order')) {
      _showErrorDialog(context, state.error ?? 'Unknown error occurred');
    }
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

    // 🎯 Dispatch the event
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
              // ✅ Only close dialog and show result when order is complete OR there's an error
              if (state.isOrderComplete && state.invoiceGenerated) {
                Navigator.of(context).pop(); // Close processing dialog
                _showSuccessDialog(context, state);
              } else if (state.status == SalesOrderCoordinatorStatus.error &&
                  state.error != null) {
                Navigator.of(context).pop(); // Close processing dialog
                _showErrorDialog(context, state.error!);
              }
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

  void _navigateToHome(BuildContext context) {
    // 🎯 Capture ALL references BEFORE any navigation or state changes
    final bloc = context.read<SalesOrderCoordinatorBloc>();
    final companyId = widget.authBloc.state.companyId;
    final userId = widget.authBloc.state.userId?.id;
    final branchId = widget.authBloc.state.userId?.branch;

    // 🎯 Clear state synchronously to ensure clean state for next entry
    bloc.add(ClearOrderDetails());
    bloc.add(ResetCoordinatorState());

    // 🎯 Prepare new sales order for the next entry (using captured bloc reference)
    if (companyId != null && userId != null && branchId != null) {
      bloc.add(
        PrepareNewSalesOrder(
          companyId: companyId,
          employeeId: userId,
          branchId: branchId,
        ),
      );
    }

    // 🎯 Navigate to sales customer info screen LAST
    // Using GoRouter.of(context).go() which works even from dialog context
    context.go(AppRoutes.homePage);
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
  backgroundColor: Colors.amber,
  foregroundColor: Colors.white,
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
