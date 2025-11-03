// lib/core/models/notification_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// 알림 타입 정의
enum NotificationType {
  statusChanged,       // 판매 요청 상태 변경 (승인/반려)
  paymentCompleted,    // 결제 완료
  listingSold,         // 매물 판매 완료 (판매자에게)
  purchaseConfirmed,   // 구매 확정 (판매자에게)
  shipping,            // 배송 시작
  priceAlert,          // 목표 가격 도달
  marketing,           // 광고/마케팅 알림
  system,              // 시스템 공지
}

/// NotificationType enum 헬퍼
extension NotificationTypeExtension on NotificationType {
  /// ✅ 수정: toString() → toStringValue()로 이름 변경 (Object.toString() 충돌 방지)
  String toStringValue() {
    switch (this) {
      case NotificationType.statusChanged:
        return 'statusChanged';
      case NotificationType.paymentCompleted:
        return 'paymentCompleted';
      case NotificationType.listingSold:
        return 'listingSold';
      case NotificationType.purchaseConfirmed:
        return 'purchaseConfirmed';
      case NotificationType.shipping:
        return 'shipping';
      case NotificationType.priceAlert:
        return 'priceAlert';
      case NotificationType.marketing:
        return 'marketing';
      case NotificationType.system:
        return 'system';
    }
  }
}

/// String을 NotificationType으로 변환
NotificationType notificationTypeFromString(String type) {
  switch (type.toLowerCase()) {
    case 'statuschanged':
      return NotificationType.statusChanged;
    case 'paymentcompleted':
      return NotificationType.paymentCompleted;
    case 'listingsold':
      return NotificationType.listingSold;
    case 'purchaseconfirmed':
      return NotificationType.purchaseConfirmed;
    case 'shipping':
      return NotificationType.shipping;
    case 'pricealert':
      return NotificationType.priceAlert;
    case 'marketing':
      return NotificationType.marketing;
    case 'system':
      return NotificationType.system;
    default:
      return NotificationType.system;
  }
}

/// 알림 모델
class NotificationModel {
  final String notificationId;
  final String userId;              // 알림 받을 사용자
  final NotificationType type;      // 알림 타입
  final String title;               // 알림 제목
  final String message;             // 알림 메시지

  // 관련 데이터
  final String? relatedSellRequestId;  // 판매 요청 ID
  final String? relatedListingId;      // 리스팅 ID

  // 메타데이터
  final bool isRead;                // 읽음 여부
  final DateTime createdAt;         // 생성 시간
  final DateTime? readAt;           // 읽은 시간

  NotificationModel({
    required this.notificationId,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.relatedSellRequestId,
    this.relatedListingId,
    required this.isRead,
    required this.createdAt,
    this.readAt,
  });

  /// Firestore DocumentSnapshot → NotificationModel
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return NotificationModel(
      notificationId: doc.id,
      userId: data['userId'] as String? ?? '',
      type: notificationTypeFromString(data['type'] as String? ?? 'system'),
      title: data['title'] as String? ?? '',
      message: data['message'] as String? ?? '',
      relatedSellRequestId: data['relatedSellRequestId'] as String?,
      relatedListingId: data['relatedListingId'] as String?,
      isRead: data['isRead'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      readAt: (data['readAt'] as Timestamp?)?.toDate(),
    );
  }

  /// NotificationModel → Map (Firestore용)
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type.toStringValue(),  // ✅ 수정: toString() → toStringValue()
      'title': title,
      'message': message,
      'relatedSellRequestId': relatedSellRequestId,
      'relatedListingId': relatedListingId,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
    };
  }

  /// copyWith 메서드
  NotificationModel copyWith({
    String? notificationId,
    String? userId,
    NotificationType? type,
    String? title,
    String? message,
    String? relatedSellRequestId,
    String? relatedListingId,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return NotificationModel(
      notificationId: notificationId ?? this.notificationId,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      relatedSellRequestId: relatedSellRequestId ?? this.relatedSellRequestId,
      relatedListingId: relatedListingId ?? this.relatedListingId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  @override
  String toString() {
    return 'NotificationModel(id: $notificationId, title: $title, isRead: $isRead)';
  }
}
