/// 결제 승인 요청 모델
class PaymentApprovalRequestModel {
  final String tid; // 결제 고유 번호
  final String orderId; // 파트너 주문 번호
  final String userId; // 파트너 회원 ID
  final String pgToken; // 결제 승인 요청 토큰

  PaymentApprovalRequestModel({
    required this.tid,
    required this.orderId,
    required this.userId,
    required this.pgToken,
  });

  Map<String, dynamic> toJson() {
    return {
      'tid': tid,
      'partner_order_id': orderId,
      'partner_user_id': userId,
      'pg_token': pgToken,
    };
  }
}
