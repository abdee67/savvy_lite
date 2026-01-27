import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/bloc/purchase_order_bloc.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/bloc/purchase_order_event.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/bloc/purchase_order_state.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/models/purchase_order_detail_model.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/models/purchase_report_filter_model.dart';
import 'package:savvy_stock/features/reports/purchase_report/sidebar/widgets/pending_purchase_filter_dialog.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_bloc.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_state.dart';
import 'package:savvy_stock/features/system_constant/models/system_constant.dart';

class PendingPurchaseReportPage extends StatefulWidget {
  final AuthBloc authBloc;
  const PendingPurchaseReportPage({super.key, required this.authBloc});

  @override
  State<PendingPurchaseReportPage> createState() =>
      _PendingPurchaseReportPageState();
}

class _PendingPurchaseReportPageState extends State<PendingPurchaseReportPage>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '');

  // Animation controllers
  late AnimationController _detailAnimationController;
  late Animation<double> _heightAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  // Detail panel state
  PurchaseOrderDetail? _selectedItem;
  bool _isDetailExpanded = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
  }

  void _setupAnimations() {
    _detailAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

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
      context.read<PurchaseOrderBloc>().add(
        LoadPendingPurchaseReport(
          companyId: companyId,
          filters: PurchaseReportFilters(),
          pageSize: 20,
        ),
      );
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final state = context.read<PurchaseOrderBloc>().state;
      if (state.hasMorePendingPurchase &&
          state.status !=
              PurchaseOrderStatus.loadingMorePendingPurchaseReport) {
        context.read<PurchaseOrderBloc>().add(
          const LoadMorePendingPurchaseReport(),
        );
      }
    }
  }

  void _showItemDetail(dynamic item) {
    setState(() {
      _selectedItem = item;
      _isDetailExpanded = true;
    });
    _detailAnimationController.forward(from: 0.0);
  }

  void _hideItemDetail() {
    _detailAnimationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _isDetailExpanded = false;
          _selectedItem = null;
        });
      }
    });
  }

  void _showFilterDialog() async {
    final currentFilters = context
        .read<PurchaseOrderBloc>()
        .state
        .pendingPurchaseFilters;
    final result = await showDialog<PurchaseReportFilters>(
      context: context,
      builder: (context) => PendingPurchaseFilterDialog(
        currentFilters: currentFilters,
        authBloc: widget.authBloc,
      ),
    );

    if (result != null) {
      context.read<PurchaseOrderBloc>().add(
        UpdatePendingPurchaseReportFilters(result),
      );
    }
  }

  void _exportToExcel() {
    final state = context.read<PurchaseOrderBloc>().state;
    context.read<PurchaseOrderBloc>().add(
      ExportPendingPurchaseReportToExcel(state.pendingPurchaseFilters),
    );
  }

  void _exportToPDF() {
    final state = context.read<PurchaseOrderBloc>().state;
    context.read<PurchaseOrderBloc>().add(
      ExportPendingPurchaseReportToPDF(state.pendingPurchaseFilters),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.grey, // Updated background color to match ExpirationReport
      appBar: AppBar(
        title: const Text('Pending Purchase Report'),
        backgroundColor: const Color(0xFF1C4292),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.filter),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Iconsax.export),
            tooltip: 'Export',
            onSelected: (value) {
              if (value == 'excel') _exportToExcel();
              if (value == 'pdf') _exportToPDF();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'excel',
                child: Row(
                  children: [
                    Icon(Iconsax.document_text, size: 18),
                    SizedBox(width: 8),
                    Text('Export to Excel'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Iconsax.document_code, size: 18),
                    SizedBox(width: 8),
                    Text('Export to PDF'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: MultiBlocListener(
          listeners: [
            BlocListener<PurchaseOrderBloc, PurchaseOrderState>(
              listener: (context, state) {
                if (state.status == PurchaseOrderStatus.error &&
                    state.error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.error!),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                if (state.exportPendingPurchaseMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.exportPendingPurchaseMessage!),
                    ),
                  );
                }
              },
            ),
          ],
          child: BlocBuilder<SystemConstantBloc, SystemConstantState>(
            builder: (context, systemState) {
              final systemConstant = systemState.systemConstants.isNotEmpty
                  ? systemState.systemConstants.first
                  : null;

              return BlocBuilder<PurchaseOrderBloc, PurchaseOrderState>(
                builder: (context, state) {
                  return Stack(
                    children: [
                      Column(
                        children: [
                          // Summary Cards
                          _buildSummaryCards(state, systemConstant),

                          // Active Filters Indicator
                          if (state.pendingPurchaseFilters.hasFilters)
                            _buildActiveFiltersIndicator(state),

                          // List Header
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Items: ${state.pendingPurchaseTotalCount}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors
                                        .white, // Changed to white as per bg
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Transaction List
                          Expanded(
                            child: _buildTransactionList(state, systemConstant),
                          ),
                        ],
                      ),

                      // Loading Overlay
                      if (state.status ==
                          PurchaseOrderStatus.loadingPendingPurchaseReport)
                        Container(
                          color: Colors.black.withOpacity(0.5),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionList(
    PurchaseOrderState state,
    SystemConstant? systemConstant,
  ) {
    if (state.status == PurchaseOrderStatus.loadingPendingPurchaseReport &&
        state.pendingPurchaseReports.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final items = state.pendingPurchaseReports;

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 700;
    final cardSpacing = screenHeight * 0.02;
    final cardWidth = isSmallScreen ? screenWidth * 0.85 : screenWidth * 0.8;

    if (items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.receipt_2, size: 64, color: Colors.white),
            SizedBox(height: 16),
            Text(
              'No Pending Purchase found',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: items.length + (state.hasMorePendingPurchase ? 1 : 0),
      separatorBuilder: (context, index) => SizedBox(height: cardSpacing),
      itemBuilder: (context, index) {
        if (index >= items.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          );
        }

        final item = items[index];
        return _buildTransactionListItem(
          item,
          index,
          isSmallScreen,
          cardWidth,
          screenHeight,
          systemConstant,
        );
      },
    );
  }

  Widget _buildTransactionListItem(
    PurchaseOrderDetail item,
    int index,
    bool isCompact,
    double cardWidth,
    double screenHeight,
    SystemConstant? systemConstant,
  ) {
    final isExpanded = _isDetailExpanded && _selectedItem == item;

    // For responsiveness:
    final collapsedHeight = isCompact
        ? screenHeight * 0.16
        : screenHeight *
              0.12; // Slightly taller than Expiration report due to more info
    final expandedHeight = isCompact
        ? screenHeight * 0.65
        : screenHeight * 0.55;

    return GestureDetector(
      onTap: () => isExpanded ? _hideItemDetail() : _showItemDetail(item),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: cardWidth,
        height: isExpanded ? expandedHeight : collapsedHeight,
        child: Stack(
          children: [
            // BACKGROUND LAYERS (only when expanded)
            if (isExpanded)
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

            // CARD CONTENT
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
                      // Avatar
                      _buildAvatar(item),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item
                                            .poHeaderRef
                                            ?.supplierRef
                                            ?.supplierName ??
                                        'N/A',
                                    style: TextStyle(
                                      color: const Color(0xFF373737),
                                      fontSize: isCompact ? 18 : 22,
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w800,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                _buildStatusBadge(item),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Order ${item.poHeaderRef?.orderNumber ?? 'N/A'}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Bottom Row with See More button
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

            // ANIMATED EXPANDED CONTENT
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
                        decoration: const BoxDecoration(
                          color: Colors.transparent,
                        ),
                        child: Opacity(opacity: currentOpacity, child: child),
                      ),
                    );
                  },
                  child: _buildHeaderViewContent(item, isCompact),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(PurchaseOrderDetail item) {
    IconData icon;
    Color color;

    final paymentType = item.poHeaderRef?.paymentTerm;
    if (paymentType != null) {
      icon = Iconsax.card_edit;
      color = Colors.orange;
    } else {
      icon = Iconsax.money;
      color = Colors.green;
    }

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }

  Widget _buildStatusBadge(PurchaseOrderDetail item) {
    final purchaseType = item.poHeaderRef?.paymentTerm;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (purchaseType != null ? Colors.orange : Colors.green)
            .withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (purchaseType != null ? Colors.orange : Colors.green)
              .withOpacity(0.3),
        ),
      ),
      child: Text(
        purchaseType != null ? 'Credit' : 'Cash',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: purchaseType != null ? Colors.orange : Colors.green,
        ),
      ),
    );
  }

  Widget _buildHeaderViewContent(PurchaseOrderDetail detail, bool isCompact) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildDetailRow(
            'Supplier',
            detail.poHeaderRef?.supplierRef?.supplierName ?? 'N/A',
            Iconsax.calendar,
          ),
          _buildDetailRow(
            'Item',
            detail.itemNumberRef?.itemDescription ?? 'N/A',
            Iconsax.box,
          ),
          _buildDetailRow(
            'Transaction Date',
            _dateFormat.format(
              detail.poHeaderRef?.dateTransaction ?? DateTime.now(),
            ),
            Iconsax.calendar,
          ),

          _buildDetailRow(
            'Transaction Ref ',
            '${detail.poHeaderRef?.paymentTerm != null ? "CO-" : "PO-"} ${detail.poHeaderRef?.orderNumber}',
            Iconsax.card,
          ),
          _buildDetailRow(
            'Invoice No',
            detail.poHeaderRef?.invoiceNumber ?? 'N/A',
            Iconsax.card,
          ),
          _buildDetailRow(
            'UOM',
            detail.unitOfMeasureRef?.description1 ?? 'N/A',
            Iconsax.uniEB15,
          ),
          _buildDetailRow(
            'Quantity Ordered',
            detail.quantityTransaction?.toString() ?? 'N/A',
            Iconsax.chart_2,
            valueColor: const Color(0xFF1C4292),
          ),
          _buildDetailRow(
            'Quantity Received',
            detail.quantityRecieved?.toString() ?? 'N/A',
            Iconsax.chart_2,
            isBold: true,
            valueColor: const Color(0xFF1C4292),
          ),
          _buildDetailRow(
            'Quantity Remaining',
            detail.quantityOpen?.toString() ?? 'N/A',
            Iconsax.chart_2,
            isBold: true,
            valueColor: const Color(0xFF1C4292),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
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
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              textAlign: TextAlign.justify,
              TextSpan(
                children: [
                  TextSpan(
                    text: '$label: ',
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

  Widget _buildSummaryCards(
    PurchaseOrderState state,
    SystemConstant? systemConstant,
  ) {
    final totals = state.pendingPurchaseTotals;
    if (totals == null) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Total Received Quantity',
                    totals.totalReceivedQuantity.toString(),
                    Iconsax.money_send,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Total Remaing Quantity',
                    totals.totalRemainigQuantity.toString(),
                    Iconsax.document_text,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Divider(),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Total Ordered Quantity',
                    totals.totalTransactionQunatity.toString(),
                    Iconsax.document_text,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Page',
                    '${state.pendingPurchasePage}/${state.pendingPurchaseTotalPages}',
                    Iconsax.document,
                    Colors.blue,
                  ),
                ),
              ],
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
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
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

  Widget _buildActiveFiltersIndicator(PurchaseOrderState state) {
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
              _buildFilterDescription(state.pendingPurchaseFilters),
              style: TextStyle(fontSize: 12, color: Colors.blue[800]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Iconsax.close_circle, size: 16),
            onPressed: () {
              context.read<PurchaseOrderBloc>().add(
                const ClearPendingPurchaseReportFilters(),
              );
            },
          ),
        ],
      ),
    );
  }

  String _buildFilterDescription(PurchaseReportFilters filters) {
    final parts = <String>[];
    if (filters.dateFrom != null) parts.add('Start Range');
    if (filters.dateTo != null) parts.add('End Range');
    if (filters.itemId != null) parts.add('Selected item: ${filters.itemId}');
    if (filters.supplierId != null) {
      parts.add('Selected supplier: ${filters.supplierId}');
    }

    return parts.isNotEmpty ? 'Active: ${parts.join(', ')}' : 'No filters';
  }
}
