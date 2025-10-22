// lib/features/notification/domain/usecases/delete_notification.dart

import '../repositories/notification_repository.dart';

/// 알림을 삭제하는 Use Case
class DeleteNotification {
  final NotificationRepository _repository;

  DeleteNotification(this._repository);

  /// Use Case 실행
  Future<void> call(String notificationId) async {
    try {
      await _repository.deleteNotification(notificationId);
    } catch (e) {
      // 필요시 비즈니스 로직 추가
      rethrow;
    }
  }
}
