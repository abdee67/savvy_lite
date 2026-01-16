import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:savvy_stock/core/constants/app_routes.dart';
import 'package:savvy_stock/core/utils/ui_helper.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/sales/sales_return/bloc/sales_return_bloc.dart';
import 'package:savvy_stock/features/sales/sales_return/bloc/sales_return_event.dart';
import 'package:savvy_stock/features/sales/sales_return/bloc/sales_return_state.dart';
import 'package:savvy_stock/features/sales/sales_return/models/void_sales_header.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_bloc.dart';

class SalesReturnDashBoardPage extends StatefulWidget {
  final AuthBloc authBloc;
  const SalesReturnDashBoardPage({super.key, required this.authBloc});

  @override
  State<SalesReturnDashBoardPage> createState() =>
      _SalesReturnDashBoardPageState();
}

class _SalesReturnDashBoardPageState extends State<SalesReturnDashBoardPage>
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
  SalesReturnHeader? _selectedSalesOrder;
  late int _decimalPlace;

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
    context.read<SalesReturnBloc>().add(
      LoadSalesReturns(companyId: widget.authBloc.state.companyId!),
    );
    _decimalPlace = context
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
    SalesReturnHeader filter,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    context.read<SalesReturnBloc>().add(
      FilterSalesReturns(
        fsNumber: filter.fsNumber!,
        startDate: startDate,
        endDate: endDate,
        companyId: widget.authBloc.state.companyId!,
      ),
    );
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<SalesReturnBloc>().add(
      FilterSalesReturns(
        fsNumber: '',
        companyId: widget.authBloc.state.companyId!,
        startDate: null,
        endDate: null,
      ),
    );
  }

  void _showsalesOrderDetail(SalesReturnHeader salesOrder) {
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
    context.read<SalesReturnBloc>().add(
      LoadSalesReturns(companyId: widget.authBloc.state.companyId!),
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('salesOrders refreshed')));
  }

  void _exportToExcel() {
    final bloc = context.read<SalesReturnBloc>();
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

  void _exportToCSV() {
    final bloc = context.read<SalesReturnBloc>();
    final state = bloc.state;

    if (state.selectedItems.isNotEmpty) {
      // bloc.add(ExportSaleOrder(salesOrder: state.selected!, format: 'csv'));
    } else {
      // bloc.add(ExportSaleOrder(salesOrder: state.selected!, format: 'csv'));
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Exporting to CSV...')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey,
      appBar: AppBar(
        title: const Text('Sales Order Report'),
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
      body: SafeArea(
        child: BlocConsumer<SalesReturnBloc, SalesReturnState>(
          listener: (context, state) {
            if (state.status == SalesReturnStatus.success) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.successMessage ?? 'Operation completed successfully',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            }

            if (state.status == SalesReturnStatus.failure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage ?? 'An error occurred'),
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
                hintText: 'Search by sales order return number, item, store...',
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
        ],
      ),
    );
  }

  Widget _buildsalesOrdersList(SalesReturnState state) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 700;
    final cardSpacing = screenHeight * 0.02;
    final cardWidth = isSmallScreen ? screenWidth * 0.85 : screenWidth * 0.8;

    if (state.status == SalesReturnStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == SalesReturnStatus.failure) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              state.errorMessage ?? 'Failed to load sales orders returns',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<SalesReturnBloc>().add(
                LoadSalesReturns(companyId: widget.authBloc.state.companyId!),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.filteredHeaders.isEmpty) {
      final query = state.searchQuery ?? '';
      final hasQuery = query.isNotEmpty;

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.receipt, size: 64, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              !hasQuery
                  ? 'No Sales Orders return found'
                  : 'No results for "$query"',
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
        itemCount: state.filteredHeaders.length,
        separatorBuilder: (context, index) => SizedBox(height: cardSpacing),
        itemBuilder: (context, index) {
          final salesOrder = state.filteredHeaders[index];
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
    SalesReturnHeader salesOrder,
    bool isSelected,
    SalesReturnState state,
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

    return AnimatedBuilder(
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
                      _buildsalesOrderAvatar(salesOrder, isSelected, isCompact),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'FS - ${salesOrder.fsNumber ?? 'N/A'}',
                                  style: TextStyle(
                                    color: const Color(0xFF373737),
                                    fontSize: isCompact ? 20 : 24,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w800,
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
                                    'Order Date : ${_formatDateTime(salesOrder.orderDate ?? DateTime.now())}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.blue[800],
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
    );
  }

  Widget _buildsalesOrderDetailContent(
    SalesReturnHeader salesOrder,
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
          if (salesOrder.fsNumber != null)
            _buildsalesOrderInfoItem(
              'FS Number : ',
              salesOrder.fsNumber ?? 'N/A',
              Iconsax.rulerpen,
              isCompact,
            ),
          if (salesOrder.commentForReturn != null)
            _buildsalesOrderInfoItem(
              'Reason : ',
              salesOrder.commentForReturn.toString() ?? 'N/A',
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
                    decimalDigits: _decimalPlace,
                    symbol: 'ETB ',
                  ).format(salesOrder.withholdAmount!) ??
                  'N/A',
              Iconsax.barcode,
              isCompact,
            ),
          if (salesOrder.tax != null)
            _buildsalesOrderInfoItem(
              'Tax : ',
              NumberFormat.currency(
                    decimalDigits: _decimalPlace,
                    symbol: 'ETB ',
                  ).format(salesOrder.tax!) ??
                  'N/A',
              Iconsax.profile_2user,
              isCompact,
            ),
          if (salesOrder.discountAmount != null)
            _buildsalesOrderInfoItem(
              'Discount : ',
              NumberFormat.currency(
                    decimalDigits: _decimalPlace,
                    symbol: 'ETB ',
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
                    decimalDigits: _decimalPlace,
                    symbol: 'ETB ',
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
                  'View Details',
                  () => _showsalesOrderDetail(
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
    SalesReturnHeader salesOrder,
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
      case 'Sales Order': // Adjustment
        return Colors.orange;
      case 'Issue': // Issue
        return Colors.red;
      case 'Transfer': // Transfer
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getsalesOrderTypeBorderColor(String? salesOrderType) {
    switch (salesOrderType) {
      case 'Sales Order': // Adjustment
        return Colors.orange[300]!;
      case 'Issue': // Issue
        return Colors.red[300]!;
      case 'Transfer': // Transfer
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
