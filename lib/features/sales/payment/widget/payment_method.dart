import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:savvy_stock/core/widgets/custom_text_Form.dart';
import 'package:savvy_stock/features/sales/payment/blocs/payment_bloc.dart';
import 'package:savvy_stock/features/sales/payment/blocs/payment_event.dart';
import 'package:savvy_stock/features/sales/payment/blocs/payment_state.dart';

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
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E3A5C),
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
                  _buildPaymentTermField(context, state),
                  const SizedBox(height: 16),
                ],
                _buildPaymentInstrumentDropdown(context, state),
                const SizedBox(height: 8),
                if (state.paymentInstrument.isNotEmpty)
                  Text(
                    _getInstrumentDescription(state.paymentInstrument),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                if (isCreditSelected) const SizedBox(height: 8),
                if (isCreditSelected)
                  Text(
                    'Payment terms are required for credit transactions',
                    style: TextStyle(
                      color: Colors.amber[200],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentTermField(BuildContext context, PaymentState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          controller: _paymentTermController,
          labelText: 'Enter Due date on receipt',
          hintText: 'Enter payment terms',
          onChanged: (value) => _updatePaymentTerm(context, value),
          textInputAction: TextInputAction.done,
          suffixIcon: const Icon(Icons.calendar_today, size: 20),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Payment term is required for credit';
            }
            return null;
          },
        ),
      ],
    );
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
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonFormField<String>(
            initialValue:
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
            borderRadius: BorderRadius.circular(8),
            menuMaxHeight: 200,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
            ),
            style: const TextStyle(color: Color(0xFF1E3A5C), fontSize: 16),
            dropdownColor: Colors.white,
            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF1E3A5C)),
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
        ),
      ],
    );
  }

  Widget _buildPaymentTypeSelector(BuildContext context, PaymentState state) {
    const paymentTypes = ['Cash', 'Credit', 'Advance'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          direction: Axis.horizontal,
          spacing: 10,
          runSpacing: 10,
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
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF2A4B7C)
                      : Colors.grey[300]!,
                  width: 1,
                ),
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
