import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:savvy_stock/features/sales/quotation_order/bloc/quotation_order_bloc.dart';
import 'package:savvy_stock/features/sales/quotation_order/bloc/quotation_order_event.dart';
import 'package:savvy_stock/features/sales/quotation_order/bloc/quotation_order_state.dart';
import 'package:savvy_stock/features/sales/quotation_order/model/quotation_order_detail.dart';
import 'package:savvy_stock/features/sales/quotation_order/model/quotation_order_header.dart';
import 'package:savvy_stock/features/sales/quotation_order/screens/quote_payment_screen/quote_payment_action.dart';
import 'package:savvy_stock/features/sales/quotation_order/screens/quote_payment_screen/quote_payment_details.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_bloc.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_event.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/sales/customer/models/customer_model.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_bloc.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_event.dart';

class QuotePaymentScreen extends StatefulWidget {
  final AuthBloc authBloc;
  final Map<String, dynamic>? orderData;

  const QuotePaymentScreen({
    super.key,
    required this.authBloc,
    required this.orderData,
  });

  @override
  State<QuotePaymentScreen> createState() => _QuotePaymentScreenState();
}

class _QuotePaymentScreenState extends State<QuotePaymentScreen> {
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
    final coordinatorBloc = context.read<QuotationOrderBloc>();
    final customer = widget.orderData?['customer'] as Customer?;
    final orderDetails =
        widget.orderData?['orderDetails'] as List<QuotationOrderDetail>?;
    final orderHeader =
        widget.orderData?['orderHeader'] as QuotationOrderHeader;
    final totalAmount = widget.orderData?['totalAmount'] as double?;

    if (customer != null) {
      coordinatorBloc.add(UpdateCustomerInfo(customer: customer));
    }

    // Initialize payment calculations
    coordinatorBloc.add(
      CalculateQuotationTotals(
        header: orderHeader,
        details: orderDetails!,
        applyWithholding: orderHeader.withHoldApply!,
        discountAmount: orderHeader.discountAmount!,
      ),
    );
    coordinatorBloc.add(LoadFeeSystemConstants());
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
        title: const Text('Payment Summary'),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh),
            onPressed: () {
              final quoteState = context.read<QuotationOrderBloc>().state;
              context.read<QuotationOrderBloc>().add(
                CalculateQuotationTotals(
                  header: quoteState.selectedHeader!,
                  details: quoteState.createDetailItems,
                  applyWithholding: quoteState.canApplyWithholding!,
                  discountAmount: quoteState.discountAmount!,
                ),
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
        child: BlocListener<QuotationOrderBloc, QuotationOrderState>(
          listener: (context, state) {
            if (state.status == QuotationOrderStatus.error) {
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
                            child: QuotePaymentDetails(
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
              const QuotePaymentAction(),
            ],
          ),
        ),
      ),
    );
  }
}
