import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/reports/cash_flow/bloc/cash_flow_bloc.dart';
import 'package:savvy_stock/features/reports/cash_flow/bloc/cash_flow_event.dart';
import 'package:savvy_stock/features/reports/cash_flow/bloc/cash_flow_state.dart';
import 'package:savvy_stock/features/reports/cash_flow/sidebar/widgets/cash_flow_filter_dialog.dart';
import 'package:savvy_stock/features/sales/sales_order/header/model/sales_transaction_filtering_model.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_bloc.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_state.dart';

class CashFlowSummaryReportPage extends StatefulWidget {
  final AuthBloc authBloc;
  const CashFlowSummaryReportPage({super.key, required this.authBloc});

  @override
  State<CashFlowSummaryReportPage> createState() =>
      _CashFlowSummaryReportPageState();
}

class _CashFlowSummaryReportPageState extends State<CashFlowSummaryReportPage> {
  final ScrollController _scrollController = ScrollController();
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
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
    super.dispose();
  }

  void _loadInitialData() {
    final companyId = widget.authBloc.state.companyId;
    if (companyId != null) {
      context.read<CashFlowBloc>().add(
        LoadCashFlowSummaryReport(
          companyId: companyId,
          filters: const SalesTransactionReportFilters(),
          pageSize: 20,
        ),
      );
    }
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
      final state = context.read<CashFlowBloc>().state;
      if (state.hasMoreCashFlowSummaryReport &&
          state.status != CashFlowStatus.loadingMoreCashFlowSummaryReport) {
        context.read<CashFlowBloc>().add(const LoadMoreCashFlowSummaryReport());
      }
    }
  }

  void _showFilterDialog() async {
    final currentFilters = context
        .read<CashFlowBloc>()
        .state
        .cashFlowSummaryReportFilters;
    final result = await showDialog<SalesTransactionReportFilters>(
      context: context,
      builder: (context) => CashFlowFilterDialog(
        currentFilters: currentFilters,
        authBloc: widget.authBloc,
      ),
    );

    if (result != null) {
      context.read<CashFlowBloc>().add(
        UpdateCashFlowSummaryReportFilters(result),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Cash Flow Summary',
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
            icon: const Icon(Iconsax.export),
            onPressed: () {
              final state = context.read<CashFlowBloc>().state;
              context.read<CashFlowBloc>().add(
                ExportCashFlowSummaryReportToExcel(
                  state.cashFlowSummaryReportFilters,
                ),
              );
            },
            tooltip: 'Export to Excel',
          ),
        ],
      ),
      body: SafeArea(
        child: BlocConsumer<CashFlowBloc, CashFlowState>(
          listener: (context, state) {
            if (state.exportCashFlowSummaryReportMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.exportCashFlowSummaryReportMessage!),
                ),
              );
            }
            if (state.status == CashFlowStatus.error && state.error != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${state.error}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            return BlocBuilder<SystemConstantBloc, SystemConstantState>(
              builder: (context, systemState) {
                final systemConstant = systemState.systemConstants.isNotEmpty
                    ? systemState.systemConstants.first
                    : null;
                final currencySymbol = systemConstant?.currencyCode ?? '\$';

                if (state.status ==
                        CashFlowStatus.loadingCashFlowSummaryReport &&
                    state.cashFlowSummaryReport.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Summary Cards
                      _buildSummaryCards(state, currencySymbol),
                      const SizedBox(height: 16),

                      // Main Content
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth > 600) {
                              return _buildDesktopTable(
                                state,
                                currencySymbol,
                                constraints,
                              );
                            } else {
                              return _buildMobileList(
                                state,
                                currencySymbol,
                                constraints,
                              );
                            }
                          },
                        ),
                      ),

                      // Loading More Indicator
                      if (state.status ==
                          CashFlowStatus.loadingMoreCashFlowSummaryReport)
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

  Widget _buildSummaryCards(CashFlowState state, String currencySymbol) {
    final totals = state.cashFlowSummaryReportTotals;
    if (totals == null) return const SizedBox.shrink();
    return Card(
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
                    'Inflow',
                    '$currencySymbol ${_currencyFormat.format(totals.totalInflow)}',
                    Iconsax.arrow_up,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Outflow',
                    '$currencySymbol ${_currencyFormat.format(totals.totalOutflow)}',
                    Iconsax.arrow_down,
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Net Cash Flow',
                    '$currencySymbol ${_currencyFormat.format(totals.netCashFlow)}',
                    Iconsax.wallet_check,
                    totals.netCashFlow >= 0 ? Colors.blue : Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Total History',
                    '${totals.totalCount}',
                    Iconsax.task,
                    Colors.purple,
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
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDesktopTable(
    CashFlowState state,
    String currencySymbol,
    BoxConstraints constraints,
  ) {
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
              dataRowHeight: 60,
              columnSpacing: 24,
              horizontalMargin: 24,
              columns: const [
                DataColumn(
                  label: Text(
                    'Date',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Reference',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Category',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Type',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Amount',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  numeric: true,
                ),
              ],
              rows: state.cashFlowSummaryReport.map((item) {
                final isInflow =
                    item.orderType == 'Sales' ||
                    item.orderType == 'Other Income';
                return DataRow(
                  cells: [
                    DataCell(Text(_dateFormat.format(item.date))),
                    DataCell(Text(item.reference)),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isInflow
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isInflow ? 'Inflow' : 'Outflow',
                          style: TextStyle(
                            color: isInflow ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    DataCell(Text(item.orderType)),
                    DataCell(
                      Text(
                        '${isInflow ? "+" : "-"}$currencySymbol ${_currencyFormat.format(item.amount)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isInflow ? Colors.green : Colors.red,
                        ),
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

  Widget _buildMobileList(
    CashFlowState state,
    String currencySymbol,
    BoxConstraints constraints,
  ) {
    return ListView.separated(
      controller: _scrollController,
      itemCount: state.cashFlowSummaryReport.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = state.cashFlowSummaryReport[index];
        final isInflow =
            item.orderType == 'Sales' || item.orderType == 'Other Income';
        return Container(
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
                      color: isInflow
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.orderType,
                      style: TextStyle(
                        color: isInflow ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    _dateFormat.format(item.date),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.reference,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${isInflow ? "+" : "-"}$currencySymbol ${_currencyFormat.format(item.amount)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isInflow ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
