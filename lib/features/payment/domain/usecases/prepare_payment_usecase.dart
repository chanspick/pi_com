import 'package:pi_com/features/payment/domain/entities/payment_entity.dart';
import 'package:pi_com/features/payment/domain/repositories/payment_repository.dart';

/// 결제 준비 Use Case
class PreparePaymentUseCase {
  final PaymentRepository _repository;

  PreparePaymentUseCase({
    required PaymentRepository repository,
  }) : _repository = repository;

  /// 결제 준비 실행
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
  Future<PaymentEntity> call({
    required String orderId,
    required String userId,
    required String itemName,
    int quantity = 1,
    required int totalAmount,
    required String approvalUrl,
    required String cancelUrl,
    required String failUrl,
  }) async {
    if (orderId.isEmpty) {
      throw Exception('주문 번호가 필요합니다');
    }
    if (userId.isEmpty) {
      throw Exception('사용자 ID가 필요합니다');
    }
    if (itemName.isEmpty) {
      throw Exception('상품명이 필요합니다');
    }
    if (totalAmount <= 0) {
      throw Exception('결제 금액은 0보다 커야 합니다');
    }

    return await _repository.preparePayment(
      orderId: orderId,
      userId: userId,
      itemName: itemName,
      quantity: quantity,
      totalAmount: totalAmount,
      approvalUrl: approvalUrl,
      cancelUrl: cancelUrl,
      failUrl: failUrl,
    );
  }
}
