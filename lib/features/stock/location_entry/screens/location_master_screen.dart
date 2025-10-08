// features/stock/location_master/pages/location_master_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:savvy_stock/core/constants/app_routes.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/stock/location_entry/blocs/location_master_event.dart';
import 'package:savvy_stock/features/stock/location_entry/blocs/location_master_state.dart';
import 'package:savvy_stock/features/stock/location_entry/widget/export_menu.dart';
import 'package:savvy_stock/features/stock/location_entry/widget/location_list_toolBar.dart';
import 'package:savvy_stock/features/stock/location_entry/widget/location_master_create_edit.dart';
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

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Master'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Add any global actions here if needed
        ],
      ),
      body: BlocConsumer<LocationMasterBloc, LocationMasterState>(
        listener: (context, state) {
          if (state.status == LocationMasterStatus.success &&
              state.message.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state.status == LocationMasterStatus.failure &&
              state.message.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }

          // Update filtered locations when state changes
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _filterLocations();
          });
        },
        builder: (context, state) {
          return Column(
            children: [
              // Toolbar
              LocationListToolbar(
                onNewLocation: () => _navigateToCreate(context),
                onEdit: () => _navigateToEdit(context, state.selected),
                onDelete: () => _showDeleteDialog(context, state.selected),
                onRefresh: () => _refreshList(context),
                onExport: (format) => _exportData(context, format),
                isEditEnabled: state.selected != null,
                isDeleteEnabled: state.selected != null,
              ),

              // Search and Table
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Search Header
                      _buildSearchHeader(),

                      const SizedBox(height: 16),

                      // Data Table
                      Expanded(child: _buildLocationTable(state)),

                      // Pagination (if needed)
                      // _buildPagination(),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Row(
      children: [
        const Text(
          'Store Locations',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        SizedBox(
          width: 300,
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationTable(LocationMasterState state) {
    if (state.status == LocationMasterStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredLocations.isEmpty) {
      return const Center(
        child: Text(
          'No locations found.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Column(
        children: [
          // Table Header
          _buildTableHeader(),

          // Grouped Data
          Expanded(
            child: ListView.builder(
              itemCount: _groupedLocations.length,
              itemBuilder: (context, groupIndex) {
                final branchName = _groupedLocations.keys.elementAt(groupIndex);
                final locations = _groupedLocations[branchName]!;
                final isExpanded = _expandedGroups[branchName] ?? true;

                return _buildLocationGroup(
                  branchName,
                  locations,
                  isExpanded,
                  state,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: const Row(
        children: [
          SizedBox(width: 50), // Selection column space
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.all(12.0),
              child: Text(
                'Store/Branch',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: EdgeInsets.all(12.0),
              child: Text(
                'Location Description',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: EdgeInsets.all(12.0),
              child: Text(
                'Code 1',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: EdgeInsets.all(12.0),
              child: Text(
                'Code 2',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: EdgeInsets.all(12.0),
              child: Text(
                'Code 3',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationGroup(
    String branchName,
    List<LocationMaster> locations,
    bool isExpanded,
    LocationMasterState state,
  ) {
    return Column(
      children: [
        // Group Header
        ListTile(
          leading: Icon(isExpanded ? Icons.expand_more : Icons.chevron_right),
          title: Text(
            branchName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          trailing: Text('${locations.length} locations'),
          onTap: () {
            setState(() {
              _expandedGroups[branchName] = !isExpanded;
            });
          },
        ),

        // Group Data
        if (isExpanded) ...[
          ...locations.map((location) => _buildLocationRow(location, state)),
        ],
      ],
    );
  }

  Widget _buildLocationRow(LocationMaster location, LocationMasterState state) {
    final isSelected = state.selected?.id == location.id;

    return InkWell(
      onTap: () {
        context.read<LocationMasterBloc>().add(SetSelectedLocation(location));
      },
      onDoubleTap: () {
        _navigateToEdit(context, location);
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: Row(
          children: [
            // Selection Checkbox
            SizedBox(
              width: 50,
              child: Checkbox(
                value: isSelected,
                onChanged: (value) {
                  if (value == true) {
                    context.read<LocationMasterBloc>().add(
                      SetSelectedLocation(location),
                    );
                  } else {
                    context.read<LocationMasterBloc>().add(
                      const SetSelectedLocation(null),
                    );
                  }
                },
              ),
            ),

            // Store/Branch
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(location.branchName ?? 'Unknown'),
              ),
            ),

            // Location Description
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(location.locationDescription ?? ''),
              ),
            ),

            // Code 1
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(location.code01 ?? ''),
              ),
            ),

            // Code 2
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(location.code02 ?? ''),
              ),
            ),

            // Code 3
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(location.code03 ?? ''),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination() {
    // Simple pagination - in a real app, you'd implement proper pagination
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('1-10 of 100 records'), // This would be dynamic
          Row(
            children: [
              IconButton(icon: const Icon(Icons.first_page), onPressed: () {}),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {},
              ),
              const Text('Page 1 of 10'),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {},
              ),
              IconButton(icon: const Icon(Icons.last_page), onPressed: () {}),
            ],
          ),
          DropdownButton<int>(
            value: 10,
            items: const [
              DropdownMenuItem(value: 10, child: Text('10')),
              DropdownMenuItem(value: 20, child: Text('20')),
              DropdownMenuItem(value: 30, child: Text('30')),
              DropdownMenuItem(value: 40, child: Text('40')),
              DropdownMenuItem(value: 50, child: Text('50')),
            ],
            onChanged: (value) {},
          ),
        ],
      ),
    );
  }

  void _navigateToCreate(BuildContext context) {
    context.read<LocationMasterBloc>().add(
      PrepareCreateLocation(context.read<LocationMasterBloc>().state.companyId),
    );
    context.push(AppRoutes.locationMasterCreate);
  }

  void _navigateToEdit(BuildContext context, LocationMaster? location) {
    if (location != null) {
      context.read<LocationMasterBloc>().add(PrepareEditLocation(location));
      context.push(AppRoutes.locationMasterEdit, extra: location);
    }
  }

  void _showDeleteDialog(BuildContext context, LocationMaster? location) {
    if (location == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Confirmation'),
          ],
        ),
        content: const Text('Are you sure you want to delete this location?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<LocationMasterBloc>().add(
                DeleteLocationMaster(location),
              );
              Navigator.of(context).pop();
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  void _refreshList(BuildContext context) {
    final companyId = context.read<LocationMasterBloc>().state.companyId;
    context.read<LocationMasterBloc>().add(LoadLocationMasters(companyId));
  }

  void _exportData(BuildContext context, ExportFormat format) {
    // Implement export logic based on format
    final state = context.read<LocationMasterBloc>().state;
    final data = state.items;

    // This would typically use a package like excel or csv
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
        content: Text('Exported to ${format.name.toUpperCase()}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _exportToExcel(List<LocationMaster> data) {
    // Implement Excel export
    // You'd use a package like excel: ^2.0.1
  }

  void _exportToCsv(List<LocationMaster> data) {
    // Implement CSV export
  }
}
