import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:savvy_stock/features/sales/quotation_order/bloc/quotation_order_bloc.dart';
import 'package:savvy_stock/features/sales/quotation_order/bloc/quotation_order_event.dart';
import 'package:savvy_stock/features/sales/quotation_order/bloc/quotation_order_state.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_bloc.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_event.dart';
import 'package:savvy_stock/core/di/injection_container.dart';
import 'package:savvy_stock/core/widgets/custom_text_Form.dart';
import 'package:savvy_stock/features/system_constant/repo/system_constant_service.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';

class QuotePaymentDetails extends StatefulWidget {
  final AuthBloc authBloc;
  const QuotePaymentDetails({super.key, required this.authBloc});

  @override
  State<QuotePaymentDetails> createState() => _QuotePaymentDetailsState();
}

class _QuotePaymentDetailsState extends State<QuotePaymentDetails> {
  final NumberFormat _currencyFormat = NumberFormat('#,##0.00');
  final TextEditingController _discountController = TextEditingController();
  bool _discountEnabled = false;
  bool _systemConstantsLoaded = false;
  int _decimalPlace = 2;

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
        final companyId = widget.authBloc.state.companyId;
        if (companyId != null) {
          context.read<SystemConstantBloc>().add(
            LoadSystemConstants(companyId),
          );
          context.read<QuotationOrderBloc>().add(LoadFeeSystemConstants());
        }
      }
    });
    _decimalPlace =
        context.read<SystemConstantBloc>().state.selected?.decimalPlaces ?? 2;
  }

  void _onDiscountChanged() {
    if (_discountEnabled) {
      final discountAmount = double.tryParse(_discountController.text) ?? 0;
      _updateFinancialData(discountAmount: discountAmount);
    }
  }

  void _updateFinancialData({double discountAmount = 0}) {
    final bloc = context.read<QuotationOrderBloc>();
    final state = bloc.state;

    bloc.add(
      UpdateTaxSettings(
        subTotal: state.subTotal ?? 0.0,
        discountAmount: discountAmount,
        isWithholdingEnabled: state.canApplyWithholding ?? false,
      ),
    );
  }

  void _toggleDiscount(bool enabled) {
    setState(() {
      _discountEnabled = enabled;
      if (!enabled) {
        _discountController.clear();
        _updateFinancialData(discountAmount: 0);
      }
    });
  }

  void _toggleWithholding(bool enabled) {
    final bloc = context.read<QuotationOrderBloc>();
    final state = bloc.state;

    bloc.add(
      UpdateTaxSettings(
        subTotal: state.subTotal ?? 0.0,
        discountAmount: state.discountAmount ?? 0.0,
        isWithholdingEnabled: enabled,
      ),
    );
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
      context.read<QuotationOrderBloc>().add(LoadFeeSystemConstants());
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

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<QuotationOrderBloc, QuotationOrderState>(
      //Sync discount amount with state
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
      builder: (context, state) {
        // Sync discount controller with state
        if (state.discountAmount != null &&
            _discountController.text.isEmpty &&
            state.discountAmount! > 0) {
          _discountController.text = state.discountAmount!.toStringAsFixed(2);
        }

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
              context.read<QuotationOrderBloc>().add(LoadFeeSystemConstants());
            },
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetails(BuildContext context, QuotationOrderState state) {
    // YOUR EXISTING UI CODE HERE (the SingleChildScrollView with all the fields)
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    final padding = isSmallScreen ? 12.0 : 16.0;

    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Order Summary Header
            const SizedBox(height: 16),
            _buildReadOnlyField(
              context,
              'Subtotal',
              _currencyFormat.format(state.subTotal),
              icon: Icons.shopping_cart,
            ),
            const SizedBox(height: 6),
            _buildDiscountField(context, state, isSmallScreen),
            const SizedBox(height: 16),
            _buildWithholdingField(context, state, isSmallScreen),
            const SizedBox(height: 16),
            _buildTaxField(context, state),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            _buildTotalField(context, 'Total', state.totalAmount ?? 0.0),
            if (!(state.canApplyWithholding ?? false) &&
                (state.isWithholdingEnabled ?? false))
              _buildWarningMessage(context, state),
          ],
        ),
      ),
    );
  }

  Widget _buildTaxField(BuildContext context, QuotationOrderState state) {
    final vatRate = state.taxRate ?? 0.0;
    final taxAmount = state.tax ?? 0.0;
    return _buildReadOnlyField(
      context,
      'Tax (${vatRate.toStringAsFixed(_decimalPlace)}%)',
      NumberFormat.currency(
        decimalDigits: _decimalPlace,
        symbol: 'ETB ',
      ).format(taxAmount),
      icon: Icons.receipt,
      subtitle: 'VAT rate from system configuration',
    );
  }

  Widget _buildDiscountField(
    BuildContext context,
    QuotationOrderState state,
    bool isSmallScreen,
  ) {
    final theme = Theme.of(context);
    final borderColor = _discountEnabled
        ? theme.colorScheme.primary
        : const Color(0xFF1C1C1C);

    return GestureDetector(
      onTap: () => _toggleDiscount(!_discountEnabled),
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
            const Icon(Icons.discount, size: 20),
            const SizedBox(width: 8),

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
                      _updateFinancialData(
                        discountAmount: double.tryParse(value) ?? 0,
                      );
                    },
                  ),
                ),
              ),
            ),
            _buildToggleSwitch(_discountEnabled, borderColor, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildWithholdingField(
    BuildContext context,
    QuotationOrderState state,
    bool isSmallScreen,
  ) {
    final theme = Theme.of(context);
    final canApplyWithholding = state.canApplyWithholding ?? false;
    final isWithholdingEnabled = state.isWithholdingEnabled ?? false;
    final isWithholdingApplied = canApplyWithholding && isWithholdingEnabled;

    final borderColor = isWithholdingApplied
        ? theme.colorScheme.primary
        : isWithholdingEnabled
        ? theme.colorScheme.primary
        : const Color(0xFF1C1C1C);

    final withholdingAmountText = isWithholdingApplied
        ? _currencyFormat.format(state.withholdAmount)
        : '----';

    final withholdingRate = state.withholdingRate ?? 0.0;
    final withholdingDisplayText = isWithholdingApplied
        ? '$withholdingAmountText (${withholdingRate.toStringAsFixed(_decimalPlace)}%)'
        : isWithholdingEnabled && !canApplyWithholding
        ? 'Not applicable'
        : 'Withholding(----)';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _toggleWithholding(!isWithholdingEnabled),
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
                const SizedBox(width: 8),

                /// Withholding display (not editable but reactive)
                Expanded(
                  child: IgnorePointer(
                    ignoring: true,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: isWithholdingEnabled ? 1.0 : 0.6,
                      child: TextField(
                        enabled: false,
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

                _buildToggleSwitch(isWithholdingEnabled, borderColor, theme),
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
              ? 'Subtotal must exceed ${NumberFormat.currency(decimalDigits: _decimalPlace, symbol: 'ETB ').format(state.withholdingInitial)} to apply withholding'
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
              '${withholdingRate.toStringAsFixed(_decimalPlace)}% of subtotal',
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ),
      ],
    );
  }

  Widget _buildToggleSwitch(
    bool isEnabled,
    Color borderColor,
    ThemeData theme,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: 36,
      height: 20,
      margin: const EdgeInsets.only(left: 10),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(12),
        color: isEnabled ? theme.colorScheme.primary : Colors.grey[100],
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 250),
        alignment: isEnabled ? Alignment.centerRight : Alignment.centerLeft,
        curve: Curves.easeInOut,
        child: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isEnabled ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildWarningMessage(BuildContext context, QuotationOrderState state) {
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
              'Withholding is enabled but cannot be applied because subtotal is below ${NumberFormat.currency(decimalDigits: _decimalPlace, symbol: 'ETB ').format(state.withholdingInitial)}',
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF155888).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF155888)),
      ),
      child: Row(
        children: [
          const Icon(Icons.payment, color: Color(0xFF155888)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF155888),
              ),
            ),
          ),
          Text(
            NumberFormat.currency(
              decimalDigits: _decimalPlace,
              symbol: 'ETB ',
            ).format(value),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF155888),
            ),
          ),
        ],
      ),
    );
  }
}
