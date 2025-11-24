// lib/core/constants/notification_constants.dart

import '../models/sell_request_model.dart';

/// 알림 관련 상수
class NotificationConstants {
  NotificationConstants._();

  static const int pageSize = 50;
  static const int maxNotifications = 100;

  static const String statusChangedIcon = '✅';
  static const String paymentCompletedIcon = '💰';
  static const String systemIcon = '🔔';
}

/// 알림 메시지 헬퍼
class NotificationMessageHelper {
  NotificationMessageHelper._();

  /// 상태 변경 알림 제목
  static String getStatusChangedTitle(SellRequestStatus newStatus) {
    switch (newStatus) {
      case SellRequestStatus.approved:
        return '판매 요청 승인됨';
      case SellRequestStatus.rejected:
        return '판매 요청 거절됨';
      case SellRequestStatus.sold:
        return '판매 완료';
      case SellRequestStatus.pending:
        return '판매 요청 상태 변경';
      case SellRequestStatus.testing:
        return '판매 요청 테스트 중';
      case SellRequestStatus.cancelled:
        return '판매 요청 취소됨';
    }
  }

  /// 상태 변경 알림 메시지
  static String getStatusChangedMessage(
      String partName,
      SellRequestStatus oldStatus,
      SellRequestStatus newStatus,
      ) {
    switch (newStatus) {
      case SellRequestStatus.approved:
        return '$partName 판매 요청이 승인되었습니다. 곧 리스팅에 등록됩니다.';
      case SellRequestStatus.rejected:
        return '$partName 판매 요청이 거절되었습니다. 자세한 내용은 관리자 메모를 확인해주세요.';
      case SellRequestStatus.sold:
        return '$partName이(가) 판매되었습니다! 대금 입금을 기다려주세요.';
      case SellRequestStatus.pending:
        return '$partName 판매 요청 상태가 변경되었습니다.';
      case SellRequestStatus.testing:
        return '$partName 판매 요청이 테스트 중입니다. 검수가 완료되면 알려드리겠습니다.';
      case SellRequestStatus.cancelled:
        return '$partName 판매 요청이 취소되었습니다.';
    }
  }

  /// 대금 입금 완료 메시지
  static String getPaymentCompletedMessage(String partName, int amount) {
    return '$partName 판매 대금 ${_formatAmount(amount)}원이 입금되었습니다.';
  }

  /// 시스템 공지 메시지 (기본)
  static String getSystemMessage(String message) {
    return message;
  }

  /// 금액 포맷팅
  static String _formatAmount(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  }
}
