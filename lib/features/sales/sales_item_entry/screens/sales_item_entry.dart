import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:savvy_stock/features/sales/customer/blocs/customer_bloc.dart';
import 'package:savvy_stock/features/sales/customer/models/customer_model.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/blocs/sales_item_entry_bloc.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/blocs/sales_item_entry_event.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/blocs/sales_item_entry_state.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/widget/sales_item_entry_confirmed_item.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/widget/sales_item_entry_form.dart';

class ItemEntryScreen extends StatelessWidget {
  const ItemEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final customerBloc = context.read<CustomerBloc>();
    context.read<ItemEntryBloc>().add(
      LoadItemsAndStores(customerBloc: customerBloc),
    );
    return ItemEntryScreenView();
  }
}

class ItemEntryScreenView extends StatefulWidget {
  const ItemEntryScreenView({super.key});

  @override
  State<ItemEntryScreenView> createState() => _ItemEntryScreenViewState();
}

class _ItemEntryScreenViewState extends State<ItemEntryScreenView> {
  final List<GlobalKey<FormState>> _formKeys = [];

  @override
  void initState() {
    super.initState();
    // Initialize form keys based on initial selectedItems
    _initializeFormKeys();
  }

  void _initializeFormKeys() {
    final state = context.read<ItemEntryBloc>().state;
    _formKeys.clear();
    _formKeys.addAll(
      List.generate(
        state.selectedItems.length,
        (index) => GlobalKey<FormState>(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Debug: Check global CustomerBloc
    final customerBloc = context.read<CustomerBloc>();
    print(
      'Global CustomerBloc selected customer: ${customerBloc.state.selectedBillToCustomer.name}',
    );

    // Debug: Check global ItemEntryBloc
    final itemEntryBloc = context.read<ItemEntryBloc>();
    print(
      'Global ItemEntryBloc items: ${itemEntryBloc.state.confirmedItems.length}',
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Sales Item Entry')),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: BlocConsumer<ItemEntryBloc, ItemEntryState>(
          listener: (context, state) {
            if (state.status == ItemEntryStatus.failure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage ?? 'An error occurred'),
                ),
              );
            }
            if (_formKeys.length != state.selectedItems.length) {
              setState(() {
                if (_formKeys.length < state.selectedItems.length) {
                  // Add new keys for new items
                  for (
                    int i = _formKeys.length;
                    i < state.selectedItems.length;
                    i++
                  ) {
                    _formKeys.add(GlobalKey<FormState>());
                  }
                } else {
                  // Remove excess keys
                  _formKeys.removeRange(
                    state.selectedItems.length,
                    _formKeys.length,
                  );
                }
              });
            }
          },
          builder: (context, state) {
            return Column(
              children: [
                // Upper Section - Order Items
                Expanded(
                  flex: 1,
                  child: Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: state.selectedItems.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4.0),
                                child: SalesItemEntryForm(index: index),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Lower Section - Order Summary
                SalesItemEntryConfirmedItem(),
              ],
            );
          },
        ),
      ),
    );
  }
}
