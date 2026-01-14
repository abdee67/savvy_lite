import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:savvy_stock/features/sales/sales_order/integration/bloc/sales_order_coordinator_bloc.dart';
import 'package:savvy_stock/features/sales/sales_order/integration/bloc/sales_order_coordinator_event.dart';
import 'package:savvy_stock/features/sales/sales_order/integration/bloc/sales_order_coordinator_state.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_bloc.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_event.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/sales/customer/models/customer_model.dart';
import 'package:savvy_stock/features/sales/sales_order/payment/widget/payment_details.dart';
import 'package:savvy_stock/features/sales/sales_order/payment/widget/payment_method.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_bloc.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_event.dart';

class PaymentScreen extends StatefulWidget {
  final AuthBloc authBloc;
  final Map<String, dynamic>? orderData;

  const PaymentScreen({
    super.key,
    required this.authBloc,
    required this.orderData,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePaymentData();
    });
  }

  void _initializePaymentData() {
    if (!mounted) return;

    context.read<SystemConstantBloc>().add(
      LoadSystemConstants(widget.authBloc.state.companyId!),
    );

    // Load payment terms
    context.read<UdcDetailsBloc>().add(LoadAllUdcDetails());

    // Initialize payment data in coordinator
    final coordinatorBloc = context.read<SalesOrderCoordinatorBloc>();
    final customer = widget.orderData?['customer'] as Customer?;
    final orderDetails = widget.orderData?['orderDetails'] as List<dynamic>?;
    final orderHeader = widget.orderData?['orderHeader'] as dynamic;
    final totalAmount = widget.orderData?['totalAmount'] as double?;

    if (customer != null) {
      coordinatorBloc.add(SyncCustomerToOrder(customer: customer));
    }

    // Initialize payment calculations
    if (kDebugMode) {
      developer.log('DEBUG: PaymentScreen initializing data');
    }
    if (kDebugMode) {
      developer.log(
        'DEBUG: Coordinator state has header: ${coordinatorBloc.state.currentHeader != null}',
      );
    }
    if (kDebugMode) {
      developer.log(
        'DEBUG: Coordinator state has details: ${coordinatorBloc.state.currentDetails.length}',
      );
    }

    coordinatorBloc.add(const CalculateCompleteOrderTotals());
    coordinatorBloc.add(const LoadFeeSystemConstants());
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SalesOrderCoordinatorBloc, SalesOrderCoordinatorState>(
      listener: (context, state) {
        if (state.status == SalesOrderCoordinatorStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state.currentDetails.isEmpty) {
          return _buildEmptyOrderState();
        }

        return Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            title: const Text('Payment Summary'),
            actions: [
              IconButton(
                icon: const Icon(Iconsax.refresh),
                onPressed: () {
                  context.read<SalesOrderCoordinatorBloc>().add(
                    const CalculateCompleteOrderTotals(),
                  );
                },
                tooltip: 'Refresh calculations',
              ),
            ],
            backgroundColor: const Color(0xFF155888),
            foregroundColor: Colors.white,
            elevation: 2,
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Upper Section - Order Items
                Expanded(
                  flex: 1,
                  child: Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: PaymentDetails(authBloc: widget.authBloc),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Lower Section - Order Summary
                PaymentMethod(salesState: state, orderData: widget.orderData),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyOrderState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'No Items in Sales Order',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add items to the sales order before proceeding to payment',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context.pop();
            },
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to Items'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF155888),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
