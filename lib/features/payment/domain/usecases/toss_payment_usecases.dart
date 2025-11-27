import 'package:pi_com/features/payment/data/datasources/toss_payment_remote_datasource.dart';
import 'package:pi_com/features/payment/domain/entities/toss_payment_entity.dart';

/// 토스페이먼츠 결제 승인 UseCase
class ApproveTossPaymentUseCase {
  final TossPaymentRemoteDataSource _dataSource;

  ApproveTossPaymentUseCase({
    required TossPaymentRemoteDataSource dataSource,
  }) : _dataSource = dataSource;

  Future<TossPaymentEntity> call({
    required String paymentKey,
    required String orderId,
    required int amount,
  }) async {
    return await _dataSource.confirmPayment(
      paymentKey: paymentKey,
      orderId: orderId,
      amount: amount,
    );
  }
}

/// 토스페이먼츠 결제 취소 UseCase
class CancelTossPaymentUseCase {
  final TossPaymentRemoteDataSource _dataSource;

  CancelTossPaymentUseCase({
    required TossPaymentRemoteDataSource dataSource,
  }) : _dataSource = dataSource;

  /// 전액 취소
  Future<TossPaymentEntity> call({
    required String paymentKey,
    required String cancelReason,
  }) async {
    return await _dataSource.cancelPayment(
      paymentKey: paymentKey,
      cancelReason: cancelReason,
    );
  }

  /// 부분 취소
  Future<TossPaymentEntity> partialCancel({
    required String paymentKey,
    required String cancelReason,
    required int cancelAmount,
  }) async {
    return await _dataSource.cancelPayment(
      paymentKey: paymentKey,
      cancelReason: cancelReason,
      cancelAmount: cancelAmount,
    );
  }
}

/// 토스페이먼츠 결제 조회 UseCase
class GetTossPaymentUseCase {
  final TossPaymentRemoteDataSource _dataSource;

  GetTossPaymentUseCase({
    required TossPaymentRemoteDataSource dataSource,
  }) : _dataSource = dataSource;

  Future<TossPaymentEntity> call({
    required String paymentKey,
  }) async {
    return await _dataSource.getPayment(
      paymentKey: paymentKey,
    );
  }
}
