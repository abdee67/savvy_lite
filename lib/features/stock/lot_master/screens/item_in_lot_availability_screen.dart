import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/branch_list/blocs/branch_list_bloc.dart';
import 'package:savvy_stock/features/branch_list/blocs/branch_list_event.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_bloc.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_event.dart';
import 'package:savvy_stock/features/stock/location_entry/blocs/location_master_bloc.dart';
import 'package:savvy_stock/features/stock/location_entry/blocs/location_master_event.dart';
import 'package:savvy_stock/features/stock/lot_master/blocs/lot_master_bloc.dart';
import 'package:savvy_stock/features/stock/lot_master/blocs/lot_master_event.dart';
import 'package:savvy_stock/features/stock/lot_master/blocs/lot_master_state.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_bloc.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_state.dart';
import 'package:savvy_stock/features/stock/lot_coloring/model/lot_coloring_model.dart';
import 'package:savvy_stock/features/stock/lot_master/widgets/item_in_lot_availability_filter.dart';

class LotAvailabilityScreen extends StatefulWidget {
  final AuthBloc authBloc;
  const LotAvailabilityScreen({super.key, required this.authBloc});

  @override
  State<LotAvailabilityScreen> createState() => _LotAvailabilityScreenState();
}

class _LotAvailabilityScreenState extends State<LotAvailabilityScreen> {
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
      context.read<LotMasterBloc>().add(
        LoadLotAvailability(
          companyId: widget.authBloc.state.companyId!,
          page: 1,
          pageSize: 20,
        ),
      );
      context.read<LotMasterBloc>().add(CalculateMultipleLotStatus());
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
      final state = context.read<LotMasterBloc>().state;
      if (state.hasMoreAvailability &&
          state.status != LotMasterStatus.loadingLotAvailability) {
        context.read<LotMasterBloc>().add(LoadMoreLotAvailability());
      }
    }
  }

  void _showFilterDialog() {
    final currentState = context.read<LotMasterBloc>().state;
    showDialog(
      context: context,
      builder: (context) {
        return AvailableLotFilterDialog(
          currentFilters: currentState.availabilityFilters,
          onApply: (filters) {
            context.read<LotMasterBloc>().add(FilterLotAvailability(filters));
          },
          onClear: () {
            context.read<LotMasterBloc>().add(ClearLotAvailabilityFilters());
          },
        );
      },
    );
  }

  void _refreshList(bool isRefresh) {
    final companyId = widget.authBloc.state.companyId;
    if (companyId != null) {
      context.read<LotMasterBloc>().add(
        LoadLotAvailability(companyId: companyId, page: 1, pageSize: 20),
      );
    }
    if (isRefresh) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('List Refreshed'),
          backgroundColor: Color(0xFF1C4292),
          behavior: SnackBarBehavior.floating,
          dismissDirection: DismissDirection.down,
          clipBehavior: Clip.antiAliasWithSaveLayer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(50)),
          ),
        ),
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
          'Lot Availability',
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
            onPressed: () => _refreshList(true),
            tooltip: 'Refresh',
          ),
        ],
      ), //pull down to refresh
      //pull down to refresh
      body: SafeArea(
        child: BlocConsumer<LotMasterBloc, LotMasterState>(
          listener: (context, state) {
            if (state.status == LotMasterStatus.failure) {
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
                final systemConstant = systemState.systemConstants.isNotEmpty
                    ? systemState.systemConstants.first
                    : null;
                final currencySymbol = systemConstant?.currencyCode ?? 'ETB ';
                final decimalPlaces = systemConstant?.decimalPlaces ?? 2;

                if (state.status == LotMasterStatus.loadingLotAvailability &&
                    state.availabilityLots.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildSummaryCard(state, currencySymbol, decimalPlaces),
                      const SizedBox(height: 16),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: () async => _refreshList(true),
                          backgroundColor: Color(0xFF1C4292),
                          color: Colors.amber,
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
                      ),
                      if (state.status ==
                          LotMasterStatus.loadingMoreLotAvailability)
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
    LotMasterState state,
    String currencySymbol,
    int decimalPlaces,
  ) {
    final totalAmount = state.availabilityLots.fold<double>(
      0,
      (sum, item) =>
          sum + ((item.unitPrice ?? 0) * (item.quantityAvailable ?? 0)),
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
              state.availabilityTotalCount.toString(),
              Iconsax.box,
              Colors.purple,
            ),
            _buildSummaryItem(
              'Page',
              '${state.availabilityPage}/${state.availabilityTotalPages}',
              Iconsax.document,
              Colors.blue,
            ),
            _buildSummaryItem(
              'Value',
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
    LotMasterState state,
    String currencySymbol,
    int decimalPlaces,
    BoxConstraints constraints,
  ) {
    if (state.availabilityLots.isEmpty) {
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
                DataColumn(label: Text('Lot')),
                DataColumn(label: Text('Branch')),
                DataColumn(label: Text('Item')),
                DataColumn(label: Text('Loc')),
                DataColumn(label: Text('Qty')),
                DataColumn(label: Text('Recei')),
                DataColumn(label: Text('Effe')),
                DataColumn(label: Text('Expiry')),
                DataColumn(label: Text('Batch')),
                DataColumn(label: Text('Status')),
              ],
              rows: state.availabilityLots.map((item) {
                final bgColor = _getColorFromType(item.tempColorType);
                return DataRow(
                  color: WidgetStateProperty.all(bgColor.withOpacity(0.1)),
                  cells: [
                    DataCell(Text(item.lotNumber?.toString() ?? 'N/A')),
                    DataCell(Text(_getBranchName(item.branch!) ?? 'N/A')),
                    DataCell(Text(item.itemRef?.itemDescription ?? 'N/A')),
                    DataCell(Text(_getLocationName(item.location!) ?? 'N/A')),
                    DataCell(
                      Text(
                        '${item.quantityAvailable?.toString() ?? '0'} ${item.itemRef?.unitOfMeasureDescription?.description1 ?? ""}',
                      ),
                    ),
                    DataCell(
                      Text(
                        item.dateReceived != null
                            ? _dateFormat.format(item.dateReceived!)
                            : 'N/A',
                      ),
                    ),
                    DataCell(
                      Text(
                        item.dateEffective != null
                            ? _dateFormat.format(item.dateEffective!)
                            : 'N/A',
                      ),
                    ),
                    DataCell(
                      Text(
                        item.dateExpiration != null
                            ? _dateFormat.format(item.dateExpiration!)
                            : 'N/A',
                      ),
                    ),

                    DataCell(Text(item.batchNumberSupplier ?? 'N/A')),
                    DataCell(Text(item.statusDescription ?? 'N/A')),
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
    LotMasterState state,
    String currencySymbol,
    int decimalPlaces,
  ) {
    if (state.availabilityLots.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      controller: _scrollController,
      itemCount: state.availabilityLots.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = state.availabilityLots[index];
        final bgColor = _getColorFromType(item.tempColorType);

        return Card(
          margin: EdgeInsets.zero,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: bgColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: bgColor.withOpacity(0.2), width: 1),
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
                          'Lot: ${item.lotNumber ?? "N/A"}',
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
                          color: bgColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          item.statusDescription ?? 'N/A',
                          style: TextStyle(
                            color: bgColor.computeLuminance() > 0.5
                                ? Colors.black87
                                : bgColor,
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
                  const SizedBox(height: 8),
                  _buildMobileInfoRow(
                    Iconsax.reserve,
                    'Avl. Qty',
                    '${item.quantityAvailable ?? "0"} ${item.itemRef?.unitOfMeasureDescription?.description1 ?? ""}',
                  ),

                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (item.dateEffective != null)
                        _buildMobileStat(
                          'Effective',
                          _dateFormat.format(item.dateEffective!),
                          Iconsax.calendar_1,
                          Colors.green,
                        ),

                      if (item.dateReceived != null)
                        _buildMobileStat(
                          'Received',
                          _dateFormat.format(item.dateReceived!),
                          Iconsax.calendar_1,
                          Colors.amber,
                        ),
                      if (item.dateExpiration != null)
                        _buildMobileStat(
                          'Expiry',
                          _dateFormat.format(item.dateExpiration!),
                          Iconsax.calendar_remove,
                          Colors.red,
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

  Color _getColorFromType(LotExpirationColor? color) {
    if (color == null) return Colors.grey.shade300;
    final code = (color.colorTypeCode ?? '').trim().toUpperCase();
    final name = (color.colorTypeName ?? '').trim().toLowerCase();
    switch (code) {
      case '01':
        return Colors.red;
      case '11':
        return Colors.blue;
      case '04':
        return Colors.green;
      case '16':
        return Colors.black;
      case '07':
        return Colors.yellow;
      case '02':
        return Colors.orange;
      case '03':
        return Colors.grey;
      case '06':
        return const Color.fromARGB(255, 14, 90, 4);
      case '08':
        return Colors.purple;
      case '05':
        return Colors.lime;
      default:
        if (name.contains('red')) return Colors.red;
        if (name.contains('blue')) return Colors.blue;
        if (name.contains('green')) return Colors.green;
        if (name.contains('yellow')) return Colors.yellow;
        if (name.contains('orange')) return Colors.orange;
        if (name.contains('black')) return Colors.black;
        return Colors.grey.shade300;
    }
  }

  Widget _buildEmptyState() {
    return const Center(child: Text('No lot items found'));
  }
}
