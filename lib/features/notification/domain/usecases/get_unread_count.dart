// lib/features/notification/domain/usecases/get_unread_count.dart

import '../repositories/notification_repository.dart';

/// 읽지 않은 알림 개수를 가져오는 Use Case
class GetUnreadCount {
  final NotificationRepository _repository;

  GetUnreadCount(this._repository);

  /// Use Case 실행
  Future<int> call(String userId) async {
    try {
      return await _repository.getUnreadCount(userId);
    } catch (e) {
      // 에러 발생 시 0 반환
      return 0;
    }
  }
}
