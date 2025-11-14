// features/sales/sales_item_entry/widgets/sales_item_entry_confirmed_item.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:savvy_stock/core/constants/app_routes.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/sales/customer/blocs/customer_bloc.dart';
import 'package:savvy_stock/features/sales/customer/models/customer_model.dart';
import 'package:savvy_stock/features/sales/sales_order/detail/model/sales_order_detail.dart';
import 'package:savvy_stock/features/sales/sales_order/integration/bloc/sales_order_coordinator_bloc.dart';
import 'package:savvy_stock/features/sales/sales_order/integration/bloc/sales_order_coordinator_event.dart';
import 'package:savvy_stock/features/sales/sales_order/integration/bloc/sales_order_coordinator_state.dart';

class SalesItemEntryConfirmedItem extends StatefulWidget {
  final List<GlobalKey<FormState>> formKeys;
  const SalesItemEntryConfirmedItem({super.key, required this.formKeys});

  @override
  State<SalesItemEntryConfirmedItem> createState() =>
      _SalesItemEntryConfirmedItemState();
}

class _SalesItemEntryConfirmedItemState
    extends State<SalesItemEntryConfirmedItem> {
  final Map<int, double> _dragOffset = {};
  final ScrollController _scrollController = ScrollController();

  void _safeDeleteItem(BuildContext context, int index) {
    final coordinatorBloc = context.read<SalesOrderCoordinatorBloc>();
    final coordinatorState = coordinatorBloc.state;

    if (index < 0 || index >= coordinatorState.currentDetails.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete item. Invalid index.')),
      );
      return;
    }

    final itemToDelete = coordinatorState.currentDetails[index];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item?'),
        content: Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              coordinatorBloc.add(RemoveDetailFromOrder(detail: itemToDelete));

              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Item deleted')));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _moveToEdit(BuildContext context, int index) {
    // In this implementation, items are always editable in the form section
    // This function could be used to highlight or scroll to the item
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Item can be edited in the form above')),
    );
  }

  void _onHorizontalDragUpdate(int index, DragUpdateDetails details) {
    setState(() {
      final current = _dragOffset[index] ?? 0;
      var newOffset = current + details.delta.dx;
      if (newOffset > 0) newOffset = 0;
      _dragOffset[index] = newOffset;
    });
  }

  void _onHorizontalDragEnd(
    BuildContext context,
    int index,
    DragEndDetails details,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final threshold = screenWidth * 0.3;
    final current = _dragOffset[index] ?? 0;

    if (current.abs() > threshold) {
      setState(() {
        _dragOffset[index] = -screenWidth;
      });

      Future.delayed(const Duration(milliseconds: 300), () {
        _safeDeleteItem(context, index);
        if (mounted) {
          setState(() {
            _dragOffset.remove(index);
          });
        }
      });
    } else {
      setState(() {
        _dragOffset[index] = 0.0;
      });
    }
  }

  void _validateAndProceed(BuildContext context) {
    // Validate all forms
    bool allValid = true;
    for (final formKey in widget.formKeys) {
      if (formKey.currentState != null && !formKey.currentState!.validate()) {
        allValid = false;
        break;
      }
    }

    if (!allValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix validation errors in the forms'),
        ),
      );
      return;
    }

    final coordinatorBloc = context.read<SalesOrderCoordinatorBloc>();
    final coordinatorState = coordinatorBloc.state;

    if (coordinatorState.currentDetails.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item')),
      );
      return;
    }

    // Validate stock availability
    if (!coordinatorState.isStockValidated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please validate stock availability first'),
        ),
      );
      return;
    }

    _navigateToSummary(context, coordinatorState);
  }

  void _navigateToSummary(
    BuildContext context,
    SalesOrderCoordinatorState state,
  ) {
    final customerBloc = context.read<CustomerBloc>();
    final selectedCustomer = customerBloc.state.selectedBillToCustomer;

    if (selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer first')),
      );
      return;
    }

    if (context.read<AuthBloc>().state.hasAccessToPrivilege(
      AppRoutes.paymentSummary,
    )) {
      context.push(
        AppRoutes.paymentSummary,
        extra: {
          'customer': selectedCustomer,
          'orderDetails': state.currentDetails,
          'orderHeader': state.currentHeader,
          'totalAmount': state.lastTotalAmount ?? 0.0,
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No access to payment summary')),
      );
    }
  }

  double _calculateTotalAmount(List<SalesOrderDetail> details) {
    return details.fold<double>(0.0, (sum, detail) {
      return sum + (detail.extendedPrice ?? 0.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SalesOrderCoordinatorBloc, SalesOrderCoordinatorState>(
      builder: (context, coordinatorState) {
        final confirmedDetails = coordinatorState.currentDetails;
        final totalAmount =
            coordinatorState.lastTotalAmount ??
            _calculateTotalAmount(confirmedDetails);

        return Expanded(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.only(
                    top: 50,
                    left: 16,
                    right: 16,
                    bottom: 16,
                  ),
                  child: Column(
                    children: [
                      // Header
                      Text(
                        'Order Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Items List
                      Expanded(
                        child: confirmedDetails.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                controller: _scrollController,
                                itemCount: confirmedDetails.length,
                                itemBuilder: (context, index) {
                                  final item = confirmedDetails[index];
                                  final offset = _dragOffset[index] ?? 0.0;

                                  return GestureDetector(
                                    onDoubleTap: () =>
                                        _moveToEdit(context, index),
                                    onHorizontalDragUpdate: (details) =>
                                        _onHorizontalDragUpdate(index, details),
                                    onHorizontalDragEnd: (details) =>
                                        _onHorizontalDragEnd(
                                          context,
                                          index,
                                          details,
                                        ),
                                    child: Stack(
                                      children: [
                                        // Delete background
                                        Positioned.fill(
                                          child: Container(
                                            alignment: Alignment.centerRight,
                                            decoration: BoxDecoration(
                                              color: Colors.redAccent,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                            ),
                                            margin: const EdgeInsets.only(
                                              bottom: 8,
                                            ),
                                            child: const Icon(
                                              Icons.delete,
                                              color: Colors.white,
                                              size: 28,
                                            ),
                                          ),
                                        ),

                                        // Item card
                                        AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          transform: Matrix4.translationValues(
                                            offset,
                                            0,
                                            0,
                                          ),
                                          curve: Curves.easeOut,
                                          margin: const EdgeInsets.only(
                                            bottom: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.1,
                                                ),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Row(
                                              children: [
                                                // Item info
                                                Expanded(
                                                  flex: 3,
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Item ${index + 1}',
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                      if (item.extendedPrice !=
                                                          null)
                                                        Text(
                                                          'Total: \$${item.extendedPrice!.toStringAsFixed(2)}',
                                                          style:
                                                              const TextStyle(
                                                                color: Colors
                                                                    .green,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                        ),
                                                    ],
                                                  ),
                                                ),

                                                // Quantity
                                                Expanded(
                                                  child: Text(
                                                    'Qty: ${item.quantity?.toStringAsFixed(2) ?? '0'}',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),

                                                // Unit Price
                                                Expanded(
                                                  child: Text(
                                                    'Price: \$${item.unitPrice?.toStringAsFixed(2) ?? '0'}',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),

                      const SizedBox(height: 16),

                      // Total Amount
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: const Color(0xFF155888),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Grand Total',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              '\$${totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Continue Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: confirmedDetails.isNotEmpty
                              ? () => _validateAndProceed(context)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF155888),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Save & Continue to Payment',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Validate & Calculate Button
              Positioned(
                right: 16,
                top: -25,
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: confirmedDetails.isNotEmpty
                        ? () {
                            context.read<SalesOrderCoordinatorBloc>().add(
                              const ValidateCompleteStockAvailability(),
                            );
                            context.read<SalesOrderCoordinatorBloc>().add(
                              const CalculateCompleteOrderTotals(),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: confirmedDetails.isNotEmpty
                          ? Colors.orange
                          : Colors.grey,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 4,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calculate, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Validate & Calculate',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No items confirmed yet',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Add items above and click "Confirm Item"',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
