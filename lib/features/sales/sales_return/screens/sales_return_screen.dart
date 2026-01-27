// features/sales/sales_return/ui/sales_return_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:savvy_stock/core/widgets/custom_dropdown.dart';
import 'package:savvy_stock/core/widgets/custom_text_Form.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/sales/sales_return/bloc/sales_return_bloc.dart';
import 'package:savvy_stock/features/sales/sales_return/bloc/sales_return_event.dart';
import 'package:savvy_stock/features/sales/sales_return/bloc/sales_return_state.dart';
import 'package:savvy_stock/features/sales/sales_return/models/void_sales_details.dart';
import 'package:savvy_stock/features/sales/sales_return/models/void_sales_header.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_bloc.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_event.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_state.dart';

class SalesReturnScreen extends StatefulWidget {
  final AuthBloc authBloc;

  const SalesReturnScreen({super.key, required this.authBloc});

  @override
  State<SalesReturnScreen> createState() => _SalesReturnScreen();
}

class _SalesReturnScreen extends State<SalesReturnScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _fsNumberController = TextEditingController();
  final TextEditingController _invoiceNumberController =
      TextEditingController();
  final TextEditingController _customerBillToController =
      TextEditingController();
  final TextEditingController _customerShipToController =
      TextEditingController();
  final TextEditingController _orderDateController = TextEditingController();
  final TextEditingController _orderNumberController = TextEditingController();
  final TextEditingController _taxController = TextEditingController();
  final TextEditingController _withholdAmountController =
      TextEditingController();
  final TextEditingController _totalAmountController = TextEditingController();
  final TextEditingController _returnDateController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();

  // Dropdown values
  int? _selectedReturnReason;

  // Date values
  DateTime? _returnDate;

  @override
  void initState() {
    super.initState();

    // Load initial data
    context.read<UdcDetailsBloc>().add(LoadAllUdcDetails());

    // Set default return date to today
    _returnDate = DateTime.now();
    _updateReturnDateController();
  }

  void _updateReturnDateController() {
    _returnDateController.text = _returnDate != null
        ? '${_returnDate!.month.toString().padLeft(2, '0')}/${_returnDate!.day.toString().padLeft(2, '0')}/${_returnDate!.year}'
        : '';
  }

  void _selectReturnDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _returnDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _returnDate = picked;
        _updateReturnDateController();
      });
    }
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filter Sales Order',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  labelText: 'FS Number',
                  controller: _fsNumberController,
                  prefixIcon: const Icon(Iconsax.document, size: 20),
                  hintText: 'Enter FS Number',
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  labelText: 'Invoice Number',
                  controller: _invoiceNumberController,
                  prefixIcon: const Icon(Iconsax.receipt, size: 20),
                  hintText: 'Enter Invoice Number',
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _searchSalesOrder();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF155888),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Search',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _searchSalesOrder() {
    final fsNumber = _fsNumberController.text.trim();
    final invoiceNumber = _invoiceNumberController.text.trim();

    if (fsNumber.isEmpty && invoiceNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter FS Number or Invoice Number'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    context.read<SalesReturnBloc>().add(
      LoadSalesReturnByFsNumber(
        fsNumber: fsNumber,
        companyId: widget.authBloc.state.companyId!,
      ),
    );
  }

  void _processReturn() {
    if (_selectedReturnReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Return reason must be selected'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final state = context.read<SalesReturnBloc>().state;
    final returnHeader = state.selectedHeader?.copyWith(
      returnStatus: _selectedReturnReason,
      commentForReturn: _commentController.text.trim(),
      returnDate: _returnDate,
    );

    if (returnHeader != null && state.createDetails.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Iconsax.warning_2, color: Colors.orange),
              SizedBox(width: 8),
              Text('Confirmation'),
            ],
          ),
          content: const Text('Do you want to proceed with the return?'),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _submitReturn(returnHeader, state.createDetails);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF155888),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Yes', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }

  void _submitReturn(
    SalesReturnHeader header,
    List<SalesReturnDetails> details,
  ) {
    context.read<SalesReturnBloc>().add(
      SubmitSalesReturn(
        header: header,
        details: details,
        returnReason: _selectedReturnReason.toString(),
      ),
    );
    context.read<SalesReturnBloc>().add(ResetSalesReturnState());
    context.read<SalesReturnBloc>().add(
      LoadSalesReturns(companyId: widget.authBloc.state.companyId!),
    );
    Navigator.pop(context);
  }

  void _clearForm() {
    setState(() {
      _fsNumberController.clear();
      _invoiceNumberController.clear();
      _customerBillToController.clear();
      _customerShipToController.clear();
      _orderDateController.clear();
      _orderNumberController.clear();
      _taxController.clear();
      _withholdAmountController.clear();
      _totalAmountController.clear();
      _commentController.clear();
      _selectedReturnReason = null;
      _returnDate = DateTime.now();
      _updateReturnDateController();
    });

    context.read<SalesReturnBloc>().add(ResetSalesReturnState());
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 400;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sales Return',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF155888),
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.filter),
            onPressed: _showFilterDialog,
            tooltip: 'Filter Sales Order',
          ),
        ],
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<SalesReturnBloc, SalesReturnState>(
            listener: (context, state) {
              if (state.status == SalesReturnStatus.success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      state.successMessage ?? 'Return processed successfully',
                    ),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
                _clearForm();
              } else if (state.status == SalesReturnStatus.failure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.errorMessage ?? 'An error occurred'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              }
            },
          ),
        ],
        child: BlocBuilder<SalesReturnBloc, SalesReturnState>(
          builder: (context, state) {
            // Auto-fill form when sales order is loaded
            if (state.selectedHeader != null &&
                _customerBillToController.text.isEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _autoFillForm(state.selectedHeader!);
              });
            }

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Search Section - Modern Card
                          _buildSearchSection(),
                          const SizedBox(height: 16),

                          // Order Details Section - Compact Card
                          if (state.selectedHeader != null) ...[
                            _buildCompactOrderDetailsSection(
                              state,
                              isSmallScreen,
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Return Details Section
                          if (state.selectedHeader != null) ...[
                            _buildReturnDetailsSection(isSmallScreen),
                            const SizedBox(height: 16),
                          ],

                          // Items Section
                          if (state.createDetails.isNotEmpty) ...[
                            _buildItemsSection(state.createDetails),
                            const SizedBox(height: 16),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                // Bottom Action Buttons - Sticky
                if (state.selectedHeader != null &&
                    state.createDetails.isNotEmpty)
                  _buildBottomActions(state, isSmallScreen),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Search Sales Order',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF155888),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _showFilterDialog,
                    icon: const Icon(Iconsax.filter, size: 18),
                    label: const Text('Filter'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF155888),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _clearForm,
                    icon: const Icon(Iconsax.trash, size: 18),
                    label: const Text('Clear'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactOrderDetailsSection(
    SalesReturnState state,
    bool isSmallScreen,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF155888).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Iconsax.document,
                    size: 20,
                    color: Color(0xFF155888),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Order Details',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Compact two-column layout for mobile
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isSmallScreen ? 1 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: isSmallScreen ? 4 : 3,
              ),
              itemCount: 8, // Number of fields to show
              itemBuilder: (context, index) {
                switch (index) {
                  case 0:
                    return _buildCompactField(
                      'Customer Bill To',
                      _customerBillToController.text,
                      Iconsax.user,
                    );
                  case 1:
                    return _buildCompactField(
                      'Customer Ship To',
                      _customerShipToController.text,
                      Iconsax.user,
                    );
                  case 2:
                    return _buildCompactField(
                      'FS Number',
                      _fsNumberController.text,
                      Iconsax.document,
                    );
                  case 3:
                    return _buildCompactField(
                      'Order Date',
                      _orderDateController.text,
                      Iconsax.calendar,
                    );
                  case 4:
                    return _buildCompactField(
                      'Order Number',
                      _orderNumberController.text,
                      Iconsax.hashtag,
                    );
                  case 5:
                    return _buildCompactField(
                      'Payment Method',
                      state.selectedHeader?.paymentMethod ?? '',
                      Iconsax.card,
                    );
                  case 6:
                    return _buildCompactField(
                      'Tax',
                      _taxController.text,
                      Iconsax.receipt,
                    );
                  case 7:
                    return _buildCompactField(
                      'Total Amount',
                      _totalAmountController.text,
                      Iconsax.dollar_circle,
                      isAmount: true,
                    );
                  default:
                    return const SizedBox();
                }
              },
            ),

            // Show more details button
            if (state.selectedHeader != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => _showOrderDetailsBottomSheet(state),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('View All Details'),
                    SizedBox(width: 8),
                    Icon(Iconsax.arrow_down, size: 16),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompactField(
    String label,
    String value,
    IconData icon, {
    bool isAmount = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value.isNotEmpty ? value : '-',
            style: TextStyle(
              fontSize: 14,
              fontWeight: isAmount ? FontWeight.w600 : FontWeight.w500,
              color: isAmount ? const Color(0xFF155888) : Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showOrderDetailsBottomSheet(SalesReturnState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Order Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildDetailRow(
                      'Customer Bill To',
                      _customerBillToController.text,
                    ),
                    _buildDetailRow(
                      'Customer Ship To',
                      _customerShipToController.text,
                    ),
                    _buildDetailRow('FS Number', _fsNumberController.text),
                    _buildDetailRow('Order Date', _orderDateController.text),
                    _buildDetailRow(
                      'Order Number',
                      _orderNumberController.text,
                    ),
                    _buildDetailRow(
                      'Payment Method',
                      state.selectedHeader?.paymentMethod ?? '',
                    ),
                    _buildDetailRow(
                      'Payment Instrument',
                      state
                              .selectedHeader
                              ?.paymentInstrumentRef
                              ?.description1 ??
                          '',
                    ),
                    _buildDetailRow(
                      'Order Type',
                      state.selectedHeader?.orderType?.toString() ?? '',
                    ),
                    _buildDetailRow('Tax', _taxController.text),
                    _buildDetailRow(
                      'With Hold',
                      _withholdAmountController.text,
                    ),
                    _buildDetailRow(
                      'Total Amount',
                      _totalAmountController.text,
                      isAmount: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isAmount = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value.isNotEmpty ? value : '-',
              style: TextStyle(
                fontSize: 14,
                fontWeight: isAmount ? FontWeight.w600 : FontWeight.normal,
                color: isAmount ? const Color(0xFF155888) : Colors.black87,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReturnDetailsSection(bool isSmallScreen) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF155888).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Iconsax.arrow_swap,
                    size: 20,
                    color: Color(0xFF155888),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Return Details',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            BlocBuilder<UdcDetailsBloc, UdcDetailsState>(
              builder: (context, state) {
                final returnReasons = state.details
                    .where((udc) => udc.udcGroup == 'SR')
                    .toList();

                return CustomDropdown(
                  labelText: 'Reason *',
                  value: _selectedReturnReason,
                  prefixIcon: const Icon(Iconsax.info_circle, size: 20),
                  items: returnReasons.map((reason) {
                    return DropdownMenuItem<int>(
                      value: reason.id,
                      child: Text(reason.description1),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedReturnReason = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Reason must be selected';
                    }
                    return null;
                  },
                );
              },
            ),
            const SizedBox(height: 12),
            CustomTextField(
              labelText: 'Return Date',
              controller: _returnDateController,
              readOnly: true,
              prefixIcon: const Icon(Iconsax.calendar, size: 20),
              suffixIcon: IconButton(
                icon: const Icon(Iconsax.calendar, size: 20),
                onPressed: _selectReturnDate,
              ),
              onTap: _selectReturnDate,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              labelText: 'Comment',
              controller: _commentController,
              prefixIcon: const Icon(Iconsax.message_text, size: 20),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsSection(List<SalesReturnDetails> items) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF155888).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Iconsax.box,
                    size: 20,
                    color: Color(0xFF155888),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Items to Return',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF155888).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${items.length} items',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF155888),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return _buildCompactItemCard(item, index);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactItemCard(SalesReturnDetails item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF155888).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Item ${index + 1}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF155888),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.itemEntryRef?.itemDescription ?? 'N/A',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Item Details - Grid Layout
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 3,
            children: [
              _buildItemDetailChip(
                'Branch',
                item.itemInBranchRef?.branchRef?.description.toString() ??
                    'N/A',
                Iconsax.building,
              ),
              _buildItemDetailChip(
                'UOM',
                item.unitOfMeasureRef?.description1 ?? 'N/A',
                Iconsax.rulerpen,
              ),
              _buildItemDetailChip(
                'Qty',
                item.quantity?.toStringAsFixed(2) ?? '0.00',
                Iconsax.weight,
              ),
              _buildItemDetailChip(
                'Price',
                '\$${item.unitPrice?.toStringAsFixed(2) ?? '0.00'}',
                Iconsax.dollar_circle,
              ),
            ],
          ),

          // Total Price
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF155888).withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Iconsax.dollar_square,
                  size: 16,
                  color: Color(0xFF155888),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Total:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF155888),
                  ),
                ),
                const Spacer(),
                Text(
                  '\$${item.extendedPrice?.toStringAsFixed(2) ?? '0.00'}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF155888),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemDetailChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(SalesReturnState state, bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 12,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: isSmallScreen
          ? Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: state.status == SalesReturnStatus.submitting
                        ? null
                        : _processReturn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF155888),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: state.status == SalesReturnStatus.submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text(
                            'Process Return',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _clearForm,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _clearForm,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: state.status == SalesReturnStatus.submitting
                        ? null
                        : _processReturn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF155888),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: state.status == SalesReturnStatus.submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text(
                            'Process Return',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
    );
  }

  void _autoFillForm(SalesReturnHeader header) {
    setState(() {
      _customerBillToController.text =
          header.customerBillToRef?.customerName ??
          header.customerBillTo.toString();
      _customerShipToController.text =
          header.customerTableIdRef?.customerName ??
          header.customerTableId.toString();
      _fsNumberController.text = header.fsNumber ?? '';
      _orderDateController.text = header.orderDate != null
          ? '${header.orderDate!.month.toString().padLeft(2, '0')}/${header.orderDate!.day.toString().padLeft(2, '0')}/${header.orderDate!.year}'
          : '';
      _orderNumberController.text = header.orderNumber?.toString() ?? '';
      _taxController.text = header.tax?.toStringAsFixed(2) ?? '0.00';
      _withholdAmountController.text =
          header.withholdAmount?.toStringAsFixed(2) ?? '0.00';
      _totalAmountController.text =
          header.amountTotal?.toStringAsFixed(2) ?? '0.00';
    });
  }

  @override
  void dispose() {
    _fsNumberController.dispose();
    _invoiceNumberController.dispose();
    _customerBillToController.dispose();
    _customerShipToController.dispose();
    _orderDateController.dispose();
    _orderNumberController.dispose();
    _taxController.dispose();
    _withholdAmountController.dispose();
    _totalAmountController.dispose();
    _returnDateController.dispose();
    _commentController.dispose();
    super.dispose();
  }
}
