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

class CashOutFlowReportPage extends StatefulWidget {
  final AuthBloc authBloc;
  const CashOutFlowReportPage({super.key, required this.authBloc});

  @override
  State<CashOutFlowReportPage> createState() => _CashOutFlowReportPageState();
}

class _CashOutFlowReportPageState extends State<CashOutFlowReportPage> {
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
    print('CashOutFlowPage: Loading initial data. CompanyID: $companyId');
    if (companyId != null) {
      context.read<CashFlowBloc>().add(
        LoadCashOutFlowReport(
          companyId: companyId,
          filters: const SalesTransactionReportFilters(),
          pageSize: 20,
        ),
      );
    } else {
      print('CashOutFlowPage: CompanyID is null!');
    }
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
      final state = context.read<CashFlowBloc>().state;
      if (state.hasMoreCashOutFlowReport &&
          state.status != CashFlowStatus.loadingMoreCashOutFlowReport) {
        context.read<CashFlowBloc>().add(const LoadMoreCashOutFlowReport());
      }
    }
  }

  void _showFilterDialog() async {
    final currentFilters = context
        .read<CashFlowBloc>()
        .state
        .cashOutFlowReportFilters;
    final result = await showDialog<SalesTransactionReportFilters>(
      context: context,
      builder: (context) => CashFlowFilterDialog(
        currentFilters: currentFilters,
        authBloc: widget.authBloc,
      ),
    );

    if (result != null) {
      context.read<CashFlowBloc>().add(UpdateCashOutFlowReportFilters(result));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Cash Outflow Report',
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
                ExportCashOutFlowReportToExcel(state.cashOutFlowReportFilters),
              );
            },
            tooltip: 'Export to Excel',
          ),
        ],
      ),
      body: BlocConsumer<CashFlowBloc, CashFlowState>(
        listener: (context, state) {
          if (state.exportCashOutFlowReportMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.exportCashOutFlowReportMessage!)),
            );
          }
          if (state.status == CashFlowStatus.error && state.error != null) {
            print('CashOutFlowPage: Error state: ${state.error}');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${state.error}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          print(
            'CashOutFlowPage: Rebuild. Status: ${state.status}, Totals: ${state.cashOutFlowReportTotals?.totalCount}, ListSize: ${state.cashOutFlowReport.length}',
          );
          return BlocBuilder<SystemConstantBloc, SystemConstantState>(
            builder: (context, systemState) {
              final systemConstant = systemState.systemConstants.isNotEmpty
                  ? systemState.systemConstants.first
                  : null;
              final currencySymbol = systemConstant?.currencyCode ?? '\$';

              if (state.status == CashFlowStatus.loadingCashOutFlowReport &&
                  state.cashOutFlowReport.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Summary Cards
                    _buildSummaryCards(state, currencySymbol),
                    const SizedBox(height: 16),
                    if (state.status == CashFlowStatus.error)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          state.error ?? 'Unknown Error',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),

                    // Main Content (Responsive)
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
                        CashFlowStatus.loadingMoreCashOutFlowReport)
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
    );
  }

  Widget _buildSummaryCards(CashFlowState state, String currencySymbol) {
    final totals = state.cashOutFlowReportTotals;
    if (totals == null) return const SizedBox.shrink();
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Count',
                    '${totals.totalCount}',
                    Iconsax.document_text,
                    Colors.purple,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Page',
                    '${state.cashOutFlowReportPage}/${state.cashOutFlowReportTotalPages}',
                    Iconsax.document,
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
                    'Total Credit',
                    '$currencySymbol ${_currencyFormat.format(totals.totalCredit)}',
                    Iconsax.money_send,
                    Colors.green,
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

  // ==========================================================================
  // DESKTOP TABLE VIEW
  // ==========================================================================

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
                    'Type',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Purchase Type',
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
              rows: state.cashOutFlowReport.map((item) {
                return DataRow(
                  cells: [
                    DataCell(Text(_dateFormat.format(item.date))),
                    DataCell(
                      Row(
                        children: [
                          Icon(
                            Iconsax.document_text,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            item.reference,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: item.orderType == 'Purchase'
                              ? Colors.blue.withOpacity(0.1)
                              : Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item.orderType,
                          style: TextStyle(
                            color: item.orderType == 'Purchase'
                                ? Colors.blue
                                : Colors.purple,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        item.cashCredit.isNotEmpty == true
                            ? item.cashCredit
                            : '-',
                      ),
                    ),
                    DataCell(
                      Text(
                        '$currencySymbol ${_currencyFormat.format(item.amount)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green, // Inflow is always positive
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

  // ==========================================================================
  // MOBILE LIST VIEW
  // ==========================================================================

  Widget _buildMobileList(
    CashFlowState state,
    String currencySymbol,
    BoxConstraints constraints,
  ) {
    return ListView.separated(
      controller: _scrollController,
      itemCount: state.cashOutFlowReport.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = state.cashOutFlowReport[index];
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
                      color: item.orderType == 'Purchase'
                          ? Colors.blue.withOpacity(0.1)
                          : Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.orderType,
                      style: TextStyle(
                        color: item.orderType == 'Purchase'
                            ? Colors.blue
                            : Colors.purple,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.reference,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        if (item.cashCredit.isNotEmpty == true)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              'Type: ${item.cashCredit}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    '$currencySymbol ${_currencyFormat.format(item.amount)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green,
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
