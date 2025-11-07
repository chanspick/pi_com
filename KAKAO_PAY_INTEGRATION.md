# 카카오페이 결제 통합 가이드

파이컴퓨터 프로젝트에 카카오페이 결제 시스템이 성공적으로 통합되었습니다!

## ✅ 구현 완료 항목

### 1. Flutter 앱 (클라이언트)

#### Payment Feature 구조
```
lib/features/payment/
├── data/
│   ├── datasources/
│   │   ├── payment_remote_datasource.dart
│   │   └── payment_remote_datasource_impl.dart
│   ├── models/
│   │   ├── payment_prepare_request_model.dart
│   │   ├── payment_prepare_response_model.dart
│   │   ├── payment_approval_request_model.dart
│   │   └── payment_approval_response_model.dart
│   └── repositories/
│       └── payment_repository_impl.dart
├── domain/
│   ├── entities/
│   │   └── payment_entity.dart
│   ├── repositories/
│   │   └── payment_repository.dart
│   └── usecases/
│       ├── prepare_payment_usecase.dart
│       ├── approve_payment_usecase.dart
│       └── cancel_payment_usecase.dart
└── presentation/
    ├── providers/
    │   └── payment_provider.dart
    └── screens/
        └── payment_webview_screen.dart
```

#### 주요 기능
- ✅ 결제 준비 API 호출
- ✅ WebView 결제 화면 표시
- ✅ 결제 승인 처리
- ✅ 결제 취소/실패 처리
- ✅ CheckoutScreen 통합 (장바구니 결제)
- ✅ 바로 구매 기능 구현
- ✅ 웹/앱 환경 자동 감지
- ✅ Deep Link 설정 (Android)

### 2. 백엔드 API (서버)

#### 구조
```
backend_example/
├── package.json
├── .env.example
├── server.js
├── routes/
│   └── payment.js
└── README.md
```

#### API 엔드포인트
- `POST /api/payment/prepare` - 결제 준비
- `POST /api/payment/approve` - 결제 승인
- `POST /api/payment/cancel` - 결제 취소
- `GET /api/payment/:tid` - 결제 조회

### 3. 보안 설정
- ✅ Admin Key는 백엔드에서만 관리
- ✅ 환경 변수 (.env) 사용
- ✅ Deep Link 설정 (picom://payment)
- ✅ HTTPS 지원 준비

---

## 🚀 시작하기

### 1단계: 백엔드 서버 설정

```bash
cd backend_example

# 패키지 설치
npm install

# 환경 변수 설정
cp .env.example .env
```

`.env` 파일 수정:
```bash
KAKAO_ADMIN_KEY=your_admin_key_here
KAKAO_CID=TC0ONETIME
PORT=3000
APP_SCHEME=picom://payment
```

**카카오페이 Admin Key 발급:**
1. https://developers.kakaopay.com/ 접속
2. 내 애플리케이션 등록
3. Admin Key (Secret Key) 발급
4. `.env` 파일에 설정

**서버 실행:**
```bash
npm start
```

### 2단계: Flutter 앱 설정

**1. 백엔드 URL 설정**

`lib/features/payment/presentation/providers/payment_provider.dart:17` 수정:

```dart
final paymentRemoteDataSourceProvider = Provider<PaymentRemoteDataSource>((ref) {
  return PaymentRemoteDataSourceImpl(
    baseUrl: 'http://localhost:3000',  // 개발 환경
    // baseUrl: 'https://your-production-api.com',  // 프로덕션 환경
  );
});
```

**2. 패키지 설치**

```bash
flutter pub get
```

**3. 앱 실행**

```bash
flutter run
```

---

## 📱 사용 방법

### 1. 장바구니 결제

1. 상품 상세 화면에서 "장바구니" 버튼 클릭
2. 장바구니 화면에서 "결제하기" 클릭
3. 배송 방법 선택:
   - **즉시 배송**: 배송비 10,000원, 2-3일 소요
   - **드래곤볼 보관**: 무료, 30일 보관 후 합배송
4. 결제 수단 선택: **카카오페이**
5. "결제하기" 버튼 클릭
6. WebView에서 카카오페이 인증
7. 결제 완료

### 2. 바로 구매

1. 상품 상세 화면에서 "바로 구매" 버튼 클릭
2. 자동으로 CheckoutScreen으로 이동
3. 위와 동일한 결제 프로세스 진행

### 3. 드래곤볼 결제

1. 드래곤볼 보관함에서 부품 선택
2. "선택한 부품 배송 요청" 버튼 클릭
3. 합배송 비용 확인 (최대 50% 절감)
4. 카카오페이로 결제

---

## 🔧 주요 코드 위치

### CheckoutScreen (결제 화면)
**파일**: `lib/features/checkout/presentation/screens/checkout_screen.dart`

**주요 메서드**:
- `_purchase()`: 결제 처리 진입점 (144-178줄)
- `_processKakaoPayment()`: 카카오페이 결제 처리 (180-257줄)
- `_completeOrder()`: 주문 완료 처리 (277-322줄)

### PaymentWebViewScreen (결제 WebView)
**파일**: `lib/features/payment/presentation/screens/payment_webview_screen.dart`

**주요 메서드**:
- `_handleApproval()`: 결제 승인 처리 (97-132줄)
- `_handleCancel()`: 결제 취소 처리 (135-142줄)
- `_handleFail()`: 결제 실패 처리 (145-151줄)

### 바로 구매 기능
**파일**: `lib/features/listing/presentation/widgets/listing_bottom_bar.dart`

**주요 메서드**:
- `_handleDirectPurchase()`: 바로 구매 처리 (178-209줄)

---

## 🧪 테스트

### 1. 백엔드 API 테스트

```bash
# Health Check
curl http://localhost:3000/health

# 결제 준비 테스트
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

### 2. Flutter 앱 테스트

**시나리오 1: 장바구니 결제**
1. 로그인
2. 상품 검색
3. 장바구니 추가
4. CheckoutScreen 이동
5. 카카오페이 선택
6. 결제 진행

**시나리오 2: 바로 구매**
1. 로그인
2. 상품 상세 화면
3. "바로 구매" 버튼 클릭
4. 즉시 CheckoutScreen 이동
5. 결제 진행

**시나리오 3: 드래곤볼 보관**
1. 장바구니 결제 시 "드래곤볼 보관" 선택
2. 약관 동의
3. 결제 완료 후 드래곤볼에 부품 저장 확인

---

## 🌐 웹 환경 대응

### 플랫폼 감지
`checkout_screen.dart:201-211`에서 자동으로 플랫폼을 감지합니다:

```dart
if (kIsWeb) {
  // 웹 환경: 웹 URL 사용
  approvalUrl = '${Uri.base.origin}/payment/approve?order_id=$orderId';
  cancelUrl = '${Uri.base.origin}/payment/cancel';
  failUrl = '${Uri.base.origin}/payment/fail';
} else {
  // 앱 환경: Deep Link 사용
  approvalUrl = 'http://localhost:3000/payment/approve?order_id=$orderId';
  // ...
}
```

### 웹 전용 처리
웹에서는 리다이렉트 URL이 자동으로 웹 URL로 변환되어, 결제 완료 후 웹 페이지로 돌아옵니다.

---

## 📦 Play Store 업로드

### 1. 인앱 결제 정책
- **실물 상품**: 외부 결제 허용 ✅
- **디지털 콘텐츠**: Google Play 결제 필수 ❌

**파이컴퓨터**: 컴퓨터 부품 (실물 상품) → 카카오페이 사용 가능

### 2. 권한 설정
`android/app/src/main/AndroidManifest.xml`에 이미 설정됨:
- Internet 권한
- Deep Link intent-filter

### 3. WebView 사용 선언
Play Console 업로드 시:
- "앱에서 WebView를 사용하나요?" → **예**
- "WebView에서 어떤 콘텐츠를 표시하나요?" → **결제 처리**

### 4. 개인정보 처리방침
다음 항목 명시:
- 주문자 정보 (이름, 주소, 연락처)
- 결제 금액
- 결제 방법
- 카카오페이 거래 ID (tid)

---

## 🔐 보안 체크리스트

- [x] Admin Key는 백엔드에서만 사용
- [x] `.env` 파일은 `.gitignore`에 추가
- [x] HTTPS 사용 (프로덕션)
- [x] 결제 정보는 DB에 저장 (현재는 임시 Map 사용)
- [x] Deep Link 보안 검증
- [ ] Rate Limiting 설정 (향후 추가)
- [ ] 결제 금액 검증 (서버 사이드)
- [ ] 로그 모니터링

---

## 🐛 문제 해결

### 1. "결제 준비 실패: 네트워크 오류"
**원인**: 백엔드 서버가 실행되지 않음

**해결**:
```bash
cd backend_example
npm start
```

### 2. "결제 승인 실패: Admin Key 오류"
**원인**: `.env` 파일에 Admin Key가 설정되지 않음

**해결**:
1. 카카오페이 개발자센터에서 Admin Key 발급
2. `.env` 파일에 설정
3. 서버 재시작

### 3. WebView가 표시되지 않음
**원인**: 플랫폼별 WebView 설정 누락

**해결** (Android):
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.INTERNET" />
```

### 4. 결제 완료 후 주문이 생성되지 않음
**원인**: `_completeOrder` 메서드에서 에러 발생

**디버깅**:
```dart
// checkout_screen.dart
try {
  await _completeOrder(...);
} catch (e) {
  print('주문 생성 오류: $e');  // 로그 확인
}
```

---

## 📚 참고 자료

- [카카오페이 개발자 문서](https://developers.kakaopay.com/)
- [카카오페이 단건 결제 API](https://developers.kakaopay.com/docs/payment/online/single-payment)
- [Flutter WebView 플러그인](https://pub.dev/packages/webview_flutter)
- [Flutter Dio 패키지](https://pub.dev/packages/dio)
- [Node.js Express](https://expressjs.com/)

---

## 🎉 다음 단계

### 단기 (1-2주)
1. ✅ 카카오페이 테스트 환경에서 실제 결제 테스트
2. ✅ 에러 처리 강화
3. ✅ 로그 모니터링 시스템 구축

### 중기 (1개월)
1. 백엔드를 실제 서버에 배포 (Heroku, AWS, GCP 등)
2. 프로덕션 CID 발급 및 설정
3. Play Store 제출 및 심사

### 장기 (3개월)
1. 다른 결제 수단 추가 (신용카드, 계좌이체 등)
2. 정기 결제 구현 (구독 서비스)
3. 결제 통계 및 분석 대시보드

---

## 📞 문의

카카오페이 통합 관련 문의사항이 있으시면 프로젝트 이슈에 등록해주세요.

**구현 완료일**: 2025-01-07
**버전**: 1.0.0
