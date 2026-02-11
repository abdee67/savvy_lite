import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:savvy_stock/core/constants/app_routes.dart';
import 'package:savvy_stock/core/utils/ui_helper.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/sales/customer/blocs/customer_bloc.dart';
import 'package:savvy_stock/features/sales/customer/blocs/customer_event.dart';
import 'package:savvy_stock/features/sales/customer/blocs/customer_state.dart';
import 'package:savvy_stock/features/sales/customer/models/customer_model.dart';

class CustomerListPage extends StatefulWidget {
  final AuthBloc authBloc;
  const CustomerListPage({super.key, required this.authBloc});

  @override
  State<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends State<CustomerListPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSelectionMode = false;
  final Map<int, double> _dragOffset = {};

  // Animation controllers for detail panel
  late AnimationController _detailAnimationController;
  late Animation<double> _heightAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  // Detail panel state
  Customer? _selectedCustomer;
  bool _customerDetail = false;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _detailAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Set up animations
    _setupAnimations();

    context.read<CustomerBloc>().add(
      LoadCustomers(widget.authBloc.state.companyId!),
    );
  }

  void _setupAnimations() {
    _heightAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _detailAnimationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOutCubic),
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _detailAnimationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, -0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _detailAnimationController,
            curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
          ),
        );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _detailAnimationController.dispose();
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
    context.read<CustomerBloc>().add(SelectCustomer(customer, selected));
  }

  void _showCustomerDetail(Customer customer) {
    setState(() {
      _selectedCustomer = customer;
      _customerDetail = true;
    });

    // Start the animation
    _detailAnimationController.forward(from: 0.0);
  }

  void _hideCustomerDetail() {
    // Reverse the animation
    _detailAnimationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _customerDetail = false;
          _selectedCustomer = null;
        });
      }
    });
  }

  void _safeDelete(BuildContext context, {int? index}) {
    final bloc = context.read<CustomerBloc>();
    final state = bloc.state;

    if (state.selectedCustomers.isNotEmpty) {
      final itemsToDelete = state.selectedCustomers;
      showDeleteDialog(
        context,
        title: 'Delete selected customers?',
        content:
            'Are you sure you want to delete ${itemsToDelete.length} customers?',
        onConfirm: () {
          final ids = itemsToDelete.map((e) => e.id!).toList();
          final deletedIndexes = itemsToDelete
              .map((emp) => state.filteredCustomers.indexOf(emp))
              .toList();
          bloc.add(
            DeleteSelectedCustomers(
              selectedItems: ids,
              deletedItems: itemsToDelete,
              deletedIndexes: deletedIndexes,
            ),
          );
        },
      );
      return;
    }
    if (index == null || index < 0 || index >= state.filteredCustomers.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete customer. Invalid index.')),
      );
      return;
    }
    final itemToDelete = state.filteredCustomers[index];
    showDeleteDialog(
      context,
      title: 'Delete "${itemToDelete.customerName}"?',
      content:
          'Are you sure you want to delete "${itemToDelete.customerName}"?',
      onConfirm: () {
        bloc.add(
          DeleteCustomer(deletedItem: itemToDelete, deletedIndex: index),
        );
      },
    );
  }

  void _clearSelection() {
    context.read<CustomerBloc>().add(ClearSelection());
    setState(() {
      _isSelectionMode = false;
    });
  }

  void _callCustomer(String phone) {
    // Implement phone call functionality
  }

  void _emailCustomer(String? email) {
    if (email != null) {
      // Implement email functionality
    }
  }

  void _exportCustomer(Customer customer) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Customer data exported')));
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
        _safeDelete(context, index: index);
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
      backgroundColor: Colors.grey,
      appBar: AppBar(title: const Text('Customer List')),
      body: SafeArea(
        child: BlocConsumer<CustomerBloc, CustomerState>(
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
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Expanded(
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
          ),
          const SizedBox(width: 12),
          _buildFloatingActionButton(context),
        ],
      ),
    );
  }

  Widget _buildActionButtons(CustomerState state) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: state.isSelectionMode ? 60 : 0,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey,
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
                    onPressed: () => _safeDelete(context),
                    tooltip: 'Delete selected',
                  ),
                if (state.canEdit)
                  IconButton(
                    icon: const Icon(
                      Iconsax.edit,
                      color: Color.fromARGB(255, 28, 66, 146),
                    ),
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

  Widget _buildFloatingActionButton(BuildContext context) {
    return BlocBuilder<CustomerBloc, CustomerState>(
      builder: (context, state) {
        return ElevatedButton(
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
          style: ElevatedButton.styleFrom(
            backgroundColor: Color.fromARGB(255, 28, 66, 146),
            shape: const CircleBorder(),
          ),
          child: Icon(
            state.canEdit ? Icons.edit : Icons.add,
            color: Colors.white,
          ),
        );
      },
    );
  }

  Widget _buildCustomerList(CustomerState state) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 700;
    final cardSpacing = screenHeight * 0.02;
    final cardWidth = isSmallScreen ? screenWidth * 0.85 : screenWidth * 0.8;

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
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<CustomerBloc>().add(
                LoadCustomers(widget.authBloc.state.companyId!),
              ),
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
            const Icon(Iconsax.people, size: 64, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              state.searchQuery.isEmpty
                  ? 'No customers found'
                  : 'No results for "${state.searchQuery}"',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Container(
      width: screenWidth,
      height: screenHeight,
      decoration: const BoxDecoration(color: Colors.grey),
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: state.filteredCustomers.length,
        separatorBuilder: (context, index) => SizedBox(height: cardSpacing),
        itemBuilder: (context, index) {
          final customer = state.filteredCustomers[index];
          final isSelected = state.selectedCustomers.contains(customer);

          return _buildCustomerListItem(
            customer,
            isSelected,
            state,
            index,
            isSmallScreen,
            cardWidth,
          );
        },
      ),
    );
  }

  Widget _buildCustomerListItem(
    Customer customer,
    bool isSelected,
    CustomerState state,
    int index,
    bool isCompact,
    double cardWidth,
  ) {
    final offset = _dragOffset[index] ?? 0.0;
    // Check expansion state
    final isExpanded = _customerDetail == true && _selectedCustomer == customer;

    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          _toggleCustomerSelection(customer, !isSelected);
        }
      },
      onLongPress: () {
        if (!_isSelectionMode) {
          setState(() => _isSelectionMode = true);
        }
        _toggleCustomerSelection(customer, !isSelected);
      },
      onHorizontalDragUpdate: (d) => _onHorizontalDragUpdate(index, d),
      onHorizontalDragEnd: (d) => _onHorizontalDragEnd(context, index, d),
      onDoubleTap: () =>
          isExpanded ? _hideCustomerDetail() : _showCustomerDetail(customer),

      child: AnimatedBuilder(
        animation: _scrollController,
        builder: (context, child) {
          // WRAPPER: Ensures both background and foreground obey 'cardWidth'
          return SizedBox(
            width: cardWidth,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // --- LAYER 1: DELETE INDICATOR (Background) ---
                // This uses Positioned.fill to match the Height of the foreground automatically
                Positioned.fill(
                  child: Container(
                    alignment: Alignment.centerRight,
                    margin: const EdgeInsets.only(
                      bottom: 2,
                    ), // Same margin as card
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),

                // --- LAYER 2: FOREGROUND CARD (Content) ---
                Transform.translate(
                  offset: Offset(offset, 0),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    // DECORATION: Handles the Yellow/White transition
                    decoration: BoxDecoration(
                      // If expanded, the base becomes yellow. If collapsed, white.
                      color: isExpanded
                          ? Colors.amber
                          : (isSelected ? Colors.blue[50] : Colors.white),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                        color: isSelected
                            ? const Color.fromARGB(255, 28, 66, 146)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),

                    // ANIMATED SIZE: This is the key to efficient height
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      alignment: Alignment.topCenter,
                      child: Column(
                        mainAxisSize: MainAxisSize.min, // Shrink to fit content
                        children: [
                          // --- PART A: HEADER (Name, Phone, Button) ---
                          Container(
                            padding: const EdgeInsets.fromLTRB(15, 15, 15, 10),
                            decoration: BoxDecoration(
                              // The header stays white (or blue-ish) even when expanded
                              color: isSelected
                                  ? Colors.blue[50]
                                  : Colors.white,
                              borderRadius: isExpanded
                                  ? const BorderRadius.vertical(
                                      top: Radius.circular(30),
                                      bottom: Radius.circular(
                                        20,
                                      ), // Slight curve when open
                                    )
                                  : BorderRadius.circular(30),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildAvatar(
                                      customer,
                                      isSelected,
                                      isCompact,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _buildNameAndBadge(
                                            customer,
                                            isCompact,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            customer.phoneNumber ?? 'No Phone',
                                            style: TextStyle(
                                              color: const Color(0xFF684B4B),
                                              fontSize: isCompact ? 14 : 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                // --- SEE MORE / SEE LESS BUTTON ---
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () => isExpanded
                                      ? _hideCustomerDetail()
                                      : _showCustomerDetail(customer),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          isExpanded ? "See Less" : "See More",
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Icon(
                                          isExpanded
                                              ? Icons.keyboard_arrow_up
                                              : Icons.keyboard_arrow_down,
                                          color: Colors.grey[600],
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // --- PART B: DETAILS SECTION (Yellow Background) ---
                          if (isExpanded)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              child: _buildCustomerDetailContent(
                                customer,
                                isCompact,
                              ),
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
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildAvatar(Customer customer, bool isSelected, bool isCompact) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isSelected
            ? const Color.fromARGB(255, 28, 66, 146)
            : Colors.grey[200],
        shape: BoxShape.circle,
      ),
      child: Icon(
        Iconsax.profile_circle,
        color: isSelected ? Colors.white : Colors.grey[600],
        size: isCompact ? 20 : 24,
      ),
    );
  }

  Widget _buildNameAndBadge(Customer customer, bool isCompact) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            customer.customerName ?? 'Unknown',
            style: TextStyle(
              color: const Color(0xFF373737),
              fontSize: isCompact ? 18 : 22, // Slightly smaller safer fonts
              fontWeight: FontWeight.w800,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (customer.defaultsValue == 'Y')
          Container(
            margin: const EdgeInsets.only(left: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green),
            ),
            child: const Text('Default', style: TextStyle(fontSize: 10)),
          ),
      ],
    );
  }

  Widget _buildCustomerDetailContent(Customer customer, bool isCompact) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildCustomerInfoItem(
            'Customer ID : ',
            customer.id?.toString() ?? 'N/A',
            Iconsax.card,
            isCompact,
          ),
          _buildCustomerInfoItem(
            'Customer Name : ',
            customer.customerName ?? 'Unknown',
            Iconsax.profile_circle,
            isCompact,
          ),
          if (customer.contactName != null)
            _buildCustomerInfoItem(
              'Contact Name : ',
              customer.contactName!,
              Iconsax.user,
              isCompact,
            ),
          if (customer.phoneNumber != null && customer.phoneNumber!.isNotEmpty)
            _buildCustomerInfoItem(
              'Phone : ',
              customer.phoneNumber!,
              Iconsax.call,
              isCompact,
            ),
          if (customer.tinNumber != null && customer.tinNumber!.isNotEmpty)
            _buildCustomerInfoItem(
              'TIN Number : ',
              customer.tinNumber!,
              Iconsax.receipt,
              isCompact,
            ),
          if (customer.country != null && customer.country!.isNotEmpty)
            _buildCustomerInfoItem(
              'Country : ',
              customer.country!,
              Iconsax.location,
              isCompact,
            ),
          if (customer.city != null && customer.city!.isNotEmpty)
            _buildCustomerInfoItem(
              'City : ',
              customer.city!,
              Iconsax.building,
              isCompact,
            ),
          if (customer.address != null && customer.address!.isNotEmpty)
            _buildCustomerInfoItem(
              'Address : ',
              customer.address!,
              Iconsax.location,
              isCompact,
            ),
          if (customer.address2 != null && customer.address2!.isNotEmpty)
            _buildCustomerInfoItem(
              'Address Line 2 : ',
              customer.address2!,
              Iconsax.location,
              isCompact,
            ),

          // Action buttons row
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(
                  Iconsax.call,
                  'Call',
                  () => _callCustomer(customer.phoneNumber ?? ''),
                  isCompact,
                ),
                _buildActionButton(
                  Iconsax.sms,
                  'Email',
                  () => _emailCustomer(customer.customerId?.toString()),
                  isCompact,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfoItem(
    String label,
    String value,
    IconData icon,
    bool isCompact,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: Colors.grey[600]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: label,
                    style: const TextStyle(
                      color: Color(0xFF373737),
                      fontSize: 13,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      color: Color(0xFF373737),
                      fontSize: 13,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    VoidCallback onPressed,
    bool isCompact,
  ) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, size: isCompact ? 20 : 24),
          onPressed: onPressed,
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFF145888),
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: isCompact ? 10 : 12,
            color: const Color(0xFF373737),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _navigateToAddScreen() {
    // Navigate to add customer screen
    context.push(AppRoutes.customerCreate);
  }

  void _navigateToEditScreen(Customer customer) {
    // Navigate to edit customer screen
    context.push(AppRoutes.customerEdit, extra: {'customer': customer});
  }
}
