// lib/features/notification/domain/usecases/mark_as_read.dart

import '../repositories/notification_repository.dart';

/// 알림을 읽음 처리하는 Use Case
class MarkAsRead {
  final NotificationRepository _repository;

  MarkAsRead(this._repository);

  /// Use Case 실행
  Future<void> call(String notificationId) async {
    try {
      await _repository.markAsRead(notificationId);
    } catch (e) {
      // 필요시 비즈니스 로직 추가 (예: 분석 이벤트 전송)
      rethrow;
    }
  }
}
