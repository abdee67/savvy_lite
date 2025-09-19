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

class PaymentScreen extends StatefulWidget {
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
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bloc = context.read<PaymentBloc>();
      bloc.add(
        LoadPayment(
          confirmedItems: widget.confirmedItems,
          totalAmount: widget.totalAmount,
          customer: widget.customer,
        ),
      );
      bloc.add(const LoadFeeSystemConstants());
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: const Color(0xFF155888),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: BlocBuilder<PaymentBloc, PaymentState>(
          builder: (context, state) {
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
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: const [PaymentDetails()],
              ),
            );
          },
        ),
      ),

      /// ✅ This bottomNavigationBar will now respond to the keyboard
      bottomNavigationBar: AnimatedPadding(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(height: 1, thickness: 1),
            const PaymentMethod(),
            Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: const PaymentAction(),
            ),
          ],
        ),
      ),
    );
  }
}
