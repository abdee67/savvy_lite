import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:savvy_stock/core/blocs/system_constant/system_constant_bloc.dart';
import 'package:savvy_stock/core/blocs/system_constant/system_constant_event.dart';
import 'package:savvy_stock/core/constants/app_routes.dart';
import 'package:savvy_stock/core/di/injection_container.dart';
import 'package:savvy_stock/core/repositories/udc_repository.dart';
import 'package:savvy_stock/core/utils/ui_helper.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/branch_list/blocs/branch_list_bloc.dart';
import 'package:savvy_stock/features/branch_list/blocs/branch_list_event.dart'
    hide ClearSelection;
import 'package:savvy_stock/features/branch_list/models/branch_list_model.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_event.dart'
    hide ClearSelection;
import 'package:savvy_stock/features/stock/location_entry/blocs/location_master_event.dart';
import 'package:savvy_stock/features/stock/lot_coloring/bloc/lot_coloring_bloc.dart';
import 'package:savvy_stock/features/stock/lot_coloring/model/lot_coloring_model.dart';
import 'package:savvy_stock/features/stock/lot_master/blocs/lot_master_bloc.dart';
import 'package:savvy_stock/features/stock/lot_master/blocs/lot_master_event.dart';
import 'package:savvy_stock/features/stock/lot_master/blocs/lot_master_state.dart';
import 'package:savvy_stock/features/stock/lot_master/models/lot_master_model.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_bloc.dart';
import 'package:savvy_stock/features/stock/location_entry/blocs/location_master_bloc.dart';

class LotMasterDashboard extends StatefulWidget {
  final AuthBloc authBloc;
  const LotMasterDashboard({super.key, required this.authBloc});

  @override
  State<LotMasterDashboard> createState() => _LotMasterDashboardState();
}

class _LotMasterDashboardState extends State<LotMasterDashboard>
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

  //  Detail panel state
  LotMaster? _selectedLot;
  final List<LotMaster> _selectedLots = [];
  bool _lotDetail = false;

  final List<Branch> _branches = [];
  final UdcRepository _udcRepository = getIt<UdcRepository>();

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

    // Load system constants
    context.read<SystemConstantBloc>().add(
      LoadSystemConstants(widget.authBloc.state.companyId!),
    );

    context.read<LotMasterBloc>().add(
      LoadLotMasters(widget.authBloc.state.companyId!),
    );
    context.read<LotMasterBloc>().add(ClaculateMultipleLotStatus());
    context.read<BranchBloc>().add(
      LoadBranchs(widget.authBloc.state.companyId!),
    );
    context.read<StockItemEntryBloc>().add(
      LoadItems(widget.authBloc.state.companyId!),
    );
    context.read<LocationMasterBloc>().add(
      LoadLocationMasters(widget.authBloc.state.companyId!),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _debugSystemConstants();
      _debugSystemConstantBloc();
      if (context.read<LotMasterBloc>().state.items.isNotEmpty) {
        _debugLotColorCalculation(
          context.read<LotMasterBloc>().state.items.first,
        );
      }
    });
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
    context.read<LotMasterBloc>().add(SearchLotMasters(query));
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<LotMasterBloc>().add(SearchLotMasters(''));
  }

  void _toggleLotSelection(LotMaster lot, bool selected) {
    // You might need to add a SelectLot event in your bloc
    context.read<LotMasterBloc>().add(SelecteLot(lot, selected));
  }

  void _showLotDetail(LotMaster lot) {
    setState(() {
      _selectedLot = lot;
      _lotDetail = true;
    });

    //Start the animation
    _detailAnimationController.forward(from: 0.0);
  }

  void _hideLotDetail() {
    // Reverse the animation
    _detailAnimationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _lotDetail = false;
          _selectedLot = null;
        });
      }
    });
  }

  void _clearSelection() {
    context.read<LotMasterBloc>().add(ClearSelection());
    setState(() {
      _isSelectionMode = false;
    });
  }

  void _exportLot(LotMaster lot) {
    // Implement export functionality
    print('Exporting lot: ${lot.lotNumber}');
  }

  void _navigateToCreateScreen() {
    final companyId = context.read<AuthBloc>().state.companyId;
    if (companyId != null) {
      context.read<LotMasterBloc>().add(PrepareCreateLot(companyId));
      context.push(AppRoutes.lotCreation);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Company ID not found. Please login again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToEditScreen(LotMaster lot) {
    context.read<LotMasterBloc>().add(PrepareEditLot(lot));
    context.push(AppRoutes.lotEdit, extra: lot);
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
    final itemBloc = context.read<StockItemEntryBloc>();
    final itemDescription =
        itemBloc.state.items
            .where((entry) => entry.id == itemId)
            .firstOrNull
            ?.itemDescription ??
        'Item $itemId';
    return itemDescription;
  }

  String _getLocationName(int locationId) {
    final locationBloc = context.read<LocationMasterBloc>();
    final locationState = locationBloc.state;
    final locationName =
        locationState.locations
            .where((entry) => entry.id == locationId)
            .firstOrNull
            ?.locationDescription ??
        'Branch $locationId';
    return locationName;
  }

  void _safeDelete(BuildContext context, {int? index}) {
    final bloc = context.read<LotMasterBloc>();
    final state = bloc.state;

    //CASE 1: Multiple lots
    if (state.multiSelectionItems.isNotEmpty) {
      final lotsToDelete = state.multiSelectionItems;
      showDeleteDialog(
        context,
        title: 'Delete selected lots?',
        content: 'Are you sure you want to delete ${lotsToDelete.length} lots?',
        onConfirm: () {
          final ids = lotsToDelete.map((e) => e.id).toList();
          final deletedIndexes = lotsToDelete
              .map((lot) => state.items.indexOf(lot))
              .toList();
          bloc.add(DeleteMultipleLotMasters(lotsToDelete));
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

    final lotToDelete = state.filteredItems[index];

    showDeleteDialog(
      context,
      title: 'Delete Lot ${lotToDelete.lotNumber}?',
      content:
          'Are you sure you want to delete lot "${lotToDelete.lotNumber}"?',
      onConfirm: () {
        bloc.add(DeleteLotMaster(lotToDelete));
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

  // Enhanced status methods
  String _getStatusBadgeText(LotMaster lot) {
    // Use status description if available, otherwise fall back to code
    if (lot.statusDescription != null && lot.statusDescription!.isNotEmpty) {
      return lot.statusDescription!;
    }

    // Fallback to status code mapping
    if (lot.statusCode != null && lot.statusCode!.isNotEmpty) {
      switch (lot.statusCode?.toUpperCase()) {
        case 'A':
          return 'Active';
        case 'E':
          return 'Expired';
        case 'I':
          return 'Inactive';
        case 'D':
          return 'Damaged';
        case 'H':
          return 'On Hold';
        default:
          return lot.statusCode!; //return code if we dont recognize it
      }
    }

    return 'Unknown';
  }

  Color _getColorFromType(LotExpirationColor? color) {
    if (color == null) return Colors.grey.shade200;

    final code = (color.colorTypeCode ?? '').trim().toUpperCase();
    final name = (color.colorTypeName ?? '').trim().toLowerCase();

    print('🎨 Color Mapping - Code: $code, Name: $name');

    // Map based on your UDC data
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

  void _debugLotColorCalculation(LotMaster lot) async {
    final systemConstant = context.read<SystemConstantBloc>().state.selected;
    final lotTypeUdcDetail = await _udcRepository.getUdcDetailById(
      systemConstant?.lotType,
    );
    final lotType = lotTypeUdcDetail?.detailCode.toUpperCase();

    final color = await context.read<LotExpirationColorsBloc>().getLotColorType(
      lot.branch,
      lot.itemNumber,
      lot.dateExpiration,
      lot.dateEffective,
      lot.dateReceived,
    );

    // Use the method from LotExpirationColorsBloc
    final daysDifference = context
        .read<LotExpirationColorsBloc>()
        .calculateDaysDifference(
          lot.dateExpiration,
          lot.dateEffective,
          lot.dateReceived,
          lotType,
        );

    print('''
🎯 DEBUG LOT COLOR CALCULATION:
  Lot: ${lot.lotNumber}
  Lot Type: $lotType (${lotTypeUdcDetail?.description1})
  Branch: ${lot.branch}
  Item: ${lot.itemNumber}
  Expiration: ${lot.dateExpiration}
  Effective: ${lot.dateEffective} 
  Received: ${lot.dateReceived}
  Calculated Color: ${color?.colorTypeName} (${color?.colorTypeCode})
  Days Difference: $daysDifference
''');
  }

  void _debugSystemConstants() async {
    try {
      final systemConstant = context.read<SystemConstantBloc>().state.selected;
      print('''
🔧 SYSTEM CONSTANT DEBUG:
  Company ID: ${widget.authBloc.state.companyId}
  System Constant ID: ${systemConstant?.id}
  Lot Type ID: ${systemConstant?.lotType}
  Apply Lot Mgmt: ${systemConstant?.applyLotMgm}
  Is Synced: ${systemConstant?.isSynced}
''');

      if (systemConstant?.lotType != null) {
        final lotTypeUdc = await _udcRepository.getUdcDetailById(
          systemConstant?.lotType,
        );
        print(
          '  Lot Type UDC: ${lotTypeUdc?.detailCode} - ${lotTypeUdc?.description1}',
        );
      } else {
        print('  ❌ Lot Type is NULL in system constant');

        // Check if system constant is loaded at all
        final systemConstantState = context.read<SystemConstantBloc>().state;
        print(
          '  System Constant State: ${systemConstantState.systemConstants.length} constants loaded',
        );
        print(
          '  Selected System Constant: ${systemConstantState.selected?.toJson()}',
        );
      }
    } catch (e) {
      print('❌ Error debugging system constants: $e');
    }
  }

  // Call this in your initState or build method
  // WidgetsBinding.instance.addPostFrameCallback((_) => _debugSystemConstants());
  void _debugSystemConstantBloc() {
    final systemConstantState = context.read<SystemConstantBloc>().state;
    final systemConstant = systemConstantState.selected;

    print('''
🔍 SYSTEM CONSTANT BLOC STATE DEBUG:
  Status: ${systemConstantState.status}
  Constants Loaded: ${systemConstantState.systemConstants.length}
  Selected Constant: ${systemConstant?.id}
  Selected Lot Type: ${systemConstant?.lotType}
  Has Selected: ${systemConstantState.selected != null}
  State: ${systemConstantState.toString()}
''');
  }

  // Call this in your build method
  // WidgetsBinding.instance.addPostFrameCallback((_) => _debugSystemConstantBloc());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey,
      appBar: AppBar(
        title: const Text('Lot Master'),
        backgroundColor: const Color.fromARGB(255, 28, 66, 146),
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<LotMasterBloc, LotMasterState>(
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

                  // Lot List
                  Expanded(child: _buildLotList(state)),
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
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: _handleSearch,
            ),
          ),
          const SizedBox(width: 8),
          // Add refresh/calculate button
          IconButton(
            icon: const Icon(Iconsax.calculator),
            onPressed: _calculateAllLotStatus,
            tooltip: 'Recalculate all lot status',
            style: IconButton.styleFrom(backgroundColor: Colors.blue[50]),
          ),
          const SizedBox(width: 12),
          _buildFloatingActionButton(context),
        ],
      ),
    );
  }

  Widget _buildActionButtons(LotMasterState state) {
    final hasSelection = _selectedLots.isNotEmpty;

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
                  '${_selectedLots.length} selected',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Iconsax.calculator, color: Colors.blue),
                  onPressed: _calculateAllLotStatus,
                  tooltip: 'Recalculate status for selected',
                ),
                IconButton(
                  icon: const Icon(Iconsax.trash, color: Colors.red),
                  onPressed: () => _safeDelete(context),
                  tooltip: 'Delete selected',
                ),
                if (_selectedLots.length == 1)
                  IconButton(
                    icon: const Icon(
                      Iconsax.edit,
                      color: Color.fromARGB(255, 28, 66, 146),
                    ),
                    onPressed: () {
                      final lot = _selectedLots.first;
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
    return BlocBuilder<LotMasterBloc, LotMasterState>(
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

  Widget _buildLotList(LotMasterState state) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 700;
    final cardSpacing = screenHeight * 0.02;
    final cardWidth = isSmallScreen ? screenWidth * 0.85 : screenWidth * 0.8;

    if (state.status == LotMasterStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == LotMasterStatus.failure) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              state.message.isNotEmpty ? state.message : 'Failed to load lots',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<LotMasterBloc>().add(
                LoadLotMasters(widget.authBloc.state.companyId!),
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
            const Icon(Iconsax.box_1, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              state.searchQuery.isEmpty
                  ? 'No lots found'
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
          final lot = state.filteredItems[index];
          final isSelected = state.selectedItems.contains(lot);

          return _buildLotListItem(
            lot,
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

  Widget _buildLotListItem(
    LotMaster lot,
    bool isSelected,
    LotMasterState state,
    int index,
    bool isCompact,
    double cardWidth,
  ) {
    final offset = _dragOffset[index] ?? 0.0;
    final isExpanded = _lotDetail == true && _selectedLot == lot;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // For responsiveness:
    final collapsedHeight = isCompact
        ? screenHeight * 0.22
        : screenHeight * 0.14;
    final expandedHeight = isCompact
        ? screenHeight * 0.55
        : screenHeight * 0.45;
    final collapsedWidth = isCompact ? screenWidth * 0.92 : screenWidth * 0.8;

    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          _toggleLotSelection(lot, !isSelected);
        } else {
          _showLotDetail(lot);
        }
      },
      onLongPress: () {
        if (!_isSelectionMode) {
          setState(() {
            _isSelectionMode = true;
          });
        }
        _toggleLotSelection(lot, !isSelected);
      },
      onDoubleTap: () => _showLotDetail(lot),
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

              // 3. LOT CARD
              AnimatedContainer(
                padding: const EdgeInsets.only(top: 10, left: 10, right: 10),
                width: collapsedWidth,
                height: collapsedHeight,
                duration: const Duration(milliseconds: 400),
                transform: Matrix4.translationValues(offset, 0, 0),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: _getColorFromType(lot.tempColorType),
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
                        // Lot Avatar
                        _buildLotAvatar(lot, isSelected, isCompact),
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
                                    'Lot #${lot.lotNumber ?? 'N/A'}',
                                    style: TextStyle(
                                      color: const Color(0xFF373737),
                                      fontSize: isCompact ? 20 : 24,
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
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
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.circle,
                                          size: 14,
                                          color: Colors.blue,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _getStatusBadgeText(lot),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.blue,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              // Date information
                              if (lot.dateEffective != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.blue),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Iconsax.calendar_1,
                                        size: 12,
                                        color: Colors.blue,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Effective: ${_formatDate(lot.dateEffective!)}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.blue,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 2),
                              if (lot.dateExpiration != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.blue),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Iconsax.calendar_tick,
                                        size: 12,
                                        color: Colors.blue,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Expires: ${_formatDate(lot.dateExpiration!)}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.blue,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
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
                        // UPDATED: Quantity badge with status color
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.blue),
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
                                'Qty: ${lot.quantityAvailable?.toStringAsFixed(2) ?? '0.00'}',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: isCompact ? 10 : 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // See More / See Less button
                        ElevatedButton(
                          onPressed: () => isExpanded
                              ? _hideLotDetail()
                              : _showLotDetail(lot),
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
                    child: _buildLotDetailContent(lot, isCompact),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLotDetailContent(LotMaster lot, bool isCompact) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildLotInfoItem(
            'Lot Number : ',
            lot.lotNumber?.toString() ?? 'N/A',
            Iconsax.tag,
            isCompact,
          ),
          _buildLotInfoItem(
            'Branch : ',
            _getBranchName(lot.branch!),
            Iconsax.building,
            isCompact,
          ),
          _buildLotInfoItem(
            'Item Number : ',
            _getItemName(lot.itemNumber!),
            Iconsax.box,
            isCompact,
          ),
          _buildLotInfoItem(
            'Location : ',
            _getLocationName(lot.location!),
            Iconsax.location,
            isCompact,
          ),
          _buildLotInfoItem(
            'Unit Price : ',
            lot.unitPrice != null
                ? '\$${lot.unitPrice!.toStringAsFixed(2)}'
                : 'N/A',
            Iconsax.dollar_circle,
            isCompact,
          ),
          _buildLotInfoItem(
            'Quantity Available : ',
            lot.quantityAvailable?.toStringAsFixed(2) ?? '0.00',
            Iconsax.weight,
            isCompact,
          ),
          _buildLotInfoItem(
            'Supplier Batch : ',
            lot.batchNumberSupplier ?? 'N/A',
            Iconsax.barcode,
            isCompact,
          ),
          _buildLotInfoItem(
            'Effective Date : ',
            lot.dateEffective != null ? _formatDate(lot.dateEffective!) : 'N/A',
            Iconsax.calendar_1,
            isCompact,
          ),
          _buildLotInfoItem(
            'Expiration Date : ',
            lot.dateExpiration != null
                ? _formatDate(lot.dateExpiration!)
                : 'N/A',
            Iconsax.calendar_tick,
            isCompact,
          ),
          _buildLotInfoItem(
            'Received Date : ',
            lot.dateReceived != null ? _formatDate(lot.dateReceived!) : 'N/A',
            Iconsax.calendar_add,
            isCompact,
          ),
          _buildLotInfoItem(
            'Lot Status : ',
            _getStatusBadgeText(lot),
            Iconsax.activity,
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
                  () => _navigateToEditScreen(lot),
                  isCompact,
                ),
                _buildActionButton(
                  Iconsax.export,
                  'Export',
                  () => _exportLot(lot),
                  isCompact,
                ),
                _buildActionButton(
                  Iconsax.calculator,
                  'Status',
                  () => _calculateSingleLotStatus(lot),
                  isCompact,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _calculateSingleLotStatus(LotMaster lot) async {
    final systemConstant = context.read<SystemConstantBloc>().state.selected;
    final lotTypeUdcDetail = await _udcRepository.getUdcDetailById(
      systemConstant?.lotType,
    );
    context.read<LotMasterBloc>().add(
      CalculateLotStatus(lot, lotTypeUdcDetail),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Recalculating status for Lot ${lot.lotNumber}...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _calculateAllLotStatus() {
    context.read<LotMasterBloc>().add(ClaculateMultipleLotStatus());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recalculating all lot status...'),
        backgroundColor: Colors.blue,
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

  Widget _buildLotAvatar(LotMaster lot, bool isSelected, bool isCompact) {
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

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
