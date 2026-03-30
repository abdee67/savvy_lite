// features/reports/stock_report/pages/stock_report_landing_page.dart
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:savvy_stock/features/reports/stock_report/dashboard/widgets/summary_metrics_card.dart';
import 'package:savvy_stock/features/reports/stock_report/dashboard/widgets/stock_charts.dart';
import 'package:savvy_stock/features/reports/stock_report/dashboard/widgets/recent_transactions_table.dart';
import 'package:savvy_stock/features/reports/stock_report/dashboard/widgets/sidebar_menu.dart';

class StockReportDashboard extends StatefulWidget {
  const StockReportDashboard({super.key});

  @override
  State<StockReportDashboard> createState() => _StockReportDashboardState();
}

class _StockReportDashboardState extends State<StockReportDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _sidebarExpanded = false;
  bool _showSidebarOverlay = false;
  double _sidebarWidth = 280;
  final double _sidebarHeight = 280;
  final double _sidebarMinWidth = 0;
  final double _sidebarMaxWidth = 320;

  // Filter states
  String _salesTimeFilter = 'month';
  String _purchaseTimeFilter = 'month';

  // Responsive breakpoints
  bool get isMobile => MediaQuery.sizeOf(context).width < 768;
  bool get isTablet =>
      MediaQuery.sizeOf(context).width >= 768 &&
      MediaQuery.sizeOf(context).width < 1024;
  bool get isDesktop => MediaQuery.sizeOf(context).width >= 1024;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final isLandscape = screenSize.width > screenSize.height;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Stack(
          children: [
            // Main Content
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              left: _sidebarExpanded && isDesktop ? _sidebarWidth : 0,
              right: 0,
              top: 0,
              bottom: 0,
              child: _buildMainContent(),
            ),

            // Overlay for Mobile/Tablet when sidebar is open
            if (_showSidebarOverlay && (isMobile || isTablet))
              Positioned.fill(
                child: GestureDetector(
                  onTap: _hideSidebar,
                  child: Container(color: Colors.black.withOpacity(0.5)),
                ),
              ),

            // Sidebar
            if (_sidebarExpanded || isDesktop)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: _buildSidebar(screenSize),
              ),

            // Floating Menu Button for Mobile/Tablet
            if (!isDesktop && !_sidebarExpanded)
              Positioned(
                left: 16,
                top: MediaQuery.paddingOf(context).top + 16,
                child: FloatingActionButton.small(
                  backgroundColor: const Color(0xFF155888),
                  foregroundColor: Colors.white,
                  onPressed: _toggleSidebar,
                  child: const Icon(Icons.menu),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Container(
      padding: EdgeInsets.fromLTRB(isDesktop ? 24 : 16, 24, 24, 24),
      child: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            floating: false,
            pinned: true,
            scrolledUnderElevation:
                0, //when the screen scrolls it remain at the top
            snap: false,
            backgroundColor: Colors.grey[50],
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stock Dashboard',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF155888),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Real-time stock insights and analytics',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                ),
              ],
            ),
            actions: isDesktop
                ? [
                    IconButton(
                      icon: Icon(
                        _sidebarExpanded ? Icons.menu_open : Icons.menu,
                        color: const Color(0xFF155888),
                      ),
                      onPressed: _toggleSidebar,
                    ),
                    const SizedBox(width: 16),
                  ]
                : null,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(height: 1, color: Colors.grey.shade200),
            ),
          ),

          // Summary Metrics Cards
          SliverPadding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            sliver: SliverToBoxAdapter(child: _buildSummaryMetrics()),
          ),

          // Charts Section
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 24),
            sliver: SliverToBoxAdapter(child: _buildChartsSection()),
          ),

          // Recent Transactions Section
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 24),
            sliver: SliverToBoxAdapter(
              child: _buildRecentTransactionsSection(),
            ),
          ),

          // Bottom Spacing
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildSidebar(Size screenSize) {
    final sidebarWidth = isDesktop
        ? (_sidebarExpanded ? _sidebarWidth : 0)
        : screenSize.width * 0.5;
    final sidebarHeight = isDesktop
        ? (_sidebarExpanded ? _sidebarHeight : 0)
        : screenSize.height * 0.5;

    return GestureDetector(
      onHorizontalDragUpdate: _handleSidebarDrag,
      onHorizontalDragEnd: _handleSidebarDragEnd,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: sidebarWidth.toDouble(),
        height: sidebarHeight.toDouble(),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            right: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(4, 0),
            ),
          ],
        ),
        child: SidebarMenu(
          isExpanded: _sidebarExpanded,
          onToggleExpanded: _toggleSidebar,
          isDesktop: isDesktop,
        ),
      ),
    );
  }

  Widget _buildSummaryMetrics() {
    final metrics = [
      {
        'title': 'Current Inventory',
        'value': 125480.0,
        'change': '+12.5%',
        'isPositive': true,
        'icon': Iconsax.box,
        'color': const Color(0xFF3B82F6),
        'iconBackground': const Color(0xFFEBF5FF),
      },
      {
        'title': 'Upcoming Inventory',
        'value': 45230.0,
        'change': '+8.2%',
        'isPositive': true,
        'icon': Iconsax.box_tick,
        'color': const Color(0xFF8B5CF6),
        'iconBackground': const Color(0xFFF3E8FF),
      },
      {
        'title': 'Received Inventory',
        'value': 89210.0,
        'change': '+15.3%',
        'isPositive': true,
        'icon': Iconsax.box_add,
        'color': const Color(0xFF10B981),
        'iconBackground': const Color(0xFFE6F8F5),
      },
      {
        'title': 'Stock Out',
        'value': 4230.0,
        'change': '-3.2%',
        'isPositive': false,
        'icon': Iconsax.box_remove,
        'color': const Color(0xFFF59E0B),
        'iconBackground': const Color(0xFFFEF3E7),
      },
    ];

    if (isMobile) {
      // Mobile: Horizontal layout
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.start,
        children: metrics
            .map(
              (metric) => SizedBox(
                width: (MediaQuery.sizeOf(context).width - 60) / 2,
                child: SummaryMetricsCard(
                  title: metric['title'] as String,
                  value: metric['value'] as double,
                  change: metric['change'] as String,
                  isPositive: metric['isPositive'] as bool,
                  icon: metric['icon'] as IconData,
                  color: metric['color'] as Color,
                  iconBackground: metric['iconBackground'] as Color,
                ),
              ),
            )
            .toList(),
      );
    } else if (isTablet) {
      // Tablet: 2x2 grid
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.start,
        children: metrics
            .map(
              (metric) => SizedBox(
                width: (MediaQuery.sizeOf(context).width - 80) / 2,
                child: SummaryMetricsCard(
                  title: metric['title'] as String,
                  value: metric['value'] as double,
                  change: metric['change'] as String,
                  isPositive: metric['isPositive'] as bool,
                  icon: metric['icon'] as IconData,
                  color: metric['color'] as Color,
                  iconBackground: metric['iconBackground'] as Color,
                ),
              ),
            )
            .toList(),
      );
    } else {
      // Desktop: 4 columns
      return Wrap(
        spacing: 24,
        runSpacing: 24,
        children: metrics
            .map(
              (metric) => SummaryMetricsCard(
                title: metric['title'] as String,
                value: metric['value'] as double,
                change: metric['change'] as String,
                isPositive: metric['isPositive'] as bool,
                icon: metric['icon'] as IconData,
                color: metric['color'] as Color,
                iconBackground: metric['iconBackground'] as Color,
              ),
            )
            .toList(),
      );
    }
  }

  Widget _buildChartsSection() {
    if (isMobile) {
      // Mobile: Vertical stacking
      return Column(
        children: [
          SizedBox(
            height: 350,
            child: StockChart(
              title: 'Average Time To Sell (Days)',
              chartType: ChartType.line,
              data: _generateAverageTimeData(),
              showValueLabels: true,
              valuePrefix: 'Days: ',
              chartHeight: 350,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 350,
            child: RecentTransactionsTable(
              title: 'Recent Sales',
              timeFilter: _salesTimeFilter,
              onTimeFilterChanged: (value) {
                setState(() {
                  _salesTimeFilter = value;
                });
              },
              transactions: _generateRecentSales(),
              isSales: true,
              tableHeight: 350,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 500,
            child: StockChart(
              title: 'Average Inventory Value By Item (Top 10)',
              chartType: ChartType.horizontalBar,
              data: _generateInventoryValueData(),
              showValueLabels: true,
              valuePrefix: 'ETB ',
              formatValue: (value) => formatCurrency(value),
              chartHeight: 500,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 500,
            child: RecentTransactionsTable(
              title: 'Recent Purchases',
              timeFilter: _purchaseTimeFilter,
              onTimeFilterChanged: (value) {
                setState(() {
                  _purchaseTimeFilter = value;
                });
              },
              transactions: _generateRecentPurchases(),
              isSales: false,
              tableHeight: 500,
            ),
          ),
        ],
      );
    } else if (isTablet) {
      // Tablet: Side-by-side layout with 60/40 split
      return Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 60,
                child: SizedBox(
                  height: 350,
                  child: StockChart(
                    title: 'Average Time To Sell (Days)',
                    chartType: ChartType.bar,
                    data: _generateAverageTimeData(),
                    showValueLabels: true,
                    valuePrefix: 'Days: ',
                    chartHeight: 350,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 40,
                child: SizedBox(
                  height: 350,
                  child: RecentTransactionsTable(
                    title: 'Recent Sales',
                    timeFilter: _salesTimeFilter,
                    onTimeFilterChanged: (value) {
                      setState(() {
                        _salesTimeFilter = value;
                      });
                    },
                    transactions: _generateRecentSales(),
                    isSales: true,
                    tableHeight: 350,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 60,
                child: SizedBox(
                  height: 500,
                  child: StockChart(
                    title: 'Average Inventory Value By Item (Top 10)',
                    chartType: ChartType.horizontalBar,
                    data: _generateInventoryValueData(),
                    showValueLabels: true,
                    valuePrefix: 'ETB ',
                    formatValue: (value) => formatCurrency(value),
                    chartHeight: 500,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 40,
                child: SizedBox(
                  height: 500,
                  child: RecentTransactionsTable(
                    title: 'Recent Purchases',
                    timeFilter: _purchaseTimeFilter,
                    onTimeFilterChanged: (value) {
                      setState(() {
                        _purchaseTimeFilter = value;
                      });
                    },
                    transactions: _generateRecentPurchases(),
                    isSales: false,
                    tableHeight: 500,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      // Desktop: Original layout
      return Column(
        children: [
          // First Row: Average Time to Sell + Recent Sales
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Average Time to Sell Chart
                Expanded(
                  flex: 8,
                  child: StockChart(
                    title: 'Average Time To Sell (Days)',
                    chartType: ChartType.bar,
                    data: _generateAverageTimeData(),
                    showValueLabels: true,
                    valuePrefix: 'Days: ',
                    chartHeight: 350,
                  ),
                ),
                const SizedBox(width: 24),

                // Recent Sales Table
                Expanded(
                  flex: 4,
                  child: RecentTransactionsTable(
                    title: 'Recent Sales',
                    timeFilter: _salesTimeFilter,
                    onTimeFilterChanged: (value) {
                      setState(() {
                        _salesTimeFilter = value;
                      });
                    },
                    transactions: _generateRecentSales(),
                    isSales: true,
                    tableHeight: 350,
                  ),
                ),
              ],
            ),
          ),

          // Second Row: Inventory Value + Recent Purchases
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Average Inventory Value Chart
              Expanded(
                flex: 8,
                child: StockChart(
                  title: 'Average Inventory Value By Item (Top 10)',
                  chartType: ChartType.horizontalBar,
                  data: _generateInventoryValueData(),
                  showValueLabels: true,
                  valuePrefix: 'ETB ',
                  formatValue: (value) => formatCurrency(value),
                  chartHeight: 500,
                ),
              ),
              const SizedBox(width: 24),

              // Recent Purchases Table
              Expanded(
                flex: 4,
                child: RecentTransactionsTable(
                  title: 'Recent Purchases',
                  timeFilter: _purchaseTimeFilter,
                  onTimeFilterChanged: (value) {
                    setState(() {
                      _purchaseTimeFilter = value;
                    });
                  },
                  transactions: _generateRecentPurchases(),
                  isSales: false,
                  tableHeight: 500,
                ),
              ),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildRecentTransactionsSection() {
    final insightCards = [
      {
        'title': 'Low Stock Alert',
        'description': '12 items are below reorder point',
        'icon': Iconsax.warning_2,
        'color': Colors.amber,
        'action': 'Review Now',
      },
      {
        'title': 'Expiring Soon',
        'description': '8 items expiring in next 30 days',
        'icon': Iconsax.calendar_tick,
        'color': Colors.red,
        'action': 'Check Expiry',
      },
      {
        'title': 'Fast Moving Items',
        'description': 'Top 5 items by sales velocity',
        'icon': Iconsax.trend_up,
        'color': Colors.green,
        'action': 'View Details',
      },
      {
        'title': 'Stock Value',
        'description': 'Total inventory value: ETB 2,450,000',
        'icon': Iconsax.money,
        'color': Colors.blue,
        'action': 'Full Report',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Insights & Actions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF155888),
            ),
          ),
          const SizedBox(height: 16),
          if (isMobile)
            // Mobile: Vertical layout
            Column(
              children: insightCards
                  .map(
                    (card) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildInsightCard(
                        title: card['title'] as String,
                        description: card['description'] as String,
                        icon: card['icon'] as IconData,
                        color: card['color'] as Color,
                        action: card['action'] as String,
                      ),
                    ),
                  )
                  .toList(),
            )
          else
            // Tablet & Desktop: Wrap layout
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: insightCards
                  .map(
                    (card) => SizedBox(
                      width: isTablet
                          ? (MediaQuery.sizeOf(context).width - 80) / 2
                          : 280,
                      child: _buildInsightCard(
                        title: card['title'] as String,
                        description: card['description'] as String,
                        icon: card['icon'] as IconData,
                        color: card['color'] as Color,
                        action: card['action'] as String,
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildInsightCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required String action,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: color.withOpacity(0.1),
              foregroundColor: color,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(action),
          ),
        ],
      ),
    );
  }

  void _toggleSidebar() {
    setState(() {
      _sidebarExpanded = !_sidebarExpanded;
      _showSidebarOverlay = _sidebarExpanded && (isMobile || isTablet);
    });
  }

  void _hideSidebar() {
    setState(() {
      _sidebarExpanded = false;
      _showSidebarOverlay = false;
    });
  }

  void _handleSidebarDrag(DragUpdateDetails details) {
    if (isMobile || isTablet) {
      final screenWidth = MediaQuery.sizeOf(context).width;
      final newWidth = screenWidth * 0.85 - details.primaryDelta!;

      if (newWidth > 0 && newWidth < screenWidth * 0.85) {
        setState(() {
          _sidebarWidth = newWidth;
        });
      }
    }
  }

  void _handleSidebarDragEnd(DragEndDetails details) {
    if (isMobile || isTablet) {
      final screenWidth = MediaQuery.sizeOf(context).width;
      final threshold = screenWidth * 0.5;

      if (_sidebarWidth < threshold) {
        _hideSidebar();
      } else {
        setState(() {
          _sidebarWidth = screenWidth * 0.85;
        });
      }
    }
  }

  // Mock data generators
  List<ChartData> _generateAverageTimeData() {
    return [
      ChartData(label: 'A', value: 45, color: Colors.blue),
      ChartData(label: 'B', value: 32, color: Colors.green),
      ChartData(label: 'C', value: 28, color: Colors.orange),
      ChartData(label: 'D', value: 51, color: Colors.purple),
      ChartData(label: 'E', value: 39, color: Colors.red),
    ];
  }

  List<ChartData> _generateInventoryValueData() {
    return [
      ChartData(label: 'Premium Laptop', value: 1250000, color: Colors.blue),
      ChartData(label: 'Smartphone Pro', value: 980000, color: Colors.green),
      ChartData(label: 'Monitor 4K', value: 750000, color: Colors.orange),
      ChartData(
        label: 'Wireless Keyboard',
        value: 650000,
        color: Colors.purple,
      ),
      ChartData(label: 'Gaming Mouse', value: 580000, color: Colors.red),
      ChartData(label: 'External SSD', value: 520000, color: Colors.teal),
      ChartData(label: 'Webcam HD', value: 480000, color: Colors.indigo),
      ChartData(label: 'Bluetooth Speaker', value: 420000, color: Colors.pink),
      ChartData(label: 'Tablet Mini', value: 380000, color: Colors.amber),
      ChartData(label: 'Smart Watch', value: 350000, color: Colors.cyan),
    ];
  }

  List<TransactionData> _generateRecentSales() {
    return [
      TransactionData(
        item: 'Laptop Pro M3',
        description: '16GB RAM, 512GB SSD',
        value: 125000,
        change: '+12%',
      ),
      TransactionData(
        item: 'Smartphone X',
        description: '256GB, Midnight Blue',
        value: 98000,
        change: '+8%',
      ),
      TransactionData(
        item: 'Wireless Earbuds',
        description: 'Noise Cancelling',
        value: 45000,
        change: '+15%',
      ),
      TransactionData(
        item: '4K Monitor',
        description: '32-inch, 144Hz',
        value: 75000,
        change: '+5%',
      ),
      TransactionData(
        item: 'Gaming Keyboard',
        description: 'Mechanical RGB',
        value: 32000,
        change: '+22%',
      ),
    ];
  }

  List<TransactionData> _generateRecentPurchases() {
    return [
      TransactionData(
        item: 'Processor i9',
        description: '13th Gen, 24 Cores',
        value: 185000,
        change: '-3%',
      ),
      TransactionData(
        item: 'Graphics Card',
        description: 'RTX 4080, 16GB',
        value: 325000,
        change: '-8%',
      ),
      TransactionData(
        item: 'RAM Kit',
        description: 'DDR5, 64GB',
        value: 85000,
        change: '+2%',
      ),
      TransactionData(
        item: 'SSD NVMe',
        description: '2TB, Gen 4',
        value: 65000,
        change: '-5%',
      ),
      TransactionData(
        item: 'Power Supply',
        description: '1200W, Platinum',
        value: 45000,
        change: '+1%',
      ),
    ];
  }
}

String formatCurrency(double amount) {
  return NumberFormat('#,##0.00').format(amount);
}

// Supporting data classes
class ChartData {
  final String label;
  final double value;
  final Color color;

  ChartData({required this.label, required this.value, required this.color});
}

class TransactionData {
  final String item;
  final String description;
  final double value;
  final String change;

  TransactionData({
    required this.item,
    required this.description,
    required this.value,
    required this.change,
  });
}

enum ChartType { bar, horizontalBar, line }
