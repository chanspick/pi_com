/// 주문 상세 관리 페이지
///
/// Admin 전용 주문 상세 화면으로 다음 기능을 제공합니다:
/// - 주문 기본 정보 (주문자, 상품, 금액)
/// - 배송 상태 타임라인
/// - 환불/취소 이력
/// - 송장 관리 (조회/다운로드/재발행)
/// - 빠른 액션 버튼

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class OrderDetailManagementPage extends ConsumerStatefulWidget {
  final String orderId;

  const OrderDetailManagementPage({
    super.key,
    required this.orderId,
  });

  @override
  ConsumerState<OrderDetailManagementPage> createState() => _OrderDetailManagementPageState();
}

class _OrderDetailManagementPageState extends ConsumerState<OrderDetailManagementPage> {
  final _currencyFormat = NumberFormat.currency(locale: 'ko_KR', symbol: '');
  final _dateFormat = DateFormat('yyyy-MM-dd HH:mm');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('주문 상세 (${widget.orderId.substring(0, 8)}...)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
            tooltip: '새로고침',
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(widget.orderId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('오류: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('주문을 찾을 수 없습니다'));
          }

          final order = snapshot.data!.data() as Map<String, dynamic>;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. 주문 기본 정보
                _buildOrderInfoCard(order),
                const SizedBox(height: 16),

                // 2. 배송 상태 타임라인
                _buildStatusTimeline(order),
                const SizedBox(height: 16),

                // 3. 상품 목록
                _buildItemsCard(order),
                const SizedBox(height: 16),

                // 4. 배송 정보
                _buildShippingCard(order),
                const SizedBox(height: 16),

                // 5. 송장(Invoice) 관리
                _buildInvoiceCard(order),
                const SizedBox(height: 16),

                // 6. 환불/취소 이력
                if (_hasRefundHistory(order)) ...[
                  _buildRefundHistoryCard(order),
                  const SizedBox(height: 16),
                ],

                // 7. 빠른 액션
                _buildQuickActions(order),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderInfoCard(Map<String, dynamic> order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shopping_bag_outlined, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  '주문 정보',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                _buildStatusChip(order['status'] ?? 'pending'),
              ],
            ),
            const Divider(),
            _buildInfoRow('주문번호', widget.orderId),
            _buildInfoRow('주문일시', _formatTimestamp(order['createdAt'])),
            _buildInfoRow('구매자', order['buyerName'] ?? '알 수 없음'),
            _buildInfoRow('판매자', order['sellerName'] ?? '알 수 없음'),
            const Divider(),
            _buildInfoRow('상품금액', '${_currencyFormat.format(order['totalPrice'] ?? 0)}원'),
            _buildInfoRow('배송비', '${_currencyFormat.format(order['shippingFee'] ?? 0)}원'),
            _buildInfoRow(
              '총 결제금액',
              '${_currencyFormat.format((order['totalPrice'] ?? 0) + (order['shippingFee'] ?? 0))}원',
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final statusConfig = _getStatusConfig(status);
    return Chip(
      label: Text(
        statusConfig['label'] as String,
        style: TextStyle(color: statusConfig['textColor'] as Color, fontSize: 12),
      ),
      backgroundColor: statusConfig['bgColor'] as Color,
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Map<String, dynamic> _getStatusConfig(String status) {
    switch (status) {
      case 'pending':
        return {'label': '대기중', 'bgColor': Colors.grey[200]!, 'textColor': Colors.grey[700]!};
      case 'processing':
        return {'label': '처리중', 'bgColor': Colors.blue[100]!, 'textColor': Colors.blue[700]!};
      case 'shipped':
        return {'label': '배송중', 'bgColor': Colors.orange[100]!, 'textColor': Colors.orange[700]!};
      case 'delivered':
        return {'label': '배송완료', 'bgColor': Colors.green[100]!, 'textColor': Colors.green[700]!};
      case 'confirmed':
        return {'label': '구매확정', 'bgColor': Colors.teal[100]!, 'textColor': Colors.teal[700]!};
      case 'cancelled':
        return {'label': '취소됨', 'bgColor': Colors.red[100]!, 'textColor': Colors.red[700]!};
      case 'refundRequested':
        return {'label': '환불신청', 'bgColor': Colors.purple[100]!, 'textColor': Colors.purple[700]!};
      case 'refundCompleted':
        return {'label': '환불완료', 'bgColor': Colors.pink[100]!, 'textColor': Colors.pink[700]!};
      default:
        return {'label': status, 'bgColor': Colors.grey[200]!, 'textColor': Colors.grey[700]!};
    }
  }

  Widget _buildStatusTimeline(Map<String, dynamic> order) {
    final events = _buildTimelineEvents(order);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.timeline, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  '주문 상태 타임라인',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            ...events.asMap().entries.map((entry) {
              final index = entry.key;
              final event = entry.value;
              final isLast = index == events.length - 1;
              final isCompleted = event['completed'] as bool;

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCompleted ? Colors.green : Colors.grey[300],
                          ),
                          child: Icon(
                            isCompleted ? Icons.check : Icons.circle,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: isCompleted ? Colors.green[200] : Colors.grey[300],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event['title'] as String,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isCompleted ? Colors.black : Colors.grey,
                              ),
                            ),
                            if (event['time'] != null)
                              Text(
                                event['time'] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _buildTimelineEvents(Map<String, dynamic> order) {
    return [
      {
        'title': '주문 생성',
        'time': _formatTimestamp(order['createdAt']),
        'completed': true,
      },
      {
        'title': '결제 완료',
        'time': _formatTimestamp(order['paidAt']),
        'completed': order['paidAt'] != null,
      },
      {
        'title': '배송 시작',
        'time': _formatTimestamp(order['shippedAt']),
        'completed': order['shippedAt'] != null,
      },
      {
        'title': '배송 완료',
        'time': _formatTimestamp(order['deliveredAt']),
        'completed': order['deliveredAt'] != null,
      },
      {
        'title': '구매 확정',
        'time': _formatTimestamp(order['confirmedAt']),
        'completed': order['confirmedAt'] != null,
      },
    ];
  }

  Widget _buildItemsCard(Map<String, dynamic> order) {
    final items = order['items'] as List? ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.inventory_2_outlined, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  '상품 목록 (${items.length}개)',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            ...items.map((item) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    if (item['imageUrl'] != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          item['imageUrl'],
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 60,
                            height: 60,
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
                          const SizedBox(height: 4),
                          Text(
                            '수량: ${item['quantity']}개',
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${_currencyFormat.format(item['price'] ?? 0)}원',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildShippingCard(Map<String, dynamic> order) {
    final address = order['shippingAddress'];
    final trackingNumber = order['trackingNumber'];
    final shippingCompany = order['shippingCompany'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.local_shipping_outlined, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  '배송 정보',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            if (address != null) ...[
              _buildInfoRow('받는 사람', address['recipientName'] ?? '-'),
              _buildInfoRow('연락처', address['phone'] ?? '-'),
              _buildInfoRow('주소', address['fullAddress'] ?? '-'),
              if (address['detailAddress'] != null && address['detailAddress'].toString().isNotEmpty)
                _buildInfoRow('상세주소', address['detailAddress']),
            ],
            if (trackingNumber != null) ...[
              const Divider(),
              _buildInfoRow('택배사', shippingCompany ?? '-'),
              _buildInfoRow('송장번호', trackingNumber),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(Map<String, dynamic> order) {
    final invoiceId = order['invoiceId'];
    final invoiceUrl = order['invoiceUrl'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.receipt_long_outlined, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  '영수증/송장',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            if (invoiceId != null) ...[
              _buildInfoRow('송장번호', invoiceId),
              _buildInfoRow('발행일', _formatTimestamp(order['invoiceGeneratedAt'])),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('다운로드'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _downloadInvoice(invoiceUrl),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('재발행'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                      ),
                      onPressed: () => _showRegenerateDialog(),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const Text('송장이 아직 발행되지 않았습니다.'),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('송장 발행'),
                  onPressed: () => _generateInvoice(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _hasRefundHistory(Map<String, dynamic> order) {
    return order['refundRequestedAt'] != null ||
        order['refundCompletedAt'] != null ||
        order['status']?.toString().contains('refund') == true;
  }

  Widget _buildRefundHistoryCard(Map<String, dynamic> order) {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.assignment_return_outlined, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  '환불/취소 이력',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            if (order['refundRequestedAt'] != null)
              _buildInfoRow('환불 신청일', _formatTimestamp(order['refundRequestedAt'])),
            if (order['refundCompletedAt'] != null)
              _buildInfoRow('환불 완료일', _formatTimestamp(order['refundCompletedAt'])),
            if (order['refundAmount'] != null)
              _buildInfoRow('환불 금액', '${_currencyFormat.format(order['refundAmount'])}원'),
            if (order['refundReason'] != null)
              _buildInfoRow('환불 사유', order['refundReason']),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(Map<String, dynamic> order) {
    final status = order['status'] ?? 'pending';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.flash_on_outlined, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  '빠른 작업',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (status == 'processing' || status == 'pending')
                  _buildActionButton(
                    '배송 시작',
                    Icons.local_shipping,
                    Colors.blue,
                    () => _updateStatus('shipped'),
                  ),
                if (status == 'shipped')
                  _buildActionButton(
                    '배송 완료',
                    Icons.check_circle_outline,
                    Colors.green,
                    () => _updateStatus('delivered'),
                  ),
                if (status == 'delivered')
                  _buildActionButton(
                    '구매 확정',
                    Icons.verified,
                    Colors.teal,
                    () => _updateStatus('confirmed'),
                  ),
                _buildActionButton(
                  '주문 취소',
                  Icons.cancel_outlined,
                  Colors.red,
                  () => _showCancelDialog(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      onPressed: onPressed,
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
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

  Future<void> _updateStatus(String newStatus) async {
    try {
      final updates = <String, dynamic>{
        'status': newStatus,
      };

      // 상태별 타임스탬프 추가
      if (newStatus == 'shipped') {
        updates['shippedAt'] = FieldValue.serverTimestamp();
      } else if (newStatus == 'delivered') {
        updates['deliveredAt'] = FieldValue.serverTimestamp();
      } else if (newStatus == 'confirmed') {
        updates['confirmedAt'] = FieldValue.serverTimestamp();
      }

      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .update(updates);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('상태가 $newStatus(으)로 변경되었습니다'),
            backgroundColor: Colors.green,
          ),
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

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('주문 취소'),
        content: const Text('정말로 이 주문을 취소하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('아니오'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _updateStatus('cancelled');
            },
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadInvoice(String? invoiceUrl) async {
    if (invoiceUrl == null) return;
    try {
      final uri = Uri.parse(invoiceUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e')),
        );
      }
    }
  }

  Future<void> _generateInvoice() async {
    try {
      _showLoading();
      final functions = FirebaseFunctions.instanceFor(region: 'asia-northeast3');
      final callable = functions.httpsCallableFromUrl(
        'https://asia-northeast3-picom-team.cloudfunctions.net/api/invoice/generate',
      );
      await callable.call({'orderId': widget.orderId});
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('송장이 발행되었습니다'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류: $e')));
      }
    }
  }

  void _showRegenerateDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('송장 재발행'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '재발행 사유',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _regenerateInvoice(controller.text);
            },
            child: const Text('재발행'),
          ),
        ],
      ),
    );
  }

  Future<void> _regenerateInvoice(String reason) async {
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사유를 입력하세요')),
      );
      return;
    }
    try {
      _showLoading();
      final functions = FirebaseFunctions.instanceFor(region: 'asia-northeast3');
      final callable = functions.httpsCallableFromUrl(
        'https://asia-northeast3-picom-team.cloudfunctions.net/api/invoice/regenerate',
      );
      await callable.call({'orderId': widget.orderId, 'reason': reason});
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('송장이 재발행되었습니다'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류: $e')));
      }
    }
  }

  void _showLoading() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
  }
}
