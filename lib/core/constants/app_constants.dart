// lib/core/constants/app_constants.dart

/// 앱 전역 상수
///
/// PiCom 앱에서 사용되는 공통 상수들을 정의합니다.
/// 배송비, HTTP 타임아웃, 페이지네이션, 드래곤볼 보관함, 환불/구매 확정 등
/// 비즈니스 로직에 필요한 상수들이 포함됩니다.
class AppConstants {
  AppConstants._();

  // ==========================================
  // 배송비 상수
  // ==========================================

  /// 기본 배송비 (원)
  static const int defaultShippingFee = 4500;

  // ==========================================
  // HTTP 타임아웃 상수
  // ==========================================

  /// HTTP 연결 타임아웃
  static const Duration httpConnectTimeout = Duration(seconds: 10);

  /// HTTP 응답 수신 타임아웃
  static const Duration httpReceiveTimeout = Duration(seconds: 30);

  // ==========================================
  // 페이지네이션 상수
  // ==========================================

  /// 기본 페이지 크기
  static const int defaultPageSize = 20;

  /// 최대 페이지 크기
  static const int maxPageSize = 100;

  // ==========================================
  // 드래곤볼 보관함 상수
  // ==========================================

  /// 드래곤볼 보관 기간 (일)
  static const int dragonBallStorageDays = 30;

  /// 드래곤볼 만료 임박 경고 기준 (일)
  static const int dragonBallWarningDays = 7;

  // ==========================================
  // 환불 및 구매 확정 상수
  // ==========================================

  /// 환불 승인 처리 기한 (영업일)
  static const int refundApprovalDeadlineDays = 2;

  /// 자동 구매 확정 기간 (일)
  ///
  /// 배송 완료 후 이 기간이 지나면 자동으로 구매가 확정됩니다.
  static const int autoConfirmPurchaseDays = 7;
}
