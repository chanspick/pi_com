// lib/core/constants/storage_policy.dart

/// PC 보관함 정책 상수
class StoragePolicy {
  StoragePolicy._(); // Private constructor

  // ==========================================
  // 보관 기간 정책
  // ==========================================

  /// 기본 무료 보관 기간 (일) - 이용약관 제9조 기준
  static const int DEFAULT_FREE_STORAGE_DAYS = 7;

  /// 오픈 기념 이벤트 무료 보관 기간 (일) - 종료됨
  static const int EVENT_FREE_STORAGE_DAYS = 7;

  /// 현재 적용 중인 무료 보관 기간
  static const int CURRENT_FREE_STORAGE_DAYS = DEFAULT_FREE_STORAGE_DAYS;

  /// 이벤트 진행 중 여부
  static const bool IS_EVENT_ACTIVE = false;

  /// 이벤트 종료일
  static final DateTime EVENT_END_DATE = DateTime(2025, 1, 1, 0, 0, 0);

  /// 만료 임박 경고 기준 (일)
  static const int WARNING_DAYS_THRESHOLD = 7;

  /// 만료 긴급 경고 기준 (일)
  static const int URGENT_WARNING_DAYS_THRESHOLD = 3;

  // ==========================================
  // 보관료 정책 (7일 이후)
  // ==========================================

  /// 보관료 부과 시작 기준일 (무료 기간 종료 후)
  static const int STORAGE_FEE_START_DAY = DEFAULT_FREE_STORAGE_DAYS;

  /// 하루당 보관료율 (구매가 대비 %) - 보관서비스 약관 제5조
  static const double DAILY_FEE_RATE = 0.005; // 0.5%

  /// 최대 보관 기간 (일) - 카카오페이 시스템 제약
  static const int MAX_STORAGE_DAYS = 59;

  /// 위탁판매 전환 경고 기준일 (일)
  static const int CONSIGNMENT_WARNING_DAY = 50;

  /// 60일 경과 시 최대 보관료 누적율 (%)
  static const double MAX_STORAGE_FEE_PERCENTAGE = 30.0; // 30%

  /// 위탁판매 시 매각비용 비율 - 보관서비스 약관 제8조
  static const double CONSIGNMENT_SALE_COST_RATE = 0.10; // 10%

  /// 소유권 이전 기준 (누적 보관료가 구매가의 100% 초과) - 구버전, 제거 예정
  @Deprecated('Use MAX_STORAGE_FEE_PERCENTAGE instead')
  static const double OWNERSHIP_TRANSFER_THRESHOLD = 100.0; // 100%

  // ==========================================
  // 배송비 정책
  // ==========================================

  /// 부품 배송비 (케이스 미포함)
  static const int PARTS_SHIPPING_COST = 4500;

  /// 완제품 배송비 (케이스 포함)
  static const int COMPLETE_PC_SHIPPING_COST = 5000;

  /// 기본 배송비 (하위 호환성을 위해 유지)
  @Deprecated('Use PARTS_SHIPPING_COST or COMPLETE_PC_SHIPPING_COST instead')
  static const int INDIVIDUAL_SHIPPING_COST = 4500;

  /// 일괄 배송비 (하위 호환성을 위해 유지)
  @Deprecated('Use PARTS_SHIPPING_COST or COMPLETE_PC_SHIPPING_COST instead')
  static const int BATCH_SHIPPING_COST = 4500;

  // ==========================================
  // 계산 메서드
  // ==========================================

  /// 만료일 계산
  static DateTime calculateExpirationDate(DateTime storedAt) {
    return storedAt.add(Duration(days: CURRENT_FREE_STORAGE_DAYS));
  }

  /// 만료까지 남은 일수
  static int calculateDaysUntilExpiration(DateTime storedAt) {
    final expiresAt = calculateExpirationDate(storedAt);
    final now = DateTime.now();
    if (expiresAt.isBefore(now)) return 0;
    return expiresAt.difference(now).inDays;
  }

  /// 만료 임박 여부
  static bool isExpiringSoon(DateTime storedAt) {
    final days = calculateDaysUntilExpiration(storedAt);
    return days <= WARNING_DAYS_THRESHOLD && days > 0;
  }

  /// 긴급 경고 여부
  static bool isUrgentWarning(DateTime storedAt) {
    final days = calculateDaysUntilExpiration(storedAt);
    return days <= URGENT_WARNING_DAYS_THRESHOLD && days > 0;
  }

  /// 만료됨 여부
  static bool isExpired(DateTime storedAt) {
    return calculateDaysUntilExpiration(storedAt) <= 0;
  }

  /// 배송비 계산 (케이스 포함 여부로 판단)
  static int calculateShippingCost({required bool hasCase}) {
    return hasCase ? COMPLETE_PC_SHIPPING_COST : PARTS_SHIPPING_COST;
  }

  /// 개별 배송 총 비용 계산 (하위 호환성)
  @Deprecated('Use calculateShippingCost instead')
  static int calculateIndividualShippingCost(int partCount) {
    return partCount * PARTS_SHIPPING_COST;
  }

  /// 일괄 배송 총 비용 계산 (하위 호환성)
  @Deprecated('Use calculateShippingCost instead')
  static int calculateBatchShippingCost(int partCount) {
    if (partCount == 0) return 0;
    return PARTS_SHIPPING_COST;
  }

  /// 배송비 절감액 계산 (하위 호환성)
  @Deprecated('No longer applicable with flat shipping fee')
  static int calculateShippingSavings(int partCount) {
    return 0; // 더 이상 배송비 할인 없음
  }

  /// 보관료 계산 (무료 기간 이후)
  static int calculateStorageFee(DateTime storedAt, int purchasePrice) {
    final daysSinceStored = DateTime.now().difference(storedAt).inDays;

    // 무료 기간 내는 0원
    if (daysSinceStored <= STORAGE_FEE_START_DAY) {
      return 0;
    }

    // 무료 기간 이후 하루당 0.5% 부과 (최대 30%)
    final overdueDays = daysSinceStored - STORAGE_FEE_START_DAY;
    final dailyFee = (purchasePrice * DAILY_FEE_RATE).round();
    final totalFee = dailyFee * overdueDays;

    // 최대 보관료율 30% 제한
    final maxFee = (purchasePrice * MAX_STORAGE_FEE_PERCENTAGE / 100).round();
    return totalFee > maxFee ? maxFee : totalFee;
  }

  /// 보관료율 계산 (구매가 대비 %)
  static double calculateStorageFeePercentage(int storageFee, int purchasePrice) {
    if (purchasePrice == 0) return 0;
    return (storageFee / purchasePrice) * 100;
  }

  /// 소유권 이전 대상 여부
  static bool shouldTransferOwnership(int storageFee, int purchasePrice) {
    final percentage = calculateStorageFeePercentage(storageFee, purchasePrice);
    return percentage >= OWNERSHIP_TRANSFER_THRESHOLD;
  }

  /// 이벤트 종료까지 남은 일수
  static int getDaysUntilEventEnd() {
    final now = DateTime.now();
    if (EVENT_END_DATE.isBefore(now)) return 0;
    return EVENT_END_DATE.difference(now).inDays;
  }

  /// 보관 일수 계산
  static int calculateStorageDays(DateTime storedAt) {
    return DateTime.now().difference(storedAt).inDays;
  }

  /// 최대 보관 기간 초과 여부
  static bool hasExceededMaxStorageDays(DateTime storedAt) {
    return calculateStorageDays(storedAt) > MAX_STORAGE_DAYS;
  }

  /// 위탁판매 전환 경고 여부 (50일 이상)
  static bool shouldShowConsignmentWarning(DateTime storedAt) {
    final days = calculateStorageDays(storedAt);
    return days >= CONSIGNMENT_WARNING_DAY;
  }

  /// 위탁판매 전환까지 남은 일수 (60일 기준)
  static int getDaysUntilConsignment(DateTime storedAt) {
    final days = calculateStorageDays(storedAt);
    final remainingDays = 60 - days;
    return remainingDays > 0 ? remainingDays : 0;
  }
}
