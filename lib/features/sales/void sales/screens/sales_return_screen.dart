// features/sales/sales_return/ui/sales_return_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:savvy_stock/core/widgets/custom_dropdown.dart';
import 'package:savvy_stock/core/widgets/custom_text_Form.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/sales/void%20sales/bloc/sales_return_bloc.dart';
import 'package:savvy_stock/features/sales/void%20sales/bloc/sales_return_event.dart';
import 'package:savvy_stock/features/sales/void%20sales/bloc/sales_return_state.dart';
import 'package:savvy_stock/features/sales/void%20sales/models/void_sales_details.dart';
import 'package:savvy_stock/features/sales/void%20sales/models/void_sales_header.dart';
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Iconsax.search_normal, color: Color(0xFF155888)),
            SizedBox(width: 8),
            Text('Filter Sales Order'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              labelText: 'FS Number',
              controller: _fsNumberController,
              prefixIcon: const Icon(Iconsax.document),
              hintText: 'Enter FS Number',
            ),
            const SizedBox(height: 16),
            CustomTextField(
              labelText: 'Invoice Number',
              controller: _invoiceNumberController,
              prefixIcon: const Icon(Iconsax.receipt),
              hintText: 'Enter Invoice Number',
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _searchSalesOrder();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF155888),
            ),
            child: const Text('Search', style: TextStyle(color: Colors.white)),
          ),
        ],
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
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _submitReturn(returnHeader, state.createDetails);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF155888),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Return'),
        backgroundColor: const Color(0xFF155888),
        elevation: 0,
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
                  ),
                );
                _clearForm();
              } else if (state.status == SalesReturnStatus.failure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.errorMessage ?? 'An error occurred'),
                    backgroundColor: Colors.red,
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
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Search Section
                          _buildSearchSection(),
                          const SizedBox(height: 24),

                          // Order Details Section
                          if (state.selectedHeader != null) ...[
                            _buildOrderDetailsSection(state),
                            const SizedBox(height: 24),
                          ],

                          // Return Details Section
                          if (state.selectedHeader != null) ...[
                            _buildReturnDetailsSection(),
                            const SizedBox(height: 24),
                          ],

                          // Items Section
                          if (state.createDetails.isNotEmpty) ...[
                            _buildItemsSection(state.createDetails),
                            const SizedBox(height: 24),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                // Bottom Action Buttons
                if (state.selectedHeader != null &&
                    state.createDetails.isNotEmpty)
                  _buildBottomActions(state),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Iconsax.search_normal, size: 20, color: Color(0xFF155888)),
                SizedBox(width: 8),
                Text(
                  'Search Sales Order',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showFilterDialog,
                    icon: const Icon(Iconsax.filter, size: 18),
                    label: const Text('Filter Sales Order'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _clearForm,
                    icon: const Icon(Iconsax.trash, size: 18),
                    label: const Text('Clear All'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
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

  Widget _buildOrderDetailsSection(SalesReturnState state) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Iconsax.document, size: 20, color: Color(0xFF155888)),
                SizedBox(width: 8),
                Text(
                  'Order Details',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 600;
                return GridView.count(
                  crossAxisCount: isWide ? 2 : 1,
                  shrinkWrap: true,
                  childAspectRatio: isWide ? 6 : 4,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    CustomTextField(
                      labelText: 'Customer Bill To',
                      controller: _customerBillToController,
                      readOnly: true,
                      prefixIcon: const Icon(Iconsax.user),
                    ),
                    CustomTextField(
                      labelText: 'Customer Ship To',
                      controller: _customerShipToController,
                      readOnly: true,
                      prefixIcon: const Icon(Iconsax.user),
                    ),
                    CustomTextField(
                      labelText: 'FS Number',
                      controller: _fsNumberController,
                      readOnly: true,
                      prefixIcon: const Icon(Iconsax.document),
                    ),
                    CustomTextField(
                      labelText: 'Order Date',
                      controller: _orderDateController,
                      readOnly: true,
                      prefixIcon: const Icon(Iconsax.calendar),
                    ),
                    CustomTextField(
                      labelText: 'Order Number',
                      controller: _orderNumberController,
                      readOnly: true,
                      prefixIcon: const Icon(Iconsax.hashtag),
                    ),
                    CustomTextField(
                      labelText: 'Tax',
                      controller: _taxController,
                      readOnly: true,
                      prefixIcon: const Icon(Iconsax.receipt),
                    ),
                    CustomTextField(
                      labelText: 'With Hold',
                      controller: _withholdAmountController,
                      readOnly: true,
                      prefixIcon: const Icon(Iconsax.money),
                    ),
                    CustomTextField(
                      labelText: 'Total Amount',
                      controller: _totalAmountController,
                      readOnly: true,
                      prefixIcon: const Icon(Iconsax.dollar_circle),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReturnDetailsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Iconsax.arrow_swap, size: 20, color: Color(0xFF155888)),
                SizedBox(width: 8),
                Text(
                  'Return Details',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 600;
                return GridView.count(
                  crossAxisCount: isWide ? 2 : 1,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: isWide ? 4 : 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    BlocBuilder<UdcDetailsBloc, UdcDetailsState>(
                      builder: (context, state) {
                        final returnReasons = state.details
                            .where((udc) => udc.udcGroup == 'SR')
                            .toList();

                        return CustomDropdown(
                          labelText: 'Reason *',
                          value: _selectedReturnReason,
                          prefixIcon: const Icon(Iconsax.info_circle),
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
                            if (value == null) return 'Reason must be selected';
                            return null;
                          },
                        );
                      },
                    ),
                    CustomTextField(
                      labelText: 'Return Date',
                      controller: _returnDateController,
                      readOnly: true,
                      prefixIcon: const Icon(Iconsax.calendar),
                      suffixIcon: IconButton(
                        icon: const Icon(Iconsax.calendar),
                        onPressed: _selectReturnDate,
                      ),
                      onTap: _selectReturnDate,
                    ),
                    if (!(MediaQuery.of(context).size.width > 600)) ...[
                      const SizedBox.shrink(),
                    ] else ...[
                      const SizedBox.shrink(),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              labelText: 'Comment',
              controller: _commentController,
              prefixIcon: const Icon(Iconsax.message_text),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsSection(List<SalesReturnDetails> items) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Iconsax.box, size: 20, color: Color(0xFF155888)),
                SizedBox(width: 8),
                Text(
                  'Items to Return',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return _buildItemCard(item, index);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(SalesReturnDetails item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
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
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Item ${index + 1}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF155888),
                  ),
                ),
              ),
              const Spacer(),
              if (item.itemsTableId != null)
                Text(
                  'ID: ${item.itemsTableId}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Item Details Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 400;
              return GridView.count(
                crossAxisCount: isWide ? 2 : 1,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: isWide ? 4 : 2.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 8,
                children: [
                  _buildItemDetailRow(
                    'Description',
                    item.itemEntryRef?.itemDescription ?? 'N/A',
                    Iconsax.box,
                  ),
                  _buildItemDetailRow(
                    'Branch',
                    item.itemInBranch.toString() ?? 'N/A',
                    Iconsax.building,
                  ),
                  _buildItemDetailRow(
                    'UOM',
                    item.unitOfMeasureRef?.description1 ?? 'N/A',
                    Iconsax.rulerpen,
                  ),
                  _buildItemDetailRow(
                    'Quantity',
                    item.quantity?.toStringAsFixed(2) ?? '0.00',
                    Iconsax.weight,
                  ),
                  _buildItemDetailRow(
                    'Unit Price',
                    '\$${item.unitPrice?.toStringAsFixed(2) ?? '0.00'}',
                    Iconsax.dollar_circle,
                  ),
                  _buildItemDetailRow(
                    'Total Price',
                    '\$${item.extendedPrice?.toStringAsFixed(2) ?? '0.00'}',
                    Iconsax.dollar_square,
                    isTotal: true,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildItemDetailRow(
    String label,
    String value,
    IconData icon, {
    bool isTotal = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isTotal
            ? const Color(0xFF155888).withOpacity(0.05)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: isTotal ? const Color(0xFF155888) : Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(SalesReturnState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 8,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _clearForm,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: Theme.of(context).primaryColor),
              ),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: state.status == SalesReturnStatus.submitting
                  ? null
                  : _processReturn,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF155888),
                padding: const EdgeInsets.symmetric(vertical: 12),
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
                      style: TextStyle(color: Colors.white),
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
          header.customerBillToRef?.customerName ?? 'N/A';
      _customerShipToController.text =
          header.customerTableIdRef?.customerName ?? 'N/A';
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
