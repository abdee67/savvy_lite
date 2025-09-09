import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:savvy_stock/core/constants/payment_constants.dart';
import 'package:savvy_stock/core/widgets/custom_text_Form.dart';
import 'package:savvy_stock/features/sales/payment/blocs/payment_bloc.dart';
import 'package:savvy_stock/features/sales/payment/blocs/payment_event.dart';
import 'package:savvy_stock/features/sales/payment/blocs/payment_state.dart';

class PaymentDetails extends StatefulWidget {
  const PaymentDetails({super.key});

  @override
  State<PaymentDetails> createState() => _PaymentDetailsState();
}

class _PaymentDetailsState extends State<PaymentDetails> {
  final NumberFormat _currencyFormat = NumberFormat('#,##0.00');
  final TextEditingController _discountController = TextEditingController();
  bool _discountEnabled = false;
  bool _initialized = false;

  @override
  void dispose() {
    _discountController.dispose();
    super.dispose();
  }

  void _updateTaxAndFees(BuildContext context, {double discountAmount = 0}) {
    final bloc = context.read<PaymentBloc>();
    final state = bloc.state;

    bloc.add(
      UpdateTaxAndFees(
        subtotal: state.subtotal,
        discountAmount: discountAmount,
        isWithholdingEnabled: state.isWithholdingEnabled,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    final padding = isSmallScreen ? 12.0 : 16.0;

    return BlocConsumer<PaymentBloc, PaymentState>(
      listener: (context, state) {
        if (!_initialized) {
          _initialized = true;
        }
      },
      builder: (context, state) {
        final canApplyWithholding =
            state.subtotal > PaymentConstants.minSubtotalForWithholding;

        return SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionTitle('Payment Details', context),
                const SizedBox(height: 16),
                _buildReadOnlyField(
                  context,
                  'Subtotal',
                  _currencyFormat.format(state.subtotal),
                  icon: Icons.shopping_cart,
                ),
                const SizedBox(height: 12),
                _buildDiscountField(context, state, isSmallScreen),
                const SizedBox(height: 12),
                _buildWithholdingField(
                  context,
                  state,
                  canApplyWithholding,
                  isSmallScreen,
                ),
                const SizedBox(height: 12),
                _buildReadOnlyField(
                  context,
                  'Tax (${(PaymentConstants.taxRate * 100).toStringAsFixed(0)}%)',
                  _currencyFormat.format(state.taxAmount),
                  icon: Icons.receipt,
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                _buildTotalField(context, 'Total', state.grandTotal),
                if (!canApplyWithholding && state.isWithholdingEnabled)
                  _buildWarningMessage(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildDiscountField(
    BuildContext context,
    PaymentState state,
    bool isSmallScreen,
  ) {
    if (_discountController.text != state.discountAmount.toString() &&
        state.discountAmount > 0) {
      _discountController.text = state.discountAmount.toString();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Discount',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(width: isSmallScreen ? 4 : 8),
            Text(
              _discountEnabled ? 'Enabled' : 'Disabled',
              style: TextStyle(
                color: _discountEnabled
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontSize: isSmallScreen ? 12 : 14,
              ),
            ),
            SizedBox(width: isSmallScreen ? 4 : 8),
            Transform.scale(
              scale: isSmallScreen ? 0.8 : 1.0,
              child: Switch(
                value: _discountEnabled,
                onChanged: (enabled) {
                  setState(() {
                    _discountEnabled = enabled;
                    if (!enabled) {
                      _discountController.clear();
                      _updateTaxAndFees(context, discountAmount: 0);
                    }
                  });
                },
                activeColor: Theme.of(context).colorScheme.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: _discountEnabled
              ? CustomTextField(
                  controller: _discountController,
                  labelText: 'Enter discount amount',
                  enabled: _discountEnabled,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  onChanged: (value) => _updateTaxAndFees(
                    context,
                    discountAmount: double.tryParse(value) ?? 0,
                  ),
                  prefixIcon: const Icon(Icons.discount, size: 20),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildWithholdingField(
    BuildContext context,
    PaymentState state,
    bool canApplyWithholding,
    bool isSmallScreen,
  ) {
    final isWithholdingApplied =
        state.isWithholdingEnabled && canApplyWithholding;
    final withholdingAmount = isWithholdingApplied
        ? state.subtotal * PaymentConstants.withholdingRate
        : 0;

    final withholdingText = isWithholdingApplied
        ? _currencyFormat.format(withholdingAmount)
        : state.isWithholdingEnabled && !canApplyWithholding
        ? 'Not applicable'
        : '0.00';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Withholding Tax',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(width: isSmallScreen ? 4 : 8),
            Text(
              isWithholdingApplied
                  ? 'Applied'
                  : state.isWithholdingEnabled
                  ? canApplyWithholding
                        ? 'Applied'
                        : 'Will apply'
                  : 'Disabled',
              style: TextStyle(
                color: isWithholdingApplied
                    ? Theme.of(context).colorScheme.primary
                    : state.isWithholdingEnabled
                    ? Colors.orange
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontSize: isSmallScreen ? 12 : 14,
              ),
            ),
            SizedBox(width: isSmallScreen ? 4 : 8),
            Transform.scale(
              scale: isSmallScreen ? 0.8 : 1.0,
              child: Switch(
                value: state.isWithholdingEnabled,
                onChanged: (enabled) {
                  context.read<PaymentBloc>().add(
                    UpdateTaxAndFees(
                      subtotal: state.subtotal,
                      discountAmount: state.discountAmount,
                      isWithholdingEnabled: enabled,
                    ),
                  );
                },
                activeColor: isWithholdingApplied
                    ? Theme.of(context).colorScheme.primary
                    : Colors.orange,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isWithholdingApplied
                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                : state.isWithholdingEnabled
                ? Colors.orange.withOpacity(0.1)
                : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isWithholdingApplied
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                  : state.isWithholdingEnabled
                  ? Colors.orange.withOpacity(0.3)
                  : Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.account_balance,
                size: 20,
                color: isWithholdingApplied
                    ? Theme.of(context).colorScheme.primary
                    : state.isWithholdingEnabled
                    ? Colors.orange
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      withholdingText,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        color: isWithholdingApplied
                            ? Theme.of(context).colorScheme.primary
                            : state.isWithholdingEnabled
                            ? Colors.orange
                            : Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: isWithholdingApplied
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    if (isWithholdingApplied)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          '${(PaymentConstants.withholdingRate * 100).toStringAsFixed(1)}% of subtotal',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.7),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (state.isWithholdingEnabled)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              canApplyWithholding
                  ? 'Withholding tax is applied to this transaction'
                  : 'Subtotal must exceed \$${PaymentConstants.minSubtotalForWithholding} to apply withholding',
              style: TextStyle(
                fontSize: 12,
                color: canApplyWithholding
                    ? Theme.of(context).colorScheme.primary
                    : Colors.orange,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildWarningMessage(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Withholding is enabled but cannot be applied because subtotal is below \$${PaymentConstants.minSubtotalForWithholding}',
              style: TextStyle(fontSize: 12, color: Colors.orange[800]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(
    BuildContext context,
    String label,
    String value, {
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceVariant.withOpacity(0.4),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 20,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTotalField(BuildContext context, String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.payment,
                size: 24,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _currencyFormat.format(value),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
