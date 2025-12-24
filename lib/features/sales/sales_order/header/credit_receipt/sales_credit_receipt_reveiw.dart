import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:savvy_stock/core/constants/app_routes.dart';
import 'package:savvy_stock/core/utils/ui_helper.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/sales/sales_order/header/bloc/sales_order_header_bloc.dart';
import 'package:savvy_stock/features/sales/sales_order/header/bloc/sales_order_header_event.dart';
import 'package:savvy_stock/features/sales/sales_order/header/bloc/sales_order_header_state.dart';
import 'package:savvy_stock/features/sales/sales_order/header/credit_receipt/sales_credit_receipt_screen.dart';
import 'package:savvy_stock/features/sales/sales_order/header/model/sales_order_header.dart';
import 'package:savvy_stock/features/sales/sales_order/integration/bloc/sales_order_coordinator_bloc.dart';
import 'package:savvy_stock/features/sales/sales_order/integration/bloc/sales_order_coordinator_event.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_bloc.dart';

class CreditSalesReviewPage extends StatefulWidget {
  final AuthBloc authBloc;
  const CreditSalesReviewPage({super.key, required this.authBloc});

  @override
  State<CreditSalesReviewPage> createState() => _CreditSalesReviewPageState();
}

class _CreditSalesReviewPageState extends State<CreditSalesReviewPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Map<int, double> _dragOffset = {};

  // Animation controllers for detail panel
  late AnimationController _detailAnimationController;
  late Animation<double> _heightAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  // Detail panel state
  bool _salesOrderDetail = false;
  SalesOrderHeader? _selectedSalesOrder;
  late final int decimalPlace;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _detailAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Set up animations
    _setupAnimations();

    // Load salesOrders
    context.read<SalesOrderHeaderBloc>().add(
      LoadCreditSalesOrders(companyId: widget.authBloc.state.companyId!),
    );

    decimalPlace = context
        .read<SystemConstantBloc>()
        .state
        .systemConstants
        .first
        .decimalPlaces!;
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
    _searchController.dispose();
    _scrollController.dispose();
    _detailAnimationController.dispose();
    super.dispose();
  }

  void _handleSearch(
    SalesOrderHeader filter,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    context.read<SalesOrderHeaderBloc>().add(
      FilterSalesOrders(
        filter: filter,
        startDate: startDate,
        endDate: endDate,
        companyId: widget.authBloc.state.companyId!,
      ),
    );
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<SalesOrderHeaderBloc>().add(
      FilterSalesOrders(
        filter: SalesOrderHeader(),
        companyId: widget.authBloc.state.companyId!,
        startDate: null,
        endDate: null,
      ),
    );
  }

  void _showsalesOrderDetail(SalesOrderHeader salesOrder) {
    setState(() {
      _selectedSalesOrder = salesOrder;
      _salesOrderDetail = true;
    });

    // Start the animation
    _detailAnimationController.forward(from: 0.0);
  }

  void _hidesalesOrderDetail() {
    // Reverse the animation
    _detailAnimationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _salesOrderDetail = false;
          _selectedSalesOrder = null;
        });
      }
    });
  }

  void _refreshList() {
    context.read<SalesOrderHeaderBloc>().add(
      LoadSalesOrderHeaders(companyId: widget.authBloc.state.companyId!),
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('salesOrders refreshed')));
  }

  void _exportToExcel() {
    final bloc = context.read<SalesOrderHeaderBloc>();
    final state = bloc.state;

    if (state.selectedItems.isNotEmpty) {
      //bloc.add(ExportsalesOrders(state.selectedItems, 'excel'));
    } else {
      //bloc.add(ExportsalesOrders(state.salesOrders, 'excel'));
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Exporting to Excel...')));
  }

  void _receiveCredit(SalesOrderHeader selectedOrder) {
    if (selectedOrder == null && selectedOrder.paymentTerm == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All Credits is already Received')),
      );
      return;
    }

    // Open receiving dialog for this detail
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return BlocProvider.value(
          value: context.read<SalesOrderHeaderBloc>(),
          child: CreditReceiptScreen(
            salesOrderHeader: selectedOrder,
            companyId: widget.authBloc.state.companyId,
          ),
        );
      },
    );
  }

  void _exportToCSV() {
    final bloc = context.read<SalesOrderHeaderBloc>();
    final state = bloc.state;

    if (state.selectedItems.isNotEmpty) {
      bloc.add(ExportSaleOrder(salesOrder: state.selected!, format: 'csv'));
    } else {
      bloc.add(ExportSaleOrder(salesOrder: state.selected!, format: 'csv'));
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Exporting to CSV...')));
  }

  void _navigateToCreateScreen() {
    final companyId = widget.authBloc.state.companyId;
    final userId = widget.authBloc.state.userId?.id;
    final branchId = widget.authBloc.state.userId?.branch;
    context.read<SalesOrderCoordinatorBloc>().add(
      PrepareNewSalesOrder(
        companyId: companyId!,
        employeeId: userId!,
        branchId: branchId!,
      ),
    );
    context.push(AppRoutes.salesCustomerInfo);
  }

  void _safeVoid(BuildContext context, {int? index}) {
    final bloc = context.read<SalesOrderHeaderBloc>();
    final state = bloc.state;

    if (index == null || index < 0 || index >= state.creditHeaders.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot void salesOrder. Invalid index.')),
      );
      return;
    }

    final salesOrderToDelete = state.creditHeaders[index];
    final voidIndicator = 'V';

    showDeleteDialog(
      context,
      title: 'Void salesOrder #${salesOrderToDelete.orderNumber}?',
      content:
          'Are you sure you want to void salesOrder #${salesOrderToDelete.orderNumber}?',
      onConfirm: () {
        bloc.add(
          VoidSalesOrder(
            id: salesOrderToDelete.id!,
            voidIndicator: voidIndicator,
          ),
        );
      },
    );
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
        _safeVoid(context, index: index);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Credit Sales Order'),
        backgroundColor: const Color.fromARGB(255, 28, 66, 146),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.home),
            onPressed: () => {}, //context.push(AppRoutes.reportsHome),
            tooltip: 'Reports Home',
          ),
        ],
      ),
      body: BlocConsumer<SalesOrderHeaderBloc, SalesOrderHeaderState>(
        listener: (context, state) {
          if (state.status == SalesOrderHeaderStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.successmessage ?? 'Operation completed successfully',
                ),
                backgroundColor: Colors.green,
              ),
            );
          }

          if (state.status == SalesOrderHeaderStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error ?? 'An error occurred'),
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
                  // Toolbar
                  // _buildToolbar(),

                  // Search Bar
                  _buildSearchBar(),
                  //  _buildActionButtons(state),

                  // salesOrders List
                  Expanded(child: _buildsalesOrdersList(state)),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          // Refresh Button
          ElevatedButton.icon(
            onPressed: _refreshList,
            icon: const Icon(Iconsax.refresh, size: 16),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color.fromARGB(255, 28, 66, 146),
              side: BorderSide(
                color: const Color.fromARGB(255, 28, 66, 146).withOpacity(0.3),
              ),
            ),
          ),
          const Spacer(),

          // Export Menu
          PopupMenuButton<String>(
            icon: const Icon(
              Iconsax.export,
              color: Color.fromARGB(255, 28, 66, 146),
            ),
            offset: const Offset(0, 50),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'excel',
                child: Row(
                  children: [
                    Icon(Iconsax.document, size: 16),
                    SizedBox(width: 8),
                    Text('Excel'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'csv',
                child: Row(
                  children: [
                    Icon(Iconsax.document_copy, size: 16),
                    SizedBox(width: 8),
                    Text('CSV'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'excel') {
                _exportToExcel();
              } else if (value == 'csv') {
                _exportToCSV();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: const Color.fromARGB(
                    255,
                    28,
                    66,
                    146,
                  ).withOpacity(0.3),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(
                    Iconsax.export,
                    size: 16,
                    color: Color.fromARGB(255, 28, 66, 146),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Export',
                    style: TextStyle(color: Color.fromARGB(255, 28, 66, 146)),
                  ),
                ],
              ),
            ),
          ),
        ],
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
                hintText: 'Search by salesOrder number, item, store...',
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
              // onChanged: _handleSearch,
            ),
          ),
          const SizedBox(width: 12),
          _buildFloatingActionButton(context),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return BlocBuilder<SalesOrderHeaderBloc, SalesOrderHeaderState>(
      builder: (context, state) {
        return ElevatedButton(
          onPressed: () {
            _navigateToCreateScreen();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 28, 66, 146),
            shape: const CircleBorder(),
          ),
          child: const Icon(Icons.add, color: Colors.white),
        );
      },
    );
  }

  Widget _buildsalesOrdersList(SalesOrderHeaderState state) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 700;
    final cardSpacing = screenHeight * 0.02;
    final cardWidth = isSmallScreen ? screenWidth * 0.85 : screenWidth * 0.8;

    if (state.status == SalesOrderHeaderStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == SalesOrderHeaderStatus.failure) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              state.error ?? 'Failed to load sales orders',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<SalesOrderHeaderBloc>().add(
                LoadSalesOrderHeaders(
                  companyId: widget.authBloc.state.companyId!,
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.creditHeaders.isEmpty) {
      final query = state.searchQuery ?? '';
      final hasQuery = query.isNotEmpty;

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.receipt, size: 64, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              !hasQuery ? 'No salesOrders found' : 'No results for "$query"',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Container(
      width: screenWidth,
      height: screenHeight,
      decoration: BoxDecoration(color: Colors.grey[100]),
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: state.creditHeaders.length,
        separatorBuilder: (context, index) => SizedBox(height: cardSpacing),
        itemBuilder: (context, index) {
          final salesOrder = state.creditHeaders[index];
          final isSelected = state.selectedItems.contains(salesOrder);

          return _buildsalesOrderListItem(
            salesOrder,
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

  Widget _buildsalesOrderListItem(
    SalesOrderHeader salesOrder,
    bool isSelected,
    SalesOrderHeaderState state,
    int index,
    bool isCompact,
    double cardWidth,
  ) {
    final offset = _dragOffset[index] ?? 0.0;
    final isExpanded =
        _salesOrderDetail == true && _selectedSalesOrder == salesOrder;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // For responsiveness:
    final collapsedHeight = isCompact
        ? screenHeight * 0.22
        : screenHeight * 0.14;

    final expandedHeight = isCompact
        ? screenHeight * 0.55
        : screenHeight * 0.45;
    final collapsedWidth = isCompact ? screenWidth * 0.92 : screenWidth * 0.8;

    return GestureDetector(
      onDoubleTap: () => _showsalesOrderDetail(salesOrder),
      onHorizontalDragUpdate: (details) =>
          _onHorizontalDragUpdate(index, details),
      onHorizontalDragEnd: (details) =>
          _onHorizontalDragEnd(context, index, details),
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
                // Yellow background
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

              // 3. salesOrder CARD - Should come AFTER delete indicator
              AnimatedContainer(
                padding: const EdgeInsets.only(top: 10, left: 10, right: 10),
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
                        // salesOrder Avatar
                        _buildsalesOrderAvatar(
                          salesOrder,
                          isSelected,
                          isCompact,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'FS Number - ${salesOrder.fsNumber ?? 'N/A'}',
                                    style: TextStyle(
                                      color: const Color(0xFF373737),
                                      fontSize: isCompact ? 20 : 24,
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getsalesOrderTypeColor(
                                        salesOrder.paymentStatusRef!.detailCode,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _getsalesOrderTypeBorderColor(
                                          salesOrder
                                              .paymentStatusRef!
                                              .detailCode,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      salesOrder
                                              .paymentStatusRef!
                                              .description1 ??
                                          'Unknown',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              Text(
                                'Total - ${salesOrder.amountTotal}',
                                style: TextStyle(
                                  color: const Color(0xFF887F7F),
                                  fontSize: isCompact ? 12 : 14,
                                  fontStyle: FontStyle.italic,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Store and date info
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.blue[200]!,
                                      ),
                                    ),
                                    child: Text(
                                      'From ${_formatDateTime(salesOrder.orderDate ?? DateTime.now())}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.blue[800],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green[50],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.green[200]!,
                                      ),
                                    ),
                                    child: Text(
                                      'To ${_formatDateTime(salesOrder.shippedDate ?? DateTime.now())}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.green[800],
                                        fontWeight: FontWeight.bold,
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // See More / See Less button
                        ElevatedButton(
                          onPressed: () => isExpanded
                              ? _hidesalesOrderDetail()
                              : _showsalesOrderDetail(salesOrder),
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
                    child: _buildsalesOrderDetailContent(salesOrder, isCompact),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildsalesOrderDetailContent(
    SalesOrderHeader salesOrder,
    bool isCompact,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          if (salesOrder.customerBillToRef != null)
            _buildsalesOrderInfoItem(
              'Customer : ',
              salesOrder.customerBillToRef!.customerName?.toString() ?? 'N/A',
              Iconsax.box,
              isCompact,
            ),
          if (salesOrder.orderNumber != null)
            _buildsalesOrderInfoItem(
              'Order No : ',
              salesOrder.orderNumber?.toString() ?? 'N/A',
              Iconsax.receipt,
              isCompact,
            ),
          if (salesOrder.amountTotal != null)
            _buildsalesOrderInfoItem(
              'Total Amount : ',
              NumberFormat.currency(
                    decimalDigits: decimalPlace,
                    symbol: 'Birr',
                  ).format(salesOrder.amountTotal!) ??
                  'N/A',
              Iconsax.receipt,
              isCompact,
            ),
          if (salesOrder.amountOpen != null)
            _buildsalesOrderInfoItem(
              'Unreceived Amount : ',
              NumberFormat.currency(
                    decimalDigits: decimalPlace,
                    symbol: 'Birr',
                  ).format(salesOrder.amountOpen!) ??
                  'N/A',
              Iconsax.receipt,
              isCompact,
            ),
          if (salesOrder.fsNumber != null)
            _buildsalesOrderInfoItem(
              'FS Number : ',
              salesOrder.fsNumber ?? 'N/A',
              Iconsax.rulerpen,
              isCompact,
            ),
          if (salesOrder.orderType != null)
            _buildsalesOrderInfoItem(
              'Order Type : ',
              salesOrder.orderTypeRef?.description1?.toString() ?? 'N/A',
              Iconsax.receipt_edit,
              isCompact,
            ),
          if (salesOrder.orderDate != null)
            _buildsalesOrderInfoItem(
              'Order Date : ',
              _formatDateTime(salesOrder.orderDate!),
              Iconsax.shop,
              isCompact,
            ),
          if (salesOrder.shippedDate != null)
            _buildsalesOrderInfoItem(
              'Shipped Date : ',
              _formatDateTime(salesOrder.shippedDate!),
              Iconsax.calendar,
              isCompact,
            ),
          if (salesOrder.voidIndicator != null)
            _buildsalesOrderInfoItem(
              'Void Indicator : ',
              salesOrder.voidIndicator?.toString() ?? 'N/A',
              Iconsax.tag,
              isCompact,
            ),
          if (salesOrder.withholdAmount != null)
            _buildsalesOrderInfoItem(
              'Withhold Amount : ',
              NumberFormat.currency(
                    decimalDigits: decimalPlace,
                    symbol: 'Birr ',
                  ).format(salesOrder.withholdAmount!) ??
                  'N/A',
              Iconsax.barcode,
              isCompact,
            ),
          if (salesOrder.tax != null)
            _buildsalesOrderInfoItem(
              'Tax : ',
              NumberFormat.currency(
                    decimalDigits: decimalPlace,
                    symbol: 'Birr ',
                  ).format(salesOrder.tax!) ??
                  'N/A',
              Iconsax.profile_2user,
              isCompact,
            ),
          if (salesOrder.discountAmount != null)
            _buildsalesOrderInfoItem(
              'Discount : ',
              NumberFormat.currency(
                    decimalDigits: decimalPlace,
                    symbol: 'Birr ',
                  ).format(salesOrder.discountAmount!) ??
                  'N/A',
              Iconsax.profile_circle,
              isCompact,
            ),
          if (salesOrder.requiredDate != null)
            _buildsalesOrderInfoItem(
              'Required Date : ',
              _formatDateTime(salesOrder.requiredDate!),
              Iconsax.calendar,
              isCompact,
            ),
          if (salesOrder.amountCost != null)
            _buildsalesOrderInfoItem(
              'Amount Cost : ',
              NumberFormat.currency(
                    decimalDigits: decimalPlace,
                    symbol: 'Birr ',
                  ).format(salesOrder.amountCost!) ??
                  'N/A',
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
                  Iconsax.eye,
                  'Receive Payemnt',
                  () => _receiveCredit(
                    salesOrder,
                  ), // This would show even more details
                  isCompact,
                ),
                _buildActionButton(
                  Iconsax.export,
                  'Export',
                  () => _exportToExcel(), // Export this single salesOrder
                  isCompact,
                ),
                _buildActionButton(Iconsax.repeat, 'Print', () {}, isCompact),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildsalesOrderInfoItem(
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

  Widget _buildsalesOrderAvatar(
    SalesOrderHeader salesOrder,
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
      child: Icon(Iconsax.receipt, color: iconColor, size: isCompact ? 20 : 24),
    );
  }

  // Helper methods
  Color _getsalesOrderTypeColor(String? salesOrderType) {
    switch (salesOrderType) {
      case 'S': // Adjustment
        return Colors.orange;
      case 'N': // Issue
        return Colors.red;
      case '': // Transfer
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getsalesOrderTypeBorderColor(String? salesOrderType) {
    switch (salesOrderType) {
      case 'A': // Adjustment
        return Colors.orange[300]!;
      case 'I': // Issue
        return Colors.red[300]!;
      case 'T': // Transfer
        return Colors.blue[300]!;
      default:
        return Colors.grey[300]!;
    }
  }

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
