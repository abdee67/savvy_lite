// features/purchase/purchase_entry/ui/payment/purchase_payment_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:savvy_stock/core/constants/app_routes.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/bloc/purchase_order_bloc.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/bloc/purchase_order_event.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/bloc/purchase_order_state.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/screens/purchase_payment/widget/payment_details.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/screens/purchase_payment/widget/payment_method.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_bloc.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_event.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_bloc.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_event.dart';

class PurchasePaymentScreen extends StatefulWidget {
  final Map<String, dynamic> orderData;

  const PurchasePaymentScreen({super.key, required this.orderData});

  @override
  State<PurchasePaymentScreen> createState() => _PurchasePaymentScreenState();
}

class _PurchasePaymentScreenState extends State<PurchasePaymentScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePaymentData();
    });
  }

  void _initializePaymentData() {
    final authState = context.read<AuthBloc>().state;
    final companyId = authState.companyId;

    if (companyId != null) {
      // Load system constants
      context.read<SystemConstantBloc>().add(LoadSystemConstants(companyId));

      // Load UDC details for payment types and instruments
      context.read<UdcDetailsBloc>().add(LoadAllUdcDetails());

      // Initialize payment calculations in purchase order bloc
      final purchaseBloc = context.read<PurchaseOrderBloc>();

      // Calculate initial totals if not already calculated
      if (purchaseBloc.state.totalAmount == null) {
        purchaseBloc.add(CalculatePurchaseOrderTotals());
      }

      // Calculate taxes and fees
      purchaseBloc.add(CalculateTaxesAndFees());
    }
  }

  void _refreshCalculations() {
    context.read<PurchaseOrderBloc>().add(CalculatePurchaseOrderTotals());
    context.read<PurchaseOrderBloc>().add(CalculateTaxesAndFees());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PurchaseOrderBloc, PurchaseOrderState>(
      listener: (context, state) {
        // Handle errors
        if (state.status == PurchaseOrderStatus.error && state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        // Handle successful save
        if (state.status == PurchaseOrderStatus.success &&
            state.successMessage != null &&
            state.successMessage!.contains('saved')) {
          final purchaseBloc = context.read<PurchaseOrderBloc>();

          // Clear create/edit state so the next entry starts fresh
          purchaseBloc.add(const CancelPurchaseOrderCreate());
          purchaseBloc.add(const ClearPurchaseOrderSelection());

          // Navigate back to purchase order home (review) screen
          if (mounted) {
            context.go(AppRoutes.homePage);
          }
        }
      },
      builder: (context, purchaseState) {
        // Check if we have items to process
        /*  if (purchaseState.createDetails.isEmpty) {
          return _buildEmptyOrderState();
        }*/

        return Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            title: const Text('Purchase Order Payment'),
            backgroundColor: const Color(0xFF155888),
            foregroundColor: Colors.white,
            elevation: 2,
            actions: [
              // Refresh calculations button
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _refreshCalculations,
                tooltip: 'Refresh calculations',
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Upper Section - Payment Details (Financial Summary)
                Expanded(
                  flex: 2,
                  child: Container(
                    color: Colors.white,
                    child: SingleChildScrollView(
                      child: PurchasePaymentDetails(
                        purchaseState: purchaseState,
                        onDiscountChanged: (discount) {
                          context.read<PurchaseOrderBloc>().add(
                            UpdatePurchaseOrderAmounts(),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // Lower Section - Payment Method & Action
                PurchasePaymentMethod(
                  purchaseState: purchaseState,
                  orderData: widget.orderData,
                ),
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
            'No Items in Purchase Order',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add items to the purchase order before proceeding to payment',
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
