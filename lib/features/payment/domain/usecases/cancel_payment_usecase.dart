import 'package:pi_com/features/payment/domain/repositories/payment_repository.dart';

/// 결제 취소 Use Case
class CancelPaymentUseCase {
  final PaymentRepository _repository;

  CancelPaymentUseCase({
    required PaymentRepository repository,
  }) : _repository = repository;

  /// 결제 취소 실행
  ///
  /// [tid] 결제 고유 번호
  /// [cancelAmount] 취소 금액
  /// [cancelTaxFreeAmount] 취소 비과세 금액
  Future<void> call({
    required String tid,
    required int cancelAmount,
    int cancelTaxFreeAmount = 0,
  }) async {
    if (tid.isEmpty) {
      throw Exception('결제 고유 번호가 필요합니다');
    }
    if (cancelAmount <= 0) {
      throw Exception('취소 금액은 0보다 커야 합니다');
    }

    await _repository.cancelPayment(
      tid: tid,
      cancelAmount: cancelAmount,
      cancelTaxFreeAmount: cancelTaxFreeAmount,
    );
  }
}
