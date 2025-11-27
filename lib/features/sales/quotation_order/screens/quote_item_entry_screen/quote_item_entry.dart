// features/sales/sales_item_entry/screens/sales_item_entry_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:savvy_stock/features/sales/customer/blocs/customer_bloc.dart';
import 'package:savvy_stock/features/sales/customer/blocs/customer_event.dart';
import 'package:savvy_stock/features/sales/customer/models/customer_model.dart';
import 'package:savvy_stock/features/sales/quotation_order/screens/quote_item_entry_screen/quote_item_entry_confirmed_item.dart';
import 'package:savvy_stock/features/sales/quotation_order/screens/quote_item_entry_screen/quote_item_entry_form.dart';
import 'package:savvy_stock/features/sales/quotation_order/model/quotation_order_detail.dart';
import 'package:savvy_stock/features/sales/quotation_order/bloc/quotation_order_bloc.dart';
import 'package:savvy_stock/features/sales/quotation_order/bloc/quotation_order_event.dart';
import 'package:savvy_stock/features/sales/quotation_order/bloc/quotation_order_state.dart';

class QuotationItemEntryScreen extends StatefulWidget {
  final Map<String, dynamic>? customerData;
  const QuotationItemEntryScreen({super.key, this.customerData});

  @override
  State<QuotationItemEntryScreen> createState() =>
      _QuotationItemEntryScreenState();
}

class _QuotationItemEntryScreenState extends State<QuotationItemEntryScreen> {
  @override
  void initState() {
    print('🟢 ITEM ENTRY: initState called');
    super.initState();
    // Initialize coordinator with customer data from previous screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🟢 ITEM ENTRY: PostFrameCallback executing');
      _initializeCoordinator(context);
      print('🟢 ITEM ENTRY: initializeCoordinator complete');
    });
  }

  @override
  Widget build(BuildContext context) {
    print('🟢 ITEM ENTRY: build() called');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quotation Item Entry'),
        backgroundColor: const Color(0xFF155888),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: const QuotationItemEntryScreenContent(),
    );
  }

  void _initializeCoordinator(BuildContext context) {
    final customerBloc = context.read<CustomerBloc>();

    // Set customers from previous screen data
    if (widget.customerData != null) {
      final billToCustomer =
          widget.customerData!['billToCustomer'] as Customer?;
      final shipToCustomer =
          widget.customerData!['shipToCustomer'] as Customer?;

      if (billToCustomer != null) {
        // Update customer bloc
        customerBloc.add(SelectBillToCustomer(billToCustomer));
        if (shipToCustomer != null) {
          customerBloc.add(SelectShipToCustomer(shipToCustomer));
        }

        // Note: UpdateCustomerInfo is already called in the previous screen
        // before navigation, so we don't need to dispatch it again here.
        // The quotation bloc already has the customer info.
      }
    }
  }
}

class QuotationItemEntryScreenContent extends StatefulWidget {
  const QuotationItemEntryScreenContent({super.key});

  @override
  State<QuotationItemEntryScreenContent> createState() =>
      _QuotationItemEntryScreenContentState();
}

class _QuotationItemEntryScreenContentState
    extends State<QuotationItemEntryScreenContent> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  QuotationOrderDetail? _currentFormDetail;
  bool _isEditing = false;
  int? _editingIndex;
  QuotationOrderDetail?
  _originalDetail; // Store original detail for cancellation

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    // Wait for the coordinator to be ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final coordinatorState = context.read<QuotationOrderBloc>().state;
      final selectedHeader = coordinatorState.selectedHeader;

      if (selectedHeader != null && selectedHeader.id != null) {
        setState(() {
          _currentFormDetail = QuotationOrderDetail(
            tempId: DateTime.now().millisecondsSinceEpoch,
            quoteOrderHeaderId: selectedHeader.id!,
            company: selectedHeader.company,
            itemsTableId: 0,
            quantity: 1.0,
            unitPrice: 0.0,
            extendedPrice: 0.0,
          );
        });
      } else {
        // If header not ready, listen for state changes
        final coordinatorBloc = context.read<QuotationOrderBloc>();
        coordinatorBloc.stream
            .firstWhere(
              (state) =>
                  state.selectedHeader != null &&
                  state.selectedHeader!.id != null,
            )
            .then((_) {
              if (mounted) {
                final header = coordinatorBloc.state.selectedHeader;
                if (header != null && header.id != null) {
                  setState(() {
                    _currentFormDetail = QuotationOrderDetail(
                      tempId: DateTime.now().millisecondsSinceEpoch,
                      quoteOrderHeaderId: header.id!,
                      company: header.company,
                      itemsTableId: 0,
                      quantity: 1.0,
                      unitPrice: 0.0,
                      extendedPrice: 0.0,
                    );
                  });
                }
              }
            });
      }
    });
  }

  void _startEditingItem(QuotationOrderDetail detail, int index) {
    setState(() {
      _currentFormDetail = detail.copyWith(); // Create a copy for editing
      _isEditing = true;
      _editingIndex = index;
      _originalDetail = detail; // Store original for cancellation
    });

    // Remove the item from confirmed list temporarily while editing
    context.read<QuotationOrderBloc>().add(
      RemoveQuotationOrderDetail(detail: detail),
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
      final coordinatorBloc = context.read<QuotationOrderBloc>();
      final coordinatorState = coordinatorBloc.state;

      context.read<QuotationOrderBloc>().add(
        AddQuotationOrderDetail(detail: _originalDetail!),
      );

      // Recalculate totals
      /*    context.read<QuotationOrderBloc>().add(
        const ValidateCompleteStockAvailability(),
      );*/
      context.read<QuotationOrderBloc>().add(
        CalculateQuotationTotals(
          header: coordinatorState.selectedHeader!,
          details: coordinatorState.createDetailItems,
        ),
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
      final coordinatorState = context.read<QuotationOrderBloc>().state;
      final selectedHeader = coordinatorState.selectedHeader;

      if (selectedHeader != null && selectedHeader.id != null) {
        _currentFormDetail = QuotationOrderDetail(
          tempId: DateTime.now().millisecondsSinceEpoch,
          quoteOrderHeaderId: selectedHeader.id!,
          company: selectedHeader.company,
          itemsTableId: 0,
          quantity: 1.0,
          unitPrice: 0.0,
          extendedPrice: 0.0,
        );
      }
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
        final coordinatorBloc = context.read<QuotationOrderBloc>();
        print('Dispatching AddDetailToOrder event');
        // Add or update the item in coordinator
        coordinatorBloc.add(
          AddQuotationOrderDetail(detail: _currentFormDetail!),
        );
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

  void _updateFormDetail(QuotationOrderDetail updatedDetail) {
    setState(() {
      _currentFormDetail = updatedDetail;
    });

    // Delegate UOM conversion and extended price calculation to integration service
    if (updatedDetail.itemInBranch != null) {
      final coordinatorState = context.read<QuotationOrderBloc>().state;
      context.read<QuotationOrderBloc>().add(
        UpdateUnitPriceWithUom(
          detail: updatedDetail,
          itemInBranch: updatedDetail.itemBranchRef!,
        ),
      );
      context.read<QuotationOrderBloc>().add(
        CalculateQuotationTotals(
          header: coordinatorState.selectedHeader!,
          details: coordinatorState.createDetailItems,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QuotationOrderBloc, QuotationOrderState>(
      builder: (context, coordinatorState) {
        // Show loading state while preparing
        if (coordinatorState.pendingOperations.contains(
              'prepare_new_quotation_order',
            ) ||
            coordinatorState.selectedHeader == null) {
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
                  child: QuoteItemEntryForm(
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
              flex: 2,
              child: QuoteItemEntryConfirmedItem(onEditItem: _startEditingItem),
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
            'Preparing Quotation Order...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
