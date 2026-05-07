import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:savvy_stock/core/constants/app_routes.dart';
import 'package:savvy_stock/core/widgets/custom_text_Form.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/sales/customer/blocs/customer_bloc.dart';
import 'package:savvy_stock/features/sales/customer/blocs/customer_event.dart';
import 'package:savvy_stock/features/sales/customer/blocs/customer_state.dart';
import 'package:savvy_stock/features/sales/customer/models/customer_model.dart';
import 'package:savvy_stock/features/sales/customer/widget/customer_section.dart';
import 'package:savvy_stock/features/sales/sales_order/integration/bloc/sales_order_coordinator_bloc.dart';
import 'package:savvy_stock/features/sales/sales_order/integration/bloc/sales_order_coordinator_event.dart';
import 'package:savvy_stock/features/sales/sales_order/integration/bloc/sales_order_coordinator_state.dart';
import 'package:savvy_stock/features/sales/sales_order/sales_item_entry/screens/sales_item_entry.dart';

class CustomerInfoScreen extends StatelessWidget {
  final AuthBloc authBloc;
  final Map<String, dynamic>? extra;

  const CustomerInfoScreen({super.key, required this.authBloc, this.extra});

  @override
  Widget build(BuildContext context) {
    final companyId = authBloc.state.companyId;

    if (companyId != null) {
      Future.microtask(() {
        context.read<CustomerBloc>().add(LoadCustomers(companyId));
      });
    }

    return CustomerInfoScreenContent(authBloc: authBloc, extra: extra);
  }
}

class CustomerInfoScreenContent extends StatefulWidget {
  final AuthBloc authBloc;
  final Map<String, dynamic>? extra;

  const CustomerInfoScreenContent({
    super.key,
    required this.authBloc,
    this.extra,
  });

  @override
  State<CustomerInfoScreenContent> createState() =>
      _CustomerInfoScreenContentState();
}

class _CustomerInfoScreenContentState extends State<CustomerInfoScreenContent> {
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

  bool _isInitialized = false;
  bool _isOrderPrepared = false;
  late final TextEditingController _salesRefController;
  late final TextEditingController _orderDateController;
  late final TextEditingController _salesPersonController;

  Customer? _selectedBillToCustomer;
  Customer? _selectedShipToCustomer;

  @override
  void initState() {
    super.initState();
    _salesRefController = TextEditingController();
    _orderDateController = TextEditingController();
    _salesPersonController = TextEditingController();

    Future.microtask(_initializeOrderPreparation);
  }

  void _initializeOrderPreparation() {
    // Check if we have converted quotation data
    if (widget.extra != null &&
        widget.extra!.containsKey('header') &&
        widget.extra!.containsKey('details')) {
      // Initialize from converted quotation
      final header = widget.extra!['header'];
      final details = widget.extra!['details'];

      if (kDebugMode) {
        developer.log(
          'DEBUG CustomerInfo: Found converted data - header: $header, details count: ${details?.length}',
        );
      }

      context.read<SalesOrderCoordinatorBloc>().add(
        InitializeFromQuotation(header: header, details: details),
      );
      if (kDebugMode) {
        developer.log(
          'DEBUG CustomerInfo: Dispatched InitializeFromQuotation event',
        );
      }
      return;
    }

    if (kDebugMode) {
      developer.log(
        'DEBUG CustomerInfo: No converted data found, preparing new order',
      );
    }
    // Otherwise, prepare a new sales order
    final companyId = widget.authBloc.state.companyId;
    final userId = widget.authBloc.state.userId?.id;
    final branchId = widget.authBloc.state.userId?.branch;

    if (companyId != null && userId != null && branchId != null) {
      context.read<SalesOrderCoordinatorBloc>().add(
        PrepareNewSalesOrder(
          companyId: companyId,
          employeeId: userId,
          branchId: branchId,
        ),
      );
    }
  }

  @override
  void dispose() {
    _salesRefController.dispose();
    _orderDateController.dispose();
    _salesPersonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<SalesOrderCoordinatorBloc, SalesOrderCoordinatorState>(
          listenWhen: (previous, current) =>
              previous.status != current.status ||
              previous.lastOperation != current.lastOperation,
          listener: _handleCoordinatorStateChange,
        ),
      ],
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(context),
        body: SafeArea(
          child: BlocBuilder<CustomerBloc, CustomerState>(
            builder: (context, customerState) {
              return BlocBuilder<
                SalesOrderCoordinatorBloc,
                SalesOrderCoordinatorState
              >(
                builder: (context, coordinatorState) {
                  // Use post-frame callback to initialize default customer AFTER build
                  if (!_isInitialized &&
                      coordinatorState.defaultCustomer != null &&
                      coordinatorState.defaultCustomer!.isNotEmpty &&
                      customerState.customers.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _initializeDefaultCustomer(
                        coordinatorState,
                        customerState,
                      );
                    });
                  }

                  final isValid =
                      _selectedBillToCustomer != null &&
                      _selectedShipToCustomer != null &&
                      coordinatorState.currentHeader != null;

                  return Stack(
                    children: [
                      _buildContent(coordinatorState, isValid, customerState),
                      if (coordinatorState.pendingOperations.contains(
                        'prepare_new_order',
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

  void _handleCoordinatorStateChange(
    BuildContext context,
    SalesOrderCoordinatorState coordinatorState,
  ) {
    // Handle order preparation completion
    if (coordinatorState.status == SalesOrderCoordinatorStatus.success &&
        coordinatorState.lastOperation?.contains('sales order prepared') ==
            true) {
      setState(() {
        _isOrderPrepared = true;
      });
    }

    // Handle errors
    if (coordinatorState.status == SalesOrderCoordinatorStatus.error) {
      _showErrorSnackBar(context, coordinatorState.error!);
    }

    // Handle successful operations
    if (coordinatorState.status == SalesOrderCoordinatorStatus.success &&
        coordinatorState.lastOperation?.contains('sales order prepared') ==
            true) {
      _showSuccessSnackBar(context, 'New sales order prepared successfully');
    }
  }

  void _initializeDefaultCustomer(
    SalesOrderCoordinatorState state,
    CustomerState customerState,
  ) {
    if (_isInitialized) return;

    final loaded = customerState.customers;
    if (loaded.isEmpty) return;

    Customer? defaultCustomer;

    final defaults = state.defaultCustomer;
    if (defaults != null && defaults.isNotEmpty) {
      defaultCustomer = defaults;
    }

    if (defaultCustomer == null) {
      try {
        defaultCustomer = loaded.firstWhere(
          (c) => c.defaultsValue == 'Y',
          orElse: () => loaded.first,
        );
      } catch (_) {
        defaultCustomer = loaded.first;
      }
    }

    Customer billToMatch = defaultCustomer;
    if (defaultCustomer.id != null) {
      try {
        billToMatch = loaded.firstWhere(
          (c) => c.id == defaultCustomer!.id,
          orElse: () => defaultCustomer!,
        );
      } catch (_) {
        billToMatch = defaultCustomer;
      }
    }

    setState(() {
      _selectedBillToCustomer = billToMatch;
      _selectedShipToCustomer = billToMatch;
      _isInitialized = true;
    });

    // _prefillCustomerData(billToMatch);

    // Dispatch events without try-catch, let errors propagate naturally
    context.read<CustomerBloc>().add(SelectBillToCustomer(billToMatch));
    context.read<CustomerBloc>().add(SelectShipToCustomer(billToMatch));

    context.read<SalesOrderCoordinatorBloc>().add(
      SyncCustomerToOrder(customer: billToMatch),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text(
        'Customer Information',
        style: TextStyle(
          color: Colors.white,
          fontSize: _appBarFontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: const Color(0xFF155888),
      elevation: 0,
      actions: [
        BlocSelector<
          SalesOrderCoordinatorBloc,
          SalesOrderCoordinatorState,
          bool
        >(
          selector: (state) =>
              state.pendingOperations.contains('prepare_new_order'),
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
    SalesOrderCoordinatorState coordinatorState,
    bool isValid,
    CustomerState customerState,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (coordinatorState.pendingOperations.contains('prepare_new_order'))
            const _LoadingOverlay(),

          _buildCustomerSections(coordinatorState, customerState),
          const SizedBox(height: _sizedBoxHeight16),
          _buildOrderInformationSection(coordinatorState),
          const SizedBox(height: _sizedBoxHeight20),
          if (_selectedBillToCustomer != null ||
              coordinatorState.currentHeader?.customerBillToRef != null)
            _buildCustomerDetails(_selectedBillToCustomer, coordinatorState),
          const SizedBox(height: _sizedBoxHeight20),
          _buildNextButton(isValid, coordinatorState),
          const SizedBox(height: _sizedBoxHeight20),
        ],
      ),
    );
  }

  Widget _buildCustomerSections(
    SalesOrderCoordinatorState coordinatorState,
    CustomerState customerState,
  ) {
    return Column(
      children: [
        CustomerSection(
          authBloc: context.read<AuthBloc>(),
          title: 'Customer Bill To:',
          selectedCustomer: _selectedBillToCustomer ?? Customer.empty,
          customers: customerState.customers,
          onCustomerSelected: _handleBillToCustomerSelected,
          showAddButton: true,
        ),
        const SizedBox(height: _sizedBoxHeight16),
        CustomerSection(
          authBloc: context.read<AuthBloc>(),
          title: 'Customer Ship To:',
          selectedCustomer: _selectedShipToCustomer ?? Customer.empty,
          customers: customerState.customers,
          onCustomerSelected: _handleShipToCustomerSelected,
          showAddButton: false,
        ),
      ],
    );
  }

  void _handleBillToCustomerSelected(Customer customer) {
    setState(() {
      _selectedBillToCustomer = customer;
    });

    context.read<SalesOrderCoordinatorBloc>().add(
      SyncCustomerToOrder(customer: customer),
    );

    context.read<CustomerBloc>().add(SelectBillToCustomer(customer));

    if (_selectedShipToCustomer == null ||
        _selectedShipToCustomer?.id == _selectedBillToCustomer?.id) {
      setState(() {
        _selectedShipToCustomer = customer;
      });
      context.read<CustomerBloc>().add(SelectShipToCustomer(customer));
    }
  }

  void _handleShipToCustomerSelected(Customer customer) {
    setState(() {
      _selectedShipToCustomer = customer;
    });

    context.read<CustomerBloc>().add(SelectShipToCustomer(customer));
  }

  Widget _buildOrderInformationSection(
    SalesOrderCoordinatorState coordinatorState,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Order Information:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: _titleFontSize,
          ),
        ),
        const SizedBox(height: _sizedBoxHeight8),
        _buildSalesReferenceField(coordinatorState),
        const SizedBox(height: _sizedBoxHeight8),
        _buildOrderDateField(coordinatorState),
        const SizedBox(height: _sizedBoxHeight8),
        _buildSalesPersonField(coordinatorState),
      ],
    );
  }

  Widget _buildSalesReferenceField(SalesOrderCoordinatorState state) {
    final fsNumber = state.currentHeader?.fsNumber ?? '';
    if (fsNumber.isNotEmpty && _salesRefController.text.isEmpty) {
      _salesRefController.text = fsNumber;
    }

    return CustomTextField(
      controller: _salesRefController,
      labelText: 'Sales Reference',
      readOnly: true,
    );
  }

  Widget _buildOrderDateField(SalesOrderCoordinatorState state) {
    final orderDate = state.currentHeader?.orderDate ?? DateTime.now();
    if (_orderDateController.text.isEmpty) {
      _orderDateController.text =
          '${orderDate.year}-${orderDate.month.toString().padLeft(2, '0')}-${orderDate.day.toString().padLeft(2, '0')}';
    }

    return CustomTextField(
      controller: _orderDateController,
      labelText: 'Order Date',
      readOnly: true,
    );
  }

  Widget _buildSalesPersonField(SalesOrderCoordinatorState state) {
    final salesPerson = widget.authBloc.state.userId?.userName ?? '';
    if (salesPerson.isNotEmpty && _salesPersonController.text.isEmpty) {
      _salesPersonController.text = salesPerson;
    }

    return CustomTextField(
      controller: _salesPersonController,
      labelText: 'Sales Person',
      readOnly: true,
    );
  }

  Widget _buildCustomerDetails(
    Customer? customer,
    SalesOrderCoordinatorState state,
  ) {
    // Use customer from header if available (especially for converted orders)
    final displayCustomer = state.currentHeader?.customerBillToRef != null
        ? Customer.fromMap(
            state.currentHeader!.customerBillToRef!.toMap(),
          ) // Create copy to avoid reference issues
        : customer;

    if (displayCustomer == null) return const SizedBox.shrink();

    return Card(
      elevation: _cardElevation,
      child: Padding(
        padding: const EdgeInsets.all(_cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customer Information:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: _titleFontSize,
              ),
            ),
            const SizedBox(height: _sizedBoxHeight8),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildDetailRow('Name', displayCustomer.customerName),
                ),
                Expanded(
                  child: _buildDetailRow(
                    'TIN Number',
                    displayCustomer.tinNumber,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildDetailRow('Phone', displayCustomer.phoneNumber),
                ),
                Expanded(
                  child: _buildDetailRow('Country', displayCustomer.country),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(child: _buildDetailRow('City', displayCustomer.city)),
                Expanded(
                  child: _buildDetailRow('Region', displayCustomer.region),
                ),
              ],
            ),
            if (displayCustomer.defaultsValue == 'Y')
              _buildDetailRow('Status', 'Default Customer'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: _verticalDetailPadding),
      child: Row(
        children: [
          SizedBox(
            width: _detailLabelWidth,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value ?? 'N/A')),
        ],
      ),
    );
  }

  Widget _buildNextButton(
    bool isValid,
    SalesOrderCoordinatorState coordinatorState,
  ) {
    final isProcessing =
        coordinatorState.status == SalesOrderCoordinatorStatus.processing;
    final isPreparingOrder = coordinatorState.pendingOperations.contains(
      'prepare_new_order',
    );

    return Container(
      alignment: Alignment.bottomRight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (isProcessing)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: CircularProgressIndicator(),
            ),
          ElevatedButton(
            onPressed: isValid && !isProcessing && !isPreparingOrder
                ? () => _goToNextPage(context)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF155888),
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
            child: const Text(
              'Next',
              style: TextStyle(fontSize: _titleFontSize),
            ),
          ),
        ],
      ),
    );
  }

  void _goToNextPage(BuildContext context) {
    if (_selectedBillToCustomer == null &&
        context
                .read<SalesOrderCoordinatorBloc>()
                .state
                .currentHeader
                ?.customerBillToRef ==
            null) {
      _showErrorSnackBar(context, 'Please select a customer first');
      return;
    }

    // If we have a selected customer, sync it. If not, we might be relying on the header's customer (converted order)
    if (_selectedBillToCustomer != null) {
      context.read<SalesOrderCoordinatorBloc>().add(
        SyncCustomerToOrder(customer: _selectedBillToCustomer!),
      );
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ItemEntryScreen()),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white.withOpacity(0.8),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Setting up new sales order...',
              style: TextStyle(fontWeight: FontWeight.w500, color: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }
}
