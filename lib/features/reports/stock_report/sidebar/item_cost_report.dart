import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:savvy_stock/features/stock/item_cost/blocs/item_cost_bloc.dart';
import 'package:savvy_stock/features/stock/item_cost/blocs/item_cost_event.dart';
import 'package:savvy_stock/features/stock/item_cost/blocs/item_cost_state.dart';
import 'package:savvy_stock/features/stock/item_cost/models/item_cost_model.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_bloc.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';

class ItemCostReportPage extends StatefulWidget {
  final AuthBloc authBloc;
  const ItemCostReportPage({super.key, required this.authBloc});

  @override
  State<ItemCostReportPage> createState() => _ItemCostReportPageState();
}

class _ItemCostReportPageState extends State<ItemCostReportPage>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  // Animation controllers for detail panel
  late AnimationController _detailAnimationController;
  late Animation<double> _heightAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  //  Detail panel state
  ItemCost? _selectedItemCost;
  bool _itemCostDetail = false;

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
      if (context.read<ItemCostBloc>().state.items.isNotEmpty) {
        _debugLotColorCalculation(
          context.read<ItemCostBloc>().state.items.first,
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
      context.read<ItemCostBloc>().add(
        LoadItemCostReport(companyId: companyId, page: 1, pageSize: 20),
      );
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      final state = context.read<ItemCostBloc>().state;
      if (state.hasMoreItemCostReport &&
          state.status != ItemCostStatus.loadingMoreItemCostReport) {
        context.read<ItemCostBloc>().add(LoadMoreItemCostReport());
      }
    }
  }

  void _showItemCostDetail(ItemCost itemCost) {
    setState(() {
      _selectedItemCost = itemCost;
      _itemCostDetail = true;
    });

    //Start the animation
    _detailAnimationController.forward(from: 0.0);
  }

  void _hideItemCostDetail() {
    // Reverse the animation
    _detailAnimationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _itemCostDetail = false;
          _selectedItemCost = null;
        });
      }
    });
  }

  void _exportToExcel() {
    final state = context.read<ItemCostBloc>().state;
    context.read<ItemCostBloc>().add(ExportItemCostReportToExcel());
  }

  void _exportToPDF() {
    final state = context.read<ItemCostBloc>().state;
    context.read<ItemCostBloc>().add(ExportItemCostReportToPDF());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey,
      appBar: AppBar(
        title: const Text('Item Cost Report'),
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
      body: BlocConsumer<ItemCostBloc, ItemCostState>(
        listener: (context, state) {
          if (state.status == ItemCostStatus.exportItemCostReportSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage!),
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
              if (state.status == ItemCostStatus.loadingItemCostReport)
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

  Widget _buildSummaryCard(ItemCostState state) {
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
                  '${state.itemCostReportTotalCount}',
                  Iconsax.calendar_tick,
                  Colors.orange,
                ),

                _buildSummaryItem(
                  'Page',
                  '${state.itemCostReportPage}/${state.itemCostReportTotalPages}',
                  Iconsax.document,
                  Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (state.status == ItemCostStatus.loadingMoreItemCostReport)
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

  Widget _buildLotList(ItemCostState state) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 700;
    final cardSpacing = screenHeight * 0.02;
    final cardWidth = isSmallScreen ? screenWidth * 0.85 : screenWidth * 0.8;

    if (state.status == ItemCostStatus.loadingItemCostReport &&
        state.itemCostReportItems.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading Item cost report...'),
          ],
        ),
      );
    }

    if (state.status == ItemCostStatus.failure &&
        state.itemCostReportItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              state.errorMessage!.isNotEmpty
                  ? state.errorMessage!
                  : 'Failed to load item cost report',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final companyId = widget.authBloc.state.companyId;
                if (companyId != null) {
                  context.read<ItemCostBloc>().add(
                    LoadItemCostReport(companyId: companyId),
                  );
                }
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.itemCostReportItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.calendar_tick, size: 64, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              'No item cost found',
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
            state.itemCostReportItems.length +
            (state.itemCostReportItems.isEmpty ? 1 : 0),
        separatorBuilder: (context, index) => SizedBox(height: cardSpacing),
        itemBuilder: (context, index) {
          if (index >= state.itemCostReportItems.length) {
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

          final lot = state.itemCostReportItems[index];

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
    ItemCost itemCost,
    ItemCostState state,
    int index,
    bool isCompact,
    double cardWidth,
    double screenHeight,
  ) {
    // final offset = _dragOffset[index] ?? 0.0;
    final isExpanded = _itemCostDetail == true && _selectedItemCost == itemCost;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    // For responsiveness:
    final collapsedHeight = isCompact
        ? screenHeight * 0.14
        : screenHeight * 0.6;
    final expandedHeight = isCompact ? screenHeight * 0.4 : screenHeight * 0.35;

    return GestureDetector(
      onTap: () =>
          isExpanded ? _hideItemCostDetail() : _showItemCostDetail(itemCost),
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
                      _buildLotAvatar(itemCost, isCompact),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  itemCost.itemRef?.itemDescription ?? 'N/A',
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
                            if (itemCost.amountUnitCost != null)
                              _buildItemUnitCost(itemCost),
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
                            ? _hideItemCostDetail()
                            : _showItemCostDetail(itemCost),
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
                  child: _buildItemCostDetailContent(itemCost, isCompact),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCostDetailContent(ItemCost itemCost, bool isCompact) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildDetailItem(
            'Item ID: ',
            itemCost.itemRef?.itemsId ?? 'N/A',
            Iconsax.tag,
            isCompact,
          ),
          _buildDetailItem(
            'Item Description: ',
            itemCost.itemRef?.itemDescription ?? 'N/A',
            Iconsax.box,
            isCompact,
          ),
          _buildDetailItem(
            'Unit Cost: ',
            itemCost.amountUnitCost != null
                ? '${itemCost.amountUnitCost!.toStringAsFixed(2)} Birr'
                : 'N/A',
            Iconsax.dollar_circle,
            isCompact,
          ),
          _buildDetailItem(
            'Unit of Measure: ',
            itemCost.itemRef?.unitOfMeasureDescription?.description1 ?? 'N/A',
            Iconsax.dollar_circle,
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

  Widget _buildLotAvatar(ItemCost itemCost, bool isCompact) {
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

  Widget _buildItemUnitCost(ItemCost itemCost) {
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
            '${itemCost.amountUnitCost.toString()} Birr/ ${itemCost.itemRef?.unitOfMeasureDescription?.description1}',
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
}
