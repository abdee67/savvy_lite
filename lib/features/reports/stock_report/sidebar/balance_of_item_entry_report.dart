import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/reports/stock_report/sidebar/widgets/item_filtering_dialog.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_bloc.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_event.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_state.dart';
import 'package:savvy_stock/features/stock/item_entry/models/item_entry_model.dart';
import 'package:savvy_stock/features/stock/item_entry/models/item_report_filter.model.dart';
import 'package:savvy_stock/features/stock/item_transactions/blocs/item_transaction_bloc.dart';
import 'package:savvy_stock/features/stock/item_transactions/blocs/item_transaction_event.dart';
import 'package:savvy_stock/features/stock/item_transactions/blocs/item_transaction_state.dart';

class BalanceOfItemReport extends StatefulWidget {
  final AuthBloc authBloc;
  const BalanceOfItemReport({super.key, required this.authBloc});

  @override
  State<BalanceOfItemReport> createState() => _BalanceOfItemReportState();
}

class _BalanceOfItemReportState extends State<BalanceOfItemReport>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  // Animation controllers for detail panel
  late AnimationController _detailAnimationController;
  late Animation<double> _heightAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  //  Detail panel state
  ItemEntryModel? _selectedItem;
  bool _itemDetail = false;
  bool _isFilterDialogOpen = false;

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
      if (context.read<itemBloc>().state.items.isNotEmpty) {
        _debugLotColorCalculation(
          context.read<itemBloc>().state.items.first,
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
    // Get threshold from system constants
    if (companyId != null) {
      // Load data for filters
      context.read<StockItemsEntryBloc>().add(
        LoadItemReport(
          companyId: companyId,
          page: 1,
          pageSize: 20,
          filters: ItemReportFilters(),
        ),
      );
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      final state = context.read<StockItemsEntryBloc>().state;
      if (state.hasMoreItemReport &&
          state.status != ItemEntryStatus.loadingMoreItemReport) {
        context.read<StockItemsEntryBloc>().add(LoadMoreItemReport());
      }
    }
  }

  void _showFilterDialog() async {
    if (_isFilterDialogOpen) return;
    _isFilterDialogOpen = true;

    final currentFilters = context
        .read<StockItemsEntryBloc>()
        .state
        .itemReportFilters;
    final result = await showDialog<ItemReportFilters>(
      context: context,
      builder: (context) => ItemFilterDialog(
        currentFilters: currentFilters,
        authBloc: widget.authBloc,
      ),
    );

    _isFilterDialogOpen = false;

    if (result != null) {
      context.read<StockItemsEntryBloc>().add(UpdateItemReportFilters(result));
    }
  }

  void _showItemDetail(ItemEntryModel item) {
    if (item.id != 0) {
      final dateFrom =
          context
              .read<StockItemsEntryBloc>()
              .state
              .itemReportFilters
              .dateFrom ??
          DateTime.now();
      final dateThru =
          context.read<StockItemsEntryBloc>().state.itemReportFilters.dateTo ??
          DateTime.now();
      final branchId = widget.authBloc.state.branchId ?? 0;

      context.read<ItemTransactionsBloc>().add(
        GetOpeningAmountInitial(
          itemId: item.id,
          branchId: branchId,
          dateFrom: dateFrom,
          dateThru: dateThru,
        ),
      );
      context.read<ItemTransactionsBloc>().add(
        GetPOonthisdates(
          itemId: item.id,
          branchId: branchId,
          dateFrom: dateFrom,
          dateThru: dateThru,
        ),
      );
      context.read<ItemTransactionsBloc>().add(
        GetSalesOnThisDate(
          itemId: item.id,
          branchId: branchId,
          dateFrom: dateFrom,
          dateThru: dateThru,
        ),
      );
      context.read<ItemTransactionsBloc>().add(
        GetSalesOnThisDateCOS(
          itemId: item.id,
          branchId: branchId,
          dateFrom: dateFrom,
          dateThru: dateThru,
        ),
      );
      context.read<ItemTransactionsBloc>().add(
        GetGrossProfitOnThisDate(
          itemId: item.id,
          branchId: branchId,
          dateFrom: dateFrom,
          dateThru: dateThru,
        ),
      );
      context.read<ItemTransactionsBloc>().add(
        GetAmountEnding(
          itemId: item.id,
          branchId: branchId,
          dateFrom: dateFrom,
          dateThru: dateThru,
        ),
      );
    }

    setState(() {
      _selectedItem = item;
      _itemDetail = true;
    });

    //Start the animation
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

  void _exportToExcel() {
    final state = context.read<StockItemsEntryBloc>().state;
    context.read<StockItemsEntryBloc>().add(
      ExportItemReportToExcel(state.itemReportFilters),
    );
  }

  void _exportToPDF() {
    final state = context.read<StockItemsEntryBloc>().state;
    context.read<StockItemsEntryBloc>().add(
      ExportItemReportToPDF(state.itemReportFilters),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey,
      appBar: AppBar(
        title: const Text('Balance of Stock Item Report'),
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
      body: SafeArea(
        child: BlocConsumer<StockItemsEntryBloc, ItemEntryState>(
          listener: (context, state) {
            if (state.status == ItemEntryStatus.exportReportSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message!),
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
                    if (state.itemReportFilters.hasFilters)
                      _buildActiveFiltersIndicator(state),

                    // Lot List
                    Expanded(child: _buildLotList(state)),
                  ],
                ),
                // Loading Overlay
                if (state.status == ItemEntryStatus.loadingItemReport)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard(ItemEntryState state) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSummaryItem(
                  'Total items',
                  '${state.itemReportTotalCount}',
                  Iconsax.calendar_tick,
                  Colors.orange,
                ),

                _buildSummaryItem(
                  'Page',
                  '${state.itemReportPage}/${state.itemReportTotalPages}',
                  Iconsax.document,
                  Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (state.status == ItemEntryStatus.loadingMoreItemReport)
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

  Widget _buildActiveFiltersIndicator(ItemEntryState state) {
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
              _buildFilterDescription(state.itemReportFilters),
              style: TextStyle(fontSize: 12, color: Colors.blue[800]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Iconsax.close_circle, size: 16),
            onPressed: () {
              context.read<StockItemsEntryBloc>().add(ClearItemReportFilters());
            },
          ),
        ],
      ),
    );
  }

  String _buildFilterDescription(ItemReportFilters filters) {
    final parts = <String>[];

    if (filters.dateFrom != null || filters.dateTo != null) {
      parts.add('Date Range');
    }

    return parts.isNotEmpty
        ? 'Active Filters: ${parts.join(', ')}'
        : 'No filters applied';
  }

  Widget _buildLotList(ItemEntryState state) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 700;
    final cardSpacing = screenHeight * 0.02;
    final cardWidth = isSmallScreen ? screenWidth * 0.85 : screenWidth * 0.8;

    if (state.status == ItemEntryStatus.loadingItemReport &&
        state.itemReportItems.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading Balance of Stock Item report...'),
          ],
        ),
      );
    }

    if (state.status == ItemEntryStatus.failure &&
        state.itemReportItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              state.message!.isNotEmpty
                  ? state.message!
                  : 'Failed to load Balance of Stock report',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final companyId = widget.authBloc.state.companyId;
                if (companyId != null) {
                  context.read<StockItemsEntryBloc>().add(
                    LoadItemReport(
                      companyId: companyId,
                      filters: ItemReportFilters(),
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

    if (state.itemReportItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.calendar_tick, size: 64, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              'No item report found',
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
        itemCount:
            state.itemReportItems.length +
            (state.itemReportItems.isEmpty ? 1 : 0),
        separatorBuilder: (context, index) => SizedBox(height: cardSpacing),
        itemBuilder: (context, index) {
          if (index >= state.itemReportItems.length) {
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

          final lot = state.itemReportItems[index];

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
    ItemEntryModel item,
    ItemEntryState state,
    int index,
    bool isCompact,
    double cardWidth,
    double screenHeight,
  ) {
    // final offset = _dragOffset[index] ?? 0.0;
    final isExpanded = _itemDetail == true && _selectedItem == item;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    // For responsiveness:
    final collapsedHeight = isCompact
        ? screenHeight * 0.18
        : screenHeight * 0.6;
    final expandedHeight = isCompact ? screenHeight * 0.5 : screenHeight * 0.35;

    return GestureDetector(
      onTap: () => isExpanded ? _hideItemDetail() : _showItemDetail(item),
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
                      _buildLotAvatar(item, isCompact),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item.itemDescription ?? 'N/A',
                                  style: TextStyle(
                                    color: const Color(0xFF373737),
                                    fontSize: isCompact ? 20 : 24,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (item.itemsId != null)
                              _builditemDescription(item),
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
                            ? _hideItemDetail()
                            : _showItemDetail(item),
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
                  child: _builditemDetailContent(item, isCompact),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _builditemDetailContent(ItemEntryModel item, bool isCompact) {
    return BlocBuilder<ItemTransactionsBloc, ItemTransactionsState>(
      builder: (context, state) {
        final openingAmount = state.openingAmountInitial;
        final purchaseOnThisDate = state.purchaseAmountOnDate;
        final salesAmountOnThisDate = state.salesAmountOnDate;
        final costOfSalesOnThisDate = state.salesAmountOnThisDateCOS;
        final grossProfitOnThisDay = state.grossProfitOnThisDate;
        final endingAmount = state.amountEnding;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              _buildDetailItem(
                'Item Description: ',
                item.itemDescription ?? 'N/A',
                Iconsax.box,
                isCompact,
              ),
              _buildDetailItem(
                'Item ID: ',
                item.itemsId?.toString() ?? 'N/A',
                Iconsax.location,
                isCompact,
              ),

              const Divider(),
              _buildDetailItem(
                'Opening Amount: ',
                openingAmount.toStringAsFixed(2),
                Iconsax.wallet,
                isCompact,
              ),
              _buildDetailItem(
                'Purchase Amount: ',
                purchaseOnThisDate.toStringAsFixed(2),
                Iconsax.add_circle,
                isCompact,
              ),

              _buildDetailItem(
                'Revenue Amount: ',
                salesAmountOnThisDate.toStringAsFixed(2),
                Iconsax.calculator,
                isCompact,
              ),
              _buildDetailItem(
                'Cost of Sales: ',
                costOfSalesOnThisDate.toStringAsFixed(2),
                Iconsax.money_send,
                isCompact,
              ),
              _buildDetailItem(
                'Gross Profit: ',
                grossProfitOnThisDay.toStringAsFixed(2),
                Iconsax.chart,
                isCompact,
              ),
              _buildDetailItem(
                'Ending Amount: ',
                endingAmount.toStringAsFixed(2),
                Iconsax.chart,
                isCompact,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(
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

  Widget _buildLotAvatar(ItemEntryModel item, bool isCompact) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.orange.withOpacity(0.5), width: 2),
      ),
      child: Icon(Iconsax.tag, color: Colors.orange, size: isCompact ? 20 : 24),
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

  Widget _builditemDescription(ItemEntryModel item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item.itemDescription ?? 'N/A',
            style: TextStyle(
              fontSize: 10,
              color: Colors.blue,
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
