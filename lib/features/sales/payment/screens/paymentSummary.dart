import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:savvy_stock/features/sales/customer/models/customer_model.dart';
import 'package:savvy_stock/features/sales/payment/blocs/payment_bloc.dart';
import 'package:savvy_stock/features/sales/payment/blocs/payment_event.dart';
import 'package:savvy_stock/features/sales/payment/blocs/payment_state.dart';
import 'package:savvy_stock/features/sales/payment/widget/payment_action.dart';
import 'package:savvy_stock/features/sales/payment/widget/payment_details.dart';
import 'package:savvy_stock/features/sales/payment/widget/payment_method.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/models/confirmed_item.dart';

class PaymentScreen extends StatelessWidget {
  final List<ConfirmedItem> confirmedItems;
  final double totalAmount;
  final Customer customer;

  const PaymentScreen({
    super.key,
    required this.confirmedItems,
    required this.totalAmount,
    required this.customer,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PaymentBloc()
        ..add(
          LoadPayment(
            confirmedItems: confirmedItems,
            totalAmount: totalAmount,
            customer: customer,
          ),
        ),
      child: PaymentScreenContent(
        confirmedItems: confirmedItems,
        totalAmount: totalAmount,
      ),
    );
  }
}

class PaymentScreenContent extends StatefulWidget {
  final List<ConfirmedItem> confirmedItems;
  final double totalAmount;

  const PaymentScreenContent({
    super.key,
    required this.confirmedItems,
    required this.totalAmount,
  });

  @override
  State<PaymentScreenContent> createState() => _PaymentScreenContentState();
}

class _PaymentScreenContentState extends State<PaymentScreenContent> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: const Color(0xFF155888),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: SafeArea(
        child: BlocConsumer<PaymentBloc, PaymentState>(
          listener: (context, state) {
            if (state.status == PaymentStatus.failure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage ?? 'Payment failed'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } else if (state.status == PaymentStatus.success) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Payment successful!'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          builder: (context, state) {
            return Column(
              children: [
                // Upper Part - Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          color: Colors.grey[50],
                          child: const PaymentDetails(),
                        ),
                      ],
                    ),
                  ),
                ),

                // Lower Part - Fixed Height
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Divider between sections
                    const Divider(height: 1, thickness: 1),

                    // Payment Method Section
                    const PaymentMethod(),

                    // Payment Action Buttons
                    Container(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: PaymentAction(state: state),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
