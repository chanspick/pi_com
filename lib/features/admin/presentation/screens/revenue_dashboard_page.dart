/// 매출 대시보드 페이지
///
/// Admin용 매출 분석 대시보드:
/// - 기간 선택 (오늘/주간/월간/커스텀)
/// - 핵심 지표 카드
/// - 매출 차트 (fl_chart)
/// - 정산 현황

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../widgets/revenue_chart_widget.dart';
import '../../data/services/excel_export_service.dart';

enum DateRangeType { today, week, month, custom }

class RevenueDashboardPage extends ConsumerStatefulWidget {
  const RevenueDashboardPage({super.key});

  @override
  ConsumerState<RevenueDashboardPage> createState() => _RevenueDashboardPageState();
}

class _RevenueDashboardPageState extends ConsumerState<RevenueDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateRangeType _selectedRange = DateRangeType.week;
  DateTimeRange? _customRange;

  final _currencyFormat = NumberFormat.currency(locale: 'ko_KR', symbol: '', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: 1);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        _selectedRange = DateRangeType.values[_tabController.index];
        if (_selectedRange == DateRangeType.custom && _customRange == null) {
          _showDateRangePicker();
        }
      });
    }
  }

  Future<void> _showDateRangePicker() async {
    final now = DateTime.now();
    final result = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
      initialDateRange: _customRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
          ),
    );

    if (result != null) {
      setState(() => _customRange = result);
    } else if (_customRange == null) {
      _tabController.animateTo(1); // 주간으로 돌아가기
    }
  }

  DateTimeRange _getDateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (_selectedRange) {
      case DateRangeType.today:
        return DateTimeRange(start: today, end: now);
      case DateRangeType.week:
        return DateTimeRange(start: today.subtract(const Duration(days: 7)), end: now);
      case DateRangeType.month:
        return DateTimeRange(start: today.subtract(const Duration(days: 30)), end: now);
      case DateRangeType.custom:
        return _customRange ?? DateTimeRange(start: today.subtract(const Duration(days: 30)), end: now);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('매출 대시보드'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: _exportReport,
            tooltip: '엑셀 내보내기',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
            tooltip: '새로고침',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '오늘'),
            Tab(text: '주간'),
            Tab(text: '월간'),
            Tab(text: '커스텀'),
          ],
        ),
      ),
      body: _buildDashboard(),
    );
  }

  Widget _buildDashboard() {
    final dateRange = _getDateRange();

    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchRevenueData(dateRange),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('오류: ${snapshot.error}'));
        }

        final data = snapshot.data ?? {};
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 기간 표시
              _buildPeriodHeader(dateRange),
              const SizedBox(height: 16),

              // 핵심 지표 카드
              _buildMetricsGrid(data),
              const SizedBox(height: 16),

              // 일별 매출 차트
              DailyRevenueLineChart(
                dailyData: List<Map<String, dynamic>>.from(data['dailyRevenue'] ?? []),
              ),
              const SizedBox(height: 16),

              // 카테고리별 매출
              CategoryRevenueBarChart(
                categoryData: List<Map<String, dynamic>>.from(data['categoryRevenue'] ?? []),
              ),
              const SizedBox(height: 16),

              // 결제수단별 비율
              PaymentMethodPieChart(
                paymentData: List<Map<String, dynamic>>.from(data['paymentMethodRevenue'] ?? []),
              ),
              const SizedBox(height: 16),

              // 정산 현황
              _buildSettlementCard(data),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPeriodHeader(DateTimeRange range) {
    final format = DateFormat('yyyy.MM.dd');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, color: Colors.blue, size: 20),
          const SizedBox(width: 8),
          Text(
            '${format.format(range.start)} ~ ${format.format(range.end)}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          if (_selectedRange == DateRangeType.custom) ...[
            const Spacer(),
            TextButton(
              onPressed: _showDateRangePicker,
              child: const Text('변경'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(Map<String, dynamic> data) {
    final totalRevenue = (data['totalRevenue'] as num?)?.toInt() ?? 0;
    final totalOrders = (data['totalOrders'] as num?)?.toInt() ?? 0;
    final avgOrderValue = (data['avgOrderValue'] as num?)?.toInt() ?? 0;
    final totalRefunds = (data['totalRefunds'] as num?)?.toInt() ?? 0;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        MetricCard(
          title: '총 매출',
          value: '${_currencyFormat.format(totalRevenue)}원',
          icon: Icons.attach_money,
          color: Colors.green,
          changePercent: data['revenueChange'] as double?,
        ),
        MetricCard(
          title: '주문 수',
          value: '${totalOrders}건',
          icon: Icons.shopping_cart_outlined,
          color: Colors.blue,
          changePercent: data['ordersChange'] as double?,
        ),
        MetricCard(
          title: '평균 주문액',
          value: '${_currencyFormat.format(avgOrderValue)}원',
          icon: Icons.analytics_outlined,
          color: Colors.orange,
        ),
        MetricCard(
          title: '환불액',
          value: '${_currencyFormat.format(totalRefunds)}원',
          icon: Icons.replay,
          color: Colors.red,
        ),
      ],
    );
  }

  Widget _buildSettlementCard(Map<String, dynamic> data) {
    final pendingSettlement = (data['pendingSettlement'] as num?)?.toInt() ?? 0;
    final completedSettlement = (data['completedSettlement'] as num?)?.toInt() ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.account_balance_outlined, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  '정산 현황',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: _buildSettlementItem(
                    '정산 대기',
                    '${_currencyFormat.format(pendingSettlement)}원',
                    Colors.orange,
                  ),
                ),
                Container(width: 1, height: 50, color: Colors.grey[300]),
                Expanded(
                  child: _buildSettlementItem(
                    '정산 완료',
                    '${_currencyFormat.format(completedSettlement)}원',
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

  Widget _buildSettlementItem(String title, String value, Color color) {
    return Column(
      children: [
        Text(title, style: TextStyle(color: Colors.grey[600])),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Future<Map<String, dynamic>> _fetchRevenueData(DateTimeRange range) async {
    final db = FirebaseFirestore.instance;
    final startTimestamp = Timestamp.fromDate(range.start);
    final endTimestamp = Timestamp.fromDate(range.end);

    // 주문 데이터 조회
    final ordersSnapshot = await db
        .collection('orders')
        .where('createdAt', isGreaterThanOrEqualTo: startTimestamp)
        .where('createdAt', isLessThanOrEqualTo: endTimestamp)
        .get();

    final orders = ordersSnapshot.docs.map((d) => d.data()).toList();

    // 완료된 주문만 필터링 (cancelled, refundCompleted 제외)
    final completedOrders = orders.where((o) {
      final status = o['status'] as String?;
      return status != 'cancelled' && status != 'refundCompleted';
    }).toList();

    // 총 매출 계산
    final totalRevenue = completedOrders.fold<int>(
      0,
      (sum, o) => sum + ((o['totalPrice'] as num?)?.toInt() ?? 0),
    );

    // 환불 금액 계산
    final refundedOrders = orders.where((o) => o['status'] == 'refundCompleted');
    final totalRefunds = refundedOrders.fold<int>(
      0,
      (sum, o) => sum + ((o['refundAmount'] as num?)?.toInt() ?? 0),
    );

    // 평균 주문액
    final avgOrderValue = completedOrders.isNotEmpty
        ? (totalRevenue / completedOrders.length).round()
        : 0;

    // 일별 매출 집계
    final dailyRevenue = _aggregateDailyRevenue(completedOrders, range);

    // 카테고리별 매출 (상품 정보에서 추출)
    final categoryRevenue = _aggregateCategoryRevenue(completedOrders);

    // 결제수단별 매출
    final paymentMethodRevenue = _aggregatePaymentMethodRevenue(completedOrders);

    // 이전 기간 대비 변화율 계산
    final previousRange = DateTimeRange(
      start: range.start.subtract(range.duration),
      end: range.start,
    );
    final prevData = await _fetchPreviousPeriodData(previousRange);

    return {
      'totalRevenue': totalRevenue,
      'totalOrders': completedOrders.length,
      'avgOrderValue': avgOrderValue,
      'totalRefunds': totalRefunds,
      'dailyRevenue': dailyRevenue,
      'categoryRevenue': categoryRevenue,
      'paymentMethodRevenue': paymentMethodRevenue,
      'pendingSettlement': totalRevenue - totalRefunds, // 간소화된 계산
      'completedSettlement': 0, // 실제 정산 데이터 연동 필요
      'revenueChange': _calculateChangePercent(totalRevenue, prevData['totalRevenue']),
      'ordersChange': _calculateChangePercent(completedOrders.length, prevData['totalOrders']),
    };
  }

  List<Map<String, dynamic>> _aggregateDailyRevenue(
    List<Map<String, dynamic>> orders,
    DateTimeRange range,
  ) {
    final dailyMap = <String, int>{};
    final dateFormat = DateFormat('MM-dd');

    // 범위 내 모든 날짜 초기화
    var current = range.start;
    while (current.isBefore(range.end) || current.isAtSameMomentAs(range.end)) {
      dailyMap[dateFormat.format(current)] = 0;
      current = current.add(const Duration(days: 1));
    }

    // 주문 데이터 집계
    for (final order in orders) {
      final createdAt = (order['createdAt'] as Timestamp?)?.toDate();
      if (createdAt != null) {
        final key = dateFormat.format(createdAt);
        final price = (order['totalPrice'] as num?)?.toInt() ?? 0;
        dailyMap[key] = (dailyMap[key] ?? 0) + price;
      }
    }

    return dailyMap.entries
        .map((e) => {'date': e.key, 'revenue': e.value})
        .toList()
      ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
  }

  List<Map<String, dynamic>> _aggregateCategoryRevenue(List<Map<String, dynamic>> orders) {
    final categoryMap = <String, int>{};

    for (final order in orders) {
      final items = order['items'] as List? ?? [];
      for (final item in items) {
        final category = item['category'] as String? ?? '기타';
        final price = (item['price'] as num?)?.toInt() ?? 0;
        final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
        categoryMap[category] = (categoryMap[category] ?? 0) + (price * quantity);
      }
    }

    final result = categoryMap.entries
        .map((e) => {'category': e.key, 'revenue': e.value})
        .toList()
      ..sort((a, b) => (b['revenue'] as int).compareTo(a['revenue'] as int));

    return result.take(6).toList(); // 상위 6개만
  }

  List<Map<String, dynamic>> _aggregatePaymentMethodRevenue(List<Map<String, dynamic>> orders) {
    final methodMap = <String, int>{};

    for (final order in orders) {
      final method = order['paymentMethod'] as String? ?? '기타';
      final price = (order['totalPrice'] as num?)?.toInt() ?? 0;
      methodMap[method] = (methodMap[method] ?? 0) + price;
    }

    return methodMap.entries
        .map((e) => {'method': _getPaymentMethodLabel(e.key), 'revenue': e.value})
        .toList()
      ..sort((a, b) => (b['revenue'] as int).compareTo(a['revenue'] as int));
  }

  String _getPaymentMethodLabel(String method) {
    switch (method.toLowerCase()) {
      case 'kakaopay':
        return '카카오페이';
      case 'tosspay':
      case 'toss':
        return '토스페이먼츠';
      case 'card':
        return '신용/체크카드';
      case 'transfer':
        return '계좌이체';
      default:
        return method;
    }
  }

  Future<Map<String, dynamic>> _fetchPreviousPeriodData(DateTimeRange range) async {
    final db = FirebaseFirestore.instance;
    final startTimestamp = Timestamp.fromDate(range.start);
    final endTimestamp = Timestamp.fromDate(range.end);

    final ordersSnapshot = await db
        .collection('orders')
        .where('createdAt', isGreaterThanOrEqualTo: startTimestamp)
        .where('createdAt', isLessThanOrEqualTo: endTimestamp)
        .get();

    final orders = ordersSnapshot.docs.map((d) => d.data()).toList();
    final completedOrders = orders.where((o) {
      final status = o['status'] as String?;
      return status != 'cancelled' && status != 'refundCompleted';
    }).toList();

    final totalRevenue = completedOrders.fold<int>(
      0,
      (sum, o) => sum + ((o['totalPrice'] as num?)?.toInt() ?? 0),
    );

    return {
      'totalRevenue': totalRevenue,
      'totalOrders': completedOrders.length,
    };
  }

  double? _calculateChangePercent(num current, num? previous) {
    if (previous == null || previous == 0) return null;
    return ((current - previous) / previous * 100);
  }

  Future<void> _exportReport() async {
    try {
      final dateRange = _getDateRange();
      final data = await _fetchRevenueData(dateRange);

      await ExcelExportService.exportRevenueReport({
        'period': '${DateFormat('yyyy.MM.dd').format(dateRange.start)} ~ ${DateFormat('yyyy.MM.dd').format(dateRange.end)}',
        'totalRevenue': data['totalRevenue'],
        'totalOrders': data['totalOrders'],
        'averageOrderValue': data['avgOrderValue'],
        'totalRefunds': data['totalRefunds'],
        'netRevenue': (data['totalRevenue'] as int) - (data['totalRefunds'] as int),
        'dailyRevenue': data['dailyRevenue'],
        'productRevenue': data['categoryRevenue'],
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('리포트가 생성되었습니다'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e')),
        );
      }
    }
  }
}
