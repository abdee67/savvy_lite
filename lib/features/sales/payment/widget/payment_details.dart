import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:savvy_stock/core/constants/payment_constants.dart';
import 'package:savvy_stock/core/di/injection_container.dart';
import 'package:savvy_stock/core/widgets/custom_text_Form.dart';
import 'package:savvy_stock/features/sales/payment/blocs/payment_bloc.dart';
import 'package:savvy_stock/features/sales/payment/blocs/payment_event.dart';
import 'package:savvy_stock/features/sales/payment/blocs/payment_state.dart';
import 'package:savvy_stock/core/services/system_constant/system_constant_service.dart';
import 'package:savvy_stock/core/models/system_constant.dart';

class PaymentDetails extends StatefulWidget {
  const PaymentDetails({super.key});

  @override
  State<PaymentDetails> createState() => _PaymentDetailsState();
}

class _PaymentDetailsState extends State<PaymentDetails> {
  final NumberFormat _currencyFormat = NumberFormat('#,##0.00');
  final TextEditingController _discountController = TextEditingController();
  final SystemConstantsService _systemConstantsService =
      getIt<SystemConstantsService>();
  bool _discountEnabled = false;
  bool _systemConstantsLoaded = false;

  @override
  void initState() {
    super.initState();
    _discountController.addListener(_onDiscountChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final systemConstantsService = getIt<SystemConstantsService>();
      if (systemConstantsService.currentSystemConstant != null) {
        setState(() {
          _systemConstantsLoaded = true;
        });
        context.read<PaymentBloc>().add(const LoadFeeSystemConstants());
      } else {
        // Wait for system constants
        context.read<PaymentBloc>().add(const WaitForSystemConstants());
      }
    });
  }

  void _onDiscountChanged() {
    if (_discountEnabled) {
      final discountAmount = double.tryParse(_discountController.text) ?? 0;
      _updateTaxAndFees(discountAmount: discountAmount);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load data when dependencies change (screen becomes visible)
    final systemConstantsService = getIt<SystemConstantsService>();
    systemConstantsService.addListener(_onSystemConstantsChanged);
  }

  void _onSystemConstantsChanged() {
    final systemConstantsService = getIt<SystemConstantsService>();
    if (systemConstantsService.currentSystemConstant != null) {
      setState(() {
        _systemConstantsLoaded = true;
      });
      context.read<PaymentBloc>().add(const LoadFeeSystemConstants());
    } else {
      // Wait for system constants
      context.read<PaymentBloc>().add(const WaitForSystemConstants());
    }
  }

  @override
  void dispose() {
    final systemConstantsService = getIt<SystemConstantsService>();
    systemConstantsService.removeListener(_onSystemConstantsChanged);
    _discountController.removeListener(_onDiscountChanged);
    _discountController.dispose();
    super.dispose();
  }

  void _updateTaxAndFees({double discountAmount = 0}) {
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
    return BlocConsumer<PaymentBloc, PaymentState>(
      //Sync discount amount with state
      listener: (context, state) {
        if (state.systemConstantsError != null &&
            state.systemConstantsError!.contains(
              'Waiting for system constants',
            )) {
          // System constants are still loading, try to load them
          getIt<SystemConstantsService>().currentSystemConstant;
        }
      },
      builder: (context, state) {
        // SHOW LOADING IF SYSTEM CONSTANTS NOT READY
        if (!_systemConstantsLoaded) {
          return _buildLoadingState();
        }

        // SHOW ERROR IF SYSTEM CONSTANTS FAILED TO LOAD
        if (state.systemConstantsError != null &&
            !state.systemConstantsError!.contains(
              'Waiting for system constants',
            )) {
          return _buildErrorState(state.systemConstantsError!);
        }

        // NORMAL RENDERING WHEN SYSTEM CONSTANTS ARE READY
        return _buildPaymentDetails(context, state);
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading system configuration...'),
          SizedBox(height: 8),
          Text(
            'Please wait while we load your tax rates and settings',
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.orange, size: 48),
          SizedBox(height: 16),
          Text(
            'Configuration Error',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(color: Colors.orange),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              getIt<SystemConstantsService>().ensureLoaded();
              context.read<PaymentBloc>().add(const LoadFeeSystemConstants());
            },
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetails(BuildContext context, PaymentState state) {
    // YOUR EXISTING UI CODE HERE (the SingleChildScrollView with all the fields)
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    final padding = isSmallScreen ? 12.0 : 16.0;

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
            if (state.systemConstantsError != null)
              _buildSystemConstantsWarning(state.systemConstantsError!),
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
              state.canApplyWithholding,
              state.withholdingRate,
              state.withholdingInitial,
              isSmallScreen,
            ),
            const SizedBox(height: 12),
            _buildTaxField(context, state, state.vatRate),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            _buildTotalField(context, 'Total', state.grandTotal),
            if (!state.canApplyWithholding && state.isWithholdingEnabled)
              _buildWarningMessage(context, state),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemConstantsWarning(String error) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning, color: Colors.orange, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(color: Colors.orange, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaxField(
    BuildContext context,
    PaymentState state,
    double vatRate,
  ) {
    return _buildReadOnlyField(
      context,
      'Tax (${(vatRate).toStringAsFixed(1)}%)',
      _currencyFormat.format(state.taxAmount),
      icon: Icons.receipt,
      subtitle: 'VAT rate from system configuration',
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

  // Add this method to show when values are loaded from database
  Widget _buildDataSourceIndicator(bool fromDatabase) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: fromDatabase
            ? Colors.green.withOpacity(0.1)
            : Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: fromDatabase ? Colors.green : Colors.blue,
          width: 0.5,
        ),
      ),
      child: Text(
        fromDatabase ? '✓ Using database values' : '⚠ Using default values',
        style: TextStyle(
          fontSize: 10,
          color: fromDatabase ? Colors.green : Colors.blue,
          fontWeight: FontWeight.bold,
        ),
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
                      _updateTaxAndFees(discountAmount: 0);
                    }
                  });
                },
                activeThumbColor: Theme.of(context).colorScheme.primary,
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
    double withholdingRate,
    double withholdingInitial,
    bool isSmallScreen,
  ) {
    final isWithholdingApplied =
        state.canApplyWithholding && state.isWithholdingEnabled;
    final withholdingAmount = _currencyFormat.format(state.withholdingAmount);
    final withholdingText = isWithholdingApplied
        ? '$withholdingAmount ($withholdingRate%)'
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
                activeThumbColor: isWithholdingApplied
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
                : Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
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
                          '${(state.withholdingRate).toStringAsFixed(1)}% of subtotal',
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
                  : 'Subtotal must exceed \$${state.withholdingInitial} to apply withholding',
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

  Widget _buildWarningMessage(BuildContext context, PaymentState state) {
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
          Icon(Iconsax.information_copy, color: Colors.orange[700], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Withholding is enabled but cannot be applied because subtotal is below \$${_currencyFormat.format(state.withholdingInitial)}',
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
    String? subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (subtitle != null)
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withOpacity(0.4),
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
