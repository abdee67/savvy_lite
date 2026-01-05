import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/reports/sales_report/sidebar/widgets/credit_receipt_filter_dialog.dart';
import 'package:savvy_stock/features/sales/sales_order/header/bloc/sales_order_header_bloc.dart';
import 'package:savvy_stock/features/sales/sales_order/header/bloc/sales_order_header_event.dart';
import 'package:savvy_stock/features/sales/sales_order/header/bloc/sales_order_header_state.dart';
import 'package:savvy_stock/features/sales/sales_order/header/model/credit_receipt_model.dart';
import 'package:savvy_stock/features/sales/sales_order/header/model/sales_transaction_filtering_model.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_bloc.dart';

class CreditReceivedReport extends StatefulWidget {
  final AuthBloc authBloc;
  const CreditReceivedReport({super.key, required this.authBloc});

  @override
  State<CreditReceivedReport> createState() => _CreditReceivedReportState();
}

class _CreditReceivedReportState extends State<CreditReceivedReport>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  // Animation controllers for detail panel
  late AnimationController _detailAnimationController;
  late Animation<double> _heightAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  //  Detail panel state
  CreditReceipt? _selectedItem;
  bool _itemDetail = false;
  bool _isFilterDialogOpen = false;
  late final int decimalPlace = context
      .read<SystemConstantBloc>()
      .state
      .systemConstants
      .first
      .decimalPlaces!;

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
      context.read<SalesOrderHeaderBloc>().add(
        LoadCreditReceiptsReport(
          companyId: companyId,
          page: 1,
          pageSize: 20,
          filters: SalesTransactionReportFilters(),
        ),
      );
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      final state = context.read<SalesOrderHeaderBloc>().state;
      if (state.hasMoreCreditReceiptReport &&
          state.status !=
              SalesOrderHeaderStatus.loadingMoreCreditReceiptReport) {
        context.read<SalesOrderHeaderBloc>().add(
          LoadMoreCreditReceiptsReport(),
        );
      }
    }
  }

  void _showFilterDialog() async {
    if (_isFilterDialogOpen) return;
    _isFilterDialogOpen = true;

    final currentFilters = context
        .read<SalesOrderHeaderBloc>()
        .state
        .creditReceiptReportFilters;
    final result = await showDialog<SalesTransactionReportFilters>(
      context: context,
      builder: (context) => CreditReceiptFilterDialog(
        currentFilters: currentFilters,
        authBloc: widget.authBloc,
      ),
    );

    _isFilterDialogOpen = false;

    if (result != null) {
      context.read<SalesOrderHeaderBloc>().add(
        UpdateCreditReceiptReportFilters(result),
      );
    }
  }

  void _showItemDetail(CreditReceipt item) {
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
    final state = context.read<SalesOrderHeaderBloc>().state;
    context.read<SalesOrderHeaderBloc>().add(
      ExportCreditReceiptReportToExcel(state.creditReceiptReportFilters),
    );
  }

  void _exportToPDF() {
    final state = context.read<SalesOrderHeaderBloc>().state;
    context.read<SalesOrderHeaderBloc>().add(
      ExportCreditReceiptReportToPDF(state.creditReceiptReportFilters),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey,
      appBar: AppBar(
        title: const Text('Credit Received Report'),
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
      body: BlocConsumer<SalesOrderHeaderBloc, SalesOrderHeaderState>(
        listener: (context, state) {
          if (state.status ==
              SalesOrderHeaderStatus.exportCreditReceiptReportSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successmessage!),
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
                  if (state.creditReceiptReportFilters.hasFilters)
                    _buildActiveFiltersIndicator(state),

                  // Lot List
                  Expanded(child: _buildLotList(state)),
                ],
              ),
              // Loading Overlay
              if (state.status ==
                  SalesOrderHeaderStatus.loadingCreditReceiptReport)
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

  Widget _buildSummaryCard(SalesOrderHeaderState state) {
    final totalAmount = state.creditReceiptsReport.fold<double>(
      0.0,
      (previousValue, element) =>
          previousValue + (element.receiptAmount ?? 0.0),
    );

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
                  '${state.creditReceiptsReport.length}',
                  Iconsax.calendar_tick,
                  Colors.orange,
                ),
                _buildSummaryItem(
                  'Total Receipt Amount',
                  NumberFormat.currency(
                    decimalDigits: decimalPlace,
                    symbol: 'ETB ',
                  ).format(totalAmount),
                  Iconsax.trontron_trx,
                  Colors.orange,
                ),

                _buildSummaryItem(
                  'Page',
                  '${state.creditReceiptReportPage}/${state.creditReceiptReportTotalPages}',
                  Iconsax.document,
                  Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (state.status ==
                SalesOrderHeaderStatus.loadingMoreCreditReceiptReport)
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

  Widget _buildActiveFiltersIndicator(SalesOrderHeaderState state) {
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
              _buildFilterDescription(state.creditReceiptReportFilters),
              style: TextStyle(fontSize: 12, color: Colors.blue[800]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Iconsax.close_circle, size: 16),
            onPressed: () {
              context.read<SalesOrderHeaderBloc>().add(
                ClearCreditReceiptsReportFilters(),
              );
            },
          ),
        ],
      ),
    );
  }

  String _buildFilterDescription(SalesTransactionReportFilters filters) {
    final parts = <String>[];

    if (filters.customerId != null) {
      parts.add('Customer: ${filters.customerId}');
    }

    if (filters.fsNumber != null && filters.fsNumber!.isNotEmpty) {
      parts.add('FS Number: ${filters.fsNumber}');
    }

    return parts.isNotEmpty
        ? 'Active Filters: ${parts.join(', ')}'
        : 'No filters applied';
  }

  Widget _buildLotList(SalesOrderHeaderState state) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 700;
    final cardSpacing = screenHeight * 0.02;
    final cardWidth = isSmallScreen ? screenWidth * 0.85 : screenWidth * 0.8;

    if (state.status == SalesOrderHeaderStatus.loadingCreditReceiptReport &&
        state.creditReceiptsReport.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading Item Transaction report...'),
          ],
        ),
      );
    }

    if (state.status == SalesOrderHeaderStatus.failure &&
        state.creditReceiptsReport.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              state.error!.isNotEmpty
                  ? state.error!
                  : 'Failed to load item Transaction report',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final companyId = widget.authBloc.state.companyId;
                if (companyId != null) {
                  context.read<SalesOrderHeaderBloc>().add(
                    LoadCreditReceiptsReport(
                      companyId: companyId,
                      filters: SalesTransactionReportFilters(),
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

    if (state.creditReceiptsReport.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.calendar_tick, size: 64, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              'No credit receipt report found',
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
            state.creditReceiptsReport.length +
            (state.creditReceiptsReport.isEmpty ? 1 : 0),
        separatorBuilder: (context, index) => SizedBox(height: cardSpacing),
        itemBuilder: (context, index) {
          if (index >= state.creditReceiptsReport.length) {
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

          final lot = state.creditReceiptsReport[index];

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
    CreditReceipt item,
    SalesOrderHeaderState state,
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
        ? screenHeight * 0.14
        : screenHeight * 0.6;
    final expandedHeight = isCompact ? screenHeight * 0.4 : screenHeight * 0.35;

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
                                  item
                                          .soHeaderRef
                                          ?.customerBillToRef
                                          ?.customerName ??
                                      'N/A',
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
                            if (item.soHeaderRef?.orderTypeRef?.description1 !=
                                null)
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

  Widget _builditemDetailContent(CreditReceipt item, bool isCompact) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildDetailItem(
            'Customer: ',
            item.soHeaderRef?.customerBillToRef?.customerName ?? 'N/A',
            Iconsax.user,
            isCompact,
          ),
          _buildDetailItem(
            'Order date: ',
            _formatDate(item.soHeaderRef?.orderDate ?? DateTime.now()),
            Iconsax.calendar,
            isCompact,
          ),
          _buildDetailItem(
            'Transaction Ref: ',
            'FS - ${item.soHeaderRef?.fsNumber ?? 'N/A'}',
            Iconsax.document,
            isCompact,
          ),
          _buildDetailItem(
            'Sales Amount: ',
            item.soHeaderRef?.amountTotal.toString() ?? 'N/A',
            Iconsax.wallet,
            isCompact,
          ),
          _buildDetailItem(
            'Paid Amount: ',
            item.receiptAmount?.toString() ?? 'N/A',
            Iconsax.wallet,
            isCompact,
          ),
          _buildDetailItem(
            'Remaining Amount: ',
            NumberFormat.currency(
                  decimalDigits: decimalPlace,
                  symbol: 'ETB ',
                ).format(item.remainingValues) ??
                'N/A',
            Iconsax.wallet,
            isCompact,
          ),
          _buildDetailItem(
            'Paid Date: ',
            _formatDate(item.dateReceipt!),
            Iconsax.calendar,
            isCompact,
          ),
        ],
      ),
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

  Widget _buildLotAvatar(CreditReceipt item, bool isCompact) {
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

  Widget _builditemDescription(CreditReceipt item) {
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
            item.soHeaderRef?.orderTypeRef?.description1 ?? 'N/A',
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
