// lib/features/notification/domain/usecases/get_notifications_stream.dart

import '../../../../core/models/notification_model.dart';
import '../repositories/notification_repository.dart';

/// 사용자의 알림 목록 스트림을 가져오는 Use Case
class GetNotificationsStream {
  final NotificationRepository _repository;

  GetNotificationsStream(this._repository);

  /// Use Case 실행
  Stream<List<NotificationModel>> call(String userId) {
    try {
      return _repository.getNotificationsStream(userId);
    } catch (e) {
      // 필요시 비즈니스 로직 추가 (예: 에러 로깅)
      rethrow;
    }
  }
}
