// 통계 대시보드
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 통계 대시보드 페이지
///
/// 표시 정보:
/// - 전체 사용자 수
/// - 전체 매물 수 (상태별)
/// - 판매 요청 수 (상태별)
/// - 총 거래액
/// - 최근 주문 현황
class StatisticsDashboardPage extends ConsumerWidget {
  const StatisticsDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('통계 대시보드'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '새로고침',
            onPressed: () {
              // 강제 리빌드
              (context as Element).markNeedsBuild();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 주요 지표 카드
            _buildMainMetrics(context),
            const SizedBox(height: 24),

            // 매물 현황
            const Text(
              '📦 매물 현황',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildListingStats(),
            const SizedBox(height: 24),

            // 판매 요청 현황
            const Text(
              '📋 판매 요청 현황',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildSellRequestStats(),
            const SizedBox(height: 24),

            // 최근 주문
            const Text(
              '🛒 최근 주문 (7일)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildRecentOrders(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainMetrics(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            context,
            '전체 사용자',
            Icons.people,
            Colors.blue,
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                return Text(
                  '${snapshot.data!.docs.length}',
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            context,
            '전체 매물',
            Icons.inventory_2,
            Colors.green,
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('listings').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                return Text(
                  '${snapshot.data!.docs.length}',
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            context,
            '총 거래액',
            Icons.attach_money,
            Colors.orange,
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('paymentStatus', isEqualTo: 'completed')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final total = snapshot.data!.docs.fold<int>(
                  0,
                  (sum, doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return sum + (data['totalPrice'] as int? ?? 0);
                  },
                );
                return Text(
                  '₩${_formatPrice(total)}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    Widget valueWidget,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 12),
            valueWidget,
          ],
        ),
      ),
    );
  }

  Widget _buildListingStats() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('listings').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final listings = snapshot.data!.docs;
        final stats = {
          'available': 0,
          'reserved': 0,
          'sold': 0,
          'sold_external': 0,
        };

        for (final doc in listings) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'] ?? 'available';
          stats[status] = (stats[status] ?? 0) + 1;
        }

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildStatusChip('판매중', stats['available'] ?? 0, Colors.green),
            _buildStatusChip('예약됨', stats['reserved'] ?? 0, Colors.orange),
            _buildStatusChip('판매완료', stats['sold'] ?? 0, Colors.grey),
            _buildStatusChip('타사이트', stats['sold_external'] ?? 0, Colors.purple),
          ],
        );
      },
    );
  }

  Widget _buildSellRequestStats() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('sell_requests').snapshots(),  // ✅ 수정
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data!.docs;
        final stats = {
          'pending': 0,
          'approved': 0,
          'rejected': 0,
        };

        for (final doc in requests) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'] ?? 'pending';
          stats[status] = (stats[status] ?? 0) + 1;
        }

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildStatusChip('대기중', stats['pending'] ?? 0, Colors.blue),
            _buildStatusChip('승인됨', stats['approved'] ?? 0, Colors.green),
            _buildStatusChip('반려됨', stats['rejected'] ?? 0, Colors.red),
          ],
        );
      },
    );
  }

  Widget _buildStatusChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrders() {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('createdAt', isGreaterThan: Timestamp.fromDate(sevenDaysAgo))
          .orderBy('createdAt', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data!.docs;

        if (orders.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('최근 7일간 주문이 없습니다')),
            ),
          );
        }

        return Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: orders.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final order = orders[index].data() as Map<String, dynamic>;
              final orderId = orders[index].id;
              final timestamp = (order['createdAt'] as Timestamp?)?.toDate();

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getPaymentStatusColor(order['paymentStatus']),
                  child: Text('${index + 1}'),
                ),
                title: Text('주문 ${orderId.substring(0, 8)}...'),
                subtitle: Text(
                  '${order['buyerName'] ?? '알 수 없음'} • ₩${_formatPrice(order['totalPrice'] ?? 0)}',
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _getPaymentStatusText(order['paymentStatus']),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getPaymentStatusColor(order['paymentStatus']),
                      ),
                    ),
                    if (timestamp != null)
                      Text(
                        _formatDate(timestamp),
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Color _getPaymentStatusColor(String? status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getPaymentStatusText(String? status) {
    switch (status) {
      case 'completed':
        return '결제완료';
      case 'pending':
        return '대기중';
      case 'failed':
        return '실패';
      default:
        return '알 수 없음';
    }
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
