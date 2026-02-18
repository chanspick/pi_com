# SPEC-PHASE2-001: Phase 2 - Play Store 정책 준수

---

## TAG BLOCK

```yaml
spec_id: SPEC-PHASE2-001
title: Phase 2 - Play Store 정책 준수 (Google Play Data Safety)
created: 2026-01-23T00:00:00+09:00
status: In-Progress
priority: High
lifecycle: spec-anchored
assigned: manager-tdd
related_specs: [SPEC-PHASE0-001, SPEC-PHASE1-001]
epic: PiCom Play Store 재출시
labels: [flutter, privacy, consent, account-deletion, play-store, compliance, warranty, qr, pdf, invoice]
```

---

## 1. Environment (환경)

### 1.1 프로젝트 정보

| 항목 | 값 |
|------|-----|
| **프로젝트명** | PiCom - 중고 PC 부품 거래 플랫폼 |
| **프레임워크** | Flutter (Dart) + Firebase |
| **이전 SPEC** | SPEC-PHASE0-001 (전역 인프라), SPEC-PHASE1-001 (백엔드 안정화) - COMPLETED |
| **목표** | Google Play Store 데이터 안전 정책 완전 준수 |

### 1.2 기술 스택

**Flutter Frontend**
- Flutter 3.x (Dart)
- Riverpod 상태 관리
- go_router 네비게이션

**Firebase Backend**
- Cloud Functions: TypeScript
- Firestore: 문서 데이터베이스
- Firebase Auth: 사용자 인증

**기존 인프라 (완료)**
- AppLogger: 로깅 시스템
- Result 패턴: 성공/실패 처리 표준화
- 감사 로그: auditLogs 컬렉션

### 1.3 Google Play 데이터 안전 정책 요구사항

| 정책 항목 | 현재 상태 | 필요 조치 |
|----------|----------|-----------|
| 데이터 수집 공개 | 부분 준수 | 개인정보처리방침 업데이트 |
| 사용자 동의 | 미구현 | 약관/개인정보 동의 UI 필요 |
| 계정 삭제 | 미구현 | 계정 삭제 기능 구현 필요 |
| 데이터 보관 기간 | 미명시 | 처리방침에 명시 필요 |
| 제3자 데이터 공유 | 미명시 | PG사, 배송사 공유 내역 명시 |

---

## 2. Assumptions (가정)

### 2.1 기술적 가정

| 가정 | 신뢰도 | 근거 | 위험 |
|------|--------|------|------|
| Firebase Auth 계정 삭제 API 사용 가능 | High | Firebase 공식 문서 | 없음 |
| Firestore 사용자 데이터 일괄 삭제 가능 | High | Cloud Functions 구현 | 없음 |
| HTML 파일로 개인정보처리방침 표시 가능 | High | 기존 assets/html/ 구조 활용 | 없음 |
| 동의 이력은 Firestore 서브컬렉션으로 저장 | High | 일반적인 패턴 | 없음 |

### 2.2 비즈니스 가정

| 가정 | 신뢰도 | 근거 | 위험 |
|------|--------|------|------|
| 약관 버전 관리가 필요함 | High | 법적 요구사항 | 없음 |
| 계정 삭제 시 30일 유예 기간 필요 | Medium | 일반적인 서비스 패턴 | 비즈니스 확인 필요 |
| 기존 사용자도 최초 로그인 시 동의 필요 | High | Play Store 정책 | 없음 |
| 개인정보 보호책임자 정보 필요 | High | 법적 요구사항 | 없음 |

### 2.3 검증이 필요한 가정

- **계정 삭제 유예 기간**: 30일이 적절한지, 즉시 삭제가 필요한지 비즈니스 확인
- **개인정보 보호책임자**: 실제 담당자 정보 확인 필요
- **제3자 제공 목록**: KakaoPay, TossPayments, 배송사 목록 확인

---

## 3. Requirements (요구사항)

### 3.1 동의 UI 구현 (Day 1-2)

#### REQ-CONSENT-001: 약관 동의 화면

**[Event-Driven]** **WHEN** 사용자가 최초 로그인하거나 약관 버전이 업데이트되면 **THEN** 동의 화면(consent_screen)을 표시해야 한다.

**[Ubiquitous]** 시스템은 **항상** 이용약관과 개인정보처리방침 동의를 필수로 요구해야 한다.

**[State-Driven]** **IF** 사용자가 모든 필수 항목에 동의하면 **THEN** 다음 화면으로 진행할 수 있어야 한다.

**[Unwanted]** 시스템은 필수 동의 없이 서비스를 이용하도록 **허용하지 않아야 한다**.

신규 파일:
- `lib/features/auth/presentation/screens/consent_screen.dart`

UI 구성요소:
- 전체 동의 체크박스
- 이용약관 동의 (필수) + 상세 보기 버튼
- 개인정보처리방침 동의 (필수) + 상세 보기 버튼
- 마케팅 정보 수신 동의 (선택)
- 동의하고 시작하기 버튼

#### REQ-CONSENT-002: 개인정보처리방침 상세 화면

**[Event-Driven]** **WHEN** 사용자가 개인정보처리방침 상세 보기를 탭하면 **THEN** 전체 내용을 WebView로 표시해야 한다.

**[Ubiquitous]** 시스템은 **항상** 최신 버전의 개인정보처리방침을 표시해야 한다.

신규 파일:
- `lib/features/auth/presentation/screens/privacy_detail_screen.dart`

#### REQ-CONSENT-003: 이용약관 상세 화면

**[Event-Driven]** **WHEN** 사용자가 이용약관 상세 보기를 탭하면 **THEN** 전체 내용을 WebView로 표시해야 한다.

신규 파일:
- `lib/features/auth/presentation/screens/terms_detail_screen.dart`

---

### 3.2 계정 삭제 기능 (Day 3-4)

#### REQ-DELETE-001: 계정 삭제 요청 화면

**[Event-Driven]** **WHEN** 사용자가 마이페이지에서 계정 삭제를 선택하면 **THEN** 계정 삭제 안내 화면을 표시해야 한다.

**[Ubiquitous]** 시스템은 **항상** 삭제 시 영향받는 데이터 목록을 사용자에게 안내해야 한다.

신규 파일:
- `lib/features/my_page/presentation/screens/account_delete_screen.dart`

표시 정보:
- 삭제되는 데이터 목록 (프로필, 거래 내역, 등록 상품 등)
- 삭제 불가 조건 (진행 중인 거래, 미정산 금액)
- 삭제 처리 기간 안내
- 삭제 요청 버튼

#### REQ-DELETE-002: 계정 삭제 최종 확인 화면

**[Event-Driven]** **WHEN** 사용자가 삭제 요청 버튼을 탭하면 **THEN** 최종 확인 화면을 표시해야 한다.

**[State-Driven]** **IF** 사용자가 비밀번호/재인증을 완료하면 **THEN** 계정 삭제를 진행해야 한다.

**[Unwanted]** 시스템은 재인증 없이 계정을 삭제**하지 않아야 한다**.

신규 파일:
- `lib/features/my_page/presentation/screens/account_delete_confirm_screen.dart`

확인 절차:
- "계정 삭제" 문구 직접 입력
- 재인증 (Google/Kakao 재로그인)
- 최종 삭제 버튼

#### REQ-DELETE-003: 계정 삭제 처리 (Backend)

**[Event-Driven]** **WHEN** 계정 삭제가 확인되면 **THEN** Cloud Functions에서 다음 데이터를 삭제해야 한다.

삭제 대상 데이터:
- `users/{uid}` 문서 및 모든 서브컬렉션
- `listings` 컬렉션의 사용자 매물 (상태를 'deleted'로 변경)
- Firebase Auth 계정
- Firebase Storage 사용자 이미지

**[Ubiquitous]** 시스템은 **항상** 계정 삭제를 감사 로그에 기록해야 한다.

**[State-Driven]** **IF** 진행 중인 거래가 있으면 **THEN** 계정 삭제를 거부하고 사유를 안내해야 한다.

신규/수정 파일:
- `functions/src/user/delete_account.ts` (신규)

---

### 3.3 개인정보처리방침 업데이트 (Day 4-5)

#### REQ-PRIVACY-001: 개인정보처리방침 문서 업데이트

**[Ubiquitous]** 시스템은 **항상** 다음 항목을 개인정보처리방침에 포함해야 한다.

수정 파일:
- `assets/html/privacy.html`

필수 포함 항목:

1. **수집하는 개인정보 항목**
   - 필수: 이름, 이메일, 전화번호, 주소
   - 선택: 프로필 사진
   - 자동 수집: 기기 정보, IP 주소, 서비스 이용 기록

2. **수집 및 이용 목적**
   - 회원 관리 및 본인 확인
   - 상품 거래 서비스 제공
   - 결제 및 환불 처리
   - 고객 문의 응대
   - 서비스 개선 및 통계 분석

3. **보유 및 이용 기간**
   - 회원 탈퇴 시까지
   - 관련 법령에 따른 보존 (전자상거래법 5년 등)

4. **제3자 제공**
   - 결제 대행사: KakaoPay, TossPayments (결제 처리)
   - 배송사: (배송 서비스 제공)

5. **파기 절차 및 방법**
   - 보유 기간 경과 후 지체 없이 파기
   - 전자적 파일: 복구 불가능한 방법으로 삭제
   - 종이 문서: 분쇄 또는 소각

6. **이용자 권리**
   - 개인정보 열람, 정정, 삭제 요청 권리
   - 처리 정지 요청 권리
   - 동의 철회 권리

7. **개인정보 보호책임자**
   - 이름, 연락처, 이메일

---

### 3.4 동의 이력 저장 (Backend)

#### REQ-BACKEND-001: 동의 이력 서브컬렉션

**[Event-Driven]** **WHEN** 사용자가 약관에 동의하면 **THEN** `users/{uid}/consents` 서브컬렉션에 동의 이력을 저장해야 한다.

**[Ubiquitous]** 시스템은 **항상** 동의 시점의 약관 버전, 일시, IP 주소를 기록해야 한다.

데이터 구조:
```typescript
interface ConsentRecord {
  id: string;
  termsVersion: string;        // 이용약관 버전 (예: "1.0.0")
  privacyVersion: string;      // 개인정보처리방침 버전 (예: "1.0.0")
  marketingConsent: boolean;   // 마케팅 동의 여부
  consentedAt: Timestamp;      // 동의 일시
  ipAddress: string;           // IP 주소
  userAgent: string;           // 접속 환경
}
```

신규/수정 파일:
- `functions/src/user/save_consent.ts` (신규)
- `lib/features/auth/data/repositories/consent_repository.dart` (신규)

---

## 4. Specifications (상세 명세)

### 4.1 파일 구조

```
lib/
├── features/
│   ├── auth/
│   │   ├── presentation/
│   │   │   └── screens/
│   │   │       ├── consent_screen.dart         # 신규: 약관 동의 화면
│   │   │       ├── privacy_detail_screen.dart  # 신규: 개인정보처리방침 상세
│   │   │       └── terms_detail_screen.dart    # 신규: 이용약관 상세
│   │   └── data/
│   │       └── repositories/
│   │           └── consent_repository.dart     # 신규: 동의 저장 Repository
│   └── my_page/
│       └── presentation/
│           └── screens/
│               ├── account_delete_screen.dart          # 신규: 계정 삭제 화면
│               └── account_delete_confirm_screen.dart  # 신규: 최종 확인
├── assets/
│   └── html/
│       ├── privacy.html      # 수정: 개인정보처리방침
│       └── terms.html        # 확인: 이용약관 (필요시 수정)
└── functions/
    └── src/
        └── user/
            ├── delete_account.ts   # 신규: 계정 삭제 처리
            └── save_consent.ts     # 신규: 동의 저장
```

### 4.2 화면 흐름

```
┌─────────────────────────────────────────────────────────────────┐
│                        동의 플로우                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────┐     ┌────────────┐     ┌──────────────────┐       │
│  │ 로그인    │────>│ 동의 필요?  │────>│ consent_screen   │       │
│  └──────────┘     └────────────┘     └──────────────────┘       │
│                         │ No                  │                  │
│                         ▼                     │ 상세보기          │
│                   ┌──────────┐     ┌─────────▼──────────┐       │
│                   │ 홈 화면   │     │ privacy_detail     │       │
│                   └──────────┘     │ terms_detail       │       │
│                         ▲          └────────────────────┘       │
│                         │                     │ 동의 완료        │
│                         └─────────────────────┘                 │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                      계정 삭제 플로우                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────┐     ┌────────────────────┐     ┌───────────────┐  │
│  │ 마이페이지 │────>│ account_delete     │────>│ delete_confirm │  │
│  │ 설정      │     │ (삭제 안내)         │     │ (최종 확인)    │  │
│  └──────────┘     └────────────────────┘     └───────────────┘  │
│                                                      │           │
│                                              ┌───────▼────────┐  │
│                                              │ 재인증 + 삭제   │  │
│                                              │ 처리 완료      │  │
│                                              └────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### 4.3 API 명세

#### 동의 저장 API

**Endpoint**: `POST /user/consent`

```typescript
// Request
interface SaveConsentRequest {
  termsVersion: string;
  privacyVersion: string;
  marketingConsent: boolean;
}

// Response
interface SaveConsentResponse {
  success: boolean;
  consentId: string;
  message?: string;
}
```

#### 계정 삭제 API

**Endpoint**: `POST /user/delete-account`

```typescript
// Request
interface DeleteAccountRequest {
  confirmText: string;  // "계정 삭제" 입력값
}

// Response
interface DeleteAccountResponse {
  success: boolean;
  message: string;
  scheduledDeletionDate?: string;  // 유예 기간이 있는 경우
}
```

### 4.4 Firestore 인덱스

```json
// firestore.indexes.json에 추가
{
  "collectionGroup": "consents",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "consentedAt", "order": "DESCENDING" }
  ]
}
```

---

## 5. Traceability (추적성)

| 요구사항 ID | 관련 파일 | 테스트 케이스 | 검증 방법 |
|-------------|-----------|---------------|-----------|
| REQ-CONSENT-001 | consent_screen.dart | TC-CONSENT-001-* | Widget Test |
| REQ-CONSENT-002 | privacy_detail_screen.dart | TC-CONSENT-002-* | Widget Test |
| REQ-CONSENT-003 | terms_detail_screen.dart | TC-CONSENT-003-* | Widget Test |
| REQ-DELETE-001 | account_delete_screen.dart | TC-DELETE-001-* | Widget Test |
| REQ-DELETE-002 | account_delete_confirm_screen.dart | TC-DELETE-002-* | Widget Test |
| REQ-DELETE-003 | delete_account.ts | TC-DELETE-003-* | Integration Test |
| REQ-PRIVACY-001 | privacy.html | TC-PRIVACY-001-* | Manual Review |
| REQ-BACKEND-001 | save_consent.ts | TC-BACKEND-001-* | Integration Test |

---

## 6. Risks (위험 요소)

| 위험 | 영향도 | 발생 가능성 | 완화 전략 |
|------|--------|-------------|-----------|
| 기존 사용자 동의 획득 실패 | High | Low | 필수 동의 화면으로 서비스 이용 차단 |
| 계정 삭제 후 데이터 복구 요청 | Medium | Low | 30일 유예 기간 검토, 명확한 안내 |
| 개인정보처리방침 법적 미비 | High | Medium | 법률 전문가 검토 권장 |
| WebView 렌더링 이슈 | Low | Low | 대체 텍스트 화면 준비 |
| 진행 중 거래 있는 사용자 삭제 시도 | Medium | Medium | 삭제 전 거래 상태 검증 |

---

---

## Implementation Notes (2026-02-18)

### 실제 구현 범위 (Divergence Report)

Phase 2의 실제 구현은 원래 SPEC과 달리 QR 기반 AS 보증 시스템에 중점을 두었습니다.

#### 구현 완료된 기능
- QR 기반 AS 보증 시스템 (M1~M4)
- PDF 보증서 자동생성
- 유저 로그인/보증 등록 시스템
- 관리자 일괄 작업 도구

#### 구현된 파일 (SPEC 외 추가)
- `functions/src/warranty/` - 보증 서비스 전체 (10개 파일)
- `functions/src/invoice/` - PDF 보증서 생성 (2개 파일)
- `functions/src/admin/bulk_operations.ts` - 관리자 일괄 작업

#### 미구현 항목 (원래 SPEC 범위)
- `privacy_detail_screen.dart` - 개인정보처리방침 상세 화면
- `terms_detail_screen.dart` - 이용약관 상세 화면
- `consent_repository.dart` - 동의 저장 Repository
- `account_delete_confirm_screen.dart` - 계정 삭제 최종 확인
- `functions/src/user/delete_account.ts` - 계정 삭제 백엔드
- `functions/src/user/save_consent.ts` - 동의 저장 백엔드

#### 부분 구현 항목
- `consent_screen.dart` - 약관 동의 화면 (구현됨)
- `account_delete_screen.dart` - 계정 삭제 화면 (구현됨)
- `privacy_policy.html` - 개인정보처리방침 (기존 파일 존재)

### 관련 커밋
- `800f970` feat: PDF 보증서 자동생성 + 유저 로그인/보증 등록 시스템
- `3f5ba35` docs: 로드맵 업데이트 - QR 기반 AS 보증 시스템 완료 (Phase 2)
- `8b67af4` feat: QR 기반 AS 보증 시스템 구현 (Phase 2 - M1~M4)

---

*이 문서는 MoAI-ADK manager-spec 에이전트에 의해 생성되었습니다.*
*SPEC Version: 1.0.0*
*Last Updated: 2026-01-23*
