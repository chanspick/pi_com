# SPEC-PHASE2-001: Implementation Plan (구현 계획)

---

## TAG BLOCK

```yaml
spec_id: SPEC-PHASE2-001
document_type: plan
related_spec: SPEC-PHASE2-001/spec.md
created: 2026-01-23T00:00:00+09:00
```

---

## 1. Overview (개요)

### 1.1 목표

Phase 2 Play Store 정책 준수의 목표는 Google Play Store 데이터 안전 정책을 완전히 준수하여 앱 재출시 기반을 마련하는 것입니다.

**핵심 성과 지표:**
- 동의 UI 완성도: 100% (3개 화면)
- 계정 삭제 기능: 완전 동작
- 개인정보처리방침: 7개 필수 항목 포함
- 동의 이력 저장: Firestore 연동 완료

### 1.2 범위

**포함:**
- 약관/개인정보처리방침 동의 UI (Flutter)
- 계정 삭제 기능 (Flutter + Cloud Functions)
- 개인정보처리방침 업데이트 (HTML)
- 동의 이력 저장 (Firestore)

**제외:**
- 앱 리브랜딩 (Phase 4)
- 새로운 비즈니스 기능
- 기존 기능 수정

---

## 2. Milestones (마일스톤)

### M1: 동의 UI 구현 (Primary Goal)

**기간:** Day 1-2

| 작업 | 예상 난이도 | 의존성 |
|------|------------|--------|
| consent_screen.dart 구현 | Medium | 없음 |
| privacy_detail_screen.dart 구현 | Low | 없음 |
| terms_detail_screen.dart 구현 | Low | 없음 |
| 동의 상태 Provider 구현 | Medium | 화면 구현 |
| consent_repository.dart 구현 | Medium | Provider 구현 |

**완료 조건:**
- 3개 동의 관련 화면 완성
- 전체 동의 / 개별 동의 기능 동작
- 상세 보기 WebView 동작
- Firestore에 동의 이력 저장

---

### M2: 계정 삭제 기능 (Secondary Goal)

**기간:** Day 3-4

| 작업 | 예상 난이도 | 의존성 |
|------|------------|--------|
| account_delete_screen.dart 구현 | Medium | 없음 |
| account_delete_confirm_screen.dart 구현 | Medium | 삭제 화면 |
| delete_account.ts (Cloud Functions) 구현 | High | 없음 |
| Firebase Auth 연동 | Medium | Functions 구현 |
| 마이페이지에 삭제 메뉴 추가 | Low | 화면 구현 |

**완료 조건:**
- 2개 계정 삭제 화면 완성
- 재인증 후 삭제 처리 동작
- 사용자 데이터 삭제 Cloud Function 동작
- 감사 로그에 삭제 이력 기록

---

### M3: 개인정보처리방침 및 통합 (Tertiary Goal)

**기간:** Day 4-5

| 작업 | 예상 난이도 | 의존성 |
|------|------------|--------|
| privacy.html 업데이트 | Medium | 없음 |
| terms.html 확인 및 수정 | Low | 없음 |
| 로그인 플로우에 동의 화면 통합 | Medium | M1 완료 |
| 기존 사용자 동의 획득 로직 | Medium | M1 완료 |
| 전체 플로우 통합 테스트 | Medium | M1, M2 완료 |

**완료 조건:**
- 개인정보처리방침 7개 필수 항목 포함
- 신규/기존 사용자 동의 플로우 동작
- 전체 E2E 플로우 검증

---

### M4: 테스트 및 검증 (Final Goal)

**기간:** Day 5 이후 또는 병렬 진행

| 작업 | 예상 난이도 | 의존성 |
|------|------------|--------|
| Widget 테스트 작성 | Medium | M1-M3 완료 |
| Cloud Functions 테스트 | Medium | M2 완료 |
| Play Store 정책 체크리스트 검증 | Low | 모든 작업 완료 |

**완료 조건:**
- 주요 화면 Widget 테스트 통과
- Cloud Functions 동작 검증
- Play Store 데이터 안전 섹션 작성 가능

---

## 3. Technical Approach (기술적 접근)

### 3.1 동의 화면 구현

**ConsentScreen 구조:**
```dart
// lib/features/auth/presentation/screens/consent_screen.dart
class ConsentScreen extends ConsumerStatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('서비스 이용 동의')),
      body: Column(
        children: [
          // 전체 동의 체크박스
          AllAgreeCheckbox(),
          Divider(),
          // 이용약관 (필수)
          ConsentItem(
            title: '이용약관 동의',
            required: true,
            onDetailTap: () => context.push('/consent/terms'),
          ),
          // 개인정보처리방침 (필수)
          ConsentItem(
            title: '개인정보처리방침 동의',
            required: true,
            onDetailTap: () => context.push('/consent/privacy'),
          ),
          // 마케팅 동의 (선택)
          ConsentItem(
            title: '마케팅 정보 수신 동의',
            required: false,
          ),
          Spacer(),
          // 동의 버튼
          ElevatedButton(
            onPressed: _canProceed ? _submitConsent : null,
            child: Text('동의하고 시작하기'),
          ),
        ],
      ),
    );
  }
}
```

**동의 상태 관리:**
```dart
// Riverpod Provider
final consentStateProvider = StateNotifierProvider<ConsentNotifier, ConsentState>((ref) {
  return ConsentNotifier();
});

class ConsentState {
  final bool termsAgreed;
  final bool privacyAgreed;
  final bool marketingAgreed;

  bool get canProceed => termsAgreed && privacyAgreed;
}
```

### 3.2 계정 삭제 구현

**삭제 가능 조건 확인:**
```typescript
// functions/src/user/delete_account.ts
async function canDeleteAccount(uid: string): Promise<{ canDelete: boolean; reason?: string }> {
  // 1. 진행 중인 주문 확인
  const activeOrders = await db.collection('orders')
    .where('buyerId', '==', uid)
    .where('status', 'in', ['pending', 'paid', 'shipped'])
    .limit(1)
    .get();

  if (!activeOrders.empty) {
    return { canDelete: false, reason: '진행 중인 주문이 있습니다.' };
  }

  // 2. 미정산 금액 확인
  const pendingSettlements = await db.collection('settlements')
    .where('sellerId', '==', uid)
    .where('status', '==', 'pending')
    .limit(1)
    .get();

  if (!pendingSettlements.empty) {
    return { canDelete: false, reason: '미정산 금액이 있습니다.' };
  }

  return { canDelete: true };
}
```

**삭제 처리 로직:**
```typescript
async function deleteUserAccount(uid: string): Promise<void> {
  const batch = db.batch();

  // 1. 사용자 매물 상태 변경 (삭제 대신 비활성화)
  const userListings = await db.collection('listings')
    .where('sellerId', '==', uid)
    .get();

  userListings.forEach(doc => {
    batch.update(doc.ref, { status: 'deleted', deletedAt: Timestamp.now() });
  });

  // 2. 사용자 문서 삭제 표시
  const userRef = db.collection('users').doc(uid);
  batch.update(userRef, {
    status: 'deleted',
    deletedAt: Timestamp.now(),
    email: null,  // 개인정보 삭제
    phone: null,
  });

  await batch.commit();

  // 3. Firebase Auth 계정 삭제
  await admin.auth().deleteUser(uid);

  // 4. 감사 로그 기록
  await logAudit({
    userId: uid,
    action: 'ACCOUNT_DELETED',
    targetCollection: 'users',
    targetId: uid,
    details: { deletedAt: new Date().toISOString() }
  });
}
```

### 3.3 개인정보처리방침 구조

**privacy.html 템플릿:**
```html
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>개인정보처리방침</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; padding: 16px; }
    h1 { font-size: 20px; margin-bottom: 24px; }
    h2 { font-size: 16px; margin-top: 24px; color: #333; }
    p, li { font-size: 14px; line-height: 1.6; color: #666; }
  </style>
</head>
<body>
  <h1>개인정보처리방침</h1>
  <p>시행일: 2026년 1월 23일</p>
  <p>버전: 1.0.0</p>

  <h2>1. 수집하는 개인정보 항목</h2>
  <p><strong>필수 수집 항목:</strong></p>
  <ul>
    <li>이름, 이메일 주소, 전화번호</li>
    <li>배송 주소 (거래 시)</li>
  </ul>
  <p><strong>자동 수집 항목:</strong></p>
  <ul>
    <li>기기 정보 (기기 종류, OS 버전)</li>
    <li>IP 주소, 서비스 이용 기록</li>
  </ul>

  <h2>2. 수집 및 이용 목적</h2>
  <!-- ... -->

  <h2>3. 보유 및 이용 기간</h2>
  <!-- ... -->

  <!-- 4~7 섹션 계속 -->

  <h2>7. 개인정보 보호책임자</h2>
  <p>이름: [담당자 이름]</p>
  <p>연락처: [전화번호]</p>
  <p>이메일: [이메일 주소]</p>
</body>
</html>
```

### 3.4 라우팅 설정

**go_router 설정:**
```dart
// lib/core/router/app_router.dart에 추가
GoRoute(
  path: '/consent',
  builder: (context, state) => const ConsentScreen(),
  routes: [
    GoRoute(
      path: 'privacy',
      builder: (context, state) => const PrivacyDetailScreen(),
    ),
    GoRoute(
      path: 'terms',
      builder: (context, state) => const TermsDetailScreen(),
    ),
  ],
),
GoRoute(
  path: '/account/delete',
  builder: (context, state) => const AccountDeleteScreen(),
),
GoRoute(
  path: '/account/delete/confirm',
  builder: (context, state) => const AccountDeleteConfirmScreen(),
),
```

---

## 4. Architecture Design (아키텍처 설계)

### 4.1 동의 플로우 시퀀스

```
┌────────┐     ┌──────────┐     ┌───────────┐     ┌──────────┐
│ Client │     │ Firebase │     │ Functions │     │Firestore │
└───┬────┘     └────┬─────┘     └─────┬─────┘     └────┬─────┘
    │               │                 │                 │
    │ 로그인 요청    │                 │                 │
    │──────────────>│                 │                 │
    │               │                 │                 │
    │ 로그인 성공    │                 │                 │
    │<──────────────│                 │                 │
    │               │                 │                 │
    │ 동의 상태 확인 │                 │                 │
    │────────────────────────────────────────────────>│
    │               │                 │                 │
    │ 동의 필요 응답 │                 │                 │
    │<────────────────────────────────────────────────│
    │               │                 │                 │
    │ 동의 화면 표시 │                 │                 │
    │ (사용자 동의)  │                 │                 │
    │               │                 │                 │
    │ 동의 저장 요청 │                 │                 │
    │────────────────────────────────>│                 │
    │               │                 │ 동의 이력 저장   │
    │               │                 │────────────────>│
    │               │                 │                 │
    │ 동의 완료 응답 │                 │                 │
    │<────────────────────────────────│                 │
    │               │                 │                 │
    │ 홈 화면으로 이동│                 │                 │
```

### 4.2 계정 삭제 시퀀스

```
┌────────┐     ┌──────────┐     ┌───────────┐     ┌──────────┐
│ Client │     │ Firebase │     │ Functions │     │Firestore │
└───┬────┘     └────┬─────┘     └─────┬─────┘     └────┬─────┘
    │               │                 │                 │
    │ 삭제 가능 확인 │                 │                 │
    │────────────────────────────────>│                 │
    │               │                 │ 거래 상태 조회   │
    │               │                 │────────────────>│
    │               │                 │                 │
    │ 삭제 가능 응답 │                 │                 │
    │<────────────────────────────────│                 │
    │               │                 │                 │
    │ 재인증 요청    │                 │                 │
    │──────────────>│                 │                 │
    │               │                 │                 │
    │ 재인증 성공    │                 │                 │
    │<──────────────│                 │                 │
    │               │                 │                 │
    │ 계정 삭제 요청 │                 │                 │
    │────────────────────────────────>│                 │
    │               │                 │ 데이터 삭제/비활성화
    │               │                 │────────────────>│
    │               │                 │                 │
    │               │                 │ Auth 삭제       │
    │               │                 │────────────────>│
    │               │                 │                 │
    │ 삭제 완료 응답 │                 │                 │
    │<────────────────────────────────│                 │
    │               │                 │                 │
    │ 로그아웃 처리  │                 │                 │
```

---

## 5. Dependencies (의존성)

### 5.1 Flutter 의존성

| 패키지 | 용도 | 상태 |
|--------|------|------|
| webview_flutter | 약관/방침 상세 보기 | 기존 사용 중 확인 필요 |
| riverpod | 동의 상태 관리 | 기존 사용 중 |
| go_router | 화면 네비게이션 | 기존 사용 중 |

### 5.2 내부 의존성

| 모듈 | 의존 대상 |
|------|-----------|
| consent_screen.dart | consent_repository.dart, go_router |
| account_delete_screen.dart | Firebase Auth, Cloud Functions |
| delete_account.ts | audit_logger.ts, Firestore |
| save_consent.ts | Firestore |

### 5.3 SPEC 의존성

- **SPEC-PHASE0-001**: AppLogger, Failures 활용
- **SPEC-PHASE1-001**: auditLogs 컬렉션 활용, Result 패턴 활용

---

## 6. Risk Mitigation (위험 완화)

### 6.1 기존 사용자 동의 획득

**위험:** 기존 사용자가 동의 거부 시 서비스 이용 불가

**완화 전략:**
1. 명확한 동의 필요 사유 안내
2. 동의 거부 시 로그아웃 처리
3. FAQ 또는 고객센터 안내 추가

### 6.2 계정 삭제 오류

**위험:** 삭제 처리 중 부분 실패

**완화 전략:**
1. 트랜잭션 처리로 원자성 보장
2. 삭제 실패 시 재시도 로직
3. 관리자 알림 및 수동 처리 대비

### 6.3 개인정보처리방침 법적 이슈

**위험:** 법적 요구사항 미충족

**완화 전략:**
1. 표준 템플릿 기반 작성
2. 필수 7개 항목 체크리스트 검증
3. 법률 전문가 검토 권장

---

## 7. Testing Strategy (테스트 전략)

### 7.1 Widget 테스트

| 대상 | 테스트 항목 |
|------|-------------|
| consent_screen.dart | 전체 동의, 개별 동의, 필수 체크 |
| account_delete_screen.dart | 삭제 조건 표시, 버튼 활성화 |
| account_delete_confirm_screen.dart | 확인 텍스트 입력, 재인증 |

### 7.2 Integration 테스트

| 시나리오 | 검증 항목 |
|----------|-----------|
| 신규 사용자 동의 플로우 | 로그인 -> 동의 -> 홈 |
| 기존 사용자 동의 플로우 | 로그인 -> 동의 필요 감지 -> 동의 |
| 계정 삭제 플로우 | 요청 -> 확인 -> 재인증 -> 삭제 |

### 7.3 수동 테스트

| 항목 | 검증 내용 |
|------|-----------|
| 개인정보처리방침 | 7개 필수 항목 포함 확인 |
| 이용약관 | 내용 적절성 확인 |
| WebView 렌더링 | iOS/Android 양쪽 확인 |

---

## 8. Deployment Plan (배포 계획)

### 8.1 배포 순서

1. **Cloud Functions 배포** (선행)
   ```bash
   firebase deploy --only functions:saveConsent,functions:deleteAccount
   ```

2. **Firestore 규칙 업데이트** (필요시)
   ```bash
   firebase deploy --only firestore:rules
   ```

3. **Flutter 앱 빌드 및 테스트**
   ```bash
   flutter build apk --release
   flutter build ios --release
   ```

### 8.2 Feature Flag 고려

동의 플로우를 Feature Flag로 관리하여 점진적 롤아웃 가능:
```dart
if (FeatureFlags.requireConsent) {
  // 동의 플로우 실행
}
```

### 8.3 롤백 계획

- 동의 플로우 비활성화: Feature Flag off
- Cloud Functions 롤백: 이전 버전으로 재배포
- 개인정보처리방침: 이전 HTML 복원

---

*이 문서는 SPEC-PHASE2-001의 구현 계획입니다.*
*작성일: 2026-01-23*
