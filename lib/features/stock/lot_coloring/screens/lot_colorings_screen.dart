import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:savvy_stock/core/utils/ui_helper.dart';
import 'package:savvy_stock/core/widgets/custom_dropdown.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/branch_list/blocs/branch_list_bloc.dart';
import 'package:savvy_stock/features/branch_list/blocs/branch_list_event.dart'
    hide ClearSelection;
import 'package:savvy_stock/features/branch_list/blocs/branch_list_state.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_bloc.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_event.dart'
    hide ClearSelection;
import 'package:savvy_stock/features/stock/lot_coloring/bloc/lot_coloring_bloc.dart';
import 'package:savvy_stock/features/stock/lot_coloring/bloc/lot_coloring_event.dart';
import 'package:savvy_stock/features/stock/lot_coloring/bloc/lot_coloring_state.dart';
import 'package:savvy_stock/features/stock/lot_coloring/model/lot_coloring_model.dart';
import 'package:savvy_stock/features/stock/lot_coloring/widgets/lot_coloring_form.dart';

import '../../item_entry/blocs/item_entry_state.dart';

class LotExpirationColorsDashboard extends StatefulWidget {
  final AuthBloc authBloc;

  const LotExpirationColorsDashboard({super.key, required this.authBloc});

  @override
  State<LotExpirationColorsDashboard> createState() =>
      _LotExpirationColorsDashboardState();
}

class _LotExpirationColorsDashboardState
    extends State<LotExpirationColorsDashboard>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSelectionMode = false;
  final Map<int, double> _dragOffset = {};

  // Animation controllers for detail panel
  late AnimationController _detailAnimationController;
  late Animation<double> _heightAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  //  Detail panel state
  LotExpirationColor? _selectedColor;
  final List<LotExpirationColor> _selectedColors = [];
  bool _colorDetail = false;

  // Level selection
  String? _selectedLevel;
  int? _selectedBranch;
  int? _selectedItem;

  @override
  void initState() {
    super.initState();

    //Initialize animation controller
    _detailAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    //   Set up animations
    _setupAnimations();

    // Load initial data
    context.read<BranchBloc>().add(
      LoadBranchs(widget.authBloc.state.companyId!),
    );
    context.read<StockItemsEntryBloc>().add(
      LoadItems(widget.authBloc.state.companyId!),
    );
    context.read<LotExpirationColorsBloc>().add(
      LoadLotExpirationColors(widget.authBloc.state.companyId!),
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

  void _onLevelChanged(String? level) {
    setState(() {
      _selectedLevel = level;
      _selectedBranch = null;
      _selectedItem = null;
    });

    _applyFilters();
  }

  void _onBranchChanged(int? branchId) {
    setState(() {
      _selectedBranch = branchId;
    });
    _applyFilters();
  }

  void _onItemChanged(int? itemId) {
    setState(() {
      _selectedItem = itemId;
    });
    _applyFilters();
  }

  void _applyFilters() {
    context.read<LotExpirationColorsBloc>().add(
      FilterLotExpirationColors(
        level: _selectedLevel,
        branchId: _selectedBranch,
        itemId: _selectedItem,
      ),
    );
  }

  void _handleSearch(String query) {
    context.read<LotExpirationColorsBloc>().add(
      SearchLotExpirationColors(query),
    );
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<LotExpirationColorsBloc>().add(SearchLotExpirationColors(''));
  }

  void _toggleColorSelection(LotExpirationColor color, bool selected) {
    context.read<LotExpirationColorsBloc>().add(
      SelectLotExpirationColor(color, selected),
    );
  }

  void _showLotDetail(LotExpirationColor color) {
    setState(() {
      _selectedColor = color;
      _colorDetail = true;
    });

    //Start the animation
    _detailAnimationController.forward(from: 0.0);
  }

  void _hideLotDetail() {
    // Reverse the animation
    _detailAnimationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _colorDetail = false;
          _selectedColor = null;
        });
      }
    });
  }

  void _clearSelection() {
    context.read<LotExpirationColorsBloc>().add(ClearSelection());
    setState(() {
      _isSelectionMode = false;
    });
  }

  void _exportLot(LotExpirationColor color) {
    // Implement export functionality
    if (kDebugMode) {
      developer.log('Exporting lot: ${color.colorType}');
    }
  }

  void _navigateToCreateScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            LotExpirationColorsFormPage(authBloc: widget.authBloc),
      ),
    );
  }

  void _navigateToEditScreen(LotExpirationColor color) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LotExpirationColorsFormPage(
          authBloc: widget.authBloc,
          existingColoring: color,
        ),
      ),
    );
  }

  void _deleteColor(LotExpirationColor color) {
    showDeleteDialog(
      context,
      title: 'Delete Color Configuration?',
      content: 'Are you sure you want to delete this color configuration?',
      onConfirm: () {
        context.read<LotExpirationColorsBloc>().add(
          DeleteLotExpirationColors(color),
        );
      },
    );
  }

  void _safeDelete(BuildContext context, {int? index}) {
    final bloc = context.read<LotExpirationColorsBloc>();
    final state = bloc.state;

    //CASE 1: Multiple lots
    if (state.selectedItems.isNotEmpty) {
      final colorsToDelete = state.selectedItems;
      showDeleteDialog(
        context,
        title: 'Delete selected lot colors?',
        content:
            'Are you sure you want to delete ${colorsToDelete.length} lot colors?',
        onConfirm: () {
          final ids = colorsToDelete.map((e) => e.id).toList();
          final deletedIndexes = colorsToDelete
              .map((lot) => state.items.indexOf(lot))
              .toList();
          bloc.add(DeleteMultipleLotExpirationColors(colorsToDelete));
        },
      );
      return;
    }

    // CASE 2: Single lot by index
    if (index == null || index < 0 || index >= state.filteredItems.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete lot. Invalid index.')),
      );
      return;
    }

    final colorToDelete = state.filteredItems[index];

    showDeleteDialog(
      context,
      title: 'Delete Lot ${colorToDelete.colorType}?',
      content:
          'Are you sure you want to delete lot "${colorToDelete.colorType}"?',
      onConfirm: () {
        bloc.add(DeleteLotExpirationColors(colorToDelete));
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
      //Not far enough → snap back
      setState(() {
        _dragOffset[index] = 0.0;
      });
    }
  }

  String _getLevelDescription(String? level) {
    switch (level) {
      case '1':
        return 'Company Level';
      case '2':
        return 'Store Level';
      case '3':
        return 'Item Level';
      case '4':
        return 'Item Store Level';
      default:
        return 'Unknown Level';
    }
  }

  String _getColorTypeName(LotExpirationColor color) {
    if (color.colorTypeCode != null && color.colorTypeName!.isNotEmpty) {
      return color.colorTypeName!;
    }
    switch (color.colorTypeCode?.toUpperCase()) {
      case 'RED':
        return 'Red';
      case 'BLU':
        return 'Blue';
      case 'GRN':
        return 'Green';
      case 'BLK':
        return 'Black';
      default:
        return 'Unknown';
    }
  }

  Color _getColorFromType(LotExpirationColor? color) {
    if (color == null) return Colors.grey.shade200;

    final code = (color.colorTypeCode ?? '').trim().toUpperCase();
    final name = (color.colorTypeName ?? '').trim().toLowerCase();

    switch (code) {
      case 'RED':
        return Colors.red;
      case 'BLU':
        return Colors.blue;
      case 'GRN':
        return Colors.green;
      case 'BLK':
        return Colors.black;
      case 'YL':
        return Colors.yellow;
      case 'ORG':
        return Colors.orange;
      case 'GRY':
        return Colors.grey;
      case 'OV':
        return const Color.fromARGB(255, 14, 90, 4);
      case 'PRPL':
        return Colors.purple;
      case 'LM':
        return Colors.lime;

      default:
        // Fallback to name matching
        if (name.contains('red')) return Colors.red;
        if (name.contains('blue')) return Colors.blue;
        if (name.contains('green')) return Colors.green;
        if (name.contains('yellow')) return Colors.yellow;
        if (name.contains('orange')) return Colors.orange;
        if (name.contains('black')) return Colors.black;

        return Colors.grey.shade200;
    }
  }

  String _getBranchName(int branchId) {
    final branchBloc = context.read<BranchBloc>();
    final branchState = branchBloc.state;
    final branchDescription =
        branchState.branchs
            .where((entry) => entry.id == branchId)
            .firstOrNull
            ?.description ??
        'Branch $branchId';
    return branchDescription;
  }

  String _getItemName(int itemId) {
    final itemBloc = context.read<StockItemsEntryBloc>();
    final itemDescription =
        itemBloc.state.items
            .where((entry) => entry.id == itemId)
            .firstOrNull
            ?.itemDescription ??
        'Item $itemId';
    return itemDescription;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Lot Expiration Colors'),
        backgroundColor: const Color.fromARGB(255, 28, 66, 146),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            context.read<LotExpirationColorsBloc>().add(
              LoadLotExpirationColors(widget.authBloc.state.companyId!),
            );
          },
          child:
              BlocConsumer<LotExpirationColorsBloc, LotExpirationColorsState>(
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
                          _buildSearchBar(),
                          // Filter Section
                          _buildFilterSection(),

                          _buildActionButtons(state),
                          // Color List
                          Expanded(child: _buildColorList(state)),
                        ],
                      ),
                    ],
                  );
                },
              ),
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
                hintText: 'Search by lot number or supplier batch...',
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
                fillColor: Colors.white,
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

  Widget _buildActionButtons(LotExpirationColorsState state) {
    final hasSelection = _selectedColors.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: hasSelection ? 60 : 0,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.white)),
      ),
      child: hasSelection
          ? Row(
              children: [
                Text(
                  '${_selectedColors.length} selected',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Iconsax.trash, color: Colors.red),
                  onPressed: () => _safeDelete(context),
                  tooltip: 'Delete selected',
                ),
                if (_selectedColors.length == 1)
                  IconButton(
                    icon: const Icon(
                      Iconsax.edit,
                      color: Color.fromARGB(255, 28, 66, 146),
                    ),
                    onPressed: () {
                      final lot = _selectedColors.first;
                      _navigateToEditScreen(lot);
                    },
                    tooltip: 'Edit lot',
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
    return BlocBuilder<LotExpirationColorsBloc, LotExpirationColorsState>(
      builder: (context, state) {
        return ElevatedButton(
          onPressed: () {
            if (state.canEdit && state.selectedItems.isNotEmpty) {
              final lot = state.selectedItems.first;
              _navigateToEditScreen(lot);
            } else {
              _navigateToCreateScreen();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 28, 66, 146),
            shape: const CircleBorder(),
          ),
          child: const Icon(Icons.add, color: Colors.white),
        );
      },
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.white)),
      ),
      child: Column(
        children: [
          // Level Dropdown
          CustomDropdown(
            labelText: 'Filter by Level',
            value: _selectedLevel,
            items: const [
              DropdownMenuItem(value: '1', child: Text('Company Level')),
              DropdownMenuItem(value: '2', child: Text('Store Level')),
              DropdownMenuItem(value: '3', child: Text('Item Level')),
              DropdownMenuItem(value: '4', child: Text('Item Store Level')),
            ],
            onChanged: _onLevelChanged,
          ),
          const SizedBox(height: 12),

          // Branch Dropdown (for Level 2 and 4)
          if (_selectedLevel != null &&
              (_selectedLevel == '2' || _selectedLevel == '4'))
            Column(
              children: [
                BlocBuilder<BranchBloc, BranchState>(
                  builder: (context, state) {
                    return CustomDropdown(
                      labelText: 'Store',
                      value: _selectedBranch,
                      items: state.branchs.map((branch) {
                        return DropdownMenuItem<int>(
                          value: branch.id,
                          child: Text(branch.description ?? 'Unknown Branch'),
                        );
                      }).toList(),
                      onChanged: _onBranchChanged,
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),

          // Item Dropdown (for Level 3 and 4)
          if (_selectedLevel != null &&
              (_selectedLevel == '3' || _selectedLevel == '4'))
            BlocBuilder<StockItemsEntryBloc, ItemEntryState>(
              builder: (context, state) {
                return CustomDropdown(
                  labelText: 'Item Number',
                  value: _selectedItem,
                  items: state.filteredItems.map((item) {
                    return DropdownMenuItem<int>(
                      value: item.id,
                      child: Text('${item.itemDescription} (${item.itemsId})'),
                    );
                  }).toList(),
                  onChanged: _onItemChanged,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildColorList(LotExpirationColorsState state) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 700;
    final cardSpacing = screenHeight * 0.02;
    final cardWidth = isSmallScreen ? screenWidth * 0.92 : screenWidth * 0.8;

    if (state.status == LotExpirationColorsStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == LotExpirationColorsStatus.failure) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              state.message ?? 'Failed to load color configurations',
              style: const TextStyle(color: Colors.grey),
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
            const Icon(Iconsax.colorfilter, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _selectedLevel == null
                  ? 'No color configurations found'
                  : 'No configurations for ${_getLevelDescription(_selectedLevel)}',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Container(
      width: screenWidth,
      height: screenHeight,
      decoration: const BoxDecoration(color: Colors.white),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: state.filteredItems.length,
        separatorBuilder: (context, index) => SizedBox(height: cardSpacing),
        itemBuilder: (context, index) {
          final color = state.filteredItems[index];
          final isSelected = state.selectedItems.contains(color);
          return _buildColorCard(
            color,
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

  Widget _buildColorCard(
    LotExpirationColor color,
    bool isSelected,
    LotExpirationColorsState state,
    int index,
    bool isCompact,
    double cardWidth,
  ) {
    final offset = _dragOffset[index] ?? 0.0;
    final isExpanded = _colorDetail == true && _selectedColor == color;

    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          _toggleColorSelection(color, !isSelected);
        } else {
          _showLotDetail(color);
        }
      },
      onLongPress: () {
        if (!_isSelectionMode) {
          setState(() {
            _isSelectionMode = true;
          });
        }
        _toggleColorSelection(color, !isSelected);
      },
      onDoubleTap: () => _showLotDetail(color),
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
              // 1. DELETE INDICATOR
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
                    color: isExpanded
                        ? Colors.amber
                        : (isSelected
                              ? Colors.blue[50]
                              : _getColorFromType(color)),
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
                                : _getColorFromType(color),
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
                                  // Lot Avatar
                                  _buildLotAvatar(color, isSelected, isCompact),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              _getLevelDescription(
                                                color.lotExpLevel?.toString() ??
                                                    'N/A',
                                              ),
                                              style: TextStyle(
                                                color: const Color.fromARGB(
                                                  255,
                                                  99,
                                                  97,
                                                  97,
                                                ),
                                                fontSize: isCompact ? 20 : 24,
                                                fontFamily: 'Inter',
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.withOpacity(
                                                  0.1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: Colors.blue
                                                      .withOpacity(0.3),
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Iconsax.weight,
                                                    size: 14,
                                                    color: Colors.blue,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    color.activeForSalesFlag ==
                                                            'Y'
                                                        ? 'Active'
                                                        : 'Inactive',
                                                    style: TextStyle(
                                                      color: Colors.blue,
                                                      fontSize: isCompact
                                                          ? 10
                                                          : 12,
                                                      fontWeight:
                                                          FontWeight.bold,
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
                                ],
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () => isExpanded
                                    ? _hideLotDetail()
                                    : _showLotDetail(color),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
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
                          SizedBox(
                            height: 300,
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: _buildLotDetailContent(color, isCompact),
                            ),
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

  Widget _buildLotDetailContent(LotExpirationColor color, bool isCompact) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildLotInfoItem(
            'Level Type : ',
            _getLevelDescription(color.lotExpLevel?.toString() ?? 'N/A'),
            Iconsax.tag,
            isCompact,
          ),
          _buildLotInfoItem(
            'Description : ',
            color.description ?? 'N/A',
            Iconsax.info_circle,
            isCompact,
          ),
          _buildLotInfoItem(
            'Color : ',
            _getColorTypeName(color),
            Iconsax.colorfilter,
            isCompact,
          ),
          if (color.branch != null)
            _buildLotInfoItem(
              'Branch : ',
              _getBranchName(color.branch!),
              Iconsax.building,
              isCompact,
            ),
          if (color.itemNumber != null)
            _buildLotInfoItem(
              'Item : ',
              _getItemName(color.itemNumber!),
              Iconsax.box,
              isCompact,
            ),
          _buildLotInfoItem(
            'Minimum Days : ',
            color.daysMinimum?.toString() ?? 'N/A',
            Iconsax.calendar_1,
            isCompact,
          ),
          _buildLotInfoItem(
            'Maximum Days : ',
            color.daysMaximum?.toString() ?? 'N/A',
            Iconsax.calendar_1,
            isCompact,
          ),
          _buildLotInfoItem(
            'Satus Type : ',
            color.activeForSalesFlag == 'Y' ? 'Active' : 'Inactive',
            Iconsax.tag,
            isCompact,
          ),
          // Action buttons row
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(
                  Iconsax.edit,
                  'Edit',
                  () => _navigateToEditScreen(color),
                  isCompact,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLotInfoItem(
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
              color: Colors.blue.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.blue.withOpacity(0.2), width: 2),
            ),
            child: Icon(icon, size: 16, color: Colors.blue),
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
                    style: TextStyle(
                      color: Colors.blue,
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

  Widget _buildLotAvatar(
    LotExpirationColor color,
    bool isSelected,
    bool isCompact,
  ) {
    final Color backgroundColor;
    final Color iconColor;

    if (isSelected) {
      backgroundColor = const Color.fromARGB(255, 28, 66, 146);
      iconColor = Colors.white;
    } else {
      backgroundColor = Colors.blue.withOpacity(0.2);
      iconColor = Colors.blue;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.blue.withOpacity(0.5), width: 2),
      ),
      child: Icon(Iconsax.tag, color: iconColor, size: isCompact ? 20 : 24),
    );
  }
}
