import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/purchase/other_expenses/bloc/other_expenses_bloc.dart';
import 'package:savvy_stock/features/purchase/other_expenses/screens/widgets/other_expense_filter_dialog.dart';
import 'package:savvy_stock/features/purchase/other_expenses/screens/widgets/other_expense_form_dialog.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/models/other_expenses.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_bloc.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_state.dart';

class OtherExpensesDashboard extends StatefulWidget {
  final AuthBloc authBloc;
  const OtherExpensesDashboard({super.key, required this.authBloc});

  @override
  State<OtherExpensesDashboard> createState() => _OtherExpensesDashboardState();
}

class _OtherExpensesDashboardState extends State<OtherExpensesDashboard> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '');

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    final companyId = widget.authBloc.state.companyId;
    if (companyId != null) {
      context.read<OtherExpensesBloc>().add(
        const LoadPaginatedExpenses(page: 1, pageSize: 20),
      );
    }
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
      final state = context.read<OtherExpensesBloc>().state;
      if (state.hasMore && state.status != OtherExpensesStatus.loading) {
        context.read<OtherExpensesBloc>().add(
          LoadPaginatedExpenses(
            page: state.currentPage + 1,
            pageSize: 20,
            dateFrom: state.dateFrom,
            dateTo: state.dateTo,
          ),
        );
      }
    }
  }

  void _showFilterDialog() {
    final state = context.read<OtherExpensesBloc>().state;
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<OtherExpensesBloc>(),
        child: OtherExpenseFilterDialog(
          initialDateFrom: state.dateFrom,
          initialDateTo: state.dateTo,
        ),
      ),
    );
  }

  void _showCreateDialog() {
    context.read<OtherExpensesBloc>().add(const PrepareCreateExpense());
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<OtherExpensesBloc>(),
        child: const OtherExpenseFormDialog(),
      ),
    );
  }

  void _showEditDialog(OtherExpense expense) {
    context.read<OtherExpensesBloc>().add(PrepareEditExpense(expense));
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<OtherExpensesBloc>(),
        child: OtherExpenseFormDialog(expense: expense),
      ),
    );
  }

  void _deleteExpense(OtherExpense expense) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
          'Are you sure you want to delete this expense of ${_currencyFormat.format(expense.paymentAmount ?? 0)} ETB?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              if (expense.id != null) {
                context.read<OtherExpensesBloc>().add(
                  DeleteOtherExpense(expense.id!),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _updateCosts() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Update Item Costs'),
        content: const Text(
          'This will distribute the overhead costs to all item costs. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<OtherExpensesBloc>().add(
                const UpdateItemCostsByOverheadCosts(),
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _refreshList() {
    context.read<OtherExpensesBloc>().add(const RefreshList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Other Expenses',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1C4292),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.filter),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
          IconButton(
            icon: const Icon(Iconsax.refresh),
            onPressed: _refreshList,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Iconsax.money_send),
            onPressed: _updateCosts,
            tooltip: 'Update Item Costs',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        backgroundColor: const Color(0xFF1C4292),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: BlocConsumer<OtherExpensesBloc, OtherExpensesState>(
          listener: (context, state) {
            if (state.status == OtherExpensesStatus.error &&
                state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${state.errorMessage}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            if (state.status == OtherExpensesStatus.loaded &&
                state.errorMessage == null) {
              // Success case - could show a success message if needed
            }
          },
          builder: (context, state) {
            return BlocBuilder<SystemConstantBloc, SystemConstantState>(
              builder: (context, systemState) {
                final systemConstant = systemState.systemConstants.isNotEmpty
                    ? systemState.systemConstants.first
                    : null;
                final currencySymbol = systemConstant?.currencyCode ?? 'ETB';
                final decimalPlaces = systemConstant?.decimalPlaces ?? 2;

                if (state.status == OtherExpensesStatus.loading &&
                    state.items.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Summary Card
                      _buildSummaryCard(state, currencySymbol, decimalPlaces),
                      const SizedBox(height: 16),

                      // Main Content
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth > 600) {
                              return _buildDesktopTable(
                                state,
                                currencySymbol,
                                decimalPlaces,
                                constraints,
                              );
                            } else {
                              return _buildMobileList(
                                state,
                                currencySymbol,
                                decimalPlaces,
                              );
                            }
                          },
                        ),
                      ),

                      // Loading More Indicator
                      if (state.status == OtherExpensesStatus.loading &&
                          state.items.isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    OtherExpensesState state,
    String currencySymbol,
    int decimalPlaces,
  ) {
    final totalAmount = state.items.fold<double>(
      0,
      (sum, item) => sum + (item.paymentAmount ?? 0),
    );

    return Card(
      margin: const EdgeInsets.all(6),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryItem(
              'Total Records',
              state.totalCount.toString(),
              Iconsax.document_text,
              Colors.purple,
            ),
            _buildSummaryItem(
              'Page',
              '${state.currentPage}/${state.totalPages}',
              Iconsax.document,
              Colors.blue,
            ),
            _buildSummaryItem(
              'Total Amount',
              '$currencySymbol ${totalAmount.toStringAsFixed(decimalPlaces)}',
              Iconsax.money_send,
              Colors.green,
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

  // Desktop Table View
  Widget _buildDesktopTable(
    OtherExpensesState state,
    String currencySymbol,
    int decimalPlaces,
    BoxConstraints constraints,
  ) {
    if (state.items.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          controller: _scrollController,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(Colors.grey[50]),
              dataRowMinHeight: 60,
              dataRowMaxHeight: 80,
              columnSpacing: 24,
              horizontalMargin: 24,
              columns: const [
                DataColumn(
                  label: Text(
                    'Amount',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  numeric: true,
                ),
                DataColumn(
                  label: Text(
                    'Date',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Reason',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Actions',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              rows: state.items.map((item) {
                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        '$currencySymbol ${(item.paymentAmount ?? 0).toStringAsFixed(decimalPlaces)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataCell(
                      Text(
                        item.datePayment != null
                            ? _dateFormat.format(item.datePayment!)
                            : 'N/A',
                      ),
                    ),
                    DataCell(
                      Text(
                        item.reasonDescription ?? 'No description',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Iconsax.edit, color: Colors.blue),
                            onPressed: () => _showEditDialog(item),
                            tooltip: 'Edit',
                          ),
                          IconButton(
                            icon: const Icon(Iconsax.trash, color: Colors.red),
                            onPressed: () => _deleteExpense(item),
                            tooltip: 'Delete',
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  // Mobile List View
  Widget _buildMobileList(
    OtherExpensesState state,
    String currencySymbol,
    int decimalPlaces,
  ) {
    if (state.items.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      controller: _scrollController,
      itemCount: state.items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = state.items[index];
        return Dismissible(
          key: Key(item.id?.toString() ?? index.toString()),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Text('Confirm Delete'),
                content: const Text(
                  'Are you sure you want to delete this expense?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          },
          onDismissed: (direction) {
            if (item.id != null) {
              context.read<OtherExpensesBloc>().add(
                DeleteOtherExpense(item.id!),
              );
            }
          },
          child: InkWell(
            onTap: () => _showEditDialog(item),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$currencySymbol ${(item.paymentAmount ?? 0).toStringAsFixed(decimalPlaces)}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Text(
                        item.datePayment != null
                            ? _dateFormat.format(item.datePayment!)
                            : 'N/A',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item.reasonDescription ?? 'No description',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.receipt, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No expenses found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add a new expense',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
