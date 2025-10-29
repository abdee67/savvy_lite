import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:savvy_stock/core/widgets/custom_dropdown.dart';
import 'package:savvy_stock/core/widgets/custom_text_Form.dart';
import 'package:savvy_stock/features/sales/payment/blocs/payment_bloc.dart';
import 'package:savvy_stock/features/sales/payment/blocs/payment_event.dart';
import 'package:savvy_stock/features/sales/payment/blocs/payment_state.dart';
import 'package:savvy_stock/features/sales/payment/widget/payment_action.dart';

class PaymentMethod extends StatefulWidget {
  const PaymentMethod({super.key});

  @override
  State<PaymentMethod> createState() => _PaymentMethodState();
}

class _PaymentMethodState extends State<PaymentMethod> {
  final TextEditingController _paymentTermController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _paymentTermController.dispose();
    super.dispose();
  }

  void _selectPaymentType(BuildContext context, String paymentType) {
    final bloc = context.read<PaymentBloc>();
    final currentState = bloc.state;

    bloc.add(
      UpdatePaymentDetails(
        paymentType: paymentType,
        paymentMethod: currentState.paymentMethod,
        paymentInstrument: currentState.paymentInstrument,
        paymentTerm: currentState.paymentTerm,
      ),
    );

    // Clear payment term if switching from Credit to another payment type
    if (paymentType != 'Credit' && currentState.paymentTerm.isNotEmpty) {
      _paymentTermController.clear();
      bloc.add(
        UpdatePaymentDetails(
          paymentType: paymentType,
          paymentMethod: currentState.paymentMethod,
          paymentInstrument: currentState.paymentInstrument,
          paymentTerm: '',
        ),
      );
    }
  }

  void _updatePaymentInstrument(BuildContext context, String? instrument) {
    if (instrument == null) return;

    final bloc = context.read<PaymentBloc>();
    final currentState = bloc.state;

    // Preserve the existing payment term
    final paymentTerm = _paymentTermController.text.isNotEmpty
        ? _paymentTermController.text
        : currentState.paymentTerm;

    bloc.add(
      UpdatePaymentDetails(
        paymentType: currentState.paymentType,
        paymentMethod: currentState.paymentMethod,
        paymentInstrument: instrument,
        paymentTerm: paymentTerm,
      ),
    );

    // Ensure the controller is in sync with the state
    if (_paymentTermController.text != paymentTerm) {
      _paymentTermController.text = paymentTerm;
    }
  }

  void _updatePaymentTerm(BuildContext context, String term) {
    final bloc = context.read<PaymentBloc>();
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

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 700;
    final isMediumScreen = MediaQuery.of(context).size.width < 1024;
    final padding = isSmallScreen
        ? 16
        : isMediumScreen
        ? 24
        : 32;

    return BlocConsumer<PaymentBloc, PaymentState>(
      listener: (context, state) {
        // Sync controller with state changes from other sources
        if (_paymentTermController.text != state.paymentTerm) {
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
                const SizedBox(height: 16),
                _buildPaymentTypeSelector(context, state),
                const SizedBox(height: 16),
                if (isCreditSelected) ...[
                  _buildPaymentTermField(
                    context,
                    _paymentTermController,
                    state,
                  ),
                  const SizedBox(height: 16),
                ],
                _buildPaymentInstrumentDropdown(context, state),
                const SizedBox(height: 8),
                if (state.paymentInstrument.isNotEmpty)
                  Text(
                    _getInstrumentDescription(state.paymentInstrument),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                const SizedBox(height: 16),
                const PaymentAction(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentTermField(
    BuildContext context,
    TextEditingController controller,
    PaymentState state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _selectDate(controller),
          child: AbsorbPointer(
            child: CustomTextField(
              controller: controller,
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

  Future<void> _selectDate(TextEditingController controller) async {
    // Dismiss keyboard if it's showing
    FocusScope.of(context).unfocus();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: controller.text.isNotEmpty
          ? DateTime.tryParse(controller.text) ?? DateTime.now()
          : DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      controller.text =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    }
  }

  Widget _buildPaymentInstrumentDropdown(
    BuildContext context,
    PaymentState state,
  ) {
    const instruments = ['Cash', 'Check', 'Credit Card', 'Bank Transfer'];

    // Filter available instruments based on payment type
    List<String> availableInstruments;
    if (state.paymentType == 'Cash') {
      availableInstruments = ['Cash'];
    } else if (state.paymentType == 'Credit') {
      availableInstruments = ['Check', 'Credit Card', 'Bank Transfer'];
    } else if (state.paymentType == 'Advance') {
      availableInstruments = ['Cash', 'Bank Transfer'];
    } else {
      availableInstruments = instruments;
    }

    // Reset instrument if current selection is not available for the payment type
    if (!availableInstruments.contains(state.paymentInstrument) &&
        state.paymentInstrument.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updatePaymentInstrument(context, availableInstruments.first);
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomDropdown<String>(
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
          prefixIcon: Icon(Icons.money_off),
          items: availableInstruments.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                style: const TextStyle(color: Color(0xFF1E3A5C)),
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            _updatePaymentInstrument(context, newValue);
          },
        ),
      ],
    );
  }

  Widget _buildPaymentTypeSelector(BuildContext context, PaymentState state) {
    const paymentTypes = ['Cash', 'Credit', 'Advance'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
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
              selectedColor: Colors.amber,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(width: 1),
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
