import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:savvy_stock/core/constants/app_routes.dart';
import 'package:savvy_stock/core/utils/ui_helper.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/bloc/purchase_order_bloc.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/bloc/purchase_order_event.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/bloc/purchase_order_state.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/models/purchase_order_detail_model.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/models/purchase_order_header_model.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/screens/purchase_receive/purchase_receive_screen.dart';

class PurchaseReviewPage extends StatefulWidget {
  final AuthBloc authBloc;
  const PurchaseReviewPage({super.key, required this.authBloc});

  @override
  State<PurchaseReviewPage> createState() => _PurchaseReviewPageState();
}

class _PurchaseReviewPageState extends State<PurchaseReviewPage>
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
  bool _purchaseOrderDetail = false;
  PurchaseOrderDetail? _selectedPurchaseOrder;

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

    // Load purchaseOrders
    context.read<PurchaseOrderBloc>().add(
      LoadPurchaseOrders(companyId: widget.authBloc.state.companyId!),
    );
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

  void _hanleSearch(
    PurchaseOrderHeader filter,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    context.read<PurchaseOrderBloc>().add(
      FilterPurchaseOrders(
        supplierId: filter.supplierId,
        invoiceNumber: filter.invoiceNumber,
        startDate: startDate,
        endDate: endDate,
      ),
    );
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<PurchaseOrderBloc>().add(const ClearPurchaseOrderFilters());
  }

  void _showPurchaseOrderDetail(PurchaseOrderDetail purchaseOrder) {
    setState(() {
      _selectedPurchaseOrder = purchaseOrder;
      _purchaseOrderDetail = true;
    });

    // Start the animation
    _detailAnimationController.forward(from: 0.0);
  }

  void _hidePurchaseOrderDetail() {
    // Reverse the animation
    _detailAnimationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _purchaseOrderDetail = false;
          _selectedPurchaseOrder = null;
        });
      }
    });
  }

  void _refreshList() {
    context.read<PurchaseOrderBloc>().add(
      LoadPurchaseOrders(companyId: widget.authBloc.state.companyId!),
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Purchase Orders refreshed')));
  }

  void _receiveItem(PurchaseOrderDetail purchaseOrderDetail) {
    if (purchaseOrderDetail.quantityOpen! <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All Orders is already Received')),
      );
      return;
    }
    // Prepare receiver data in the bloc
    context.read<PurchaseOrderBloc>().add(
      PreparePurchaseOrderReceipt(detail: purchaseOrderDetail),
    );

    // Open receiving dialog for this detail
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return BlocProvider.value(
          value: context.read<PurchaseOrderBloc>(),
          child: PurchaseReceivingScreen(
            detail: purchaseOrderDetail,
            orderData: const {},
            authBloc: widget.authBloc,
          ),
        );
      },
    );
  }

  void _exportToExcel() {
    final bloc = context.read<PurchaseOrderBloc>();
    final state = bloc.state;

    if (state.selectedHeader != null) {
      //bloc.add(ExportQuotationOrder(purchaseOrder: state.selectedHeader!, format: 'excel'));
    } else {
      // bloc.add(ExportQuotationOrder(purchaseOrder: state.selectedHeader!, format: 'excel'));
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Exporting to Excel...')));
  }

  void _exportToCSV() {
    final bloc = context.read<PurchaseOrderBloc>();
    final state = bloc.state;
    if (state.selectedHeader != null) {
      //bloc.add(ExportQuotationOrder(purchaseOrder: state.selectedHeader!, format: 'csv'));
    } else {
      //bloc.add(ExportSaleOrder(purchaseOrder: state.selected!, format: 'csv'));
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Exporting to CSV...')));
  }

  void _navigateToCreateScreen() {
    final companyId = widget.authBloc.state.companyId;
    final branchId = widget.authBloc.state.userId?.branch;
    context.read<PurchaseOrderBloc>().add(
      PrepareCreatePurchaseOrder(companyId: companyId!, branchId: branchId),
    );
    context.push(AppRoutes.purchaseSupplierInfo);
  }

  void _safeVoid(
    BuildContext context, {
    int? index,
    PurchaseOrderDetail? detail,
  }) {
    final bloc = context.read<PurchaseOrderBloc>();
    final state = bloc.state;

    PurchaseOrderDetail? purchaseOrderToDelete;

    if (detail != null) {
      purchaseOrderToDelete = detail;
    } else if (index != null &&
        index >= 0 &&
        index < state.filteredDetails.length) {
      purchaseOrderToDelete = state.filteredDetails[index];
    }

    if (purchaseOrderToDelete == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete Purchase Order. Invalid selection.'),
        ),
      );
      return;
    }

    showDeleteDialog(
      context,
      title:
          'Delete Purchase Order #${purchaseOrderToDelete.itemNumberRef?.itemDescription}?',
      content:
          'Are you sure you want to delete Purchase Order #${purchaseOrderToDelete.itemNumberRef?.itemDescription}?',
      onConfirm: () {
        bloc.add(DeletePurchaseOrderHeader(id: purchaseOrderToDelete!.id!));
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
        title: const Text('Purchase Order Review'),
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
      body: BlocConsumer<PurchaseOrderBloc, PurchaseOrderState>(
        listener: (context, state) {
          if (state.status == PurchaseOrderStatus.success) {
            if (state.lastOperation == 'receive_items' &&
                state.selectedReceiver != null) {
              // Navigate to Sales Customer Info with extra data
              /*  context
                  .push(
                    AppRoutes.receiveItem,
                    extra: {'details': state.selectedReceiver},
                  )
                  .then((_) {
                    // Reset state when returning to prevent loop
                    context.read<PurchaseOrderBloc>().add(
                      ResetPurchaseOrderSettings(),
                    );
                  });
*/
              // Also reset immediately to prevent double push if rebuild happens
              context.read<PurchaseOrderBloc>().add(
                ResetPurchaseOrderSettings(),
              );
            }
          }

          if (state.status == PurchaseOrderStatus.error) {
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
                  // Search Bar
                  _buildSearchBar(),

                  // purchaseOrders List
                  Expanded(child: _buildPurchaseOrdersList(state)),
                ],
              ),
            ],
          );
        },
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
                hintText: 'Search by Purchase Order number, supplier...',
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
              onChanged: (value) {
                context.read<PurchaseOrderBloc>().add(
                  SearchPurchaseOrders(query: value),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          _buildFloatingActionButton(context),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return BlocBuilder<PurchaseOrderBloc, PurchaseOrderState>(
      builder: (context, state) {
        return ElevatedButton(
          onPressed: () {
            _navigateToCreateScreen();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 28, 66, 146),
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(16),
          ),
          child: const Icon(Icons.add, color: Colors.white),
        );
      },
    );
  }

  Widget _buildPurchaseOrdersList(PurchaseOrderState state) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 700;
    final cardSpacing = screenHeight * 0.02;
    final cardWidth = isSmallScreen ? screenWidth * 0.85 : screenWidth * 0.8;

    if (state.status == PurchaseOrderStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == PurchaseOrderStatus.failure) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              state.error ?? 'Failed to load purchase orders',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<PurchaseOrderBloc>().add(
                LoadPurchaseOrders(companyId: widget.authBloc.state.companyId!),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.filteredDetails.isEmpty) {
      final query = state.searchQuery ?? '';
      final hasQuery = query.isNotEmpty;

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.receipt, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              !hasQuery
                  ? 'No Purchase Orders found'
                  : 'No results for "$query"',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
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
        itemCount: state.filteredDetails.length,
        separatorBuilder: (context, index) => SizedBox(height: cardSpacing),
        itemBuilder: (context, index) {
          final purchaseOrder = state.filteredDetails[index];
          final isSelected = state.selectedDetails?.contains(purchaseOrder);

          return _buildPurchaseOrderListItem(
            purchaseOrder,
            isSelected!,
            state,
            index,
            isSmallScreen,
            cardWidth,
          );
        },
      ),
    );
  }

  Widget _buildPurchaseOrderListItem(
    PurchaseOrderDetail purchaseOrder,
    bool isSelected,
    PurchaseOrderState state,
    int index,
    bool isCompact,
    double cardWidth,
  ) {
    final offset = _dragOffset[index] ?? 0.0;
    final isExpanded =
        _purchaseOrderDetail == true && _selectedPurchaseOrder == purchaseOrder;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // For responsiveness:
    final collapsedHeight = isCompact
        ? screenHeight * 0.22
        : screenHeight * 0.16;

    final expandedHeight = isCompact
        ? screenHeight * 0.55
        : screenHeight * 0.45;
    final collapsedWidth = isCompact ? screenWidth * 0.92 : screenWidth * 0.8;

    return GestureDetector(
      onDoubleTap: () => _showPurchaseOrderDetail(purchaseOrder),
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

              // 3. PurchaseOrder CARD - Should come AFTER delete indicator
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
                        // PurchaseOrder Avatar
                        _buildPurchaseOrderAvatar(
                          purchaseOrder,
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
                                    ' ${purchaseOrder.itemNumberRef?.itemDescription ?? 'N/A'}',
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
                                      color: _getPurchaseOrderTypeColor(
                                        purchaseOrder
                                            .poReceiveStatusRef
                                            ?.detailCode,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _getPurchaseOrderTypeBorderColor(
                                          purchaseOrder
                                              .poReceiveStatusRef
                                              ?.detailCode,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      purchaseOrder
                                              .poReceiveStatusRef
                                              ?.description1 ??
                                          'Unknown',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              Text(
                                'Received Amount - ${NumberFormat.currency(symbol: '\$').format(purchaseOrder.amountReceived ?? 0)}',
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
                                      _formatDateTime(
                                            purchaseOrder.dateEffective!,
                                          ) ??
                                          '',
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
                                      'Supplier: ${purchaseOrder.batchNumberSupplier ?? 'N/A'}',
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
                              ? _hidePurchaseOrderDetail()
                              : _showPurchaseOrderDetail(purchaseOrder),
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
                    child: _buildPurchaseOrderDetailContent(
                      purchaseOrder,
                      isCompact,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPurchaseOrderDetailContent(
    PurchaseOrderDetail purchaseOrder,
    bool isCompact,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          if (purchaseOrder.batchNumberSupplier != null)
            _buildquotationOrderInfoItem(
              'Supplier : ',
              purchaseOrder.batchNumberSupplier!.toString() ?? 'N/A',
              Iconsax.box,
              isCompact,
            ),
          if (purchaseOrder.itemNumber != null)
            _buildquotationOrderInfoItem(
              'Item  : ',
              purchaseOrder.itemNumberRef?.itemDescription.toString() ?? 'N/A',
              Iconsax.receipt,
              isCompact,
            ),
          if (purchaseOrder.unitOfMeasure != null)
            _buildquotationOrderInfoItem(
              ' UoM : ',
              purchaseOrder.unitOfMeasureRef?.description1.toString() ?? 'N/A',
              Iconsax.rulerpen,
              isCompact,
            ),
          if (purchaseOrder.poReceiveStatus != null)
            _buildquotationOrderInfoItem(
              ' Status : ',
              purchaseOrder.poReceiveStatusRef?.description1.toString() ??
                  'N/A',
              Iconsax.rulerpen,
              isCompact,
            ),
          if (purchaseOrder.amountReceived != null)
            _buildquotationOrderInfoItem(
              ' Receive Amount : ',
              purchaseOrder.amountReceived.toString() ?? 'N/A',
              Iconsax.rulerpen,
              isCompact,
            ),
          if (purchaseOrder.amountOpen != null)
            _buildquotationOrderInfoItem(
              'Unreceived Amount : ',
              purchaseOrder.amountOpen.toString(),
              Iconsax.receipt_edit,
              isCompact,
            ),
          if (purchaseOrder.quantityOpen != null)
            _buildquotationOrderInfoItem(
              'Unreceived Qunatity : ',
              purchaseOrder.quantityOpen.toString(),
              Iconsax.receipt_edit,
              isCompact,
            ),
          if (purchaseOrder.quantityRecieved != null)
            _buildquotationOrderInfoItem(
              ' Receive Qunatity : ',
              purchaseOrder.quantityRecieved.toString() ?? 'N/A',
              Iconsax.rulerpen,
              isCompact,
            ),
          if (purchaseOrder.unitCost != null)
            _buildquotationOrderInfoItem(
              ' Unit Cost : ',
              purchaseOrder.unitCost.toString() ?? 'N/A',
              Iconsax.rulerpen,
              isCompact,
            ),
          if (purchaseOrder.amountExtendedCost != null)
            _buildquotationOrderInfoItem(
              ' Extended Cost : ',
              purchaseOrder.amountExtendedCost.toString() ?? 'N/A',
              Iconsax.rulerpen,
              isCompact,
            ),
          if (purchaseOrder.quantityTransaction != null)
            _buildquotationOrderInfoItem(
              ' Transaction Quntity : ',
              purchaseOrder.quantityTransaction.toString() ?? 'N/A',
              Iconsax.rulerpen,
              isCompact,
            ),
          if (purchaseOrder.dateEffective != null)
            _buildquotationOrderInfoItem(
              'Effective Date : ',
              _formatDateTime(purchaseOrder.dateEffective!),
              Iconsax.shop,
              isCompact,
            ),
          if (purchaseOrder.dateExpiration != null)
            _buildquotationOrderInfoItem(
              'Expiration Date : ',
              _formatDateTime(purchaseOrder.dateExpiration!),
              Iconsax.shop,
              isCompact,
            ),
          if (purchaseOrder.dateDelivery != null)
            _buildquotationOrderInfoItem(
              'Delivery Date : ',
              _formatDateTime(purchaseOrder.dateDelivery!),
              Iconsax.calendar,
              isCompact,
            ),

          // Action buttons row
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (purchaseOrder.quantityOpen! > 0)
                  _buildActionButton(
                    Iconsax.convert_3d_cube,
                    'Receive Item',
                    () => _receiveItem(purchaseOrder),
                    isCompact,
                  ),
                _buildActionButton(
                  Iconsax.trash,
                  'Delete',
                  () => _safeVoid(context, detail: purchaseOrder),
                  isCompact,
                ),
                _buildActionButton(
                  Iconsax.export,
                  'Export',
                  () => _exportToExcel(),
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

  Widget _buildquotationOrderInfoItem(
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

  Widget _buildPurchaseOrderAvatar(
    PurchaseOrderDetail purchaseOrder,
    bool isSelected,
    bool isCompact,
  ) {
    return Container(
      width: isCompact ? 40 : 50,
      height: isCompact ? 40 : 50,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Center(
        child: Text(
          purchaseOrder.batchNumberSupplier?.substring(0, 1).toUpperCase() ??
              'S',
          style: TextStyle(
            fontSize: isCompact ? 18 : 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF373737),
          ),
        ),
      ),
    );
  }

  Color _getPurchaseOrderTypeColor(String? status) {
    switch (status) {
      case 'C':
        return Colors.green;
      case 'P':
        return Colors.orange;
      case 'N':
      default:
        return Colors.red;
    }
  }

  Color _getPurchaseOrderTypeBorderColor(String? status) {
    switch (status) {
      case 'C':
        return Colors.green[700]!;
      case 'P':
        return Colors.orange[700]!;
      case 'N':
      default:
        return Colors.red[700]!;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('dd MMM yyyy').format(dateTime);
  }
}
