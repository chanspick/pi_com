# 🔒 PiCom 보안 가이드 (관리자용)

## 📋 목차
1. [Firebase 보안 설정](#firebase-보안-설정)
2. [API 키 및 환경변수 관리](#api-키-및-환경변수-관리)
3. [결제 시스템 보안](#결제-시스템-보안)
4. [사용자 데이터 보호](#사용자-데이터-보호)
5. [정기 보안 점검 체크리스트](#정기-보안-점검-체크리스트)
6. [보안 사고 대응 절차](#보안-사고-대응-절차)

---

## 🔥 Firebase 보안 설정

### Firestore Security Rules
**위치**: `firestore.rules`

#### ⚠️ 현재 적용된 보안 규칙 (프로덕션용)

```javascript
// 주요 보안 원칙
1. 사용자는 본인의 데이터만 읽고 쓸 수 있음
2. 관리자만 특정 작업 수행 가능 (isAdmin() 함수 사용)
3. 공개 데이터(부품, 매물)는 읽기만 가능
4. 모든 쓰기 작업은 인증 필수
```

#### 🔐 관리자 권한 확인
관리자는 Firestore의 `users` 컬렉션에서 `isAdmin: true` 플래그로 식별됩니다.

**관리자 추가 방법**:
```javascript
// Firebase Console에서 직접 실행
db.collection('users').doc('USER_ID').update({
  isAdmin: true
});
```

#### 🚨 규칙 업데이트 후 필수 작업
```bash
# Firestore Rules 배포
firebase deploy --only firestore:rules

# 배포 확인
firebase firestore:rules:get
```

---

## 🔑 API 키 및 환경변수 관리

### Firebase API 키 (공개 가능)
**위치**: `lib/firebase_options.dart`

```dart
// ✅ 이 키들은 클라이언트에 노출되어도 안전합니다
// Firestore Rules로 보안이 관리됩니다
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'AIzaSyD9l5bjk__wTe3__jORJ2F6WxTeoXEo9fQ',
  projectId: 'picom-team',
);
```

**주의**: Firebase API 키는 공개되어도 괜찮지만, **Firestore/Storage Rules**가 제대로 설정되어야 합니다!

---

### 카카오페이 Admin Key (비공개)
**위치**: Firebase Functions 환경변수

#### 🔐 설정 방법
```bash
# 카카오페이 Admin Key 설정
firebase functions:config:set kakaopay.admin_key="YOUR_ADMIN_KEY_HERE"

# 카카오페이 CID 설정 (프로덕션용)
firebase functions:config:set kakaopay.cid="YOUR_PRODUCTION_CID"

# 설정 확인
firebase functions:config:get

# Functions 재배포
firebase deploy --only functions
```

#### ⚠️ 테스트 vs 프로덕션
```javascript
// 현재 코드 (functions/src/index.ts:108)
cid: config.kakaopay?.cid || "TC0ONETIME"  // TC0ONETIME은 테스트용

// 프로덕션 배포 전 반드시 변경:
firebase functions:config:set kakaopay.cid="YOUR_REAL_CID"
```

#### 📝 카카오페이 설정 체크리스트
- [ ] 카카오페이 관리자센터에서 실 CID 발급
- [ ] Admin Key를 Firebase Functions Config에 설정
- [ ] 승인/취소/실패 URL이 실제 도메인으로 설정되었는지 확인
- [ ] 테스트 결제 후 실제 결제로 전환

---

## 💳 결제 시스템 보안

### 카카오페이 통합 보안
**위치**: `functions/src/index.ts`, `lib/features/payment/`

#### 🔒 보안 원칙
1. **서버 사이드 검증**: 모든 결제는 Firebase Functions를 통해 처리
2. **거래 ID(TID) 관리**: Firestore에 모든 결제 기록 저장
3. **이중 결제 방지**: 동일 주문 번호로 중복 결제 불가능하도록 로직 구현

#### 📊 결제 데이터 구조
```javascript
// Firestore: payments/{tid}
{
  tid: "T1234567890",
  partner_order_id: "ORDER_20250112_001",
  partner_user_id: "user123",
  total_amount: 50000,
  status: "ready" | "approved" | "cancelled" | "failed",
  created_at: Timestamp,
  approved_at: Timestamp (optional),
}
```

#### 🚨 결제 보안 점검사항
- [ ] 결제 금액은 서버에서 재계산하여 검증
- [ ] 주문 상태는 결제 승인 후에만 변경
- [ ] 취소/환불은 원래 결제 금액 검증 후 처리
- [ ] 모든 결제 로그는 Firestore에 영구 보관

---

## 👤 사용자 데이터 보호

### 개인정보 수집 항목
**위치**: `web/privacy_policy.html`, `lib/features/auth/`

#### 📝 수집하는 개인정보
1. **필수 정보**
   - 이메일 주소 (Firebase Auth)
   - 비밀번호 (암호화되어 저장)

2. **선택 정보**
   - 닉네임
   - 프로필 이미지
   - 배송지 정보 (주문 시)

3. **자동 수집 정보**
   - 접속 로그
   - 기기 정보 (User Agent)
   - IP 주소 (Firebase 자동 수집)

#### 🗑️ 회원 탈퇴 및 데이터 삭제
**위치**: `web/account_deletion.html`

```dart
// 사용자 데이터 완전 삭제 절차
1. Firebase Auth 계정 삭제
2. Firestore 사용자 문서 삭제 (/users/{userId})
3. 서브컬렉션 삭제:
   - /users/{userId}/dragonBalls
   - /users/{userId}/cart
   - /users/{userId}/favorites
   - /users/{userId}/addresses
4. Storage의 사용자 이미지 삭제
```

#### ⚠️ 보관 데이터
**법적 보관 의무로 삭제하지 않는 데이터**:
- 결제 기록 (5년)
- 주문 기록 (5년)
- 환불/취소 기록 (5년)

---

## 🔍 정기 보안 점검 체크리스트

### 월간 점검 (매월 1일)
- [ ] Firestore Rules 최신 상태 확인
- [ ] Firebase Functions 로그 검토 (비정상 패턴 확인)
- [ ] 결제 실패 로그 분석
- [ ] 사용자 신고 내역 검토

### 주간 점검 (매주 월요일)
- [ ] Firebase Console에서 이상 트래픽 확인
- [ ] Storage 사용량 모니터링
- [ ] Functions 실행 횟수 및 에러율 확인

### 배포 전 필수 점검
- [ ] `firestore.rules` 프로덕션 규칙 적용
- [ ] `functions/src/index.ts`에 테스트 키 없는지 확인
- [ ] `.gitignore`에 민감 정보 파일 추가 확인
- [ ] 카카오페이 CID가 프로덕션용인지 확인
- [ ] 앱 버전 코드/이름 업데이트
- [ ] ProGuard 규칙 적용 (난독화)

---

## 🚨 보안 사고 대응 절차

### 1단계: 즉시 조치
```bash
# 의심되는 경우 즉시 Firestore Rules를 읽기 전용으로 변경
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read: if request.auth != null;
      allow write: if false;  // 모든 쓰기 차단
    }
  }
}

# 긴급 배포
firebase deploy --only firestore:rules
```

### 2단계: 피해 범위 확인
1. Firebase Console > Firestore > 최근 변경 로그 확인
2. Functions 로그에서 비정상 요청 패턴 분석
3. 영향받은 사용자 식별

### 3단계: 복구
1. 백업 데이터로 복원 (Firestore 자동 백업 활용)
2. 보안 취약점 패치
3. 정상 Rules 재배포
4. 영향받은 사용자에게 알림

### 4단계: 사후 조치
1. 사고 원인 분석 문서 작성
2. 재발 방지 대책 수립
3. 관련 규정 및 절차 업데이트

---

## 📞 비상 연락망

### Firebase 프로젝트 정보
- **Project ID**: `picom-team`
- **Console URL**: https://console.firebase.google.com/project/picom-team

### 주요 서비스 관리자 페이지
- **카카오페이**: https://developers.kakao.com/console/app
- **Google Play Console**: https://play.google.com/console

---

## 🔄 버전 히스토리
- **v1.0.2** (2025-01-12): Firestore Rules 프로덕션 전환
- **v1.0.1** (2025-01-12): 카카오페이 통합
- **v1.0.0** (2025-01-10): 초기 출시

---

## 📚 참고 자료
- [Firebase Security Rules 공식 문서](https://firebase.google.com/docs/rules)
- [카카오페이 개발 가이드](https://developers.kakaopay.com/)
- [Google Play 보안 정책](https://play.google.com/console/about/guides/security/)
- [개인정보보호법](https://www.privacy.go.kr/)

---

**마지막 업데이트**: 2025-01-12
**작성자**: PiCom 개발팀
**문의**: 앱 내 고객센터
