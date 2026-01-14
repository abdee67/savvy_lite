// features/stock/location_master/pages/location_master_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:savvy_stock/core/constants/app_routes.dart';
import 'package:savvy_stock/core/utils/ui_helper.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/stock/location_entry/blocs/location_master_event.dart';
import 'package:savvy_stock/features/stock/location_entry/blocs/location_master_state.dart';
import '../blocs/location_master_bloc.dart';
import '../models/location_master_model.dart';

class LocationMasterListPage extends StatefulWidget {
  final AuthBloc authBloc;

  const LocationMasterListPage({super.key, required this.authBloc});

  @override
  State<LocationMasterListPage> createState() => _LocationMasterListPageState();
}

class _LocationMasterListPageState extends State<LocationMasterListPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSelectionMode = false;
  final Map<int, double> _dragOffset = {};
  final List<LocationMaster> _selectedLocations = [];

  // Animation controllers for detail panel
  late AnimationController _detailAnimationController;
  late Animation<double> _heightAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  // Detail panel state
  LocationMaster? _selectedLocation;
  bool _locationDetail = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLocations();
    });

    // Initialize animation controller
    _detailAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Set up animations
    _setupAnimations();

    _searchController.addListener(_onSearchChanged);
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

  void _loadLocations() {
    final companyId = widget.authBloc.state.companyId;
    if (companyId != null) {
      context.read<LocationMasterBloc>().add(LoadLocationMasters(companyId));
    } else {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _loadLocations();
      });
    }
  }

  void _handleSearch(String query) {
    context.read<LocationMasterBloc>().add(SearchLocations(query));
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<LocationMasterBloc>().add(SearchLocations(''));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _detailAnimationController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedLocations.clear();
      }
    });
  }

  void _toggleLocationSelection(LocationMaster location) {
    setState(() {
      if (_selectedLocations.contains(location)) {
        _selectedLocations.remove(location);
      } else {
        _selectedLocations.add(location);
      }
    });
  }

  void _showLocationDetail(LocationMaster location) {
    setState(() {
      _selectedLocation = location;
      _locationDetail = true;
    });

    // Start the animation
    _detailAnimationController.forward(from: 0.0);
  }

  void _hideLocationDetail() {
    // Reverse the animation
    _detailAnimationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _locationDetail = false;
          _selectedLocation = null;
        });
        _detailAnimationController.reset();
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedLocations.clear();
      _isSelectionMode = false;
    });
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

  void _safeDelete(BuildContext context, {int? index}) {
    final bloc = context.read<LocationMasterBloc>();
    final state = bloc.state;

    if (_selectedLocations.isNotEmpty) {
      final itemsToDelete = _selectedLocations;
      showDeleteDialog(
        context,
        title: 'Delete selected locations?',
        content:
            'Are you sure you want to delete ${itemsToDelete.length} locations?',
        onConfirm: () {
          for (final location in itemsToDelete) {
            bloc.add(DeleteLocationMaster(location));
          }
          _clearSelection();
          _refreshList(context);
        },
      );
      return;
    }

    if (index == null || index < 0 || index >= state.items.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete location. Invalid index.')),
      );
      return;
    }

    final itemToDelete = state.items[index];
    showDeleteDialog(
      context,
      title: 'Delete "${itemToDelete.locationDescription}"?',
      content:
          'Are you sure you want to delete "${itemToDelete.locationDescription}"?',
      onConfirm: () {
        bloc.add(DeleteLocationMaster(itemToDelete));
        _refreshList(context);
      },
    );
  }

  // Helper method to count assigned location codes
  int _getAssignedCodesCount(LocationMaster location) {
    final codes = [
      location.code01,
      location.code02,
      location.code03,
      location.code04,
      location.code05,
      location.code06,
      location.code07,
      location.code08,
      location.code09,
      location.code10,
    ];
    return codes.where((code) => code != null && code.isNotEmpty).length;
  }

  // Helper method to get non-empty location codes
  List<String> _getNonEmptyCodes(LocationMaster location) {
    final codes = [
      if (location.code01 != null && location.code01!.isNotEmpty)
        location.code01!,
      if (location.code02 != null && location.code02!.isNotEmpty)
        location.code02!,
      if (location.code03 != null && location.code03!.isNotEmpty)
        location.code03!,
      if (location.code04 != null && location.code04!.isNotEmpty)
        location.code04!,
      if (location.code05 != null && location.code05!.isNotEmpty)
        location.code05!,
      if (location.code06 != null && location.code06!.isNotEmpty)
        location.code06!,
      if (location.code07 != null && location.code07!.isNotEmpty)
        location.code07!,
      if (location.code08 != null && location.code08!.isNotEmpty)
        location.code08!,
      if (location.code09 != null && location.code09!.isNotEmpty)
        location.code09!,
      if (location.code10 != null && location.code10!.isNotEmpty)
        location.code10!,
    ];
    return codes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey,
      appBar: AppBar(
        title: const Text('Location Master'),
        backgroundColor: const Color.fromARGB(255, 28, 66, 146),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh_circle),
            onPressed: () {
              _loadLocations();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: BlocConsumer<LocationMasterBloc, LocationMasterState>(
          listener: (context, state) {
            if (state.status == LocationMasterStatus.failure &&
                state.message.isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
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
                    // Search Bar
                    _buildSearchBar(),
                    _buildActionButtons(state),
                    // Location List
                    Expanded(child: _buildLocationList(state)),
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
                hintText: 'Search by location name or branch...',
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

  Widget _buildActionButtons(LocationMasterState state) {
    final hasSelection = _selectedLocations.isNotEmpty;

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
                  '${_selectedLocations.length} selected',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Iconsax.trash, color: Colors.red),
                  onPressed: () => _safeDelete(context),
                  tooltip: 'Delete selected',
                ),
                if (_selectedLocations.length == 1)
                  IconButton(
                    icon: const Icon(
                      Iconsax.edit,
                      color: Color.fromARGB(255, 28, 66, 146),
                    ),
                    onPressed: () {
                      final location = _selectedLocations.first;
                      _navigateToEditScreen(location);
                    },
                    tooltip: 'Edit location',
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
    return BlocBuilder<LocationMasterBloc, LocationMasterState>(
      builder: (context, state) {
        return ElevatedButton(
          onPressed: () {
            if (_selectedLocations.isNotEmpty) {
              // Navigate to edit screen with selected location
              final location = _selectedLocations.first;
              _navigateToEditScreen(location);
            } else {
              // Navigate to add screen
              _navigateToCreateScreen();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 28, 66, 146),
            shape: const CircleBorder(),
          ),
          child: Icon(
            _selectedLocations.isNotEmpty ? Icons.edit : Icons.add,
            color: Colors.white,
          ),
        );
      },
    );
  }

  Widget _buildLocationList(LocationMasterState state) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final isSmallScreen = screenWidth < 700;
    final cardSpacing = screenHeight * 0.02;
    final cardWidth = isSmallScreen ? screenWidth * 0.85 : screenWidth * 0.8;

    if (state.status == LocationMasterStatus.loading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == LocationMasterStatus.failure && state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              state.message.isEmpty
                  ? 'Failed to load locations'
                  : state.message,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _refreshList(context),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final filteredLocations = state.filteredItems;

    if (filteredLocations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.location, size: 64, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'No locations found'
                  : 'No results for "${_searchController.text}"',
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
        itemCount: filteredLocations.length,
        separatorBuilder: (context, index) => SizedBox(height: cardSpacing),
        itemBuilder: (context, index) {
          final location = filteredLocations[index];
          final isSelected = _selectedLocations.contains(location);

          return _buildLocationListItem(
            location,
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

  Widget _buildLocationListItem(
    LocationMaster location,
    bool isSelected,
    LocationMasterState state,
    int index,
    bool isCompact,
    double cardWidth,
  ) {
    final offset = _dragOffset[index] ?? 0.0;
    final isExpanded = _locationDetail == true && _selectedLocation == location;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;

    // For responsiveness:
    final collapsedHeight = isCompact
        ? screenHeight * 0.22
        : screenHeight * 0.14;

    final expandedHeight = isCompact
        ? screenHeight * 0.55
        : screenHeight * 0.45;
    final collapsedWidth = isCompact ? screenWidth * 0.92 : screenWidth * 0.8;

    final assignedCodesCount = _getAssignedCodesCount(location);

    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          _toggleLocationSelection(location);
        } else {
          // Single tap shows detail when not in selection mode
          _showLocationDetail(location);
        }
      },
      onLongPress: () {
        if (!_isSelectionMode) {
          setState(() {
            _isSelectionMode = true;
          });
        }
        _toggleLocationSelection(location);
      },
      onHorizontalDragUpdate: (details) =>
          _onHorizontalDragUpdate(index, details),
      onHorizontalDragEnd: (details) =>
          _onHorizontalDragEnd(context, index, details),
      onDoubleTap: () => _showLocationDetail(location),
      child: AnimatedBuilder(
        animation: _scrollController,
        builder: (context, child) => Container(
          transform: Matrix4.translationValues(offset, 0, 0),
          width: collapsedWidth,
          height: isExpanded ? expandedHeight : collapsedHeight,
          child: Stack(
            children: [
              // 1. DELETE INDICATOR - Should be FIRST in Stack
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

              // 3. LOCATION CARD
              AnimatedContainer(
                padding: const EdgeInsets.only(
                  top: 10,
                  left: 10,
                  right: 10,
                  bottom: 10,
                ),
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
                        // Location Avatar
                        _buildLocationAvatar(location, isSelected, isCompact),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                location.locationDescription ??
                                    'Unnamed location',
                                style: TextStyle(
                                  color: const Color(0xFF373737),
                                  fontSize: isCompact ? 20 : 24,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                location.branchName ?? 'Unnamed branch',
                                style: TextStyle(
                                  color: const Color.fromARGB(
                                    255,
                                    107,
                                    104,
                                    104,
                                  ),
                                  fontSize: isCompact ? 12 : 14,
                                  fontStyle: FontStyle.italic,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Location codes count badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.blue[200]!),
                                ),
                                child: Text(
                                  '$assignedCodesCount location codes',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: const Color(0xFF145888),
                                    fontWeight: FontWeight.bold,
                                  ),
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
                              ? _hideLocationDetail()
                              : _showLocationDetail(location),
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
                    child: _buildLocationDetailContent(location, isCompact),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationDetailContent(LocationMaster location, bool isCompact) {
    final assignedCodesCount = _getAssignedCodesCount(location);
    final nonEmptyCodes = _getNonEmptyCodes(location);
    final displayedCodes = nonEmptyCodes.take(5).toList();
    final hasMoreCodes = nonEmptyCodes.length > 5;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildLocationInfoItem(
            'Location ID : ',
            location.id.toString(),
            Iconsax.card,
            isCompact,
          ),
          _buildLocationInfoItem(
            'Branch : ',
            location.branchName ?? 'Unknown Branch',
            Iconsax.building,
            isCompact,
          ),
          _buildLocationInfoItem(
            'Total Location Codes : ',
            '$assignedCodesCount',
            Iconsax.code,
            isCompact,
          ),

          // Location Codes Section
          if (nonEmptyCodes.isNotEmpty)
            Padding(
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
                    child: const Icon(
                      Iconsax.code,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Location Codes : ',
                          style: TextStyle(
                            color: Color(0xFF373737),
                            fontSize: 13,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Display location codes as chips
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            ...displayedCodes.map(
                              (code) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.blue[200]!),
                                ),
                                child: Text(
                                  code,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.blue[800],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            if (hasMoreCodes)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange[50],
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.orange[200]!,
                                  ),
                                ),
                                child: Text(
                                  '+${nonEmptyCodes.length - 5} more',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.orange[800],
                                    fontWeight: FontWeight.w500,
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
            ),

          if (location.marginType != null)
            _buildLocationInfoItem(
              'Margin Type : ',
              location.marginType == 'F' ? 'Flat' : 'Percentage',
              Iconsax.chart,
              isCompact,
            ),
          if (location.marginRate != null)
            _buildLocationInfoItem(
              'Margin Rate : ',
              '${location.marginRate}${location.marginType == 'F' ? ' ETB' : '%'}',
              Iconsax.dollar_circle,
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
                  () => _navigateToEditScreen(location),
                  isCompact,
                ),
                _buildActionButton(
                  Iconsax.export,
                  'Export',
                  () => _exportLocation(location),
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

  Widget _buildLocationInfoItem(
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

  Widget _buildLocationAvatar(
    LocationMaster location,
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
      child: Icon(
        Iconsax.location,
        color: iconColor,
        size: isCompact ? 20 : 24,
      ),
    );
  }

  void _navigateToCreateScreen() {
    final companyId = widget.authBloc.state.companyId;
    if (companyId != null) {
      context.read<LocationMasterBloc>().add(PrepareCreateLocation(companyId));
      context.push(AppRoutes.locationMasterCreate);
    }
  }

  void _navigateToEditScreen(LocationMaster location) {
    context.read<LocationMasterBloc>().add(PrepareEditLocation(location));
    context.push(AppRoutes.locationMasterEdit, extra: location);
  }

  void _refreshList(BuildContext context) {
    final companyId = widget.authBloc.state.companyId;
    if (companyId != null) {
      context.read<LocationMasterBloc>().add(LoadLocationMasters(companyId));
    }
  }

  void _exportLocation(LocationMaster location) {
    // Implement export functionality
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Location data exported')));
  }
}
