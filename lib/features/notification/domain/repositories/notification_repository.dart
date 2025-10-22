// lib/features/notification/domain/repositories/notification_repository.dart

import '../../../../core/models/notification_model.dart';

/// Notification Repository 인터페이스
/// Clean Architecture: Domain Layer는 구체적인 구현을 모름
abstract class NotificationRepository {
  /// 사용자의 알림 목록 스트림
  Stream<List<NotificationModel>> getNotificationsStream(String userId);

  /// 알림을 읽음 처리
  Future<void> markAsRead(String notificationId);

  /// 알림 삭제
  Future<void> deleteNotification(String notificationId);

  /// 사용자의 모든 알림 삭제
  Future<void> clearAllNotifications(String userId);

  /// 읽지 않은 알림 개수
  Future<int> getUnreadCount(String userId);
}
