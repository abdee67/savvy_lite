import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:savvy_stock/core/constants/app_routes.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_bloc.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_event.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_state.dart';
import 'package:savvy_stock/features/udc_detail/models/udc_details.dart';

class UomDashboard extends StatefulWidget {
  final AuthBloc authBloc;
  const UomDashboard({super.key, required this.authBloc});

  @override
  State<UomDashboard> createState() => _UomDashboardState();
}

class _UomDashboardState extends State<UomDashboard> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    final companyId = widget.authBloc.state.companyId;
    if (companyId != null) {
      context.read<UdcDetailsBloc>().add(LoadUdcDetailsByGroup('UM'));
    }
  }

  void _navigateToCreateUOM() {
    context.push(AppRoutes.uomCreation);
  }

  void _navigateToEditUOM(UdcDetails item) {
    context.push(AppRoutes.uomEdit, extra: item);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'UOM List',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1C4292),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.add),
            onPressed: _navigateToCreateUOM,
            tooltip: 'Create UOM',
          ),
        ],
      ),
      body: SafeArea(
        child: BlocConsumer<UdcDetailsBloc, UdcDetailsState>(
          listener: (context, state) {
            if (state.status == UdcDetailsStatus.failure &&
                state.failure != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${state.failure}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  if (state.status == UdcDetailsStatus.failure)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        state.failure ?? 'Unknown Error',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),

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
            );
          },
        ),
      ),
    );
  }

  Widget _buildDesktopTable(UdcDetailsState state, BoxConstraints constraints) {
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
                    'Detail code',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Description 1',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Description 2',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              rows: state.details.map((item) {
                return DataRow(
                  onLongPress: () => _navigateToEditUOM(item),
                  cells: [
                    DataCell(
                      GestureDetector(
                        onDoubleTap: () => _navigateToEditUOM(item),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            item.detailCode,
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
                      GestureDetector(
                        onDoubleTap: () => _navigateToEditUOM(item),
                        child: Row(
                          children: [
                            Icon(
                              Iconsax.document_text,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              item.description1,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    DataCell(
                      GestureDetector(
                        onDoubleTap: () => _navigateToEditUOM(item),
                        child: Row(
                          children: [
                            Icon(
                              Iconsax.document_text,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              item.description2 ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
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

  Widget _buildMobileList(UdcDetailsState state, BoxConstraints constraints) {
    return ListView.separated(
      controller: _scrollController,
      itemCount: state.details.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = state.details[index];
        return GestureDetector(
          onDoubleTap: () => _navigateToEditUOM(item),
          onLongPress: () => _navigateToEditUOM(item),
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
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.detailCode,
                        style: const TextStyle(
                          color: Colors.purple,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
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
                            item.description1,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          if (item.description2?.isNotEmpty == true)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                'Type: ${item.description2}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
