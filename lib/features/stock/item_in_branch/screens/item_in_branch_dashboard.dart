import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:savvy_stock/core/constants/app_routes.dart';
import 'package:savvy_stock/core/utils/ui_helper.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/stock/item_in_branch/blocs/item_in_branch_bloc.dart';
import 'package:savvy_stock/features/stock/item_in_branch/blocs/item_in_branch_event.dart';
import 'package:savvy_stock/features/stock/item_in_branch/blocs/item_in_branch_state.dart';
import 'package:savvy_stock/features/stock/item_in_branch/models/item_in_branch_model.dart';

class ItemInBranchDashboard extends StatefulWidget {
  final AuthBloc authBloc;
  const ItemInBranchDashboard({super.key, required this.authBloc});

  @override
  State<ItemInBranchDashboard> createState() => _ItemInBranchDashboardState();
}

class _ItemInBranchDashboardState extends State<ItemInBranchDashboard> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSelectionMode = false;
  final Map<int, double> _dragOffset = {};

  @override
  void initState() {
    super.initState();
    context.read<StockItemInBranchBloc>().add(
      LoadItemsFromBranch(widget.authBloc.state.companyId!),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSearch(String query) {
    context.read<StockItemInBranchBloc>().add(SearchItemsFromBranch(query));
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<StockItemInBranchBloc>().add(SearchItemsFromBranch(''));
  }

  void _toggleItemInBranchSelection(ItemInBranchModel items, bool selected) {
    context.read<StockItemInBranchBloc>().add(
      SelectItemFromBranch(items, selected),
    );
  }

  void _showItemDetail(ItemInBranchModel item) {
    if (!_isSelectionMode) {
      context.read<StockItemInBranchBloc>().add(ShowItemDetailFromBranch(item));
    }
  }

  void _hideItemDetail() {
    context.read<StockItemInBranchBloc>().add(HideItemDetailFromBranch());
  }

  void _clearSelection() {
    context.read<StockItemInBranchBloc>().add(ClearSelectionFromBranch());
    setState(() {
      _isSelectionMode = false;
    });
  }

  void _callItem(String itemId) {
    // Implement phone call functionality
    print('Calling: $itemId');
  }

  void _emailItem(String itemId) {
    // Implement email functionality
    print('Emailing: $itemId');
    }

  void _exportItem(ItemInBranchModel item) {
    context.read<StockItemInBranchBloc>().add(ExportSingleItemFromBranch(item));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Item data exported')));
  }

  void _navigateToEditScreen(ItemInBranchModel item) {
    context.push(AppRoutes.editItemInBranch, extra: item);
  }

  void _navigateToAddScreen() {
    context.push(AppRoutes.addItemToBranch);
  }

  void _safeDelete(BuildContext context, {int? index}) {
    final bloc = context.read<StockItemInBranchBloc>();
    final state = bloc.state;

    // CASE 1: Multiple users
    if (state.selectedItems.isNotEmpty) {
      final itemsToDelete = state.selectedItems;

      showDeleteDialog(
        context,
        title: 'Delete selected items?',
        content:
            'Are you sure you want to delete ${itemsToDelete.length} Items?',
        onConfirm: () {
          final ids = itemsToDelete.map((e) => e.id).toList();
          final deletedIndexes = itemsToDelete
              .map((emp) => state.items.indexOf(emp))
              .toList();
          bloc.add(
            DeleteSelectedItemsFromBranch(
              selectedItems: ids,
              deletedItems: itemsToDelete,
              deletedIndexes: deletedIndexes,
            ),
          );
        },
      );
      return;
    }

    // CASE 2: Single branch by index
    if (index == null || index < 0 || index >= state.filteredItems.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete item. Invalid index.')),
      );
      return;
    }

    final itemToDelete = state.filteredItems[index];

    showDeleteDialog(
      context,
      title: 'Delete "${itemToDelete.itemNumber}"?',
      content: 'Are you sure you want to delete "${itemToDelete.itemNumber}"?',
      onConfirm: () {
        bloc.add(
          DeleteItemFromBranch(
            deletedItem: itemToDelete,
            deletedIndex: index,
            itemId: itemToDelete.id,
          ),
        );
      },
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
    final threshold = screenWidth * 0.3;
    final current = _dragOffset[index] ?? 0;
    if (current.abs() > threshold) {
      // Swipe far enough → delete
      setState(() {
        _dragOffset[index] = -screenWidth;
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Item In Branch Management'),
        backgroundColor: const Color.fromARGB(255, 28, 66, 146),
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<StockItemInBranchBloc, ItemInBranchState>(
        listener: (context, state) {
          if (state.selectedItems.isNotEmpty && !_isSelectionMode) {
            setState(() {
              _isSelectionMode = true;
            });
          } else if (state.selectedItems.isEmpty && _isSelectionMode) {
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
                  // Search Bar
                  _buildSearchBar(),
                  _buildActionButtons(state),

                  // Role List
                  Expanded(child: _buildRoleList(state)),
                ],
              ),
              if (state.showDetailPanel && state.itemDetail != null)
                _buildDetailPanel(state.itemDetail!),
            ],
          );
        },
      ),
      // Floating Action Button for Add
      floatingActionButton:
          BlocBuilder<StockItemInBranchBloc, ItemInBranchState>(
            builder: (context, state) {
              if (state.showDetailPanel) {
                return const SizedBox.shrink();
              }
              return FloatingActionButton(
                onPressed: () {
                  if (state.canEdit && state.selectedItems.isNotEmpty) {
                    // Navigate to edit screen with selected customer
                    final customer = state.selectedItems.first;
                    _navigateToEditScreen(customer);
                  } else {
                    // Navigate to add screen
                    _navigateToAddScreen();
                  }
                },
                backgroundColor: Color.fromARGB(255, 28, 66, 146),
                child: Icon(
                  state.canEdit && state.selectedItems.isNotEmpty
                      ? Icons.edit
                      : Icons.add,
                  color: Colors.white,
                ),
              );
            },
          ),
    );
  }

  Widget _buildActionButtons(ItemInBranchState state) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: state.hasSelection ? 60 : 0,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: state.hasSelection
          ? Row(
              children: [
                Text(
                  '${state.selectedItems.length} selected',
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
                      final item = state.selectedItems.first;
                      _navigateToEditScreen(item);
                    },
                    tooltip: 'Edit branch',
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
          hintText: 'Search by branch description or address...',
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

  Widget _buildRoleList(ItemInBranchState state) {
    if (state.status == ItemInBranchStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == ItemInBranchStatus.failure) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              state.message ?? 'Failed to load Items',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<StockItemInBranchBloc>().add(
                LoadItemsFromBranch(widget.authBloc.state.companyId!),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.user_tag, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              state.searchQuery.isEmpty
                  ? 'No roles found'
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
      itemCount: state.filteredItems.length,
      itemBuilder: (context, index) {
        final item = state.filteredItems[index];
        final isSelected = state.selectedItems.contains(item);
        final screenWidth = MediaQuery.of(context).size.width;
        final useCompactLayout = screenWidth < 700;

        return _buildItemInBranchListItem(
          item,
          state,
          isSelected,
          index,
          useCompactLayout,
        );
      },
    );
  }

  Widget _buildItemInBranchListItem(
    ItemInBranchModel item,
    ItemInBranchState state,
    bool isSelected,
    int index,
    bool isCompact,
  ) {
    final offset = _dragOffset[index] ?? 0.0;

    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          _toggleItemInBranchSelection(item, !isSelected);
        }
      },
      onLongPress: () {
        if (!_isSelectionMode) {
          setState(() {
            _isSelectionMode = true;
          });
        }
        _toggleItemInBranchSelection(item, !isSelected);
      },
      onDoubleTap: () => _showItemDetail(item),
      onHorizontalDragUpdate: (details) =>
          _onHorizontalDragUpdate(index, details),
      onHorizontalDragEnd: (details) =>
          _onHorizontalDragEnd(context, index, details),
      child: Stack(
        children: [
          // Background (delete indicator)
          Positioned.fill(
            child: Container(
              alignment: Alignment.centerRight,
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              margin: const EdgeInsets.only(bottom: 2),
              child: const Icon(Icons.delete, color: Colors.white, size: 28),
            ),
          ),

          // Role card
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
                color: isSelected
                    ? const Color.fromARGB(255, 28, 66, 146)
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: _buildItemInBranchAvatar(item, isSelected, isCompact),
              title: Text(
                item.itemNumber.toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              trailing: _buildItemInBranchTrailing(item),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailPanel(ItemInBranchModel item) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        height: MediaQuery.of(context).size.height * 0.65, // responsive height
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Item Title
                    Text(
                      item.itemNumber.toString(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1C4292),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 26),
                    // Detail grid
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _buildDetailCard(
                          title: 'Item Number',
                          value: item.itemNumber.toString(),
                          color: Colors.blue,
                        ),
                        _buildDetailCard(
                          title: 'Branch',
                          value:
                              item.branchrefrence?.referenceId.toString() ?? '',
                          color: Colors.blue,
                        ),
                        _buildDetailCard(
                          title: 'Margin Rate',
                          value: item.marginRate.toString(),
                          color: Colors.blue,
                        ),
                        _buildDetailCard(
                          title: 'Unit Price',
                          value: item.unitPrice.toString(),
                          color: Colors.blue,
                        ),
                        _buildDetailCard(
                          title: 'Margin Type',
                          value: item.marginType ?? 'N/A',
                          color: Colors.blue,
                        ),
                        _buildDetailCard(
                          title: 'Unit of Measure',
                          value: item.unitOfMeasure ?? 'N/A',
                          color: Colors.blue,
                        ),
                        _buildDetailCard(
                          title: 'Available Quantity',
                          value: item.quantityAvailable.toString() ?? 'N/A',
                          color: Colors.blue,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Actions
            _buildActionBar(item),
          ],
        ),
      ),
    );
  }

  // Header with drag handle + close
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF1C4292),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white54,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const SizedBox(width: 16),
              const Icon(Icons.inventory_2, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Item In Branch Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: _hideItemDetail,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Detail card style
  Widget _buildDetailCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      width:
          (MediaQuery.of(context).size.width / 2) - 30, // responsive 2-column
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Bottom action bar
  Widget _buildActionBar(ItemInBranchModel item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF1C4292),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            Icons.edit,
            'Edit',
            Colors.amber,
            () => _navigateToEditScreen(item),
          ),
          _buildActionButton(
            Icons.share,
            'Share',
            Colors.green,
            () => _exportItem(item),
          ),
          _buildActionButton(
            Icons.delete,
            'Delete',
            Colors.red,
            () => _safeDelete(context),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onPressed,
  ) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon, color: color),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildItemInBranchAvatar(
    ItemInBranchModel item,
    bool isSelected,
    bool isCompact,
  ) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Iconsax.user_tag,
        color: Colors.white,
        size: isCompact ? 20 : 24,
      ),
    );
  }

  Widget _buildItemInBranchTrailing(ItemInBranchModel item) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Taxable status badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: item.item?.taxable == 'Y'
                ? Colors.red.withOpacity(0.1)
                : Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: item.item?.taxable == 'Y' ? Colors.red : Colors.green,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                item.item?.taxable == 'Y' ? Icons.receipt : Icons.money_off,
                size: 12,
                color: item.item?.taxable == 'Y' ? Colors.red : Colors.green,
              ),
              const SizedBox(width: 4),
              Text(
                item.item?.taxable == 'Y' ? 'Taxable' : 'Non-Tax',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: item.item?.taxable == 'Y' ? Colors.red : Colors.green,
                  fontFamily: 'Roboto',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
