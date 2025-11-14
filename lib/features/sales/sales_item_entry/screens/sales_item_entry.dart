// features/sales/sales_item_entry/screens/sales_item_entry_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/sales/customer/blocs/customer_bloc.dart';
import 'package:savvy_stock/features/sales/customer/blocs/customer_event.dart';
import 'package:savvy_stock/features/sales/customer/models/customer_model.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/widget/sales_item_entry_confirmed_item.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/widget/sales_item_entry_form.dart';
import 'package:savvy_stock/features/sales/sales_order/detail/model/sales_order_detail.dart';
import 'package:savvy_stock/features/sales/sales_order/integration/bloc/sales_order_coordinator_bloc.dart';
import 'package:savvy_stock/features/sales/sales_order/integration/bloc/sales_order_coordinator_event.dart';
import 'package:savvy_stock/features/sales/sales_order/integration/bloc/sales_order_coordinator_state.dart';

class ItemEntryScreen extends StatelessWidget {
  final Map<String, dynamic>? customerData;
  const ItemEntryScreen({super.key, this.customerData});

  @override
  Widget build(BuildContext context) {
    // Initialize coordinator with customer data from previous screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCoordinator(context);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Item Entry'),
        backgroundColor: const Color(0xFF155888),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      resizeToAvoidBottomInset: false,
      body: const ItemEntryScreenContent(),
    );
  }

  void _initializeCoordinator(BuildContext context) {
    final coordinatorBloc = context.read<SalesOrderCoordinatorBloc>();
    final customerBloc = context.read<CustomerBloc>();

    // Set customers from previous screen data
    if (customerData != null) {
      final billToCustomer = customerData!['billToCustomer'] as Customer?;
      final shipToCustomer = customerData!['shipToCustomer'] as Customer?;
      final currentHeader = customerData!['currentHeader'];

      if (billToCustomer != null) {
        // Update customer bloc
        customerBloc.add(SelectBillToCustomer(billToCustomer));
        if (shipToCustomer != null) {
          customerBloc.add(SelectShipToCustomer(shipToCustomer));
        }

        // Sync customer to coordinator
        coordinatorBloc.add(SyncCustomerToOrder(customer: billToCustomer));
      }

      // Validate that we have a current header
      final coordinatorState = coordinatorBloc.state;
      if (coordinatorState.currentHeader == null && currentHeader != null) {
        // If header is not prepared, trigger preparation
        final authBloc = context.read<AuthBloc>();
        if (authBloc.state.companyId != null && authBloc.state.userId != null) {
          coordinatorBloc.add(
            PrepareNewSalesOrder(
              companyId: authBloc.state.companyId!,
              employeeId: authBloc.state.userId!,
            ),
          );
        }
      }
    }
  }
}

class ItemEntryScreenContent extends StatefulWidget {
  const ItemEntryScreenContent({super.key});

  @override
  State<ItemEntryScreenContent> createState() => _ItemEntryScreenContentState();
}

class _ItemEntryScreenContentState extends State<ItemEntryScreenContent> {
  final List<GlobalKey<FormState>> _formKeys = [];
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeFormKeys();
  }

  void _initializeFormKeys() {
    final state = context.read<SalesOrderCoordinatorBloc>().state;
    _formKeys.clear();
    _formKeys.addAll(
      List.generate(
        state.currentDetails.length,
        (index) => GlobalKey<FormState>(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // Listen for coordinator state changes
        BlocListener<SalesOrderCoordinatorBloc, SalesOrderCoordinatorState>(
          listener: (context, coordinatorState) {
            // Update form keys when details change
            if (_formKeys.length != coordinatorState.currentDetails.length &&
                coordinatorState.status !=
                    SalesOrderCoordinatorStatus.processing) {
              setState(() {
                _initializeFormKeys();
              });
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
              if (coordinatorState.lastOperation?.contains('calculated') ==
                  true) {
                // Totals calculated successfully
                print(
                  'Order totals updated: ${coordinatorState.lastTotalAmount}',
                );
              }
            }
          },
        ),
      ],
      child: SafeArea(
        child:
            BlocBuilder<SalesOrderCoordinatorBloc, SalesOrderCoordinatorState>(
              builder: (context, coordinatorState) {
                // Show loading state while preparing
                if (coordinatorState.pendingOperations.contains(
                  'prepare_new_order',
                )) {
                  return const _OrderPreparationLoader();
                }

                return Column(
                  children: [
                    // Upper Section - Item Entry Forms
                    Expanded(
                      flex: 2,
                      child: Container(
                        color: Colors.white,
                        child: Column(
                          children: [
                            // Add New Item Button
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton.icon(
                                  onPressed: () => _addNewItem(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF155888),
                                    foregroundColor: Colors.white,
                                  ),
                                  icon: const Icon(Icons.add, size: 20),
                                  label: const Text('Add New Item'),
                                ),
                              ),
                            ),

                            // Item Entry Forms
                            Expanded(
                              child: coordinatorState.currentDetails.isEmpty
                                  ? _buildEmptyItemsState()
                                  : ListView.builder(
                                      padding: const EdgeInsets.all(8),
                                      itemCount: coordinatorState
                                          .currentDetails
                                          .length,
                                      itemBuilder: (context, index) {
                                        final detail = coordinatorState
                                            .currentDetails[index];

                                        // Ensure we have enough form keys
                                        if (index >= _formKeys.length) {
                                          _formKeys.add(GlobalKey<FormState>());
                                        }

                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 8.0,
                                          ),
                                          child: SalesItemEntryForm(
                                            key: ValueKey(
                                              detail.tempId ?? detail.id,
                                            ),
                                            detail: detail,
                                            index: index,
                                            formKey: _formKeys[index],
                                            onRemove: () =>
                                                _removeItem(context, index),
                                            onConfirm: () =>
                                                _confirmItem(context, index),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Lower Section - Confirmed Items Summary
                    SalesItemEntryConfirmedItem(formKeys: _formKeys),
                  ],
                );
              },
            ),
      ),
    );
  }

  Widget _buildEmptyItemsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Items Added',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Click "Add New Item" to start adding products',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _addNewItem(BuildContext context) {
    final coordinatorBloc = context.read<SalesOrderCoordinatorBloc>();
    final coordinatorState = coordinatorBloc.state;

    if (coordinatorState.currentHeader == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait for order preparation to complete'),
        ),
      );
      return;
    }

    // Create a new empty detail
    final newDetail = SalesOrderDetail(
      tempId: DateTime.now().millisecondsSinceEpoch, // Temporary ID
      salesOrderHeaderId: coordinatorState.currentHeader?.id,
      company: coordinatorState.currentHeader?.company,
      quantity: 1.0,
      unitPrice: 0.0,
      extendedPrice: 0.0,
    );

    coordinatorBloc.add(AddDetailToOrder(detail: newDetail));

    // Add new form key
    setState(() {
      _formKeys.add(GlobalKey<FormState>());
    });
  }

  void _removeItem(BuildContext context, int index) {
    final coordinatorBloc = context.read<SalesOrderCoordinatorBloc>();
    final coordinatorState = coordinatorBloc.state;

    if (index < coordinatorState.currentDetails.length) {
      final detail = coordinatorState.currentDetails[index];
      coordinatorBloc.add(RemoveDetailFromOrder(detail: detail));

      // Remove form key
      setState(() {
        if (index < _formKeys.length) {
          _formKeys.removeAt(index);
        }
      });
    }
  }

  void _confirmItem(BuildContext context, int index) {
    final coordinatorBloc = context.read<SalesOrderCoordinatorBloc>();
    final coordinatorState = coordinatorBloc.state;

    if (index < coordinatorState.currentDetails.length) {
      final detail = coordinatorState.currentDetails[index];

      // Validate the form
      if (index < _formKeys.length && _formKeys[index].currentState != null) {
        if (!_formKeys[index].currentState!.validate()) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please fix validation errors')),
          );
          return;
        }
      }

      // Trigger stock validation and calculations
      coordinatorBloc.add(const ValidateCompleteStockAvailability());
      coordinatorBloc.add(const CalculateCompleteOrderTotals());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item confirmed successfully')),
      );
    }
  }
}

class _OrderPreparationLoader extends StatelessWidget {
  const _OrderPreparationLoader();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Preparing Sales Order...',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
