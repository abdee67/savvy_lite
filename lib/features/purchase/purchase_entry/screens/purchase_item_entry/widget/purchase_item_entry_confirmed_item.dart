import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:savvy_stock/core/constants/app_routes.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/bloc/purchase_order_bloc.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/bloc/purchase_order_event.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/bloc/purchase_order_state.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/models/purchase_order_detail_model.dart';

class PurchaseItemEntryConfirmedItem extends StatefulWidget {
  final Function(PurchaseOrderDetail, int) onEditItem;
  final VoidCallback? onProceed;
  final bool showProceedButton;

  const PurchaseItemEntryConfirmedItem({
    super.key,
    required this.onEditItem,
    this.onProceed,
    this.showProceedButton = true,
  });

  @override
  State<PurchaseItemEntryConfirmedItem> createState() =>
      _PurchaseItemEntryConfirmedItemState();
}

class _PurchaseItemEntryConfirmedItemState
    extends State<PurchaseItemEntryConfirmedItem> {
  final Map<int, double> _dragOffset = {};

  void _safeDeleteItem(BuildContext context, int index) {
    final purchaseOrderBloc = context.read<PurchaseOrderBloc>();
    final purchaseOrderState = purchaseOrderBloc.state;

    if (index < 0 || index >= purchaseOrderState.createDetails.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete item. Invalid index.')),
      );
      return;
    }

    final itemToDelete = purchaseOrderState.createDetails[index];

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
              purchaseOrderBloc.add(
                RemovePurchaseOrderDetail(detail: itemToDelete),
              );

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Item deleted'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _moveToEdit(BuildContext context, int index) {
    final purchaseState = context.read<PurchaseOrderBloc>().state;

    if (index < 0 || index >= purchaseState.createDetails.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot edit item. Invalid index.')),
      );
      return;
    }

    final itemToEdit = purchaseState.createDetails[index];
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
    final threshold = 80.0;

    if (current.abs() > threshold) {
      setState(() {
        _dragOffset[index] = -120.0;
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
    final purchaseState = context.read<PurchaseOrderBloc>().state;

    if (purchaseState.createDetails.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one item'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (widget.onProceed != null) {
      widget.onProceed!();
    } else {
      _navigateToPayment(context, purchaseState);
    }
  }

  void _navigateToPayment(BuildContext context, PurchaseOrderState state) {
    final authState = context.read<AuthBloc>().state;

    if (authState.hasAccessToPrivilege(AppRoutes.purchaseOrderPayment)) {
      context.push(AppRoutes.purchaseOrderPayment);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No access to payment screen')),
      );
    }
  }

  void _clearAllItems(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Items?'),
        content: const Text(
          'This will remove all items from the purchase order.',
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All items cleared'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PurchaseOrderBloc, PurchaseOrderState>(
      builder: (context, purchaseState) {
        final confirmedDetails = purchaseState.createDetails;
        final totalAmount = purchaseState.totalAmount ?? 0.0;
        final autoReceipt = purchaseState.autoReceipt ?? false;
        final itemCount = confirmedDetails.length;

        return Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
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
              // Header with Actions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF155888),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Top Row: Title and Count
                    Row(
                      children: [
                        const Icon(
                          Icons.shopping_cart_checkout,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Confirmed Purchase Items',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            itemCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (itemCount > 0)
                          IconButton(
                            icon: const Icon(
                              Icons.delete_sweep,
                              color: Colors.white,
                            ),
                            tooltip: 'Clear All',
                            onPressed: () => _clearAllItems(context),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Summary Row
                    Row(
                      children: [
                        // Total Amount
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Order Total',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '\$${totalAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Auto Receipt Status
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Receipt Mode',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: autoReceipt
                                      ? Colors.green
                                      : Colors.orange,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      autoReceipt
                                          ? Icons.auto_awesome
                                          : Icons.work_outline,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      autoReceipt
                                          ? 'Auto Receipt'
                                          : 'Manual Receipt',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
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
                            height: 90,
                            margin: const EdgeInsets.only(bottom: 8),
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
                                        children: [
                                          // Item Number
                                          Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFF155888,
                                              ).withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              '${index + 1}',
                                              style: const TextStyle(
                                                color: Color(0xFF155888),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),

                                          // Item details
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                // Item Name
                                                Text(
                                                  item
                                                          .itemNumberRef
                                                          ?.itemDescription ??
                                                      'Item #${item.itemNumber ?? 'N/A'}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),

                                                // Details row
                                                Row(
                                                  children: [
                                                    // Quantity
                                                    _buildDetailChip(
                                                      icon: Icons.scale,
                                                      text:
                                                          '${item.quantityTransaction?.toStringAsFixed(2) ?? '0'} ${item.unitOfMeasureRef?.description1 ?? 'EA'}',
                                                      color: Colors.blue,
                                                    ),
                                                    const SizedBox(width: 8),

                                                    // Unit Cost
                                                    _buildDetailChip(
                                                      icon: Icons.attach_money,
                                                      text:
                                                          '\$${item.unitCost?.toStringAsFixed(2) ?? '0'}',
                                                      color: Colors.green,
                                                    ),
                                                  ],
                                                ),

                                                // Batch number if exists
                                                if (item.batchNumberSupplier !=
                                                        null &&
                                                    item
                                                        .batchNumberSupplier!
                                                        .isNotEmpty)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          top: 4,
                                                        ),
                                                    child: Text(
                                                      'Batch: ${item.batchNumberSupplier}',
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                        color: Colors.grey,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),

                                          // Extended Cost
                                          Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              const Text(
                                                'Total',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '\$${item.amountExtendedCost?.toStringAsFixed(2) ?? '0.00'}',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF155888),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(width: 8),

                                          // Edit Icon
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit,
                                              size: 18,
                                              color: Colors.grey,
                                            ),
                                            onPressed: () =>
                                                _moveToEdit(context, index),
                                            tooltip: 'Edit Item',
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

              // Footer Actions (if showProceedButton is true)
              if (widget.showProceedButton)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade300, width: 1),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Back Button
                          OutlinedButton.icon(
                            onPressed: () {
                              context.pop();
                            },
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Back'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF155888),
                              side: const BorderSide(color: Color(0xFF155888)),
                            ),
                          ),

                          // Proceed Button
                          ElevatedButton.icon(
                            onPressed: confirmedDetails.isNotEmpty
                                ? () => _validateAndProceed(context)
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: confirmedDetails.isNotEmpty
                                  ? const Color(0xFF155888)
                                  : Colors.grey,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text('Proceed to Review'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Help text
                      Text(
                        'Double tap or tap edit icon to edit • Swipe left to delete',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      // Item count summary
                      if (confirmedDetails.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '$itemCount item${itemCount == 1 ? '' : 's'} • Total: \$${totalAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
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

  Widget _buildDetailChip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No items added yet',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Add purchase items using the form above to build your purchase order',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              // Scroll to form or show form
              if (widget.onProceed != null) {
                widget.onProceed!();
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Add First Item'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF155888),
              side: const BorderSide(color: Color(0xFF155888)),
            ),
          ),
        ],
      ),
    );
  }
}
