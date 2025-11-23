import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../domain/entities/price_point_entity.dart';

class PriceHistoryChart extends StatelessWidget {
  final List<PricePointEntity> priceHistory;

  const PriceHistoryChart({super.key, required this.priceHistory});

  @override
  Widget build(BuildContext context) {
    // 1. 데이터 필터링 및 정렬
    final validHistory = priceHistory
        .where((p) => p.lowestPrice > 0 && p.averagePrice > 0)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (validHistory.isEmpty) return const Center(child: Text('데이터 없음'));

    // 현재(마지막) 최저가 (기준선용)
    final currentLowestPrice = validHistory.last.lowestPrice.toDouble();

    // Y축 범위 계산
    final allPrices = validHistory.expand((p) => [p.lowestPrice, p.averagePrice]).toList();
    double minPrice = allPrices.reduce((a, b) => a < b ? a : b).toDouble();
    double maxPrice = allPrices.reduce((a, b) => a > b ? a : b).toDouble();

    // 차트 여백 확보
    double minY = minPrice * 0.9;
    double maxY = maxPrice * 1.1;

    return Column(
      children: [
        // 범례 (디자인 개선)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem('최저가', Colors.blueAccent),
            const SizedBox(width: 16),
            _buildLegendItem('평균가', Colors.orangeAccent),
            const SizedBox(width: 16),
            // 점선 범례 추가
            Row(
              children: [
                Text(
                  '--- 현재가',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500),
                )
              ],
            )
          ],
        ),
        const SizedBox(height: 20),

        Expanded(
          child: LineChart(
            LineChartData(
              // [개선 3] 터치 인터랙션 강화
              lineTouchData: LineTouchData(
                handleBuiltInTouches: true,
                touchTooltipData: LineTouchTooltipData(
                  // ⚠️ [수정] 버전 호환성을 위해 getTooltipColor 대신 tooltipBgColor 사용
                  tooltipBgColor: Colors.blueGrey.withOpacity(0.9),
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final index = spot.x.toInt();
                      final date = validHistory[index].date;
                      final price = spot.y.toInt();
                      // 툴팁에 날짜 표시 (X축에서 숨겼으므로 여기서 보여줌)
                      return LineTooltipItem(
                        '${date.month}/${date.day}\n',
                        const TextStyle(color: Colors.white70, fontSize: 10),
                        children: [
                          TextSpan(
                            text: '${_formatPrice(price)}원',
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      );
                    }).toList();
                  },
                ),
                // 터치 시 수직 가이드 라인 표시
                getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
                  return spotIndexes.map((spotIndex) {
                    return TouchedSpotIndicatorData(
                      FlLine(color: Colors.grey.withOpacity(0.5), strokeWidth: 1, dashArray: [5, 5]),
                      FlDotData(
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                              radius: 5,
                              color: barData.color ?? Colors.blue,
                              strokeWidth: 2,
                              strokeColor: Colors.white
                          );
                        },
                      ),
                    );
                  }).toList();
                },
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                // [개선 4] 격자 점선 처리
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey.withOpacity(0.15),
                    strokeWidth: 1,
                    dashArray: [5, 5], // 점선 효과
                  );
                },
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: _calculateInterval(minY, maxY),
                    getTitlesWidget: (value, meta) {
                      if (value == minY || value == maxY) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(
                          _formatCompactMoney(value.toInt()),
                          style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                          textAlign: TextAlign.right,
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false), // 테두리 제거 (모던함)
              minY: minY,
              maxY: maxY,
              // [개선 2] 현재가 기준선 (Extra Line)
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: currentLowestPrice,
                    color: Colors.green.withOpacity(0.5),
                    strokeWidth: 1,
                    dashArray: [5, 5],
                    label: HorizontalLineLabel(
                      show: true,
                      alignment: Alignment.topRight,
                      padding: const EdgeInsets.only(right: 5, bottom: 0),
                      style: TextStyle(color: Colors.green[700], fontSize: 9, fontWeight: FontWeight.bold),
                      labelResolver: (line) => '현재가',
                    ),
                  ),
                ],
              ),
              lineBarsData: [
                // 최저가 라인 (그라데이션 적용)
                LineChartBarData(
                  spots: validHistory.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.lowestPrice.toDouble())).toList(),
                  isCurved: true,
                  color: Colors.blueAccent,
                  barWidth: 2.5,
                  dotData: FlDotData(show: false),
                  // [개선 1] 아래 영역 그라데이션 채우기
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        Colors.blueAccent.withOpacity(0.2),
                        Colors.blueAccent.withOpacity(0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                // 평균가 라인 (점선 느낌 또는 얇게)
                LineChartBarData(
                  spots: validHistory.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.averagePrice)).toList(),
                  isCurved: true,
                  color: Colors.orangeAccent.withOpacity(0.8),
                  barWidth: 2,
                  dashArray: [5, 5], // 평균가는 점선으로 표현해서 최저가와 구분
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(show: false),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

  // 10만, 1.5만 처럼 축약
  String _formatCompactMoney(int value) {
    if (value >= 10000) {
      double manwon = value / 10000;
      return '${manwon.toStringAsFixed(manwon % 1 == 0 ? 0 : 1)}만';
    }
    return _formatPrice(value);
  }

  double _calculateInterval(double min, double max) {
    double range = max - min;
    if (range == 0) return 10000;
    return range / 4;
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
      ],
    );
  }
}