
// lib/features/order/domain/entities/order_entity.dart

import 'package:pi_com/features/cart/domain/entities/cart_item_entity.dart';

enum OrderStatus {
  pending,           // 주문 대기
  processing,        // 처리 중
  shipped,           // 배송 중
  delivered,         // 배송 완료
  confirmed,         // 구매 확정 (정산 대기)
  cancelled,         // 주문 취소

  // ✅ 추가: 환불 관련 상태
  refundRequested,   // 환불 신청됨
  refundApproved,    // 환불 승인됨 (반품 택배 발송 가능)
  refundRejected,    // 환불 거부됨
  itemReturning,     // 반품 물품 반송 중
  refundInspecting,  // 환불 검수 중 (3영업일 이내)
  refundInspectionPass,   // 검수 합격
  refundInspectionFail,   // 검수 불합격
  refundProcessing,  // 환불 처리 중 (카카오페이 연동)
  refundCompleted,   // 환불 완료
}

class OrderEntity {
  final String orderId;
  final String userId;
  final String sellerId;
  final String sellerName;
  final List<CartItemEntity> items;
  final double totalPrice;
  final double shippingFee;
  final OrderStatus status;
  final DateTime createdAt;
  final String shippingAddress;

  // ✅ 추가: 주문 이력 상세 타임스탬프
  final DateTime? paidAt;           // 결제 완료 시각
  final DateTime? shippedAt;        // 배송 시작 시각
  final DateTime? deliveredAt;      // 배송 완료 시각 (⭐ 환불 기한 계산에 필수)
  final DateTime? confirmedAt;      // 구매 확정 시각

  // ✅ 추가: 환불 관련 필드
  final DateTime? refundRequestedAt; // 환불 신청 시각
  final DateTime? refundCompletedAt; // 환불 완료 시각
  final int? refundAmount;           // 환불 금액

  // ✅ 추가: 송장 관련 필드
  final String? invoiceId;           // 송장 ID
  final String? invoiceUrl;          // 송장 PDF 다운로드 URL
  final DateTime? invoiceGeneratedAt; // 송장 생성 시각

  OrderEntity({
    required this.orderId,
    required this.userId,
    required this.sellerId,
    required this.sellerName,
    required this.items,
    required this.totalPrice,
    required this.shippingFee,
    required this.status,
    required this.createdAt,
    required this.shippingAddress,
    this.paidAt,
    this.shippedAt,
    this.deliveredAt,
    this.confirmedAt,
    this.refundRequestedAt,
    this.refundCompletedAt,
    this.refundAmount,
    this.invoiceId,
    this.invoiceUrl,
    this.invoiceGeneratedAt,
  });

  double get finalTotal => totalPrice + shippingFee;

  /// 환불 가능 여부 계산 (배송 완료 기준)
  bool canRequestRefund() {
    if (deliveredAt == null) return false;
    if (status != OrderStatus.delivered) return false;

    final daysSinceDelivery = DateTime.now().difference(deliveredAt!).inDays;
    return daysSinceDelivery <= 30; // 최대 30일 (판매자 귀책의 경우)
  }

  /// 환불 신청 가능 남은 일수
  int? daysUntilRefundDeadline() {
    if (deliveredAt == null) return null;

    final daysSinceDelivery = DateTime.now().difference(deliveredAt!).inDays;
    return 30 - daysSinceDelivery;
  }
}
