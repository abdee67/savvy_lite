import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/stock/item_UoM_conversions/blocs/item_UoM_conversions_bloc.dart';
import 'package:savvy_stock/features/stock/item_UoM_conversions/blocs/item_UoM_conversions_event.dart';
import 'package:savvy_stock/features/stock/item_UoM_conversions/blocs/item_UoM_conversions_state.dart';
import 'package:savvy_stock/features/stock/item_UoM_conversions/models/item_UoM_conversions_model.dart';
import 'package:savvy_stock/features/stock/item_UoM_conversions/widgets/item_UoM_conversion_create_and_edit.dart.dart';

class ItemUomConversionListScreen extends StatefulWidget {
  final AuthBloc authBloc;

  const ItemUomConversionListScreen({super.key, required this.authBloc});

  @override
  State<ItemUomConversionListScreen> createState() =>
      _ItemUomConversionListScreenState();
}

class _ItemUomConversionListScreenState
    extends State<ItemUomConversionListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load UoM conversions when screen initializes
    context.read<ItemUomConversionBloc>().add(
      LoadItemUomConversions(widget.authBloc.state.companyId!),
    );
  }

  void _navigateToCreateForm() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => BlocProvider.value(
              value: context.read<ItemUomConversionBloc>(),
              child: ItemUomConversionForm(authBloc: widget.authBloc),
            ),
          ),
        )
        .then((_) {
          // Refresh list when returning from form
          context.read<ItemUomConversionBloc>().add(
            LoadItemUomConversions(widget.authBloc.state.companyId!),
          );
        });
  }

  void _navigateToEditForm(ItemUomConversion item) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => BlocProvider.value(
              value: context.read<ItemUomConversionBloc>(),
              child: ItemUomConversionForm(
                authBloc: widget.authBloc,
                editingItem: item,
              ),
            ),
          ),
        )
        .then((_) {
          // Refresh list when returning from form
          context.read<ItemUomConversionBloc>().add(
            LoadItemUomConversions(widget.authBloc.state.companyId!),
          );
        });
  }

  void _deleteItem(ItemUomConversion item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text(
            'Are you sure you want to delete this UoM conversion?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<ItemUomConversionBloc>().add(
                  DeleteItemUomConversion(item),
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UoM Conversions'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _navigateToCreateForm,
            tooltip: 'Create New UoM Conversion',
          ),
        ],
      ),
      body: BlocConsumer<ItemUomConversionBloc, ItemUomConversionState>(
        listener: (context, state) {
          if (state.status == ItemUomConversionStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.message ?? 'Operation completed successfully',
                ),
                backgroundColor: Colors.green,
              ),
            );
            // Refresh list after successful operation
            context.read<ItemUomConversionBloc>().add(
              LoadItemUomConversions(widget.authBloc.state.companyId!),
            );
          } else if (state.status == ItemUomConversionStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message ?? 'An error occurred'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextFormField(
                  controller: _searchController,
                  onChanged: (query) {
                    // Implement search functionality if needed
                  },
                  decoration: const InputDecoration(
                    hintText: 'Search UoM conversions...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),

              // Data Table
              Expanded(child: _buildDataTable()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDataTable() {
    return BlocBuilder<ItemUomConversionBloc, ItemUomConversionState>(
      builder: (context, state) {
        if (state.status == ItemUomConversionStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.items.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.swap_horiz, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No UoM conversions found',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Click the + button to create a new UoM conversion',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: state.items.length,
          itemBuilder: (context, index) {
            final item = state.items[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                title: Text('Item: ${item.itemNumber}'),
                subtitle: Text(
                  '${item.fromUom} → ${item.toUom} (Factor: ${item.conversionFactor})',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _navigateToEditForm(item),
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteItem(item),
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
