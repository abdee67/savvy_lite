import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:savvy_stock/core/utils/ui_helper.dart';
import 'package:savvy_stock/core/widgets/custom_dropdown.dart';
import 'package:savvy_stock/core/widgets/custom_searchable_dropdown.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/stock/item_UoM_conversions/blocs/item_UoM_conversions_bloc.dart';
import 'package:savvy_stock/features/stock/item_UoM_conversions/blocs/item_UoM_conversions_event.dart';
import 'package:savvy_stock/features/stock/item_UoM_conversions/blocs/item_UoM_conversions_state.dart';
import 'package:savvy_stock/features/stock/item_UoM_conversions/models/item_UoM_conversions_model.dart';
import 'package:savvy_stock/features/stock/item_UoM_conversions/widgets/item_UoM_conversion_create_and_edit.dart.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_bloc.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_event.dart'
    hide ClearSelection;
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_state.dart';
import 'package:savvy_stock/features/stock/item_entry/models/item_entry_model.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_bloc.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_event.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_state.dart';
import 'package:savvy_stock/features/udc_detail/models/udc_details.dart';

class ItemUomConversionListScreen extends StatefulWidget {
  final AuthBloc authBloc;

  const ItemUomConversionListScreen({super.key, required this.authBloc});

  @override
  State<ItemUomConversionListScreen> createState() =>
      _ItemUomConversionListScreenState();
}

class _ItemUomConversionListScreenState
    extends State<ItemUomConversionListScreen>
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

  // Detail panel state
  ItemUomConversion? _selectedConversion;
  final List<ItemUomConversion> _selectedConversions = [];
  bool _conversionDetail = false;

  // Item selection
  int? _selectedItem;

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

    // Load initial data
    context.read<StockItemsEntryBloc>().add(
      LoadItems(widget.authBloc.state.companyId!),
    );
    context.read<UdcDetailsBloc>().add(LoadUdcDetailsByGroup('UM'));
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

  void _onItemChanged(int? itemId) {
    setState(() {
      _selectedItem = itemId;
    });

    if (itemId != null) {
      context.read<ItemUomConversionBloc>().add(
        LoadItemUomConversions(widget.authBloc.state.companyId!),
      );
    }
  }

  void _handleSearch(String query) {
    context.read<ItemUomConversionBloc>().add(SearchItemUomConversions(query));
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<ItemUomConversionBloc>().add(SearchItemUomConversions(''));
  }

  void _toggleConversionSelection(ItemUomConversion conversion, bool selected) {
    context.read<ItemUomConversionBloc>().add(
      SelectItemUomConversion(conversion, selected),
    );
  }

  void _showConversionDetail(ItemUomConversion conversion) {
    setState(() {
      _selectedConversion = conversion;
      _conversionDetail = true;
    });

    // Start the animation
    _detailAnimationController.forward(from: 0.0);
  }

  void _hideConversionDetail() {
    // Reverse the animation
    _detailAnimationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _conversionDetail = false;
          _selectedConversion = null;
        });
      }
    });
  }

  void _clearSelection() {
    context.read<ItemUomConversionBloc>().add(ClearSelection());
    setState(() {
      _isSelectionMode = false;
    });
  }

  void _exportConversion(ItemUomConversion conversion) {
    // Implement export functionality
    print('Exporting conversion: ${conversion.id}');
  }

  void _navigateToCreateScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ItemUomConversionForm(authBloc: widget.authBloc),
      ),
    );
  }

  void _navigateToEditScreen(ItemUomConversion conversion) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ItemUomConversionForm(
          authBloc: widget.authBloc,
          editingItem: conversion,
        ),
      ),
    );
  }

  void _deleteConversion(ItemUomConversion conversion) {
    showDeleteDialog(
      context,
      title: 'Delete UoM Conversion?',
      content: 'Are you sure you want to delete this UoM conversion?',
      onConfirm: () {
        context.read<ItemUomConversionBloc>().add(
          DeleteItemUomConversion(conversion),
        );
      },
    );
  }

  void _safeDelete(BuildContext context, {int? index}) {
    final bloc = context.read<ItemUomConversionBloc>();
    final state = bloc.state;

    // CASE 1: Multiple conversions
    if (state.multiSelectionItems.isNotEmpty) {
      final conversionsToDelete = state.multiSelectionItems;
      showDeleteDialog(
        context,
        title: 'Delete selected UoM conversions?',
        content:
            'Are you sure you want to delete ${conversionsToDelete.length} UoM conversions?',
        onConfirm: () {
          bloc.add(DeleteMultipleItemUomConversions(conversionsToDelete));
        },
      );
      return;
    }

    // CASE 2: Single conversion by index
    if (index == null || index < 0 || index >= state.filteredItems.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete conversion. Invalid index.'),
        ),
      );
      return;
    }

    final conversionToDelete = state.filteredItems[index];

    showDeleteDialog(
      context,
      title: 'Delete UoM Conversion?',
      content: 'Are you sure you want to delete this UoM conversion?',
      onConfirm: () {
        bloc.add(DeleteItemUomConversion(conversionToDelete));
      },
    );
  }

  void _onHorizontalDragUpdate(int index, DragUpdateDetails details) {
    setState(() {
      final current = _dragOffset[index] ?? 0;
      var newOffset = current + details.delta.dx;

      // Only allow left swipe
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

  String _getUomName(int? uomId, UdcDetailsState udcState) {
    if (uomId == null) return 'N/A';
    final uom = udcState.details.firstWhere(
      (u) => u.id == uomId,
      orElse: () => UdcDetails.empty(),
    );
    return uom.description1 ?? 'Unknown UoM';
  }

  String _getItemName(int? itemId, ItemEntryState itemState) {
    if (itemId == null) return 'N/A';
    final item = itemState.items.firstWhere(
      (i) => i.id == itemId,
      orElse: () => ItemEntryModel.empty(),
    );
    return item.itemDescription ?? 'Unknown Item';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('UoM Conversions'),
        backgroundColor: const Color.fromARGB(255, 28, 66, 146),
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<ItemUomConversionBloc, ItemUomConversionState>(
        listener: (context, state) {
          if (state.multiSelectionItems.isNotEmpty && !_isSelectionMode) {
            setState(() {
              _isSelectionMode = true;
            });
          } else if (state.multiSelectionItems.isEmpty && _isSelectionMode) {
            setState(() {
              _isSelectionMode = false;
            });
          }

          if (state.status == ItemUomConversionStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.message ?? 'Operation completed successfully',
                ),
                backgroundColor: Colors.green,
              ),
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
          return Stack(
            children: [
              Column(
                children: [
                  _buildSearchBar(),
                  // Filter Section
                  _buildFilterSection(),
                  _buildActionButtons(state),
                  // Conversion List
                  Expanded(child: _buildConversionList(state)),
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
                hintText: 'Search by item or UoM...',
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

  Widget _buildActionButtons(ItemUomConversionState state) {
    final hasSelection = state.multiSelectionItems.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: hasSelection ? 60 : 0,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: hasSelection
          ? Row(
              children: [
                Text(
                  '${state.multiSelectionItems.length} selected',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Iconsax.trash, color: Colors.red),
                  onPressed: () => _safeDelete(context),
                  tooltip: 'Delete selected',
                ),
                if (state.multiSelectionItems.length == 1)
                  IconButton(
                    icon: const Icon(
                      Iconsax.edit,
                      color: Color.fromARGB(255, 28, 66, 146),
                    ),
                    onPressed: () {
                      final conversion = state.multiSelectionItems.first;
                      _navigateToEditScreen(conversion);
                    },
                    tooltip: 'Edit conversion',
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
    return BlocBuilder<ItemUomConversionBloc, ItemUomConversionState>(
      builder: (context, state) {
        return ElevatedButton(
          onPressed: () {
            if (state.canEdit && state.multiSelectionItems.isNotEmpty) {
              final conversion = state.multiSelectionItems.first;
              _navigateToEditScreen(conversion);
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
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          // Item Dropdown
          BlocBuilder<StockItemsEntryBloc, ItemEntryState>(
            builder: (context, state) {
              if (state.status == ItemEntryStatus.loading) {
                return const Center(child: CircularProgressIndicator());
              }
              // Safe employee list with null check
              final item = state.items.toList();
              if (item.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'No valid item found',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              // Use CustomSearchableDropdown which works with String options.
              // We map branch descriptions to ids when selection changes.
              return Builder(
                builder: (context) {
                  String? currentItemDesc;
                  if (_selectedItem != null) {
                    final match = item.where((b) => b.id == _selectedItem);
                    if (match.isNotEmpty) {
                      currentItemDesc = match.first.itemDescription;
                    }
                  }

                  return CustomSearchableDropdown(
                    labelText: 'Item *',
                    options: item.map((b) => b.itemDescription ?? '').toList(),
                    value: currentItemDesc,
                    prefixIcon: Iconsax.profile_circle,
                    allowCustomEntries: false,
                    onChanged: (value) {
                      setState(() {
                        if (value == null) {
                          _selectedItem = null;
                        } else {
                          final matches = item.where(
                            (b) => b.itemDescription == value,
                          );
                          _selectedItem = matches.isNotEmpty
                              ? matches.first.id
                              : null;
                        }
                      });
                    },
                    validator: (value) {
                      if (_selectedItem == null) {
                        return 'Please select an item';
                      }
                      return null;
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildConversionList(ItemUomConversionState state) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 700;
    final cardSpacing = screenHeight * 0.02;
    final cardWidth = isSmallScreen ? screenWidth * 0.92 : screenWidth * 0.8;

    if (state.status == ItemUomConversionStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == ItemUomConversionStatus.failure) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              state.message ?? 'Failed to load UoM conversions',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_selectedItem == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.swap_horiz, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Please select an item to view UoM conversions',
              style: TextStyle(color: Colors.grey, fontSize: 16),
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
            const Icon(Icons.swap_horiz, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No UoM conversions found for this item',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    // Filter conversions by selected item
    final itemConversions = state.filteredItems
        .where((conversion) => conversion.itemNumber == _selectedItem)
        .toList();

    if (itemConversions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.swap_horiz, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No UoM conversions found for this item',
              style: TextStyle(color: Colors.grey, fontSize: 16),
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
        padding: const EdgeInsets.all(16),
        itemCount: itemConversions.length,
        separatorBuilder: (context, index) => SizedBox(height: cardSpacing),
        itemBuilder: (context, index) {
          final conversion = itemConversions[index];
          final isSelected = state.multiSelectionItems.contains(conversion);
          return _buildConversionCard(
            conversion,
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

  Widget _buildConversionCard(
    ItemUomConversion conversion,
    bool isSelected,
    ItemUomConversionState state,
    int index,
    bool isCompact,
    double cardWidth,
  ) {
    final offset = _dragOffset[index] ?? 0.0;
    final isExpanded =
        _conversionDetail == true && _selectedConversion == conversion;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // For responsiveness:
    final collapsedHeight = isCompact
        ? screenHeight * 0.15
        : screenHeight * 0.14;
    final expandedHeight = isCompact
        ? screenHeight * 0.55
        : screenHeight * 0.45;
    final collapsedWidth = isCompact ? screenWidth * 0.92 : screenWidth * 0.8;

    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          _toggleConversionSelection(conversion, !isSelected);
        } else {
          _showConversionDetail(conversion);
        }
      },
      onLongPress: () {
        if (!_isSelectionMode) {
          setState(() {
            _isSelectionMode = true;
          });
        }
        _toggleConversionSelection(conversion, !isSelected);
      },
      onDoubleTap: () => _showConversionDetail(conversion),
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
              // 1. DELETE INDICATOR
              if (!isExpanded)
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
                Positioned.fill(
                  top: 47,
                  child: Container(
                    width: collapsedWidth,
                    height: expandedHeight,
                    decoration: ShapeDecoration(
                      color: const Color(0xFFFDD105),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
              ],

              // 3. CONVERSION CARD
              AnimatedContainer(
                padding: const EdgeInsets.only(top: 10, left: 10, right: 10),
                width: collapsedWidth,
                height: collapsedHeight,
                duration: const Duration(milliseconds: 400),
                transform: Matrix4.translationValues(offset, 0, 0),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(color: Colors.transparent, width: 2),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Conversion Avatar
                        _buildConversionAvatar(
                          conversion,
                          isSelected,
                          isCompact,
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
                                    'Level ${conversion.uomStructureLevel ?? 'N/A'}',
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
                                ],
                              ),
                              // Conversion information
                              if (conversion.conversionFactor != null)
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.blue.withOpacity(0.3),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Iconsax.convert_3d_cube,
                                            size: 12,
                                            color: Colors.blue,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Factor: ${conversion.conversionFactor!}',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.blue,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.green.withOpacity(0.3),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Iconsax.arrow_swap_horizontal,
                                            size: 12,
                                            color: Colors.green,
                                          ),
                                          const SizedBox(width: 4),
                                          BlocBuilder<
                                            UdcDetailsBloc,
                                            UdcDetailsState
                                          >(
                                            builder: (context, udcState) {
                                              return Text(
                                                '${_getUomName(conversion.fromUom, udcState)} → ${_getUomName(conversion.toUom, udcState)}',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              );
                                            },
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // See More / See Less button
                        ElevatedButton(
                          onPressed: () => isExpanded
                              ? _hideConversionDetail()
                              : _showConversionDetail(conversion),
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
                    child: _buildConversionDetailContent(conversion, isCompact),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConversionDetailContent(
    ItemUomConversion conversion,
    bool isCompact,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildConversionInfoItem(
            'Structure Level : ',
            conversion.uomStructureLevel?.toString() ?? 'N/A',
            Iconsax.layer,
            isCompact,
          ),
          _buildConversionInfoItem(
            'From UoM : ',
            _getUomName(
              conversion.fromUom,
              context.read<UdcDetailsBloc>().state,
            ),
            Iconsax.convert_3d_cube,
            isCompact,
          ),
          _buildConversionInfoItem(
            'To UoM : ',
            _getUomName(conversion.toUom, context.read<UdcDetailsBloc>().state),
            Iconsax.convert_3d_cube,
            isCompact,
          ),
          _buildConversionInfoItem(
            'Conversion Factor : ',
            conversion.conversionFactor?.toString() ?? 'N/A',
            Iconsax.convert_card,
            isCompact,
          ),
          _buildConversionInfoItem(
            'Item : ',
            _getItemName(
              conversion.itemNumber,
              context.read<StockItemsEntryBloc>().state,
            ),
            Iconsax.box,
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
                  () => _navigateToEditScreen(conversion),
                  isCompact,
                ),
                _buildActionButton(
                  Iconsax.export,
                  'Export',
                  () => _exportConversion(conversion),
                  isCompact,
                ),
                _buildActionButton(
                  Iconsax.trash,
                  'Delete',
                  () => _deleteConversion(conversion),
                  isCompact,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversionInfoItem(
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

  Widget _buildConversionAvatar(
    ItemUomConversion conversion,
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
      child: Icon(
        Iconsax.convert_3d_cube,
        color: iconColor,
        size: isCompact ? 20 : 24,
      ),
    );
  }
}
