# SPEC-PHASE0-001: Implementation Plan

---

## TAG BLOCK

```yaml
spec_id: SPEC-PHASE0-001
document_type: plan
created: 2026-01-22T00:00:00+09:00
status: Planned
```

---

## 1. Executive Summary

### 1.1 목표

Phase 0는 PiCom 프로젝트의 안정적인 개발 기반을 마련하는 단계입니다. 전역 인프라 구축과 Critical 버그 수정을 통해 후속 Phase들의 원활한 진행을 보장합니다.

### 1.2 범위

- **0.1 전역 인프라 구축**: Logger, Constants, Failures, Result 타입
- **0.2 Critical 버그 수정 (Flutter)**: Debug print 제거, 배송비 상수화, HTTP 타임아웃, Kakao SDK 키
- **0.3 Critical 버그 수정 (Backend)**: Admin UID 환경변수화, Firestore 인덱스, 결제 트랜잭션

### 1.3 예상 기간

| 마일스톤 | 우선순위 | 복잡도 |
|----------|----------|--------|
| M1: 전역 인프라 구축 | Primary Goal | Medium |
| M2: Flutter Critical 수정 | Primary Goal | Medium |
| M3: Backend Critical 수정 | Secondary Goal | High |
| M4: 통합 검증 | Final Goal | Low |

---

## 2. Technical Approach

### 2.1 아키텍처 설계 방향

#### 2.1.1 Logger 시스템

**설계 원칙**:
- Singleton 패턴으로 전역 접근 가능
- 환경별 동작 분리 (Debug vs Release)
- 확장 가능한 구조 (Crashlytics, Analytics 연동 준비)

```dart
// 설계 스케치
enum LogLevel { debug, info, warning, error }

class AppLogger {
  // 환경별 출력 전략
  static void _log(LogLevel level, String message, String? tag) {
    if (!kDebugMode && level != LogLevel.error) return;
    // ...
  }
}
```

#### 2.1.2 에러 핸들링 계층

**설계 원칙**:
- sealed class로 컴파일 타임 안전성 보장
- 도메인별 Failure 타입 정의
- 사용자 친화적 메시지와 기술적 에러 코드 분리

```
Failure (sealed base)
├── NetworkFailure
├── AuthFailure
├── PaymentFailure
├── ServerFailure
├── ValidationFailure
└── NotFoundFailure
```

#### 2.1.3 Result 타입

**설계 원칙**:
- 함수형 프로그래밍 패턴 적용
- Either/Result 패턴으로 명시적 에러 처리
- 패턴 매칭을 통한 안전한 결과 처리

```dart
// 사용 예시
final result = await repository.getUser(id);
return result.when(
  success: (user) => UserLoaded(user),
  failure: (failure) => UserError(failure.message),
);
```

### 2.2 Backend 설계 방향

#### 2.2.1 Admin 설정 중앙화

```typescript
// functions/src/config/admin.ts
import * as functions from 'firebase-functions';

export function getAdminUserIds(): string[] {
  const adminIds = functions.config().admin?.user_ids;
  if (!adminIds) {
    console.warn('ADMIN_USER_IDS not configured');
    return [];
  }
  return adminIds.split(',').map(id => id.trim());
}
```

#### 2.2.2 결제 트랜잭션 패턴

```typescript
// Firestore Transaction 패턴
await db.runTransaction(async (transaction) => {
  // 1. 모든 읽기 작업
  const orderDoc = await transaction.get(orderRef);
  const listingDoc = await transaction.get(listingRef);

  // 2. 검증
  if (!orderDoc.exists) throw new Error('Order not found');

  // 3. 모든 쓰기 작업
  transaction.update(orderRef, { status: 'paid' });
  transaction.update(listingRef, { status: 'sold' });
});
```

---

## 3. Task Breakdown

### 3.1 Milestone 1: 전역 인프라 구축 (Primary Goal)

#### Task 1.1: Logger 시스템 구현

| 태스크 | 설명 | 우선순위 |
|--------|------|----------|
| T1.1.1 | `lib/core/utils/app_logger.dart` 파일 생성 | High |
| T1.1.2 | LogLevel enum 정의 | High |
| T1.1.3 | AppLogger 클래스 구현 (d, i, w, e 메서드) | High |
| T1.1.4 | 환경별 출력 로직 구현 (kDebugMode) | High |
| T1.1.5 | 단위 테스트 작성 | Medium |

**Dependencies**: 없음

---

#### Task 1.2: 통합 상수 파일 생성

| 태스크 | 설명 | 우선순위 |
|--------|------|----------|
| T1.2.1 | `lib/core/constants/app_constants.dart` 파일 생성 | High |
| T1.2.2 | 배송비 상수 정의 (defaultShippingFee = 4500) | High |
| T1.2.3 | HTTP 타임아웃 상수 정의 | Medium |
| T1.2.4 | 페이지네이션 상수 정의 | Low |
| T1.2.5 | 드래곤볼/환불 관련 상수 정의 | Low |

**Dependencies**: 없음

---

#### Task 1.3: 에러 핸들링 표준화

| 태스크 | 설명 | 우선순위 |
|--------|------|----------|
| T1.3.1 | `lib/core/errors/failures.dart` 파일 생성 | High |
| T1.3.2 | sealed class Failure 정의 | High |
| T1.3.3 | NetworkFailure, AuthFailure 구현 | High |
| T1.3.4 | PaymentFailure, ServerFailure 구현 | High |
| T1.3.5 | ValidationFailure, NotFoundFailure 구현 | Medium |
| T1.3.6 | 단위 테스트 작성 | Medium |

**Dependencies**: 없음

---

#### Task 1.4: Result 타입 구현

| 태스크 | 설명 | 우선순위 |
|--------|------|----------|
| T1.4.1 | `lib/core/utils/result.dart` 파일 생성 | High |
| T1.4.2 | sealed class Result<T> 정의 | High |
| T1.4.3 | Success<T>, Fail<T> 클래스 구현 | High |
| T1.4.4 | when() 메서드 구현 | High |
| T1.4.5 | 단위 테스트 작성 | Medium |

**Dependencies**: Task 1.3 (Failures)

---

### 3.2 Milestone 2: Flutter Critical 수정 (Primary Goal)

#### Task 2.1: Debug Print 제거 및 Logger 교체

| 태스크 | 설명 | 우선순위 |
|--------|------|----------|
| T2.1.1 | 전체 파일 스캔 및 교체 대상 목록 확정 | High |
| T2.1.2 | checkout 관련 파일 수정 (3개) | High |
| T2.1.3 | auth 관련 파일 수정 (5개) | High |
| T2.1.4 | listing 관련 파일 수정 (4개) | Medium |
| T2.1.5 | 기타 파일 수정 (24개) | Medium |
| T2.1.6 | 교체 완료 검증 (grep 확인) | High |

**Dependencies**: Task 1.1 (Logger)

**영향 파일 목록** (총 36개):
```
lib/main.dart
lib/features/checkout/presentation/screens/checkout_screen.dart
lib/features/checkout/domain/usecases/purchase_usecase.dart
lib/features/listing/presentation/screens/listing_detail_screen.dart
lib/features/listing/presentation/screens/part_shop_screen.dart
lib/features/listing/data/datasources/listing_remote_datasource.dart
lib/features/listing/data/models/listing_model.dart
lib/features/auth/presentation/screens/auth_screen.dart
lib/features/auth/data/repositories/auth_repository_impl.dart
lib/features/auth/data/datasources/kakao_auth_datasource.dart
lib/features/auth/data/datasources/google_auth_datasource.dart
lib/features/auth/data/datasources/web_kakao_auth.dart
lib/features/auth/data/datasources/firestore_user_datasource.dart
lib/features/recommendation/data/repositories/recommendation_repository_impl.dart
lib/features/recommendation/data/datasources/compatibility_remote_datasource_impl.dart
lib/features/payment/presentation/screens/toss_payment_webview_screen.dart
lib/features/payment/presentation/screens/toss_payment_web_screen.dart
lib/features/refund/presentation/screens/refund_request_screen.dart
lib/features/sell_request/presentation/screens/part_search_screen.dart
lib/features/sell_request/presentation/screens/finished_pc_sell_screen.dart
lib/features/sell_request/presentation/screens/sell_request_screen.dart
lib/features/my_page/presentation/screens/notification_settings_screen.dart
lib/features/my_page/presentation/screens/profile_edit_screen.dart
lib/features/my_page/presentation/providers/favorites_provider.dart
lib/features/cart/data/datasources/cart_remote_datasource_impl.dart
lib/features/dragon_ball/presentation/screens/batch_shipment_request_screen.dart
lib/features/home/presentation/widgets/product_list_section.dart
lib/features/admin/data/repositories/admin_sell_request_repository_impl.dart
lib/features/admin/data/repositories/admin_auth_repository.dart
lib/features/admin/presentation/screens/admin_dashboard.dart
lib/features/address/presentation/screens/daum_postcode_screen_mobile.dart
lib/core/repositories/base_part_repository.dart
lib/core/utils/notification_handler.dart
lib/core/utils/firebase_data_seeder.dart
lib/core/providers/theme_provider.dart
lib/core/data/datasources/image_upload_datasource.dart
```

---

#### Task 2.2: 배송비 상수화

| 태스크 | 설명 | 우선순위 |
|--------|------|----------|
| T2.2.1 | checkout_screen.dart 수정 (3곳) | High |
| T2.2.2 | cart_summary.dart 수정 (1곳) | High |
| T2.2.3 | purchase_usecase.dart 수정 (3000→4500 중요!) | Critical |
| T2.2.4 | 상수 임포트 및 참조 확인 | High |

**Dependencies**: Task 1.2 (Constants)

**Critical 수정 사항**:
```dart
// purchase_usecase.dart:57
// 변경 전
final shippingFee = 3000.0; // 판매자당 3000원

// 변경 후
import 'package:pi_com/core/constants/app_constants.dart';
final shippingFee = AppConstants.defaultShippingFee.toDouble();
```

---

#### Task 2.3: HTTP 타임아웃 설정

| 태스크 | 설명 | 우선순위 |
|--------|------|----------|
| T2.3.1 | payment_remote_datasource_impl.dart 위치 확인 | High |
| T2.3.2 | HTTP 클라이언트에 타임아웃 설정 추가 | High |
| T2.3.3 | 타임아웃 에러 핸들링 구현 | Medium |

**Dependencies**: Task 1.2 (Constants)

---

#### Task 2.4: Kakao SDK 키 환경변수 분리

| 태스크 | 설명 | 우선순위 |
|--------|------|----------|
| T2.4.1 | main.dart에서 Kakao 초기화 코드 확인 | High |
| T2.4.2 | 환경 설정 파일 또는 dotenv 패키지 도입 검토 | Medium |
| T2.4.3 | Kakao SDK 키를 환경 변수에서 로드하도록 수정 | High |
| T2.4.4 | .gitignore에 환경 파일 추가 확인 | High |

**Dependencies**: 없음

---

### 3.3 Milestone 3: Backend Critical 수정 (Secondary Goal)

#### Task 3.1: Admin UID 환경변수화

| 태스크 | 설명 | 우선순위 |
|--------|------|----------|
| T3.1.1 | `functions/src/config/admin.ts` 파일 생성 | High |
| T3.1.2 | getAdminUserIds() 함수 구현 | High |
| T3.1.3 | isAdmin() 헬퍼 함수 구현 | Medium |
| T3.1.4 | approval_deadline_scheduler.ts 수정 | High |
| T3.1.5 | process_refund.ts 수정 | High |
| T3.1.6 | Firebase 환경 변수 설정 (firebase functions:config:set) | High |

**Dependencies**: 없음

---

#### Task 3.2: Firestore 인덱스 배포

| 태스크 | 설명 | 우선순위 |
|--------|------|----------|
| T3.2.1 | 현재 필요한 복합 쿼리 분석 | Medium |
| T3.2.2 | firestore.indexes.json 업데이트 | Medium |
| T3.2.3 | 인덱스 배포 (firebase deploy --only firestore:indexes) | Medium |
| T3.2.4 | 배포 후 쿼리 동작 확인 | Medium |

**Dependencies**: 없음

---

#### Task 3.3: 결제 트랜잭션 로직 구현

| 태스크 | 설명 | 우선순위 |
|--------|------|----------|
| T3.3.1 | `functions/src/payment/payment_transaction.ts` 파일 생성 | High |
| T3.3.2 | processPaymentWithTransaction() 함수 설계 | High |
| T3.3.3 | 트랜잭션 내 주문 생성 로직 구현 | High |
| T3.3.4 | 트랜잭션 내 재고 업데이트 로직 구현 | High |
| T3.3.5 | 롤백 및 에러 처리 로직 구현 | High |
| T3.3.6 | 단위 테스트 작성 | Medium |

**Dependencies**: Task 3.1 (Admin Config 패턴 참고)

---

### 3.4 Milestone 4: 통합 검증 (Final Goal)

#### Task 4.1: 정적 분석

| 태스크 | 설명 | 우선순위 |
|--------|------|----------|
| T4.1.1 | flutter analyze 실행 및 경고 해결 | High |
| T4.1.2 | print/debugPrint 잔존 여부 확인 | High |
| T4.1.3 | 하드코딩된 상수 잔존 여부 확인 | High |

---

#### Task 4.2: 테스트 실행

| 태스크 | 설명 | 우선순위 |
|--------|------|----------|
| T4.2.1 | 신규 유틸리티 단위 테스트 실행 | High |
| T4.2.2 | 기존 테스트 회귀 확인 | High |
| T4.2.3 | Backend Functions 테스트 실행 | Medium |

---

#### Task 4.3: 수동 검증

| 태스크 | 설명 | 우선순위 |
|--------|------|----------|
| T4.3.1 | 결제 플로우 수동 테스트 | High |
| T4.3.2 | 장바구니 배송비 표시 확인 | High |
| T4.3.3 | 관리자 알림 발송 확인 | Medium |

---

## 4. Dependencies Graph

```
[M1: 인프라]
  ├── T1.1 Logger ──────────────────┐
  ├── T1.2 Constants ───────────────┼──► [M2: Flutter]
  ├── T1.3 Failures ─┬──► T1.4 Result   │    ├── T2.1 Print 제거
  └──────────────────┘                  │    ├── T2.2 배송비
                                        │    ├── T2.3 타임아웃
                                        │    └── T2.4 Kakao SDK
                                        │
[M3: Backend] ◄─────────────────────────┘
  ├── T3.1 Admin UID
  ├── T3.2 Firestore Index
  └── T3.3 Payment Transaction

[M4: 검증] ◄── M1, M2, M3 완료 후
  ├── T4.1 정적 분석
  ├── T4.2 테스트 실행
  └── T4.3 수동 검증
```

---

## 5. Risk Mitigation

### 5.1 배송비 불일치 위험

**위험**: purchase_usecase.dart의 3000원과 다른 파일의 4500원 불일치

**완화 전략**:
1. 작업 전 비즈니스 담당자에게 정확한 배송비 정책 확인
2. 모든 배송비 참조를 AppConstants로 통일 후 한 곳에서 관리
3. 변경 후 장바구니 → 결제 → 주문 완료까지 전체 플로우 검증

### 5.2 Debug Print 제거 회귀 위험

**위험**: 필요한 디버깅 정보가 손실될 수 있음

**완화 전략**:
1. 기존 print 내용을 동일한 Logger 레벨로 유지
2. 중요 정보는 info/warning, 디버깅 정보는 debug 레벨 사용
3. 변경 전후 로그 출력 비교 검증

### 5.3 Backend 환경 변수 설정 누락 위험

**위험**: 프로덕션 배포 시 환경 변수 미설정

**완화 전략**:
1. 배포 체크리스트에 환경 변수 설정 항목 추가
2. 환경 변수 미설정 시 명확한 에러 로깅
3. CI/CD 파이프라인에 환경 변수 검증 단계 추가

---

## 6. Expert Consultation Recommendations

### 6.1 Backend 전문가 (expert-backend)

**상담 필요 영역**:
- 결제 트랜잭션 로직 설계 검토
- Firestore 트랜잭션 최적화 패턴
- Firebase Functions 환경 변수 관리 모범 사례

### 6.2 보안 전문가 (expert-security)

**상담 필요 영역**:
- API 키 관리 모범 사례 (Kakao SDK)
- Admin UID 보안 관리 방안
- 환경 변수 암호화 필요 여부

---

## 7. Success Criteria

| 기준 | 측정 방법 | 목표값 |
|------|-----------|--------|
| Debug print 제거율 | grep 검색 결과 | 100% |
| 상수 통일율 | 하드코딩 검색 결과 | 100% |
| 신규 파일 테스트 커버리지 | flutter test --coverage | 80%+ |
| 정적 분석 경고 | flutter analyze | 0개 |
| 결제 플로우 정상 동작 | 수동 테스트 | Pass |

---

*이 문서는 MoAI-ADK manager-spec 에이전트에 의해 생성되었습니다.*
*Plan Version: 1.0.0*
*Last Updated: 2026-01-22*
