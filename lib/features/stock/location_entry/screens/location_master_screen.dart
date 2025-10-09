// features/stock/location_master/pages/location_master_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:savvy_stock/core/constants/app_routes.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/stock/location_entry/blocs/location_master_event.dart';
import 'package:savvy_stock/features/stock/location_entry/blocs/location_master_state.dart';
import 'package:savvy_stock/features/stock/location_entry/widget/export_menu.dart';
import '../blocs/location_master_bloc.dart';
import '../models/location_master_model.dart';

class LocationMasterListPage extends StatefulWidget {
  final AuthBloc authBloc;

  const LocationMasterListPage({super.key, required this.authBloc});

  @override
  State<LocationMasterListPage> createState() => _LocationMasterListPageState();
}

class _LocationMasterListPageState extends State<LocationMasterListPage> {
  final TextEditingController _searchController = TextEditingController();
  List<LocationMaster> _filteredLocations = [];
  final List<LocationMaster> _selectedLocations = [];
  Map<String, List<LocationMaster>> _groupedLocations = {};
  final Map<String, bool> _expandedGroups = {};
  ViewMode _currentViewMode = ViewMode.list;
  bool _isSelectionMode = false;
  bool _initialLoadCompleted = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLocations();
    });
  }

  void _loadLocations() {
    if (_initialLoadCompleted) return;

    final companyId = widget.authBloc.state.companyId;
    if (companyId != null) {
      print('🔄 Initial load triggered - Company ID: $companyId');
      context.read<LocationMasterBloc>().add(LoadLocationMasters(companyId));
      _initialLoadCompleted = true;
    } else {
      print('⚠️ Company ID not available yet, waiting...');
      // Retry after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _loadLocations();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _filterLocations();
    });
  }

  void _filterLocations() {
    final state = context.read<LocationMasterBloc>().state;
    final searchTerm = _searchController.text.toLowerCase();

    if (searchTerm.isEmpty) {
      _filteredLocations = state.items;
    } else {
      _filteredLocations = state.items.where((location) {
        return location.locationDescription?.toLowerCase().contains(
                  searchTerm,
                ) ==
                true ||
            location.branchName?.toLowerCase().contains(searchTerm) == true ||
            location.code01?.toLowerCase().contains(searchTerm) == true ||
            location.code02?.toLowerCase().contains(searchTerm) == true ||
            location.code03?.toLowerCase().contains(searchTerm) == true;
      }).toList();
    }
    _groupLocations();
  }

  void _groupLocations() {
    _groupedLocations = {};
    for (final location in _filteredLocations) {
      final branchName = location.branchName ?? 'Unknown Branch';
      if (!_groupedLocations.containsKey(branchName)) {
        _groupedLocations[branchName] = [];
        _expandedGroups[branchName] = true;
      }
      _groupedLocations[branchName]!.add(location);
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedLocations.clear();
        context.read<LocationMasterBloc>().add(const SetSelectedLocation(null));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(context),
      floatingActionButton: _isSelectionMode
          ? null
          : _buildFloatingActionButton(context),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    final state = context.read<LocationMasterBloc>().state;
    final hasSelection = _isSelectionMode && _selectedLocations.isNotEmpty;
    final isWide = MediaQuery.of(context).size.width > 600;
    final theme = Theme.of(context);

    final List<Widget> mainActions = [
      if (!_isSelectionMode)
        IconButton(
          icon: Icon(
            _currentViewMode == ViewMode.list ? Icons.grid_view : Icons.list,
          ),
          onPressed: () {
            setState(() {
              _currentViewMode = _currentViewMode == ViewMode.list
                  ? ViewMode.grid
                  : ViewMode.list;
            });
          },
          tooltip: _currentViewMode == ViewMode.list
              ? 'Grid View'
              : 'List View',
        ),
      if (!_isSelectionMode && state.items.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.check_box_outlined),
          onPressed: _toggleSelectionMode,
          tooltip: 'Select Multiple',
        ),
      if (hasSelection && _selectedLocations.length == 1)
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => _navigateToEdit(context, _selectedLocations.first),
          tooltip: 'Edit Selected',
        ),
      if (hasSelection)
        IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _showDeleteDialog(context, _selectedLocations),
          tooltip: 'Delete Selected',
        ),
      IconButton(
        icon: const Icon(Icons.refresh),
        onPressed: () => _refreshList(context),
        tooltip: 'Refresh',
      ),
      if (!_isSelectionMode && state.items.isNotEmpty)
        ExportMenu(onExport: (format) => _exportData(context, format)),
    ];

    return AppBar(
      elevation: 0.5,
      backgroundColor: theme.colorScheme.onPrimaryContainer,
      foregroundColor: theme.colorScheme.inversePrimary,
      centerTitle: !isWide,
      leading: _isSelectionMode
          ? IconButton(
              icon: const Icon(Icons.close),
              onPressed: _toggleSelectionMode,
              tooltip: 'Cancel Selection',
            )
          : null,
      title: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
              child: child,
            ),
          );
        },
        child: _isSelectionMode
            ? Text(
                key: const ValueKey('selectionTitle'),
                '${_selectedLocations.length} selected',
                style: const TextStyle(fontWeight: FontWeight.w600),
              )
            : const Text(
                key: ValueKey('defaultTitle'),
                'Location Master',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
      ),
      actions: [
        if (isWide)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: Row(
              key: ValueKey(_isSelectionMode),
              mainAxisSize: MainAxisSize.min,
              children: mainActions,
            ),
          )
        else
          PopupMenuButton<int>(
            key: ValueKey(_isSelectionMode),
            icon: const Icon(Icons.more_vert),
            tooltip: 'Menu',
            itemBuilder: (context) => [
              if (!_isSelectionMode)
                PopupMenuItem(
                  value: 1,
                  child: Text(
                    _currentViewMode == ViewMode.list
                        ? 'Switch to Grid View'
                        : 'Switch to List View',
                  ),
                ),
              if (!_isSelectionMode && state.items.isNotEmpty)
                const PopupMenuItem(value: 2, child: Text('Select Multiple')),
              if (hasSelection && _selectedLocations.length == 1)
                const PopupMenuItem(value: 3, child: Text('Edit Selected')),
              if (hasSelection)
                const PopupMenuItem(value: 4, child: Text('Delete Selected')),
              const PopupMenuItem(value: 5, child: Text('Refresh')),
              if (!_isSelectionMode && state.items.isNotEmpty)
                const PopupMenuItem(value: 6, child: Text('Export')),
            ],
            onSelected: (value) {
              switch (value) {
                case 1:
                  setState(() {
                    _currentViewMode = _currentViewMode == ViewMode.list
                        ? ViewMode.grid
                        : ViewMode.list;
                  });
                  break;
                case 2:
                  _toggleSelectionMode();
                  break;
                case 3:
                  _navigateToEdit(context, _selectedLocations.first);
                  break;
                case 4:
                  _showDeleteDialog(context, _selectedLocations);
                  break;
                case 5:
                  _refreshList(context);
                  break;
                case 6:
                  _exportData(context, ExportFormat.csv);
                  break;
              }
            },
          ),
      ],
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _navigateToCreate(context),
      child: const Icon(Icons.add),
    );
  }

  Widget _buildBody(BuildContext context) {
    return BlocConsumer<LocationMasterBloc, LocationMasterState>(
      listener: (context, state) {
        if (state.status == LocationMasterStatus.failure &&
            state.message.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }

        // Update filtered data when state changes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _filterLocations();
        });

        // Load data if company ID becomes available and we haven't loaded yet
        if (state.companyId != 0 &&
            state.items.isEmpty &&
            !_initialLoadCompleted) {
          print('🔄 Company ID available in BLoC state, loading locations...');
          context.read<LocationMasterBloc>().add(
            LoadLocationMasters(state.companyId!),
          );
          _initialLoadCompleted = true;
        }
      },
      builder: (context, state) {
        if (state.status == LocationMasterStatus.loading &&
            state.items.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading locations...'),
              ],
            ),
          );
        }

        // Show error state
        if (state.status == LocationMasterStatus.failure &&
            state.items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Failed to load locations',
                  style: TextStyle(fontSize: 18, color: Colors.red),
                ),
                const SizedBox(height: 8),
                Text(
                  state.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
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

        if (state.items.isEmpty &&
            state.status != LocationMasterStatus.loading) {
          return _buildEmptyState(state);
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Search Bar
              _buildSearchBar(),
              const SizedBox(height: 16),

              // Status Info
              _buildStatusInfo(state),

              const SizedBox(height: 16),

              // View Mode Content
              Expanded(
                child: _currentViewMode == ViewMode.list
                    ? _buildListView(state)
                    : _buildGridView(state),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusInfo(LocationMasterState state) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total: ${state.items.length} • Filtered: ${_filteredLocations.length}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          if (state.status == LocationMasterStatus.loading)
            const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 4),
                Text(
                  'Loading...',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search locations...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
              )
            : null,
      ),
    );
  }

  Widget _buildListView(LocationMasterState state) {
    return ListView.builder(
      itemCount: _groupedLocations.length,
      itemBuilder: (context, groupIndex) {
        final branchName = _groupedLocations.keys.elementAt(groupIndex);
        final locations = _groupedLocations[branchName]!;
        final isExpanded = _expandedGroups[branchName] ?? true;

        return _buildBranchSection(branchName, locations, isExpanded, state);
      },
    );
  }

  Widget _buildBranchSection(
    String branchName,
    List<LocationMaster> locations,
    bool isExpanded,
    LocationMasterState state,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          // Branch Header
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.store,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                size: 20,
              ),
            ),
            title: Text(
              branchName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text(
              '${locations.length} location${locations.length == 1 ? '' : 's'}',
            ),
            trailing: IconButton(
              icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () {
                setState(() {
                  _expandedGroups[branchName] = !isExpanded;
                });
              },
            ),
            onTap: () {
              setState(() {
                _expandedGroups[branchName] = !isExpanded;
              });
            },
          ),

          // Locations List
          if (isExpanded) ...[
            const Divider(height: 1),
            ...locations.map(
              (location) => _buildLocationListItem(location, state),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationListItem(
    LocationMaster location,
    LocationMasterState state,
  ) {
    final isSelected = _isSelectionMode
        ? _selectedLocations.contains(location)
        : state.selected?.id == location.id;

    return ListTile(
      leading: _isSelectionMode
          ? Checkbox(
              value: isSelected,
              onChanged: (value) => _toggleLocationSelection(location),
            )
          : Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_on,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ),
      title: Text(
        location.locationDescription ?? 'Unnamed Location',
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isSelected ? Theme.of(context).colorScheme.primary : null,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (location.code01 != null && location.code01!.isNotEmpty)
            Text('Code 1: ${location.code01!}'),
          if (location.code02 != null && location.code02!.isNotEmpty)
            Text('Code 2: ${location.code02!}'),
          if (location.code03 != null && location.code03!.isNotEmpty)
            Text('Code 3: ${location.code03!}'),
        ],
      ),
      trailing: _isSelectionMode
          ? null
          : IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
              onPressed: () => _navigateToEdit(context, location),
            ),
      onTap: () {
        if (_isSelectionMode) {
          _toggleLocationSelection(location);
        } else {
          context.read<LocationMasterBloc>().add(SetSelectedLocation(location));
          _navigateToEdit(context, location);
        }
      },
      onLongPress: () {
        if (!_isSelectionMode) {
          _toggleSelectionMode();
          _toggleLocationSelection(location);
        }
      },
    );
  }

  Widget _buildGridView(LocationMasterState state) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: _filteredLocations.length,
      itemBuilder: (context, index) {
        final location = _filteredLocations[index];
        final isSelected = _isSelectionMode
            ? _selectedLocations.contains(location)
            : state.selected?.id == location.id;

        return _buildLocationGridItem(location, isSelected, state);
      },
    );
  }

  Widget _buildLocationGridItem(
    LocationMaster location,
    bool isSelected,
    LocationMasterState state,
  ) {
    return Card(
      elevation: 2,
      color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (_isSelectionMode) {
            _toggleLocationSelection(location);
          } else {
            context.read<LocationMasterBloc>().add(
              SetSelectedLocation(location),
            );
            _navigateToEdit(context, location);
          }
        },
        onLongPress: () {
          if (!_isSelectionMode) {
            _toggleSelectionMode();
            _toggleLocationSelection(location);
          }
        },
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location Icon
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Location Name
                  Text(
                    location.branchName ?? 'Unknown Branch',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // Branch Name
                  Text(
                    location.locationDescription ?? 'Unnamed',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const Spacer(),

                  // Codes
                  if (location.code01 != null && location.code01!.isNotEmpty)
                    Text(
                      'Code: ${location.code01!}',
                      style: const TextStyle(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            // Selection Checkbox
            if (_isSelectionMode)
              Positioned(
                top: 8,
                right: 8,
                child: Checkbox(
                  value: isSelected,
                  onChanged: (value) => _toggleLocationSelection(location),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(LocationMasterState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No Locations Found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Get started by creating your first location',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _navigateToCreate(context),
            icon: const Icon(Icons.add),
            label: const Text('Create First Location'),
          ),
        ],
      ),
    );
  }

  // Navigation Methods
  void _navigateToCreate(BuildContext context) {
    final companyId = widget.authBloc.state.companyId;
    if (companyId != null) {
      context.read<LocationMasterBloc>().add(PrepareCreateLocation(companyId));
      context.push(AppRoutes.locationMasterCreate);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot create: No company context'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _navigateToEdit(BuildContext context, LocationMaster? location) {
    if (location != null) {
      context.read<LocationMasterBloc>().add(PrepareEditLocation(location));
      context.push(AppRoutes.locationMasterEdit, extra: location);
    }
  }

  void _showDeleteDialog(BuildContext context, List<LocationMaster> locations) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            SizedBox(width: 8),
            Text('Delete Locations'),
          ],
        ),
        content: Text(
          locations.length == 1
              ? 'Are you sure you want to delete "${locations.first.locationDescription}"?'
              : 'Are you sure you want to delete ${locations.length} locations?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              for (final location in locations) {
                context.read<LocationMasterBloc>().add(
                  DeleteLocationMaster(location),
                );
                context.read<LocationMasterBloc>().add(
                  LoadLocationMasters(widget.authBloc.state.companyId!),
                );
              }
              _toggleSelectionMode();
              Navigator.of(context).pop();
              _refreshList(context);
            },
            child: Text(
              'Delete${locations.length > 1 ? ' ${locations.length}' : ''}',
            ),
          ),
        ],
      ),
    );
  }

  void _refreshList(BuildContext context) {
    final companyId = widget.authBloc.state.companyId;
    if (companyId != null) {
      print('🔄 Manual refresh triggered');
      context.read<LocationMasterBloc>().add(LoadLocationMasters(companyId));
    } else {
      print('❌ Cannot refresh: No company ID available');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot refresh: No company context'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _exportData(BuildContext context, ExportFormat format) {
    final state = context.read<LocationMasterBloc>().state;
    final data = state.items;

    switch (format) {
      case ExportFormat.xlsx:
        _exportToExcel(data);
        break;
      case ExportFormat.csv:
        _exportToCsv(data);
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Exported ${data.length} locations to ${format.name.toUpperCase()}',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _exportToExcel(List<LocationMaster> data) {
    // Implement Excel export
  }

  void _exportToCsv(List<LocationMaster> data) {
    // Implement CSV export
  }
}

// Add this enum for view modes
enum ViewMode { list, grid }

// Remove the old LocationListToolbar widget since we've integrated its functionality into the app bar
