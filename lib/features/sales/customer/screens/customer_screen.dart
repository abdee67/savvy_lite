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

class CustomerInfoScreen extends StatelessWidget {
  final AuthBloc authBloc;
  const CustomerInfoScreen({super.key, required this.authBloc});

  @override
  Widget build(BuildContext context) {
    // Ensure customers are loaded (once per screen show)
    final companyId = authBloc.state.companyId;
    if (companyId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<CustomerBloc>().add(LoadCustomers(companyId));
      });
    }

    return const CustomerInfoScreenContent();
  }
}

class CustomerInfoScreenContent extends StatefulWidget {
  const CustomerInfoScreenContent({super.key});

  @override
  State<CustomerInfoScreenContent> createState() =>
      _CustomerInfoScreenContentState();
}

class _CustomerInfoScreenContentState extends State<CustomerInfoScreenContent> {
  bool _isInitialized = false;
  bool _isOrderPrepared = false;
  bool _areCustomersLoaded = false;
  late TextEditingController _salesRefController;
  late TextEditingController _orderDateController;
  late TextEditingController _salesPersonController;

  Customer? _selectedBillToCustomer;
  Customer? _selectedShipToCustomer;

  @override
  void initState() {
    super.initState();
    _salesRefController = TextEditingController();
    _orderDateController = TextEditingController();
    _salesPersonController = TextEditingController();

    // Initialize order preparation after widgets are built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeOrderPreparation();
    });
  }

  void _initializeOrderPreparation() {
    final authState = context.read<AuthBloc>().state;
    if (authState.companyId != null && authState.userId != null) {
      context.read<SalesOrderCoordinatorBloc>().add(
        PrepareNewSalesOrder(
          companyId: authState.companyId!,
          employeeId: authState.userId!,
        ),
      );
    }
  }

  // Method to auto-select default customers when both order and customers are ready
  void _autoSelectDefaultCustomers(
    BuildContext context,
    CustomerState customerState,
  ) {
    if (!_isInitialized && _isOrderPrepared && _areCustomersLoaded) {
      _isInitialized = true;

      // Find default customer
      final defaultCustomers = customerState.customers
          .where((customer) => customer.defaultsValue == 'Y')
          .toList();

      if (defaultCustomers.isNotEmpty) {
        final defaultCustomer = defaultCustomers.first;

        // Set both bill to and ship to as default customer initially
        _selectedBillToCustomer = defaultCustomer;
        _selectedShipToCustomer = defaultCustomer;

        // Update coordinator bloc with default customer
        context.read<SalesOrderCoordinatorBloc>().add(
          SyncCustomerToOrder(customer: defaultCustomer),
        );

        // Update customer bloc selections
        context.read<CustomerBloc>().add(SelectBillToCustomer(defaultCustomer));
        context.read<CustomerBloc>().add(SelectShipToCustomer(defaultCustomer));

        // Update UI
        if (mounted) {
          setState(() {});
        }

        // Pre-fill form fields with default customer data
        _prefillCustomerData(defaultCustomer);

        print(
          'Default customer automatically selected: ${defaultCustomer.customerName}',
        );
      } else {
        print('No default customer found');
      }
    }
  }

  void _prefillCustomerData(Customer customer) {
    _salesPersonController.text = customer.customerName ?? '';
    // You can pre-fill other fields as needed
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
        // Listen for customer state changes
        BlocListener<CustomerBloc, CustomerState>(
          listener: (context, customerState) {
            if (customerState.status == CustomerStatus.loaded) {
              setState(() {
                _areCustomersLoaded = true;
              });
              _autoSelectDefaultCustomers(context, customerState);
            }
          },
        ),
        // Listen for coordinator state changes
        BlocListener<SalesOrderCoordinatorBloc, SalesOrderCoordinatorState>(
          listener: (context, coordinatorState) {
            // Handle order preparation completion
            if (coordinatorState.status ==
                    SalesOrderCoordinatorStatus.success &&
                coordinatorState.lastOperation?.contains('prepared') == true) {
              setState(() {
                _isOrderPrepared = true;
              });

              // Trigger auto-selection if customers are already loaded
              final customerState = context.read<CustomerBloc>().state;
              if (customerState.status == CustomerStatus.loaded) {
                _autoSelectDefaultCustomers(context, customerState);
              }
            }

            // Handle errors
            if (coordinatorState.status == SalesOrderCoordinatorStatus.error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(coordinatorState.error!),
                  backgroundColor: Colors.red,
                ),
              );
            }

            // Handle successful operations
            if (coordinatorState.status ==
                SalesOrderCoordinatorStatus.success) {
              if (coordinatorState.lastOperation?.contains('prepared') ==
                  true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('New sales order prepared successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Customer Information',
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: const Color(0xFF155888),
          elevation: 0,
          actions: [
            // Show loading indicator when preparing order
            BlocBuilder<SalesOrderCoordinatorBloc, SalesOrderCoordinatorState>(
              builder: (context, state) {
                if (state.pendingOperations.contains('prepare_new_order')) {
                  return const Padding(
                    padding: EdgeInsets.only(right: 16.0),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ],
        ),
        body: BlocBuilder<CustomerBloc, CustomerState>(
          builder: (context, customerState) {
            return BlocBuilder<
              SalesOrderCoordinatorBloc,
              SalesOrderCoordinatorState
            >(
              builder: (context, coordinatorState) {
                final isValid =
                    _selectedBillToCustomer != null &&
                    _selectedShipToCustomer != null &&
                    coordinatorState.currentHeader != null;

                return Stack(
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Show loading state while preparing order
                          if (coordinatorState.pendingOperations.contains(
                            'prepare_new_order',
                          ))
                            const _OrderPreparationLoader(),

                          // Customer Bill To section
                          CustomerSection(
                            authBloc: context.read<AuthBloc>(),
                            title: 'Customer Bill To:',
                            selectedCustomer:
                                _selectedBillToCustomer ?? Customer.empty,
                            customers: customerState.customers,
                            onCustomerSelected: (customer) {
                              setState(() {
                                _selectedBillToCustomer = customer;
                              });

                              // Update coordinator with selected customer
                              context.read<SalesOrderCoordinatorBloc>().add(
                                SyncCustomerToOrder(customer: customer),
                              );

                              // Update customer bloc
                              context.read<CustomerBloc>().add(
                                SelectBillToCustomer(customer),
                              );

                              // If ship to is not set or same as previous bill to, update it too
                              if (_selectedShipToCustomer == null ||
                                  _selectedShipToCustomer?.id ==
                                      _selectedBillToCustomer?.id) {
                                setState(() {
                                  _selectedShipToCustomer = customer;
                                });
                                context.read<CustomerBloc>().add(
                                  SelectShipToCustomer(customer),
                                );
                              }

                              print(
                                'Bill To customer selected: ${customer.customerName}',
                              );
                            },
                            showAddButton: true,
                          ),

                          const SizedBox(height: 16),

                          // Customer Ship To section
                          CustomerSection(
                            authBloc: context.read<AuthBloc>(),
                            title: 'Customer Ship To:',
                            selectedCustomer:
                                _selectedShipToCustomer ?? Customer.empty,
                            customers: customerState.customers,
                            onCustomerSelected: (customer) {
                              setState(() {
                                _selectedShipToCustomer = customer;
                              });

                              // Update customer bloc
                              context.read<CustomerBloc>().add(
                                SelectShipToCustomer(customer),
                              );

                              print(
                                'Ship To customer selected: ${customer.customerName}',
                              );
                            },
                            showAddButton: false,
                          ),

                          const SizedBox(height: 16),

                          // Order Information Section
                          const Text(
                            'Order Information:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Sales Reference (auto-generated from coordinator)
                          _buildSalesReferenceField(coordinatorState),

                          const SizedBox(height: 8),

                          // Order Date (auto-filled with current date)
                          _buildOrderDateField(coordinatorState),

                          const SizedBox(height: 8),

                          // Sales Person (auto-filled from auth user)
                          _buildSalesPersonField(coordinatorState),

                          const SizedBox(height: 20),

                          // Customer Details Display
                          if (_selectedBillToCustomer != null)
                            _buildCustomerDetails(_selectedBillToCustomer!),

                          const SizedBox(height: 20),

                          // Next button
                          _buildNextButton(context, isValid, coordinatorState),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),

                    // Show overlay when order is being prepared
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
      onChanged: (value) => {},
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
      onChanged: (value) => {},
    );
  }

  Widget _buildSalesPersonField(SalesOrderCoordinatorState state) {
    final salesPerson = state.currentHeader?.employee?.fullName ?? '';
    if (salesPerson.isNotEmpty && _salesPersonController.text.isEmpty) {
      _salesPersonController.text = salesPerson;
    }

    return CustomTextField(
      controller: _salesPersonController,
      labelText: 'Sales Person',
      readOnly: true,
      onChanged: (value) => {},
    );
  }

  Widget _buildCustomerDetails(Customer customer) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customer Information:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            _buildDetailRow('Name', customer.customerName ?? 'N/A'),
            _buildDetailRow('TIN Number', customer.tinNumber ?? 'N/A'),
            _buildDetailRow('Phone', customer.phoneNumber ?? 'N/A'),
            _buildDetailRow('Country', customer.country ?? 'N/A'),
            _buildDetailRow('Region', customer.region ?? 'N/A'),
            _buildDetailRow('City', customer.city ?? 'N/A'),
            if (customer.defaultsValue == 'Y')
              _buildDetailRow('Status', 'Default Customer'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildNextButton(
    BuildContext context,
    bool isValid,
    SalesOrderCoordinatorState coordinatorState,
  ) {
    return Container(
      alignment: Alignment.bottomRight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Show processing indicator
          if (coordinatorState.status == SalesOrderCoordinatorStatus.processing)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: CircularProgressIndicator(),
            ),

          ElevatedButton(
            onPressed:
                isValid &&
                    coordinatorState.status !=
                        SalesOrderCoordinatorStatus.processing &&
                    !coordinatorState.pendingOperations.contains(
                      'prepare_new_order',
                    )
                ? () => _goToNextPage(context)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF155888),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Next', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  void _goToNextPage(BuildContext context) {
    if (_selectedBillToCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer first')),
      );
      return;
    }

    // Ensure the coordinator has the latest customer data
    context.read<SalesOrderCoordinatorBloc>().add(
      SyncCustomerToOrder(customer: _selectedBillToCustomer!),
    );

    print(
      'Selected customer: ${_selectedBillToCustomer!.id} - ${_selectedBillToCustomer!.customerName}',
    );

    if (context.read<AuthBloc>().state.hasAccessToPrivilege(
      AppRoutes.salesItemEntry,
    )) {
      // Pass both customers and the current order state to the next screen
      final customerData = {
        'billToCustomer': _selectedBillToCustomer,
        'shipToCustomer': _selectedShipToCustomer,
        'currentHeader': context
            .read<SalesOrderCoordinatorBloc>()
            .state
            .currentHeader,
      };

      context.push(AppRoutes.salesItemEntry, extra: customerData);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No access to sales item entry')),
      );
    }
  }
}

// Loading overlay widget
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

// Order preparation loader widget
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
