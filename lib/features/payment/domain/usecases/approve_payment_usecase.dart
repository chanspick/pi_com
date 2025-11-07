import 'package:pi_com/features/payment/domain/entities/payment_entity.dart';
import 'package:pi_com/features/payment/domain/repositories/payment_repository.dart';

/// 결제 승인 Use Case
class ApprovePaymentUseCase {
  final PaymentRepository _repository;

  ApprovePaymentUseCase({
    required PaymentRepository repository,
  }) : _repository = repository;

  /// 결제 승인 실행
  ///
  /// [tid] 결제 고유 번호
  /// [orderId] 파트너 주문 번호
  /// [userId] 파트너 회원 ID
  /// [pgToken] 결제 승인 요청 토큰
  ///
  /// Returns: 결제 승인 결과
  Future<PaymentEntity> call({
    required String tid,
    required String orderId,
    required String userId,
    required String pgToken,
  }) async {
    if (tid.isEmpty) {
      throw Exception('결제 고유 번호가 필요합니다');
    }
    if (orderId.isEmpty) {
      throw Exception('주문 번호가 필요합니다');
    }
    if (userId.isEmpty) {
      throw Exception('사용자 ID가 필요합니다');
    }
    if (pgToken.isEmpty) {
      throw Exception('결제 승인 토큰이 필요합니다');
    }

    return await _repository.approvePayment(
      tid: tid,
      orderId: orderId,
      userId: userId,
      pgToken: pgToken,
    );
  }
}
