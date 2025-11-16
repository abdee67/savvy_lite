import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:savvy_stock/features/sales/sales_order/integration/bloc/sales_order_coordinator_bloc.dart';
import 'package:savvy_stock/features/sales/sales_order/integration/bloc/sales_order_coordinator_event.dart';
import 'package:savvy_stock/features/sales/sales_order/integration/bloc/sales_order_coordinator_state.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_bloc.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_event.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/sales/customer/models/customer_model.dart';
import 'package:savvy_stock/features/sales/payment/widget/payment_details.dart';
import 'package:savvy_stock/features/sales/payment/widget/payment_method.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/models/confirmed_item.dart';
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
    context.read<UdcDetailsBloc>().add(LoadUdcDetailsByGroup('LT'));

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
    coordinatorBloc.add(const CalculateCompleteOrderTotals());
    coordinatorBloc.add(const LoadFeeSystemConstants());
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Payment'),
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
        child:
            BlocListener<SalesOrderCoordinatorBloc, SalesOrderCoordinatorState>(
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
                                child: PaymentDetails(
                                  authBloc: widget.authBloc,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Lower Section - Order Summary
                  const PaymentMethod(),
                ],
              ),
            ),
      ),
    );
  }
}
