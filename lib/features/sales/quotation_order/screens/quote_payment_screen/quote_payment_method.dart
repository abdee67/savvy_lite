import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:savvy_stock/core/widgets/custom_dropdown.dart';
import 'package:savvy_stock/core/widgets/custom_text_Form.dart';
import 'package:savvy_stock/features/sales/sales_order/payment/widget/payment_action.dart';
import 'package:savvy_stock/features/sales/sales_order/integration/bloc/sales_order_coordinator_bloc.dart';
import 'package:savvy_stock/features/sales/sales_order/integration/bloc/sales_order_coordinator_event.dart';
import 'package:savvy_stock/features/sales/sales_order/integration/bloc/sales_order_coordinator_state.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_bloc.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_event.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_state.dart';

class PaymentMethod extends StatefulWidget {
  const PaymentMethod({super.key});

  @override
  State<PaymentMethod> createState() => _PaymentMethodState();
}

class _PaymentMethodState extends State<PaymentMethod> {
  final TextEditingController _paymentTermController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  int? _selectedPaymentInstrument;
  @override
  void initState() {
    super.initState();
    _paymentTermController.addListener(_onPaymentTermChanged);
    context.read<UdcDetailsBloc>().add(
      LoadAllUdcDetails(),
    ); // for Unit of Measure and lot status
  }

  void _onPaymentTermChanged() {
    final bloc = context.read<SalesOrderCoordinatorBloc>();
    final currentState = bloc.state;

    bloc.add(
      UpdatePaymentDetails(
        paymentMethod: currentState.paymentMethod,
        paymentInstrument: currentState.paymentInstrument,
        paymentTerm: _paymentTermController.text,
      ),
    );
  }

  void _selectpaymentMethod(BuildContext context, String paymentMethod) {
    final bloc = context.read<SalesOrderCoordinatorBloc>();
    final currentState = bloc.state;

    bloc.add(
      UpdatePaymentDetails(
        paymentMethod: paymentMethod,
        paymentInstrument: currentState.paymentInstrument,
        paymentTerm: paymentMethod == 'Credit' ? currentState.paymentTerm : '',
      ),
    );

    // Clear payment term if switching from Credit
    if (paymentMethod != 'Credit') {
      _paymentTermController.clear();
    }
  }

  void _updatePaymentInstrument(BuildContext context, int? instrument) {
    if (instrument == null) return;

    final bloc = context.read<SalesOrderCoordinatorBloc>();
    final currentState = bloc.state;
    bloc.add(
      UpdatePaymentDetails(
        paymentMethod: currentState.paymentMethod,
        paymentInstrument: currentState.paymentInstrument,
        paymentTerm: currentState.paymentTerm,
      ),
    );
  }

  void _updatePaymentTerm(BuildContext context, String term) {
    final bloc = context.read<SalesOrderCoordinatorBloc>();
    final currentState = bloc.state;

    bloc.add(
      UpdatePaymentDetails(
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
        final isCreditSelected = state.paymentMethod == 'Credit';

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
                _buildpaymentMethodSelector(context, state),
                const SizedBox(height: 16),
                if (isCreditSelected) ...[
                  _buildPaymentTermField(context),
                  const SizedBox(height: 16),
                ],
                BlocBuilder<UdcDetailsBloc, UdcDetailsState>(
                  builder: (context, state) {
                    final paymentInstrument = state.details
                        .where((udc) => udc.udcGroupRef?.udcCode == 'PI')
                        .toList();

                    return CustomDropdown(
                      labelText: 'Payment Instrument',
                      value: _selectedPaymentInstrument,
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a payment instrument';
                        }
                        return null;
                      },
                      prefixIcon: const Icon(Icons.credit_card),
                      items: paymentInstrument.map((udc) {
                        return DropdownMenuItem<int>(
                          value: udc.id,
                          child: Text(udc.description1),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        _updatePaymentInstrument(context, newValue);
                        setState(() {
                          _selectedPaymentInstrument = newValue;
                        });
                      },
                    );
                  },
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

  Widget _buildpaymentMethodSelector(
    BuildContext context,
    SalesOrderCoordinatorState state,
  ) {
    const paymentMethods = ['Cash', 'Credit', 'Advance'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Methods',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: paymentMethods.map((type) {
            final isSelected = state.paymentMethod == type;
            return ChoiceChip(
              label: Text(
                type,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF1E3A5C),
                ),
              ),
              selected: isSelected,
              onSelected: (_) => _selectpaymentMethod(context, type),
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
}
