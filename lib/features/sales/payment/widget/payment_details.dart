import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_bloc.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_event.dart';
import 'package:savvy_stock/core/di/injection_container.dart';
import 'package:savvy_stock/core/widgets/custom_text_Form.dart';
import 'package:savvy_stock/features/sales/payment/blocs/payment_bloc.dart';
import 'package:savvy_stock/features/sales/payment/blocs/payment_event.dart';
import 'package:savvy_stock/features/sales/payment/blocs/payment_state.dart';
import 'package:savvy_stock/features/system_constant/repo/system_constant_service.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';

class PaymentDetails extends StatefulWidget {
  final AuthBloc authBloc;
  const PaymentDetails({super.key, required this.authBloc});

  @override
  State<PaymentDetails> createState() => _PaymentDetailsState();
}

class _PaymentDetailsState extends State<PaymentDetails> {
  final NumberFormat _currencyFormat = NumberFormat('#,##0.00');
  final TextEditingController _discountController = TextEditingController();
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
        context.read<SystemConstantBloc>().add(
          LoadSystemConstants(widget.authBloc.state.companyId!),
        );
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
          Icon(Icons.error_outline, color: Colors.amber, size: 48),
          SizedBox(height: 16),
          Text(
            'Configuration Error',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(color: Colors.amber),
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
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.systemConstantsError != null)
              _buildSystemConstantsWarning(state.systemConstantsError!),
            const SizedBox(height: 16),
            _buildReadOnlyField(
              context,
              'Subtotal',
              _currencyFormat.format(state.subtotal),
              icon: Icons.shopping_cart,
            ),
            const SizedBox(height: 6),
            _buildDiscountField(context, state, isSmallScreen),
            const SizedBox(height: 16),
            _buildWithholdingField(
              context,
              state,
              state.canApplyWithholding,
              state.withholdingRate,
              state.withholdingInitial,
              isSmallScreen,
            ),
            const SizedBox(height: 16),
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
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning, color: Colors.amber, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(color: Colors.amber, fontSize: 12),
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
      'Tax (${vatRate.toStringAsFixed(1)}%)',
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

    final theme = Theme.of(context);
    final borderColor = _discountEnabled
        ? theme.colorScheme.primary
        : const Color(0xFF1C1C1C);

    return GestureDetector(
      onTap: () {
        setState(() {
          _discountEnabled = !_discountEnabled;
          if (!_discountEnabled) {
            _discountController.clear();
            _updateTaxAndFees(discountAmount: 0);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 45,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          children: [
            const Icon(Icons.discount),

            /// Discount text field (editable only when enabled)
            Expanded(
              child: IgnorePointer(
                ignoring: !_discountEnabled,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _discountEnabled ? 1.0 : 0.6,
                  child: TextField(
                    controller: _discountController,
                    textAlign: TextAlign.center,
                    enabled: _discountEnabled,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      fillColor: Colors.grey[100],
                      border: InputBorder.none,
                      hintText: _discountEnabled
                          ? 'Discount(0.00)'
                          : 'Discount(----)',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onChanged: (value) {
                      _updateTaxAndFees(
                        discountAmount: double.tryParse(value) ?? 0,
                      );
                    },
                  ),
                ),
              ),
            ),

            /// Animated toggle knob
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              width: 36,
              height: 20,
              margin: const EdgeInsets.only(left: 10),
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                border: Border.all(color: borderColor, width: 1),
                borderRadius: BorderRadius.circular(12),
                color: _discountEnabled
                    ? theme.colorScheme.primary
                    : Colors.grey[100],
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 250),
                alignment: _discountEnabled
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                curve: Curves.easeInOut,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _discountEnabled ? Colors.white : Colors.grey[700],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
    final theme = Theme.of(context);
    final isWithholdingEnabled = state.isWithholdingEnabled;
    final isWithholdingApplied =
        state.canApplyWithholding && state.isWithholdingEnabled;

    final borderColor = isWithholdingApplied
        ? theme.colorScheme.primary
        : isWithholdingEnabled
        ? theme.colorScheme.primary
        : const Color(0xFF1C1C1C);

    final withholdingAmountText = isWithholdingApplied
        ? _currencyFormat.format(state.withholdingAmount)
        : '----';

    final withholdingDisplayText = isWithholdingApplied
        ? '$withholdingAmountText (${withholdingRate.toStringAsFixed(1)}%)'
        : isWithholdingEnabled && !canApplyWithholding
        ? 'Not applicable'
        : 'Withholding(----)';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            context.read<PaymentBloc>().add(
              UpdateTaxAndFees(
                subtotal: state.subtotal,
                discountAmount: state.discountAmount,
                isWithholdingEnabled: !isWithholdingEnabled,
              ),
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: 45,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance, size: 20),

                /// Withholding display (not editable but reactive)
                Expanded(
                  child: IgnorePointer(
                    ignoring: !isWithholdingEnabled,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: isWithholdingEnabled ? 1.0 : 0.6,
                      child: TextField(
                        enabled: isWithholdingEnabled,
                        controller: TextEditingController(
                          text: withholdingDisplayText,
                        ),
                        readOnly: true,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          fillColor: Colors.grey[100],
                          border: InputBorder.none,
                          hintText: 'Withholding(----)',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                /// Animated toggle knob (matches discount field)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  width: 36,
                  height: 20,
                  margin: const EdgeInsets.only(left: 10),
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    border: Border.all(color: borderColor, width: 1),
                    borderRadius: BorderRadius.circular(12),
                    color: isWithholdingApplied
                        ? theme.colorScheme.primary
                        : isWithholdingEnabled
                        ? theme.colorScheme.primary
                        : Colors.grey[100],
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 250),
                    alignment: isWithholdingEnabled
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    curve: Curves.easeInOut,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isWithholdingEnabled
                            ? Colors.white
                            : Colors.grey[700],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        /// Status text below the field
        Text(
          isWithholdingApplied
              ? 'Withholding tax is applied to this transaction'
              : isWithholdingEnabled && !canApplyWithholding
              ? 'Subtotal must exceed \$${withholdingInitial.toStringAsFixed(2)} to apply withholding'
              : 'Withholding tax is disabled',
          style: TextStyle(
            fontSize: 12,
            color: isWithholdingApplied
                ? theme.colorScheme.primary
                : isWithholdingEnabled && !canApplyWithholding
                ? Colors.amber[800]
                : theme.colorScheme.onSurface.withOpacity(0.6),
            fontStyle: isWithholdingApplied || isWithholdingEnabled
                ? FontStyle.italic
                : FontStyle.normal,
          ),
        ),

        if (isWithholdingApplied)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              '${withholdingRate.toStringAsFixed(1)}% of subtotal',
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
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
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Iconsax.information_copy, color: Colors.amber, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Withholding is enabled but cannot be applied because subtotal is below \$${_currencyFormat.format(state.withholdingInitial)}',
              style: TextStyle(fontSize: 12, color: Colors.amber),
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
        CustomTextField(
          labelText: label,
          value: value,
          readOnly: true,
          prefixIcon: Icon(icon),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subtitle != null)
              Text(
                subtitle,
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildTotalField(BuildContext context, String label, double value) {
    return CustomTextField(
      labelText: label,
      value: _currencyFormat.format(value),
      readOnly: true,
      prefixIcon: Icon(Icons.payment),
    );
  }
}
