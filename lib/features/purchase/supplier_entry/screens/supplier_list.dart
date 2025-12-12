import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:savvy_stock/core/constants/app_routes.dart';
import 'package:savvy_stock/core/utils/ui_helper.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/purchase/supplier_entry/blocs/supplier_bloc.dart';
import 'package:savvy_stock/features/purchase/supplier_entry/blocs/supplier_event.dart';
import 'package:savvy_stock/features/purchase/supplier_entry/blocs/supplier_state.dart';
import 'package:savvy_stock/features/purchase/supplier_entry/models/supplier_model.dart';

class SupplierListPage extends StatefulWidget {
  final AuthBloc authBloc;
  const SupplierListPage({super.key, required this.authBloc});

  @override
  State<SupplierListPage> createState() => _SupplierListPageState();
}

class _SupplierListPageState extends State<SupplierListPage>
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
  SupplierModel? _selectedSupplier;
  bool _supplierDetail = false;

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

    context.read<SupplierBloc>().add(
      LoadSuppliers(widget.authBloc.state.companyId!),
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
    context.read<SupplierBloc>().add(
      SearchSuppliers(query, widget.authBloc.state.companyId!),
    );
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<SupplierBloc>().add(SearchSuppliers('', 0));
  }

  void _toggleCustomerSelection(SupplierModel supplier, bool selected) {
    context.read<SupplierBloc>().add(SelectSupplier(supplier, selected));
  }

  void _showCustomerDetail(SupplierModel supplier) {
    setState(() {
      _selectedSupplier = supplier;
      _supplierDetail = true;
    });

    // Start the animation
    _detailAnimationController.forward(from: 0.0);
  }

  void _hideCustomerDetail() {
    // Reverse the animation
    _detailAnimationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _supplierDetail = false;
          _selectedSupplier = null;
        });
      }
    });
  }

  void _safeDelete(BuildContext context, {int? index}) {
    final bloc = context.read<SupplierBloc>();
    final state = bloc.state;

    if (state.selectedSuppliers.isNotEmpty) {
      final itemsToDelete = state.selectedSuppliers;
      showDeleteDialog(
        context,
        title: 'Delete selected suppliers?',
        content:
            'Are you sure you want to delete ${itemsToDelete.length} suppliers?',
        onConfirm: () {
          final ids = itemsToDelete.map((e) => e.id!).toList();
          final deletedIndexes = itemsToDelete
              .map((emp) => state.filteredSuppliers.indexOf(emp))
              .toList();
          bloc.add(
            DeleteSelectedSuppliers(
              selectedItems: ids,
              deletedItems: itemsToDelete,
              deletedIndexes: deletedIndexes,
            ),
          );
        },
      );
      return;
    }
    if (index == null || index < 0 || index >= state.filteredSuppliers.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete supplier. Invalid index.')),
      );
      return;
    }
    final itemToDelete = state.filteredSuppliers[index];
    showDeleteDialog(
      context,
      title: 'Delete "${itemToDelete.supplierName}"?',
      content:
          'Are you sure you want to delete "${itemToDelete.supplierName}"?',
      onConfirm: () {
        bloc.add(
          DeleteSupplier(deletedItem: itemToDelete, deletedIndex: index),
        );
      },
    );
  }

  void _clearSelection() {
    context.read<SupplierBloc>().add(ClearSelection());
    setState(() {
      _isSelectionMode = false;
    });
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

  void _exportCustomer(SupplierModel supplier) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('SupplierModel data exported')),
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
      appBar: AppBar(title: const Text('SupplierModel List')),
      body: BlocConsumer<SupplierBloc, SupplierState>(
        listener: (context, state) {
          // Update selection mode based on state
          if (state.selectedSuppliers.isNotEmpty && !_isSelectionMode) {
            setState(() {
              _isSelectionMode = true;
            });
          } else if (state.selectedSuppliers.isEmpty && _isSelectionMode) {
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
                  // SupplierModel List
                  Expanded(child: _buildCustomerList(state)),
                ],
              ),
            ],
          );
        },
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

  Widget _buildActionButtons(SupplierState state) {
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
                  '${state.selectedSuppliers.length} selected',
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
                      final supplier = state.selectedSuppliers.first;
                      _navigateToEditScreen(supplier);
                    },
                    tooltip: 'Edit supplier',
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
    return BlocBuilder<SupplierBloc, SupplierState>(
      builder: (context, state) {
        return ElevatedButton(
          onPressed: () {
            if (state.canEdit) {
              // Navigate to edit screen with selected supplier
              final supplier = state.selectedSuppliers.first;
              _navigateToEditScreen(supplier);
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

  Widget _buildCustomerList(SupplierState state) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 700;
    final cardSpacing = screenHeight * 0.02;
    final cardWidth = isSmallScreen ? screenWidth * 0.85 : screenWidth * 0.8;

    if (state.status == SupplierStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == SupplierStatus.failure) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              state.errorMessage ?? 'Failed to load suppliers',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<SupplierBloc>().add(
                LoadSuppliers(widget.authBloc.state.companyId!),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.filteredSuppliers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.people, size: 64, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              state.searchQuery.isEmpty
                  ? 'No Supplier found'
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
        itemCount: state.filteredSuppliers.length,
        separatorBuilder: (context, index) => SizedBox(height: cardSpacing),
        itemBuilder: (context, index) {
          final supplier = state.filteredSuppliers[index];
          final isSelected = state.selectedSuppliers.contains(supplier);

          return _buildCustomerListItem(
            supplier,
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
    SupplierModel supplier,
    bool isSelected,
    SupplierState state,
    int index,
    bool isCompact,
    double cardWidth,
  ) {
    final offset = _dragOffset[index] ?? 0.0;
    final isExpanded = _supplierDetail == true && _selectedSupplier == supplier;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // For responsiveness:
    final collapsedHeight = isCompact
        ? screenHeight *
              0.24 // phones
        : screenHeight * 0.14; // tablets / wide screens

    final expandedHeight = isCompact
        ? screenHeight * 0.55
        : screenHeight * 0.45;
    final collapsedWidth = isCompact ? screenWidth * 0.92 : screenWidth * 0.8;

    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          _toggleCustomerSelection(supplier, !isSelected);
        }
      },
      onLongPress: () {
        if (!_isSelectionMode) {
          setState(() {
            _isSelectionMode = true;
          });
        }
        _toggleCustomerSelection(supplier, !isSelected);
      },
      onHorizontalDragUpdate: (details) =>
          _onHorizontalDragUpdate(index, details),
      onHorizontalDragEnd: (details) =>
          _onHorizontalDragEnd(context, index, details),
      onDoubleTap: () => _showCustomerDetail(supplier),
      child: AnimatedBuilder(
        animation: _scrollController,
        builder: (context, child) => Container(
          transform: Matrix4.translationValues(offset, 0, 0),
          width: collapsedWidth,
          height: isExpanded ? expandedHeight : collapsedHeight,
          child: Stack(
            children: [
              // 1. DELETE INDICATOR - Should be FIRST in Stack
              if (!isExpanded) // Only show delete indicator when not expanded
                Positioned.fill(
                  child: Container(
                    alignment: Alignment.centerRight,
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    margin: const EdgeInsets.only(bottom: 2),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),

              // 2. BACKGROUND LAYERS (only when expanded)
              if (isExpanded) ...[
                // Yellow background
                Positioned.fill(
                  top: 47,
                  child: Container(
                    width: collapsedWidth,
                    height: expandedHeight,
                    decoration: ShapeDecoration(
                      color: const Color(0xFFFDD105), // Fixed yellow color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
              ],

              // 3. CUSTOMER CARD - Should come AFTER delete indicator
              AnimatedContainer(
                padding: const EdgeInsets.only(top: 10, left: 10, right: 10),
                width: collapsedWidth,
                height: collapsedHeight,
                duration: const Duration(milliseconds: 400),
                transform: Matrix4.translationValues(offset, 0, 0),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue[50] : Colors.white,
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // SupplierModel Avatar
                        Container(
                          margin: const EdgeInsets.only(top: 20),
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
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    supplier.supplierName ?? 'Unknown Supplier',
                                    style: TextStyle(
                                      color: const Color(0xFF373737),
                                      fontSize: isCompact ? 20 : 24,
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                supplier.phoneNo1 ??
                                    supplier.phoneNo2 ??
                                    'No Phone',
                                style: TextStyle(
                                  color: const Color.fromARGB(255, 104, 75, 75),
                                  fontSize: isCompact ? 12 : 14,
                                  fontStyle: FontStyle.italic,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // SupplierModel contact info
                              if (supplier.contactPerson != null)
                                Text(
                                  'Contact: ${supplier.contactPerson}',
                                  style: TextStyle(
                                    color: const Color.fromARGB(
                                      255,
                                      104,
                                      75,
                                      75,
                                    ),
                                    fontSize: isCompact ? 12 : 14,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              // SupplierModel ID
                              Text(
                                'Tin: ${supplier.tinNumber.toString()}',
                                style: TextStyle(
                                  color: const Color.fromARGB(255, 104, 75, 75),
                                  fontSize: isCompact ? 12 : 14,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // See More / See Less button
                        ElevatedButton(
                          onPressed: () => isExpanded
                              ? _hideCustomerDetail()
                              : _showCustomerDetail(supplier),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF145888),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            isExpanded ? 'See Less' : 'See More',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isCompact ? 10 : 12,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 4. ANIMATED EXPANDED CONTENT
              if (isExpanded)
                Positioned(
                  top: collapsedHeight + 10,
                  left: 20,
                  right: 20,
                  child: AnimatedBuilder(
                    animation: _detailAnimationController,
                    builder: (context, child) {
                      final currentHeight =
                          _heightAnimation.value *
                          (expandedHeight - collapsedHeight - 20);
                      final currentOpacity = _opacityAnimation.value;

                      return SlideTransition(
                        position: _slideAnimation,
                        child: Container(
                          height: currentHeight > 0 ? currentHeight : 0,
                          decoration: BoxDecoration(color: Colors.transparent),
                          child: Opacity(opacity: currentOpacity, child: child),
                        ),
                      );
                    },
                    child: _buildCustomerDetailContent(supplier, isCompact),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerDetailContent(SupplierModel supplier, bool isCompact) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          if (supplier.supplierName != null)
            _buildSupplierInfoItem(
              'Supplie Name: ',
              supplier.supplierName?.toString() ?? 'N/A',
              Iconsax.card,
              isCompact,
            ),
          if (supplier.phoneNo1 != null)
            _buildSupplierInfoItem(
              'Phone No : ',
              supplier.phoneNo1.toString(),
              Iconsax.profile_circle,
              isCompact,
            ),
          if (supplier.addressLine != null)
            _buildSupplierInfoItem(
              'Address: ',
              supplier.addressLine!,
              Iconsax.user,
              isCompact,
            ),
          if (supplier.country != null)
            _buildSupplierInfoItem(
              'Country : ',
              supplier.country!,
              Iconsax.call,
              isCompact,
            ),
          if (supplier.tinNumber != null && supplier.tinNumber!.isNotEmpty)
            _buildSupplierInfoItem(
              'TIN Number : ',
              supplier.tinNumber!,
              Iconsax.receipt,
              isCompact,
            ),
          if (supplier.country != null && supplier.country!.isNotEmpty)
            _buildSupplierInfoItem(
              'Country : ',
              supplier.country!,
              Iconsax.location,
              isCompact,
            ),
          if (supplier.city != null && supplier.city!.isNotEmpty)
            _buildSupplierInfoItem(
              'City : ',
              supplier.city!,
              Iconsax.building,
              isCompact,
            ),
          if (supplier.state != null && supplier.state!.isNotEmpty)
            _buildSupplierInfoItem(
              'State : ',
              supplier.state!,
              Iconsax.location,
              isCompact,
            ),
          if (supplier.region != null && supplier.region!.isNotEmpty)
            _buildSupplierInfoItem(
              'Region  : ',
              supplier.region!,
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
                  () => _callCustomer(supplier.phoneNo1 ?? ''),
                  isCompact,
                ),
                _buildActionButton(
                  Iconsax.sms,
                  'Email',
                  () => _emailCustomer(supplier.email?.toString()),
                  isCompact,
                ),
                _buildActionButton(
                  Iconsax.export,
                  'Export',
                  () => _exportCustomer(supplier),
                  isCompact,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierInfoItem(
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
    // Navigate to add supplier screen
    context.push(AppRoutes.supplierCreate);
  }

  void _navigateToEditScreen(SupplierModel supplier) {
    // Navigate to edit supplier screen
    context.push(AppRoutes.supplierEdit, extra: {'supplier': supplier});
  }
}
