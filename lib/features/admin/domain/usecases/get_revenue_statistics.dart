/// Get Revenue Statistics UseCase
///
/// 매출 통계 데이터 조회 유스케이스:
/// - 기간별 매출 집계
/// - 판매자별 매출 집계
/// - 카테고리별 매출 분석
/// - 결제수단별 분석

import 'package:cloud_firestore/cloud_firestore.dart';

/// 매출 통계 결과
class RevenueStatistics {
  final int totalRevenue;
  final int totalOrders;
  final int avgOrderValue;
  final int totalRefunds;
  final int netRevenue;
  final double? revenueChangePercent;
  final double? ordersChangePercent;
  final List<DailyRevenue> dailyRevenue;
  final List<CategoryRevenue> categoryRevenue;
  final List<PaymentMethodRevenue> paymentMethodRevenue;
  final SettlementSummary settlementSummary;

  const RevenueStatistics({
    required this.totalRevenue,
    required this.totalOrders,
    required this.avgOrderValue,
    required this.totalRefunds,
    required this.netRevenue,
    this.revenueChangePercent,
    this.ordersChangePercent,
    required this.dailyRevenue,
    required this.categoryRevenue,
    required this.paymentMethodRevenue,
    required this.settlementSummary,
  });
}

class DailyRevenue {
  final String date;
  final int revenue;
  final int orderCount;
  final int refunds;

  const DailyRevenue({
    required this.date,
    required this.revenue,
    required this.orderCount,
    required this.refunds,
  });

  int get netRevenue => revenue - refunds;

  Map<String, dynamic> toMap() => {
    'date': date,
    'revenue': revenue,
    'orderCount': orderCount,
    'refunds': refunds,
    'netRevenue': netRevenue,
  };
}

class CategoryRevenue {
  final String category;
  final int revenue;
  final int quantity;
  final double percentage;

  const CategoryRevenue({
    required this.category,
    required this.revenue,
    required this.quantity,
    required this.percentage,
  });

  Map<String, dynamic> toMap() => {
    'category': category,
    'revenue': revenue,
    'quantity': quantity,
    'percentage': percentage,
  };
}

class PaymentMethodRevenue {
  final String method;
  final int revenue;
  final int count;
  final double percentage;

  const PaymentMethodRevenue({
    required this.method,
    required this.revenue,
    required this.count,
    required this.percentage,
  });

  Map<String, dynamic> toMap() => {
    'method': method,
    'revenue': revenue,
    'count': count,
    'percentage': percentage,
  };
}

class SettlementSummary {
  final int pendingAmount;
  final int pendingCount;
  final int completedAmount;
  final int completedCount;

  const SettlementSummary({
    required this.pendingAmount,
    required this.pendingCount,
    required this.completedAmount,
    required this.completedCount,
  });
}

/// 매출 통계 조회 유스케이스
class GetRevenueStatistics {
  final FirebaseFirestore _firestore;

  GetRevenueStatistics({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// 기간별 매출 통계 조회
  Future<RevenueStatistics> call({
    required DateTime startDate,
    required DateTime endDate,
    String? sellerId, // 특정 판매자 필터
  }) async {
    final startTimestamp = Timestamp.fromDate(startDate);
    final endTimestamp = Timestamp.fromDate(endDate);

    // 주문 데이터 조회
    Query<Map<String, dynamic>> query = _firestore
        .collection('orders')
        .where('createdAt', isGreaterThanOrEqualTo: startTimestamp)
        .where('createdAt', isLessThanOrEqualTo: endTimestamp);

    if (sellerId != null) {
      query = query.where('sellerId', isEqualTo: sellerId);
    }

    final ordersSnapshot = await query.get();
    final orders = ordersSnapshot.docs.map((d) => d.data()).toList();

    // 완료된 주문 필터링
    final completedOrders = orders.where(_isCompletedOrder).toList();

    // 환불된 주문
    final refundedOrders = orders.where((o) => o['status'] == 'refundCompleted').toList();

    // 기본 통계 계산
    final totalRevenue = _sumOrderPrices(completedOrders);
    final totalRefunds = refundedOrders.fold<int>(
      0,
      (sum, o) => sum + ((o['refundAmount'] as num?)?.toInt() ?? 0),
    );
    final avgOrderValue = completedOrders.isNotEmpty
        ? (totalRevenue / completedOrders.length).round()
        : 0;

    // 일별 매출 집계
    final dailyRevenue = _aggregateDailyRevenue(completedOrders, startDate, endDate);

    // 카테고리별 매출 집계
    final categoryRevenue = _aggregateCategoryRevenue(completedOrders);

    // 결제수단별 매출 집계
    final paymentMethodRevenue = _aggregatePaymentMethodRevenue(completedOrders);

    // 이전 기간 대비 변화율
    final previousStartDate = startDate.subtract(endDate.difference(startDate));
    final previousEndDate = startDate;
    final previousStats = await _getPreviousPeriodStats(
      previousStartDate,
      previousEndDate,
      sellerId,
    );

    // 정산 현황
    final settlementSummary = await _getSettlementSummary(sellerId);

    return RevenueStatistics(
      totalRevenue: totalRevenue,
      totalOrders: completedOrders.length,
      avgOrderValue: avgOrderValue,
      totalRefunds: totalRefunds,
      netRevenue: totalRevenue - totalRefunds,
      revenueChangePercent: _calculateChangePercent(totalRevenue, previousStats['revenue']),
      ordersChangePercent: _calculateChangePercent(completedOrders.length, previousStats['orders']),
      dailyRevenue: dailyRevenue,
      categoryRevenue: categoryRevenue,
      paymentMethodRevenue: paymentMethodRevenue,
      settlementSummary: settlementSummary,
    );
  }

  /// 판매자별 매출 통계 조회
  Future<List<Map<String, dynamic>>> getSellerStatistics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final startTimestamp = Timestamp.fromDate(startDate);
    final endTimestamp = Timestamp.fromDate(endDate);

    final ordersSnapshot = await _firestore
        .collection('orders')
        .where('createdAt', isGreaterThanOrEqualTo: startTimestamp)
        .where('createdAt', isLessThanOrEqualTo: endTimestamp)
        .get();

    final orders = ordersSnapshot.docs.map((d) => d.data()).toList();
    final completedOrders = orders.where(_isCompletedOrder).toList();

    // 판매자별 집계
    final sellerMap = <String, Map<String, dynamic>>{};

    for (final order in completedOrders) {
      final sellerId = order['sellerId'] as String? ?? 'unknown';
      final sellerName = order['sellerName'] as String? ?? '판매자';
      final price = (order['totalPrice'] as num?)?.toInt() ?? 0;

      sellerMap.putIfAbsent(sellerId, () => {
        'sellerId': sellerId,
        'sellerName': sellerName,
        'totalRevenue': 0,
        'orderCount': 0,
      });

      sellerMap[sellerId]!['totalRevenue'] =
          (sellerMap[sellerId]!['totalRevenue'] as int) + price;
      sellerMap[sellerId]!['orderCount'] =
          (sellerMap[sellerId]!['orderCount'] as int) + 1;
    }

    return sellerMap.values.toList()
      ..sort((a, b) => (b['totalRevenue'] as int).compareTo(a['totalRevenue'] as int));
  }

  /// 인기 상품 통계 조회
  Future<List<Map<String, dynamic>>> getTopProducts({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 10,
  }) async {
    final startTimestamp = Timestamp.fromDate(startDate);
    final endTimestamp = Timestamp.fromDate(endDate);

    final ordersSnapshot = await _firestore
        .collection('orders')
        .where('createdAt', isGreaterThanOrEqualTo: startTimestamp)
        .where('createdAt', isLessThanOrEqualTo: endTimestamp)
        .get();

    final orders = ordersSnapshot.docs.map((d) => d.data()).toList();
    final completedOrders = orders.where(_isCompletedOrder).toList();

    // 상품별 집계
    final productMap = <String, Map<String, dynamic>>{};

    for (final order in completedOrders) {
      final items = order['items'] as List? ?? [];
      for (final item in items) {
        final productId = item['listingId'] as String? ?? item['partId'] as String? ?? 'unknown';
        final productName = item['partName'] as String? ?? '상품';
        final price = (item['price'] as num?)?.toInt() ?? 0;
        final quantity = (item['quantity'] as num?)?.toInt() ?? 1;

        productMap.putIfAbsent(productId, () => {
          'productId': productId,
          'productName': productName,
          'totalRevenue': 0,
          'totalQuantity': 0,
        });

        productMap[productId]!['totalRevenue'] =
            (productMap[productId]!['totalRevenue'] as int) + (price * quantity);
        productMap[productId]!['totalQuantity'] =
            (productMap[productId]!['totalQuantity'] as int) + quantity;
      }
    }

    final products = productMap.values.toList()
      ..sort((a, b) => (b['totalRevenue'] as int).compareTo(a['totalRevenue'] as int));

    return products.take(limit).toList();
  }

  // ======== Private Helper Methods ========

  bool _isCompletedOrder(Map<String, dynamic> order) {
    final status = order['status'] as String?;
    return status != 'cancelled' &&
        status != 'refundCompleted' &&
        status != 'pending';
  }

  int _sumOrderPrices(List<Map<String, dynamic>> orders) {
    return orders.fold<int>(
      0,
      (sum, o) => sum + ((o['totalPrice'] as num?)?.toInt() ?? 0),
    );
  }

  List<DailyRevenue> _aggregateDailyRevenue(
    List<Map<String, dynamic>> orders,
    DateTime startDate,
    DateTime endDate,
  ) {
    final dailyMap = <String, Map<String, int>>{};

    // 범위 내 모든 날짜 초기화
    var current = startDate;
    while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
      final key = '${current.month.toString().padLeft(2, '0')}-${current.day.toString().padLeft(2, '0')}';
      dailyMap[key] = {'revenue': 0, 'orderCount': 0, 'refunds': 0};
      current = current.add(const Duration(days: 1));
    }

    // 주문 데이터 집계
    for (final order in orders) {
      final createdAt = (order['createdAt'] as Timestamp?)?.toDate();
      if (createdAt != null) {
        final key = '${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
        if (dailyMap.containsKey(key)) {
          final price = (order['totalPrice'] as num?)?.toInt() ?? 0;
          dailyMap[key]!['revenue'] = dailyMap[key]!['revenue']! + price;
          dailyMap[key]!['orderCount'] = dailyMap[key]!['orderCount']! + 1;
        }
      }
    }

    return dailyMap.entries.map((e) => DailyRevenue(
      date: e.key,
      revenue: e.value['revenue']!,
      orderCount: e.value['orderCount']!,
      refunds: e.value['refunds']!,
    )).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  List<CategoryRevenue> _aggregateCategoryRevenue(List<Map<String, dynamic>> orders) {
    final categoryMap = <String, Map<String, int>>{};
    var totalRevenue = 0;

    for (final order in orders) {
      final items = order['items'] as List? ?? [];
      for (final item in items) {
        final category = item['category'] as String? ?? '기타';
        final price = (item['price'] as num?)?.toInt() ?? 0;
        final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
        final itemRevenue = price * quantity;

        categoryMap.putIfAbsent(category, () => {'revenue': 0, 'quantity': 0});
        categoryMap[category]!['revenue'] = categoryMap[category]!['revenue']! + itemRevenue;
        categoryMap[category]!['quantity'] = categoryMap[category]!['quantity']! + quantity;
        totalRevenue += itemRevenue;
      }
    }

    return categoryMap.entries.map((e) => CategoryRevenue(
      category: e.key,
      revenue: e.value['revenue']!,
      quantity: e.value['quantity']!,
      percentage: totalRevenue > 0 ? (e.value['revenue']! / totalRevenue * 100) : 0,
    )).toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));
  }

  List<PaymentMethodRevenue> _aggregatePaymentMethodRevenue(
    List<Map<String, dynamic>> orders,
  ) {
    final methodMap = <String, Map<String, int>>{};
    var totalRevenue = 0;

    for (final order in orders) {
      final method = order['paymentMethod'] as String? ?? '기타';
      final price = (order['totalPrice'] as num?)?.toInt() ?? 0;

      methodMap.putIfAbsent(method, () => {'revenue': 0, 'count': 0});
      methodMap[method]!['revenue'] = methodMap[method]!['revenue']! + price;
      methodMap[method]!['count'] = methodMap[method]!['count']! + 1;
      totalRevenue += price;
    }

    return methodMap.entries.map((e) => PaymentMethodRevenue(
      method: _getPaymentMethodLabel(e.key),
      revenue: e.value['revenue']!,
      count: e.value['count']!,
      percentage: totalRevenue > 0 ? (e.value['revenue']! / totalRevenue * 100) : 0,
    )).toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));
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

  Future<Map<String, int>> _getPreviousPeriodStats(
    DateTime startDate,
    DateTime endDate,
    String? sellerId,
  ) async {
    final startTimestamp = Timestamp.fromDate(startDate);
    final endTimestamp = Timestamp.fromDate(endDate);

    Query<Map<String, dynamic>> query = _firestore
        .collection('orders')
        .where('createdAt', isGreaterThanOrEqualTo: startTimestamp)
        .where('createdAt', isLessThanOrEqualTo: endTimestamp);

    if (sellerId != null) {
      query = query.where('sellerId', isEqualTo: sellerId);
    }

    final ordersSnapshot = await query.get();
    final orders = ordersSnapshot.docs.map((d) => d.data()).toList();
    final completedOrders = orders.where(_isCompletedOrder).toList();

    return {
      'revenue': _sumOrderPrices(completedOrders),
      'orders': completedOrders.length,
    };
  }

  Future<SettlementSummary> _getSettlementSummary(String? sellerId) async {
    // 정산 대기 주문
    Query<Map<String, dynamic>> pendingQuery = _firestore
        .collection('orders')
        .where('status', isEqualTo: 'confirmed');

    if (sellerId != null) {
      pendingQuery = pendingQuery.where('sellerId', isEqualTo: sellerId);
    }

    final pendingSnapshot = await pendingQuery.get();
    final pendingOrders = pendingSnapshot.docs
        .where((d) => d.data()['settlementStatus'] == null)
        .toList();

    final pendingAmount = pendingOrders.fold<int>(
      0,
      (sum, d) => sum + ((d.data()['totalPrice'] as num?)?.toInt() ?? 0),
    );

    // 정산 완료
    Query<Map<String, dynamic>> completedQuery = _firestore
        .collection('settlements')
        .where('status', isEqualTo: 'completed');

    if (sellerId != null) {
      completedQuery = completedQuery.where('sellerId', isEqualTo: sellerId);
    }

    final completedSnapshot = await completedQuery.get();
    final completedAmount = completedSnapshot.docs.fold<int>(
      0,
      (sum, d) => sum + ((d.data()['amount'] as num?)?.toInt() ?? 0),
    );

    return SettlementSummary(
      pendingAmount: pendingAmount,
      pendingCount: pendingOrders.length,
      completedAmount: completedAmount,
      completedCount: completedSnapshot.docs.length,
    );
  }

  double? _calculateChangePercent(num current, int? previous) {
    if (previous == null || previous == 0) return null;
    return ((current - previous) / previous * 100);
  }
}
