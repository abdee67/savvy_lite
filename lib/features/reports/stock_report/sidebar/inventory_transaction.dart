import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:savvy_stock/features/stock/item_transactions/blocs/item_transaction_bloc.dart';
import 'package:savvy_stock/features/stock/item_transactions/blocs/item_transaction_event.dart';
import 'package:savvy_stock/features/stock/item_transactions/blocs/item_transaction_state.dart';
import 'package:savvy_stock/features/stock/item_transactions/model/item_transaction_model.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';

class InventoryTransactionReportPage extends StatefulWidget {
  final AuthBloc authBloc;
  const InventoryTransactionReportPage({super.key, required this.authBloc});

  @override
  State<InventoryTransactionReportPage> createState() =>
      _InventoryTransactionReportPageState();
}

class _InventoryTransactionReportPageState
    extends State<InventoryTransactionReportPage>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  // Animation controllers for detail panel
  late AnimationController _detailAnimationController;
  late Animation<double> _heightAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  //  Detail panel state
  ItemTransactionModel? _selectedItemTransaction;
  bool _itemTransactionDetail = false;

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
      if (context.read<ItemTransactionBloc>().state.items.isNotEmpty) {
        _debugLotColorCalculation(
          context.read<ItemTransactionBloc>().state.items.first,
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
      context.read<ItemTransactionsBloc>().add(
        LoadItemTransactionsReport(companyId: companyId, page: 1, pageSize: 20),
      );
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      final state = context.read<ItemTransactionsBloc>().state;
      if (state.hasMoreItemTransactionReport &&
          state.status !=
              ItemTransactionsStatus.loadingMoreItemTransactionReport) {
        context.read<ItemTransactionsBloc>().add(
          LoadMoreItemTransactionsReport(),
        );
      }
    }
  }

  void _showItemTransactionDetail(ItemTransactionModel itemTransaction) {
    setState(() {
      _selectedItemTransaction = itemTransaction;
      _itemTransactionDetail = true;
    });

    //Start the animation
    _detailAnimationController.forward(from: 0.0);
  }

  void _hideItemTransactionDetail() {
    // Reverse the animation
    _detailAnimationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _itemTransactionDetail = false;
          _selectedItemTransaction = null;
        });
      }
    });
  }

  void _exportToExcel() {
    final state = context.read<ItemTransactionsBloc>().state;
    context.read<ItemTransactionsBloc>().add(
      ExportItemTransactionsReportToExcel(),
    );
  }

  void _exportToPDF() {
    final state = context.read<ItemTransactionsBloc>().state;
    context.read<ItemTransactionsBloc>().add(
      ExportItemTransactionsReportToPDF(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey,
      appBar: AppBar(
        title: const Text('Item Transaction Report'),
        backgroundColor: const Color.fromARGB(255, 28, 66, 146),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.export),
            onPressed: _showExportMenu,
            tooltip: 'Export',
          ),
        ],
      ),
      body: BlocConsumer<ItemTransactionsBloc, ItemTransactionsState>(
        listener: (context, state) {
          if (state.status ==
              ItemTransactionsStatus.exportItemTransactionReportSuccess) {
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

                  // Lot List
                  Expanded(child: _buildLotList(state)),
                ],
              ),
              // Loading Overlay
              if (state.status ==
                  ItemTransactionsStatus.loadingItemTransactionReport)
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

  Widget _buildSummaryCard(ItemTransactionsState state) {
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
                  '${state.itemTransactionReportTotalCount}',
                  Iconsax.calendar_tick,
                  Colors.orange,
                ),

                _buildSummaryItem(
                  'Page',
                  '${state.itemTransactionReportPage}/${state.itemTransactionReportTotalPages}',
                  Iconsax.document,
                  Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (state.status ==
                ItemTransactionsStatus.loadingMoreItemTransactionReport)
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

  Widget _buildLotList(ItemTransactionsState state) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 700;
    final cardSpacing = screenHeight * 0.02;
    final cardWidth = isSmallScreen ? screenWidth * 0.85 : screenWidth * 0.8;

    if (state.status == ItemTransactionsStatus.loadingItemTransactionReport &&
        state.itemTransactionReportItems.isEmpty) {
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

    if (state.status == ItemTransactionsStatus.failure &&
        state.itemTransactionReportItems.isEmpty) {
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
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final companyId = widget.authBloc.state.companyId;
                if (companyId != null) {
                  context.read<ItemTransactionsBloc>().add(
                    LoadItemTransactionsReport(companyId: companyId),
                  );
                }
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.itemTransactionReportItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.calendar_tick, size: 64, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              'No item Transaction found',
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
            state.itemTransactionReportItems.length +
            (state.itemTransactionReportItems.isEmpty ? 1 : 0),
        separatorBuilder: (context, index) => SizedBox(height: cardSpacing),
        itemBuilder: (context, index) {
          if (index >= state.itemTransactionReportItems.length) {
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

          final lot = state.itemTransactionReportItems[index];

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
    ItemTransactionModel itemTransaction,
    ItemTransactionsState state,
    int index,
    bool isCompact,
    double cardWidth,
    double screenHeight,
  ) {
    // final offset = _dragOffset[index] ?? 0.0;
    final isExpanded =
        _itemTransactionDetail == true &&
        _selectedItemTransaction == itemTransaction;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    // For responsiveness:
    final collapsedHeight = isCompact
        ? screenHeight * 0.18
        : screenHeight * 0.6;
    final expandedHeight = isCompact ? screenHeight * 0.5 : screenHeight * 0.35;

    return GestureDetector(
      onTap: () => isExpanded
          ? _hideItemTransactionDetail()
          : _showItemTransactionDetail(itemTransaction),
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
                      _buildLotAvatar(itemTransaction, isCompact),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  itemTransaction.item?.itemDescription ??
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
                            if (itemTransaction.transactionType != null)
                              _buildItemTransactionType(itemTransaction),
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
                            ? _hideItemTransactionDetail()
                            : _showItemTransactionDetail(itemTransaction),
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
                  child: _buildItemTransactionDetailContent(
                    itemTransaction,
                    isCompact,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemTransactionDetailContent(
    ItemTransactionModel itemTransaction,
    bool isCompact,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildDetailItem(
            'Transaction type: ',
            itemTransaction.transactionTypeDetail?.description1 ?? 'N/A',
            Iconsax.tag,
            isCompact,
          ),
          _buildDetailItem(
            'Item Description: ',
            itemTransaction.item?.itemDescription ?? 'N/A',
            Iconsax.box,
            isCompact,
          ),
          _buildDetailItem(
            'Branch: ',
            itemTransaction.branchDetail?.description ?? 'N/A',
            Iconsax.location,
            isCompact,
          ),
          _buildDetailItem(
            'Location: ',
            itemTransaction
                    .itemLocationRef
                    ?.locationDescription
                    ?.locationDescription ??
                'N/A',
            Iconsax.location_add,
            isCompact,
          ),
          _buildDetailItem(
            'Transaction Date: ',
            _formatDate(itemTransaction.dateCreated),
            Iconsax.calendar,
            isCompact,
          ),
          if (itemTransaction.lotNumber != null)
            _buildDetailItem(
              'Lot Number : ',
              itemTransaction.lotNumber?.toString() ?? 'N/A',
              Iconsax.tag,
              isCompact,
            ),
          _buildDetailItem(
            'Batch Number: ',
            itemTransaction.lotNumberRef?.batchNumberSupplier ?? 'N/A',
            Iconsax.nexo_nexo,
            isCompact,
          ),
          if (itemTransaction.supplier != null)
            _buildDetailItem(
              'Supplier: ',
              itemTransaction.supplierDetail?.supplierName ?? 'N/A',
              Iconsax.nexo_nexo,
              isCompact,
            ),
          if (itemTransaction.customer != null)
            _buildDetailItem(
              'Customer : ',
              itemTransaction.customerDetail?.customerName ?? 'N/A',
              Iconsax.nexo_nexo,
              isCompact,
            ),
          _buildDetailItem(
            'Transaction Qunatity: ',
            itemTransaction.quantityTransaction.toString() ?? 'N/A',
            Iconsax.nexo_nexo,
            isCompact,
          ),
          _buildDetailItem(
            'Amount Cost: ',
            itemTransaction.amountCost.toString() ?? 'N/A',
            Iconsax.nexo_nexo,
            isCompact,
          ),
          _buildDetailItem(
            'Order Type: ',
            itemTransaction.orderTypeDetail?.description1 ?? 'N/A',
            Iconsax.nexo_nexo,
            isCompact,
          ),
          _buildDetailItem(
            'Remark: ',
            itemTransaction.remark ?? 'N/A',
            Iconsax.nexo_nexo,
            isCompact,
          ),
          _buildDetailItem(
            'Unit of Measure: ',
            itemTransaction.unitOfMeasureDetail?.description1 ?? 'N/A',
            Iconsax.uniEB1B,
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

  Widget _buildLotAvatar(ItemTransactionModel itemTransaction, bool isCompact) {
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

  Widget _buildItemTransactionType(ItemTransactionModel itemTransaction) {
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
            itemTransaction.transactionTypeDetail?.description1 ?? 'N/A',
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
