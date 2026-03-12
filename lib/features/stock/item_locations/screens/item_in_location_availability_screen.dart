import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/branch_list/blocs/branch_list_bloc.dart';
import 'package:savvy_stock/features/branch_list/blocs/branch_list_event.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_bloc.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_event.dart';
import 'package:savvy_stock/features/stock/item_locations/blocs/item_locations_bloc.dart';
import 'package:savvy_stock/features/stock/item_locations/blocs/item_locations_event.dart';
import 'package:savvy_stock/features/stock/item_locations/blocs/item_locations_state.dart';
import 'package:savvy_stock/features/stock/item_locations/widgets/item_location_availability_filter_dialog.dart';
import 'package:savvy_stock/features/stock/location_entry/blocs/location_master_bloc.dart';
import 'package:savvy_stock/features/stock/location_entry/blocs/location_master_event.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_bloc.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_state.dart';

class ItemInLocationAvailabilityScreen extends StatefulWidget {
  final AuthBloc authBloc;
  const ItemInLocationAvailabilityScreen({super.key, required this.authBloc});

  @override
  State<ItemInLocationAvailabilityScreen> createState() =>
      _ItemInLocationAvailabilityScreenState();
}

class _ItemInLocationAvailabilityScreenState
    extends State<ItemInLocationAvailabilityScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    final companyId = widget.authBloc.state.companyId;
    if (companyId != null) {
      context.read<StockItemLocationBloc>().add(
        LoadLazyItemLocations(
          companyId: widget.authBloc.state.companyId!,
          page: 1,
          pageSize: 20,
        ),
      );
      context.read<BranchBloc>().add(
        LoadBranchs(widget.authBloc.state.companyId!),
      );
      context.read<StockItemsEntryBloc>().add(
        LoadItems(widget.authBloc.state.companyId!),
      );
      context.read<LocationMasterBloc>().add(
        LoadLocationMasters(widget.authBloc.state.companyId!),
      );
    }
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
      final state = context.read<StockItemLocationBloc>().state;
      if (state.hasMoreLazyItems &&
          state.status !=
              ItemLocationsStatus.loadingMoreItemLocationAvailability) {
        context.read<StockItemLocationBloc>().add(LoadMoreLazyItemLocations());
      }
    }
  }

  void _showFilterDialog() {
    final currentState = context.read<StockItemLocationBloc>().state;
    showDialog(
      context: context,
      builder: (context) {
        return ItemLocationAvailabilityFilterDialog(
          currentFilters: currentState.lazyFilters,
          onApply: (filters) {
            context.read<StockItemLocationBloc>().add(
              FilterLazyItemLocations(filters),
            );
          },
          onClear: () {
            context.read<StockItemLocationBloc>().add(
              ClearLazyItemLocationsFilters(),
            );
          },
        );
      },
    );
  }

  void _refreshList() {
    final companyId = widget.authBloc.state.companyId;
    if (companyId != null) {
      context.read<StockItemLocationBloc>().add(
        LoadLazyItemLocations(companyId: companyId, page: 1, pageSize: 20),
      );
    }
  }

  String _getLocationName(int locationId) {
    final locationBloc = context.read<LocationMasterBloc>();
    final locationState = locationBloc.state;
    final locationName =
        locationState.locations
            .where((entry) => entry.id == locationId)
            .firstOrNull
            ?.locationDescription ??
        'Loc $locationId';
    return locationName;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Item Location Availability',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1C4292),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.filter),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
          IconButton(
            icon: const Icon(Iconsax.refresh),
            onPressed: _refreshList,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SafeArea(
        child: BlocConsumer<StockItemLocationBloc, ItemLocationsState>(
          listener: (context, state) {
            if (state.status == ItemLocationsStatus.failure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${state.message}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            return BlocBuilder<SystemConstantBloc, SystemConstantState>(
              builder: (context, systemState) {
                final systemConstant = systemState.systemConstant;
                final currencySymbol = systemConstant?.currencyCode ?? 'ETB ';
                final decimalPlaces = systemConstant?.decimalPlaces ?? 2;

                if (state.status ==
                        ItemLocationsStatus.loadingItemLocationAvailability &&
                    state.items.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildSummaryCard(state, currencySymbol, decimalPlaces),
                      const SizedBox(height: 16),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth > 600) {
                              return _buildDesktopTable(
                                state,
                                currencySymbol,
                                decimalPlaces,
                                constraints,
                              );
                            } else {
                              return _buildMobileList(
                                state,
                                currencySymbol,
                                decimalPlaces,
                              );
                            }
                          },
                        ),
                      ),
                      if (state.status ==
                          ItemLocationsStatus
                              .loadingMoreItemLocationAvailability)
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    ItemLocationsState state,
    String currencySymbol,
    int decimalPlaces,
  ) {
    final totalAmount = state.lazyItems.fold<double>(
      0,
      (sum, item) => sum + (state.locationCosts[item.id] ?? 0.0),
    );

    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryItem(
              'Total Items',
              state.lazyTotalCount.toString(),
              Iconsax.box,
              Colors.purple,
            ),
            _buildSummaryItem(
              'Page',
              '${state.lazyPage}/${state.lazyTotalPages}',
              Iconsax.document,
              Colors.blue,
            ),
            _buildSummaryItem(
              'Total Cost',
              NumberFormat.currency(
                symbol: currencySymbol,
                decimalDigits: decimalPlaces,
              ).format(totalAmount),
              Iconsax.money_send,
              Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopTable(
    ItemLocationsState state,
    String currencySymbol,
    int decimalPlaces,
    BoxConstraints constraints,
  ) {
    if (state.lazyItems.isEmpty) {
      return _buildEmptyState();
    }

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          controller: _scrollController,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(Colors.grey[50]),
              columnSpacing: 20,
              columns: const [
                DataColumn(label: Text('Branch')),
                DataColumn(label: Text('Item')),
                DataColumn(label: Text('Location')),
                DataColumn(label: Text('Avl. Qty')),
                DataColumn(label: Text('Amount Cost')),
                DataColumn(label: Text('UoM')),
              ],
              rows: state.lazyItems.map((item) {
                return DataRow(
                  cells: [
                    DataCell(Text(item.branchRef?.description ?? 'N/A')),
                    DataCell(Text(item.itemRef?.itemDescription ?? 'N/A')),
                    DataCell(
                      Text(
                        item.locationDescription?.locationDescription ?? 'N/A',
                      ),
                    ),
                    DataCell(
                      Text(
                        '${item.quantityOnHand?.toString() ?? '0'} ${item.itemRef?.unitOfMeasureDescription?.description1 ?? ""}',
                      ),
                    ),

                    DataCell(
                      Text(
                        NumberFormat.currency(
                          symbol: currencySymbol,
                          decimalDigits: decimalPlaces,
                        ).format(state.locationCosts[item.id] ?? 0.0),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileList(
    ItemLocationsState state,
    String currencySymbol,
    int decimalPlaces,
  ) {
    if (state.lazyItems.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      controller: _scrollController,
      itemCount: state.lazyItems.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = state.lazyItems[index];

        return Card(
          margin: EdgeInsets.zero,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Branch: ${item.branchRef?.description ?? "N/A"}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          NumberFormat.currency(
                            symbol: currencySymbol,
                            decimalDigits: decimalPlaces,
                          ).format(state.locationCosts[item.id] ?? 0.0),
                          style: TextStyle(
                            color: Colors.grey.computeLuminance() > 0.5
                                ? Colors.black87
                                : Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildMobileInfoRow(
                    Iconsax.box,
                    'Item',
                    item.itemRef?.itemDescription ?? 'N/A',
                  ),
                  const SizedBox(height: 8),
                  _buildMobileInfoRow(
                    Iconsax.buildings,
                    'Branch',
                    _getBranchName(item.branch!) ?? 'N/A',
                  ),
                  const SizedBox(height: 8),
                  _buildMobileInfoRow(
                    Iconsax.location,
                    'Location',
                    _getLocationName(item.location!) ?? 'N/A',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMobileStat(
                        'Avl. Qty',
                        '${item.quantityOnHand ?? "0"} ${item.itemRef?.unitOfMeasureDescription?.description1 ?? ""}',
                        Iconsax.reserve,
                        Colors.blue,
                      ),
                      _buildMobileStat(
                        'UoM',
                        item.itemRef?.unitOfMeasureDescription?.description1 ??
                            'N/A',
                        Iconsax.message_square,
                        Colors.orange,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileStat(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Text('No lot items found'));
  }
}
