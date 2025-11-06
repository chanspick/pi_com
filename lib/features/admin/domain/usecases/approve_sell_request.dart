// lib/features/admin/domain/usecases/approve_sell_request.dart

import '../repositories/admin_sell_request_repository.dart';

/// SellRequest 승인 UseCase
///
/// 역할:
/// - SellRequest를 승인 상태로 변경
/// - Listing 생성
/// - BasePart 가격 통계 업데이트
/// - 사용자에게 승인 알림 발송
class ApproveSellRequest {
  final AdminSellRequestRepository _repository;

  ApproveSellRequest(this._repository);

  /// SellRequest 승인 실행
  ///
  /// [requestId]: 승인할 SellRequest ID
  /// [finalPrice]: Admin이 결정한 최종 판매 가격
  /// [finalConditionScore]: Admin이 평가한 상태 점수 (1-100, 실수)
  /// [adminNotes]: Admin의 검토 노트 (선택)
  ///
  /// ⚠️ 주의:
  /// - Transaction으로 처리되므로 전체 성공 또는 전체 실패
  /// - brand는 SellRequest에서 자동으로 가져옴 (수동 입력 불필요)
  Future<void> call({
    required String requestId,
    required int finalPrice,
    required double finalConditionScore,
    String? adminNotes,
  }) async {
    // Repository를 통해 승인 프로세스 실행
    await _repository.approveSellRequest(
      requestId: requestId,
      finalPrice: finalPrice,
      finalConditionScore: finalConditionScore,
      adminNotes: adminNotes,
    );

    // ✅ 승인 후 알림은 Repository에서 자동 발송됨
    // (AdminSellRequestRepositoryImpl의 approveSellRequest 메서드 참고)
  }
}
