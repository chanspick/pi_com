import 'package:pi_com/features/payment/data/datasources/payment_remote_datasource.dart';
import 'package:pi_com/features/payment/data/models/payment_prepare_request_model.dart';
import 'package:pi_com/features/payment/data/models/payment_approval_request_model.dart';
import 'package:pi_com/features/payment/domain/entities/payment_entity.dart';
import 'package:pi_com/features/payment/domain/repositories/payment_repository.dart';

/// 결제 Repository 구현체
class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentRemoteDataSource _remoteDataSource;

  PaymentRepositoryImpl({
    required PaymentRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
  Future<PaymentEntity> preparePayment({
    required String orderId,
    required String userId,
    required String itemName,
    int quantity = 1,
    required int totalAmount,
    required String approvalUrl,
    required String cancelUrl,
    required String failUrl,
  }) async {
    try {
      final request = PaymentPrepareRequestModel(
        orderId: orderId,
        userId: userId,
        itemName: itemName,
        quantity: quantity,
        totalAmount: totalAmount,
        approvalUrl: approvalUrl,
        cancelUrl: cancelUrl,
        failUrl: failUrl,
      );

      final response = await _remoteDataSource.preparePayment(request);

      return response.toEntity(
        orderId: orderId,
        userId: userId,
        itemName: itemName,
        totalAmount: totalAmount,
      );
    } catch (e) {
      throw Exception('결제 준비 실패: $e');
    }
  }

  @override
  Future<PaymentEntity> approvePayment({
    required String tid,
    required String orderId,
    required String userId,
    required String pgToken,
  }) async {
    try {
      final request = PaymentApprovalRequestModel(
        tid: tid,
        orderId: orderId,
        userId: userId,
        pgToken: pgToken,
      );

      final response = await _remoteDataSource.approvePayment(request);

      return response.toEntity();
    } catch (e) {
      throw Exception('결제 승인 실패: $e');
    }
  }

  @override
  Future<void> cancelPayment({
    required String tid,
    required int cancelAmount,
    int cancelTaxFreeAmount = 0,
  }) async {
    try {
      await _remoteDataSource.cancelPayment(
        tid: tid,
        cancelAmount: cancelAmount,
        cancelTaxFreeAmount: cancelTaxFreeAmount,
      );
    } catch (e) {
      throw Exception('결제 취소 실패: $e');
    }
  }
}
