import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:savvy_stock/core/constants/app_routes.dart';
import 'package:savvy_stock/core/utils/ui_helper.dart';
import 'package:savvy_stock/features/FSNMR/blocs/FSNMR_bloc.dart';
import 'package:savvy_stock/features/FSNMR/blocs/FSNMR_event.dart';
import 'package:savvy_stock/features/FSNMR/blocs/FSNMR_state.dart';
import 'package:savvy_stock/features/FSNMR/models/fast_slow_nonmoving_rule.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';

class FSNMRDashboard extends StatefulWidget {
  final AuthBloc authBloc;
  const FSNMRDashboard({super.key, required this.authBloc});

  @override
  State<FSNMRDashboard> createState() => _FSNMRDashboardState();
}

class _FSNMRDashboardState extends State<FSNMRDashboard> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  // Drag offset for swipe-to-delete
  final Map<int, double> _dragOffset = {};

  @override
  void initState() {
    super.initState();
    _loadInitialData();
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
      context.read<FSNMRBloc>().add(LoadRules(companyId));
    }
  }

  Future<void> _navigateToCreateRule() async {
    final result = await context.push(AppRoutes.fsnmrCreate);
    if (result == true) {
      _loadInitialData();
    }
  }

  Future<void> _navigateToEditRule(FastSlowNonMovingRule item) async {
    final result = await context.push(AppRoutes.fsnmrEdit, extra: item);
    if (result == true) {
      _loadInitialData();
    }
  }

  void _onSearchChanged(String query) {
    context.read<FSNMRBloc>().add(SearchRules(query));
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<FSNMRBloc>().add(const SearchRules(''));
  }

  // ========== SWIPE-TO-DELETE HANDLERS ==========

  void _onHorizontalDragUpdate(int index, DragUpdateDetails details) {
    setState(() {
      final current = _dragOffset[index] ?? 0;
      var newOffset = current + details.delta.dx;

      // Only allow left swipe (negative offset)
      if (newOffset > 0) newOffset = 0;
      _dragOffset[index] = newOffset;
    });
  }

  void _onHorizontalDragEnd(
    BuildContext context,
    int index,
    DragEndDetails details,
    FSNMRState state,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final threshold = screenWidth * 0.3;
    final current = _dragOffset[index] ?? 0;

    if (current.abs() > threshold) {
      // Swipe far enough → trigger delete
      setState(() {
        _dragOffset[index] = -screenWidth;
      });

      Future.delayed(const Duration(milliseconds: 300), () {
        _safeDelete(context, index: index, state: state);
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

  void _safeDelete(
    BuildContext context, {
    required int index,
    required FSNMRState state,
  }) {
    if (index < 0 || index >= state.rules.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete rule. Invalid index.')),
      );
      return;
    }

    final ruleToDelete = state.rules[index];
    final reportFreqDesc =
        ruleToDelete.reportFrequencyRef?.description1 ??
        'Rule ${ruleToDelete.id}';

    showDeleteDialog(
      context,
      title: 'Delete "$reportFreqDesc"?',
      content: 'Are you sure you want to delete this rule?',
      onConfirm: () {
        context.read<FSNMRBloc>().add(
          DeleteRule(
            ruleId: ruleToDelete.id!,
            deletedRule: ruleToDelete,
            deletedIndex: index,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Fast SlowNon-Moving Rules',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1C4292),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.add),
            onPressed: _navigateToCreateRule,
            tooltip: 'Create Rule',
          ),
        ],
      ),
      body: SafeArea(
        child: BlocConsumer<FSNMRBloc, FSNMRState>(
          listener: (context, state) {
            if (state.status == FSNMRStatus.failure && state.message != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${state.message}'),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (state.status == FSNMRStatus.success &&
                state.message != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message!),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state.status == FSNMRStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            // use filteredRules which will contain search results
            final displayList = state.filteredRules;

            return Column(
              children: [
                _buildSearchBar(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        if (state.status == FSNMRStatus.failure)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              state.message ?? 'Unknown Error',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),

                        if (displayList.isEmpty)
                          Expanded(
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _searchController.text.isNotEmpty
                                        ? Iconsax.search_status
                                        : Iconsax.chart,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchController.text.isNotEmpty
                                        ? 'No rules found for "${_searchController.text}"'
                                        : 'No rules found',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  if (_searchController.text.isEmpty)
                                    ElevatedButton.icon(
                                      onPressed: _navigateToCreateRule,
                                      icon: const Icon(Iconsax.add),
                                      label: const Text('Create Rule'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF1C4292,
                                        ),
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          )
                        else
                          // Main Content (Responsive)
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                if (constraints.maxWidth > 600) {
                                  return _buildDesktopTable(state, constraints);
                                } else {
                                  return _buildMobileList(state, constraints);
                                }
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
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
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by frequency or days...',
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
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }

  Widget _buildDesktopTable(FSNMRState state, BoxConstraints constraints) {
    // use filteredRules which will contain search results
    final displayList = state.filteredRules;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
              dataRowMinHeight: 50,
              dataRowMaxHeight: 70,
              columnSpacing: 24,
              horizontalMargin: 24,
              columns: const [
                DataColumn(
                  label: Text(
                    'Report Frequency',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Period (Days)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'UOM',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Fast Moving (>)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Slow Moving (<)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Non Moving (=)',
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
              rows: displayList.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return DataRow(
                  onLongPress: () => _navigateToEditRule(item),
                  cells: [
                    DataCell(
                      GestureDetector(
                        onDoubleTap: () => _navigateToEditRule(item),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            item.reportFrequencyRef?.description1 ?? 'UNKNOWN',
                            style: const TextStyle(
                              color: Colors.purple,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        item.periodInDays?.toString() ?? '-',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    DataCell(
                      Text(
                        item.unitOfMeasureDefaultRef?.description1 ?? '-',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    DataCell(
                      Text(
                        item.fastMovementRuleUnit?.toString() ?? '-',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    DataCell(
                      Text(
                        item.slowMovementRuleUnit?.toString() ?? '-',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    DataCell(
                      Text(
                        item.nonMovementRuleUnit?.toString() ?? '-',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Iconsax.edit, size: 20),
                            color: const Color(0xFF1C4292),
                            onPressed: () => _navigateToEditRule(item),
                            tooltip: 'Edit',
                          ),
                          IconButton(
                            icon: const Icon(Iconsax.trash, size: 20),
                            color: Colors.red,
                            onPressed: () => _safeDelete(
                              context,
                              index: index,
                              state: state,
                            ),
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

  Widget _buildMobileList(FSNMRState state, BoxConstraints constraints) {
    // use filteredRules which will contain search results
    final displayList = state.filteredRules;

    return ListView.separated(
      controller: _scrollController,
      itemCount: displayList.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = displayList[index];
        final offset = _dragOffset[index] ?? 0.0;

        return GestureDetector(
          onDoubleTap: () => _navigateToEditRule(item),
          onLongPress: () => _navigateToEditRule(item),
          onHorizontalDragUpdate: (details) =>
              _onHorizontalDragUpdate(index, details),
          onHorizontalDragEnd: (details) =>
              _onHorizontalDragEnd(context, index, details, state),
          child: Stack(
            children: [
              // Delete indicator background (visible when swiping)
              Positioned.fill(
                child: Container(
                  alignment: Alignment.centerRight,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(
                    Iconsax.trash,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),

              // Card content (slides when swiping)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                transform: Matrix4.translationValues(offset, 0, 0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.purple.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                item.reportFrequencyRef?.description1 ??
                                    'Unknown',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.purple,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Period: ${item.periodInDays?.toString() ?? '-'} days',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'UOM: ${item.unitOfMeasureDefaultRef?.description1 ?? '-'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _buildMovementChip(
                              'Fast',
                              item.fastMovementRuleUnit,
                              Colors.green,
                            ),
                            const SizedBox(height: 4),
                            _buildMovementChip(
                              'Slow',
                              item.slowMovementRuleUnit,
                              Colors.orange,
                            ),
                            const SizedBox(height: 4),
                            _buildMovementChip(
                              'Non',
                              item.nonMovementRuleUnit,
                              Colors.red,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMovementChip(String label, double? value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$label: ${value?.toString() ?? '-'}',
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
