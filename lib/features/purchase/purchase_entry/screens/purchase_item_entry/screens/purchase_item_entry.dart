// features/purchase/purchase_entry/screens/purchase_item_entry_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:savvy_stock/core/constants/app_routes.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/bloc/purchase_order_bloc.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/bloc/purchase_order_event.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/bloc/purchase_order_state.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/models/purchase_order_detail_model.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/screens/purchase_item_entry/widget/purchase_item_entry_confirmed_item.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/screens/purchase_item_entry/widget/purchase_item_entry_form.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_bloc.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_event.dart';

class PurchaseItemEntryScreen extends StatelessWidget {
  final Map<String, dynamic> orderData;

  const PurchaseItemEntryScreen({super.key, required this.orderData});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<PurchaseOrderBloc>(),
      child: PurchaseItemEntryScreenContent(orderData: orderData),
    );
  }
}

class PurchaseItemEntryScreenContent extends StatefulWidget {
  final Map<String, dynamic> orderData;

  const PurchaseItemEntryScreenContent({super.key, required this.orderData});

  @override
  State<PurchaseItemEntryScreenContent> createState() =>
      _PurchaseItemEntryScreenContentState();
}

class _PurchaseItemEntryScreenContentState
    extends State<PurchaseItemEntryScreenContent> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  PurchaseOrderDetail? _editingDetail;
  late PurchaseOrderDetail _newItemDetail; // Stable instance for new item
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();

    // Load necessary data for the screen
    _createNewItemDetail(); // Initialize the stable new item detail
    _loadInitialData();
  }

  void _loadInitialData() {
    final authState = context.read<AuthBloc>().state;
    final companyId = authState.companyId;

    if (companyId != null) {
      // Load initial data if needed
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Check if we have a valid purchase order header
        final purchaseState = context.read<PurchaseOrderBloc>().state;
        if (purchaseState.selectedHeader == null) {
          // If no header is selected, we need to go back or handle the error
          _showErrorSnackBar('Purchase order not properly initialized');
        }
      });
      context.read<StockItemsEntryBloc>().add(LoadItems(companyId));
    }
  }

  void _createNewItemDetail() {
    _newItemDetail = PurchaseOrderDetail(
      tempId: DateTime.now().millisecondsSinceEpoch,
      poHeader: widget
          .orderData['headerId'], // Assuming id is reachable or will be updated in build
      // We can't access bloc state easily here for header/company without context in initState sometimes,
      // but we can update it in build if needed, or just let the form populate defaults.
      // Better to initialize with minimal unique ID.
      quantityTransaction: 1.0,
      unitCost: 0.0,
      amountExtendedCost: 0.0,
      quantityOpen: 1.0,
      amountOpen: 0.0,
      dateDelivery: widget.orderData['deliveryDate'],
    );
  }

  void _startEditingItem(PurchaseOrderDetail detail, int index) {
    setState(() {
      _editingDetail = detail;
      _isEditing = true;
    });

    // Remove the item from confirmed list temporarily while editing
    context.read<PurchaseOrderBloc>().add(
      RemovePurchaseOrderDetailInCreate(detail: detail),
    );

    // Scroll to top to show the form
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
    if (_isEditing && _editingDetail != null) {
      // Add the original item back to confirmed list
      context.read<PurchaseOrderBloc>().add(
        AddPurchaseOrderDetail(detail: _editingDetail!),
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
      _editingDetail = null;
    });

    // Reset form
    _createNewItemDetail(); // Generate fresh ID for next new item
    _formKey.currentState?.reset();
  }

  void _confirmItem(PurchaseOrderDetail detail) {
    if (_formKey.currentState?.validate() ?? false) {
      if (_isEditing && _editingDetail != null) {
        // Update existing item - since it was removed on edit start, we just add it back
        // The index check against flawed current list state is removed
        context.read<PurchaseOrderBloc>().add(
          AddPurchaseOrderDetail(detail: detail),
        );

        // _showSuccessSnackBar('Item updated successfully');
      } else {
        // Add new item
        context.read<PurchaseOrderBloc>().add(
          AddPurchaseOrderDetail(detail: detail),
        );

        //   _showSuccessSnackBar('Item added successfully');
      }

      _resetForm();
      _createNewItemDetail(); // Ensure next item has fresh ID

      // Recalculate totals
      context.read<PurchaseOrderBloc>().add(CalculatePurchaseOrderTotals());
    } else {
      _showErrorSnackBar('Please fix validation errors');
    }
  }

  void _updateFormDetail(PurchaseOrderDetail updatedDetail) {
    // This method is called when the form is updated
    // We can update the detail in the BLoC if needed
    if (_isEditing) {
      // While editing, we don't update the BLoC until confirmation
      // Just update the local state
      setState(() {
        _editingDetail = updatedDetail;
      });
    }

    // Calculate extended cost
    if (updatedDetail.quantityTransaction != null &&
        updatedDetail.unitCost != null) {
      context.read<PurchaseOrderBloc>().add(
        CalculateExtendedCost(detail: updatedDetail),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _proceedToPayment() {
    final purchaseState = context.read<PurchaseOrderBloc>().state;

    if (purchaseState.createDetails.isEmpty) {
      _showErrorSnackBar('Please add at least one item to the order');
      return;
    }

    // Navigate to review screen
    context.push(AppRoutes.purchaseOrderPayment, extra: widget.orderData);
  }

  void _clearAllItems() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Items'),
        content: const Text(
          'Are you sure you want to remove all items from this order?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final bloc = context.read<PurchaseOrderBloc>();
              final details = List<PurchaseOrderDetail>.from(
                bloc.state.createDetails,
              );

              for (final detail in details) {
                bloc.add(RemovePurchaseOrderDetail(detail: detail));
              }

              Navigator.pop(context);
              _showSuccessSnackBar('All items cleared');
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PurchaseOrderBloc, PurchaseOrderState>(
      listener: (context, state) {
        // Handle errors
        if (state.error != null) {
          _showErrorSnackBar(state.error!);
        }

        // Handle success messages
        if (state.successMessage != null) {
          _showSuccessSnackBar(state.successMessage!);
        }
      },
      builder: (context, purchaseState) {
        // Show loading state while preparing
        if (purchaseState.status == PurchaseOrderStatus.loading &&
            purchaseState.pendingOperations.contains(
              'prepare_create_purchase_order',
            )) {
          return _buildLoadingState();
        }

        // Check if we have a valid header
        if (purchaseState.selectedHeader == null) {
          return _buildNoHeaderState();
        }

        // Get auto receipt setting
        final autoReceipt =
            purchaseState.autoReceipt ??
            widget.orderData['autoReceipt'] == true;

        // Create initial form detail - use stable instance
        // We update the stable instance with latest header/company info if needed,
        // but avoid changing tempId unless explicitly reset.
        final initialFormDetail =
            _editingDetail ??
            _newItemDetail.copyWith(
              poHeader: purchaseState.selectedHeader?.id,
              company: purchaseState.selectedHeader?.company,
            );

        return Scaffold(
          appBar: AppBar(
            title: const Text('Purchase Items Entry'),
            backgroundColor: const Color(0xFF155888),
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              // Auto Receipt Indicator
              if (autoReceipt)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.auto_awesome, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Auto Receipt',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              // Clear All Button
              if (purchaseState.createDetails.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_sweep),
                  tooltip: 'Clear All Items',
                  onPressed: _clearAllItems,
                ),
            ],
          ),
          body: Column(
            children: [
              // Order Information Banner
              _buildOrderInfoBanner(purchaseState),

              // Main Content (Form + Confirmed Items)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Form Section
                    Expanded(
                      flex: 4,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: PurchaseItemEntryForm(
                            initialDetail: initialFormDetail,
                            formKey: _formKey,
                            isEditing: _isEditing,
                            onUpdate: _updateFormDetail,
                            onConfirm: (detail) {
                              // When form is confirmed, use the detail passed from the form
                              _confirmItem(detail);
                            },
                            onCancel: _isEditing ? _cancelEditing : null,
                            orderData: {
                              ...widget.orderData,
                              'autoReceipt': autoReceipt,
                            },
                          ),
                        ),
                      ),
                    ),

                    // Confirmed Items Section
                    Expanded(
                      flex: 4,
                      child: PurchaseItemEntryConfirmedItem(
                        onEditItem: _startEditingItem,
                        onProceed: _proceedToPayment,
                        showProceedButton: true,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrderInfoBanner(PurchaseOrderState state) {
    final header = state.selectedHeader;
    final supplier = header?.supplierRef;
    final orderNumber = header?.orderNumber;
    final totalAmount = state.totalAmount ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF155888),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Supplier Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  supplier?.supplierName ?? 'No Supplier',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'PO #${orderNumber ?? 'N/A'}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),

          // Order Stats
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Order Total',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                '\$${totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${state.createDetails.length} items',
                style: const TextStyle(color: Colors.white70, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF155888)),
          ),
          SizedBox(height: 16),
          Text(
            'Preparing Purchase Order...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildNoHeaderState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.orange.shade400),
          const SizedBox(height: 16),
          const Text(
            'Purchase Order Not Initialized',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'The purchase order was not properly initialized. Please go back and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context.pop();
            },
            icon: const Icon(Icons.arrow_back),
            label: const Text('Go Back to Supplier Info'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF155888),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
