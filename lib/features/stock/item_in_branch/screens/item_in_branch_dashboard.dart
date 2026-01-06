import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:savvy_stock/core/constants/app_routes.dart';
import 'package:savvy_stock/core/utils/ui_helper.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/branch_list/blocs/branch_list_bloc.dart';
import 'package:savvy_stock/features/branch_list/blocs/branch_list_event.dart';
import 'package:savvy_stock/features/branch_list/blocs/branch_list_state.dart';
import 'package:savvy_stock/features/branch_list/models/branch_list_model.dart';
import 'package:savvy_stock/features/stock/item_entry/models/item_entry_model.dart';
import 'package:savvy_stock/features/stock/item_in_branch/blocs/item_in_branch_bloc.dart';
import 'package:savvy_stock/features/stock/item_in_branch/blocs/item_in_branch_event.dart';
import 'package:savvy_stock/features/stock/item_in_branch/blocs/item_in_branch_state.dart';
import 'package:savvy_stock/features/stock/item_in_branch/models/item_in_branch_model.dart';

import '../../item_entry/blocs/item_entry_bloc.dart';
import '../../item_entry/blocs/item_entry_event.dart';
import '../../item_entry/blocs/item_entry_state.dart';

class ItemInBranchDashboard extends StatefulWidget {
  final AuthBloc authBloc;
  const ItemInBranchDashboard({super.key, required this.authBloc});

  @override
  State<ItemInBranchDashboard> createState() => _ItemInBranchDashboardState();
}

class _ItemInBranchDashboardState extends State<ItemInBranchDashboard>
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
  ItemInBranchModel? _selectedItem;
  bool _itemDetail = false;

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

    context.read<StockItemInBranchBloc>().add(
      LoadItemsFromBranch(widget.authBloc.state.companyId!),
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
    setState(() {
      _selectedItem = item;
      _itemDetail = true;
    });

    // Start the animation
    _detailAnimationController.forward(from: 0.0);
  }

  void _hideItemDetail() {
    // Reverse the animation
    _detailAnimationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _itemDetail = false;
          _selectedItem = null;
        });
      }
    });
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

  String _getItemDescription(int? itemId) {
    if (itemId == null) return '';
    // load item descriptions from item_entry bloc
    final itemEntryBloc = context.read<StockItemsEntryBloc>();
    itemEntryBloc.add(LoadItems(widget.authBloc.state.companyId!));

    final itemEntryState = itemEntryBloc.state;
    if (itemEntryState.status == ItemEntryStatus.success) {
      final item = itemEntryState.items.firstWhere(
        (item) => item.id == itemId,
        orElse: () => ItemEntryModel.empty(),
      );
      return item.itemDescription ?? 'Item $itemId';
    }

    return 'Item $itemId';
  }

  String _getItemBranch(int? branchId) {
    if (branchId == null) return '';
    // load item branch from branch bloc
    final branchBloc = context.read<BranchBloc>();
    branchBloc.add(LoadBranchs(widget.authBloc.state.companyId!));

    final branchState = branchBloc.state;
    if (branchState.status == BranchStatus.success) {
      final item = branchState.branchs.firstWhere(
        (item) => item.id == branchId,
        orElse: () => Branch.empty(),
      );
      return item.description ?? 'Branch $branchId';
    }

    return 'Branch $branchId';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey,
      appBar: AppBar(
        title: const Text('Item In Branch Management'),
        backgroundColor: const Color.fromARGB(255, 28, 66, 146),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: BlocConsumer<StockItemInBranchBloc, ItemInBranchState>(
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

                    // Item List
                    Expanded(child: _buildItemList(state)),
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
                hintText: 'Search by item number or branch...',
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
        ],
      ),
    );
  }

  Widget _buildActionButtons(ItemInBranchState state) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: state.hasSelection ? 60 : 0,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey,
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
                    tooltip: 'Edit item',
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
    return BlocBuilder<StockItemInBranchBloc, ItemInBranchState>(
      builder: (context, state) {
        return ElevatedButton(
          onPressed: () {
            if (state.canEdit && state.selectedItems.isNotEmpty) {
              // Navigate to edit screen with selected item
              final item = state.selectedItems.first;
              _navigateToEditScreen(item);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Color.fromARGB(255, 28, 66, 146),
            shape: const CircleBorder(),
          ),
          child: const Icon(Icons.edit, color: Colors.white),
        );
      },
    );
  }

  Widget _buildItemList(ItemInBranchState state) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 700;
    final cardSpacing = screenHeight * 0.02;
    final cardWidth = isSmallScreen ? screenWidth * 0.85 : screenWidth * 0.8;

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
            const Icon(Iconsax.box, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              state.searchQuery.isEmpty
                  ? 'No items found'
                  : 'No results for "${state.searchQuery}"',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
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
        itemCount: state.filteredItems.length,
        separatorBuilder: (context, index) => SizedBox(height: cardSpacing),
        itemBuilder: (context, index) {
          final item = state.filteredItems[index];
          final isSelected = state.selectedItems.contains(item);

          return _buildItemListItem(
            item,
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

  Widget _buildItemListItem(
    ItemInBranchModel item,
    bool isSelected,
    ItemInBranchState state,
    int index,
    bool isCompact,
    double cardWidth,
  ) {
    final offset = _dragOffset[index] ?? 0.0;
    final isExpanded = _itemDetail == true && _selectedItem == item;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Responsive sizing based on screen size
    final collapsedHeight = _getCollapsedHeight(screenWidth, screenHeight);
    final expandedHeight = _getExpandedHeight(screenWidth, screenHeight);
    final collapsedWidth = _getCardWidth(screenWidth);
    final itemDescription = _getItemDescription(item.itemNumber);
    final branch = _getItemBranch(item.branch);

    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          _toggleItemInBranchSelection(item, !isSelected);
        } else {
          // Single tap shows detail when not in selection mode
          _showItemDetail(item);
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
              // 3. ITEM CARD - Should come AFTER delete indicator
              AnimatedContainer(
                padding: const EdgeInsets.only(top: 5, left: 10, right: 10),
                //width: collapsedWidth,
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
                        // Item Avatar
                        _buildItemAvatar(item, isSelected, isCompact),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.itemRef!.itemDescription!,
                                style: TextStyle(
                                  color: const Color(0xFF373737),
                                  fontSize: _getTitleFontSize(screenWidth),
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                item.branchRef!.description!,
                                style: TextStyle(
                                  color: const Color(0xFF887F7F),
                                  fontSize: _getSubtitleFontSize(screenWidth),
                                  fontStyle: FontStyle.italic,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Stock and price info
                              Row(
                                children: [
                                  // Available Quantity
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.blue[200]!,
                                      ),
                                    ),
                                    child: Text(
                                      'Qty: ${item.quantityAvailable}',
                                      style: TextStyle(
                                        fontSize: _getBadgeFontSize(
                                          screenWidth,
                                        ),
                                        color: Colors.blue[800],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Unit Price
                                  if (item.unitPrice != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green[50],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.green[200]!,
                                        ),
                                      ),
                                      child: Text(
                                        '\$${item.unitPrice!.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: _getBadgeFontSize(
                                            screenWidth,
                                          ),
                                          color: Colors.green[800],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
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
                              ? _hideItemDetail()
                              : _showItemDetail(item),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF145888),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: _getButtonPadding(screenWidth),
                          ),
                          child: Text(
                            isExpanded ? 'See Less' : 'See More',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: _getButtonFontSize(screenWidth),
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
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
                    child: _buildItemDetailContent(item, screenWidth),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemDetailContent(ItemInBranchModel item, double screenWidth) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildItemInfoItem(
            'Item in Branch ID : ',
            item.id.toString(),
            Iconsax.card,
            screenWidth,
          ),
          _buildItemInfoItem(
            'Item : ',
            item.itemRef!.itemsId.toString(),
            Iconsax.box,
            screenWidth,
          ),
          _buildItemInfoItem(
            'Branch : ',
            _getItemBranch(item.branch),
            Iconsax.building,
            screenWidth,
          ),
          _buildItemInfoItem(
            'Unit Price : ',
            item.unitPrice != null
                ? '\$${item.unitPrice!.toStringAsFixed(2)}'
                : 'N/A',
            Iconsax.dollar_circle,
            screenWidth,
          ),
          _buildItemInfoItem(
            'Margin Rate : ',
            item.marginRate?.toStringAsFixed(2) ?? 'N/A',
            Iconsax.percentage_circle,
            screenWidth,
          ),
          _buildItemInfoItem(
            'Margin Type : ',
            item.marginType ?? 'N/A',
            Iconsax.chart,
            screenWidth,
          ),
          _buildItemInfoItem(
            'Unit of Measure : ',
            item.unitOfMeasureRef?.description1.toString() ?? 'N/A',
            Iconsax.rulerpen,
            screenWidth,
          ),
          _buildItemInfoItem(
            'Available Quantity : ',
            item.quantityAvailable?.toString() ?? 'N/A',
            Iconsax.notification_status_copy,
            screenWidth,
          ),

          // Action buttons row
          Padding(
            padding: EdgeInsets.only(top: 16, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(
                  Iconsax.edit,
                  'Edit',
                  () => _navigateToEditScreen(item),
                  screenWidth,
                ),
                _buildActionButton(
                  Iconsax.export,
                  'Export',
                  () => _exportItem(item),
                  screenWidth,
                ),
                _buildActionButton(
                  Iconsax.trash,
                  'Delete',
                  () => _safeDelete(context),
                  screenWidth,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemInfoItem(
    String label,
    String value,
    IconData icon,
    double screenWidth,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: _getIconSize(screenWidth),
            height: _getIconSize(screenWidth),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: _getIconInnerSize(screenWidth),
              color: Colors.grey[600],
            ),
          ),
          SizedBox(width: _getSpacing(screenWidth)),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: label,
                    style: TextStyle(
                      color: const Color(0xFF373737),
                      fontSize: _getDetailLabelFontSize(screenWidth),
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      color: const Color(0xFF373737),
                      fontSize: _getDetailValueFontSize(screenWidth),
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
    double screenWidth,
  ) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, size: _getActionIconSize(screenWidth)),
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
            fontSize: _getActionLabelFontSize(screenWidth),
            color: const Color(0xFF373737),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildItemAvatar(
    ItemInBranchModel item,
    bool isSelected,
    bool isCompact,
  ) {
    final Color backgroundColor;
    final Color iconColor;

    if (isSelected) {
      backgroundColor = const Color.fromARGB(255, 28, 66, 146);
      iconColor = Colors.white;
    } else {
      backgroundColor = Colors.grey[200]!;
      iconColor = Colors.grey[600]!;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      child: Icon(Iconsax.box, color: iconColor, size: isCompact ? 20 : 24),
    );
  }

  // Responsive helper methods
  double _getCollapsedHeight(double screenWidth, double screenHeight) {
    if (screenWidth < 360) return screenHeight * 0.22; // Very small phones
    if (screenWidth < 400) return screenHeight * 0.20; // Small phones
    if (screenWidth < 700) return screenHeight * 0.22; // Medium phones
    return screenHeight * 0.14; // Tablets and larger
  }

  double _getExpandedHeight(double screenWidth, double screenHeight) {
    if (screenWidth < 360) return screenHeight * 0.65; // Very small phones
    if (screenWidth < 400) return screenHeight * 0.60; // Small phones
    if (screenWidth < 700) return screenHeight * 0.55; // Medium phones
    return screenHeight * 0.45; // Tablets and larger
  }

  double _getCardWidth(double screenWidth) {
    if (screenWidth < 360) return screenWidth * 0.92; // Very small phones
    if (screenWidth < 400) return screenWidth * 0.90; // Small phones
    if (screenWidth < 700) return screenWidth * 0.85; // Medium phones
    return screenWidth * 0.8; // Tablets and larger
  }

  double _getTitleFontSize(double screenWidth) {
    if (screenWidth < 360) return 18; // Very small phones
    if (screenWidth < 400) return 19; // Small phones
    if (screenWidth < 700) return 20; // Medium phones
    return 24; // Tablets and larger
  }

  double _getSubtitleFontSize(double screenWidth) {
    if (screenWidth < 360) return 10; // Very small phones
    if (screenWidth < 400) return 11; // Small phones
    if (screenWidth < 700) return 12; // Medium phones
    return 14; // Tablets and larger
  }

  double _getBadgeFontSize(double screenWidth) {
    if (screenWidth < 360) return 9; // Very small phones
    if (screenWidth < 400) return 9; // Small phones
    if (screenWidth < 700) return 10; // Medium phones
    return 10; // Tablets and larger
  }

  double _getInfoFontSize(double screenWidth) {
    if (screenWidth < 360) return 10; // Very small phones
    if (screenWidth < 400) return 11; // Small phones
    if (screenWidth < 700) return 12; // Medium phones
    return 14; // Tablets and larger
  }

  double _getButtonFontSize(double screenWidth) {
    if (screenWidth < 360) return 9; // Very small phones
    if (screenWidth < 400) return 9; // Small phones
    if (screenWidth < 700) return 10; // Medium phones
    return 12; // Tablets and larger
  }

  EdgeInsets _getButtonPadding(double screenWidth) {
    if (screenWidth < 360) {
      return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
    }
    if (screenWidth < 400) {
      return const EdgeInsets.symmetric(horizontal: 14, vertical: 7);
    }
    if (screenWidth < 700) {
      return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
    }
    return const EdgeInsets.symmetric(horizontal: 20, vertical: 10);
  }

  double _getIconSize(double screenWidth) {
    if (screenWidth < 360) return 28; // Very small phones
    if (screenWidth < 400) return 30; // Small phones
    return 32; // Medium phones and larger
  }

  double _getIconInnerSize(double screenWidth) {
    if (screenWidth < 360) return 14; // Very small phones
    if (screenWidth < 400) return 15; // Small phones
    return 16; // Medium phones and larger
  }

  double _getSpacing(double screenWidth) {
    if (screenWidth < 360) return 8; // Very small phones
    if (screenWidth < 400) return 10; // Small phones
    return 12; // Medium phones and larger
  }

  double _getDetailLabelFontSize(double screenWidth) {
    if (screenWidth < 360) return 11; // Very small phones
    if (screenWidth < 400) return 12; // Small phones
    return 13; // Medium phones and larger
  }

  double _getDetailValueFontSize(double screenWidth) {
    if (screenWidth < 360) return 11; // Very small phones
    if (screenWidth < 400) return 12; // Small phones
    return 13; // Medium phones and larger
  }

  double _getActionIconSize(double screenWidth) {
    if (screenWidth < 360) return 18; // Very small phones
    if (screenWidth < 400) return 19; // Small phones
    if (screenWidth < 700) return 20; // Medium phones
    return 24; // Tablets and larger
  }

  double _getActionLabelFontSize(double screenWidth) {
    if (screenWidth < 360) return 9; // Very small phones
    if (screenWidth < 400) return 9; // Small phones
    if (screenWidth < 700) return 10; // Medium phones
    return 12; // Tablets and larger
  }
}
