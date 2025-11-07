import 'package:pi_com/features/payment/domain/entities/payment_entity.dart';

/// 결제 Repository 인터페이스
abstract class PaymentRepository {
  /// 결제 준비
  ///
  /// [orderId] 파트너 주문 번호
  /// [userId] 파트너 회원 ID
  /// [itemName] 상품명
  /// [quantity] 상품 수량
  /// [totalAmount] 총 결제 금액
  /// [approvalUrl] 결제 승인 후 리다이렉트 URL
  /// [cancelUrl] 결제 취소 후 리다이렉트 URL
  /// [failUrl] 결제 실패 후 리다이렉트 URL
  ///
  /// Returns: 결제 준비 결과 (tid, redirect URL 포함)
  Future<PaymentEntity> preparePayment({
    required String orderId,
    required String userId,
    required String itemName,
    int quantity = 1,
    required int totalAmount,
    required String approvalUrl,
    required String cancelUrl,
    required String failUrl,
  });

  /// 결제 승인
  ///
  /// [tid] 결제 고유 번호
  /// [orderId] 파트너 주문 번호
  /// [userId] 파트너 회원 ID
  /// [pgToken] 결제 승인 요청 토큰
  ///
  /// Returns: 결제 승인 결과
  Future<PaymentEntity> approvePayment({
    required String tid,
    required String orderId,
    required String userId,
    required String pgToken,
  });

  /// 결제 취소
  ///
  /// [tid] 결제 고유 번호
  /// [cancelAmount] 취소 금액
  /// [cancelTaxFreeAmount] 취소 비과세 금액
  Future<void> cancelPayment({
    required String tid,
    required int cancelAmount,
    int cancelTaxFreeAmount = 0,
  });
}
