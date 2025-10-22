// lib/features/admin/domain/repositories/admin_sell_request_repository.dart

import '../../../../core/models/sell_request_model.dart';

abstract class AdminSellRequestRepository {
  /// 승인 프로세스
  Future<void> approveSellRequest({
    required String requestId,
    required int finalPrice,
    required int finalConditionScore,
    // ❌ brand 파라미터 제거 (SellRequest에서 가져옴)
    String? adminNotes,
  });

  /// 반려 프로세스
  Future<void> rejectSellRequest({
    required String requestId,
    required String rejectReason,
  });

  /// 대기 중인 SellRequest 조회 (🆕 추가)
  Stream<List<SellRequest>> getPendingSellRequests();

  /// 알림 전송
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String message,
    String? relatedSellRequestId,
    String? relatedListingId,  // 🆕 추가
  });
}
