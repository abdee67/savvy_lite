import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:savvy_stock/features/sales/customer/blocs/customer_bloc.dart';
import 'package:savvy_stock/features/sales/customer/blocs/customer_event.dart';
import 'package:savvy_stock/features/sales/customer/blocs/customer_state.dart';
import 'package:savvy_stock/features/sales/customer/models/customer_model.dart';

class CustomerListPage extends StatefulWidget {
  const CustomerListPage({super.key});

  @override
  State<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends State<CustomerListPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSelectionMode = false;
  final Map<int, double> _dragOffset = {};

  @override
  void initState() {
    super.initState();
    context.read<CustomerBloc>().add(LoadCustomers());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSearch(String query) {
    context.read<CustomerBloc>().add(SearchCustomers(query));
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<CustomerBloc>().add(SearchCustomers(''));
  }

  void _toggleCustomerSelection(Customer customer, bool selected) {
    context.read<CustomerBloc>().add(
      SelectCustomer(customer, isSelected: selected),
    );
  }

  void _showCustomerDetail(Customer customer) {
    if (!_isSelectionMode) {
      context.read<CustomerBloc>().add(ShowCustomerDetail(customer));
    }
  }

  void _hideCustomerDetail() {
    context.read<CustomerBloc>().add(HideCustomerDetail());
  }

  void _deleteSelectedCustomers() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customers'),
        content: const Text(
          'Are you sure you want to delete the selected customers?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<CustomerBloc>().add(DeleteSelectedCustomers());
              _isSelectionMode = false;
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _clearSelection() {
    context.read<CustomerBloc>().add(ClearSelection());
    _isSelectionMode = false;
  }

  void _callCustomer(String phone) {
    // Implement phone call functionality
    print('Calling: $phone');
  }

  void _emailCustomer(String? email) {
    if (email != null) {
      // Implement email functionality
      print('Emailing: $email');
    }
  }

  void _exportCustomer(Customer customer) {
    context.read<CustomerBloc>().add(ExportCustomer(customer));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Customer data exported')));
  }

  void _safeDeleteCustomer(BuildContext context, int index) {
    final bloc = context.read<CustomerBloc>();
    final state = bloc.state;

    // Validate the index
    if (index < 0 || index >= state.filteredCustomers.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete item. Invalid index.')),
      );
      return;
    }

    final itemToDelete = state.filteredCustomers[index];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${itemToDelete.name}"?'),
        content: Text(
          'Are you sure you want to delete "${itemToDelete.name}"?',
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              bloc.add(DeleteSelectedCustomers());
              // Show undo snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('"${itemToDelete.name}" deleted'),
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
        _safeDeleteCustomer(context, index);
        setState(() {
          _dragOffset.remove(index);
        });
      });
    } else {
      // Not far enough → snap back
      setState(() {
        _dragOffset[index] = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(title: const Text('Customer List')),
      body: BlocConsumer<CustomerBloc, CustomerState>(
        listener: (context, state) {
          // Update selection mode based on state
          if (state.selectedCustomers.isNotEmpty && !_isSelectionMode) {
            setState(() {
              _isSelectionMode = true;
            });
          } else if (state.selectedCustomers.isEmpty && _isSelectionMode) {
            setState(() {
              _isSelectionMode = false;
            });
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              Column(
                children: [
                  // Header with Search and Actions
                  _buildSearchBar(),
                  _buildActionButtons(state),
                  // Customer List
                  Expanded(child: _buildCustomerList(state)),
                ],
              ),

              // Detail Panel
              if (state.showDetailPanel && state.customerDetail != null)
                _buildDetailPanel(state.customerDetail!),
            ],
          );
        },
      ),

      // Floating Action Button for Add
      floatingActionButton: BlocBuilder<CustomerBloc, CustomerState>(
        builder: (context, state) {
          return FloatingActionButton(
            onPressed: () {
              if (state.canEdit) {
                // Navigate to edit screen with selected customer
                final customer = state.selectedCustomers.first;
                _navigateToEditScreen(customer);
              } else {
                // Navigate to add screen
                _navigateToAddScreen();
              }
            },
            backgroundColor: Colors.blue,
            child: Icon(
              state.canEdit ? Icons.edit : Icons.add,
              color: Colors.white,
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by name, phone, or email...',
          prefixIcon: const Icon(Iconsax.search_normal, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Iconsax.close_circle, size: 20),
                  onPressed: _clearSearch,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: _handleSearch,
      ),
    );
  }

  Widget _buildActionButtons(CustomerState state) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: state.isSelectionMode ? 60 : 0,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: state.isSelectionMode
          ? Row(
              children: [
                Text(
                  '${state.selectedCustomers.length} selected',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                if (state.canDelete)
                  IconButton(
                    icon: const Icon(Iconsax.trash, color: Colors.red),
                    onPressed: _deleteSelectedCustomers,
                    tooltip: 'Delete selected',
                  ),
                if (state.canEdit)
                  IconButton(
                    icon: const Icon(Iconsax.edit, color: Colors.blue),
                    onPressed: () {
                      final customer = state.selectedCustomers.first;
                      _navigateToEditScreen(customer);
                    },
                    tooltip: 'Edit customer',
                  ),
                IconButton(
                  icon: const Icon(Iconsax.close_circle),
                  onPressed: () => _clearSelection(),
                  tooltip: 'Clear selection',
                ),
              ],
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildCustomerList(CustomerState state) {
    if (state.status == CustomerStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == CustomerStatus.failure) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              state.errorMessage ?? 'Failed to load customers',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  context.read<CustomerBloc>().add(LoadCustomers()),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.filteredCustomers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.people, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              state.searchQuery.isEmpty
                  ? 'No customers found'
                  : 'No results for "${state.searchQuery}"',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: state.filteredCustomers.length,
      itemBuilder: (context, index) {
        final customer = state.filteredCustomers[index];
        final isSelected = state.selectedCustomers.contains(customer);

        return _buildCustomerListItem(customer, isSelected, state, index);
      },
    );
  }

  Widget _buildCustomerListItem(
    Customer customer,
    bool isSelected,
    CustomerState state,
    int index,
  ) {
    final offset = _dragOffset[index] ?? 0.0;
    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          // In selection mode, single tap toggles selection
          _toggleCustomerSelection(customer, !isSelected);
        }
      },
      onLongPress: () {
        // Long press enters selection mode and toggles this item
        if (!_isSelectionMode) {
          _isSelectionMode = true;
        }
        _toggleCustomerSelection(customer, !isSelected);
      },
      onHorizontalDragUpdate: (details) =>
          _onHorizontalDragUpdate(index, details),
      onHorizontalDragEnd: (details) =>
          _onHorizontalDragEnd(context, index, details),
      onDoubleTap: () => _showCustomerDetail(customer),
      child: Stack(
        children: [
          // 🔴 Background (delete indicator)
          Positioned.fill(
            child: Container(
              alignment: Alignment.centerRight,
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              margin: const EdgeInsets.only(bottom: 2),
              child: const Icon(Icons.delete, color: Colors.white, size: 28),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            transform: Matrix4.translationValues(offset, 0, 0),
            curve: Curves.easeOut,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue[50] : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.transparent,
                width: 2,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue : Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Iconsax.profile_circle,
                  color: isSelected ? Colors.white : Colors.grey[600],
                  size: 24,
                ),
              ),
              title: Text(
                customer.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (customer.contactName != null)
                    Text('Contact: ${customer.contactName}'),
                  if (customer.phone.isNotEmpty)
                    Text('Phone: ${customer.phone}'),
                  if (customer.email != null) Text('Email: ${customer.email}'),
                ],
              ),
              trailing: isSelected
                  ? const Icon(Iconsax.tick_circle, color: Colors.blue)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailPanel(Customer customer) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        height: 400,
        decoration: BoxDecoration(
          color: Colors.amber,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Close button
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _hideCustomerDetail,
              ),
            ),

            // Customer details
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        customer.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildDetailRow('Contact Name', customer.contactName),
                    _buildDetailRow('Phone', customer.phone),
                    _buildDetailRow('Email', customer.email),
                    _buildDetailRow('TIN', customer.tin),
                    _buildDetailRow('Country', customer.country),
                    _buildDetailRow('City', customer.city),
                    _buildDetailRow('Address', customer.addressLine1),

                    if (customer.addressLine2 != null)
                      _buildDetailRow('Address Line 2', customer.addressLine2),
                  ],
                ),
              ),
            ),

            // Action buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: const Icon(Iconsax.call, size: 28),
                    onPressed: () => _callCustomer(customer.phone),
                    tooltip: 'Call customer',
                  ),
                  IconButton(
                    icon: const Icon(Iconsax.sms, size: 28),
                    onPressed: () => _emailCustomer(customer.email),
                    tooltip: 'Email customer',
                  ),
                  IconButton(
                    icon: const Icon(Iconsax.export, size: 28),
                    onPressed: () => _exportCustomer(customer),
                    tooltip: 'Export customer data',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.black,
              fontSize: 12,
            ),
          ),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  void _navigateToAddScreen() {
    // Navigate to add customer screen
    print('Navigate to add customer screen');
  }

  void _navigateToEditScreen(Customer customer) {
    // Navigate to edit customer screen
    print('Navigate to edit customer screen for ${customer.name}');
  }
}
