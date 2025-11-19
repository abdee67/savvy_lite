import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:savvy_stock/core/widgets/custom_dropdown.dart';
import 'package:savvy_stock/core/widgets/custom_text_Form.dart';
import 'package:savvy_stock/features/sales/sales_order/payment/widget/payment_action.dart';
import 'package:savvy_stock/features/sales/sales_order/integration/bloc/sales_order_coordinator_bloc.dart';
import 'package:savvy_stock/features/sales/sales_order/integration/bloc/sales_order_coordinator_event.dart';
import 'package:savvy_stock/features/sales/sales_order/integration/bloc/sales_order_coordinator_state.dart';

class PaymentMethod extends StatefulWidget {
  const PaymentMethod({super.key});

  @override
  State<PaymentMethod> createState() => _PaymentMethodState();
}

class _PaymentMethodState extends State<PaymentMethod> {
  final TextEditingController _paymentTermController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  @override
  void initState() {
    super.initState();
    _paymentTermController.addListener(_onPaymentTermChanged);
  }

  void _onPaymentTermChanged() {
    final bloc = context.read<SalesOrderCoordinatorBloc>();
    final currentState = bloc.state;

    bloc.add(
      UpdatePaymentDetails(
        paymentType: currentState.paymentType,
        paymentMethod: currentState.paymentMethod,
        paymentInstrument: currentState.paymentInstrument,
        paymentTerm: _paymentTermController.text,
      ),
    );
  }

  void _selectPaymentType(BuildContext context, String paymentType) {
    final bloc = context.read<SalesOrderCoordinatorBloc>();
    final currentState = bloc.state;

    bloc.add(
      UpdatePaymentDetails(
        paymentType: paymentType,
        paymentMethod: currentState.paymentMethod,
        paymentInstrument: currentState.paymentInstrument,
        paymentTerm: paymentType == 'Credit' ? currentState.paymentTerm : '',
      ),
    );

    // Clear payment term if switching from Credit
    if (paymentType != 'Credit') {
      _paymentTermController.clear();
    }
  }

  void _updatePaymentInstrument(BuildContext context, String? instrument) {
    if (instrument == null) return;

    final bloc = context.read<SalesOrderCoordinatorBloc>();
    final currentState = bloc.state;
    bloc.add(
      UpdatePaymentDetails(
        paymentType: currentState.paymentType,
        paymentMethod: currentState.paymentMethod,
        paymentInstrument: instrument,
        paymentTerm: currentState.paymentTerm,
      ),
    );
  }

  void _updatePaymentTerm(BuildContext context, String term) {
    final bloc = context.read<SalesOrderCoordinatorBloc>();
    final currentState = bloc.state;

    bloc.add(
      UpdatePaymentDetails(
        paymentType: currentState.paymentType,
        paymentMethod: currentState.paymentMethod,
        paymentInstrument: currentState.paymentInstrument,
        paymentTerm: term,
      ),
    );
  }

  Future<void> _selectDate() async {
    FocusScope.of(context).unfocus();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF155888)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      _paymentTermController.text =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    }
  }

  @override
  void dispose() {
    _paymentTermController.removeListener(_onPaymentTermChanged);
    _paymentTermController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 700;
    final isMediumScreen = MediaQuery.of(context).size.width < 1024;
    final padding = isSmallScreen
        ? 16
        : isMediumScreen
        ? 24
        : 32;

    return BlocConsumer<SalesOrderCoordinatorBloc, SalesOrderCoordinatorState>(
      listener: (context, state) {
        // Sync controller with state changes from other sources
        if (_paymentTermController.text != state.paymentTerm &&
            state.paymentTerm.isNotEmpty) {
          _paymentTermController.text = state.paymentTerm;
        }
      },
      builder: (context, state) {
        final isCreditSelected = state.paymentType == 'Credit';

        return Container(
          constraints: BoxConstraints(
            maxWidth: double.infinity,
            minHeight: isSmallScreen
                ? 250
                : isMediumScreen
                ? 330
                : 400,
            maxHeight: isSmallScreen
                ? 350
                : isMediumScreen
                ? 400
                : 450,
          ),
          padding: EdgeInsets.all(padding.toDouble()),
          decoration: BoxDecoration(
            color: Colors.grey,
            borderRadius: const BorderRadius.only(
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPaymentTypeSelector(context, state),
                const SizedBox(height: 16),
                if (isCreditSelected) ...[
                  _buildPaymentTermField(context),
                  const SizedBox(height: 16),
                ],
                _buildPaymentInstrumentDropdown(context, state),
                const SizedBox(height: 8),
                if (state.paymentInstrument.isNotEmpty)
                  Text(
                    _getInstrumentDescription(state.paymentInstrument),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                const PaymentAction(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentTermField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _selectDate(),
          child: AbsorbPointer(
            child: CustomTextField(
              controller: _paymentTermController,
              labelText: 'Enter Due date on receipt',
              hintText: 'Select date',
              focusNode: FocusNode(
                debugLabel: 'Payment Term',
                canRequestFocus: false,
              ),
              textInputAction: TextInputAction.done,
              prefixIcon: const Icon(Icons.calendar_today, size: 20),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Payment term is required for credit';
                }
                return null;
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentInstrumentDropdown(
    BuildContext context,
    SalesOrderCoordinatorState state,
  ) {
    const allInstruments = ['Cash', 'Check', 'Credit Card', 'Bank Transfer'];

    // Filter available instruments based on payment type
    List<String> availableInstruments;
    switch (state.paymentType) {
      case 'Cash':
        availableInstruments = ['Cash'];
        break;
      case 'Credit':
        availableInstruments = ['Check', 'Credit Card', 'Bank Transfer'];
        break;
      case 'Advance':
        availableInstruments = ['Cash', 'Bank Transfer'];
        break;
      default:
        availableInstruments = allInstruments;
    }

    // Reset instrument if current selection is not available
    if (!availableInstruments.contains(state.paymentInstrument) &&
        state.paymentInstrument.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updatePaymentInstrument(context, availableInstruments.first);
      });
    }

    return CustomDropdown<String>(
      labelText: 'Payment Instrument',
      value:
          state.paymentInstrument.isNotEmpty &&
              availableInstruments.contains(state.paymentInstrument)
          ? state.paymentInstrument
          : availableInstruments.first,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a payment instrument';
        }
        return null;
      },
      prefixIcon: const Icon(Icons.credit_card),
      items: availableInstruments.map((String value) {
        return DropdownMenuItem<String>(value: value, child: Text(value));
      }).toList(),
      onChanged: (String? newValue) {
        _updatePaymentInstrument(context, newValue);
      },
    );
  }

  Widget _buildPaymentTypeSelector(
    BuildContext context,
    SalesOrderCoordinatorState state,
  ) {
    const paymentTypes = ['Cash', 'Credit', 'Advance'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Type',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: paymentTypes.map((type) {
            final isSelected = state.paymentType == type;
            return ChoiceChip(
              label: Text(
                type,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF1E3A5C),
                ),
              ),
              selected: isSelected,
              onSelected: (_) => _selectPaymentType(context, type),
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF155888),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Colors.grey),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _getInstrumentDescription(String instrument) {
    switch (instrument) {
      case 'Cash':
        return 'Immediate payment with physical currency';
      case 'Check':
        return 'Payment via written check';
      case 'Credit Card':
        return 'Payment via credit/debit card';
      case 'Bank Transfer':
        return 'Electronic funds transfer';
      default:
        return '';
    }
  }
}
