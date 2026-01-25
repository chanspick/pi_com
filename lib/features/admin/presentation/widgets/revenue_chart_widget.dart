/// Revenue Chart Widget - 매출 차트 위젯
///
/// fl_chart를 사용한 매출 시각화 위젯들:
/// - 라인 차트 (일별 매출 추이)
/// - 바 차트 (카테고리별 매출)
/// - 파이 차트 (결제수단별 비율)

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

/// 일별 매출 라인 차트
class DailyRevenueLineChart extends StatelessWidget {
  final List<Map<String, dynamic>> dailyData;
  final String title;

  const DailyRevenueLineChart({
    super.key,
    required this.dailyData,
    this.title = '일별 매출 추이',
  });

  @override
  Widget build(BuildContext context) {
    if (dailyData.isEmpty) {
      return _buildEmptyState();
    }

    final spots = _buildSpots();
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY / 4,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey[300]!,
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) => Text(
                          _formatAmount(value),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: (dailyData.length / 5).ceilToDouble(),
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= dailyData.length) return const SizedBox();
                          final date = dailyData[index]['date'] as String? ?? '';
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              date.length >= 5 ? date.substring(5) : date,
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.1),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final index = spot.x.toInt();
                          final date = index < dailyData.length
                              ? dailyData[index]['date'] ?? ''
                              : '';
                          return LineTooltipItem(
                            '$date\n${_formatCurrency(spot.y.toInt())}',
                            const TextStyle(color: Colors.white),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _buildSpots() {
    return dailyData.asMap().entries.map((entry) {
      final revenue = (entry.value['revenue'] as num?)?.toDouble() ?? 0;
      return FlSpot(entry.key.toDouble(), revenue);
    }).toList();
  }

  Widget _buildEmptyState() {
    return Card(
      child: Container(
        height: 250,
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: Text('데이터가 없습니다', style: TextStyle(color: Colors.grey)),
        ),
      ),
    );
  }

  String _formatAmount(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(0)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toStringAsFixed(0);
  }

  String _formatCurrency(int value) {
    return NumberFormat.currency(locale: 'ko_KR', symbol: '', decimalDigits: 0).format(value) + '원';
  }
}

/// 카테고리별 매출 바 차트
class CategoryRevenueBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> categoryData;
  final String title;

  const CategoryRevenueBarChart({
    super.key,
    required this.categoryData,
    this.title = '카테고리별 매출',
  });

  @override
  Widget build(BuildContext context) {
    if (categoryData.isEmpty) {
      return _buildEmptyState();
    }

    final maxY = categoryData
        .map((d) => (d['revenue'] as num?)?.toDouble() ?? 0)
        .reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY * 1.1,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final category = categoryData[group.x.toInt()]['category'] ?? '';
                        return BarTooltipItem(
                          '$category\n${_formatCurrency(rod.toY.toInt())}',
                          const TextStyle(color: Colors.white),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) => Text(
                          _formatAmount(value),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= categoryData.length) return const SizedBox();
                          final category = categoryData[index]['category'] ?? '';
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              category.length > 6 ? '${category.substring(0, 6)}...' : category,
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: categoryData.asMap().entries.map((entry) {
                    final revenue = (entry.value['revenue'] as num?)?.toDouble() ?? 0;
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: revenue,
                          color: _getBarColor(entry.key),
                          width: 20,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getBarColor(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
    ];
    return colors[index % colors.length];
  }

  Widget _buildEmptyState() {
    return Card(
      child: Container(
        height: 250,
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: Text('데이터가 없습니다', style: TextStyle(color: Colors.grey)),
        ),
      ),
    );
  }

  String _formatAmount(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(0)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toStringAsFixed(0);
  }

  String _formatCurrency(int value) {
    return NumberFormat.currency(locale: 'ko_KR', symbol: '', decimalDigits: 0).format(value) + '원';
  }
}

/// 결제수단별 파이 차트
class PaymentMethodPieChart extends StatelessWidget {
  final List<Map<String, dynamic>> paymentData;
  final String title;

  const PaymentMethodPieChart({
    super.key,
    required this.paymentData,
    this.title = '결제수단별 비율',
  });

  @override
  Widget build(BuildContext context) {
    if (paymentData.isEmpty) {
      return _buildEmptyState();
    }

    final total = paymentData.fold<double>(
      0,
      (sum, d) => sum + ((d['revenue'] as num?)?.toDouble() ?? 0),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 30,
                      sections: paymentData.asMap().entries.map((entry) {
                        final revenue = (entry.value['revenue'] as num?)?.toDouble() ?? 0;
                        final percentage = total > 0 ? (revenue / total * 100) : 0;
                        return PieChartSectionData(
                          value: revenue,
                          title: '${percentage.toStringAsFixed(0)}%',
                          color: _getPieColor(entry.key),
                          radius: 40,
                          titleStyle: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: paymentData.asMap().entries.map((entry) {
                      final method = entry.value['method'] ?? '';
                      final revenue = (entry.value['revenue'] as num?)?.toInt() ?? 0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _getPieColor(entry.key),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                method,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            Text(
                              _formatCurrency(revenue),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getPieColor(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];
    return colors[index % colors.length];
  }

  Widget _buildEmptyState() {
    return Card(
      child: Container(
        height: 200,
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: Text('데이터가 없습니다', style: TextStyle(color: Colors.grey)),
        ),
      ),
    );
  }

  String _formatCurrency(int value) {
    return NumberFormat.currency(locale: 'ko_KR', symbol: '', decimalDigits: 0).format(value) + '원';
  }
}

/// 핵심 지표 카드
class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final double? changePercent;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
    this.changePercent,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const Spacer(),
                if (changePercent != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: changePercent! >= 0 ? Colors.green[50] : Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          changePercent! >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 14,
                          color: changePercent! >= 0 ? Colors.green : Colors.red,
                        ),
                        Text(
                          '${changePercent!.abs().toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: changePercent! >= 0 ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
