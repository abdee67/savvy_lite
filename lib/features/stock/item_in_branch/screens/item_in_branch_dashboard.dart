import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:savvy_stock/core/constants/app_routes.dart';
import 'package:savvy_stock/core/utils/ui_helper.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/branch_list/blocs/branch_list_bloc.dart';
import 'package:savvy_stock/features/branch_list/blocs/branch_list_event.dart';
import 'package:savvy_stock/features/branch_list/blocs/branch_list_state.dart';
import 'package:savvy_stock/features/branch_list/models/branch_list_model.dart';
import 'package:savvy_stock/features/stock/item_in_branch/blocs/item_in_branch_bloc.dart';
import 'package:savvy_stock/features/stock/item_in_branch/blocs/item_in_branch_event.dart';
import 'package:savvy_stock/features/stock/item_in_branch/blocs/item_in_branch_state.dart';
import 'package:savvy_stock/features/stock/item_in_branch/models/item_in_branch_model.dart';
import 'package:savvy_stock/features/stock/item_in_branch/widgets/item_in_branch_create_and_edit.dart.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_bloc.dart';

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
  late int _decimalPlace;

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
    _decimalPlace = context
        .read<SystemConstantBloc>()
        .state
        .selected!
        .decimalPlaces!;
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
  }

  void _emailItem(String itemId) {
    // Implement email functionality
  }

  void _exportItem(ItemInBranchModel item) {
    context.read<StockItemInBranchBloc>().add(ExportSingleItemFromBranch(item));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Item data exported')));
  }

  void _navigateToEditScreen(ItemInBranchModel item) {
    // context.push(
    //   AppRoutes.editItemInBranch,
    //   extra: item,
    // ); //we dont have a link (privilege) in server for editing stock/item_in_branch, so we use just normal routing
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ItemInBranchFormPage(authBloc: widget.authBloc, item: item),
      ),
    );
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
    final isCompact = MediaQuery.of(context).size.width;
    final threshold = isCompact * 0.3;
    final current = _dragOffset[index] ?? 0;
    if (current.abs() > threshold) {
      // Swipe far enough → delete
      setState(() {
        _dragOffset[index] = -isCompact;
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
      backgroundColor: Colors.white,
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
      height: state.hasSelection ? 30 : 0,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.white)),
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

  Widget _buildItemList(ItemInBranchState state) {
    final isCompact = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = isCompact < 700;
    final cardSpacing = screenHeight * 0.02;
    final cardWidth = isSmallScreen ? isCompact * 0.85 : isCompact * 0.8;

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
      width: isCompact,
      height: screenHeight,
      decoration: const BoxDecoration(color: Colors.white),
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
        builder: (context, child) => SizedBox(
          width: cardWidth,
          child: Stack(
            children: [
              // 1. DELETE INDICATOR - Should be FIRST in Stack
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
                            color: isSelected ? Colors.blue[50] : Colors.white,
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.itemRef!.itemDescription!,
                                          style: TextStyle(
                                            color: const Color(0xFF373737),
                                            fontSize: isCompact ? 14 : 16,
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        Text(
                                          item.branchRef!.description!,
                                          style: TextStyle(
                                            color: const Color.fromARGB(
                                              255,
                                              95,
                                              88,
                                              88,
                                            ),
                                            fontSize: isCompact ? 12 : 14,
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
                                            Text(
                                              'Qty: ${item.quantityAvailable}',
                                              style: TextStyle(
                                                fontSize: isCompact ? 10 : 14,
                                                color: Colors.blue[800],
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () => isExpanded
                                    ? _hideItemDetail()
                                    : _showItemDetail(item),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      // See More / See Less button
                                      Text(
                                        isExpanded ? 'See Less' : 'See More',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: isCompact ? 10 : 12,
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w600,
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

                        // 4. ANIMATED EXPANDED CONTENT
                        if (isExpanded)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            child: _buildItemDetailContent(item, isCompact),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemDetailContent(ItemInBranchModel item, bool isCompact) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildItemInfoItem(
            'Item : ',
            item.itemRef!.itemDescription.toString(),
            Iconsax.box,
            isCompact,
          ),
          _buildItemInfoItem(
            'Branch : ',
            _getItemBranch(item.branch),
            Iconsax.building,
            isCompact,
          ),
          _buildItemInfoItem(
            'Unit Price : ',
            NumberFormat.currency(
              symbol: 'ETB ',
              decimalDigits: _decimalPlace,
            ).format(item.unitPrice),
            Iconsax.dollar_circle,
            isCompact,
          ),
          _buildItemInfoItem(
            'Margin Rate : ',
            item.marginRate?.toStringAsFixed(2) ?? 'N/A',
            Iconsax.percentage_circle,
            isCompact,
          ),
          _buildItemInfoItem(
            'Margin Type : ',
            item.marginType == 'F'
                ? 'Flat'
                : item.marginType == 'P'
                ? 'Percentage'
                : 'N/A',
            Iconsax.chart,
            isCompact,
          ),
          _buildItemInfoItem(
            'Unit of Measure : ',
            item.unitOfMeasureRef?.description1.toString() ?? 'N/A',
            Iconsax.rulerpen,
            isCompact,
          ),
          _buildItemInfoItem(
            'Available Quantity : ',
            '${NumberFormat.decimalPatternDigits(decimalDigits: _decimalPlace).format(item.quantityAvailable)} ${item.unitOfMeasureRef?.description1}',
            Iconsax.notification_status_copy,
            isCompact,
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
                  isCompact,
                ),

                _buildActionButton(
                  Iconsax.trash,
                  'Delete',
                  () => _safeDelete(context),
                  isCompact,
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
    bool isCompact,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: _getIconSize(isCompact),
            height: _getIconSize(isCompact),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: _getIconInnerSize(isCompact),
              color: Colors.grey[600],
            ),
          ),
          SizedBox(width: _getSpacing(isCompact)),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: label,
                    style: TextStyle(
                      color: const Color(0xFF373737),
                      fontSize: _getDetailLabelFontSize(isCompact),
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      color: const Color(0xFF373737),
                      fontSize: _getDetailValueFontSize(isCompact),
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
          icon: Icon(icon, size: _getActionIconSize(isCompact)),
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
            fontSize: _getActionLabelFontSize(isCompact),
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

  double _getIconSize(bool isCompact) {
    if (isCompact) return 28; // Very small phones
    if (isCompact) return 30; // Small phones
    return 32; // Medium phones and larger
  }

  double _getIconInnerSize(bool isCompact) {
    if (isCompact) return 14; // Very small phones
    if (isCompact) return 15; // Small phones
    return 16; // Medium phones and larger
  }

  double _getSpacing(bool isCompact) {
    if (isCompact) return 8; // Very small phones
    if (isCompact) return 10; // Small phones
    return 12; // Medium phones and larger
  }

  double _getDetailLabelFontSize(bool isCompact) {
    if (isCompact) return 11; // Very small phones
    if (isCompact) return 12; // Small phones
    return 13; // Medium phones and larger
  }

  double _getDetailValueFontSize(bool isCompact) {
    if (isCompact) return 11; // Very small phones
    if (isCompact) return 12; // Small phones
    return 13; // Medium phones and larger
  }

  double _getActionIconSize(bool isCompact) {
    if (isCompact) return 18; // Very small phones
    if (isCompact) return 19; // Small phones
    if (isCompact) return 20; // Medium phones
    return 24; // Tablets and larger
  }

  double _getActionLabelFontSize(bool isCompact) {
    if (isCompact) return 9; // Very small phones
    if (isCompact) return 9; // Small phones
    if (isCompact) return 10; // Medium phones
    return 12; // Tablets and larger
  }
}
