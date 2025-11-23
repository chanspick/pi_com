// lib/features/order/presentation/screens/purchase_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/order_entity.dart';
import '../../data/models/order_model.dart';
import '../providers/order_provider.dart';
import '../../../../core/constants/routes.dart';

/// 구매 상세 조회 Provider (읽기 전용)
final purchaseDetailProvider = StreamProvider.autoDispose.family<OrderEntity, String>((ref, orderId) {
  return FirebaseFirestore.instance
      .collection('orders')
      .doc(orderId)
      .snapshots()
      .map((doc) {
    if (!doc.exists) {
      throw Exception('주문을 찾을 수 없습니다');
    }
    return OrderModel.fromFirestore(doc).toEntity();
  });
});

/// 구매 상세 화면 (알람에서 접근, 읽기 전용)
class PurchaseDetailScreen extends ConsumerWidget {
  final String orderId;

  const PurchaseDetailScreen({
    super.key,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(purchaseDetailProvider(orderId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('구매 상세'),
        elevation: 0,
      ),
      body: orderAsync.when(
        data: (order) => _buildContent(context, order),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('오류: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('돌아가기'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, OrderEntity order) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 주문 상태 헤더
          _buildStatusHeader(context, order),

          // 주문 정보
          _buildOrderInfo(context, order),

          // 구매 상품 목록
          _buildItemsList(context, order),

          // 배송 정보
          _buildShippingInfo(context, order),

          // 결제 정보
          _buildPaymentInfo(context, order),

          // 액션 버튼들 (배송 완료 상태일 때만 표시)
          if (order.status == OrderStatus.delivered)
            _buildActionButtons(context, order),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(BuildContext context, OrderEntity order) {
    Color bgColor;
    Color textColor;
    String statusText;
    IconData icon;

    switch (order.status) {
      case OrderStatus.pending:
        bgColor = Colors.orange.withValues(alpha: 0.1);
        textColor = Colors.orange;
        statusText = '결제 대기 중';
        icon = Icons.schedule;
        break;
      case OrderStatus.processing:
        bgColor = Colors.blue.withValues(alpha: 0.1);
        textColor = Colors.blue;
        statusText = '처리 중';
        icon = Icons.autorenew;
        break;
      case OrderStatus.shipped:
        bgColor = Colors.purple.withValues(alpha: 0.1);
        textColor = Colors.purple;
        statusText = '배송 중';
        icon = Icons.local_shipping;
        break;
      case OrderStatus.delivered:
        bgColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green;
        statusText = '배송 완료';
        icon = Icons.check_circle;
        break;
      case OrderStatus.confirmed:
        bgColor = Colors.teal.withValues(alpha: 0.1);
        textColor = Colors.teal;
        statusText = '구매 확정';
        icon = Icons.verified;
        break;
      case OrderStatus.cancelled:
        bgColor = Colors.red.withValues(alpha: 0.1);
        textColor = Colors.red;
        statusText = '취소됨';
        icon = Icons.cancel;
        break;
      // 환불 관련 상태
      case OrderStatus.refundRequested:
        bgColor = Colors.amber.withValues(alpha: 0.1);
        textColor = Colors.amber;
        statusText = '환불 신청됨';
        icon = Icons.assignment_return;
        break;
      case OrderStatus.refundApproved:
        bgColor = Colors.amber.withValues(alpha: 0.1);
        textColor = Colors.amber;
        statusText = '환불 승인됨';
        icon = Icons.check_circle;
        break;
      case OrderStatus.refundRejected:
        bgColor = Colors.red.withValues(alpha: 0.1);
        textColor = Colors.red;
        statusText = '환불 거부됨';
        icon = Icons.cancel;
        break;
      case OrderStatus.itemReturning:
        bgColor = Colors.amber.withValues(alpha: 0.1);
        textColor = Colors.amber;
        statusText = '반품 배송중';
        icon = Icons.local_shipping;
        break;
      case OrderStatus.refundInspecting:
        bgColor = Colors.blue.withValues(alpha: 0.1);
        textColor = Colors.blue;
        statusText = '환불 검수중';
        icon = Icons.search;
        break;
      case OrderStatus.refundInspectionPass:
        bgColor = Colors.blue.withValues(alpha: 0.1);
        textColor = Colors.blue;
        statusText = '검수 합격';
        icon = Icons.verified;
        break;
      case OrderStatus.refundInspectionFail:
        bgColor = Colors.deepOrange.withValues(alpha: 0.1);
        textColor = Colors.deepOrange;
        statusText = '검수 불합격';
        icon = Icons.error;
        break;
      case OrderStatus.refundProcessing:
        bgColor = Colors.blue.withValues(alpha: 0.1);
        textColor = Colors.blue;
        statusText = '환불 처리중';
        icon = Icons.refresh;
        break;
      case OrderStatus.refundCompleted:
        bgColor = Colors.teal.withValues(alpha: 0.1);
        textColor = Colors.teal;
        statusText = '환불 완료';
        icon = Icons.account_balance_wallet;
        break;
    }

    return Container(
      width: double.infinity,
      color: bgColor,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(icon, size: 64, color: textColor),
          const SizedBox(height: 12),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatDate(order.createdAt),
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderInfo(BuildContext context, OrderEntity order) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '주문 정보',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const Divider(height: 24),
          _buildInfoRow('주문 번호', order.orderId),
          _buildInfoRow('주문 일시', _formatDate(order.createdAt)),
          _buildInfoRow('판매자', order.sellerName),
        ],
      ),
    );
  }

  Widget _buildItemsList(BuildContext context, OrderEntity order) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '구매 상품',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const Divider(height: 24),
          ...order.items.map((item) => _buildItemCard(item)),
        ],
      ),
    );
  }

  Widget _buildItemCard(dynamic item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          // 상품 이미지
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: item.imageUrl ?? '',
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: 80,
                height: 80,
                color: Colors.grey[300],
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                width: 80,
                height: 80,
                color: Colors.grey[300],
                child: const Icon(Icons.image, size: 30),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // 상품 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.brand} ${item.modelName}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '수량: ${item.quantity}개',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatPrice(item.price.toInt())}원',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShippingInfo(BuildContext context, OrderEntity order) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '배송 정보',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const Divider(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on, color: Colors.grey[600], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  order.shippingAddress,
                  style: const TextStyle(fontSize: 15, height: 1.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfo(BuildContext context, OrderEntity order) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withValues(alpha: 0.1),
            Theme.of(context).primaryColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          _buildPaymentRow('상품 금액', order.totalPrice),
          const SizedBox(height: 12),
          _buildPaymentRow('배송비', order.shippingFee),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '총 결제 금액',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_formatPrice(order.finalTotal.toInt())}원',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey[700],
          ),
        ),
        Text(
          '${_formatPrice(amount.toInt())}원',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, OrderEntity order) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 환불 신청 버튼 (30일 이내)
          if (_canRequestRefund(order)) ...[
            OutlinedButton.icon(
              onPressed: () {
                context.push(
                  Routes.refundRequest,
                  extra: order.orderId,
                );
              },
              icon: const Icon(Icons.assignment_return),
              label: const Text('반품/환불 신청'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                foregroundColor: Colors.orange[700],
                side: BorderSide(color: Colors.orange[700]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // 구매 확정 안내
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.blue.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '상품에 문제가 없으면 구매를 확정해주세요.\n구매 확정 시 판매자에게 정산이 진행됩니다.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Consumer(
            builder: (context, ref, child) {
              return ElevatedButton(
                onPressed: () => _handleConfirmPurchase(context, ref, order.orderId),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '구매 확정',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _handleConfirmPurchase(
    BuildContext context,
    WidgetRef ref,
    String orderId,
  ) async {
    // 확인 다이얼로그 표시
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('구매 확정'),
        content: const Text(
          '구매를 확정하시겠습니까?\n\n구매 확정 후에는 환불이 불가능하며, 판매자에게 정산이 진행됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('확정'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // 로딩 표시
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // 구매 확정 처리
      final orderRepository = ref.read(orderRepositoryProvider);
      await orderRepository.confirmPurchase(orderId);

      // 로딩 닫기
      if (context.mounted) {
        Navigator.pop(context);
      }

      // 성공 메시지 표시
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('구매가 확정되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // 로딩 닫기
      if (context.mounted) {
        Navigator.pop(context);
      }

      // 에러 메시지 표시
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('구매 확정 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 환불 신청 가능 여부 확인
  bool _canRequestRefund(OrderEntity order) {
    // 배송 완료일이 없으면 불가
    if (order.deliveredAt == null) return false;

    // 배송 완료 상태만 환불 가능
    if (order.status != OrderStatus.delivered) return false;

    // 최대 30일 이내만 환불 가능
    final daysSinceDelivery = DateTime.now().difference(order.deliveredAt!).inDays;
    return daysSinceDelivery <= 30;
  }

  String _formatPrice(int price) {
    final formatter = NumberFormat('#,###');
    return formatter.format(price);
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
