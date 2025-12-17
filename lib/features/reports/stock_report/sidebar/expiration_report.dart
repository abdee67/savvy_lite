import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:savvy_stock/features/reports/stock_report/sidebar/widgets/expiration_filter_dialog.dart';
import 'package:savvy_stock/features/stock/lot_master/models/expiration_report_filters.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_bloc.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_event.dart';
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

class ExpirationReportPage extends StatefulWidget {
  final AuthBloc authBloc;
  const ExpirationReportPage({super.key, required this.authBloc});

  @override
  State<ExpirationReportPage> createState() => _ExpirationReportPageState();
}

class _ExpirationReportPageState extends State<ExpirationReportPage>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  // Animation controllers for detail panel
  late AnimationController _detailAnimationController;
  late Animation<double> _heightAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  //  Detail panel state
  LotMaster? _selectedLot;
  bool _lotDetail = false;
  bool _isFilterDialogOpen = false;

  final UdcRepository _udcRepository = getIt<UdcRepository>();

  @override
  void initState() {
    super.initState();

    //Initialize animation controller
    _detailAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    // Setup animations
    _setupAnimations();

    // Load initial data
    _loadInitialData();

    // Setup scroll listener for pagination
    _scrollController.addListener(_onScroll);
    /*   WidgetsBinding.instance.addPostFrameCallback((_) {
      _debugSystemConstants();
      _debugSystemConstantBloc();
      if (context.read<LotMasterBloc>().state.items.isNotEmpty) {
        _debugLotColorCalculation(
          context.read<LotMasterBloc>().state.items.first,
        );
      }
    });*/
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
    _scrollController.dispose();
    _detailAnimationController.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    final companyId = widget.authBloc.state.companyId;
    if (companyId != null) {
      // Load data for filters
      context.read<BranchBloc>().add(LoadBranchs(companyId));
      context.read<StockItemsEntryBloc>().add(LoadItems(companyId));
      context.read<LocationMasterBloc>().add(LoadLocationMasters(companyId));

      // Load initial expiration report
      context.read<LotMasterBloc>().add(
        LoadExpirationReport(
          companyId: companyId,
          filters: const ExpirationReportFilters(),
          pageSize: 20,
        ),
      );
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      final state = context.read<LotMasterBloc>().state;
      if (state.hasMoreExpirationReport &&
          state.status != LotMasterStatus.loadingMoreExpirationReport) {
        context.read<LotMasterBloc>().add(LoadMoreExpirationReport());
      }
    }
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

  void _showFilterDialog() async {
    if (_isFilterDialogOpen) return;
    _isFilterDialogOpen = true;

    final currentFilters = context
        .read<LotMasterBloc>()
        .state
        .expirationReportFilters;
    final result = await showDialog<ExpirationReportFilters>(
      context: context,
      builder: (context) => ExpirationFilterDialog(
        currentFilters: currentFilters,
        authBloc: widget.authBloc,
      ),
    );

    _isFilterDialogOpen = false;

    if (result != null) {
      context.read<LotMasterBloc>().add(UpdateExpirationReportFilters(result));
    }
  }

  void _exportToExcel() {
    final state = context.read<LotMasterBloc>().state;
    context.read<LotMasterBloc>().add(
      ExportExpirationReportToExcel(state.expirationReportFilters),
    );
  }

  void _exportToPDF() {
    final state = context.read<LotMasterBloc>().state;
    context.read<LotMasterBloc>().add(
      ExportExpirationReportToPDF(state.expirationReportFilters),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey,
      appBar: AppBar(
        title: const Text('Expiration Report'),
        backgroundColor: const Color.fromARGB(255, 28, 66, 146),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.filter),
            onPressed: _showFilterDialog,
            tooltip: 'Filter Report',
          ),
          IconButton(
            icon: const Icon(Iconsax.export),
            onPressed: _showExportMenu,
            tooltip: 'Export',
          ),
        ],
      ),
      body: BlocConsumer<LotMasterBloc, LotMasterState>(
        listener: (context, state) {
          if (state.status == LotMasterStatus.exportReportSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.exportReportMessage),
                backgroundColor: Colors.green,
              ),
            );
          }
        },

        builder: (context, state) {
          return Stack(
            children: [
              Column(
                children: [
                  // Summary Card
                  _buildSummaryCard(state),

                  // Active Filters Indicator
                  if (state.expirationReportFilters.hasFilters)
                    _buildActiveFiltersIndicator(state),

                  // Lot List
                  Expanded(child: _buildLotList(state)),
                ],
              ),
              // Loading Overlay
              if (state.status == LotMasterStatus.loadingExpirationReport)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(LotMasterState state) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem(
                  'Expired Lots',
                  '${state.expirationReportTotalCount}',
                  Iconsax.box,
                  Colors.blue,
                ),
                _buildSummaryItem(
                  'Total Value',
                  '${state.expirationReportTotalCost.toStringAsFixed(2)} Birr',
                  Iconsax.dollar_circle,
                  Colors.green,
                ),
                _buildSummaryItem(
                  'Page',
                  '${state.expirationReportPage}/${state.expirationReportTotalPages}',
                  Iconsax.document,
                  Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (state.status == LotMasterStatus.loadingMoreExpirationReport)
              LinearProgressIndicator(
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
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
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildActiveFiltersIndicator(LotMasterState state) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Row(
        children: [
          const Icon(Iconsax.filter, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _buildFilterDescription(state.expirationReportFilters),
              style: TextStyle(fontSize: 12, color: Colors.blue[800]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Iconsax.close_circle, size: 16),
            onPressed: () {
              context.read<LotMasterBloc>().add(ClearExpirationReportFilters());
            },
          ),
        ],
      ),
    );
  }

  String _buildFilterDescription(ExpirationReportFilters filters) {
    final parts = <String>[];

    if (filters.itemId != null) parts.add('Item Filtered');
    if (filters.branchId != null) parts.add('Branch Filtered');
    if (filters.locationId != null) parts.add('Location Filtered');
    if (filters.showZeroAvailability) parts.add('Including Zero Qty');
    if (filters.dateFrom != null || filters.dateTo != null)
      parts.add('Date Range');

    return parts.isNotEmpty
        ? 'Active Filters: ${parts.join(', ')}'
        : 'No filters applied';
  }

  Widget _buildLotList(LotMasterState state) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 700;
    final cardSpacing = screenHeight * 0.02;
    final cardWidth = isSmallScreen ? screenWidth * 0.85 : screenWidth * 0.8;

    if (state.status == LotMasterStatus.loadingExpirationReport &&
        state.expirationReportLots.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading expiration report...'),
          ],
        ),
      );
    }

    if (state.status == LotMasterStatus.failure &&
        state.expirationReportLots.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              state.message.isNotEmpty
                  ? state.message
                  : 'Failed to load expiration report',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final companyId = widget.authBloc.state.companyId;
                if (companyId != null) {
                  context.read<LotMasterBloc>().add(
                    LoadExpirationReport(
                      companyId: companyId,
                      filters: state.expirationReportFilters,
                    ),
                  );
                }
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.expirationReportLots.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.calendar_tick, size: 64, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              'No expiration item found',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            if (state.expirationReportFilters.hasFilters)
              TextButton(
                onPressed: () {
                  context.read<LotMasterBloc>().add(
                    ClearExpirationReportFilters(),
                  );
                },
                child: const Text(
                  'Clear Filters',
                  style: TextStyle(color: Colors.blue),
                ),
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
        itemCount:
            state.expirationReportLots.length +
            (state.expirationReportLots.isEmpty ? 1 : 0),
        separatorBuilder: (context, index) => SizedBox(height: cardSpacing),
        itemBuilder: (context, index) {
          if (index >= state.expirationReportLots.length) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.blue.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Loading more...',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            );
          }

          final lot = state.expirationReportLots[index];

          return _buildLotListItem(
            lot,
            state,
            index,
            isSmallScreen,
            cardWidth,
            screenHeight,
          );
        },
      ),
    );
  }

  Widget _buildLotListItem(
    LotMaster lot,
    LotMasterState state,
    int index,
    bool isCompact,
    double cardWidth,
    double screenHeight,
  ) {
    // final offset = _dragOffset[index] ?? 0.0;
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

    return GestureDetector(
      onTap: () => isExpanded ? _hideLotDetail() : _showLotDetail(lot),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: cardWidth,
        height: isExpanded ? expandedHeight : collapsedHeight,
        child: Stack(
          children: [
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
            // BACKGROUND LAYERS (only when expanded)
            if (isExpanded) ...[
              Positioned.fill(
                top: 47,
                child: Container(
                  width: cardWidth,
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

            // LOT CARD
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.only(top: 10, left: 10, right: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Lot Avatar
                      _buildLotAvatar(lot, isCompact),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Lot ${lot.lotNumber ?? 'N/A'}',
                                  style: TextStyle(
                                    color: const Color(0xFF373737),
                                    fontSize: isCompact ? 20 : 24,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                _buildStatusBadge(lot),
                              ],
                            ),
                            // Date information
                            const SizedBox(height: 2),
                            if (lot.dateExpiration != null)
                              _buildExpirationWarning(lot.dateExpiration!),
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
                        onPressed: () =>
                            isExpanded ? _hideLotDetail() : _showLotDetail(lot),
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
    );
  }

  Widget _buildLotDetailContent(LotMaster lot, bool isCompact) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildDetailItem(
            'Batch Number: ',
            lot.batchNumberSupplier ?? 'N/A',
            Iconsax.barcode,
            isCompact,
          ),
          _buildDetailItem(
            'Item ID: ',
            lot.itemRef?.itemsId ?? 'N/A',
            Iconsax.tag,
            isCompact,
          ),
          _buildDetailItem(
            'Item Description: ',
            lot.itemRef?.itemDescription ?? 'N/A',
            Iconsax.box,
            isCompact,
          ),
          _buildDetailItem(
            'Branch/Store: ',
            lot.branchRef?.description ?? 'N/A',
            Iconsax.building,
            isCompact,
          ),
          _buildDetailItem(
            'Location: ',
            lot.locationRef?.locationDescription ?? 'N/A',
            Iconsax.location,
            isCompact,
          ),
          _buildDetailItem(
            'Unit Price: ',
            lot.unitPrice != null
                ? '${lot.unitPrice!.toStringAsFixed(2)} Birr'
                : 'N/A',
            Iconsax.dollar_circle,
            isCompact,
          ),
          _buildDetailItem(
            'Unit of Measure: ',
            lot.itemRef?.unitOfMeasureDescription?.description1 ?? 'N/A',
            Iconsax.dollar_circle,
            isCompact,
          ),
          _buildDetailItem(
            'Expiration Date: ',
            lot.dateExpiration != null
                ? _formatDate(lot.dateExpiration!)
                : 'N/A',
            Iconsax.calendar_tick,
            isCompact,
          ),
          _buildDetailItem(
            'Available Quantity: ',
            lot.quantityAvailable != null
                ? '${lot.quantityAvailable} ${lot.itemRef?.unitOfMeasureDescription?.description1}'
                : 'N/A',
            Iconsax.dollar_circle,
            isCompact,
          ),
          _buildDetailItem(
            'Status: ',
            lot.statusDescription ?? 'N/A',
            Iconsax.activity,
            isCompact,
          ),

          // Total Cost
          FutureBuilder<double>(
            future: context
                .read<LotMasterBloc>()
                .repository
                .calculateLotTotalCost(lot),
            builder: (context, snapshot) {
              return _buildDetailItem(
                'Total Cost: ',
                snapshot.hasData
                    ? '${snapshot.data!.toStringAsFixed(2)} Birr'
                    : 'Calculating...',
                Iconsax.dollar_square,
                isCompact,
                valueColor: Colors.green,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(
    String label,
    String value,
    IconData icon,
    bool isCompact, {
    Color valueColor = Colors.blue,
  }) {
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

  Widget _buildLotAvatar(LotMaster lot, bool isCompact) {
    final isExpired = lot.statusCode?.toUpperCase() == 'E';

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isExpired
            ? Colors.red.withOpacity(0.2)
            : Colors.orange.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(
          color: isExpired
              ? Colors.red.withOpacity(0.5)
              : Colors.orange.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Icon(
        isExpired ? Iconsax.danger : Iconsax.warning_2,
        color: isExpired ? Colors.red : Colors.orange,
        size: isCompact ? 20 : 24,
      ),
    );
  }

  void _showExportMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Export Report',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Iconsax.document_text, color: Colors.green),
                ),
                title: const Text('Export to Excel'),
                subtitle: const Text('Export as .xlsx file'),
                onTap: () {
                  Navigator.pop(context);
                  _exportToExcel();
                },
              ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Iconsax.document_download, color: Colors.red),
                ),
                title: const Text('Export to PDF'),
                subtitle: const Text('Export as .pdf file'),
                onTap: () {
                  Navigator.pop(context);
                  _exportToPDF();
                },
              ),
              const Divider(),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(LotMaster lot) {
    Color badgeColor;
    String statusText;

    switch (lot.statusCode?.toUpperCase()) {
      case 'E':
        badgeColor = Colors.red;
        statusText = 'EXPIRED';
        break;
      case 'A':
        badgeColor = Colors.green;
        statusText = 'ACTIVE';
        break;
      default:
        badgeColor = Colors.grey;
        statusText = 'UNKNOWN';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 12, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 10,
              color: badgeColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpirationWarning(DateTime expirationDate) {
    final now = DateTime.now();
    final daysUntilExpiry = expirationDate.difference(now).inDays;

    Color color;
    String text;

    if (daysUntilExpiry < 0) {
      color = Colors.red;
      text = 'EXPIRED ${(daysUntilExpiry * -1)} days ago';
    } else if (daysUntilExpiry <= 7) {
      color = Colors.orange;
      text = 'Expires in $daysUntilExpiry days';
    } else {
      color = Colors.blue;
      text = 'Expires: ${_formatDate(expirationDate)}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Iconsax.calendar_tick, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
