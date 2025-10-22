// lib/features/admin/domain/usecases/send_notification_to_user.dart

import '../repositories/admin_sell_request_repository.dart';

/// 사용자에게 알림 발송 UseCase
///
/// 역할:
/// - Admin이 수동으로 특정 사용자에게 알림 발송
/// - 시스템 공지나 개별 안내에 사용
class SendNotificationToUser {
  final AdminSellRequestRepository _repository;

  SendNotificationToUser(this._repository);

  /// 알림 발송 실행
  ///
  /// [userId]: 수신자 사용자 ID
  /// [title]: 알림 제목
  /// [message]: 알림 내용
  /// [relatedSellRequestId]: 관련 SellRequest ID (선택)
  /// [relatedListingId]: 관련 Listing ID (선택)
  Future<void> call({
    required String userId,
    required String title,
    required String message,
    String? relatedSellRequestId,
    String? relatedListingId,
  }) async {
    await _repository.sendNotificationToUser(
      userId: userId,
      title: title,
      message: message,
      relatedSellRequestId: relatedSellRequestId,
      relatedListingId: relatedListingId,
    );
  }
}
