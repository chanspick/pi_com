// lib/core/models/notification_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// 알림 타입 정의
enum NotificationType {
  // ===== 기존 타입 =====
  statusChanged,       // 판매 요청 상태 변경 (승인/반려)
  paymentCompleted,    // 결제 완료
  listingSold,         // 매물 판매 완료 (판매자에게)
  purchaseConfirmed,   // 구매 확정 (판매자에게)
  shipping,            // 배송 시작
  priceAlert,          // 목표 가격 도달
  marketing,           // 광고/마케팅 알림
  system,              // 시스템 공지

  // ===== 검수/QC Flow =====
  inspectionStarted,      // 검수 시작
  inspectionPassed,       // 검수 합격
  inspectionFailed,       // 검수 불합격 + 반송 주소 등록 요청
  returnAddressExpiring,  // 반송 주소 등록 마감 임박 (50일, 55일)
  penaltyIssued,          // 위약금 부과

  // ===== 보관 서비스 Flow =====
  storageCreated,         // 보관 서비스 시작
  storageFeeStart,        // 보관료 발생 시작 (7일 무료 기간 종료)
  storageExpiring,        // 보관 기간 만료 임박 (50일, 55일, 58일)
  consignmentWarning,     // 위탁판매 전환 경고 (50일+)
  consignmentConverted,   // 위탁판매 전환 완료 (37일)
  consignmentSold,        // 위탁판매 매각 완료

  // ===== 환불 Flow =====
  refundRequested,        // 환불 신청 접수 (판매자에게)
  refundApproved,         // 환불 승인 (구매자에게)
  refundRejected,         // 환불 거부 (구매자에게)
  returnShippingRequired, // 반품 택배 발송 요청
  returnItemReceived,     // 반품 물품 수령
  refundInspecting,       // 환불 검수 중 (3영업일)
  refundInspectionPass,   // 환불 검수 합격
  refundInspectionFail,   // 환불 검수 불합격
  refundProcessing,       // 환불 처리 중
  refundCompleted,        // 환불 완료

  // ===== 정산 Flow =====
  purchaseConfirmReminder, // 구매 확정 요청 (배송 완료 5일 후)
  autoConfirmed,          // 자동 구매 확정 (7일)
  settlementPending,      // 정산 대기 중 (D+1)
  settlementCompleted,    // 정산 완료 (D+2)
}

/// NotificationType enum 헬퍼
extension NotificationTypeExtension on NotificationType {
  /// ✅ 수정: toString() → toStringValue()로 이름 변경 (Object.toString() 충돌 방지)
  String toStringValue() {
    return name; // Dart enum의 name property 사용 (더 간단)
  }
}

/// String을 NotificationType으로 변환
NotificationType notificationTypeFromString(String type) {
  // Dart enum의 values.byName 사용 (더 간단하고 안전)
  try {
    return NotificationType.values.byName(type);
  } catch (e) {
    // 매칭되는 타입이 없으면 system 반환
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
  final String? relatedSellRequestId;  // 판매 요청 ID (statusChanged 알림용)
  final String? relatedListingId;      // 리스팅 ID (listingSold 알림용)
  final String? relatedOrderId;        // 주문 ID (paymentCompleted, purchaseConfirmed 알림용)
  final String? relatedRefundId;       // 환불 ID (refund 관련 알림용)
  final String? relatedDragonBallId;   // 보관 ID (storage 관련 알림용)

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
    this.relatedOrderId,
    this.relatedRefundId,
    this.relatedDragonBallId,
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
      relatedOrderId: data['relatedOrderId'] as String?,
      relatedRefundId: data['relatedRefundId'] as String?,
      relatedDragonBallId: data['relatedDragonBallId'] as String?,
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
      'relatedOrderId': relatedOrderId,
      'relatedRefundId': relatedRefundId,
      'relatedDragonBallId': relatedDragonBallId,
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
    String? relatedOrderId,
    String? relatedRefundId,
    String? relatedDragonBallId,
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
      relatedOrderId: relatedOrderId ?? this.relatedOrderId,
      relatedRefundId: relatedRefundId ?? this.relatedRefundId,
      relatedDragonBallId: relatedDragonBallId ?? this.relatedDragonBallId,
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
