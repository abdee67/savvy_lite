// features/reports/stock_report/widgets/stock_charts.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:savvy_stock/features/reports/cash_flow/dashboard/cash_flow_report_dashboard.dart';

class StockChart extends StatelessWidget {
  final String title;
  final ChartType chartType;
  final List<ChartData> data;
  final bool showValueLabels;
  final String? valuePrefix;
  final String Function(double)? formatValue;
  final double chartHeight;

  const StockChart({
    super.key,
    required this.title,
    required this.chartType,
    required this.data,
    this.showValueLabels = false,
    this.valuePrefix,
    this.formatValue,
    required this.chartHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      height: chartHeight,
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
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: chartType == ChartType.horizontalBar
                ? _buildHorizontalBarChart()
                : _buildVerticalBarChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalBarChart() {
    return BarChart(
      BarChartData(
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            //tooltipBgColor: Colors.white,
            tooltipBorder: BorderSide(color: Colors.grey.shade300),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${data[groupIndex].label}\n${valuePrefix ?? ''}${formatValue?.call(rod.toY) ?? rod.toY.toStringAsFixed(2)}',
                const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < data.length) {
                  return _buildLabel(data[index].label, 12);
                }
                return const Text('');
              },
              reservedSize: 40,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 50),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: data.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: item.value,
                width: 20,
                borderRadius: BorderRadius.circular(4),
                color: item.color,
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: data.map((e) => e.value).reduce((a, b) => a > b ? a : b),
                  color: Colors.grey.shade100,
                ),
              ),
            ],
          );
        }).toList(),
        gridData: const FlGridData(show: false),
      ),
    );
  }

  Widget _buildHorizontalBarChart() {
    final maxValue = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            // tooltipBgColor: Colors.white,
            tooltipBorder: BorderSide(color: Colors.grey.shade300),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${data[groupIndex].label}\n${valuePrefix ?? ''}${formatValue?.call(rod.toY) ?? rod.toY.toStringAsFixed(2)}',
                const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < data.length) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildLabel(data[index].label, 11),
                  );
                }
                return const Text('');
              },
              reservedSize: 120,
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: data.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: item.value,
                width: 14,
                borderRadius: BorderRadius.circular(4),
                color: item.color,
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxValue,
                  color: Colors.grey.shade100,
                ),
              ),
            ],
          );
        }).toList(),
        gridData: const FlGridData(show: false),
        alignment: BarChartAlignment.spaceAround,
        maxY: maxValue * 1.1,
      ),
      swapAnimationDuration: const Duration(milliseconds: 500),
    );
  }

  Widget _buildLabel(String text, double fontSize) {
    // Handle long labels by breaking them into multiple lines
    if (text.length > 20) {
      final chunks = <String>[];
      for (int i = 0; i < text.length; i += 15) {
        final end = i + 15 < text.length ? i + 15 : text.length;
        chunks.add(text.substring(i, end));
      }
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: chunks
            .map(
              (chunk) => Text(
                chunk,
                style: TextStyle(
                  fontSize: fontSize,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.right,
              ),
            )
            .toList(),
      );
    }

    return Text(
      text,
      style: TextStyle(fontSize: fontSize, color: Colors.grey.shade700),
      textAlign: TextAlign.right,
      overflow: TextOverflow.clip,
    );
  }
}
