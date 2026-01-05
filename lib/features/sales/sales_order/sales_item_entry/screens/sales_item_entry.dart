// features/sales/sales_item_entry/screens/sales_item_entry_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:savvy_stock/features/sales/customer/blocs/customer_bloc.dart';
import 'package:savvy_stock/features/sales/customer/blocs/customer_event.dart';
import 'package:savvy_stock/features/sales/customer/models/customer_model.dart';
import 'package:savvy_stock/features/sales/sales_order/sales_item_entry/widget/sales_item_entry_confirmed_item.dart';
import 'package:savvy_stock/features/sales/sales_order/sales_item_entry/widget/sales_item_entry_form.dart';
import 'package:savvy_stock/features/sales/sales_order/detail/model/sales_order_detail.dart';
import 'package:savvy_stock/features/sales/sales_order/integration/bloc/sales_order_coordinator_bloc.dart';
import 'package:savvy_stock/features/sales/sales_order/integration/bloc/sales_order_coordinator_event.dart';
import 'package:savvy_stock/features/sales/sales_order/integration/bloc/sales_order_coordinator_state.dart';
import 'package:savvy_stock/core/di/injection_container.dart';
import 'package:savvy_stock/features/sales/sales_order/integration/service/sales_order_integration_service.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_bloc.dart';

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
      body: ItemEntryScreenContent(),
    );
  }

  void _initializeCoordinator(BuildContext context) {
    final coordinatorBloc = context.read<SalesOrderCoordinatorBloc>();
    final customerBloc = context.read<CustomerBloc>();

    // Set customers from previous screen data
    if (customerData != null) {
      final billToCustomer = customerData!['billToCustomer'] as Customer?;
      final shipToCustomer = customerData!['shipToCustomer'] as Customer?;

      if (billToCustomer != null) {
        // Update customer bloc
        customerBloc.add(SelectBillToCustomer(billToCustomer));
        if (shipToCustomer != null) {
          customerBloc.add(SelectShipToCustomer(shipToCustomer));
        }

        // Sync customer to coordinator
        coordinatorBloc.add(SyncCustomerToOrder(customer: billToCustomer));
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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  SalesOrderDetail? _currentFormDetail;
  bool _isEditing = false;
  int? _editingIndex;
  SalesOrderDetail? _originalDetail; // Store original detail for cancellation

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    // Wait for the coordinator to be ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final coordinatorState = context.read<SalesOrderCoordinatorBloc>().state;
      if (coordinatorState.currentHeader != null) {
        setState(() {
          _currentFormDetail = SalesOrderDetail(
            tempId: DateTime.now().millisecondsSinceEpoch,
            salesOrderHeaderId: coordinatorState.currentHeader?.id,
            company: coordinatorState.currentHeader?.company,
            quantity: 1.0,
            unitPrice: 0.0,
            extendedPrice: 0.0,
          );
        });
      } else {
        // If header not ready, listen for state changes
        final coordinatorBloc = context.read<SalesOrderCoordinatorBloc>();
        coordinatorBloc.stream
            .firstWhere((state) => state.currentHeader != null)
            .then((_) {
              if (mounted) {
                setState(() {
                  _currentFormDetail = SalesOrderDetail(
                    tempId: DateTime.now().millisecondsSinceEpoch,
                    salesOrderHeaderId: coordinatorBloc.state.currentHeader?.id,
                    company: coordinatorBloc.state.currentHeader?.company,
                    quantity: 1.0,
                    unitPrice: 0.0,
                    extendedPrice: 0.0,
                  );
                });
              }
            });
      }
    });
  }

  void _startEditingItem(SalesOrderDetail detail, int index) {
    setState(() {
      _currentFormDetail = detail.copyWith(); // Create a copy for editing
      _isEditing = true;
      _editingIndex = index;
      _originalDetail = detail; // Store original for cancellation
    });

    // Remove the item from confirmed list temporarily while editing
    context.read<SalesOrderCoordinatorBloc>().add(
      RemoveDetailFromOrder(detail: detail),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Now editing item. Make changes and click "Update Item".',
        ),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Cancel',
          onPressed: _cancelEditing,
          textColor: Colors.white,
        ),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _cancelEditing() {
    if (_isEditing && _originalDetail != null) {
      // Add the original item back to confirmed list
      context.read<SalesOrderCoordinatorBloc>().add(
        AddDetailToOrder(detail: _originalDetail!),
      );

      // Recalculate totals
      context.read<SalesOrderCoordinatorBloc>().add(
        const ValidateCompleteStockAvailability(),
      );
      context.read<SalesOrderCoordinatorBloc>().add(
        const CalculateCompleteOrderTotals(),
      );
    }

    _resetForm();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Editing cancelled'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _resetForm() {
    setState(() {
      _isEditing = false;
      _editingIndex = null;
      _originalDetail = null;

      // Create new empty form
      final coordinatorState = context.read<SalesOrderCoordinatorBloc>().state;
      _currentFormDetail = SalesOrderDetail(
        tempId: DateTime.now().millisecondsSinceEpoch,
        salesOrderHeaderId: coordinatorState.currentHeader?.id,
        company: coordinatorState.currentHeader?.company,
        quantity: 1.0,
        unitPrice: 0.0,
        extendedPrice: 0.0,
      );
    });

    // Reset form
    _formKey.currentState?.reset();
  }

  void _confirmItem() {
    print('=== CONFIRM ITEM STARTED ===');
    print('Form valid: ${_formKey.currentState?.validate()}');
    print('Current detail: ${_currentFormDetail?.toString()}');

    if (_formKey.currentState?.validate() ?? false) {
      if (_currentFormDetail != null) {
        final coordinatorBloc = context.read<SalesOrderCoordinatorBloc>();
        print('Dispatching AddDetailToOrder event');
        // Add or update the item in coordinator
        coordinatorBloc.add(AddDetailToOrder(detail: _currentFormDetail!));
        print('AddDetailToOrder event dispatched');
        _resetForm();

        /*  ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Item updated successfully'
                  : 'Item added successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );*/
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix validation errors'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _updateFormDetail(SalesOrderDetail updatedDetail) {
    setState(() {
      _currentFormDetail = updatedDetail;
    });

    // Delegate UOM conversion and extended price calculation to integration service
    if (updatedDetail.itemBranch != null) {
      final integrationService = getIt<SalesOrderIntegrationService>();
      integrationService.updateUnitPriceFromItemBranch(
        updatedDetail.itemBranch!,
        updatedDetail,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SalesOrderCoordinatorBloc, SalesOrderCoordinatorState>(
      builder: (context, coordinatorState) {
        // Show loading state while preparing
        if (coordinatorState.pendingOperations.contains('prepare_new_order') ||
            coordinatorState.currentHeader == null) {
          return const _OrderPreparationLoader();
        }

        return Column(
          children: [
            // Form Section - Always visible
            if (_currentFormDetail != null)
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: SalesItemEntryForm(
                    key: ValueKey(_currentFormDetail!.tempId),
                    detail: _currentFormDetail!,
                    formKey: _formKey,
                    isEditing: _isEditing,
                    onUpdate: _updateFormDetail,
                    onConfirm: _confirmItem,
                    onCancel: _isEditing ? _cancelEditing : null,
                  ),
                ),
              ),

            // Confirmed Items Section
            Expanded(
              flex: 3,
              child: SalesItemEntryConfirmedItem(onEditItem: _startEditingItem),
            ),
          ],
        );
      },
    );
  }
}

class _OrderPreparationLoader extends StatelessWidget {
  const _OrderPreparationLoader();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Preparing Sales Order...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
