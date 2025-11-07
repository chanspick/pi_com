/// 결제 준비 요청 모델
class PaymentPrepareRequestModel {
  final String orderId; // 파트너 주문 번호
  final String userId; // 파트너 회원 ID
  final String itemName; // 상품명
  final int quantity; // 상품 수량
  final int totalAmount; // 총 결제 금액
  final int taxFreeAmount; // 비과세 금액 (기본 0)
  final String approvalUrl; // 결제 승인 후 리다이렉트 URL
  final String cancelUrl; // 결제 취소 후 리다이렉트 URL
  final String failUrl; // 결제 실패 후 리다이렉트 URL

  PaymentPrepareRequestModel({
    required this.orderId,
    required this.userId,
    required this.itemName,
    this.quantity = 1,
    required this.totalAmount,
    this.taxFreeAmount = 0,
    required this.approvalUrl,
    required this.cancelUrl,
    required this.failUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'partner_order_id': orderId,
      'partner_user_id': userId,
      'item_name': itemName,
      'quantity': quantity,
      'total_amount': totalAmount,
      'tax_free_amount': taxFreeAmount,
      'approval_url': approvalUrl,
      'cancel_url': cancelUrl,
      'fail_url': failUrl,
    };
  }
}
