import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/sales/sales_order/detail/model/sales_order_detail.dart';
import 'package:savvy_stock/features/sales/sales_order/header/bloc/sales_order_header_bloc.dart';
import 'package:savvy_stock/features/sales/sales_order/header/bloc/sales_order_header_event.dart';
import 'package:savvy_stock/features/sales/sales_order/header/bloc/sales_order_header_state.dart';
import 'package:savvy_stock/features/sales/sales_order/header/model/sales_order_header.dart';
import 'package:savvy_stock/features/sales/sales_order/header/model/sales_transaction_filtering_model.dart';
import 'package:savvy_stock/features/reports/sales_report/sidebar/widgets/sales_transaction_filter_dialog.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_bloc.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_state.dart';
import 'package:savvy_stock/features/system_constant/models/system_constant.dart';

class SalesTransactionReportPage extends StatefulWidget {
  final AuthBloc authBloc;
  const SalesTransactionReportPage({super.key, required this.authBloc});

  @override
  State<SalesTransactionReportPage> createState() =>
      _SalesTransactionReportPageState();
}

class _SalesTransactionReportPageState extends State<SalesTransactionReportPage>
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
  dynamic _selectedItem; // Can be SalesOrderHeader or SalesOrderDetail
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
      context.read<SalesOrderHeaderBloc>().add(
        LoadSalesTransactionReport(
          companyId: companyId,
          filters: SalesTransactionReportFilters(),
          pageSize: 20,
        ),
      );
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final state = context.read<SalesOrderHeaderBloc>().state;
      if (state.hasMoreSalesTransaction &&
          state.status != SalesOrderHeaderStatus.loadingMore) {
        context.read<SalesOrderHeaderBloc>().add(
          const LoadMoreSalesTransactionReport(),
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
        .read<SalesOrderHeaderBloc>()
        .state
        .salesTransactionFilters;
    final result = await showDialog<SalesTransactionReportFilters>(
      context: context,
      builder: (context) => SalesTransactionFilterDialog(
        currentFilters: currentFilters,
        authBloc: widget.authBloc,
      ),
    );

    if (result != null) {
      context.read<SalesOrderHeaderBloc>().add(
        UpdateSalesTransactionFilters(result),
      );
    }
  }

  void _exportToExcel() {
    final state = context.read<SalesOrderHeaderBloc>().state;
    context.read<SalesOrderHeaderBloc>().add(
      ExportSalesTransactionToExcel(state.salesTransactionFilters),
    );
  }

  void _exportToPDF() {
    final state = context.read<SalesOrderHeaderBloc>().state;
    context.read<SalesOrderHeaderBloc>().add(
      ExportSalesTransactionToPDF(state.salesTransactionFilters),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.grey, // Updated background color to match ExpirationReport
      appBar: AppBar(
        title: const Text('Sales Transaction Report'),
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
            BlocListener<SalesOrderHeaderBloc, SalesOrderHeaderState>(
              listener: (context, state) {
                if (state.exportSalesTransactionMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.exportSalesTransactionMessage!),
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

              return BlocBuilder<SalesOrderHeaderBloc, SalesOrderHeaderState>(
                builder: (context, state) {
                  return Stack(
                    children: [
                      Column(
                        children: [
                          // Summary Cards
                          _buildSummaryCards(state, systemConstant),

                          // Active Filters Indicator
                          if (state.salesTransactionFilters.hasFilters)
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
                                  state.salesTransactionFilters.isDetailView
                                      ? 'Detail Transactions'
                                      : 'Header Transactions',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1C4292),
                                  ),
                                ),
                                Text(
                                  'Total Items: ${state.salesTransactionTotalCount}',
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
                      if (state.status == SalesOrderHeaderStatus.loading)
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
    SalesOrderHeaderState state,
    SystemConstant? systemConstant,
  ) {
    if (state.status == SalesOrderHeaderStatus.loading &&
        state.salesTransactionHeaders.isEmpty &&
        state.salesTransactionDetails.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final isDetailView = state.salesTransactionFilters.isDetailView;
    final items = isDetailView
        ? state.salesTransactionDetails
        : state.salesTransactionHeaders;

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
              'No transactions found',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: items.length + (state.hasMoreSalesTransaction ? 1 : 0),
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
          isDetailView,
        );
      },
    );
  }

  Widget _buildTransactionListItem(
    dynamic item,
    int index,
    bool isCompact,
    double cardWidth,
    double screenHeight,
    SystemConstant? systemConstant,
    bool isDetailView,
  ) {
    final isExpanded = _isDetailExpanded && _selectedItem == item;

    // For responsiveness:
    final collapsedHeight = isCompact
        ? screenHeight * 0.22
        : screenHeight *
              0.16; // Slightly taller than Expiration report due to more info
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
                      _buildAvatar(item, isDetailView),
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
                                    isDetailView
                                        ? (item as SalesOrderDetail)
                                                  .itemDescription ??
                                              'N/A'
                                        : (item as SalesOrderHeader)
                                                  .customerBillToName ??
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
                                _buildStatusBadge(item, isDetailView),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isDetailView
                                  ? 'Qty: ${(item as SalesOrderDetail).quantity?.toStringAsFixed(2) ?? '0'}'
                                  : 'Order ${(item as SalesOrderHeader).orderNumber ?? 'N/A'}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (!isDetailView) ...[
                              const SizedBox(height: 2),
                              Text(
                                _dateFormat.format(
                                  (item as SalesOrderHeader).orderDate ??
                                      DateTime.now(),
                                ),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
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
                  child: isDetailView
                      ? _buildDetailViewContent(
                          item as SalesOrderDetail,
                          isCompact,
                        )
                      : _buildHeaderViewContent(
                          item as SalesOrderHeader,
                          isCompact,
                          systemConstant,
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(dynamic item, bool isDetailView) {
    IconData icon;
    Color color;

    if (isDetailView) {
      icon = Iconsax.box;
      color = Colors.orange;
    } else {
      final status =
          (item as SalesOrderHeader).paymentMethod?.toLowerCase() ?? '';
      if (status.contains('cash')) {
        icon = Iconsax.tick_circle;
        color = Colors.green;
      } else if (status.contains('credit')) {
        icon = Iconsax.clock;
        color = Colors.orange;
      } else {
        icon = Iconsax.danger;
        color = Colors.red;
      }
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

  Widget _buildStatusBadge(dynamic item, bool isDetailView) {
    if (isDetailView) {
      final detail = item as SalesOrderDetail;
      final profit = detail.grossProfitDetail ?? 0;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: (profit >= 0 ? Colors.green : Colors.red).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (profit >= 0 ? Colors.green : Colors.red).withOpacity(0.3),
          ),
        ),
        child: Text(
          profit >= 0 ? 'Profit' : 'Loss',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: profit >= 0 ? Colors.green : Colors.red,
          ),
        ),
      );
    } else {
      final header = item as SalesOrderHeader;
      return _buildStatusChip(header.paymentMethod ?? 'Unknown');
    }
  }

  Widget _buildHeaderViewContent(
    SalesOrderHeader header,
    bool isCompact,
    SystemConstant? systemConstant,
  ) {
    final showTax = systemConstant?.taxInfoDisplayBoolean ?? true;
    final showDiscount = systemConstant?.discountDisplayBoolean ?? true;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildDetailRow(
            'Customer',
            header.customerBillToRef?.customerName ?? 'N/A',
            Iconsax.calendar,
          ),
          _buildDetailRow(
            'Date',
            _dateFormat.format(header.orderDate!),
            Iconsax.calendar,
          ),
          _buildDetailRow(
            'Transaction Ref',
            'FS-${header.fsNumber ?? 'N/A'}',
            Iconsax.card,
          ),
          _buildDetailRow(
            'Witholding Tax',
            _currencyFormat.format(header.withholdAmount ?? 0),
            Iconsax.receipt,
          ),
          if (showTax)
            _buildDetailRow(
              'Tax',
              _currencyFormat.format(header.tax ?? 0),
              Iconsax.math,
            ),
          if (showDiscount)
            _buildDetailRow(
              'Discount',
              _currencyFormat.format(header.discountAmount ?? 0),
              Iconsax.discount_shape,
            ),
          _buildDetailRow(
            'Total Revenue',
            _currencyFormat.format(header.amountTotal ?? 0),
            Iconsax.money_send,
            isBold: true,
            valueColor: const Color(0xFF1C4292),
          ),
          _buildDetailRow(
            'Cost Of Sales',
            _currencyFormat.format(header.amountCost ?? 0),
            Iconsax.money_send,
            isBold: true,
            valueColor: const Color(0xFF1C4292),
          ),

          _buildDetailRow(
            'Gross Profit',
            _currencyFormat.format(header.itemWiseGrossProfit ?? 0),
            Iconsax.chart_2,
            valueColor: const Color(0xFF1C4292),
          ),
          _buildDetailRow(
            'Sales Chnannel',
            header.paymentInstrumentRef?.description1 ?? 'N/A',
            Iconsax.chart_2,
            valueColor: const Color(0xFF1C4292),
          ),
          _buildDetailRow(
            'Order Type',
            header.orderTypeRef?.description1 ?? 'N/A',
            Iconsax.chart_2,
            valueColor: const Color(0xFF1C4292),
          ),
          if (header.paymentTerm != null)
            _buildDetailRow(
              'Payment Term',
              (header.paymentTerm ?? 0).toString(),
              Iconsax.chart_2,
              valueColor: const Color(0xFF1C4292),
            ),
          if (header.employeesId != null)
            _buildDetailRow(
              'Sales Person',
              header.employee?.nameFirst ?? 'N/A',
              Iconsax.chart_2,
              valueColor: const Color(0xFF1C4292),
            ),
          if (header.proformaReference != null)
            _buildDetailRow(
              'Proforma Reference',
              header.proformaReference ?? 'N/A',
              Iconsax.chart_2,
              valueColor: const Color(0xFF1C4292),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailViewContent(SalesOrderDetail detail, bool isCompact) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildDetailRow(
            'Item',
            detail.item?.itemDescription ?? 'N/A',
            Iconsax.hashtag,
          ),
          _buildDetailRow(
            'Customer',
            detail.orderHeader?.customerBillToRef?.customerName ?? 'N/A',
            Iconsax.calendar,
          ),
          _buildDetailRow(
            'Order Number',
            detail.orderHeader?.orderNumber?.toString() ?? 'N/A',
            Iconsax.hashtag,
          ),
          _buildDetailRow(
            'Date',
            detail.orderDate != null
                ? _dateFormat.format(detail.orderDate!)
                : 'N/A',
            Iconsax.calendar,
          ),

          _buildDetailRow(
            'Transaction Ref',
            'FS-${detail.fsNumber ?? 'N/A'}',
            Iconsax.calendar,
          ),
          _buildDetailRow(
            'UOM',
            detail.unitOfMeasureDescription ?? 'N/A',
            Iconsax.ruler,
          ),
          _buildDetailRow(
            'Quantity',
            detail.quantity?.toString() ?? 'N/A',
            Iconsax.ruler,
          ),
          _buildDetailRow(
            'Unit Price',
            _currencyFormat.format(detail.unitPrice ?? 0),
            Iconsax.tag,
          ),
          _buildDetailRow(
            'VAT',
            _currencyFormat.format(detail.taxAmount ?? 0),
            Iconsax.tag,
          ),
          _buildDetailRow(
            'Total Amount',
            _currencyFormat.format(detail.extendedPrice ?? 0),
            Iconsax.money_send,
            isBold: true,
          ),
          _buildDetailRow(
            'COGS',
            _currencyFormat.format(detail.amountCost ?? 0),
            Iconsax.money_send,
            isBold: true,
          ),
          _buildDetailRow(
            'Gross Profit',
            _currencyFormat.format(detail.grossProfitDetail ?? 0),
            Iconsax.chart_2,
            valueColor: (detail.grossProfitDetail ?? 0) >= 0
                ? Colors.green
                : Colors.red,
            isBold: true,
          ),

          if (detail.orderHeader?.paymentTerm != null)
            _buildDetailRow(
              'Payment Term',
              (detail.orderHeader?.paymentTerm ?? 0).toString(),
              Iconsax.chart_2,
              valueColor: const Color(0xFF1C4292),
            ),
          if (detail.orderHeader?.employeesId != null)
            _buildDetailRow(
              'Sales Representative',
              (detail.orderHeader?.employee?.nameFirst ?? 0).toString(),
              Iconsax.chart_2,
              valueColor: const Color(0xFF1C4292),
            ),
          if (detail.orderHeader?.proformaReference != null)
            _buildDetailRow(
              'Proforma Reference',
              (detail.orderHeader?.proformaReference ?? 0).toString(),
              Iconsax.chart_2,
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
    SalesOrderHeaderState state,
    SystemConstant? systemConstant,
  ) {
    final totals = state.salesTransactionTotals;
    if (totals == null) return const SizedBox.shrink();

    final showTax = systemConstant?.taxInfoDisplayBoolean ?? true;
    final showDiscount = systemConstant?.discountDisplayBoolean ?? true;
    final vatLabel = systemConstant?.totVat ?? 'VAT';

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
                _buildSummaryItem(
                  'Total Revenue',
                  _currencyFormat.format(totals.revenueTotal),
                  Iconsax.money_send,
                  Colors.green,
                ),
                _buildSummaryItem(
                  'Count',
                  '${totals.totalCount}',
                  Iconsax.document_text,
                  Colors.blue,
                ),
              ],
            ),
            if (showTax || showDiscount) ...[
              const SizedBox(height: 6),
              const Divider(),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  if (showTax)
                    _buildSummaryItem(
                      vatLabel,
                      _currencyFormat.format(totals.vatTotal),
                      Iconsax.receipt_2,
                      Colors.orange,
                    ),
                  if (showDiscount)
                    _buildSummaryItem(
                      'Discount',
                      _currencyFormat.format(totals.discountTotal),
                      Iconsax.discount_shape,
                      Colors.purple,
                    ),
                ],
              ),
            ],
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
              _buildFilterDescription(state.salesTransactionFilters),
              style: TextStyle(fontSize: 12, color: Colors.blue[800]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Iconsax.close_circle, size: 16),
            onPressed: () {
              context.read<SalesOrderHeaderBloc>().add(
                const ClearSalesTransactionFilters(),
              );
            },
          ),
        ],
      ),
    );
  }

  String _buildFilterDescription(SalesTransactionReportFilters filters) {
    final parts = <String>[];
    if (filters.customerId != null) parts.add('Customer Filtered');
    if (filters.itemId != null) parts.add('Item Filtered');
    if (filters.dateFrom != null) parts.add('Date Range');
    if (filters.salesType != null) parts.add('Type: ${filters.salesType}');
    if (filters.isDetailView) parts.add('Detail View');

    return parts.isNotEmpty ? 'Active: ${parts.join(', ')}' : 'No filters';
  }

  Widget _buildStatusChip(String status) {
    Color color = Colors.grey;
    if (status.toLowerCase().contains('cash')) color = Colors.green;
    if (status.toLowerCase().contains('credit')) color = Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
