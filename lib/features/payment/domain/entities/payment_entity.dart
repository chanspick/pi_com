/// 결제 엔티티
class PaymentEntity {
  final String tid; // 카카오페이 거래 고유 번호
  final String orderId; // 파트너 주문 번호
  final String userId; // 파트너 회원 ID
  final String itemName; // 상품명
  final int totalAmount; // 총 결제 금액
  final DateTime createdAt; // 결제 생성 시간
  final String? approvedAt; // 결제 승인 시간
  final String status; // 결제 상태 (ready, approved, failed, cancelled)

  PaymentEntity({
    required this.tid,
    required this.orderId,
    required this.userId,
    required this.itemName,
    required this.totalAmount,
    required this.createdAt,
    this.approvedAt,
    required this.status,
  });

  PaymentEntity copyWith({
    String? tid,
    String? orderId,
    String? userId,
    String? itemName,
    int? totalAmount,
    DateTime? createdAt,
    String? approvedAt,
    String? status,
  }) {
    return PaymentEntity(
      tid: tid ?? this.tid,
      orderId: orderId ?? this.orderId,
      userId: userId ?? this.userId,
      itemName: itemName ?? this.itemName,
      totalAmount: totalAmount ?? this.totalAmount,
      createdAt: createdAt ?? this.createdAt,
      approvedAt: approvedAt ?? this.approvedAt,
      status: status ?? this.status,
    );
  }
}

/// 결제 상태
class PaymentStatus {
  static const String ready = 'ready'; // 결제 준비
  static const String approved = 'approved'; // 결제 승인
  static const String failed = 'failed'; // 결제 실패
  static const String cancelled = 'cancelled'; // 결제 취소
}
