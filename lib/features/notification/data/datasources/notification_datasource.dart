// lib/features/notification/data/datasources/notification_datasource.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/models/notification_model.dart';
import '../../../../core/constants/firebase_constants.dart';
import '../../../../core/constants/notification_constants.dart';

/// Notification DataSource 인터페이스
abstract class NotificationDataSource {
  /// 사용자의 알림 목록 스트림
  Stream<List<NotificationModel>> getNotificationsStream(String userId);

  /// 알림을 읽음 처리
  Future<void> markAsRead(String notificationId);

  /// 알림 삭제
  Future<void> deleteNotification(String notificationId);

  /// 사용자의 모든 알림 삭제
  Future<void> clearAllNotifications(String userId);

  /// 읽지 않은 알림 개수 (한 번만 가져오기)
  Future<int> getUnreadCount(String userId);
}

/// Notification DataSource 구현체
class NotificationDataSourceImpl implements NotificationDataSource {
  final FirebaseFirestore _firestore;

  NotificationDataSourceImpl({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  @override
  Stream<List<NotificationModel>> getNotificationsStream(String userId) {
    try {
      return _firestore
          .collection(FirebaseConstants.notificationsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(NotificationConstants.pageSize)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      throw Exception('Failed to get notifications stream: $e');
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection(FirebaseConstants.notificationsCollection)
          .doc(notificationId)
          .update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection(FirebaseConstants.notificationsCollection)
          .doc(notificationId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  @override
  Future<void> clearAllNotifications(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(FirebaseConstants.notificationsCollection)
          .where('userId', isEqualTo: userId)
          .get();

      // Batch delete
      final batch = _firestore.batch();
      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to clear all notifications: $e');
    }
  }

  @override
  Future<int> getUnreadCount(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(FirebaseConstants.notificationsCollection)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .count()
          .get();

      return querySnapshot.count ?? 0;
    } catch (e) {
      throw Exception('Failed to get unread count: $e');
    }
  }
}
