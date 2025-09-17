import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:savvy_stock/features/sales/customer/blocs/customer_bloc.dart';
import 'package:savvy_stock/features/sales/customer/models/customer_model.dart';
import 'package:savvy_stock/features/sales/payment/screens/paymentSummary.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/blocs/sales_item_entry_bloc.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/blocs/sales_item_entry_event.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/blocs/sales_item_entry_state.dart';

class SalesItemEntryConfirmedItem extends StatefulWidget {
  const SalesItemEntryConfirmedItem({super.key});

  @override
  State<SalesItemEntryConfirmedItem> createState() =>
      _SalesItemEntryConfirmedItemState();
}

class _SalesItemEntryConfirmedItemState
    extends State<SalesItemEntryConfirmedItem> {
  final Map<int, double> _dragOffset = {};
  final List<GlobalKey<FormState>> _formKeys = [];
  final ScrollController _upperScrollController = ScrollController();
  bool _initialized = false;
  void _safeDeleteItem(BuildContext context, int index) {
    final bloc = context.read<ItemEntryBloc>();
    final state = bloc.state;

    // Validate the index
    if (index < 0 || index >= state.confirmedItems.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete item. Invalid index.')),
      );
      return;
    }

    final itemToDelete = state.confirmedItems[index];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${itemToDelete.itemName}"?'),
        content: Text(
          'Are you sure you want to delete "${itemToDelete.itemName}"?',
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              bloc.add(DeleteConfirmedItem(index: index));
              // Show undo snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('"${itemToDelete.itemName}" deleted'),
                  action: SnackBarAction(
                    label: 'UNDO',
                    onPressed: () {
                      // Add undo functionality if needed
                      bloc.add(
                        UndoDelete(
                          deletedItem: itemToDelete,
                          deletedIndex: index,
                        ),
                      );
                    },
                  ),
                  duration: const Duration(seconds: 5),
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
    final bloc = context.read<ItemEntryBloc>();
    bloc.add(MoveToEdit(confirmedIndex: index));

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Item moved to edit section')));
  }

  void _onHorizontalDragUpdate(int index, DragUpdateDetails details) {
    setState(() {
      final current = _dragOffset[index] ?? 0;
      var newOffset = current + details.delta.dx;

      // only allow left swipe
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
    final threshold = screenWidth * 0.3; // ✅ 30% of screen width
    final current = _dragOffset[index] ?? 0;
    if (current.abs() > threshold) {
      // Swipe far enough → delete
      setState(() {
        _dragOffset[index] = -screenWidth; // slide fully left
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
      // Not far enough → snap back
      setState(() {
        _dragOffset[index] = 0.0;
      });
    }
  }

  void _confirmOrder(BuildContext context) {
    // Validate all forms
    bool allValid = true;
    for (int i = 0; i < _formKeys.length; i++) {
      if (_formKeys[i].currentState != null &&
          !_formKeys[i].currentState!.validate()) {
        allValid = false;

        // Scroll to the first invalid field
        _upperScrollController.animateTo(
          i * 300.0, // Adjust based on your item height
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        break;
      }
    }

    if (allValid) {
      context.read<ItemEntryBloc>().add(ConfirmOrder());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix validation errors')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    final padding = isSmallScreen ? 12.0 : 16.0;
    return BlocConsumer<ItemEntryBloc, ItemEntryState>(
      listener: (context, state) {
        if (!_initialized) {
          _initialized = true;
        }
      },
      builder: (context, state) {
        return Expanded(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade500,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  padding: const EdgeInsets.only(
                    top: 30, //spacing for confirm button
                    left: 10,
                    right: 10,
                    bottom: 16,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 4),
                      Expanded(
                        child: state.confirmedItems.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                itemCount: state.confirmedItems.length,
                                itemBuilder: (context, index) {
                                  final item = state.confirmedItems[index];
                                  final isSelected = state
                                      .selectedConfirmedItemIndices
                                      .contains(index);
                                  final itemPrice = state.itemsInStores
                                      .firstWhere(
                                        (element) =>
                                            element.item.id == item.itemId,
                                      )
                                      .unitPrice;
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
                                        // 🔴 Background (delete indicator)
                                        Positioned.fill(
                                          child: Container(
                                            alignment: Alignment.centerRight,
                                            decoration: BoxDecoration(
                                              color: Colors.redAccent,
                                              borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(20),
                                                topRight: Radius.circular(20),
                                                bottomLeft: Radius.circular(20),
                                                bottomRight: Radius.circular(
                                                  20,
                                                ),
                                              ),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                            ),
                                            margin: const EdgeInsets.only(
                                              bottom: 2,
                                            ),
                                            child: const Icon(
                                              Icons.delete,
                                              color: Colors.white,
                                              size: 28,
                                            ),
                                          ),
                                        ),

                                        // 🟢 Foreground (draggable card)
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
                                            bottom: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? Colors.grey.shade200
                                                : Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.1,
                                                ),
                                                blurRadius: 6,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                            border: isSelected
                                                ? Border.all(
                                                    color: Colors.black,
                                                  )
                                                : null,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    item.itemName,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    item.quantity
                                                        .toStringAsFixed(2),
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    itemPrice.toString(),
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    '\$${item.totalPrice.toStringAsFixed(2)}',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                    textAlign: TextAlign.end,
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
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: const Color.fromARGB(255, 29, 91, 134),
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
                              '\$${state.totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: ElevatedButton(
                          onPressed: state.totalAmount > 0
                              ? () => _navigateToSummary(context, state)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(
                              255,
                              24,
                              103,
                              160,
                            ),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Save & Continue'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Confirm Order Button
              Positioned(
                right: 16,
                top: -20,
                child: SizedBox(
                  width: 150,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: state.hasValidItems
                        ? () => _confirmOrder(context)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: state.hasValidItems
                          ? const Color.fromARGB(255, 29, 110, 168)
                          : Colors.grey,
                      foregroundColor: state.hasValidItems
                          ? Colors.white
                          : Colors.black,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 4,
                    ),
                    child: Text(
                      state.hasValidItems ? 'Confirm Order' : 'Select item',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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

  void _navigateToSummary(BuildContext context, ItemEntryState state) {
    final customerBloc = context.read<CustomerBloc>();
    final selectedCustomerFromBloc = customerBloc.state.selectedBillToCustomer;
    final selectedCustomerFromState = state.customer;

    print(
      'Customer from Bloc: "${selectedCustomerFromBloc.name}" (ID: ${selectedCustomerFromBloc.id})',
    );
    print(
      'Customer from State: "${selectedCustomerFromState.name}" (ID: ${selectedCustomerFromState.id})',
    );
    print('Customer isEmpty: ${selectedCustomerFromState.isEmpty}');
    print(
      'Customer == Customer.empty: ${selectedCustomerFromState == Customer.empty}',
    );
    if (selectedCustomerFromState.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer first')),
      );
      return;
    }
    context.push(
      '/payment-screen',
      extra: {
        'confirmedItems': state.confirmedItems,
        'totalAmount': state.totalAmount,
        'customer': selectedCustomerFromState,
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 48,
            color: Color(0xFF155888),
          ),
          SizedBox(height: 16),
          Text(
            'No items added yet',
            style: TextStyle(fontSize: 16, color: Color(0xFF155888)),
          ),
        ],
      ),
    );
  }
}
