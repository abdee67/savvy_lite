// features/purchase/purchase_entry/ui/payment/purchase_payment_method.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:savvy_stock/core/widgets/custom_dropdown.dart';
import 'package:savvy_stock/core/widgets/custom_text_form.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/bloc/purchase_order_bloc.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/bloc/purchase_order_event.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/bloc/purchase_order_state.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/screens/purchase_payment/widget/payment_action.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_bloc.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_state.dart';

class PurchasePaymentMethod extends StatefulWidget {
  final PurchaseOrderState purchaseState;
  final dynamic orderData;

  const PurchasePaymentMethod({
    super.key,
    required this.purchaseState,
    required this.orderData,
  });

  @override
  State<PurchasePaymentMethod> createState() => _PurchasePaymentMethodState();
}

class _PurchasePaymentMethodState extends State<PurchasePaymentMethod> {
  final TextEditingController _paymentTermController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? _selectedPaymentType;
  int? _selectedPaymentInstrument;
  DateTime? _creditDueDate;

  @override
  void initState() {
    super.initState();

    _paymentTermController.addListener(_onPaymentTermChanged);

    // Initialize with existing values from state
    _initializeFromState();
  }

  void _initializeFromState() {
    final header = widget.purchaseState.selectedHeader;

    // Set payment term from header
    if (header?.paymentTerm != null) {
      _paymentTermController.text = header!.paymentTerm.toString();
    }

    // Set credit due date
    if (header?.creditDueDate != null) {
      _creditDueDate = header!.creditDueDate;
    }
  }

  void _onPaymentTermChanged() {
    final term = int.tryParse(_paymentTermController.text);
    if (term != null) {
      _updatePaymentDetails(paymentTerm: term);
    }
  }

  void _updatePaymentDetails({
    String? paymentType,
    int? paymentInstrument,
    int? paymentTerm,
  }) {
    final header = widget.purchaseState.selectedHeader;
    if (header != null) {
      final updatedHeader = header.copyWith(
        //paymentType: paymentType ?? header.paymentType,
        paymentInstrument: paymentInstrument ?? header.paymentInstrument,
        paymentTerm: paymentTerm ?? header.paymentTerm,
      );

      // Update credit due date if payment term changes
      if (paymentTerm != null && header.dateTransaction != null) {
        updatedHeader.creditDueDate = header.dateTransaction!.add(
          Duration(days: paymentTerm),
        );
        _creditDueDate = updatedHeader.creditDueDate;
      }

      context.read<PurchaseOrderBloc>().add(
        UpdatePurchaseOrderHeader(header: updatedHeader),
      );
    }
  }

  void _onPaymentTypeSelected(String? type) {
    setState(() {
      _selectedPaymentType = type;
    });

    _updatePaymentDetails(paymentType: type);

    // If not credit, clear payment term
    if (type != 'Credit') {
      _paymentTermController.clear();
      _updatePaymentDetails(paymentTerm: null);
    }
  }

  void _onPaymentInstrumentSelected(int? instrument) {
    setState(() {
      _selectedPaymentInstrument = instrument;
    });

    _updatePaymentDetails(paymentInstrument: instrument);
  }

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _creditDueDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF155888),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _creditDueDate = picked;
      });

      // Calculate payment term in days
      final header = widget.purchaseState.selectedHeader;
      if (header?.dateTransaction != null) {
        final term = picked.difference(header!.dateTransaction!).inDays;
        _paymentTermController.text = term.toString();
        _updatePaymentDetails(paymentTerm: term);
      }
    }
  }

  @override
  void dispose() {
    _paymentTermController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCreditSelected = _selectedPaymentType == 'Credit';
    final supplier = widget.purchaseState.selectedHeader?.supplierRef;
    final orderTotal = widget.purchaseState.amountGrandTotalCost ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /*   // Supplier Credit Info (if applicable)
            if (supplierCreditLimit != null && supplierCreditLimit > 0)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.credit_score, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Supplier Credit Limit',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          Text(
                            '\$${supplierCreditLimit.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          if (isCreditSelected && orderTotal > supplierCreditLimit)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Warning: Order exceeds credit limit by \$${(orderTotal - supplierCreditLimit).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),*/

            // Payment Type Selection
            _buildPaymentTypeSelector(),
            const SizedBox(height: 16),

            // Payment Term (only for credit)
            if (isCreditSelected) ...[
              _buildPaymentTermField(),
              const SizedBox(height: 16),

              // Due Date Display
              if (_creditDueDate != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Credit Due Date',
                              style: TextStyle(fontSize: 12),
                            ),
                            Text(
                              '${_creditDueDate!.year}-${_creditDueDate!.month.toString().padLeft(2, '0')}-${_creditDueDate!.day.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _selectDueDate,
                        child: const Text('Change'),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
            ],

            // Payment Instrument
            BlocBuilder<UdcDetailsBloc, UdcDetailsState>(
              builder: (context, udcState) {
                final paymentInstruments = udcState.details
                    .where((udc) => udc.udcGroup == 'PI')
                    .toList();

                return CustomDropdown<int>(
                  labelText: 'Payment Instrument',
                  value: _selectedPaymentInstrument,
                  items: paymentInstruments.map((udc) {
                    return DropdownMenuItem<int>(
                      value: udc.id,
                      child: Text(udc.description1 ?? udc.detailCode ?? ''),
                    );
                  }).toList(),
                  onChanged: _onPaymentInstrumentSelected,
                  validator: (value) {
                    if (value == null) {
                      return 'Please select payment instrument';
                    }
                    return null;
                  },
                  prefixIcon: const Icon(Icons.credit_card),
                );
              },
            ),
            const SizedBox(height: 16),

            // Payment Action (Save/Complete Purchase Order)
            PurchasePaymentAction(
              purchaseState: widget.purchaseState,
              formKey: _formKey,
              isCreditSelected: isCreditSelected,
              hasPaymentInstrument: _selectedPaymentInstrument != null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentTypeSelector() {
    const paymentTypes = ['Cash', 'Credit', 'Advance', 'Bank Transfer'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Type',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: paymentTypes.map((type) {
            final isSelected = _selectedPaymentType == type;
            return ChoiceChip(
              label: Text(
                type,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF155888),
                  fontWeight: FontWeight.w500,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => _onPaymentTypeSelected(type),
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF155888),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF155888)
                      : Colors.grey.shade300,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPaymentTermField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _paymentTermController,
                labelText: 'Payment Term (Days)',
                hintText: 'Enter number of days',
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.calendar_today),
                validator: (value) {
                  if (_selectedPaymentType == 'Credit') {
                    if (value == null || value.isEmpty) {
                      return 'Payment term is required for credit';
                    }
                    final term = int.tryParse(value);
                    if (term == null || term <= 0) {
                      return 'Enter valid number of days';
                    }
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _selectDueDate,
              icon: const Icon(Icons.calendar_month),
              label: const Text('Select Date'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Enter number of days or select due date',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}
