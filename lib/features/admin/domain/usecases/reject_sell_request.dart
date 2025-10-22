// lib/features/admin/domain/usecases/reject_sell_request.dart

import '../repositories/admin_sell_request_repository.dart';

/// SellRequest 반려 UseCase
///
/// 역할:
/// - SellRequest를 반려 상태로 변경
/// - 사용자에게 반려 사유 알림 발송
class RejectSellRequest {
  final AdminSellRequestRepository _repository;

  RejectSellRequest(this._repository);

  /// SellRequest 반려 실행
  ///
  /// [requestId]: 반려할 SellRequest ID
  /// [reason]: 반려 사유 (필수)
  ///
  /// ⚠️ 주의:
  /// - reason은 사용자에게 그대로 전달되므로 명확하고 친절하게 작성
  /// - 예시: "제출하신 이미지가 불선명하여 상태 확인이 어렵습니다."
  Future<void> call({
    required String requestId,
    required String reason,
  }) async {
    // Repository를 통해 반려 프로세스 실행
    await _repository.rejectSellRequest(
      requestId: requestId,
      rejectReason: reason,
    );

    // ✅ 반려 알림은 Repository에서 자동 발송됨
  }
}
