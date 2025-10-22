// lib/features/admin/data/datasources/admin_notification_datasource.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/models/notification_model.dart';
import '../../../../core/constants/firebase_constants.dart';

class AdminNotificationDataSource {
  final FirebaseFirestore _firestore;

  AdminNotificationDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// 알림 생성 (Admin → 사용자)
  Future<void> sendNotificationToUser({
    required String userId,
    required NotificationType type,
    required String title,
    required String message,
    String? relatedSellRequestId,
    String? relatedListingId,  // 🆕 추가
  }) async {
    final notificationId = _firestore
        .collection(FirebaseConstants.notificationsCollection)
        .doc()
        .id;

    final notification = NotificationModel(
      notificationId: notificationId,
      userId: userId,
      type: type,
      title: title,
      message: message,
      isRead: false,
      createdAt: DateTime.now(),
      relatedSellRequestId: relatedSellRequestId,
      relatedListingId: relatedListingId,  // 🆕 추가
    );

    await _firestore
        .collection(FirebaseConstants.notificationsCollection)
        .doc(notificationId)
        .set(notification.toMap());
  }
}
