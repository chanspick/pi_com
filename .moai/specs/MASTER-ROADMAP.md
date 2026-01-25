# PiCom 마스터 로드맵 (Master Roadmap)

> **프로젝트**: PiCom - 중고 PC 부품 거래 플랫폼
> **작성일**: 2026-01-22
> **수정일**: 2026-01-25
> **총 예상 기간**: 14-16주 (약 4개월)
> **목표**: Play Store 재출시 + 앱/웹 분리 + 백엔드 안정화
> **현재 진행**: Phase 4 (앱 리브랜딩 + 출시)

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
╔═══════════════════════════════════════════════════════════════════════════════════╗
║                            PiCom 마스터 로드맵                                     ║
╠═══════════════════════════════════════════════════════════════════════════════════╣
║ Phase 0   │ 전역 인프라 + Critical 수정              │ 1주     │ ✅ 완료       ║
║ Phase 1   │ 백엔드 안정화                           │ 2주     │ ✅ 완료       ║
║ Phase 1.5 │ 백엔드 & Admin 강화 (송장/리포트)       │ 2주     │ ✅ 완료       ║
║ Phase 2   │ Play Store 정책 준수                    │ 1주     │ ✅ 완료       ║
║ Phase 3   │ 피처 완성 (Critical → Medium)           │ 3주     │ ✅ 완료       ║
║ Phase 4   │ 앱 리브랜딩 + 출시                      │ 1주     │ 🟠 높음       ║
║ Phase 5   │ 공유 패키지 추출                        │ 2주     │ 🟡 중간       ║
║ Phase 6   │ JS 웹앱 개발                           │ 4-6주   │ 🟢 낮음       ║
║ Phase 7   │ 테스트 및 최종 배포                     │ 2주     │ ⚫ 최종       ║
╚═══════════════════════════════════════════════════════════════════════════════════╝
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

## ✅ Phase 1.5: 백엔드 & Admin 강화 (2주) - COMPLETED

> **목표**: 송장 시스템 구축 및 Admin 기능 강화로 운영 효율성 극대화
> **완료일**: 2026-01-25

### M1: 송장(Invoice) 시스템 ✅
- [x] Cloud Functions `invoice_generator.ts` - PDF 생성, Storage 업로드
- [x] Cloud Functions `invoice_trigger.ts` - 결제 완료 시 자동 송장 생성
- [x] API 엔드포인트: `POST /invoice/generate`, `GET /invoice/:orderId`, `POST /invoice/regenerate`
- [x] Firestore `invoices` 컬렉션 보안 규칙
- [x] OrderEntity/OrderModel 확장 (invoiceId, invoiceUrl, invoiceGeneratedAt)

### M2: 주문/배송 통합 관리 ✅
- [x] `order_detail_management_page.dart` - 주문 상세 관리
- [x] `bulk_action_dialog.dart` + `bulk_operations.ts` - 일괄 처리
- [x] `excel_export_service.dart` - 엑셀 내보내기
- [x] 송장 번호 입력/배송 상태 관리 UI

### M3: 매출/정산 리포트 ✅
- [x] `revenue_dashboard_page.dart` - 매출 대시보드
- [x] `settlement_report_page.dart` - 정산 리포트
- [x] `revenue_chart_widget.dart` - 차트 위젯 (fl_chart)
- [x] `get_revenue_statistics.dart` - 통계 유스케이스

### M4: 고급 검색/필터 ✅
- [x] `advanced_search_widget.dart` - 고급 검색 위젯
- [x] Firestore 복합 인덱스 추가 (orders, invoices, settlements)
- [x] 기간별/상태별/금액별 필터링

### Phase 1.5 산출물
- [x] 12개 신규 파일 (Flutter 10개, Cloud Functions 2개)
- [x] Firestore 인덱스 배포 완료
- [x] Cloud Functions 배포 완료 (5개 신규)

---

## ✅ Phase 2: Play Store 정책 준수 (1주) - COMPLETED

> **목표**: Google Play 데이터 안전 정책 완전 준수

### 2.1 동의 UI 구현 ✅

```
lib/features/auth/presentation/screens/
├── consent_screen.dart           # ✅ 구현 완료
└── ConsentDetailScreen           # ✅ WebView로 약관 표시
```

**구현된 기능:**
- [x] 서비스 이용약관 동의 (필수)
- [x] 개인정보 처리방침 동의 (필수)
- [x] 개인정보 제3자 제공 동의 (필수)
- [x] 마케팅 정보 수신 동의 (선택)
- [x] 전체 동의 / 필수 항목 전체 동의
- [x] Firestore users/{uid}/consents 서브컬렉션 저장

### 2.2 계정 삭제 기능 ✅

```
lib/features/my_page/presentation/screens/
├── account_delete_screen.dart    # ✅ 구현 완료
└── settings_screen.dart          # ✅ 계정 삭제 메뉴 추가
```

**구현된 기능:**
- [x] 삭제 전 데이터 안내 (즉시 삭제 / 법적 보존)
- [x] 탈퇴 사유 수집 (서비스 개선용)
- [x] 최종 확인 다이얼로그
- [x] 재인증 요청 (보안)
- [x] Firestore account_deletions 로그 저장
- [x] 사용자 문서 익명화
- [x] Firebase Auth 계정 삭제

### 2.3 개인정보처리방침 ✅ (기존 완비)

**파일**: `assets/html/privacy_policy.html` - 이미 완전한 형태로 작성됨

포함 항목:
- [x] 수집하는 개인정보 항목 (제2조)
- [x] 수집 및 이용 목적 (제1조)
- [x] 보유 및 이용 기간 (제3조)
- [x] 제3자 제공 - 카카오페이, 토스페이먼츠 (제4조)
- [x] 파기 절차 및 방법 (제7조)
- [x] 계정 삭제 관련 안내 (제6조)

### Phase 2 산출물
- [x] `consent_screen.dart` - 약관 동의 화면
- [x] `account_delete_screen.dart` - 계정 삭제 화면
- [x] `settings_screen.dart` - 계정 삭제 메뉴 추가
- [x] `firestore.rules` - consents, account_deletions 규칙 추가
- [x] `app.dart`, `app_router.dart`, `routes.dart` - 라우트 등록
- [ ] 이용자 권리
- [ ] 개인정보 보호책임자

### Phase 2 산출물
- [ ] 동의 UI 화면 3개
- [ ] 계정 삭제 기능
- [ ] 업데이트된 개인정보처리방침
- [ ] Firestore `users/{uid}/consents` 서브컬렉션

---

## ✅ Phase 3: 피처 완성 (3주) - COMPLETED

> **목표**: Critical/Medium 피처 완성
> **완료일**: 2026-01-25

### Week 1: Critical 피처 ✅

| 피처 | 작업 | 상태 |
|------|------|------|
| **checkout** | Debug print 제거 (→ debugPrint), 테스트 모드 조건부 표시 (kDebugMode) | ✅ |
| **payment** | 결제 성공 → 구매내역, 취소 → 장바구니, 실패 → 전화연결 네비게이션 구현 | ✅ |
| **refund** | 오래된 TODO 주석 제거 (기능은 이미 구현됨) | ✅ |

### Week 2: Medium 피처 ✅

| 피처 | 작업 | 상태 |
|------|------|------|
| **admin** | 중복 파일 삭제 (listing_list_page.dart, user_list_page.dart), improved 버전 사용 | ✅ |
| **listing** | 백업 파일 삭제 (part_shop_screen_backup.dart, part_shop_screen_enhanced.dart) | ✅ |
| **notification** | 디렉토리 이름 수정 (presentations → presentation) | ✅ |

### Week 3: 전역 개선 ✅

| 작업 | 파일 | 상태 |
|------|------|------|
| 배송비 상수화 | `shipping_constants.dart` (신규), checkout_screen, cart_summary | ✅ |
| 라우트 통합 | app.dart improved 버전 사용, 중복 라우트 제거 | ✅ |

### Phase 3 산출물
- [x] Critical 피처 수정 완료 (checkout, payment, refund)
- [x] Medium 피처 정리 완료 (admin, listing, notification)
- [x] 불필요한 파일 4개 삭제
- [x] `shipping_constants.dart` 신규 생성
- [x] Debug print → debugPrint 전환 (조건부 로깅)

### 남은 기술 부채 (향후 개선)
- [ ] Refund: Order에서 실제 상품명 조회 (현재 '주문 상품' 플레이스홀더)
- [ ] Recommendation: CPU/GPU 성능 티어 계산 로직
- [ ] Web Public: 로그아웃 구현 (web_navbar.dart)

---

## 🟡 Phase 4: 앱 리브랜딩 + 출시 (1주) - IN PROGRESS

> **목표**: Play Store 재출시
> **시작일**: 2026-01-25

### 4.1 패키지명/브랜딩 ✅

| 항목 | 현재 설정 |
|------|----------|
| Android Package | `app.picom.team.pi_com` |
| iOS Bundle ID | `app.picom.team.piCom` |
| 앱 이름 | PiCom |
| 버전 | 2.0.0+9 |

### 4.2 빌드 준비 ✅

- [x] 버전 업데이트 (1.0.7+8 → 2.0.0+9)
- [x] iOS 앱 이름 일관성 수정 (Pi Com → PiCom)
- [x] dart:html 조건부 import 수정 (excel_export_service.dart)
- [x] 디버그 빌드 성공 검증
- [x] 데이터 안전 가이드 문서 작성 (`PLAY-STORE-DATA-SAFETY.md`)

### 4.3 릴리즈 빌드 대기 중 ⏳

**필요 작업**: Keystore 설정
```bash
# 1. Keystore 생성 (최초 1회)
keytool -genkey -v -keystore android/keystore/picom-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias picom

# 2. key.properties 생성
cp android/key.properties.template android/key.properties
# 파일 수정하여 비밀번호 입력

# 3. 릴리즈 빌드
flutter build appbundle --release
```

### 4.4 스토어 제출 준비

- [ ] Keystore 설정 완료
- [ ] 릴리즈 빌드 (.aab) 생성
- [ ] 스크린샷 준비 (휴대전화 2개+)
- [ ] 앱 설명 작성
- [ ] 데이터 안전 섹션 작성 (가이드 참조: `PLAY-STORE-DATA-SAFETY.md`)
- [ ] Play Console 내부 테스트 업로드

### Phase 4 산출물
- [x] 버전 2.0.0+9 업데이트
- [x] `PLAY-STORE-DATA-SAFETY.md` 가이드 문서
- [x] `key.properties.template` 템플릿
- [x] `excel_web_helper.dart` / `excel_web_helper_stub.dart` 조건부 import
- [ ] 릴리즈 빌드 (.aab)
- [ ] Play Console 업로드

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
2026년 1월: Phase 0-1.5 ✅ 완료
├── 1월 3주: Phase 0 - 전역 인프라 + Critical ✅
├── 1월 4주: Phase 1 - 백엔드 안정화 ✅
└── 1월 5주: Phase 1.5 - 백엔드 & Admin 강화 ✅ (2026-01-25)

2026년 1월 5주 - 2월: Phase 2-4
├── ✅ Phase 2 - Play Store 정책 준수 완료 (2026-01-25)
├── ✅ Phase 3 - Critical/Medium 피처 완성 완료 (2026-01-25)
└── 🚨 NOW: Phase 4 - 리브랜딩 + 출시

2026년 2월 4주 - 4월: Phase 5-7
├── 2월 4주 - 3월 1주: Phase 5 - 공유 패키지
├── 3월 - 4월: Phase 6 - JS 웹앱
└── 4월: Phase 7 - 테스트 + 배포
```

---

## ✅ 마일스톤 체크리스트

### M1: 기반 완성 (Phase 0-1) ✅ COMPLETED
- [x] 전역 인프라 구축 완료 (SPEC-PHASE0-001)
- [x] Critical 버그 수정 완료 (Flutter + Backend)
- [x] 백엔드 안정화 완료 (SPEC-PHASE1-001)
- [x] 백엔드 & Admin 강화 완료 (Phase 1.5) - 2026-01-25

### M2: Play Store 준비 (Phase 2-3) ✅ COMPLETED
- [x] 정책 준수 완료 (Phase 2) ✅ 2026-01-25
  - [x] 동의 UI 구현 (consent_screen.dart)
  - [x] 계정 삭제 기능 (account_delete_screen.dart)
  - [x] 개인정보처리방침 완비 (privacy_policy.html)
- [x] Critical/Medium 피처 완성 (Phase 3) ✅ 2026-01-25
  - [x] Debug print 정리 (checkout_screen.dart)
  - [x] Payment 네비게이션 구현
  - [x] Admin/Listing 중복 파일 삭제
  - [x] 배송비 상수화 (shipping_constants.dart)
  - [x] notification 디렉토리 오타 수정
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
*최종 수정: 2026-01-25*
*버전: 1.3.0 - Phase 3 완료 반영*
