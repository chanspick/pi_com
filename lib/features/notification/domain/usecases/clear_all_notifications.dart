// lib/features/notification/domain/usecases/clear_all_notifications.dart

import '../repositories/notification_repository.dart';

/// 사용자의 모든 알림을 삭제하는 Use Case
class ClearAllNotifications {
  final NotificationRepository _repository;

  ClearAllNotifications(this._repository);

  /// Use Case 실행
  Future<void> call(String userId) async {
    try {
      await _repository.clearAllNotifications(userId);
    } catch (e) {
      // 필요시 비즈니스 로직 추가
      rethrow;
    }
  }
}
