# PiCom 마스터 로드맵 (Master Roadmap)

> **프로젝트**: PiCom - 중고 PC 부품 거래 플랫폼
> **작성일**: 2026-01-22
> **수정일**: 2026-01-23
> **총 예상 기간**: 14-16주 (약 4개월)
> **목표**: Play Store 재출시 + 앱/웹 분리 + 백엔드 안정화
> **현재 진행**: Phase 2 (Play Store 정책 준수)

---

## 📋 Executive Summary

### 현재 상태
- **플랫폼**: Flutter 웹앱 (프로토타입 수준)
- **백엔드**: Firebase + Cloud Functions
- **상태**: Google Play 정책 위반으로 앱 정지

### 목표 상태
- **Flutter 모바일 앱**: 새 패키지로 Play Store/App Store 출시
- **JavaScript 웹앱**: Next.js 기반 독립 웹 애플리케이션
- **백엔드**: 안정화된 Firebase + 최적화된 Cloud Functions

### 핵심 문서
| 문서 | 위치 | 내용 |
|------|------|------|
| 마스터 로드맵 | `MASTER-ROADMAP.md` | 전체 일정 및 우선순위 (이 문서) |
| 재구조화 로드맵 | `ROADMAP-PICOM-RESTRUCTURE.md` | 앱 분리 및 Play Store 정책 |
| 피처 감사 보고서 | `FEATURE-AUDIT-REPORT.md` | 19개 피처 상태 및 TODO |
| 백엔드 수술서 | `BACKEND-SURGERY-PLAN.md` | Firebase 개선 계획 |

---

## 🎯 전체 로드맵 개요

```
╔═══════════════════════════════════════════════════════════════════════════════╗
║                          PiCom 마스터 로드맵                                    ║
╠═══════════════════════════════════════════════════════════════════════════════╣
║ Phase 0   │ 전역 인프라 + Critical 수정              │ 1주     │ ✅ 완료      ║
║ Phase 1   │ 백엔드 안정화                           │ 2주     │ ✅ 완료      ║
║ Phase 2   │ Play Store 정책 준수                    │ 1주     │ 🔴 진행중    ║
║ Phase 3   │ 피처 완성 (Critical → Medium)           │ 3주     │ 🟠 높음      ║
║ Phase 4   │ 앱 리브랜딩 + 출시                      │ 1주     │ 🟠 높음      ║
║ Phase 5   │ 공유 패키지 추출                        │ 2주     │ 🟡 중간      ║
║ Phase 6   │ JS 웹앱 개발                           │ 4-6주   │ 🟢 낮음      ║
║ Phase 7   │ 테스트 및 최종 배포                     │ 2주     │ ⚫ 최종      ║
╚═══════════════════════════════════════════════════════════════════════════════╝
```

---

## 🔴 Phase 0: 전역 인프라 + Critical 수정 (1주)

> **목표**: 모든 개발의 기반이 되는 인프라 정비

### 0.1 전역 인프라 구축

#### Logger 시스템 도입
**파일**: `lib/core/utils/app_logger.dart` (신규)

```dart
import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

class AppLogger {
  static void d(String message, [String? tag]) {
    _log(LogLevel.debug, message, tag);
  }

  static void i(String message, [String? tag]) {
    _log(LogLevel.info, message, tag);
  }

  static void w(String message, [String? tag]) {
    _log(LogLevel.warning, message, tag);
  }

  static void e(String message, [Object? error, StackTrace? stackTrace, String? tag]) {
    _log(LogLevel.error, message, tag);
    if (error != null && kDebugMode) {
      debugPrint('Error: $error');
      if (stackTrace != null) {
        debugPrint('StackTrace: $stackTrace');
      }
    }
    // TODO: Production에서는 Crashlytics로 전송
  }

  static void _log(LogLevel level, String message, String? tag) {
    if (!kDebugMode) return;

    final prefix = tag != null ? '[$tag] ' : '';
    final levelStr = level.name.toUpperCase();
    debugPrint('[$levelStr] $prefix$message');
  }
}
```

#### 상수 파일 정리
**파일**: `lib/core/constants/app_constants.dart` (신규 또는 통합)

```dart
class AppConstants {
  // 배송비
  static const int defaultShippingFee = 4500;
  static const int freeShippingThreshold = 50000;

  // 타임아웃
  static const Duration httpConnectTimeout = Duration(seconds: 10);
  static const Duration httpReceiveTimeout = Duration(seconds: 30);

  // 페이지네이션
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // 드래곤볼
  static const int dragonBallStorageDays = 30;
  static const int dragonBallWarningDays = 7;

  // 환불
  static const int refundApprovalDeadlineDays = 2;
  static const int autoConfirmPurchaseDays = 7;
}
```

#### 에러 핸들링 표준화
**파일**: `lib/core/errors/failures.dart` (신규)

```dart
sealed class Failure {
  final String message;
  final String? code;
  final dynamic originalError;

  const Failure(this.message, {this.code, this.originalError});

  @override
  String toString() => 'Failure($code): $message';
}

class NetworkFailure extends Failure {
  const NetworkFailure([String message = '네트워크 연결을 확인해주세요'])
      : super(message, code: 'NETWORK_ERROR');
}

class AuthFailure extends Failure {
  const AuthFailure([String message = '인증에 실패했습니다'])
      : super(message, code: 'AUTH_ERROR');
}

class PaymentFailure extends Failure {
  const PaymentFailure([String message = '결제 처리 중 오류가 발생했습니다'])
      : super(message, code: 'PAYMENT_ERROR');
}

class ServerFailure extends Failure {
  const ServerFailure([String message = '서버 오류가 발생했습니다'])
      : super(message, code: 'SERVER_ERROR');
}

class ValidationFailure extends Failure {
  const ValidationFailure(String message)
      : super(message, code: 'VALIDATION_ERROR');
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([String message = '요청한 데이터를 찾을 수 없습니다'])
      : super(message, code: 'NOT_FOUND');
}
```

#### Result 타입 도입
**파일**: `lib/core/utils/result.dart` (신규)

```dart
import '../errors/failures.dart';

sealed class Result<T> {
  const Result();

  factory Result.success(T data) = Success<T>;
  factory Result.failure(Failure failure) = Fail<T>;

  R when<R>({
    required R Function(T data) success,
    required R Function(Failure failure) failure,
  });
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);

  @override
  R when<R>({
    required R Function(T data) success,
    required R Function(Failure failure) failure,
  }) => success(data);
}

class Fail<T> extends Result<T> {
  final Failure failure;
  const Fail(this.failure);

  @override
  R when<R>({
    required R Function(T data) success,
    required R Function(Failure failure) failure,
  }) => failure(this.failure);
}
```

### 0.2 Critical 버그 수정 (Flutter)

| 순서 | 작업 | 파일 | 예상 시간 |
|-----|------|------|----------|
| 1 | Debug print 제거 → Logger 교체 | `checkout_screen.dart` 외 10개 | 2시간 |
| 2 | 배송비 상수화 | `checkout_screen.dart`, `cart_summary.dart` | 1시간 |
| 3 | HTTP 타임아웃 설정 | `payment_remote_datasource_impl.dart` | 1시간 |
| 4 | Kakao SDK 키 환경변수 분리 | `main.dart` | 1시간 |

### 0.3 Critical 버그 수정 (Backend)

| 순서 | 작업 | 파일 | 예상 시간 |
|-----|------|------|----------|
| 1 | Admin UID 환경변수로 이동 | `approval_deadline_scheduler.ts`, `process_refund.ts` | 2시간 |
| 2 | Firestore 인덱스 배포 | `firestore.indexes.json` | 1시간 |
| 3 | 결제 트랜잭션 로직 구현 | `payment_transaction.ts` (신규) | 4시간 |

### Phase 0 산출물 ✅ COMPLETED (SPEC-PHASE0-001)
- [x] `lib/core/utils/app_logger.dart`
- [x] `lib/core/constants/app_constants.dart`
- [x] `lib/core/errors/failures.dart`
- [x] `lib/core/utils/result.dart`
- [x] `functions/src/config/admin.ts`
- [x] `firestore.indexes.json`
- [x] `functions/src/payment/payment_transaction.ts`

---

## 🔴 Phase 1: 백엔드 안정화 (2주)

> **목표**: 결제/환불 플로우 안정화, 성능 최적화

### Week 1: 핵심 플로우 안정화

| 일차 | 작업 | 상세 |
|-----|------|------|
| Day 1-2 | 결제 트랜잭션 구현 | `processPaymentWithTransaction()` |
| Day 3 | 스케줄러 배치 처리 | 5개 스케줄러 limit 추가 |
| Day 4 | Rate limiting 추가 | 결제 엔드포인트 분당 5회 |
| Day 5 | 테스트 및 배포 | staging 환경 테스트 |

### Week 2: 최적화 및 모니터링

| 일차 | 작업 | 상세 |
|-----|------|------|
| Day 1-2 | dragonBalls 쿼리 최적화 | collectionGroup → 루트 마이그레이션 |
| Day 3 | 캐싱 구현 | base_parts 1시간 캐시 |
| Day 4 | 감사 로그 추가 | auditLogs 컬렉션 생성 |
| Day 5 | 에러 모니터링 | errorLogs + 알림 |

### Phase 1 산출물 ✅ COMPLETED (SPEC-PHASE1-001)
- [x] 안정적인 결제 트랜잭션 플로우 (`payment_transaction.ts`)
- [x] 최적화된 스케줄러 쿼리 (BATCH_SIZE=100)
- [x] Rate limiting 적용 (`rate_limiter.ts`)
- [x] 감사/에러 로그 시스템 (`audit_logger.ts`, `error_logger.ts`)
- [x] DragonBalls 루트 컬렉션 마이그레이션 (`dragonball_service.ts`)
- [x] Base_parts 캐싱 (`base_parts_cache.ts`)
- [x] Parts 레거시 코드 제거 (-120줄)

---

## 🔴 Phase 2: Play Store 정책 준수 (1주)

> **목표**: Google Play 데이터 안전 정책 완전 준수

### 2.1 동의 UI 구현

```
lib/features/auth/presentation/screens/
├── consent_screen.dart           # 신규: 약관 동의 화면
├── privacy_detail_screen.dart    # 신규: 개인정보처리방침 상세
└── terms_detail_screen.dart      # 신규: 이용약관 상세
```

### 2.2 계정 삭제 기능

```
lib/features/my_page/presentation/screens/
├── account_delete_screen.dart    # 신규: 계정 삭제 화면
└── account_delete_confirm_screen.dart  # 신규: 최종 확인
```

### 2.3 개인정보처리방침 업데이트

**파일**: `assets/html/privacy.html`

필수 포함 항목:
- [ ] 수집하는 개인정보 항목
- [ ] 수집 및 이용 목적
- [ ] 보유 및 이용 기간
- [ ] 제3자 제공 (PG사, 배송사)
- [ ] 파기 절차 및 방법
- [ ] 이용자 권리
- [ ] 개인정보 보호책임자

### Phase 2 산출물
- [ ] 동의 UI 화면 3개
- [ ] 계정 삭제 기능
- [ ] 업데이트된 개인정보처리방침
- [ ] Firestore `users/{uid}/consents` 서브컬렉션

---

## 🟠 Phase 3: 피처 완성 (3주)

> **목표**: Critical/Medium 피처 완성

### Week 1: Critical 피처

| 피처 | 작업 | TODO 수 |
|------|------|---------|
| **checkout** | 네비게이션 구현, 테스트 모드 조건부 표시 | 3 |
| **payment** | 결과 화면 네비게이션 구현 | 3 |
| **refund** | 상품명 조회, Provider 리팩토링, 재발송/취소 | 10 |

### Week 2: Medium 피처

| 피처 | 작업 | TODO 수 |
|------|------|---------|
| **recommendation** | 성능 티어 계산, debug print 제거 | 2 |
| **admin** | 중복 파일 삭제, 삭제 로직 구현 | 3 |
| **listing** | 백업 파일 삭제 | 0 |

### Week 3: Partial 피처

| 피처 | 작업 | TODO 수 |
|------|------|---------|
| **dragon_ball** | 검증 로직 추가 | 0 |
| **sell_request** | 카테고리 필터 | 1 |
| **my_page** | buyerId 조회 | 1 |
| **notification** | 디렉토리 이름 수정 | 0 |
| **web_public** | 로그아웃 구현 | 2 |

### Phase 3 산출물
- [ ] 23개 TODO 해결
- [ ] 중복/백업 파일 5개 삭제
- [ ] 테스트 커버리지 40%+

---

## 🟠 Phase 4: 앱 리브랜딩 + 출시 (1주)

> **목표**: 새 패키지로 Play Store 재출시

### 4.1 패키지명 변경

| 플랫폼 | 현재 | 변경 후 |
|--------|------|---------|
| Android | `com.example.picom` | `com.picom.partshop` (예시) |
| iOS | `com.example.picom` | `com.picom.partshop` |

### 4.2 브랜딩 변경

- [ ] 앱 아이콘 (1024x1024)
- [ ] 스플래시 화면
- [ ] 앱 이름

### 4.3 Firebase 재설정

- [ ] 새 패키지로 Android/iOS 앱 등록
- [ ] google-services.json 재발급
- [ ] GoogleService-Info.plist 재발급

### 4.4 스토어 제출

- [ ] 스크린샷 준비
- [ ] 앱 설명 작성
- [ ] 데이터 안전 섹션 작성
- [ ] 내부 테스트 업로드

### Phase 4 산출물
- [ ] 새 패키지명의 앱 빌드
- [ ] Play Console 내부 테스트 트랙 업로드
- [ ] App Store Connect TestFlight 업로드

---

## 🟡 Phase 5: 공유 패키지 추출 (2주)

> **목표**: 앱/웹 공용 코드 분리

### 5.1 모노레포 구조

```
pi_com/
├── packages/
│   └── picom_core/              # 공유 비즈니스 로직
│       ├── lib/
│       │   ├── models/
│       │   ├── repositories/
│       │   ├── services/
│       │   └── picom_core.dart
│       └── pubspec.yaml
├── apps/
│   └── mobile/                  # Flutter 모바일 앱
└── melos.yaml
```

### 5.2 추출 대상

| 현재 위치 | 새 위치 |
|----------|--------|
| `lib/core/models/` | `packages/picom_core/lib/models/` |
| `lib/features/*/domain/` | `packages/picom_core/lib/domain/` |

### Phase 5 산출물
- [ ] `packages/picom_core/` 패키지
- [ ] `melos.yaml` 설정
- [ ] 모바일 앱에서 picom_core 의존성

---

## 🟢 Phase 6: JS 웹앱 개발 (4-6주)

> **목표**: Next.js 기반 독립 웹 애플리케이션

### 기술 스택

```json
{
  "framework": "Next.js 15 (App Router)",
  "language": "TypeScript 5.x",
  "state": "TanStack Query v5 + Zustand",
  "ui": "shadcn/ui + Tailwind CSS v4",
  "auth": "NextAuth.js v5 + Firebase Auth",
  "database": "Firebase Firestore"
}
```

### 개발 일정

| 주차 | 작업 |
|-----|------|
| Week 1 | 프로젝트 설정, 인증 연동 |
| Week 2 | 매물 목록/상세 페이지 |
| Week 3 | 장바구니, 결제 연동 |
| Week 4 | 마이페이지, 주문 내역 |
| Week 5 | 관리자 패널 |
| Week 6 | 최적화 및 테스트 |

### Phase 6 산출물
- [ ] Next.js 웹앱 MVP
- [ ] Firebase 인증 연동
- [ ] 결제 플로우 연동

---

## ⚫ Phase 7: 테스트 및 최종 배포 (2주)

> **목표**: 프로덕션 안정성 확보

### 7.1 E2E 테스트

- [ ] 결제 플로우 (Kakao Pay, Toss)
- [ ] 인증 플로우 (Google, Kakao)
- [ ] 환불 플로우

### 7.2 성능 테스트

| 메트릭 | 목표 |
|--------|------|
| Lighthouse Performance | 90+ |
| LCP | < 2.5s |
| FID | < 100ms |
| CLS | < 0.1 |

### 7.3 배포

- [ ] Flutter 앱 → Play Store (프로덕션)
- [ ] Flutter 앱 → App Store
- [ ] Next.js 웹 → Vercel

### Phase 7 산출물
- [ ] E2E 테스트 통과
- [ ] Play Store 프로덕션 출시
- [ ] 웹앱 프로덕션 배포

---

## 📅 전체 일정 타임라인

```
2026년 1월 4주 - 2월: Phase 0-2 (4주)
├── 1월 4주: Phase 0 - 전역 인프라 + Critical
├── 2월 1주: Phase 1a - 백엔드 핵심 안정화
├── 2월 2주: Phase 1b - 최적화 + Phase 2 시작
└── 2월 3주: Phase 2 완료 - Play Store 준비

2026년 2월 4주 - 3월: Phase 3-4 (4주)
├── 2월 4주: Phase 3a - Critical 피처
├── 3월 1주: Phase 3b - Medium 피처
├── 3월 2주: Phase 3c - Partial 피처
└── 3월 3주: Phase 4 - 리브랜딩 + 출시

2026년 3월 4주 - 5월: Phase 5-7 (6-8주)
├── 3월 4주 - 4월 1주: Phase 5 - 공유 패키지
├── 4월 - 5월 1주: Phase 6 - JS 웹앱
└── 5월 2-3주: Phase 7 - 테스트 + 배포
```

---

## ✅ 마일스톤 체크리스트

### M1: 기반 완성 (Phase 0-1) ✅ COMPLETED
- [x] 전역 인프라 구축 완료 (SPEC-PHASE0-001)
- [x] Critical 버그 수정 완료 (Flutter + Backend)
- [x] 백엔드 안정화 완료 (SPEC-PHASE1-001)

### M2: Play Store 준비 (Phase 2-3)
- [ ] 정책 준수 완료
- [ ] Critical/Medium 피처 완성
- [ ] 테스트 커버리지 40%+

### M3: 앱 출시 (Phase 4)
- [ ] 새 패키지 빌드
- [ ] Play Store 내부 테스트
- [ ] Play Store 프로덕션 출시

### M4: 웹 출시 (Phase 5-7)
- [ ] 공유 패키지 추출
- [ ] Next.js 웹앱 MVP
- [ ] 웹앱 프로덕션 배포

---

## 🔧 진행 방식

### 피처별 진행 프로토콜

1. **시작 전**: 해당 피처의 TODO/이슈 확인
2. **진행 중**: TODO 해결하며 체크리스트 업데이트
3. **완료 후**: 테스트 작성, PR 생성

### 문서 업데이트 주기

- **FEATURE-AUDIT-REPORT.md**: 피처 완성 시마다
- **BACKEND-SURGERY-PLAN.md**: 백엔드 작업 시마다
- **MASTER-ROADMAP.md**: 주간 진행 상황 반영

### 커밋 컨벤션

```
feat: 새 기능 추가
fix: 버그 수정
refactor: 리팩토링
docs: 문서 수정
chore: 설정/빌드 변경
test: 테스트 추가
```

---

*이 문서는 Alfred (MoAI-ADK)에 의해 생성되었습니다.*
*최종 수정: 2026-01-22*
*버전: 1.0.0*
