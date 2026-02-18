# SPEC-PHASE0-001: Phase 0 - 전역 인프라 구축 및 Critical 버그 수정

---

## TAG BLOCK

```yaml
spec_id: SPEC-PHASE0-001
title: Phase 0 - 전역 인프라 구축 및 Critical 버그 수정
created: 2026-01-22T00:00:00+09:00
completed: 2026-01-22T00:00:00+09:00
status: Completed
priority: High
lifecycle: spec-anchored
assigned: manager-tdd
related_specs: []
epic: PiCom Play Store 재출시
labels: [infrastructure, bug-fix, critical, flutter, firebase]
```

---

## 1. Environment (환경)

### 1.1 프로젝트 정보

| 항목 | 값 |
|------|-----|
| **프로젝트명** | PiCom - 중고 PC 부품 거래 플랫폼 |
| **프레임워크** | Flutter (Dart 3.x) + Firebase Cloud Functions (TypeScript) |
| **현재 상태** | Google Play 정책 위반으로 앱 정지, 재출시 준비 중 |
| **목표** | 전역 인프라 정비 및 Critical 버그 수정으로 안정적인 개발 기반 마련 |

### 1.2 기술 스택

**Flutter (Frontend)**
- Flutter SDK: 3.x (stable)
- Dart: 3.x
- 상태 관리: Riverpod
- 라우팅: GoRouter
- HTTP: http package

**Firebase (Backend)**
- Cloud Functions: TypeScript (firebase-functions v1)
- Firestore: 문서 데이터베이스
- Authentication: Google, Kakao 소셜 로그인
- Cloud Messaging: 푸시 알림

### 1.3 발견된 문제점 요약

| 카테고리 | 문제 | 영향 범위 |
|----------|------|-----------|
| Debug Print | 36개 파일에서 print/debugPrint 사용 | 프로덕션 로그 오염, 성능 저하 |
| 배송비 불일치 | 4500원 vs 3000원 하드코딩 | 결제 금액 불일치 가능성 |
| Admin UID 하드코딩 | Backend에서 관리자 ID 하드코딩 | 보안 취약점, 관리자 변경 시 재배포 필요 |
| 인프라 부재 | Logger, Result 타입, 에러 핸들링 표준 없음 | 디버깅 어려움, 에러 추적 불가 |

---

## 2. Assumptions (가정)

### 2.1 기술적 가정

| 가정 | 신뢰도 | 근거 | 위험 |
|------|--------|------|------|
| Flutter 앱은 kDebugMode로 개발/프로덕션 환경 구분 가능 | High | Flutter SDK 기본 제공 | 없음 |
| Firebase Functions는 환경 변수(Secret Manager) 지원 | High | Firebase 공식 문서 | 없음 |
| Dart의 sealed class는 Flutter 3.x에서 지원됨 | High | Dart 3.0+ | 없음 |
| 기존 코드 변경 시 기능 퇴보 가능성 있음 | Medium | 테스트 부재 | 회귀 테스트 필요 |

### 2.2 비즈니스 가정

| 가정 | 신뢰도 | 근거 | 위험 |
|------|--------|------|------|
| 배송비는 4500원이 정확한 값 | Medium | MASTER-ROADMAP.md 참조 | 비즈니스 확인 필요 |
| 관리자 UID 목록은 환경 변수로 관리하는 것이 적절 | High | 보안 모범 사례 | 없음 |
| 모든 print 문은 Logger로 대체 가능 | High | 코드 분석 결과 | 없음 |

### 2.3 검증이 필요한 가정

- **배송비 정책**: 부품 배송비가 4500원인지, 3000원인지 비즈니스 담당자 확인 필요
- **무료 배송 조건**: 일정 금액 이상 시 무료 배송 정책이 있는지 확인 필요
- **관리자 목록 업데이트 주기**: 환경 변수 업데이트 시 Function 재배포 필요 여부 확인

---

## 3. Requirements (요구사항)

### 3.1 전역 인프라 요구사항 (0.1)

#### REQ-INFRA-001: Logger 시스템 도입

**[Ubiquitous]** 시스템은 **항상** 로그 메시지를 LogLevel(debug, info, warning, error)에 따라 분류하여 기록해야 한다.

**[State-Driven]** **IF** 앱이 Debug 모드에서 실행 중이면 **THEN** 모든 로그 레벨의 메시지를 콘솔에 출력해야 한다.

**[State-Driven]** **IF** 앱이 Release 모드에서 실행 중이면 **THEN** error 레벨의 로그만 Crashlytics로 전송해야 한다.

**[Unwanted]** 시스템은 Release 모드에서 debug 또는 info 레벨 로그를 콘솔에 출력**하지 않아야 한다**.

상세 스펙:
- 파일 위치: `lib/core/utils/app_logger.dart`
- API: `AppLogger.d()`, `AppLogger.i()`, `AppLogger.w()`, `AppLogger.e()`
- 태그 지원: 선택적 tag 파라미터로 로그 분류 가능
- 스택 트레이스: error 레벨에서 선택적 StackTrace 파라미터 지원

---

#### REQ-INFRA-002: 통합 상수 파일 생성

**[Ubiquitous]** 시스템은 **항상** 비즈니스 로직에서 사용하는 상수 값을 중앙 집중식 상수 파일에서 참조해야 한다.

**[Unwanted]** 시스템은 비즈니스 상수(배송비, 타임아웃 등)를 개별 파일에 하드코딩**하지 않아야 한다**.

상세 스펙:
- 파일 위치: `lib/core/constants/app_constants.dart`
- 포함 항목:
  - 배송비: `defaultShippingFee = 4500`
  - HTTP 타임아웃: `httpConnectTimeout = 10초`, `httpReceiveTimeout = 30초`
  - 페이지네이션: `defaultPageSize = 20`, `maxPageSize = 100`
  - 드래곤볼: `dragonBallStorageDays = 30`, `dragonBallWarningDays = 7`
  - 환불: `refundApprovalDeadlineDays = 2`, `autoConfirmPurchaseDays = 7`

---

#### REQ-INFRA-003: 에러 핸들링 표준화

**[Ubiquitous]** 시스템은 **항상** 예외 발생 시 표준화된 Failure 타입으로 래핑하여 반환해야 한다.

**[Event-Driven]** **WHEN** 네트워크 오류가 발생하면 **THEN** NetworkFailure를 반환해야 한다.

**[Event-Driven]** **WHEN** 인증 오류가 발생하면 **THEN** AuthFailure를 반환해야 한다.

**[Event-Driven]** **WHEN** 결제 처리 중 오류가 발생하면 **THEN** PaymentFailure를 반환해야 한다.

**[Event-Driven]** **WHEN** 서버 오류가 발생하면 **THEN** ServerFailure를 반환해야 한다.

**[Event-Driven]** **WHEN** 유효성 검증 실패가 발생하면 **THEN** ValidationFailure를 반환해야 한다.

**[Event-Driven]** **WHEN** 데이터를 찾을 수 없으면 **THEN** NotFoundFailure를 반환해야 한다.

상세 스펙:
- 파일 위치: `lib/core/errors/failures.dart`
- 베이스 클래스: `sealed class Failure`
- 하위 클래스: `NetworkFailure`, `AuthFailure`, `PaymentFailure`, `ServerFailure`, `ValidationFailure`, `NotFoundFailure`
- 필수 속성: `message`, `code` (선택), `originalError` (선택)

---

#### REQ-INFRA-004: Result 타입 도입

**[Ubiquitous]** 시스템은 **항상** 실패 가능한 작업의 결과를 Result 타입으로 반환해야 한다.

**[Event-Driven]** **WHEN** 작업이 성공하면 **THEN** `Result.success(data)`를 반환해야 한다.

**[Event-Driven]** **WHEN** 작업이 실패하면 **THEN** `Result.failure(Failure)`를 반환해야 한다.

상세 스펙:
- 파일 위치: `lib/core/utils/result.dart`
- 타입: `sealed class Result<T>`
- 하위 클래스: `Success<T>`, `Fail<T>`
- 패턴 매칭: `when()` 메서드로 성공/실패 처리

---

### 3.2 Critical 버그 수정 - Flutter (0.2)

#### REQ-FIX-001: Debug Print 제거 및 Logger 교체

**[Ubiquitous]** 시스템은 **항상** 로깅이 필요한 경우 AppLogger를 사용해야 한다.

**[Unwanted]** 시스템은 `print()` 또는 `debugPrint()`를 직접 호출**하지 않아야 한다**.

영향 파일 (36개 중 주요 파일):
- `lib/main.dart`
- `lib/features/checkout/presentation/screens/checkout_screen.dart`
- `lib/features/checkout/domain/usecases/purchase_usecase.dart`
- `lib/features/listing/presentation/screens/listing_detail_screen.dart`
- `lib/features/recommendation/data/repositories/recommendation_repository_impl.dart`
- `lib/features/auth/data/repositories/auth_repository_impl.dart`
- 기타 30개 파일

---

#### REQ-FIX-002: 배송비 상수화

**[Ubiquitous]** 시스템은 **항상** 배송비 계산 시 `AppConstants.defaultShippingFee`를 참조해야 한다.

**[Unwanted]** 시스템은 배송비 값을 직접 하드코딩**하지 않아야 한다**.

영향 파일:
- `lib/features/checkout/presentation/screens/checkout_screen.dart`: 265, 533, 836 라인
- `lib/features/cart/presentation/widgets/cart_summary.dart`: 36 라인
- `lib/features/checkout/domain/usecases/purchase_usecase.dart`: 57 라인 (**3000.0 → 4500 수정 필요**)

---

#### REQ-FIX-003: HTTP 타임아웃 설정

**[Ubiquitous]** 시스템은 **항상** HTTP 요청 시 타임아웃을 설정해야 한다.

**[State-Driven]** **IF** HTTP 연결이 10초 이상 걸리면 **THEN** ConnectionTimeout 에러를 발생시켜야 한다.

**[State-Driven]** **IF** HTTP 응답 수신이 30초 이상 걸리면 **THEN** ReceiveTimeout 에러를 발생시켜야 한다.

영향 파일:
- `lib/features/payment/data/datasources/payment_remote_datasource_impl.dart` (파일 생성 또는 수정 필요)

---

#### REQ-FIX-004: Kakao SDK 키 환경변수 분리

**[Ubiquitous]** 시스템은 **항상** Kakao SDK 키를 환경 변수 또는 보안 설정 파일에서 로드해야 한다.

**[Unwanted]** 시스템은 API 키를 소스 코드에 직접 포함**하지 않아야 한다**.

영향 파일:
- `lib/main.dart`

---

### 3.3 Critical 버그 수정 - Backend (0.3)

#### REQ-FIX-005: Admin UID 환경변수화

**[Ubiquitous]** 시스템은 **항상** 관리자 UID 목록을 환경 변수(ADMIN_USER_IDS)에서 로드해야 한다.

**[Unwanted]** 시스템은 관리자 UID를 소스 코드에 하드코딩**하지 않아야 한다**.

**[Event-Driven]** **WHEN** 환경 변수가 설정되지 않았으면 **THEN** 에러 로그를 기록하고 빈 배열을 반환해야 한다.

영향 파일:
- `functions/src/refund/approval_deadline_scheduler.ts`: 192-193 라인
- `functions/src/refund/process_refund.ts`: 306 라인
- `functions/src/config/admin.ts` (신규 생성)

---

#### REQ-FIX-006: Firestore 인덱스 배포

**[Event-Driven]** **WHEN** 복합 쿼리 실행 시 **THEN** 사전 정의된 Firestore 인덱스를 사용해야 한다.

**[Unwanted]** 시스템은 인덱스 없이 복합 쿼리를 실행**하지 않아야 한다**.

영향 파일:
- `firestore.indexes.json`

---

#### REQ-FIX-007: 결제 트랜잭션 로직 구현

**[Event-Driven]** **WHEN** 결제 처리 요청이 들어오면 **THEN** Firestore 트랜잭션 내에서 원자적으로 처리해야 한다.

**[Unwanted]** 시스템은 결제 관련 데이터를 트랜잭션 외부에서 개별적으로 업데이트**하지 않아야 한다**.

**[Event-Driven]** **WHEN** 트랜잭션 내 작업이 실패하면 **THEN** 모든 변경 사항을 롤백해야 한다.

영향 파일:
- `functions/src/payment/payment_transaction.ts` (신규 생성)

---

## 4. Specifications (상세 명세)

### 4.1 파일 구조

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_constants.dart      # 신규: 통합 상수
│   │   └── firebase_constants.dart # 기존
│   ├── errors/
│   │   └── failures.dart           # 신규: 에러 타입
│   └── utils/
│       ├── app_logger.dart         # 신규: Logger
│       └── result.dart             # 신규: Result 타입

functions/
├── src/
│   ├── config/
│   │   └── admin.ts                # 신규: Admin 설정
│   ├── payment/
│   │   └── payment_transaction.ts  # 신규: 결제 트랜잭션
│   └── refund/
│       ├── approval_deadline_scheduler.ts  # 수정
│       └── process_refund.ts              # 수정
└── firestore.indexes.json          # 수정
```

### 4.2 API 명세

#### AppLogger API

```dart
class AppLogger {
  /// Debug 레벨 로그
  static void d(String message, [String? tag]);

  /// Info 레벨 로그
  static void i(String message, [String? tag]);

  /// Warning 레벨 로그
  static void w(String message, [String? tag]);

  /// Error 레벨 로그 (스택 트레이스 지원)
  static void e(String message, [Object? error, StackTrace? stackTrace, String? tag]);
}
```

#### Result API

```dart
sealed class Result<T> {
  factory Result.success(T data);
  factory Result.failure(Failure failure);

  R when<R>({
    required R Function(T data) success,
    required R Function(Failure failure) failure,
  });
}
```

#### Admin Config API (TypeScript)

```typescript
// functions/src/config/admin.ts
export function getAdminUserIds(): string[];
export function isAdmin(userId: string): boolean;
```

### 4.3 의존성

```
REQ-INFRA-001 (Logger) ← REQ-FIX-001 (Debug Print 제거)
REQ-INFRA-002 (상수) ← REQ-FIX-002 (배송비 상수화)
REQ-INFRA-003 (Failure) ← REQ-INFRA-004 (Result)
REQ-FIX-005 (Admin UID) → functions/src/config/admin.ts
```

---

## 5. Traceability (추적성)

| 요구사항 ID | 관련 파일 | 테스트 케이스 | 검증 방법 |
|-------------|-----------|---------------|-----------|
| REQ-INFRA-001 | app_logger.dart | TC-LOGGER-* | Unit Test |
| REQ-INFRA-002 | app_constants.dart | TC-CONST-* | Static Analysis |
| REQ-INFRA-003 | failures.dart | TC-FAILURE-* | Unit Test |
| REQ-INFRA-004 | result.dart | TC-RESULT-* | Unit Test |
| REQ-FIX-001 | 36개 파일 | TC-PRINT-* | grep + Unit Test |
| REQ-FIX-002 | 3개 파일 | TC-SHIPPING-* | Unit Test |
| REQ-FIX-003 | payment_remote_datasource_impl.dart | TC-TIMEOUT-* | Integration Test |
| REQ-FIX-004 | main.dart | TC-KAKAO-* | Manual Test |
| REQ-FIX-005 | admin.ts, scheduler.ts, process_refund.ts | TC-ADMIN-* | Unit Test |
| REQ-FIX-006 | firestore.indexes.json | TC-INDEX-* | Deploy Test |
| REQ-FIX-007 | payment_transaction.ts | TC-TRANSACTION-* | Integration Test |

---

## 6. Risks (위험 요소)

| 위험 | 영향도 | 발생 가능성 | 완화 전략 |
|------|--------|-------------|-----------|
| 배송비 변경으로 인한 결제 금액 불일치 | High | Medium | 비즈니스 담당자와 정책 확인 후 작업 |
| Debug print 제거 시 기존 디버깅 정보 손실 | Low | Low | Logger로 동일 정보 유지 |
| Result 타입 도입으로 기존 코드 호환성 문제 | Medium | Low | 점진적 도입, 기존 코드 우선 유지 |
| Firebase Functions 환경 변수 설정 누락 | High | Medium | 배포 전 체크리스트 작성 |
| 트랜잭션 로직 도입으로 성능 저하 | Medium | Low | 성능 테스트 후 최적화 |

---

*이 문서는 MoAI-ADK manager-spec 에이전트에 의해 생성되었습니다.*
*SPEC Version: 1.0.0*
*Last Updated: 2026-01-22*
