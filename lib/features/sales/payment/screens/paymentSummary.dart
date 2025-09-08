import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:savvy_stock/core/widgets/custom_text_form.dart';
import 'package:savvy_stock/features/sales/payment/blocs/payment_bloc.dart';
import 'package:savvy_stock/features/sales/payment/blocs/payment_event.dart';
import 'package:savvy_stock/features/sales/payment/blocs/payment_state.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/models/confirmed_item.dart';

class PaymentScreen extends StatelessWidget {
  final List<ConfirmedItem> confirmedItems;
  final double totalAmount;

  const PaymentScreen({
    super.key,
    required this.confirmedItems,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PaymentBloc()
        ..add(
          LoadPayment(confirmedItems: confirmedItems, totalAmount: totalAmount),
        ),
      child: const PaymentScreenContent(),
    );
  }
}

class PaymentScreenContent extends StatelessWidget {
  const PaymentScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: const Color(0xFF155888),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: BlocConsumer<PaymentBloc, PaymentState>(
          listener: (context, state) {
            if (state.status == PaymentStatus.failure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage ?? 'Payment failed'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            return _buildContent(context, state);
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, PaymentState state) {
    if (state.status == PaymentStatus.initial) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Order Summary Section
        Expanded(
          flex: 1,
          child: Container(
            color: Colors.white,
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: context
                        .read<PaymentBloc>()
                        .state
                        .confirmedItems
                        .length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: _buildOrderSummary(context, state),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildPaymentDetails(context, state),
        _buildPaymentAction(context, state),
      ],
    );
  }

  Widget _buildOrderSummary(BuildContext context, PaymentState state) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[200],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextField(
              labelText: 'Subtotal',
              value: state.subtotal.toString(),
              readOnly: true,
            ),
            _buildTaxFeeField(
              context,
              'Discount Amount',
              state.discountAmount,
              (value) => _updateTaxAndFees(
                context,
                discountAmount: double.tryParse(value) ?? 0,
              ),
            ),
            const SizedBox(height: 12),
            _buildTaxFeeField(
              context,
              'Withhold Amount',
              state.withholdingAmount,
              (value) => _updateTaxAndFees(
                context,
                withholdingAmount: double.tryParse(value) ?? 0,
              ),
            ),
            const SizedBox(height: 12),
            CustomTextField(
              labelText: 'Tax (10%)',
              value: state.taxAmount.toString(),
              readOnly: true,
            ),
            const Divider(),
            _buildSummaryRow(state.grandTotal, isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetails(BuildContext context, PaymentState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1E3A5C),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            color: Colors.black26,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Method',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          _buildPaymentTypeSelector(context, state),
          const SizedBox(height: 12),
          CustomTextField(
            labelText: 'Payment Term',
            onChanged: (value) => _updatePaymentDetails(context),
          ),
          const SizedBox(height: 12),
          _buildPaymentInstrumentDropdown(context, state),
        ],
      ),
    );
  }

  Widget _buildPaymentTypeSelector(BuildContext context, PaymentState state) {
    const paymentTypes = ['Cash', 'Credit', 'Advance'];

    return Row(
      children: paymentTypes.map((type) {
        final isSelected = state.paymentType == type;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: FilterChip(
              label: Text(type),
              selected: isSelected,
              onSelected: (_) => _selectPaymentType(context, type),
              backgroundColor: isSelected ? null : Colors.grey[200],
              selectedColor: const Color(0xFF155888),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPaymentInstrumentDropdown(
    BuildContext context,
    PaymentState state,
  ) {
    const instruments = ['Cash', 'Check', 'Credit Card', 'Bank Transfer'];

    return DropdownButtonFormField<String>(
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a payment instrument';
        }
        return null;
      },
      borderRadius: BorderRadius.circular(20),
      menuMaxHeight: 200,
      decoration: InputDecoration(
        labelText: 'Payment Instrument',
        labelStyle: const TextStyle(color: Colors.white),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF1E3A5C)),
        ),
        focusedBorder: UnderlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          borderSide: BorderSide(color: Color(0xFF1E3A5C)),
        ),
        filled: true,
        fillColor: Color(0xFF1E3A5C).withValues(alpha: 0.1),
      ),
      style: const TextStyle(color: Colors.white),
      dropdownColor: const Color(0xFF1E3A5C),
      initialValue: state.paymentInstrument.isNotEmpty
          ? state.paymentInstrument
          : null,
      items: instruments.map((String value) {
        return DropdownMenuItem<String>(value: value, child: Text(value));
      }).toList(),
      onChanged: (String? newValue) {
        if (newValue != null) {
          _updatePaymentDetails(context);
        }
      },
    );
  }

  Widget _buildTaxFeeField(
    BuildContext context,
    String label,
    double value,
    Function(String) onChanged,
  ) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
      ),
      keyboardType: TextInputType.number,
      initialValue: value > 0 ? value.toStringAsFixed(2) : '',
      onChanged: onChanged,
    );
  }

  Widget _buildPaymentAction(BuildContext context, PaymentState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: state.status == PaymentStatus.processing
                  ? null
                  : () => _processPayment(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF155888),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: state.status == PaymentStatus.processing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'PROCESS PAYMENT',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(double value, {bool isTotal = false}) {
    final format = NumberFormat('#,##0.00');
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomTextField(
          readOnly: true,
          value: format.format(value),
          labelText: 'Total',
        ),
      ],
    );
  }

  void _selectPaymentType(BuildContext context, String paymentType) {
    final state = context.read<PaymentBloc>().state;
    context.read<PaymentBloc>().add(
      UpdatePaymentDetails(
        paymentType: paymentType,
        paymentMethod: state.paymentMethod,
        paymentInstrument: state.paymentInstrument,
        paymentTerm: state.paymentTerm,
      ),
    );
  }

  void _updatePaymentDetails(BuildContext context) {
    // In a real app, you'd get these values from form controllers
    context.read<PaymentBloc>().add(
      const UpdatePaymentDetails(
        paymentType: 'Cash',
        paymentMethod: '',
        paymentInstrument: 'Cash',
        paymentTerm: '',
      ),
    );
  }

  void _updateTaxAndFees(
    BuildContext context, {
    double discountAmount = 0,
    double withholdingAmount = 0,
  }) {
    final state = context.read<PaymentBloc>().state;
    context.read<PaymentBloc>().add(
      UpdateTaxAndFees(
        taxAmount: state.taxAmount,
        discountAmount: discountAmount,
        withholdingAmount: withholdingAmount,
      ),
    );
  }

  void _processPayment(BuildContext context) {
    context.read<PaymentBloc>().add(const ProcessPayment());
  }
}
