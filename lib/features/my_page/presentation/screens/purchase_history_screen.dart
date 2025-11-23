// lib/features/my_page/presentation/screens/purchase_history_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../order/domain/entities/order_entity.dart';
import '../../../order/data/models/order_model.dart';
import '../../../../core/constants/routes.dart';

/// 구매 내역 Provider
final purchaseHistoryProvider = StreamProvider.autoDispose<List<OrderEntity>>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) {
    return Stream.value([]);
  }

  return FirebaseFirestore.instance
      .collection('orders')
      .where('userId', isEqualTo: currentUser.uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) => OrderModel.fromFirestore(doc).toEntity()).toList();
  });
});

/// 구매 내역 화면
class PurchaseHistoryScreen extends ConsumerWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchaseHistoryAsync = ref.watch(purchaseHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('구매 내역'),
      ),
      body: purchaseHistoryAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    '구매 내역이 없습니다',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '상품을 구매하면 여기에 표시됩니다',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () {
                      context.push(Routes.partShop);
                    },
                    icon: const Icon(Icons.store),
                    label: const Text('상품 둘러보기'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final order = orders[index];
              return _OrderCard(order: order);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('오류: $error'),
            ],
          ),
        ),
      ),
    );
  }
}

/// 주문 카드 위젯
class _OrderCard extends StatelessWidget {
  final OrderEntity order;

  const _OrderCard({required this.order});

  String _formatPrice(num price) {
    return NumberFormat('#,###').format(price.toInt());
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy.MM.dd HH:mm').format(date);
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.processing:
        return Colors.blue;
      case OrderStatus.shipped:
        return Colors.purple;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.confirmed:
        return Colors.teal;
      case OrderStatus.cancelled:
        return Colors.red;
      // 환불 관련 상태
      case OrderStatus.refundRequested:
      case OrderStatus.refundApproved:
      case OrderStatus.itemReturning:
        return Colors.amber;
      case OrderStatus.refundRejected:
        return Colors.red;
      case OrderStatus.refundInspecting:
      case OrderStatus.refundInspectionPass:
      case OrderStatus.refundProcessing:
        return Colors.blue;
      case OrderStatus.refundInspectionFail:
        return Colors.deepOrange;
      case OrderStatus.refundCompleted:
        return Colors.teal;
    }
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return '결제 완료';
      case OrderStatus.processing:
        return '배송 준비중';
      case OrderStatus.shipped:
        return '배송중';
      case OrderStatus.delivered:
        return '배송 완료';
      case OrderStatus.confirmed:
        return '구매 확정';
      case OrderStatus.cancelled:
        return '취소됨';
      // 환불 관련 상태
      case OrderStatus.refundRequested:
        return '환불 신청됨';
      case OrderStatus.refundApproved:
        return '환불 승인됨';
      case OrderStatus.refundRejected:
        return '환불 거부됨';
      case OrderStatus.itemReturning:
        return '반품 배송중';
      case OrderStatus.refundInspecting:
        return '환불 검수중';
      case OrderStatus.refundInspectionPass:
        return '검수 합격';
      case OrderStatus.refundInspectionFail:
        return '검수 불합격';
      case OrderStatus.refundProcessing:
        return '환불 처리중';
      case OrderStatus.refundCompleted:
        return '환불 완료';
    }
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.payment;
      case OrderStatus.processing:
        return Icons.inventory_2_outlined;
      case OrderStatus.shipped:
        return Icons.local_shipping_outlined;
      case OrderStatus.delivered:
        return Icons.check_circle_outline;
      case OrderStatus.confirmed:
        return Icons.verified;
      case OrderStatus.cancelled:
        return Icons.cancel_outlined;
      // 환불 관련 상태
      case OrderStatus.refundRequested:
        return Icons.assignment_return;
      case OrderStatus.refundApproved:
        return Icons.check_circle;
      case OrderStatus.refundRejected:
        return Icons.cancel;
      case OrderStatus.itemReturning:
        return Icons.local_shipping;
      case OrderStatus.refundInspecting:
        return Icons.search;
      case OrderStatus.refundInspectionPass:
        return Icons.verified;
      case OrderStatus.refundInspectionFail:
        return Icons.error;
      case OrderStatus.refundProcessing:
        return Icons.refresh;
      case OrderStatus.refundCompleted:
        return Icons.account_balance_wallet;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더: 주문 날짜와 상태
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(order.createdAt),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(order.status),
                        size: 16,
                        color: _getStatusColor(order.status),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getStatusText(order.status),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(order.status),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // 주문 상품 목록
            ...order.items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  // 상품 이미지
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item.imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image, size: 30),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 상품 정보
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.partName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '수량: ${item.quantity}개',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 가격
                  Text(
                    '${_formatPrice(item.price * item.quantity)}원',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )),

            const Divider(height: 16),

            // 가격 정보
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '상품 금액',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                Text(
                  '${_formatPrice(order.totalPrice)}원',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '배송비',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                Text(
                  '${_formatPrice(order.shippingFee)}원',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '총 결제 금액',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_formatPrice(order.finalTotal)}원',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),

            // 배송지 정보
            if (order.shippingAddress != 'DragonBall Storage') ...[
              const Divider(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on_outlined, size: 20, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '배송지',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.shippingAddress,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ] else ...[
              const Divider(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.inventory_2, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '드래곤볼 보관함에 보관 중',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // 액션 버튼 (환불 신청 등)
            if (_shouldShowRefundButton(order)) ...[
              const Divider(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.push(
                      Routes.refundRequest,
                      extra: order.orderId,
                    );
                  },
                  icon: const Icon(Icons.assignment_return),
                  label: const Text('반품/환불 신청'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange[700],
                    side: BorderSide(color: Colors.orange[700]!),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 환불 신청 버튼 표시 여부
  bool _shouldShowRefundButton(OrderEntity order) {
    // 배송 완료 상태만 환불 가능
    if (order.status != OrderStatus.delivered) return false;

    // 배송 완료일이 없으면 불가
    if (order.deliveredAt == null) return false;

    // 이미 환불 관련 상태면 버튼 숨김
    if (order.status == OrderStatus.refundRequested ||
        order.status == OrderStatus.refundApproved ||
        order.status == OrderStatus.refundRejected ||
        order.status == OrderStatus.itemReturning ||
        order.status == OrderStatus.refundInspecting ||
        order.status == OrderStatus.refundInspectionPass ||
        order.status == OrderStatus.refundInspectionFail ||
        order.status == OrderStatus.refundProcessing ||
        order.status == OrderStatus.refundCompleted) {
      return false;
    }

    // 최대 30일 이내만 환불 가능 (판매자 귀책 기준)
    final daysSinceDelivery = DateTime.now().difference(order.deliveredAt!).inDays;
    return daysSinceDelivery <= 30;
  }
}
