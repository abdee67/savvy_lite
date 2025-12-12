// features/purchase/purchase_entry/ui/credit_payment/credit_payment_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:savvy_stock/core/widgets/custom_dropdown.dart';
import 'package:savvy_stock/core/widgets/custom_text_form.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/bloc/purchase_order_bloc.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/bloc/purchase_order_event.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/bloc/purchase_order_state.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/models/credit_payment_model.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/models/purchase_order_header_model.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_bloc.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_event.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_state.dart';

class CreditPaymentScreen extends StatefulWidget {
  final PurchaseOrderHeader? purchaseOrderHeader;
  final int? companyId;

  const CreditPaymentScreen({
    super.key,
    this.purchaseOrderHeader,
    this.companyId,
  });

  @override
  State<CreditPaymentScreen> createState() => _CreditPaymentScreenState();
}

class _CreditPaymentScreenState extends State<CreditPaymentScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late CreditPayment _creditPayment;
  final TextEditingController _paymentAmountController =
      TextEditingController();
  final TextEditingController _referenceNumberController =
      TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  DateTime _datePayment = DateTime.now();
  int? _selectedPaymentInstrument;
  bool _isLoading = false;
  bool _isEditing = false;
  bool _showSuccessMessage = false;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _resetForm();
  }

  void _resetForm() {
    setState(() {
      _paymentAmountController.clear();
      _referenceNumberController.clear();
      _notesController.clear();
      _datePayment = DateTime.now();
      _selectedPaymentInstrument = null;
      _isLoading = false;
      _isEditing = false;
      _showSuccessMessage = false;
      _successMessage = null;

      // Reset credit payment object
      final authBloc = context.read<AuthBloc>();
      final userId = authBloc.state.userId?.id;

      if (widget.purchaseOrderHeader != null) {
        _creditPayment = CreditPayment(
          poHeader: widget.purchaseOrderHeader!.id,
          paymentAmount: 0.0,
          datePayment: _datePayment,
          company: widget.purchaseOrderHeader!.company,
          userId: userId,
          dateUpdated: DateTime.now(),
        );
      } else {
        // Get the latest selected header from state
        final state = context.read<PurchaseOrderBloc>().state;
        final selectedHeader = state.selectedHeader;

        _creditPayment = CreditPayment(
          poHeader: selectedHeader?.id,
          paymentAmount: 0.0,
          datePayment: _datePayment,
          company: selectedHeader?.company ?? widget.companyId,
          userId: userId,
          dateUpdated: DateTime.now(),
        );
      }
    });
    context.read<UdcDetailsBloc>().add(LoadUdcDetailsByGroup('PI'));
  }

  void _onPaymentAmountChanged(String value) {
    final amount = double.tryParse(value) ?? 0.0;
    setState(() {
      _creditPayment = _creditPayment.copyWith(paymentAmount: amount);
    });
  }

  void _onPaymentInstrumentSelected(int? instrument) {
    setState(() {
      _selectedPaymentInstrument = instrument;
      _creditPayment = _creditPayment.copyWith(paymentInstrument: instrument);
    });
  }

  void _ondatePaymentSelected() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _datePayment,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null && pickedDate != _datePayment) {
      setState(() {
        _datePayment = pickedDate;
        _creditPayment = _creditPayment.copyWith(datePayment: pickedDate);
      });
    }
  }

  Future<void> _saveCreditPayment() async {
    if (_formKey.currentState?.validate() ?? false) {
      // Validate payment amount
      if (_creditPayment.paymentAmount! <= 0) {
        _showError('Payment amount must be greater than 0');
        return;
      }

      // Check if payment amount exceeds open credit
      final purchaseOrderBloc = context.read<PurchaseOrderBloc>();
      final purchaseState = purchaseOrderBloc.state;
      final header = widget.purchaseOrderHeader ?? purchaseState.selectedHeader;

      if (header == null) {
        _showError('No purchase order selected');
        return;
      }

      final amountRemain =
          (header.amountOpenCredit ?? 0.0) - _creditPayment.paymentAmount!;
      if (amountRemain < 0) {
        _showError(
          'Payment amount exceeds open credit of ${header.amountOpenCredit?.toStringAsFixed(2)} ETB',
        );
        return;
      }

      setState(() {
        _isLoading = true;
        _showSuccessMessage = false;
        _successMessage = null;
      });

      // Update the credit payment with form data
      final updatedPayment = _creditPayment.copyWith(
        paymentInstrument: _selectedPaymentInstrument,
        dateUpdated: DateTime.now(),
      );

      // Dispatch save event
      final companyId = header.company ?? widget.companyId;
      if (companyId != null) {
        purchaseOrderBloc.add(
          SaveCreditPayment(payment: updatedPayment, companyId: companyId),
        );
      } else {
        _showError('Company ID not found');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _cancelCreditPayment() {
    // Clear selected credit payment
    context.read<PurchaseOrderBloc>().add(
      SelectCreditPayment(payment: CreditPayment()),
    );

    // Navigate back
    context.pop();
  }

  void _prepareForNewPayment() {
    _resetForm();
    _formKey.currentState?.reset();

    // Show success message for previous payment
    if (_successMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_successMessage!),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _makeAnotherPayment() {
    // First save current payment
    _saveCreditPayment();
  }

  @override
  void dispose() {
    _paymentAmountController.dispose();
    _referenceNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final purchaseOrderState = context.watch<PurchaseOrderBloc>().state;
    final authState = context.watch<AuthBloc>().state;

    // Get the current header (either from props or from state)
    final header =
        widget.purchaseOrderHeader ?? purchaseOrderState.selectedHeader;

    // If no header is selected, show error
    if (header == null) {
      return _buildErrorDialog('No purchase order selected');
    }

    // Check if this is a credit purchase
    if (header.paymentTerm == null) {
      return _buildErrorDialog('Selected order is not a credit purchase');
    }

    // Check if there's open credit
    if (header.amountOpenCredit == null || header.amountOpenCredit! <= 0) {
      return _buildErrorDialog('No open credit available for payment');
    }

    return BlocListener<PurchaseOrderBloc, PurchaseOrderState>(
      listener: (context, state) {
        // Handle credit payment success
        if (state.creditPaymentSuccess == true &&
            state.successMessage != null) {
          setState(() {
            _isLoading = false;
            _showSuccessMessage = true;
            _successMessage = state.successMessage;
          });

          // Reset form for next payment
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _prepareForNewPayment();
            }
          });
        }
        // Handle credit payment error
        else if (state.creditPaymentError != null) {
          setState(() {
            _isLoading = false;
            _showSuccessMessage = false;
          });

          _showError(state.creditPaymentError!);
        }
      },
      child: Dialog(
        insetPadding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 700),
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                _showSuccessMessage ? 'Payment Successful' : 'Credit Payment',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: _showSuccessMessage
                  ? Colors.green
                  : const Color(0xFF155888),
              foregroundColor: Colors.white,
              automaticallyImplyLeading: false,
              actions: [
                if (_showSuccessMessage)
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _prepareForNewPayment,
                    tooltip: 'Make Another Payment',
                  ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _cancelCreditPayment,
                  tooltip: 'Close',
                ),
              ],
            ),
            body: _showSuccessMessage
                ? _buildSuccessView()
                : _buildPaymentForm(header, purchaseOrderState, authState),
            bottomNavigationBar: _showSuccessMessage
                ? null
                : _buildBottomNavigationBar(),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, size: 80, color: Colors.green),
          const SizedBox(height: 20),
          Text(
            _successMessage ?? 'Payment Successful',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            'The payment has been recorded successfully.',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _prepareForNewPayment,
                icon: const Icon(Icons.add),
                label: const Text('Make Another Payment'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _cancelCreditPayment,
                icon: const Icon(Icons.check),
                label: const Text('Done'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF155888),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentForm(
    PurchaseOrderHeader header,
    PurchaseOrderState purchaseOrderState,
    authState,
  ) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderInfoSection(header),

              const SizedBox(height: 24),
              const Text(
                'Payment Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF155888),
                ),
              ),
              const SizedBox(height: 16),

              _buildPaymentDetailsForm(header),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorDialog(String message) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error, size: 60, color: Colors.red),
            const SizedBox(height: 20),
            Text(
              message,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderInfoSection(PurchaseOrderHeader header) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.receipt, color: Color(0xFF155888)),
                const SizedBox(width: 8),
                Text(
                  'Order Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildInfoColumn1(header)),
                const SizedBox(width: 24),
                Expanded(child: _buildInfoColumn2(header)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn1(PurchaseOrderHeader header) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(
          icon: Icons.numbers,
          label: 'Order No.',
          value: header.orderNumber?.toString() ?? 'N/A',
        ),
        const SizedBox(height: 12),
        _buildInfoRow(
          icon: Icons.business,
          label: 'Supplier',
          value: header.supplierRef?.supplierName ?? 'N/A',
        ),
        const SizedBox(height: 12),
        _buildInfoRow(
          icon: Icons.attach_money,
          label: 'Total Amount in ETB',
          value: header.amountGrandTotalCost?.toStringAsFixed(2) ?? '0.00',
        ),
      ],
    );
  }

  Widget _buildInfoColumn2(PurchaseOrderHeader header) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(
          icon: Icons.money_off,
          label: 'Remaining Amount in ETB',
          value: header.amountOpenCredit?.toStringAsFixed(2) ?? '0.00',
          valueColor:
              header.amountOpenCredit != null && header.amountOpenCredit! > 0
              ? Colors.red.shade700
              : Colors.green.shade700,
        ),
        const SizedBox(height: 12),
        _buildInfoRow(
          icon: Icons.calendar_today,
          label: 'Date Transaction',
          value: header.dateTransaction != null
              ? DateFormat('MM/dd/yyyy').format(header.dateTransaction!)
              : 'N/A',
        ),
        const SizedBox(height: 12),
        if (header.creditDueDate != null)
          _buildInfoRow(
            icon: Icons.event,
            label: 'Credit Due Date',
            value: DateFormat('MM/dd/yyyy').format(header.creditDueDate!),
            valueColor: header.creditDueDate!.isBefore(DateTime.now())
                ? Colors.red.shade700
                : Colors.green.shade700,
          ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentDetailsForm(PurchaseOrderHeader header) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.payment, color: Color(0xFF155888)),
                const SizedBox(width: 8),
                Text(
                  'Payment Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Payment Instrument Dropdown
            BlocBuilder<UdcDetailsBloc, UdcDetailsState>(
              builder: (context, udcState) {
                final paymentInstruments = udcState.details
                    .where((udc) => udc.udcGroup == 'PI')
                    .toList();

                return CustomDropdown<int>(
                  labelText: 'Payment Instrument *',
                  value: _selectedPaymentInstrument,
                  items: [
                    const DropdownMenuItem<int>(
                      value: null,
                      child: Text('Select Payment Instrument'),
                    ),
                    ...paymentInstruments.map((udc) {
                      return DropdownMenuItem<int>(
                        value: udc.id,
                        child: Text(udc.description1 ?? udc.detailCode ?? ''),
                      );
                    }).toList(),
                  ],
                  onChanged: _onPaymentInstrumentSelected,
                  validator: (value) {
                    if (value == null) {
                      return 'Please select payment instrument';
                    }
                    return null;
                  },
                  prefixIcon: const Icon(Icons.credit_card, size: 20),
                );
              },
            ),

            const SizedBox(height: 16),

            // Amount Paid Input
            CustomTextField(
              labelText: 'Amount Paid in ETB *',
              controller: _paymentAmountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: _onPaymentAmountChanged,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter payment amount';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Payment amount must be greater than 0';
                }

                if (amount > (header.amountOpenCredit ?? 0.0)) {
                  return 'Payment amount exceeds open credit of ${header.amountOpenCredit?.toStringAsFixed(2)} ETB';
                }
                return null;
              },
              prefixIcon: const Icon(Icons.attach_money, size: 20),
            ),

            const SizedBox(height: 16),

            // Payment Date Picker
            GestureDetector(
              onTap: _ondatePaymentSelected,
              child: AbsorbPointer(
                child: CustomTextField(
                  labelText: 'Date Paid *',
                  controller: TextEditingController(
                    text: DateFormat('MM/dd/yyyy').format(_datePayment),
                  ),
                  readOnly: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select payment date';
                    }
                    return null;
                  },
                  prefixIcon: const Icon(Icons.calendar_today, size: 20),
                  suffixIcon: const Icon(Icons.calendar_month, size: 20),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Help text
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, size: 16, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'After payment, the remaining credit amount will be updated automatically. '
                      'Payment status will change to "Paid" if remaining amount becomes 0.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _cancelCreditPayment,
              icon: const Icon(Icons.close),
              label: const Text('Cancel'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _saveCreditPayment,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.check),
              label: Text(_isLoading ? 'Saving...' : 'Save Payment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF155888),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
