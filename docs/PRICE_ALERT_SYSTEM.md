# 가격 알림 시스템 (Price Alert System)

## 📋 개요

사용자가 원하는 부품의 목표 가격을 설정하면, 해당 가격 이하로 매물이 나타날 때 알림을 받을 수 있는 시스템입니다.

**Epic 2.3 - 가격 알림 시스템**: 95% 완료 ✅

---

## 🏗️ 시스템 아키텍처

### Firestore 컬렉션 구조

```
users/{userId}/priceAlerts/{alertId}
├─ userId: string              // 사용자 ID
├─ basePartId: string          // 기준 부품 ID (예: "RTX4090")
├─ partName: string            // 부품명 (캐시, 예: "NVIDIA RTX 4090")
├─ targetPrice: int            // 목표 가격 (원)
├─ priceAtCreation: int        // 설정 당시 최저가 (비교 기준)
├─ isActive: boolean           // 활성화 여부
├─ createdAt: timestamp        // 생성 시간
├─ triggeredAt: timestamp?     // 알림 발생 시간 (null이면 미발생)
└─ lastCheckedAt: timestamp?   // 마지막 체크 시간 (Cloud Functions)
```

### 핵심 파일 구조

```
lib/
├─ core/models/
│  ├─ price_alert_model.dart          // PriceAlert 모델
│  └─ price_history_model.dart        // PriceHistory 모델
├─ features/
│  ├─ price_alert/
│  │  ├─ data/repositories/
│  │  │  └─ price_alert_repository.dart    // Firestore CRUD
│  │  └─ presentation/
│  │     ├─ providers/
│  │     │  └─ price_alert_provider.dart   // Riverpod Providers
│  │     ├─ screens/
│  │     │  └─ price_alerts_screen.dart    // 알림 목록 화면
│  │     └─ widgets/
│  │        ├─ price_alert_setup_dialog.dart  // 설정 다이얼로그
│  │        └─ price_alert_badge_icon.dart    // 홈 화면 배지
│  └─ listing/presentation/screens/
│     └─ listing_detail_screen.dart      // 알림 버튼 추가됨
```

---

## 🎯 주요 기능

### 1. 가격 알림 설정 (PriceAlertSetupDialog)

**위치**: Listing 상세 페이지 AppBar 우측 알림 아이콘

**기능**:
- ✅ 현재 최저가 표시
- ✅ 목표 가격 입력 (숫자만, 실시간 검증)
- ✅ **실시간 할인율 계산** 및 표시
  ```
  예: 현재가 500,000원, 목표가 425,000원
  → "현재가 대비 15.0% 할인"
  ```
- ✅ 가격 포맷팅 (1000 → 1,000원)
- ✅ 기존 알림 수정/삭제
- ✅ 안내 메시지

**UX 최적화**:
```dart
// 할인율 실시간 계산
double _calculateDiscount() {
  if (_targetPrice == null || _targetPrice! >= widget.currentPrice) return 0;
  return ((widget.currentPrice - _targetPrice!) / widget.currentPrice * 100);
}
```

### 2. 가격 알림 목록 (PriceAlertsScreen)

**위치**: 마이페이지 > 가격 알림

**기능**:
- ✅ 알림 상태별 배지
  - 🟠 **대기 중**: 아직 목표가 미도달
  - 🟢 **알림 완료**: 목표가 도달, 알림 발생됨
  - ⚫ **비활성화**: 사용자가 비활성화
- ✅ 목표 가격 vs 설정 당시 가격 비교
- ✅ 할인율 표시
- ✅ 카드 클릭 시 수정/삭제 다이얼로그
- ✅ 활성 알림 개수 표시 (AppBar)

### 3. 홈 화면 배지 (PriceAlertBadgeIcon)

**위치**: 홈 화면 AppBar 우측 (로그인 시에만 표시)

**기능**:
- ✅ 활성 가격 알림 개수 배지 표시
  - 0개: 아이콘만 표시
  - 1-9개: 빨간 배지에 숫자 표시
  - 10개 이상: "9+" 표시
- ✅ 클릭 시 가격 알림 목록 화면으로 이동

---

## 📊 데이터 흐름

### 1. 알림 생성 플로우

```
사용자 → Listing 상세 페이지 → 알림 아이콘 클릭
  ↓
PriceAlertSetupDialog 표시
  ↓
목표 가격 입력 (실시간 할인율 표시)
  ↓
PriceAlertActions.addAlert() 호출
  ↓
PriceAlertRepository.addPriceAlert()
  ↓
Firestore: users/{userId}/priceAlerts/{alertId} 생성
  ↓
priceAlertsProvider 자동 업데이트 (StreamProvider)
  ↓
UI 실시간 반영 (홈 배지, 알림 목록)
```

### 2. 알림 체크 플로우 (TODO: Cloud Functions)

```
Cloud Functions 스케줄러 (매일 실행)
  ↓
활성 알림 조회 (isActive == true)
  ↓
각 알림별 basePartId의 현재 최저가 조회
  ↓
IF 현재 최저가 <= 목표 가격:
  ├─ NotificationHelper.notifyPriceAlert() 호출
  ├─ triggeredAt 업데이트
  ├─ isActive = false 설정
  └─ (선택) FCM 푸시 알림 전송
```

---

## 🎨 사용자 경험 (UX) 최적화

### 1. 직관적인 가격 입력

```dart
// 가격 포맷팅
String _formatPrice(int price) {
  return price.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]},',
  );
}

// 입력 제한: 숫자만
inputFormatters: [FilteringTextInputFormatter.digitsOnly]
```

### 2. 실시간 피드백

- 목표 가격 입력 시 즉시 할인율 계산 및 표시
- 할인율이 있을 때 녹색 배지로 강조
- 현재가보다 높은 가격 입력 시 할인율 표시 안 함

### 3. 상태 표시

```dart
String get statusText {
  if (!isActive) return '비활성화';
  if (triggeredAt != null) return '알림 완료';
  return '대기 중';
}
```

### 4. 에러 방지

- basePartId 없는 상품은 알림 설정 불가 안내
- 로그인하지 않은 사용자는 로그인 안내
- 입력 검증: 빈 값, 0원 이하 방지

---

## 🔧 Riverpod Providers

### 1. priceAlertsProvider

```dart
final priceAlertsProvider = StreamProvider.autoDispose<List<PriceAlert>>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return Stream.value([]);

  final repository = ref.watch(priceAlertRepositoryProvider);
  return repository.getPriceAlertsStream(currentUser.uid);
});
```

**특징**: 실시간 동기화 (Firestore snapshots)

### 2. activePriceAlertsCountProvider

```dart
final activePriceAlertsCountProvider = Provider.autoDispose<int>((ref) {
  final alertsAsync = ref.watch(priceAlertsProvider);
  return alertsAsync.when(
    data: (alerts) => alerts.where((alert) => alert.isActive).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});
```

**사용처**: 홈 화면 배지, 알림 목록 AppBar

### 3. priceAlertActionsProvider

```dart
final priceAlertActionsProvider = Provider.autoDispose<PriceAlertActions?>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return null;

  final repository = ref.watch(priceAlertRepositoryProvider);
  return PriceAlertActions(repository, currentUser.uid);
});
```

**제공 메서드**:
- `addAlert()` - 새 알림 추가
- `updateTargetPrice()` - 목표 가격 수정
- `toggleStatus()` - 활성화/비활성화
- `deleteAlert()` - 알림 삭제
- `getAlertForBasePart()` - 기존 알림 확인

---

## 📈 가격 이력 시스템 (Epic 2.2)

### PriceHistory 모델

```dart
class PriceHistory {
  final String id;              // "RTX4090_2025-11-03"
  final String basePartId;      // 기준 부품 ID
  final DateTime date;          // 날짜
  final int lowestPrice;        // 최저가
  final int averagePrice;       // 평균가
  final int highestPrice;       // 최고가
  final int transactionCount;   // 거래 수
}
```

### PriceHistoryRepository 메서드

```dart
// 최근 N일 가격 이력 조회
Future<List<PriceHistory>> getPriceHistory(String basePartId, {int days = 30})

// 특정 날짜 이력 조회
Future<PriceHistory?> getPriceHistoryByDate(String basePartId, DateTime date)

// 현재 가격 통계 계산
Future<Map<String, dynamic>> calculatePriceStats(String basePartId)
```

---

## ☁️ Cloud Functions (TODO)

### 1. checkPriceAlerts (스케줄러)

```typescript
export const checkPriceAlerts = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async (context) => {
    // 1. 활성 알림 조회
    const alerts = await getActivePriceAlerts();

    for (const alert of alerts) {
      // 2. 현재 최저가 조회
      const currentPrice = await getLowestPrice(alert.basePartId);

      // 3. 목표가 도달 체크
      if (currentPrice <= alert.targetPrice) {
        // 4. 알림 발송
        await sendPriceNotification(alert.userId, alert);

        // 5. 알림 상태 업데이트
        await updateAlertTriggered(alert.alertId);
      }
    }
  });
```

### 2. aggregatePriceHistory (스케줄러)

```typescript
export const aggregatePriceHistory = functions.pubsub
  .schedule('every day 00:00')
  .onRun(async (context) => {
    const baseParts = await getAllBaseParts();

    for (const part of baseParts) {
      const stats = await calculateDailyPriceStats(part.id);

      await savePriceHistory({
        basePartId: part.id,
        date: new Date(),
        ...stats
      });
    }
  });
```

---

## 🧪 테스트 시나리오

### 1. 알림 생성 테스트

1. Listing 상세 페이지 이동
2. 우측 상단 알림 아이콘 클릭
3. 목표 가격 입력 (예: 현재가 500,000원 → 목표가 450,000원)
4. 할인율 표시 확인 ("현재가 대비 10.0% 할인")
5. "설정" 버튼 클릭
6. 마이페이지 > 가격 알림에서 목록 확인

### 2. 알림 수정 테스트

1. 마이페이지 > 가격 알림
2. 알림 카드 클릭
3. 목표 가격 수정
4. "수정" 버튼 클릭
5. 변경사항 즉시 반영 확인

### 3. 배지 표시 테스트

1. 홈 화면에서 가격 알림 아이콘 확인
2. 활성 알림 개수 배지 확인
3. 아이콘 클릭 시 알림 목록 이동 확인

---

## 📝 향후 개선사항

### Phase 1 (현재 완료)
- ✅ 기본 알림 CRUD
- ✅ UI/UX 최적화
- ✅ 실시간 동기화
- ✅ 상태 관리

### Phase 2 (예정)
- ⏳ Cloud Functions 자동화
- ⏳ FCM 푸시 알림
- ⏳ 가격 이력 자동 집계

### Phase 3 (향후)
- ⏳ 가격 변동 그래프 표시
- ⏳ 알림 주기 설정 (즉시/일일/주간)
- ⏳ 알림 발송 이력 조회
- ⏳ 가격 예측 AI 기능

---

## 📊 성능 최적화

### Firestore 쿼리 최적화

```dart
// 복합 인덱스 필요
collection: users/{userId}/priceAlerts
where: isActive == true
orderBy: createdAt desc
```

### StreamProvider 자동 정리

```dart
// autoDispose로 메모리 누수 방지
StreamProvider.autoDispose<List<PriceAlert>>
```

### 배치 처리

```dart
// 대량 알림 체크 시 배치 처리
for (int i = 0; i < alerts.length; i += 100) {
  final batch = alerts.skip(i).take(100).toList();
  await processBatch(batch);
}
```

---

## 🎓 사용자 가이드

### 가격 알림 설정 방법

1. **원하는 부품 찾기**
   - 홈 > 부품 스토어
   - 상품 상세 페이지 이동

2. **알림 설정**
   - 우측 상단 🔔 아이콘 클릭
   - 목표 가격 입력
   - "설정" 버튼 클릭

3. **알림 확인**
   - 마이페이지 > 가격 알림
   - 또는 홈 화면 우측 상단 🔔 배지 클릭

4. **알림 관리**
   - 알림 카드 클릭하여 수정/삭제
   - 비활성화 후 재활성화 가능

---

**작성일**: 2025-11-03
**버전**: 1.0
**상태**: 95% 완료 (Cloud Functions 자동화 대기)
