// features/sales/sales_item_entry/widgets/sales_item_entry_confirmed_item.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:savvy_stock/core/constants/app_routes.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/sales/customer/blocs/customer_bloc.dart';
import 'package:savvy_stock/features/sales/sales_order/detail/model/sales_order_detail.dart';
import 'package:savvy_stock/features/sales/sales_order/integration/bloc/sales_order_coordinator_bloc.dart';
import 'package:savvy_stock/features/sales/sales_order/integration/bloc/sales_order_coordinator_event.dart';
import 'package:savvy_stock/features/sales/sales_order/integration/bloc/sales_order_coordinator_state.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_bloc.dart';

class SalesItemEntryConfirmedItem extends StatefulWidget {
  final Function(SalesOrderDetail, int) onEditItem;

  const SalesItemEntryConfirmedItem({super.key, required this.onEditItem});

  @override
  State<SalesItemEntryConfirmedItem> createState() =>
      _SalesItemEntryConfirmedItemState();
}

class _SalesItemEntryConfirmedItemState
    extends State<SalesItemEntryConfirmedItem> {
  final Map<int, double> _dragOffset = {};
  static const _elevatedButtonBorderRadius = 20.0;
  static const _horizontalPadding32 = 32.0;
  static const _verticalPadding12 = 12.0;
  static const _titleFontSize = 16.0;
  late int? decimalPlace;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  void _initialize() {
    decimalPlace = context
        .read<SystemConstantBloc>()
        .state
        .selected
        ?.decimalPlaces;
  }

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
        content: const Text('Are you sure you want to delete this item?'),
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
    final coordinatorState = context.read<SalesOrderCoordinatorBloc>().state;

    if (index < 0 || index >= coordinatorState.currentDetails.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot edit item. Invalid index.')),
      );
      return;
    }

    final itemToEdit = coordinatorState.currentDetails[index];
    widget.onEditItem(itemToEdit, index);
  }

  void _onHorizontalDragUpdate(int index, DragUpdateDetails details) {
    setState(() {
      final current = _dragOffset[index] ?? 0;
      var newOffset = current + details.delta.dx;
      // Limit swipe to left only (negative values) and maximum swipe distance
      if (newOffset > 0) newOffset = 0;
      if (newOffset < -120) newOffset = -120; // Limit maximum swipe
      _dragOffset[index] = newOffset;
    });
  }

  void _onHorizontalDragEnd(
    BuildContext context,
    int index,
    DragEndDetails details,
  ) {
    final current = _dragOffset[index] ?? 0;
    final threshold = 80.0; // Fixed threshold instead of screen percentage

    if (current.abs() > threshold) {
      setState(() {
        _dragOffset[index] = -120.0; // Swipe to show delete fully
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
    final coordinatorBloc = context.read<SalesOrderCoordinatorBloc>();
    final coordinatorState = coordinatorBloc.state;
    context.read<SalesOrderCoordinatorBloc>().add(
      const CalculateCompleteOrderTotals(),
    );
    if (coordinatorState.currentDetails.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item')),
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
          'coordinatorReady': true, // Flag to indicate coordinator has data
          'timestamp': DateTime.now().millisecondsSinceEpoch,
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

        return Container(
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
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF155888),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.shopping_cart,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Confirmed Items',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Total: ${NumberFormat.currency(decimalDigits: decimalPlace, symbol: 'ETB ').format(totalAmount)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Items List
              Expanded(
                child: confirmedDetails.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: confirmedDetails.length,
                        itemBuilder: (context, index) {
                          final item = confirmedDetails[index];
                          final offset = _dragOffset[index] ?? 0.0;

                          return Container(
                            height: 65,
                            margin: const EdgeInsets.only(bottom: 4),
                            child: GestureDetector(
                              onDoubleTap: () => _moveToEdit(context, index),
                              onHorizontalDragUpdate: (details) =>
                                  _onHorizontalDragUpdate(index, details),
                              onHorizontalDragEnd: (details) =>
                                  _onHorizontalDragEnd(context, index, details),
                              child: Stack(
                                children: [
                                  // Delete background
                                  Positioned.fill(
                                    child: Container(
                                      alignment: Alignment.centerRight,
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
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
                                    duration: const Duration(milliseconds: 200),
                                    transform: Matrix4.translationValues(
                                      offset,
                                      0,
                                      0,
                                    ),
                                    curve: Curves.easeOut,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          // Item info
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  item.item?.itemDescription ??
                                                      'Item ${index + 1}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                if (item.extendedPrice != null)
                                                  Text(
                                                    'Total: ${NumberFormat.currency(decimalDigits: decimalPlace, symbol: 'ETB ').format(item.extendedPrice)}',
                                                    style: const TextStyle(
                                                      color: Colors.green,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontSize: 12,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                              ],
                                            ),
                                          ),

                                          // Quantity
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  'Qty: ${item.quantity?.toStringAsFixed(decimalPlace ?? 2) ?? '0'}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                Text(
                                                  'Price: ${NumberFormat.currency(decimalDigits: decimalPlace, symbol: 'ETB ').format(item.unitPrice)} / ${item.uom?.description1}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // Footer Actions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Action Buttons
                    Container(
                      alignment: Alignment.bottomRight,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: confirmedDetails.isNotEmpty
                                ? () => _validateAndProceed(context)
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
                              'Proceed to payment ',
                              style: TextStyle(fontSize: _titleFontSize),
                            ),
                          ),
                        ],
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 30, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No items confirmed yet',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
