# 카카오페이 결제 연동 가이드

## 📋 목차
1. [카카오페이 가맹점 신청](#1-카카오페이-가맹점-신청)
2. [Admin Key 및 CID 발급](#2-admin-key-및-cid-발급)
3. [Firebase Functions 환경변수 설정](#3-firebase-functions-환경변수-설정)
4. [배포 및 테스트](#4-배포-및-테스트)

---

## 1. 카카오페이 가맹점 신청

### 1.1 카카오페이 개발자센터 접속
1. [카카오페이 개발자센터](https://developers.kakaopay.com/) 접속
2. 카카오 계정으로 로그인

### 1.2 가맹점 신청
1. **내 애플리케이션** → **애플리케이션 추가하기** 클릭
2. 앱 정보 입력:
   - 앱 이름: `파이컴퓨터` (또는 원하는 이름)
   - 사업자 구분: 개인/법인 선택
   - 앱 설명: PC 부품 거래 플랫폼

3. **결제 설정** 탭으로 이동
4. **온라인 결제** 활성화
5. 필수 정보 입력:
   - 사업자등록증 업로드
   - 정산 계좌 정보
   - 담당자 연락처

### 1.3 심사 대기
- 심사 기간: 영업일 기준 3-5일
- 승인 후 Admin Key 및 CID 발급

---

## 2. Admin Key 및 CID 발급

### 2.1 Admin Key 확인
1. 카카오페이 개발자센터 → **내 애플리케이션** 선택
2. **앱 키** 탭에서 **Admin Key** 복사
   ```
   예시: 1234567890abcdef1234567890abcdef
   ```

### 2.2 CID (가맹점 코드) 확인
1. **결제** 탭 → **가맹점 정보**에서 **CID** 확인
   ```
   예시: TC0ONETIME (테스트용)
   실제 운영: TCSUBSCRIP (정기결제) 또는 기타 CID
   ```

---

## 3. Firebase Functions 환경변수 설정

### 3.1 방법 1: Firebase CLI 사용 (권장)

```bash
# functions 디렉토리로 이동
cd functions

# 카카오페이 Admin Key 설정
firebase functions:config:set kakaopay.admin_key="YOUR_ADMIN_KEY"

# 카카오페이 CID 설정
firebase functions:config:set kakaopay.cid="YOUR_CID"

# 설정 확인
firebase functions:config:get
```

**예시:**
```bash
firebase functions:config:set kakaopay.admin_key="1234567890abcdef1234567890abcdef"
firebase functions:config:set kakaopay.cid="TC0ONETIME"
```

### 3.2 방법 2: 환경변수 파일 사용 (로컬 개발용)

`functions/.env` 파일 생성:
```env
KAKAO_ADMIN_KEY=1234567890abcdef1234567890abcdef
KAKAO_CID=TC0ONETIME
```

**⚠️ 주의:** `.env` 파일은 `.gitignore`에 추가하여 Git에 커밋하지 마세요!

### 3.3 환경변수 적용

```bash
# Firebase Functions에 환경변수 적용 (Firebase CLI 사용 시 자동 적용)
firebase deploy --only functions
```

---

## 4. 배포 및 테스트

### 4.1 Firebase Functions 배포

```bash
# functions 디렉토리로 이동
cd functions

# TypeScript 빌드
npm run build

# Firebase Functions 배포
firebase deploy --only functions
```

배포 후 URL 확인:
```
https://asia-northeast3-picom-team.cloudfunctions.net/api
```

### 4.2 테스트 준비

#### 4.2.1 테스트 계정 준비
1. 카카오페이 앱 설치 (iOS/Android)
2. 카카오 계정으로 로그인
3. 카카오페이 활성화

#### 4.2.2 Flutter 앱 테스트
1. Flutter 앱 실행:
   ```bash
   flutter run
   ```

2. 장바구니에 상품 추가

3. **결제하기** 버튼 클릭

4. 카카오페이 결제 화면에서 결제 진행

5. 결과 확인:
   - ✅ 성공: 결제 성공 페이지 표시
   - ❌ 실패: 결제 실패 페이지 표시
   - 🚫 취소: 결제 취소 페이지 표시

### 4.3 테스트 모드 vs 실제 운영

#### 테스트 모드 (TC0ONETIME)
- 실제 결제 X
- 결제 프로세스만 테스트
- 카카오페이 테스트 계정 사용

#### 실제 운영 (Production)
- 실제 결제 발생
- 정산 진행
- 실제 카카오페이 계정 사용

**⚠️ 운영 전환 시:**
```bash
# CID를 실제 운영 CID로 변경
firebase functions:config:set kakaopay.cid="YOUR_PRODUCTION_CID"
firebase deploy --only functions
```

---

## 5. API 엔드포인트 정보

### 5.1 결제 준비
```
POST https://asia-northeast3-picom-team.cloudfunctions.net/api/api/payment/prepare
```

**Request Body:**
```json
{
  "partner_order_id": "ORDER_1234567890",
  "partner_user_id": "user123",
  "item_name": "RTX 4090 외 2개",
  "quantity": 3,
  "total_amount": 3500000,
  "tax_free_amount": 0,
  "approval_url": "https://your-app.com/payment/approve",
  "cancel_url": "https://your-app.com/payment/cancel",
  "fail_url": "https://your-app.com/payment/fail"
}
```

### 5.2 결제 승인
```
POST https://asia-northeast3-picom-team.cloudfunctions.net/api/api/payment/approve
```

**Request Body:**
```json
{
  "tid": "T1234567890abcdef",
  "partner_order_id": "ORDER_1234567890",
  "partner_user_id": "user123",
  "pg_token": "pg_token_from_kakao"
}
```

### 5.3 결제 취소
```
POST https://asia-northeast3-picom-team.cloudfunctions.net/api/api/payment/cancel
```

**Request Body:**
```json
{
  "tid": "T1234567890abcdef",
  "cancel_amount": 3500000,
  "cancel_tax_free_amount": 0
}
```

---

## 6. 트러블슈팅

### 6.1 Admin Key 오류
```
Error: Payment service not configured
```

**해결 방법:**
```bash
firebase functions:config:get
# Admin Key가 설정되어 있는지 확인
firebase functions:config:set kakaopay.admin_key="YOUR_KEY"
firebase deploy --only functions
```

### 6.2 CORS 오류
```
Access-Control-Allow-Origin error
```

**해결 방법:**
- Firebase Functions에 이미 CORS 설정이 되어 있음
- Flutter 앱의 baseUrl이 정확한지 확인

### 6.3 결제 실패 (Invalid CID)
```
Error: CID not valid
```

**해결 방법:**
- 테스트 모드: `TC0ONETIME` 사용
- 실제 운영: 카카오페이에서 발급받은 실제 CID 사용

### 6.4 Firebase Functions 로그 확인
```bash
# 실시간 로그 확인
firebase functions:log

# 특정 함수 로그 확인
firebase functions:log --only api
```

---

## 7. 보안 주의사항

### 7.1 Admin Key 보안
- ❌ Git에 커밋하지 마세요
- ❌ 클라이언트 코드에 하드코딩하지 마세요
- ✅ Firebase Functions 환경변수에만 저장
- ✅ `.gitignore`에 `.env` 파일 추가

### 7.2 결제 검증
- 클라이언트에서 결제 완료 신호를 받았더라도
- 반드시 서버에서 카카오페이 API로 결제 상태 확인
- Firestore의 `payments` 컬렉션에서 결제 기록 확인

### 7.3 환경 분리
- 개발 환경: 테스트 CID 사용
- 스테이징 환경: 테스트 CID 사용
- 프로덕션 환경: 실제 CID 사용

---

## 8. 추가 리소스

- [카카오페이 공식 문서](https://developers.kakaopay.com/docs)
- [Firebase Functions 문서](https://firebase.google.com/docs/functions)
- [카카오페이 고객센터](https://cs.kakao.com/helps?service=160&locale=ko)

---

## 9. 체크리스트

배포 전 확인사항:

- [ ] 카카오페이 가맹점 승인 완료
- [ ] Admin Key 발급 완료
- [ ] CID 발급 완료
- [ ] Firebase Functions에 환경변수 설정 완료
- [ ] `npm run build` 성공
- [ ] `firebase deploy --only functions` 성공
- [ ] Flutter 앱 baseUrl 업데이트 완료
- [ ] 테스트 결제 진행 및 성공 확인
- [ ] 성공/실패/취소 페이지 정상 작동 확인
- [ ] Firebase Console에서 로그 확인
- [ ] Firestore `payments` 컬렉션에 결제 기록 저장 확인

---

**모든 설정이 완료되면 실제 결제 테스트를 진행하세요!** 🎉
