// features/purchase/purchase_entry/ui/payment/purchase_payment_details.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:savvy_stock/core/widgets/custom_text_form.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/bloc/purchase_order_bloc.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/bloc/purchase_order_event.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/bloc/purchase_order_state.dart';

class PurchasePaymentDetails extends StatefulWidget {
  final PurchaseOrderState purchaseState;
  final Function(double) onDiscountChanged;

  const PurchasePaymentDetails({
    super.key,
    required this.purchaseState,
    required this.onDiscountChanged,
  });

  @override
  State<PurchasePaymentDetails> createState() => _PurchasePaymentDetailsState();
}

class _PurchasePaymentDetailsState extends State<PurchasePaymentDetails> {
  final NumberFormat _currencyFormat = NumberFormat('#,##0.00');
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _otherCostsController = TextEditingController();
  bool _discountEnabled = false;
  bool _otherCostsEnabled = false;

  @override
  void initState() {
    super.initState();

    _discountController.addListener(_onDiscountChanged);
    _otherCostsController.addListener(_onOtherCostsChanged);

    // Initialize with existing values
    _initializeFromState();
  }

  void _initializeFromState() {
    final state = widget.purchaseState;

    // Set discount
    if (state.amountDiscount != null && state.amountDiscount! > 0) {
      _discountController.text = state.amountDiscount!.toStringAsFixed(2);
      _discountEnabled = true;
    }

    // Set other costs
    if (state.amountOtherCosts != null && state.amountOtherCosts! > 0) {
      _otherCostsController.text = state.amountOtherCosts!.toStringAsFixed(2);
      _otherCostsEnabled = true;
    }
  }

  void _onDiscountChanged() {
    if (_discountEnabled) {
      final discount = double.tryParse(_discountController.text) ?? 0;
      _updateHeaderAmounts();
    }
  }

  void _onOtherCostsChanged() {
    if (_otherCostsEnabled) {
      final otherCosts = double.tryParse(_otherCostsController.text) ?? 0;
      _updateHeaderAmounts();
    }
  }

  void _updateHeaderAmounts() {
    final header = widget.purchaseState.selectedHeader;
    if (header != null) {
      final updatedHeader = header.copyWith(
        amountDiscount: _discountEnabled
            ? double.tryParse(_discountController.text)
            : 0,
        amountOtherCosts: _otherCostsEnabled
            ? double.tryParse(_otherCostsController.text)
            : 0,
      );

      context.read<PurchaseOrderBloc>().add(
        UpdatePurchaseOrderHeader(header: updatedHeader),
      );

      // Trigger recalculation
      context.read<PurchaseOrderBloc>().add(CalculatePurchaseOrderTotals());
      context.read<PurchaseOrderBloc>().add(CalculateTaxesAndFees());
    }
  }

  void _toggleDiscount(bool enabled) {
    setState(() {
      _discountEnabled = enabled;
      if (!enabled) {
        _discountController.clear();
        _updateHeaderAmounts();
      }
    });
  }

  void _toggleOtherCosts(bool enabled) {
    setState(() {
      _otherCostsEnabled = enabled;
      if (!enabled) {
        _otherCostsController.clear();
        _updateHeaderAmounts();
      }
    });
  }

  @override
  void dispose() {
    _discountController.dispose();
    _otherCostsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.purchaseState;
    final subtotal = state.totalAmount ?? 0.0;
    final discount = state.amountDiscount ?? 0.0;
    final otherCosts = state.amountOtherCosts ?? 0.0;
    final taxAmount = state.taxAmount ?? 0.0;
    final withholding = state.amountWithhold ?? 0.0;
    final grandTotal = state.amountGrandTotalCost ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          const Text(
            'Purchase Order Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF155888),
            ),
          ),
          const SizedBox(height: 16),

          // Subtotal
          _buildSummaryRow(
            label: 'Subtotal',
            amount: subtotal,
            icon: Icons.receipt,
            color: Colors.blue,
          ),
          const SizedBox(height: 12),

          // Discount (Toggleable)
          _buildToggleableField(
            label: 'Discount',
            controller: _discountController,
            enabled: _discountEnabled,
            onToggle: _toggleDiscount,
            icon: Icons.discount,
          ),
          const SizedBox(height: 12),

          // Other Costs (Toggleable)
          _buildToggleableField(
            label: 'Other Costs',
            controller: _otherCostsController,
            enabled: _otherCostsEnabled,
            onToggle: _toggleOtherCosts,
            icon: Icons.miscellaneous_services,
            hint: 'Shipping, handling, etc.',
          ),
          const SizedBox(height: 12),

          // Gross Amount
          _buildSummaryRow(
            label: 'Gross Amount',
            amount: subtotal - discount + otherCosts,
            icon: Icons.calculate,
            color: Colors.green,
          ),
          const SizedBox(height: 12),

          // Taxes
          if (taxAmount > 0)
            Column(
              children: [
                _buildSummaryRow(
                  label:
                      'Tax (${state.systemConstants?.rateVatPercentage != null ? (state.systemConstants!.rateVatPercentage! * 100).toStringAsFixed(1) : '0.0'}%)',
                  amount: taxAmount,
                  icon: Icons.account_balance,
                  color: Colors.orange,
                ),
                const SizedBox(height: 8),
              ],
            ),

          // Withholding Tax
          if (withholding > 0)
            Column(
              children: [
                _buildSummaryRow(
                  label: 'Withholding Tax',
                  amount: withholding,
                  icon: Icons.attach_money,
                  color: Colors.red,
                  isNegative: true,
                ),
                const SizedBox(height: 8),
              ],
            ),

          const Divider(height: 24),

          // Grand Total
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF155888).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF155888), width: 2),
            ),
            child: Row(
              children: [
                Icon(Icons.payment, color: const Color(0xFF155888), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GRAND TOTAL',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF155888).withOpacity(0.8),
                        ),
                      ),
                      Text(
                        'Amount to Pay',
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(0xFF155888).withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '\$${_currencyFormat.format(grandTotal)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF155888),
                  ),
                ),
              ],
            ),
          ),

          // Open Credit (if credit payment)
          if (state.amountOpenCredit != null && state.amountOpenCredit! > 0)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.credit_card, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Credit Amount',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade700,
                            ),
                          ),
                          Text(
                            '\$${_currencyFormat.format(state.amountOpenCredit!)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required String label,
    required double amount,
    required IconData icon,
    required Color color,
    bool isNegative = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
          Text(
            isNegative
                ? '-\$${_currencyFormat.format(amount)}'
                : '\$${_currencyFormat.format(amount)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleableField({
    required String label,
    required TextEditingController controller,
    required bool enabled,
    required Function(bool) onToggle,
    required IconData icon,
    String? hint,
  }) {
    return GestureDetector(
      onTap: () => onToggle(!enabled),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled ? const Color(0xFF155888) : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: enabled ? const Color(0xFF155888) : Colors.grey,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: IgnorePointer(
                ignoring: !enabled,
                child: Opacity(
                  opacity: enabled ? 1.0 : 0.5,
                  child: CustomTextField(
                    controller: controller,
                    labelText: label,
                    hintText: hint ?? 'Enter amount',
                    enabled: enabled,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    prefixIcon: const Icon(Icons.attach_money),
                    onChanged: (value) {
                      if (enabled) {
                        _updateHeaderAmounts();
                      }
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Toggle switch
            Switch(
              value: enabled,
              onChanged: onToggle,
              activeThumbColor: const Color(0xFF155888),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }
}
