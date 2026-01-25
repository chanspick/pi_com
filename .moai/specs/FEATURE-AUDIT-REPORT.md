# PiCom 피처별 감사 보고서

> **생성일**: 2026-01-22
> **분석 대상**: 19개 피처
> **발견된 이슈**: Critical 8개, Medium 6개, Low 5개

---

## 📊 피처 상태 대시보드

### 🔴 Critical (즉시 수정 필요)

#### 1. Checkout (결제 진행)
**상태**: 부분 작동 | **품질**: 낮음

| 문제 유형 | 내용 | 파일:라인 |
|----------|------|----------|
| Debug Print | Error 로깅 | `checkout_screen.dart:331` |
| Debug Print | 결제 정보 출력 | `checkout_screen.dart:553-562` |
| Debug Print | 구분선 출력 | `checkout_screen.dart:734` |
| 하드코딩 | 배송비 4500원 | `checkout_screen.dart:265, 533, 836` |
| TODO | 주문 내역 화면 이동 | `payment_success_screen.dart:124` |
| TODO | 고객센터 화면 이동 | `payment_failure_screen.dart:213` |
| TODO | 장바구니 화면 이동 | `payment_cancel_screen.dart:162` |
| 테스트 모드 | UI에 테스트 모드 안내 표시 | `checkout_screen.dart:1084` |

**수정 작업**:
- [ ] Debug print 제거 또는 logger로 교체
- [ ] 배송비 상수화 또는 DB 연동
- [ ] 결제 결과 화면 네비게이션 구현
- [ ] 테스트 모드 안내 조건부 표시

---

#### 2. Payment (결제 처리)
**상태**: 부분 작동 | **품질**: 중간

| 문제 유형 | 내용 | 파일:라인 |
|----------|------|----------|
| TODO | 주문 내역 화면 이동 | `payment_success_screen.dart:124` |
| TODO | 고객센터 화면 이동 | `payment_failure_screen.dart:213` |
| TODO | 장바구니 화면 이동 | `payment_cancel_screen.dart:162` |
| Stub 파일 | Toss 결제 스텁 | `toss_payment_web_screen_stub.dart` |
| 에러 처리 | Generic exception throwing | `payment_repository_impl.dart` |

**수정 작업**:
- [ ] 결제 성공/실패/취소 후 네비게이션 구현
- [ ] 에러 메시지 사용자 친화적으로 개선
- [ ] Stub 파일 정리

---

#### 3. Refund (환불)
**상태**: 미완성 | **품질**: 낮음

| 문제 유형 | 내용 | 파일:라인 |
|----------|------|----------|
| TODO x8 | 실제 상품명 가져오기 | `refund_repository_impl.dart:61,112,132,163,185,213,246,277` |
| TODO | 재발송 주소 입력 다이얼로그 | `refund_detail_screen.dart:497` |
| TODO | 환불 취소 처리 | `refund_detail_screen.dart:675` |
| 하드코딩 | '주문 상품' 플레이스홀더 | 전체 |
| 안티패턴 | Screen에서 직접 Repository 생성 | `refund_detail_screen.dart` |

**수정 작업**:
- [ ] Order에서 실제 상품명 조회 로직 구현
- [ ] 재발송 주소 입력 다이얼로그 구현
- [ ] 환불 취소 기능 구현
- [ ] Provider 기반 상태 관리로 리팩토링

---

### 🟡 Medium (조만간 수정 필요)

#### 4. Recommendation (AI 추천)
**상태**: 부분 작동 | **품질**: 양호 (아키텍처)

| 문제 유형 | 내용 | 파일:라인 |
|----------|------|----------|
| TODO | CPU 성능 티어 구현 필요 | `recommendation_repository_impl.dart:111` |
| TODO | GPU 성능 티어 구현 필요 | `recommendation_repository_impl.dart:112` |
| Debug Print | 부품 재고 출력 | `recommendation_repository_impl.dart:52-60` |

**수정 작업**:
- [ ] CPU/GPU 성능 티어 계산 로직 구현
- [ ] Debug print 제거
- [ ] 추천 알고리즘 검증

---

#### 5. Admin (관리자)
**상태**: 부분 작동 | **품질**: 중간 (중복 코드)

| 문제 유형 | 내용 | 파일 |
|----------|------|------|
| 중복 파일 | 이전 버전 유지됨 | `listing_list_page.dart` (OLD) |
| 중복 파일 | 이전 버전 유지됨 | `user_list_page.dart` (OLD) |
| TODO | 검색/필터 UI 추가 | `listing_list_page.dart:17` |
| TODO | 검색 UI 추가 | `user_list_page.dart:17` |
| TODO | 실제 삭제 로직 구현 | `listing_list_page_improved.dart:966` |

**수정 작업**:
- [ ] OLD 버전 파일 삭제 (improved 버전 사용)
- [ ] 삭제 로직 구현
- [ ] 검색/필터 기능 추가

---

#### 6. Listing (매물)
**상태**: 부분 작동 | **품질**: 중간 (백업 파일)

| 문제 유형 | 내용 | 파일 |
|----------|------|------|
| 백업 파일 | 삭제 필요 | `part_shop_screen_backup.dart` |
| 백업 파일 | 상태 불명확 | `part_shop_screen_enhanced.dart` |

**수정 작업**:
- [ ] 백업 파일 삭제
- [ ] Enhanced 버전 검토 후 통합 또는 삭제

---

### ⚠️ Partial (기능 보완 필요)

#### 7. Dragon Ball (드래곤볼 보관)
**상태**: 초기 단계 | **품질**: 기본

- 새로운 기능으로 대부분 UI만 구현됨
- 보관 규칙 검증 로직 부족
- 배송 요청 비즈니스 로직 미완성

---

#### 8. Sell Request (판매 요청)
**상태**: 부분 작동 | **품질**: 양호

| 문제 유형 | 내용 | 파일:라인 |
|----------|------|----------|
| TODO | 카테고리 인자 확장 필요 | `finished_pc_sell_screen.dart:137` |

---

#### 9. My Page (마이페이지)
**상태**: 부분 작동 | **품질**: 양호

| 문제 유형 | 내용 | 파일:라인 |
|----------|------|----------|
| TODO | buyerId로 조회 구현 필요 | `sales_history_screen.dart:226` |

---

#### 10. Notification (알림)
**상태**: 기본 | **품질**: 기본

| 문제 유형 | 내용 | 파일 |
|----------|------|------|
| 디렉토리 오타 | `presentations` → `presentation` | `/features/notification/presentations/` |

---

#### 11. Web Public (웹 공개 페이지)
**상태**: 대부분 작동 | **품질**: 양호

| 문제 유형 | 내용 | 파일:라인 |
|----------|------|----------|
| TODO x2 | 로그아웃 구현 | `web_navbar.dart:109, 197` |

---

### ✅ Working (안정적)

| 피처 | 상태 | 비고 |
|------|------|------|
| address | ✅ 안정 | 웹/모바일 분리 잘됨 |
| auth | ✅ 안정 | 딜레이 처리 있음 |
| cart | ✅ 안정 | 배송비 하드코딩 |
| order | ✅ 안정 | 읽기 전용 |
| parts_price | ✅ 안정 | - |
| price_alert | ⚠️ 기본 | 검증 부족 |
| price_history | ⚠️ 최소 | parts_price와 공유 |
| home | ✅ 최소 | 기본 UI |

---

## 📁 삭제 필요 파일

```
lib/features/admin/presentation/screens/listing_list_page.dart      # OLD
lib/features/admin/presentation/screens/user_list_page.dart         # OLD
lib/features/listing/presentation/screens/part_shop_screen_backup.dart
lib/features/listing/presentation/screens/part_shop_screen_enhanced.dart  # 검토 후
```

---

## 🔧 전역 수정 사항

### 1. 배송비 상수화
현재 4곳에서 `4500` 하드코딩됨:
- `checkout_screen.dart:265, 533, 836`
- `cart_summary.dart:36`

```dart
// lib/core/constants/shipping_constants.dart (신규 생성)
class ShippingConstants {
  static const int defaultShippingFee = 4500;
  static const int freeShippingThreshold = 50000; // 5만원 이상 무료배송?
}
```

### 2. Debug Print 제거
Logger 도입 또는 조건부 출력:
```dart
// lib/core/utils/logger.dart (신규 생성)
import 'package:flutter/foundation.dart';

class AppLogger {
  static void debug(String message) {
    if (kDebugMode) {
      debugPrint('[DEBUG] $message');
    }
  }

  static void error(String message, [Object? error]) {
    if (kDebugMode) {
      debugPrint('[ERROR] $message: $error');
    }
    // Production: Crashlytics 등에 보고
  }
}
```

### 3. 에러 핸들링 표준화
`lib/core/errors/failures.dart` 도입 (로드맵 참조)

---

## ✅ 피처별 수정 체크리스트

### Phase 1: Critical 피처 수정 (1주)
- [ ] **checkout** - Debug print 제거, 네비게이션 구현
- [ ] **payment** - 결과 화면 네비게이션 구현
- [ ] **refund** - 상품명 조회, Provider 리팩토링

### Phase 2: Medium 피처 수정 (1주)
- [ ] **recommendation** - 성능 티어 구현
- [ ] **admin** - 중복 파일 삭제, 삭제 로직 구현
- [ ] **listing** - 백업 파일 삭제

### Phase 3: Partial 피처 보완 (1주)
- [ ] **dragon_ball** - 검증 로직 추가
- [ ] **sell_request** - 카테고리 필터
- [ ] **my_page** - buyerId 조회
- [ ] **notification** - 디렉토리 이름 수정
- [ ] **web_public** - 로그아웃 구현

### Phase 4: 전역 개선 (3-5일)
- [ ] 배송비 상수화
- [ ] Logger 도입
- [ ] 에러 핸들링 표준화

---

*이 문서는 Alfred (MoAI-ADK)에 의해 생성되었습니다.*
*최종 수정: 2026-01-22*
