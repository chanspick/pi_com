# PiCom 카카오페이 백엔드 API

Flutter 앱에서 카카오페이 결제를 처리하기 위한 백엔드 API 서버입니다.

## 🚀 빠른 시작

### 1. 패키지 설치

```bash
npm install
```

### 2. 환경 변수 설정

`.env.example` 파일을 복사하여 `.env` 파일을 생성하고, 카카오페이에서 발급받은 Admin Key를 설정하세요.

```bash
cp .env.example .env
```

`.env` 파일 수정:
```
KAKAO_ADMIN_KEY=your_admin_key_here
KAKAO_CID=TC0ONETIME
PORT=3000
APP_SCHEME=picom://payment
```

### 3. 서버 실행

```bash
# 일반 실행
npm start

# 개발 모드 (nodemon)
npm run dev
```

## 📡 API 엔드포인트

### 1. Health Check
```
GET /health
```

**응답 예시:**
```json
{
  "status": "OK",
  "message": "PiCom Payment Backend is running"
}
```

### 2. 결제 준비
```
POST /api/payment/prepare
```

**요청 Body:**
```json
{
  "partner_order_id": "ORDER_1234567890",
  "partner_user_id": "user123",
  "item_name": "CPU 외 2개",
  "quantity": 3,
  "total_amount": 500000,
  "tax_free_amount": 0,
  "approval_url": "picom://payment/approve?order_id=ORDER_1234567890",
  "cancel_url": "picom://payment/cancel",
  "fail_url": "picom://payment/fail"
}
```

**응답 예시:**
```json
{
  "tid": "T1234567890abcdef",
  "next_redirect_app_url": "kakaotalk://kakaopay/...",
  "next_redirect_mobile_url": "https://online-pay.kakao.com/...",
  "next_redirect_pc_url": "https://online-pay.kakao.com/...",
  "android_app_scheme": "kakaotalk://kakaopay/...",
  "ios_app_scheme": "kakaotalk://kakaopay/...",
  "created_at": "2025-01-07T12:34:56Z"
}
```

### 3. 결제 승인
```
POST /api/payment/approve
```

**요청 Body:**
```json
{
  "tid": "T1234567890abcdef",
  "partner_order_id": "ORDER_1234567890",
  "partner_user_id": "user123",
  "pg_token": "xxxxxxxxxxxxxxxx"
}
```

**응답 예시:**
```json
{
  "aid": "A1234567890abcdef",
  "tid": "T1234567890abcdef",
  "cid": "TC0ONETIME",
  "partner_order_id": "ORDER_1234567890",
  "partner_user_id": "user123",
  "payment_method_type": "MONEY",
  "amount": {
    "total": 500000,
    "tax_free": 0,
    "vat": 45454,
    "point": 0,
    "discount": 0
  },
  "item_name": "CPU 외 2개",
  "quantity": 3,
  "created_at": "2025-01-07T12:34:56Z",
  "approved_at": "2025-01-07T12:35:30Z"
}
```

### 4. 결제 취소
```
POST /api/payment/cancel
```

**요청 Body:**
```json
{
  "tid": "T1234567890abcdef",
  "cancel_amount": 500000,
  "cancel_tax_free_amount": 0
}
```

### 5. 결제 조회
```
GET /api/payment/:tid
```

## 🔐 보안 주의사항

1. **Admin Key는 절대 클라이언트(Flutter 앱)에 노출하지 마세요**
2. `.env` 파일은 `.gitignore`에 추가하세요
3. 프로덕션 환경에서는 HTTPS를 사용하세요
4. 실제 서비스에서는 DB를 사용하여 결제 정보를 저장하세요

## 📝 카카오페이 Admin Key 발급

1. [카카오페이 개발자센터](https://developers.kakaopay.com/) 접속
2. 내 애플리케이션 등록
3. Admin Key (Secret Key) 발급
4. `.env` 파일에 설정

## 🧪 테스트

### 테스트 환경
- CID: `TC0ONETIME` (테스트 가맹점 코드)
- 테스트 카드번호는 카카오페이 문서 참조

### cURL 테스트 예시

**결제 준비:**
```bash
curl -X POST http://localhost:3000/api/payment/prepare \
  -H "Content-Type: application/json" \
  -d '{
    "partner_order_id": "ORDER_TEST",
    "partner_user_id": "user_test",
    "item_name": "테스트 상품",
    "quantity": 1,
    "total_amount": 10000,
    "approval_url": "picom://payment/approve",
    "cancel_url": "picom://payment/cancel",
    "fail_url": "picom://payment/fail"
  }'
```

## 🚢 배포

### Heroku
```bash
heroku create picom-payment-backend
heroku config:set KAKAO_ADMIN_KEY=your_admin_key_here
heroku config:set KAKAO_CID=your_cid_here
git push heroku main
```

### AWS, GCP, Azure 등
- Node.js 런타임 지원
- 환경 변수 설정
- HTTPS 인증서 설치

## 📚 참고 자료

- [카카오페이 개발자 문서](https://developers.kakaopay.com/)
- [단건 결제 API](https://developers.kakaopay.com/docs/payment/online/single-payment)
- [Express.js 문서](https://expressjs.com/)
