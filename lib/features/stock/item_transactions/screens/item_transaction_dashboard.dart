import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:savvy_stock/core/constants/app_routes.dart';
import 'package:savvy_stock/core/utils/ui_helper.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/stock/item_transactions/blocs/item_transaction_bloc.dart';
import 'package:savvy_stock/features/stock/item_transactions/blocs/item_transaction_event.dart';
import 'package:savvy_stock/features/stock/item_transactions/blocs/item_transaction_state.dart';
import 'package:savvy_stock/features/stock/item_transactions/model/item_transaction_model.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_bloc.dart';

class ItemTransactionsListPage extends StatefulWidget {
  final AuthBloc authBloc;
  const ItemTransactionsListPage({super.key, required this.authBloc});

  @override
  State<ItemTransactionsListPage> createState() =>
      _ItemTransactionsListPageState();
}

class _ItemTransactionsListPageState extends State<ItemTransactionsListPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSelectionMode = false;
  final Map<int, double> _dragOffset = {};

  // Animation controllers for detail panel
  late AnimationController _detailAnimationController;
  late Animation<double> _heightAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  // Detail panel state
  ItemTransactionModel? _selectedTransaction;
  bool _transactionDetail = false;

  int? decmialPlace;

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

    // Load transactions
    context.read<ItemTransactionsBloc>().add(
      LoadItemTransactions(companyId: widget.authBloc.state.companyId!),
    );
    decmialPlace = context
        .read<SystemConstantBloc>()
        .state
        .selected
        ?.decimalPlaces;
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

  void _handleSearch(String query) {
    context.read<ItemTransactionsBloc>().add(
      FilterItemTransactions(query: query),
    );
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<ItemTransactionsBloc>().add(FilterItemTransactions(query: ''));
  }

  void _toggleTransactionSelection(
    ItemTransactionModel transaction,
    bool selected,
  ) {
    context.read<ItemTransactionsBloc>().add(
      SelectItemTransaction(transaction),
    );
  }

  void _showTransactionDetail(ItemTransactionModel transaction) {
    setState(() {
      _selectedTransaction = transaction;
      _transactionDetail = true;
    });

    // Start the animation
    _detailAnimationController.forward(from: 0.0);
  }

  void _hideTransactionDetail() {
    // Reverse the animation
    _detailAnimationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _transactionDetail = false;
          _selectedTransaction = null;
        });
      }
    });
  }

  void _clearSelection() {
    context.read<ItemTransactionsBloc>().add(ClearSelection());
    setState(() {
      _isSelectionMode = false;
    });
  }

  void _refreshList() {
    context.read<ItemTransactionsBloc>().add(
      LoadItemTransactions(companyId: widget.authBloc.state.companyId!),
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Transactions refreshed')));
  }

  void _exportToExcel() {
    final bloc = context.read<ItemTransactionsBloc>();
    final state = bloc.state;

    if (state.selectedItems.isNotEmpty) {
      bloc.add(ExportTransactions(state.selectedItems, 'excel'));
    } else {
      bloc.add(ExportTransactions(state.transactions, 'excel'));
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Exporting to Excel...')));
  }

  void _exportToCSV() {
    final bloc = context.read<ItemTransactionsBloc>();
    final state = bloc.state;

    if (state.selectedItems.isNotEmpty) {
      bloc.add(ExportTransactions(state.selectedItems, 'csv'));
    } else {
      bloc.add(ExportTransactions(state.transactions, 'csv'));
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Exporting to CSV...')));
  }

  void _navigateToCreateScreen() {
    context.read<ItemTransactionsBloc>().add(PrepareCreate());
    context.push(AppRoutes.inventoryTransactionCreate);
  }

  void _navigateToEditScreen(ItemTransactionModel transaction) {
    context.push(AppRoutes.inventoryTransactionEdit, extra: transaction);
  }

  void _safeDelete(BuildContext context, {int? index}) {
    final bloc = context.read<ItemTransactionsBloc>();
    final state = bloc.state;

    // CASE 1: Multiple transactions
    if (state.selectedItems.isNotEmpty) {
      final transactionsToDelete = state.selectedItems;

      showDeleteDialog(
        context,
        title: 'Delete selected transactions?',
        content:
            'Are you sure you want to delete ${transactionsToDelete.length} transactions?',
        onConfirm: () {
          final ids = transactionsToDelete.map((e) => e.id).toList();
          final deletedIndexes = transactionsToDelete
              .map((trans) => state.transactions.indexOf(trans))
              .toList();
          bloc.add(DeleteMultipleItemTransactions(transactionsToDelete));
        },
      );
      return;
    }

    // CASE 2: Single transaction by index
    if (index == null ||
        index < 0 ||
        index >= state.filteredTransactions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete transaction. Invalid index.'),
        ),
      );
      return;
    }

    final transactionToDelete = state.filteredTransactions[index];

    showDeleteDialog(
      context,
      title: 'Delete Transaction #${transactionToDelete.transactionNumber}?',
      content:
          'Are you sure you want to delete transaction #${transactionToDelete.transactionNumber}?',
      onConfirm: () {
        bloc.add(DeleteItemTransaction(transactionToDelete));
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
        _safeDelete(context, index: index);
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
        title: const Text('Inventory Transactions'),
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
      body: BlocConsumer<ItemTransactionsBloc, ItemTransactionsState>(
        listener: (context, state) {
          if (state.selectedItems.isNotEmpty && !_isSelectionMode) {
            setState(() {
              _isSelectionMode = true;
            });
          } else if (state.selectedItems.isEmpty && _isSelectionMode) {
            setState(() {
              _isSelectionMode = false;
            });
          }

          if (state.status == ItemTransactionsStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.successmessage ?? 'Operation completed successfully',
                ),
                backgroundColor: Colors.green,
              ),
            );
          }

          if (state.status == ItemTransactionsStatus.error) {
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
                  _buildActionButtons(state),

                  // Transactions List
                  Expanded(child: _buildTransactionsList(state)),
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
                hintText: 'Search by transaction number, item, store...',
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
              onChanged: _handleSearch,
            ),
          ),
          const SizedBox(width: 12),
          _buildFloatingActionButton(context),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ItemTransactionsState state) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: state.selectedItems.isNotEmpty ? 60 : 0,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: state.selectedItems.isNotEmpty
          ? Row(
              children: [
                Text(
                  '${state.selectedItems.length} selected',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Iconsax.trash, color: Colors.red),
                  onPressed: () => _safeDelete(context),
                  tooltip: 'Delete selected',
                ),
                IconButton(
                  icon: const Icon(
                    Iconsax.edit,
                    color: Color.fromARGB(255, 28, 66, 146),
                  ),
                  onPressed: () {
                    final transaction = state.selectedItems.first;
                    _navigateToEditScreen(transaction);
                  },
                  tooltip: 'Edit transaction',
                ),
                IconButton(
                  icon: const Icon(Iconsax.close_circle),
                  onPressed: () => _clearSelection(),
                  tooltip: 'Clear selection',
                ),
              ],
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return BlocBuilder<ItemTransactionsBloc, ItemTransactionsState>(
      builder: (context, state) {
        return ElevatedButton(
          onPressed: () {
            if (state.selectedItems.isNotEmpty) {
              // Navigate to edit screen with selected transaction
              final transaction = state.selectedItems.first;
              _navigateToEditScreen(transaction);
            } else {
              // Navigate to create screen
              _navigateToCreateScreen();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 28, 66, 146),
            shape: const CircleBorder(),
          ),
          child: Icon(
            state.selectedItems.isNotEmpty ? Icons.edit : Icons.add,
            color: Colors.white,
          ),
        );
      },
    );
  }

  Widget _buildTransactionsList(ItemTransactionsState state) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 700;
    final cardSpacing = screenHeight * 0.02;
    final cardWidth = isSmallScreen ? screenWidth * 0.85 : screenWidth * 0.8;

    if (state.status == ItemTransactionsStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == ItemTransactionsStatus.failure) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              state.error ?? 'Failed to load transactions',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<ItemTransactionsBloc>().add(
                LoadItemTransactions(
                  companyId: widget.authBloc.state.companyId!,
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.filteredTransactions.isEmpty) {
      final query = state.searchQuery ?? '';
      final hasQuery = query.isNotEmpty;

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.receipt, size: 64, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              !hasQuery ? 'No transactions found' : 'No results for "$query"',
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
        itemCount: state.filteredTransactions.length,
        separatorBuilder: (context, index) => SizedBox(height: cardSpacing),
        itemBuilder: (context, index) {
          final transaction = state.filteredTransactions[index];
          final isSelected = state.selectedItems.contains(transaction);

          return _buildTransactionListItem(
            transaction,
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

  Widget _buildTransactionListItem(
    ItemTransactionModel transaction,
    bool isSelected,
    ItemTransactionsState state,
    int index,
    bool isCompact,
    double cardWidth,
  ) {
    final offset = _dragOffset[index] ?? 0.0;
    final isExpanded =
        _transactionDetail == true && _selectedTransaction == transaction;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // For responsiveness:
    final collapsedHeight = isCompact
        ? screenHeight * 0.20
        : screenHeight * 0.14;

    final expandedHeight = isCompact
        ? screenHeight * 0.55
        : screenHeight * 0.45;
    final collapsedWidth = isCompact ? screenWidth * 0.92 : screenWidth * 0.8;

    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          _toggleTransactionSelection(transaction, !isSelected);
        } else {
          // Single tap shows detail when not in selection mode
          _showTransactionDetail(transaction);
        }
      },
      onLongPress: () {
        if (!_isSelectionMode) {
          setState(() {
            _isSelectionMode = true;
          });
        }
        _toggleTransactionSelection(transaction, !isSelected);
      },
      onDoubleTap: () => _showTransactionDetail(transaction),
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

              // 3. TRANSACTION CARD - Should come AFTER delete indicator
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
                        // Transaction Avatar
                        _buildTransactionAvatar(
                          transaction,
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
                                    'Txn - ${transaction.transactionNumber ?? 'N/A'}',
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
                                      color: _getTransactionTypeColor(
                                        transaction
                                            .transactionTypeDetail
                                            ?.detailCode,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _getTransactionTypeBorderColor(
                                          transaction
                                              .transactionTypeDetail
                                              ?.detailCode,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      transaction
                                              .transactionTypeDetail
                                              ?.description1 ??
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
                                transaction.item?.itemDescription ??
                                    'Item ${transaction.itemNumber}',
                                style: TextStyle(
                                  color: const Color(0xFF887F7F),
                                  fontSize: isCompact ? 12 : 14,
                                  fontStyle: FontStyle.italic,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w300,
                                ),
                              ),

                              // Quantity and amount
                              Row(
                                children: [
                                  Text(
                                    'Qty: ${transaction.quantityTransaction} ,',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    NumberFormat.currency(
                                      decimalDigits: decmialPlace,
                                      symbol: 'ETB ',
                                    ).format(transaction.amountCost),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.w500,
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
                              ? _hideTransactionDetail()
                              : _showTransactionDetail(transaction),
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
                    child: _buildTransactionDetailContent(
                      transaction,
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

  Widget _buildTransactionDetailContent(
    ItemTransactionModel transaction,
    bool isCompact,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildTransactionInfoItem(
            'Transaction No : ',
            transaction.transactionNumber?.toString() ?? 'N/A',
            Iconsax.receipt,
            isCompact,
          ),
          _buildTransactionInfoItem(
            'Transaction Type : ',
            transaction.transactionTypeDetail?.description1 ?? 'N/A',
            Iconsax.receipt_edit,
            isCompact,
          ),
          _buildTransactionInfoItem(
            'Item : ',
            transaction.item?.itemDescription ??
                'Item ${transaction.itemNumber}',
            Iconsax.box,
            isCompact,
          ),
          _buildTransactionInfoItem(
            'Store : ',
            transaction.branchDetail?.description ??
                'Store ${transaction.branch}',
            Iconsax.shop,
            isCompact,
          ),
          _buildTransactionInfoItem(
            'Transaction Date : ',
            _formatDateTime(transaction.dateCreated),
            Iconsax.calendar,
            isCompact,
          ),
          if (transaction.lotNumber != null)
            _buildTransactionInfoItem(
              'Lot Number : ',
              transaction.lotNumber?.toString() ?? 'N/A',
              Iconsax.tag,
              isCompact,
            ),
          if (transaction.lotNumberRef?.batchNumberSupplier != null)
            _buildTransactionInfoItem(
              'Batch Number : ',
              transaction.lotNumberRef?.batchNumberSupplier ?? 'N/A',
              Iconsax.barcode,
              isCompact,
            ),
          if (transaction.supplier != null)
            _buildTransactionInfoItem(
              'Supplier : ',
              transaction.supplierDetail?.supplierName ??
                  'Supplier ${transaction.supplier}',
              Iconsax.profile_2user,
              isCompact,
            ),
          if (transaction.customer != null)
            _buildTransactionInfoItem(
              'Customer : ',
              transaction.customerDetail?.customerName ??
                  'Customer ${transaction.customer}',
              Iconsax.profile_circle,
              isCompact,
            ),
          _buildTransactionInfoItem(
            'Transaction Quantity : ',
            transaction.quantityTransaction.toString(),
            Iconsax.weight,
            isCompact,
          ),
          _buildTransactionInfoItem(
            'UoM : ',
            transaction.unitOfMeasureDetail?.description1 ?? 'N/A',
            Iconsax.rulerpen,
            isCompact,
          ),
          _buildTransactionInfoItem(
            'Amount Cost : ',
            NumberFormat.currency(
              decimalDigits: decmialPlace,
              symbol: 'ETB ',
            ).format(transaction.amountCost),
            Iconsax.dollar_circle,
            isCompact,
          ),
          if (transaction.orderTypeDetail != null)
            _buildTransactionInfoItem(
              'Order Type : ',
              transaction.orderTypeDetail?.description1 ?? 'N/A',
              Iconsax.receipt_item,
              isCompact,
            ),
          if (transaction.remark != null && transaction.remark!.isNotEmpty)
            _buildTransactionInfoItem(
              'Remark : ',
              transaction.remark!,
              Iconsax.note,
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
                  () => _showTransactionDetail(
                    transaction,
                  ), // This would show even more details
                  isCompact,
                ),
                _buildActionButton(
                  Iconsax.export,
                  'Export',
                  () => _exportToExcel(), // Export this single transaction
                  isCompact,
                ),
                _buildActionButton(
                  Iconsax.repeat,
                  'Duplicate',
                  () =>
                      _navigateToCreateScreen(), // Would pre-fill with this transaction's data
                  isCompact,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionInfoItem(
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

  Widget _buildTransactionAvatar(
    ItemTransactionModel transaction,
    bool isSelected,
    bool isCompact,
  ) {
    final Color backgroundColor;
    final Color iconColor;

    if (isSelected) {
      backgroundColor = const Color.fromARGB(255, 28, 66, 146);
      iconColor = Colors.white;
    } else if (transaction.adjustToIncrease == true) {
      backgroundColor = Colors.grey[200]!;
      iconColor = Colors.green;
    } else if (transaction.adjustToIncrease == false) {
      backgroundColor = Colors.grey[200]!;
      iconColor = Colors.red;
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
  Color _getTransactionTypeColor(String? transactionType) {
    switch (transactionType) {
      case 'A': // Adjustment
        return Colors.orange;
      case 'I': // Issue
        return Colors.red;
      case 'T': // Transfer
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getTransactionTypeBorderColor(String? transactionType) {
    switch (transactionType) {
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

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
  }
}
