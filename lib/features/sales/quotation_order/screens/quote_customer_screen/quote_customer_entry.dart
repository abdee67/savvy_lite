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
import 'package:savvy_stock/features/sales/sales_order/detail/model/sales_person.model.dart';
import 'package:savvy_stock/features/sales/quotation_order/bloc/quotation_order_bloc.dart';
import 'package:savvy_stock/features/sales/quotation_order/bloc/quotation_order_event.dart';
import 'package:savvy_stock/features/sales/quotation_order/bloc/quotation_order_state.dart';

class QuotationCustomerInfoScreen extends StatelessWidget {
  final AuthBloc authBloc;

  const QuotationCustomerInfoScreen({super.key, required this.authBloc});

  @override
  Widget build(BuildContext context) {
    final companyId = authBloc.state.companyId;

    if (companyId != null) {
      Future.microtask(() {
        context.read<CustomerBloc>().add(LoadCustomers(companyId));
      });
    }

    return QuotationCustomerInfoScreenContent(authBloc: authBloc);
  }
}

class QuotationCustomerInfoScreenContent extends StatefulWidget {
  final AuthBloc authBloc;

  const QuotationCustomerInfoScreenContent({super.key, required this.authBloc});

  @override
  State<QuotationCustomerInfoScreenContent> createState() =>
      _QuotationCustomerInfoScreenContentState();
}

class _QuotationCustomerInfoScreenContentState
    extends State<QuotationCustomerInfoScreenContent> {
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
    final companyId = widget.authBloc.state.companyId;
    final userId = widget.authBloc.state.userId?.id;
    final branchId = widget.authBloc.state.userId?.branch;

    if (companyId != null && userId != null && branchId != null) {
      context.read<QuotationOrderBloc>().add(
        PrepareCreateQuotationOrder(
          companyId: companyId,
          employeeId: userId,
          branchId: branchId,
        ),
      );
    }
  }

  void _prefillCustomerData(Salesperson salesPerson) {
    _salesPersonController.text = salesPerson.fullName;
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
        BlocListener<QuotationOrderBloc, QuotationOrderState>(
          listenWhen: (previous, current) =>
              previous.status != current.status ||
              previous.lastOperation != current.lastOperation,
          listener: _handleQuotationOrderStateChange,
        ),
      ],
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(context),
        body: BlocBuilder<CustomerBloc, CustomerState>(
          builder: (context, customerState) {
            return BlocBuilder<QuotationOrderBloc, QuotationOrderState>(
              builder: (context, quotationState) {
                // Use post-frame callback to initialize default customer AFTER build
                if (!_isInitialized &&
                    quotationState.defaultCustomer != null &&
                    quotationState.defaultCustomer!.isNotEmpty &&
                    customerState.customers.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _initializeDefaultCustomer(quotationState, customerState);
                  });
                }

                final isValid =
                    _selectedBillToCustomer != null &&
                    _selectedShipToCustomer != null &&
                    quotationState.selectedHeader != null;

                return Stack(
                  children: [
                    _buildContent(quotationState, isValid, customerState),
                    if (quotationState.pendingOperations.contains(
                      'prepare_new_quotation_order',
                    ))
                      const _LoadingOverlay(),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _handleQuotationOrderStateChange(
    BuildContext context,
    QuotationOrderState quotationState,
  ) {
    // Handle order preparation completion
    if (quotationState.status == QuotationOrderStatus.success &&
        quotationState.lastOperation?.contains('quotation order prepared') ==
            true) {
      setState(() {
        _isOrderPrepared = true;
      });
    }

    // Handle errors
    if (quotationState.status == QuotationOrderStatus.error) {
      _showErrorSnackBar(context, quotationState.error!);
    }

    // Handle successful operations
    if (quotationState.status == QuotationOrderStatus.success &&
        quotationState.lastOperation?.contains('quotation order prepared') ==
            true) {
      _showSuccessSnackBar(
        context,
        'New quotation order prepared successfully',
      );
    }
  }

  void _initializeDefaultCustomer(
    QuotationOrderState state,
    CustomerState customerState,
  ) {
    if (_isInitialized) return;

    final loaded = customerState.customers;
    if (loaded.isEmpty) return;

    Customer? defaultCustomer;

    final defaults = state.defaultCustomer;
    if (defaults != null) {
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

    context.read<QuotationOrderBloc>().add(
      UpdateCustomerInfo(customer: billToMatch),
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
        BlocSelector<QuotationOrderBloc, QuotationOrderState, bool>(
          selector: (state) =>
              state.pendingOperations.contains('prepare_new_quotation_order'),
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
    QuotationOrderState quotationState,
    bool isValid,
    CustomerState customerState,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (quotationState.pendingOperations.contains(
            'prepare_new_quotation_order',
          ))
            const _OrderPreparationLoader(),

          _buildCustomerSections(quotationState, customerState),
          const SizedBox(height: _sizedBoxHeight16),
          _buildOrderInformationSection(quotationState),
          const SizedBox(height: _sizedBoxHeight20),
          if (_selectedBillToCustomer != null)
            _buildCustomerDetails(_selectedBillToCustomer!),
          const SizedBox(height: _sizedBoxHeight20),
          _buildNextButton(isValid, quotationState),
          const SizedBox(height: _sizedBoxHeight20),
        ],
      ),
    );
  }

  Widget _buildCustomerSections(
    QuotationOrderState quotationState,
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

    context.read<QuotationOrderBloc>().add(
      UpdateCustomerInfo(customer: customer),
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

  Widget _buildOrderInformationSection(QuotationOrderState quotationState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quotation Order Information:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: _titleFontSize,
          ),
        ),
        const SizedBox(height: _sizedBoxHeight8),
        _buildSalesReferenceField(quotationState),
        const SizedBox(height: _sizedBoxHeight8),
        _buildOrderDateField(quotationState),
        const SizedBox(height: _sizedBoxHeight8),
        _buildSalesPersonField(quotationState),
      ],
    );
  }

  Widget _buildSalesReferenceField(QuotationOrderState state) {
    final fsNumber = state.selectedHeader?.fsNumber ?? '';
    if (fsNumber.isNotEmpty && _salesRefController.text.isEmpty) {
      _salesRefController.text = fsNumber;
    }

    return CustomTextField(
      controller: _salesRefController,
      labelText: 'Sales Reference',
      readOnly: true,
    );
  }

  Widget _buildOrderDateField(QuotationOrderState state) {
    final orderDate = state.selectedHeader?.orderDate ?? DateTime.now();
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

  Widget _buildSalesPersonField(QuotationOrderState state) {
    final salesPerson = state.selectedHeader?.employeeRef?.fullName ?? '';
    if (salesPerson.isNotEmpty && _salesPersonController.text.isEmpty) {
      _salesPersonController.text = salesPerson;
    }

    return CustomTextField(
      controller: _salesPersonController,
      labelText: 'Sales Person',
      readOnly: true,
    );
  }

  Widget _buildCustomerDetails(Customer customer) {
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
            _buildDetailRow('Name', customer.customerName),
            _buildDetailRow('TIN Number', customer.tinNumber),
            _buildDetailRow('Phone', customer.phoneNumber),
            _buildDetailRow('Country', customer.country),
            _buildDetailRow('Region', customer.region),
            _buildDetailRow('City', customer.city),
            if (customer.defaultsValue == 'Y')
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

  Widget _buildNextButton(bool isValid, QuotationOrderState quotationState) {
    final isProcessing =
        quotationState.status == QuotationOrderStatus.processing;
    final isPreparingOrder = quotationState.pendingOperations.contains(
      'prepare_new_quotation_order',
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

  void _goToNextPage(BuildContext context) async {
    print('🔵 NAVIGATION: Starting _goToNextPage');

    if (_selectedBillToCustomer == null) {
      _showErrorSnackBar(context, 'Please select a customer first');
      return;
    }

    print('🔵 NAVIGATION: Customer selected, getting header');
    final header = context.read<QuotationOrderBloc>().state.selectedHeader;
    print('🔵 NAVIGATION: Header obtained: ${header?.fsNumber}');

    print('🔵 NAVIGATION: Dispatching UpdateCustomerInfo');
    context.read<QuotationOrderBloc>().add(
      UpdateCustomerInfo(
        customer: _selectedBillToCustomer!,
        currentHeader: header,
      ),
    );
    print('🔵 NAVIGATION: UpdateCustomerInfo dispatched');

    // Wait a frame to ensure the event is processed
    await Future.delayed(const Duration(milliseconds: 50));
    print('🔵 NAVIGATION: Delay complete');

    if (context.read<AuthBloc>().state.hasAccessToPrivilege(
      AppRoutes.quotatioItemEntry,
    )) {
      print('🔵 NAVIGATION: Access granted, preparing customer data');
      final customerData = {
        'billToCustomer': _selectedBillToCustomer,
        'shipToCustomer': _selectedShipToCustomer,
        'currentHeader': context
            .read<QuotationOrderBloc>()
            .state
            .selectedHeader,
      };

      print('🔵 NAVIGATION: About to push route');
      if (mounted) {
        context.push(AppRoutes.quotatioItemEntry, extra: customerData);
        print('🔵 NAVIGATION: Route pushed successfully');
      } else {
        print('❌ NAVIGATION: Widget not mounted');
      }
    } else {
      print('❌ NAVIGATION: No access to quotation item entry');
      _showErrorSnackBar(context, 'No access to quotation item entry');
    }
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
      color: Colors.black54,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 16),
            Text(
              'Preparing New Order...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderPreparationLoader extends StatelessWidget {
  const _OrderPreparationLoader();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blue[50],
      child: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                'Setting up new sales order...',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
