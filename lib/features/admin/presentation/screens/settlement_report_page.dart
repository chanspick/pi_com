/// 정산 리포트 페이지
///
/// Admin용 정산 관리 화면:
/// - 정산 대기 목록
/// - 정산 완료 내역
/// - 판매자별 정산 현황
/// - 정산 엑셀 내보내기

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../data/services/excel_export_service.dart';

class SettlementReportPage extends ConsumerStatefulWidget {
  const SettlementReportPage({super.key});

  @override
  ConsumerState<SettlementReportPage> createState() => _SettlementReportPageState();
}

class _SettlementReportPageState extends ConsumerState<SettlementReportPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _currencyFormat = NumberFormat.currency(locale: 'ko_KR', symbol: '', decimalDigits: 0);
  final _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('정산 리포트'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: _exportSettlements,
            tooltip: '엑셀 내보내기',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '정산 대기'),
            Tab(text: '정산 완료'),
            Tab(text: '판매자별'),
          ],
        ),
      ),
      body: Column(
        children: [
          // 요약 카드
          _buildSummaryCards(),
          // 탭 콘텐츠
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPendingSettlements(),
                _buildCompletedSettlements(),
                _buildSellerSettlements(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchSettlementSummary(),
      builder: (context, snapshot) {
        final data = snapshot.data ?? {};
        final pendingAmount = (data['pendingAmount'] as num?)?.toInt() ?? 0;
        final completedAmount = (data['completedAmount'] as num?)?.toInt() ?? 0;
        final pendingCount = (data['pendingCount'] as num?)?.toInt() ?? 0;
        final completedCount = (data['completedCount'] as num?)?.toInt() ?? 0;

        return Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  '정산 대기',
                  '${_currencyFormat.format(pendingAmount)}원',
                  '$pendingCount건',
                  Colors.orange,
                  Icons.hourglass_empty,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  '정산 완료',
                  '${_currencyFormat.format(completedAmount)}원',
                  '$completedCount건',
                  Colors.green,
                  Icons.check_circle,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(
    String title,
    String amount,
    String count,
    Color color,
    IconData icon,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(title, style: TextStyle(color: Colors.grey[600])),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              amount,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(count, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingSettlements() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: 'confirmed')
          .where('settlementStatus', isNull: true)
          .orderBy('confirmedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data?.docs ?? [];

        // 판매자별로 그룹핑
        final sellerGroups = <String, List<Map<String, dynamic>>>{};
        for (final doc in orders) {
          final order = doc.data() as Map<String, dynamic>;
          order['orderId'] = doc.id;
          final sellerId = order['sellerId'] as String? ?? 'unknown';
          sellerGroups.putIfAbsent(sellerId, () => []);
          sellerGroups[sellerId]!.add(order);
        }

        if (sellerGroups.isEmpty) {
          return _buildEmptyState('정산 대기 중인 주문이 없습니다');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sellerGroups.length,
          itemBuilder: (context, index) {
            final sellerId = sellerGroups.keys.elementAt(index);
            final sellerOrders = sellerGroups[sellerId]!;
            return _buildSellerSettlementCard(sellerId, sellerOrders, isPending: true);
          },
        );
      },
    );
  }

  Widget _buildCompletedSettlements() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('settlements')
          .orderBy('completedAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final settlements = snapshot.data?.docs ?? [];

        if (settlements.isEmpty) {
          return _buildEmptyState('완료된 정산 내역이 없습니다');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: settlements.length,
          itemBuilder: (context, index) {
            final settlement = settlements[index].data() as Map<String, dynamic>;
            return _buildCompletedSettlementCard(settlements[index].id, settlement);
          },
        );
      },
    );
  }

  Widget _buildSellerSettlements() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchSellerSettlementSummary(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final sellers = snapshot.data ?? [];

        if (sellers.isEmpty) {
          return _buildEmptyState('판매자 정산 정보가 없습니다');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sellers.length,
          itemBuilder: (context, index) {
            final seller = sellers[index];
            return _buildSellerSummaryCard(seller);
          },
        );
      },
    );
  }

  Widget _buildSellerSettlementCard(
    String sellerId,
    List<Map<String, dynamic>> orders, {
    required bool isPending,
  }) {
    final totalAmount = orders.fold<int>(
      0,
      (sum, o) => sum + ((o['totalPrice'] as num?)?.toInt() ?? 0),
    );
    final sellerName = orders.first['sellerName'] ?? '판매자';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: Text(
            sellerName.isNotEmpty ? sellerName[0] : 'S',
            style: TextStyle(color: Colors.blue[700]),
          ),
        ),
        title: Text(sellerName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          '${orders.length}건 | ${_currencyFormat.format(totalAmount)}원',
        ),
        trailing: isPending
            ? ElevatedButton(
                onPressed: () => _processSettlement(sellerId, orders),
                child: const Text('정산'),
              )
            : null,
        children: [
          const Divider(),
          ...orders.map((order) => ListTile(
                dense: true,
                title: Text('주문번호: ${(order['orderId'] as String).substring(0, 8)}...'),
                subtitle: Text(_formatTimestamp(order['confirmedAt'])),
                trailing: Text('${_currencyFormat.format(order['totalPrice'])}원'),
              )),
        ],
      ),
    );
  }

  Widget _buildCompletedSettlementCard(String id, Map<String, dynamic> settlement) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.green,
          child: Icon(Icons.check, color: Colors.white),
        ),
        title: Text(
          settlement['sellerName'] ?? '판매자',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('정산번호: $id'),
            Text('정산일: ${_formatTimestamp(settlement['completedAt'])}'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${_currencyFormat.format(settlement['amount'])}원',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
            ),
            Text(
              '${settlement['orderCount'] ?? 0}건',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildSellerSummaryCard(Map<String, dynamic> seller) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  child: Text(
                    (seller['sellerName'] as String? ?? 'S')[0],
                    style: TextStyle(color: Colors.blue[700]),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        seller['sellerName'] ?? '판매자',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        seller['sellerId'] ?? '',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn('총 매출', '${_currencyFormat.format(seller['totalRevenue'])}원'),
                _buildStatColumn('정산 완료', '${_currencyFormat.format(seller['settledAmount'])}원'),
                _buildStatColumn('정산 대기', '${_currencyFormat.format(seller['pendingAmount'])}원'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchSettlementSummary() async {
    final db = FirebaseFirestore.instance;

    // 정산 대기 (confirmed 상태, settlementStatus 없음)
    final pendingSnapshot = await db
        .collection('orders')
        .where('status', isEqualTo: 'confirmed')
        .get();

    final pendingOrders = pendingSnapshot.docs
        .where((d) => d.data()['settlementStatus'] == null)
        .toList();

    final pendingAmount = pendingOrders.fold<int>(
      0,
      (sum, d) => sum + ((d.data()['totalPrice'] as num?)?.toInt() ?? 0),
    );

    // 정산 완료
    final completedSnapshot = await db
        .collection('settlements')
        .where('status', isEqualTo: 'completed')
        .get();

    final completedAmount = completedSnapshot.docs.fold<int>(
      0,
      (sum, d) => sum + ((d.data()['amount'] as num?)?.toInt() ?? 0),
    );

    return {
      'pendingAmount': pendingAmount,
      'pendingCount': pendingOrders.length,
      'completedAmount': completedAmount,
      'completedCount': completedSnapshot.docs.length,
    };
  }

  Future<List<Map<String, dynamic>>> _fetchSellerSettlementSummary() async {
    final db = FirebaseFirestore.instance;

    // 모든 confirmed 주문 조회
    final ordersSnapshot = await db
        .collection('orders')
        .where('status', isEqualTo: 'confirmed')
        .get();

    // 판매자별 집계
    final sellerMap = <String, Map<String, dynamic>>{};

    for (final doc in ordersSnapshot.docs) {
      final order = doc.data();
      final sellerId = order['sellerId'] as String? ?? 'unknown';
      final sellerName = order['sellerName'] as String? ?? '판매자';
      final amount = (order['totalPrice'] as num?)?.toInt() ?? 0;
      final isSettled = order['settlementStatus'] == 'completed';

      sellerMap.putIfAbsent(sellerId, () => {
        'sellerId': sellerId,
        'sellerName': sellerName,
        'totalRevenue': 0,
        'settledAmount': 0,
        'pendingAmount': 0,
      });

      sellerMap[sellerId]!['totalRevenue'] =
          (sellerMap[sellerId]!['totalRevenue'] as int) + amount;

      if (isSettled) {
        sellerMap[sellerId]!['settledAmount'] =
            (sellerMap[sellerId]!['settledAmount'] as int) + amount;
      } else {
        sellerMap[sellerId]!['pendingAmount'] =
            (sellerMap[sellerId]!['pendingAmount'] as int) + amount;
      }
    }

    return sellerMap.values.toList()
      ..sort((a, b) => (b['totalRevenue'] as int).compareTo(a['totalRevenue'] as int));
  }

  Future<void> _processSettlement(String sellerId, List<Map<String, dynamic>> orders) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('정산 처리'),
        content: Text('${orders.length}건의 주문을 정산 처리하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('정산'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final db = FirebaseFirestore.instance;
      final batch = db.batch();

      final totalAmount = orders.fold<int>(
        0,
        (sum, o) => sum + ((o['totalPrice'] as num?)?.toInt() ?? 0),
      );

      // 정산 문서 생성
      final settlementRef = db.collection('settlements').doc();
      batch.set(settlementRef, {
        'sellerId': sellerId,
        'sellerName': orders.first['sellerName'],
        'orderIds': orders.map((o) => o['orderId']).toList(),
        'orderCount': orders.length,
        'amount': totalAmount,
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 주문들의 정산 상태 업데이트
      for (final order in orders) {
        final orderRef = db.collection('orders').doc(order['orderId']);
        batch.update(orderRef, {
          'settlementStatus': 'completed',
          'settlementId': settlementRef.id,
          'settledAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('정산이 완료되었습니다'), backgroundColor: Colors.green),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e')),
        );
      }
    }
  }

  Future<void> _exportSettlements() async {
    try {
      final db = FirebaseFirestore.instance;
      final snapshot = await db
          .collection('settlements')
          .orderBy('completedAt', descending: true)
          .get();

      final settlements = snapshot.docs.map((d) {
        final data = d.data();
        data['settlementId'] = d.id;
        return data;
      }).toList();

      await ExcelExportService.exportSettlementReport(
        settlements.map((s) => Map<String, dynamic>.from(s)).toList(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('엑셀 파일이 생성되었습니다'), backgroundColor: Colors.green),
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

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '-';
    try {
      final date = (timestamp as Timestamp).toDate();
      return _dateFormat.format(date);
    } catch (e) {
      return '-';
    }
  }
}
