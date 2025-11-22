import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:savvy_stock/core/constants/app_routes.dart';
import 'package:savvy_stock/features/sales/customer/models/customer_model.dart';
import 'package:savvy_stock/features/sales/sales_order/invoice/widget/invoice_action.dart';
import 'package:savvy_stock/features/sales/sales_order/invoice/widget/invoice_first_part.dart';
import 'package:savvy_stock/features/sales/sales_order/invoice/widget/invoice_second_part.dart';
import 'package:savvy_stock/features/sales/sales_order/invoice/widget/invoice_third_part.dart';
import 'package:savvy_stock/features/sales/sales_order/integration/bloc/sales_order_coordinator_bloc.dart';
import 'package:savvy_stock/features/sales/sales_order/integration/bloc/sales_order_coordinator_state.dart';

class InvoiceReviewScreen extends StatelessWidget {
  const InvoiceReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get data from global blocs
    return BlocConsumer<SalesOrderCoordinatorBloc, SalesOrderCoordinatorState>(
      listener: (context, state) {
        // Validate that we have all necessary data
        if (state.currentHeader == null) {
          _buildErrorScreen(
            title: 'No Order Data',
            message:
                'Sales order header is not available. Please complete the order process.',
            icon: Icons.error_outline,
          );
        }

        final hasAnyDetails =
            state.currentDetails.isNotEmpty ||
            state.lastSavedDetails.isNotEmpty;

        if (!hasAnyDetails) {
          _buildErrorScreen(
            title: 'No Items in Order',
            message:
                'There are no items in the order. Please add items before generating invoice.',
            icon: Icons.shopping_cart_outlined,
          );
        }

        if (state.lastTotalAmount == null || state.lastTotalAmount! <= 0) {
          _buildErrorScreen(
            title: 'Calculation Required',
            message:
                'Order totals need to be calculated. Please wait or go back to recalculate.',
            icon: Icons.calculate_outlined,
          );
        }
      },
      builder: (context, state) {
        return _InvoiceReviewContent(state: state);
      },
    );
  }
}

Widget _buildErrorScreen({
  required String title,
  required String message,
  required IconData icon,
  BuildContext? context,
}) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Invoice Review'),
      backgroundColor: const Color(0xFF155888),
    ),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 72, color: Colors.grey),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context!.push(AppRoutes.salesDashboard),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF155888),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _InvoiceReviewContent extends StatelessWidget {
  final SalesOrderCoordinatorState state;

  const _InvoiceReviewContent({required this.state});

  @override
  Widget build(BuildContext context) {
    // Safely extract header
    final header = state.currentHeader;

    // Prefer live currentDetails; fall back to lastSavedDetails after order
    // creation so that the invoice review has items even if currentDetails
    // was cleared by detail bloc refreshes.
    final effectiveDetails = state.currentDetails.isNotEmpty
        ? state.currentDetails
        : state.lastSavedDetails;

    if (header == null) {
      return _buildErrorScreen(
        title: 'No Order Data',
        message:
            'Sales order header is not available. Please complete the order process.',
        icon: Icons.error_outline,
        context: context,
      );
    }

    if (effectiveDetails.isEmpty) {
      return _buildErrorScreen(
        title: 'No Items in Order',
        message:
            'There are no items in the order. Please add items before generating invoice.',
        icon: Icons.shopping_cart_outlined,
        context: context,
      );
    }

    if (state.lastTotalAmount == null || state.lastTotalAmount! <= 0) {
      return _buildErrorScreen(
        title: 'Calculation Required',
        message:
            'Order totals need to be calculated. Please go back and recalculate before reviewing the invoice.',
        icon: Icons.calculate_outlined,
        context: context,
      );
    }

    // Prefer joined customer ref when available, otherwise use defaultCustomer from coordinator state
    final Customer? customer =
        header.customerBillToRef ?? state.defaultCustomer;

    if (customer == null) {
      return _buildErrorScreen(
        title: 'Customer Not Available',
        message:
            'Customer information is missing for this order. Please select a customer and try again.',
        icon: Icons.person_outline,
        context: context,
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Invoice Preview'),
        backgroundColor: const Color(0xFF155888),
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => _printInvoice(context),
            tooltip: 'Print Invoice',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareInvoice(context),
            tooltip: 'Share Invoice',
          ),
          PopupMenuButton<String>(
            onSelected: (action) => _handleMenuAction(context, action),
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'save_pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, size: 20),
                    SizedBox(width: 8),
                    Text('Save as PDF'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'excel',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, size: 20),
                    SizedBox(width: 8),
                    Text('Save as Excel'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'email',
                child: Row(
                  children: [
                    Icon(Icons.email, size: 20),
                    SizedBox(width: 8),
                    Text('Email Invoice'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'duplicate',
                child: Row(
                  children: [
                    Icon(Icons.content_copy, size: 20),
                    SizedBox(width: 8),
                    Text('Duplicate Order'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header with order info
            _buildOrderHeader(context),

            // Invoice content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Customer Information
                    InvoiceFirstPart(
                      customer: customer,
                      date: header.orderDate ?? DateTime.now(),
                      invoiceNumber: state.invoiceFsNumber ?? 'Pending',
                      salesOrderNumber: header.fsNumber ?? 'N/A',
                    ),
                    const SizedBox(height: 16),

                    // Order Items
                    InvoiceSecondPart(
                      items: effectiveDetails,
                      subtotal: state.lastSubTotal ?? 0.0,
                    ),
                    const SizedBox(height: 16),

                    // Payment Information
                    InvoiceThirdPart(
                      subtotal: state.lastSubTotal ?? 0.0,
                      discountAmount: state.lastDiscountAmount ?? 0.0,
                      taxAmount: state.lastTax ?? 0.0,
                      withholdingAmount: state.lastWithholdAmount ?? 0.0,
                      totalAmount: state.lastTotalAmount ?? 0.0,
                      paymentType: state.paymentType,
                      paymentInstrument: state.paymentInstrument,
                    ),
                  ],
                ),
              ),
            ),

            // Action buttons
            const InvoiceAction(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF155888).withOpacity(0.1),
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long, color: Color(0xFF155888)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sales Order: ${state.currentHeader!.fsNumber ?? 'N/A'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (state.invoiceFsNumber != null)
                  Text(
                    'Invoice: ${state.invoiceFsNumber}',
                    style: const TextStyle(fontSize: 12, color: Colors.green),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: state.isOrderComplete ? Colors.green : Colors.orange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              state.isOrderComplete ? 'COMPLETED' : 'PENDING',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _printInvoice(BuildContext context) {
    // Implement print functionality
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Printing invoice...')));
  }

  void _shareInvoice(BuildContext context) {
    // Implement share functionality
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Sharing invoice...')));
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'save_pdf':
        _saveAsPdf(context);
        break;
      case 'email':
        _emailInvoice(context);
        break;
      case 'duplicate':
        _duplicateOrder(context);
        break;
    }
  }

  void _saveAsPdf(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Saving as PDF...')));
  }

  void _emailInvoice(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Preparing email...')));
  }

  void _duplicateOrder(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Duplicating order...')));
  }
}
