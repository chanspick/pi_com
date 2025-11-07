import 'package:pi_com/features/payment/data/models/payment_prepare_request_model.dart';
import 'package:pi_com/features/payment/data/models/payment_prepare_response_model.dart';
import 'package:pi_com/features/payment/data/models/payment_approval_request_model.dart';
import 'package:pi_com/features/payment/data/models/payment_approval_response_model.dart';

/// 결제 Remote DataSource 인터페이스
abstract class PaymentRemoteDataSource {
  /// 결제 준비 요청
  ///
  /// 백엔드 API를 통해 카카오페이 결제 준비 API를 호출합니다.
  /// 결제 준비가 성공하면 tid와 redirect URL을 반환합니다.
  Future<PaymentPrepareResponseModel> preparePayment(
    PaymentPrepareRequestModel request,
  );

  /// 결제 승인 요청
  ///
  /// 사용자가 카카오페이에서 인증을 완료한 후,
  /// 백엔드 API를 통해 카카오페이 결제 승인 API를 호출합니다.
  Future<PaymentApprovalResponseModel> approvePayment(
    PaymentApprovalRequestModel request,
  );

  /// 결제 취소 요청
  ///
  /// 주문 취소 시 카카오페이 결제를 취소합니다.
  Future<void> cancelPayment({
    required String tid,
    required int cancelAmount,
    required int cancelTaxFreeAmount,
  });
}
