// 송장 관리 화면
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 송장 관리 페이지
///
/// 기능:
/// - 결제 완료된 주문 목록
/// - 배송 주소 자동 표시
/// - 송장 번호 입력
/// - 배송 상태 관리
class ShippingManagementPage extends ConsumerStatefulWidget {
  const ShippingManagementPage({super.key});

  @override
  ConsumerState<ShippingManagementPage> createState() => _ShippingManagementPageState();
}

class _ShippingManagementPageState extends ConsumerState<ShippingManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        title: const Text('송장 관리'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '발송 대기'),
            Tab(text: '발송 완료'),
            Tab(text: '배송 중'),
            Tab(text: '배송 완료'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrderList('pending_shipment'),
          _buildOrderList('shipped'),
          _buildOrderList('in_transit'),
          _buildOrderList('delivered'),
        ],
      ),
    );
  }

  Widget _buildOrderList(String statusFilter) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('paymentStatus', isEqualTo: 'completed')
          .where('shippingStatus', isEqualTo: statusFilter)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('오류: ${snapshot.error}'));
        }

        final orders = snapshot.data?.docs ?? [];

        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_shipping_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text('주문이 없습니다', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index].data() as Map<String, dynamic>;
            final orderId = orders[index].id;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: ExpansionTile(
                leading: CircleAvatar(
                  child: Text('${index + 1}'),
                ),
                title: Text(
                  '주문번호: ${orderId.substring(0, 8)}...',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('구매자: ${order['buyerName'] ?? '알 수 없음'}'),
                    Text('결제일: ${_formatTimestamp(order['createdAt'])}'),
                    Text('총액: ₩${_formatPrice(order['totalPrice'] ?? 0)}'),
                  ],
                ),
                children: [
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 배송 주소
                        _buildInfoSection(
                          '📦 배송 주소',
                          order['shippingAddress'] ?? {},
                        ),
                        const SizedBox(height: 16),

                        // 주문 상품 목록
                        _buildItemsSection(order['items'] ?? []),
                        const SizedBox(height: 16),

                        // 송장 정보
                        _buildTrackingSection(orderId, order),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoSection(String title, Map<String, dynamic> address) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('받는 사람: ${address['recipientName'] ?? '-'}'),
              Text('연락처: ${address['phone'] ?? '-'}'),
              const SizedBox(height: 4),
              Text('주소: ${address['fullAddress'] ?? '-'}'),
              if (address['detailAddress'] != null && address['detailAddress'].toString().isNotEmpty)
                Text('상세주소: ${address['detailAddress']}'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemsSection(List items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📝 주문 상품',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...items.map((item) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                if (item['imageUrl'] != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      item['imageUrl'],
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image),
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['partName'] ?? '알 수 없음',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '수량: ${item['quantity']} • ₩${_formatPrice(item['price'] ?? 0)}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTrackingSection(String orderId, Map<String, dynamic> order) {
    final trackingNumber = order['trackingNumber'];
    final shippingCompany = order['shippingCompany'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🚚 송장 정보',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (trackingNumber != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('택배사: $shippingCompany'),
                Text('송장번호: $trackingNumber'),
              ],
            ),
          )
        else
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('송장 번호 입력'),
            onPressed: () => _showTrackingInputDialog(orderId),
          ),
      ],
    );
  }

  void _showTrackingInputDialog(String orderId) {
    final companyController = TextEditingController();
    final numberController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('송장 정보 입력'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: companyController,
              decoration: const InputDecoration(
                labelText: '택배사',
                hintText: '예: CJ대한통운',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: numberController,
              decoration: const InputDecoration(
                labelText: '송장번호',
                hintText: '예: 123456789012',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              final company = companyController.text.trim();
              final number = numberController.text.trim();

              if (company.isEmpty || number.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('모든 필드를 입력하세요')),
                );
                return;
              }

              try {
                await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
                  'shippingCompany': company,
                  'trackingNumber': number,
                  'shippingStatus': 'shipped',
                  'shippedAt': FieldValue.serverTimestamp(),
                });

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('송장 정보가 등록되었습니다'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('오류: $e')),
                  );
                }
              }
            },
            child: const Text('등록'),
          ),
        ],
      ),
    );
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '-';
    try {
      final date = (timestamp as Timestamp).toDate();
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return '-';
    }
  }
}
