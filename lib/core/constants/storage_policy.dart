// lib/core/constants/storage_policy.dart

/// PC 보관함 정책 상수
class StoragePolicy {
  StoragePolicy._(); // Private constructor

  // ==========================================
  // 보관 기간 정책
  // ==========================================

  /// 기본 무료 보관 기간 (일)
  static const int DEFAULT_FREE_STORAGE_DAYS = 60;

  /// 오픈 기념 이벤트 무료 보관 기간 (일)
  static const int EVENT_FREE_STORAGE_DAYS = 180;

  /// 현재 적용 중인 무료 보관 기간 (이벤트 중)
  static const int CURRENT_FREE_STORAGE_DAYS = EVENT_FREE_STORAGE_DAYS;

  /// 이벤트 진행 중 여부
  static const bool IS_EVENT_ACTIVE = true;

  /// 이벤트 종료일 (예시: 2025-12-31)
  static final DateTime EVENT_END_DATE = DateTime(2025, 12, 31, 23, 59, 59);

  /// 만료 임박 경고 기준 (일)
  static const int WARNING_DAYS_THRESHOLD = 7;

  /// 만료 긴급 경고 기준 (일)
  static const int URGENT_WARNING_DAYS_THRESHOLD = 3;

  // ==========================================
  // 보관료 정책 (60일 이후)
  // ==========================================

  /// 보관료 부과 시작 기준일 (무료 기간 종료 후)
  static const int STORAGE_FEE_START_DAY = DEFAULT_FREE_STORAGE_DAYS;

  /// 하루당 보관료율 (구매가 대비 %)
  static const double DAILY_FEE_RATE = 0.01; // 1%

  /// 소유권 이전 기준 (누적 보관료가 구매가의 100% 초과)
  static const double OWNERSHIP_TRANSFER_THRESHOLD = 100.0; // 100%

  // ==========================================
  // 배송비 정책
  // ==========================================

  /// 개별 배송비 (부품당)
  static const int INDIVIDUAL_SHIPPING_COST = 5000;

  /// 일괄 배송비 (묶음 배송)
  static const int BATCH_SHIPPING_COST = 6000;

  /// 배송비 할인 최소 부품 수
  static const int MIN_PARTS_FOR_DISCOUNT = 2;

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

  /// 개별 배송 총 비용 계산
  static int calculateIndividualShippingCost(int partCount) {
    return partCount * INDIVIDUAL_SHIPPING_COST;
  }

  /// 일괄 배송 총 비용 계산
  static int calculateBatchShippingCost(int partCount) {
    if (partCount == 0) return 0;
    return BATCH_SHIPPING_COST;
  }

  /// 배송비 절감액 계산
  static int calculateShippingSavings(int partCount) {
    if (partCount < MIN_PARTS_FOR_DISCOUNT) return 0;
    return calculateIndividualShippingCost(partCount) - calculateBatchShippingCost(partCount);
  }

  /// 보관료 계산 (무료 기간 이후)
  static int calculateStorageFee(DateTime storedAt, int purchasePrice) {
    final daysSinceStored = DateTime.now().difference(storedAt).inDays;

    // 무료 기간 내는 0원
    if (daysSinceStored <= STORAGE_FEE_START_DAY) {
      return 0;
    }

    // 무료 기간 이후 하루당 1% 부과
    final overdueDays = daysSinceStored - STORAGE_FEE_START_DAY;
    final dailyFee = (purchasePrice * DAILY_FEE_RATE).round();
    return dailyFee * overdueDays;
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
}
