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

class CashInflowReportPage extends StatefulWidget {
  final AuthBloc authBloc;
  const CashInflowReportPage({super.key, required this.authBloc});

  @override
  State<CashInflowReportPage> createState() => _CashInflowReportPageState();
}

class _CashInflowReportPageState extends State<CashInflowReportPage> {
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
    print('CashInflowPage: Loading initial data. CompanyID: $companyId');
    if (companyId != null) {
      context.read<CashFlowBloc>().add(
        LoadCashInFlowReport(
          companyId: companyId,
          filters: const SalesTransactionReportFilters(),
          pageSize: 20,
        ),
      );
    } else {
      print('CashInflowPage: CompanyID is null!');
    }
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
      final state = context.read<CashFlowBloc>().state;
      if (state.hasMoreCashInFlowReport &&
          state.status != CashFlowStatus.loadingMoreCashInFlowReport) {
        context.read<CashFlowBloc>().add(const LoadMoreCashInFlowReport());
      }
    }
  }

  void _showFilterDialog() async {
    final currentFilters = context
        .read<CashFlowBloc>()
        .state
        .cashInFlowReportFilters;
    final result = await showDialog<SalesTransactionReportFilters>(
      context: context,
      builder: (context) => CashFlowFilterDialog(
        currentFilters: currentFilters,
        authBloc: widget.authBloc,
      ),
    );

    if (result != null) {
      context.read<CashFlowBloc>().add(UpdateCashInFlowReportFilters(result));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[500],
      appBar: AppBar(
        title: const Text(
          'Cash Inflow Report',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFF1C4292),
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
                ExportCashInFlowReportToExcel(state.cashInFlowReportFilters),
              );
            },
            tooltip: 'Export to Excel',
          ),
        ],
      ),
      body: BlocConsumer<CashFlowBloc, CashFlowState>(
        listener: (context, state) {
          if (state.exportCashInFlowReportMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.exportCashInFlowReportMessage!)),
            );
          }
          if (state.status == CashFlowStatus.error && state.error != null) {
            print('CashInflowPage: Error state: ${state.error}');
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
            'CashInflowPage: Rebuild. Status: ${state.status}, Totals: ${state.cashInFlowReportTotals?.totalCount}, ListSize: ${state.cashInFlowReport.length}',
          );
          return BlocBuilder<SystemConstantBloc, SystemConstantState>(
            builder: (context, systemState) {
              final systemConstant = systemState.systemConstants.isNotEmpty
                  ? systemState.systemConstants.first
                  : null;
              final currencySymbol = systemConstant?.currencyCode ?? '\$';

              if (state.status == CashFlowStatus.loadingCashInFlowReport &&
                  state.cashInFlowReport.isEmpty) {
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
                        CashFlowStatus.loadingMoreCashInFlowReport)
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
    final totals = state.cashInFlowReportTotals;
    if (totals == null) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.all(6),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(6),
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
                    '${state.cashInFlowReportPage}/${state.cashInFlowReportTotalPages}',
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
                    'Total Debit',
                    '$currencySymbol ${_currencyFormat.format(totals.totalDebit)}',
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
                    'Sales Type',
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
              rows: state.cashInFlowReport.map((item) {
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
                          color: item.orderType == 'Sales'
                              ? Colors.blue.withOpacity(0.1)
                              : Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item.orderType,
                          style: TextStyle(
                            color: item.orderType == 'Sales'
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
      itemCount: state.cashInFlowReport.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = state.cashInFlowReport[index];
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
                      color: item.orderType == 'Sales'
                          ? Colors.blue.withOpacity(0.1)
                          : Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.orderType,
                      style: TextStyle(
                        color: item.orderType == 'Sales'
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
