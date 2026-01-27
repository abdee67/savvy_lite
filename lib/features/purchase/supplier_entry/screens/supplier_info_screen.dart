import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:savvy_stock/core/constants/app_routes.dart';
import 'package:savvy_stock/core/widgets/custom_text_Form.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/bloc/purchase_order_bloc.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/bloc/purchase_order_event.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/bloc/purchase_order_state.dart';

import 'package:savvy_stock/features/purchase/supplier_entry/blocs/supplier_bloc.dart';
import 'package:savvy_stock/features/purchase/supplier_entry/blocs/supplier_event.dart';
import 'package:savvy_stock/features/purchase/supplier_entry/blocs/supplier_state.dart';
import 'package:savvy_stock/features/purchase/supplier_entry/models/supplier_model.dart';
import 'package:savvy_stock/features/purchase/supplier_entry/widget/supplier_section.dart';

class SupplierInfoScreen extends StatelessWidget {
  final AuthBloc authBloc;
  final Map<String, dynamic>? extra;

  const SupplierInfoScreen({super.key, required this.authBloc, this.extra});

  @override
  Widget build(BuildContext context) {
    final companyId = authBloc.state.companyId;

    if (companyId != null) {
      Future.microtask(() {
        context.read<SupplierBloc>().add(LoadSuppliers(companyId));
      });
    }

    return SupplierInfoScreenContent(authBloc: authBloc, extra: extra);
  }
}

class SupplierInfoScreenContent extends StatefulWidget {
  final AuthBloc authBloc;
  final Map<String, dynamic>? extra;

  const SupplierInfoScreenContent({
    super.key,
    required this.authBloc,
    this.extra,
  });

  @override
  State<SupplierInfoScreenContent> createState() =>
      _SupplierInfoScreenContentState();
}

class _SupplierInfoScreenContentState extends State<SupplierInfoScreenContent> {
  static const _containerHeight = 20.0;
  static const _containerWidth = 20.0;
  static const _circularProgressStrokeWidth = 2.0;
  static const _elevatedButtonBorderRadius = 20.0;
  static const _horizontalPadding32 = 32.0;
  static const _verticalPadding12 = 12.0;
  static const _sizedBoxHeight16 = 16.0;
  static const _sizedBoxHeight8 = 8.0;
  static const _sizedBoxHeight20 = 20.0;
  static const _sizedBoxWidth16 = 16.0;
  static const _appBarFontSize = 25.0;
  static const _titleFontSize = 16.0;
  static const _detailLabelWidth = 100.0;
  static const _cardElevation = 2.0;
  static const _cardPadding = 16.0;
  static const _verticalDetailPadding = 4.0;

  final bool _isInitialized = false;
  bool _isOrderPrepared = false;
  late final TextEditingController _orderNumberController;
  late final TextEditingController _transactionDateController;
  late final TextEditingController _deliveryDateController;
  late final TextEditingController _invoiceNumberController;
  late final TextEditingController _receivingDateController;

  SupplierModel? _selectedSupplier;
  DateTime? _transactionDate;
  DateTime? _deliveryDate;
  DateTime? _receivingDate;

  @override
  void initState() {
    super.initState();
    _orderNumberController = TextEditingController();
    _transactionDateController = TextEditingController();
    _deliveryDateController = TextEditingController();
    _invoiceNumberController = TextEditingController();
    _receivingDateController = TextEditingController();

    // Set default dates
    final now = DateTime.now();
    _transactionDate = now;
    //_deliveryDate = now.add(const Duration(days: 7));
    _receivingDate = now;

    _updateDateControllers();

    Future.microtask(_initializeOrderPreparation);
  }

  void _initializeOrderPreparation() {
    final companyId = widget.authBloc.state.companyId;
    final userId = widget.authBloc.state.userId?.id;

    if (companyId != null && userId != null) {
      context.read<PurchaseOrderBloc>().add(
        PrepareCreatePurchaseOrder(companyId: companyId),
      );
    }
  }

  void _updateDateControllers() {
    _transactionDateController.text = _formatDate(_transactionDate);
    _deliveryDateController.text = _formatDate(_deliveryDate);
    _receivingDateController.text = _formatDate(_receivingDate);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _orderNumberController.dispose();
    _transactionDateController.dispose();
    _deliveryDateController.dispose();
    _invoiceNumberController.dispose();
    _receivingDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<PurchaseOrderBloc, PurchaseOrderState>(
          listenWhen: (previous, current) =>
              previous.status != current.status ||
              previous.lastOperation != current.lastOperation,
          listener: _handlePurchaseOrderStateChange,
        ),
      ],
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(context),
        body: SafeArea(
          child: BlocBuilder<SupplierBloc, SupplierState>(
            builder: (context, supplierState) {
              return BlocBuilder<PurchaseOrderBloc, PurchaseOrderState>(
                builder: (context, purchaseState) {
                  final isValid =
                      _selectedSupplier != null &&
                      purchaseState.selectedHeader != null;

                  return Stack(
                    children: [
                      _buildContent(purchaseState, isValid, supplierState),
                      if (purchaseState.status == PurchaseOrderStatus.loading &&
                          purchaseState.pendingOperations.contains(
                            'prepare_create_purchase_order',
                          ))
                        const _LoadingOverlay(),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _handlePurchaseOrderStateChange(
    BuildContext context,
    PurchaseOrderState purchaseState,
  ) {
    // Handle order preparation completion
    if (purchaseState.status == PurchaseOrderStatus.success &&
        purchaseState.lastOperation?.contains(
              'prepare_create_purchase_order',
            ) ==
            true) {
      setState(() {
        _isOrderPrepared = true;
      });

      // Update order number from state
      final orderNumber = purchaseState.selectedHeader?.orderNumber;
      if (orderNumber != null) {
        _orderNumberController.text = orderNumber.toString();
      }

      // Set initial dates from state
      final header = purchaseState.selectedHeader;
      if (header != null) {
        _transactionDate = header.dateTransaction ?? DateTime.now();
        _deliveryDate = header.dateDelivery ?? _deliveryDate;
        _updateDateControllers();
      }
    }

    // Handle errors
    if (purchaseState.status == PurchaseOrderStatus.error &&
        purchaseState.error != null) {
      _showErrorSnackBar(context, purchaseState.error!);
    }

    // Handle successful operations
    if (purchaseState.status == PurchaseOrderStatus.success &&
        purchaseState.successMessage != null) {
      _showSuccessSnackBar(context, purchaseState.successMessage!);
    }
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text(
        'Supplier & Order Information',
        style: TextStyle(
          color: Colors.white,
          fontSize: _appBarFontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: const Color(0xFF155888),
      elevation: 0,
      actions: [
        // Auto Receipt Toggle using state's autoReceipt field
        BlocBuilder<PurchaseOrderBloc, PurchaseOrderState>(
          builder: (context, state) {
            return Row(
              children: [
                Text(
                  'Auto Receipt',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Switch.adaptive(
                  value: state.autoReceipt ?? false,
                  activeColor: Colors.green,
                  inactiveThumbColor: Colors.grey,
                  onChanged: (value) {
                    context.read<PurchaseOrderBloc>().add(
                      SetPurchaseOrderAutoReceipt(autoReceipt: value),
                    );
                  },
                ),
                const SizedBox(width: 8),
              ],
            );
          },
        ),
        // Loading indicator
        BlocSelector<PurchaseOrderBloc, PurchaseOrderState, bool>(
          selector: (state) =>
              state.status == PurchaseOrderStatus.loading &&
              state.pendingOperations.contains('prepare_create_purchase_order'),
          builder: (context, isLoading) {
            if (!isLoading) return const SizedBox.shrink();

            return const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(
                child: SizedBox(
                  width: _containerWidth,
                  height: _containerHeight,
                  child: CircularProgressIndicator(
                    strokeWidth: _circularProgressStrokeWidth,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildContent(
    PurchaseOrderState purchaseState,
    bool isValid,
    SupplierState supplierState,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (purchaseState.status == PurchaseOrderStatus.loading &&
              purchaseState.pendingOperations.contains(
                'prepare_create_purchase_order',
              ))
            const _LoadingOverlay(),

          _buildSupplierSection(purchaseState, supplierState),
          const SizedBox(height: _sizedBoxHeight16),
          _buildOrderInformationSection(purchaseState),
          const SizedBox(height: _sizedBoxHeight20),
          if (_selectedSupplier != null ||
              purchaseState.selectedHeader?.supplierRef != null)
            _buildSupplierDetails(_selectedSupplier, purchaseState),
          const SizedBox(height: _sizedBoxHeight20),
          _buildNextButton(isValid, purchaseState),
          const SizedBox(height: _sizedBoxHeight20),
        ],
      ),
    );
  }

  Widget _buildSupplierSection(
    PurchaseOrderState purchaseState,
    SupplierState supplierState,
  ) {
    return Column(
      children: [
        SupplierSection(
          authBloc: context.read<AuthBloc>(),
          title: 'Supplier:',
          selectedSupplier: _selectedSupplier ?? SupplierModel.empty(),
          suppliers: supplierState.suppliers,
          onSupplierSelected: _handleSupplierSelected,
          showAddButton: true,
        ),
      ],
    );
  }

  void _handleSupplierSelected(SupplierModel supplier) {
    setState(() {
      _selectedSupplier = supplier;
    });

    // Update the purchase order header with supplier using existing UpdatePurchaseOrderHeader event
    final header = context.read<PurchaseOrderBloc>().state.selectedHeader;
    if (header != null) {
      final updatedHeader = header.copyWith(
        supplierId: supplier.id,
        supplierRef: supplier,
      );
      context.read<PurchaseOrderBloc>().add(
        UpdatePurchaseOrderHeader(header: updatedHeader),
      );
    }
  }

  Widget _buildOrderInformationSection(PurchaseOrderState purchaseState) {
    final header = purchaseState.selectedHeader;

    return Card(
      elevation: _cardElevation,
      child: Padding(
        padding: const EdgeInsets.all(_cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'PO Information:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: _titleFontSize,
                  ),
                ),
                // Auto receipt indicator using existing state field
                BlocBuilder<PurchaseOrderBloc, PurchaseOrderState>(
                  builder: (context, state) {
                    if (!(state.autoReceipt ?? false)) {
                      return const SizedBox.shrink();
                    }
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inventory,
                            size: 14,
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Auto Receipt',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: _sizedBoxHeight8),
            _buildOrderNumberField(purchaseState),
            const SizedBox(height: _sizedBoxHeight8),
            _buildTransactionDateField(purchaseState),
            const SizedBox(height: _sizedBoxHeight8),
            _buildDeliveryDateField(purchaseState),
            const SizedBox(height: _sizedBoxHeight8),
            _buildInvoiceNumberField(purchaseState),
            const SizedBox(height: _sizedBoxHeight8),
            // Show receiving date based on autoReceipt state
            BlocBuilder<PurchaseOrderBloc, PurchaseOrderState>(
              builder: (context, state) {
                if (state.autoReceipt != true) return const SizedBox.shrink();
                return Column(
                  children: [
                    _buildReceivingDateField(purchaseState),
                    const SizedBox(height: _sizedBoxHeight8),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderNumberField(PurchaseOrderState state) {
    final orderNumber = state.selectedHeader?.orderNumber ?? 0;
    if (orderNumber != 0 && _orderNumberController.text.isEmpty) {
      _orderNumberController.text = orderNumber.toString();
    }

    return Row(
      children: [
        Expanded(
          child: CustomTextField(
            controller: _orderNumberController,
            labelText: 'Purchase Order Number',
            readOnly: true,
            prefixIcon: Icon(Icons.numbers, color: Colors.blue.shade700),
          ),
        ),
        IconButton(
          icon: Icon(Icons.refresh, color: Colors.blue.shade700),
          tooltip: 'Generate New Number',
          onPressed: () {
            final companyId = widget.authBloc.state.companyId;
            if (companyId != null) {
              context.read<PurchaseOrderBloc>().add(
                GenerateNextOrderNumber(companyId: companyId),
              );
              // Listen for the updated order number
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final updatedState = context.read<PurchaseOrderBloc>().state;
                if (updatedState.nextOrderNumber != null) {
                  _orderNumberController.text = updatedState.nextOrderNumber
                      .toString();

                  // Update header with new order number using UpdatePurchaseOrderHeader
                  final header = updatedState.selectedHeader;
                  if (header != null) {
                    final updatedHeader = header.copyWith(
                      orderNumber: updatedState.nextOrderNumber,
                    );
                    context.read<PurchaseOrderBloc>().add(
                      UpdatePurchaseOrderHeader(header: updatedHeader),
                    );
                  }
                }
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildTransactionDateField(PurchaseOrderState state) {
    return CustomTextField(
      controller: _transactionDateController,
      labelText: 'Transaction Date',
      readOnly: false,
      prefixIcon: Icon(Icons.calendar_today, color: Colors.blue.shade700),
      onTap: () => _selectDate(context, (date) {
        setState(() {
          _transactionDate = date;
          _transactionDateController.text = _formatDate(date);
        });
        _updateHeaderDates(state);
      }),
    );
  }

  Widget _buildDeliveryDateField(PurchaseOrderState state) {
    return CustomTextField(
      controller: _deliveryDateController,
      labelText: 'Expected Delivery Date',
      readOnly: false,
      prefixIcon: Icon(Icons.delivery_dining, color: Colors.blue.shade700),
      onTap: () => _selectDate(context, (date) {
        setState(() {
          _deliveryDate = date;
          _deliveryDateController.text = _formatDate(date);
        });
        _updateHeaderDates(state);
      }),
    );
  }

  Widget _buildReceivingDateField(PurchaseOrderState state) {
    return CustomTextField(
      controller: _receivingDateController,
      labelText: 'Receiving Date',
      readOnly: false,
      prefixIcon: Icon(Icons.inventory, color: Colors.blue.shade700),
      onTap: () => _selectDate(context, (date) {
        setState(() {
          _receivingDate = date;
          _receivingDateController.text = _formatDate(date);
        });
        // Update receivingDates in state using CalculatePurchaseOrderTotals
        // (We'll use this as a workaround since there's no specific event)
        context.read<PurchaseOrderBloc>().add(CalculatePurchaseOrderTotals());
      }),
    );
  }

  Widget _buildInvoiceNumberField(PurchaseOrderState state) {
    return CustomTextField(
      controller: _invoiceNumberController,
      labelText: 'Supplier Invoice Number',
      keyboardType: TextInputType.text,
      prefixIcon: Icon(Icons.receipt, color: Colors.blue.shade700),
      onChanged: (value) {
        _updateHeaderInvoiceNumber(state, value);
      },
    );
  }

  Future<void> _selectDate(
    BuildContext context,
    Function(DateTime) onDateSelected,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFF155888),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF155888),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      onDateSelected(picked);
    }
  }

  void _updateHeaderDates(PurchaseOrderState state) {
    final header = state.selectedHeader;
    if (header != null) {
      final updatedHeader = header.copyWith(
        dateTransaction: _transactionDate,
        dateDelivery: _deliveryDate,
      );
      context.read<PurchaseOrderBloc>().add(
        UpdatePurchaseOrderHeader(header: updatedHeader),
      );
    }
  }

  void _updateHeaderInvoiceNumber(
    PurchaseOrderState state,
    String invoiceNumber,
  ) {
    final header = state.selectedHeader;
    if (header != null) {
      final updatedHeader = header.copyWith(
        invoiceNumber: invoiceNumber.isNotEmpty ? invoiceNumber : null,
      );
      context.read<PurchaseOrderBloc>().add(
        UpdatePurchaseOrderHeader(header: updatedHeader),
      );
    }
  }

  Widget _buildSupplierDetails(
    SupplierModel? supplier,
    PurchaseOrderState state,
  ) {
    final displaySupplier = state.selectedHeader?.supplierRef != null
        ? state.selectedHeader!.supplierRef!
        : supplier;

    if (displaySupplier == null) return const SizedBox.shrink();

    return Card(
      elevation: _cardElevation,
      child: Padding(
        padding: const EdgeInsets.all(_cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Selected Supplier Details:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: _titleFontSize,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.refresh, color: Colors.blue.shade700),
                  onPressed: () => _refreshSupplierDetails(context),
                ),
              ],
            ),
            const SizedBox(height: _sizedBoxHeight8),
            _buildDetailRow('Supplier Name', displaySupplier.supplierName),
            _buildDetailRow('TIN Number', displaySupplier.tinNumber),
            _buildDetailRow(
              'Phone',
              displaySupplier.phoneNo1 ?? displaySupplier.phoneNo2 ?? 'N/A',
            ),
            _buildDetailRow(
              'Email',
              displaySupplier.email ?? displaySupplier.addressLine ?? 'N/A',
            ),
            _buildDetailRow('Address', _buildAddress(displaySupplier)),
            if (displaySupplier.country != null)
              _buildDetailRow('Country', displaySupplier.country!),
          ],
        ),
      ),
    );
  }

  String _buildAddress(SupplierModel supplier) {
    final parts = [
      supplier.city,
      supplier.region,
      supplier.country,
    ].where((part) => part != null && part.isNotEmpty).toList();
    return parts.isNotEmpty ? parts.join(', ') : 'N/A';
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: _verticalDetailPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _detailLabelWidth,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: TextStyle(
                color: value == null || value.isEmpty
                    ? Colors.grey.shade500
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _refreshSupplierDetails(BuildContext context) {
    final companyId = widget.authBloc.state.companyId;
    if (companyId != null) {
      context.read<SupplierBloc>().add(LoadSuppliers(companyId));
      _showSuccessSnackBar(context, 'Supplier list refreshed');
    }
  }

  Widget _buildNextButton(bool isValid, PurchaseOrderState state) {
    final isProcessing = state.status == PurchaseOrderStatus.processing;
    final isLoading = state.status == PurchaseOrderStatus.loading;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Validation Summary
          if (!isValid && _selectedSupplier == null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Please select a supplier to continue',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Cancel Button
              Flexible(
                child: OutlinedButton(
                  onPressed: () {
                    _cancelOrder(context);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(
                      horizontal: _horizontalPadding32,
                      vertical: _verticalPadding12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        _elevatedButtonBorderRadius,
                      ),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: _titleFontSize),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Next Button
              Flexible(
                child: ElevatedButton(
                  onPressed: isValid && !isProcessing && !isLoading
                      ? () => _goToNextPage(context)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isValid
                        ? const Color(0xFF155888)
                        : Colors.grey.shade400,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        _elevatedButtonBorderRadius,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: _horizontalPadding32,
                      vertical: _verticalPadding12,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isProcessing)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      else
                        const Text(
                          'Add Items',
                          style: TextStyle(fontSize: _titleFontSize),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _cancelOrder(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Purchase Order'),
        content: const Text(
          'Are you sure you want to cancel this purchase order? All entered data will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No, Keep It'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<PurchaseOrderBloc>().add(
                CancelPurchaseOrderCreate(),
              );
              Navigator.pop(context);
            },
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _goToNextPage(BuildContext context) {
    if (_selectedSupplier == null &&
        context.read<PurchaseOrderBloc>().state.selectedHeader?.supplierRef ==
            null) {
      _showErrorSnackBar(context, 'Please select a supplier first');
      return;
    }

    // Validate required fields
    if (_transactionDate == null) {
      _showErrorSnackBar(context, 'Transaction date is required');
      return;
    }

    // Get the current state
    final purchaseState = context.read<PurchaseOrderBloc>().state;
    final authState = context.read<AuthBloc>().state;

    // Check if header is properly set
    if (purchaseState.selectedHeader == null) {
      _showErrorSnackBar(context, 'Purchase order not properly initialized');
      return;
    }

    // Prepare data for next screen using existing fields from state
    final orderData = {
      'supplier': _selectedSupplier,
      'currentHeader': purchaseState.selectedHeader,
      'autoReceipt': purchaseState.autoReceipt,
      'receivingDate': _receivingDate,
      'transactionDate': _transactionDate,
      'deliveryDate': _deliveryDate,
      'invoiceNumber': _invoiceNumberController.text,
    };

    // Navigate to purchase item entry screen
    context.push(AppRoutes.purchaseItemEntry, extra: orderData);
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white.withOpacity(0.9),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF155888)),
            ),
            SizedBox(height: 16),
            Text(
              'Setting up new purchase order...',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF155888),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
