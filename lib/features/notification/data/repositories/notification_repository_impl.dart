// lib/features/notification/data/repositories/notification_repository_impl.dart

import '../../../../core/models/notification_model.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_datasource.dart';

/// Notification Repository 구현체
/// DataSource를 래핑하여 Domain Layer와 분리
class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationDataSource _dataSource;

  NotificationRepositoryImpl({
    required NotificationDataSource dataSource,
  }) : _dataSource = dataSource;

  @override
  Stream<List<NotificationModel>> getNotificationsStream(String userId) {
    return _dataSource.getNotificationsStream(userId);
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    return await _dataSource.markAsRead(notificationId);
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    return await _dataSource.deleteNotification(notificationId);
  }

  @override
  Future<void> clearAllNotifications(String userId) async {
    return await _dataSource.clearAllNotifications(userId);
  }

  @override
  Future<int> getUnreadCount(String userId) async {
    return await _dataSource.getUnreadCount(userId);
  }
}
