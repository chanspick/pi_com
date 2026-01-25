# PiCom 애플리케이션 재구조화 로드맵

> **프로젝트**: PiCom (중고 PC 부품 거래 플랫폼)
> **작성일**: 2026-01-22
> **상태**: 계획 단계
> **예상 기간**: 12-14주 (약 3개월)

---

## 📋 Executive Summary

### 현재 상황
- **플랫폼**: Flutter 웹앱 (Web + Mobile 통합 코드베이스)
- **문제점**:
  - Google Play Store 데이터/개인정보 정책 위반으로 앱 정지
  - 결제 플로우 Critical 버그 존재
  - 테스트 코드 부재
  - 웹/앱 코드 혼재로 유지보수 어려움

### 목표 상태
- **Flutter 모바일 앱**: 새 패키지명으로 Play Store/App Store 재출시
- **JavaScript 웹앱**: Next.js 기반 모던 웹 애플리케이션
- **공유 코드**: 비즈니스 로직 패키지화로 코드 재사용

### 핵심 변경사항
1. 앱 패키지명/아이콘 변경 (새 앱으로 출시)
2. Google Play 데이터 안전 정책 완전 준수
3. 개인정보 처리방침/동의 UI 강화
4. Flutter 앱과 JS 웹 완전 분리
5. **⭐ 백엔드 강화**: 송장 시스템 + Admin 기능 강화 (매출 리포트, 고급 필터)

---

## 🚨 Phase 0: 긴급 수정 (1-2일)

### 0.1 Critical 버그 수정

#### 결제-주문 트랜잭션 보장
- **파일**: `lib/features/checkout/presentation/screens/checkout_screen.dart:443-448`
- **문제**: 결제 승인 성공 후 주문 생성 실패 시 사용자 금전 손실
- **해결**:
  ```dart
  // Before: 순차 실행 (위험)
  await approvePayment();
  await createOrder(); // 실패 시 결제만 완료됨

  // After: 트랜잭션 보장
  try {
    await createOrder(); // 주문 먼저 생성 (pending 상태)
    await approvePayment();
    await updateOrderStatus('paid');
  } catch (e) {
    await rollbackOrder();
    await cancelPayment();
    rethrow;
  }
  ```

#### 중복 결제 방지
- **파일**: `lib/features/checkout/presentation/screens/checkout_screen.dart`
- **문제**: 타임스탬프 기반 주문 ID로 동시 요청 시 중복 가능
- **해결**: UUID v4 도입
  ```dart
  // Before
  final orderId = DateTime.now().millisecondsSinceEpoch.toString();

  // After
  import 'package:uuid/uuid.dart';
  final orderId = const Uuid().v4();
  ```

#### HTTP 타임아웃 설정
- **파일**: `lib/features/payment/data/datasources/payment_remote_datasource_impl.dart`
- **해결**:
  ```dart
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
    sendTimeout: const Duration(seconds: 10),
  ));
  ```

### 0.2 보안 이슈 수정

#### Kakao SDK 키 환경변수 분리
- **파일**: `lib/main.dart`
- **현재**: 하드코딩된 API 키
- **해결**: `.env` 파일로 분리
  ```dart
  // Before
  KakaoSdk.init(nativeAppKey: 'HARDCODED_KEY');

  // After
  await dotenv.load();
  KakaoSdk.init(nativeAppKey: dotenv.env['KAKAO_NATIVE_APP_KEY']!);
  ```

---

## 🔴 Phase 1: Google Play 정책 준수 (1주) - 최우선

> **목표**: 데이터 안전 정책 완전 준수로 재출시 기반 마련

### 1.1 데이터 안전 섹션 준비

Google Play Console > 앱 콘텐츠 > 데이터 안전에 정확히 선언해야 할 항목:

#### 수집하는 데이터 유형
| 카테고리 | 데이터 유형 | 수집 여부 | 공유 여부 | 필수 여부 |
|---------|-----------|----------|----------|----------|
| 개인 정보 | 이름 | ✅ | ❌ | ✅ |
| 개인 정보 | 이메일 | ✅ | ❌ | ✅ |
| 개인 정보 | 전화번호 | ✅ | ❌ | ✅ |
| 위치 | 주소 (배송용) | ✅ | ✅ (배송사) | ✅ |
| 금융 정보 | 결제 정보 | ✅ | ✅ (PG사) | ✅ |
| 앱 활동 | 구매 내역 | ✅ | ❌ | ✅ |
| 기기 ID | Firebase Installation ID | ✅ | ❌ | ✅ |

#### 데이터 보안 조치
- [ ] Firebase App Check 활성화 (이미 적용됨)
- [ ] Firestore Security Rules 검토 및 강화
- [ ] 전송 중 암호화 (HTTPS - Firebase 기본 적용)
- [ ] 저장 데이터 암호화 (Firebase 기본 적용)

### 1.2 개인정보 처리방침 업데이트

**파일**: `assets/html/privacy.html` (현재 존재)

추가/수정해야 할 필수 항목:
- [ ] 수집하는 개인정보 항목 명시
- [ ] 개인정보의 수집 및 이용 목적
- [ ] 개인정보의 보유 및 이용 기간
- [ ] 개인정보의 제3자 제공 (PG사, 배송사)
- [ ] 개인정보의 파기 절차 및 방법
- [ ] 이용자의 권리 (열람, 정정, 삭제, 처리정지)
- [ ] 개인정보 보호책임자 연락처
- [ ] 개인정보처리방침 변경 고지

### 1.3 동의 UI 구현

#### 필수 동의 화면
```
lib/features/auth/presentation/screens/
├── consent_screen.dart          # 새로 생성
├── privacy_detail_screen.dart   # 새로 생성
└── terms_detail_screen.dart     # 새로 생성
```

#### 동의 항목
- [ ] (필수) 서비스 이용약관 동의
- [ ] (필수) 개인정보 처리방침 동의
- [ ] (필수) 개인정보 제3자 제공 동의 (결제/배송)
- [ ] (선택) 마케팅 정보 수신 동의
- [ ] (선택) 푸시 알림 수신 동의

#### 동의 저장
```dart
// Firestore users/{uid}/consents
{
  "termsAgreed": true,
  "termsAgreedAt": Timestamp,
  "privacyAgreed": true,
  "privacyAgreedAt": Timestamp,
  "thirdPartyAgreed": true,
  "thirdPartyAgreedAt": Timestamp,
  "marketingAgreed": false,
  "marketingAgreedAt": null,
  "pushAgreed": true,
  "pushAgreedAt": Timestamp,
  "consentVersion": "1.0.0"
}
```

### 1.4 계정 삭제 기능 구현

> Google Play 필수 요구사항: 사용자가 앱 내에서 계정 삭제 가능해야 함

**구현 위치**: `lib/features/my_page/presentation/screens/`

#### 삭제 플로우
1. 마이페이지 > 설정 > 계정 삭제
2. 삭제 전 경고 (주문/드래곤볼 처리 안내)
3. 비밀번호/소셜 재인증
4. 최종 확인 후 삭제 요청
5. 관리자 승인 후 30일 내 완전 삭제 (또는 즉시 삭제)

#### 삭제되는 데이터
- Firebase Auth 계정
- Firestore 사용자 문서
- Firebase Storage 업로드 이미지
- 관련 주문/알림/찜 데이터 (익명화 또는 삭제)

---

## 🔶 Phase 1.5: 백엔드 & Admin 강화 (2주)

> **목표**: 송장 시스템 구축 및 Admin 기능 강화로 운영 효율성 극대화

### 1.5.1 송장(Invoice) 시스템

#### 개요
- **자동 생성**: 결제 완료 시 Cloud Function이 자동으로 PDF 송장 생성
- **수동 발행**: Admin에서 재발행/수정 발행 가능
- **저장**: Firebase Storage (`invoices/{orderId}.pdf`)

#### Cloud Function 구현
```typescript
// functions/src/invoice/invoice_generator.ts
import * as pdfkit from 'pdfkit';
import * as admin from 'firebase-admin';

interface InvoiceData {
  orderId: string;
  orderDate: Date;
  buyerName: string;
  buyerEmail: string;
  buyerPhone: string;
  shippingAddress: string;
  items: Array<{
    name: string;
    quantity: number;
    unitPrice: number;
    totalPrice: number;
  }>;
  subtotal: number;
  shippingFee: number;
  totalAmount: number;
  paymentMethod: string;
}

export async function generateInvoice(orderId: string): Promise<string> {
  // 1. Firestore에서 주문 정보 조회
  // 2. PDF 생성 (pdfkit)
  // 3. Firebase Storage 업로드
  // 4. orders/{orderId}에 invoiceUrl 저장
  // 5. URL 반환
}
```

#### API 엔드포인트
```typescript
// POST /invoice/generate
// - orderId: 주문 ID
// - 응답: { invoiceUrl: string, invoiceId: string }

// GET /invoice/{orderId}
// - 응답: PDF 파일 또는 리다이렉트

// POST /invoice/regenerate
// - orderId: 주문 ID (재발행용)
```

#### 송장 데이터 모델
```typescript
// Firestore: invoices/{invoiceId}
interface Invoice {
  invoiceId: string;
  orderId: string;
  invoiceNumber: string;  // INV-2026-00001 형식
  generatedAt: Timestamp;
  regeneratedAt?: Timestamp;
  regenerateReason?: string;
  pdfUrl: string;
  status: 'generated' | 'regenerated' | 'voided';

  // 스냅샷 (발행 시점 데이터 보존)
  buyerSnapshot: {
    name: string;
    email: string;
    phone: string;
    address: string;
  };
  itemsSnapshot: Array<{
    name: string;
    quantity: number;
    unitPrice: number;
  }>;
  amountSnapshot: {
    subtotal: number;
    shippingFee: number;
    total: number;
  };
}
```

#### Orders 컬렉션 필드 추가
```typescript
// orders/{orderId} 추가 필드
{
  invoiceId: string | null;
  invoiceUrl: string | null;
  invoiceGeneratedAt: Timestamp | null;
}
```

### 1.5.2 Admin 강화 - 주문/배송 통합 관리

#### 주문 상세 관리 화면
**파일**: `lib/features/admin/presentation/screens/order_detail_management_page.dart`

```dart
// 주요 기능
class OrderDetailManagementPage extends StatelessWidget {
  // 1. 주문 상세 정보 표시
  //    - 주문자 정보, 상품 목록, 결제 정보
  //    - 배송 상태 타임라인
  //    - 환불/취소 이력

  // 2. 송장 관리
  //    - 송장 조회/다운로드 버튼
  //    - 송장 재발행 버튼 (사유 입력)

  // 3. 배송 관리
  //    - 운송장 번호 입력/수정
  //    - 배송 상태 수동 변경
  //    - 배송 메모 추가

  // 4. 빠른 액션
  //    - 주문 취소 처리
  //    - 환불 승인/거절
  //    - 고객 연락 (전화/메시지)
}
```

#### 일괄 처리 기능
```dart
// 대량 송장 발행
Future<void> bulkGenerateInvoices(List<String> orderIds);

// 대량 배송 상태 변경
Future<void> bulkUpdateShippingStatus(
  List<String> orderIds,
  ShippingStatus status,
);

// 엑셀 내보내기
Future<Uint8List> exportOrdersToExcel(OrderFilter filter);
```

### 1.5.3 Admin 강화 - 매출/정산 리포트

#### 대시보드 위젯
**파일**: `lib/features/admin/presentation/screens/revenue_dashboard_page.dart`

```dart
// 주요 메트릭
class RevenueDashboard {
  // 일별/주별/월별 매출
  Widget dailyRevenueChart();
  Widget weeklyRevenueChart();
  Widget monthlyRevenueChart();

  // 정산 현황
  Widget settlementStatus();      // 정산 대기/완료 금액
  Widget sellerPayoutPending();   // 판매자별 정산 예정

  // 수수료 현황
  Widget commissionSummary();     // 플랫폼 수수료 합계

  // 환불 현황
  Widget refundSummary();         // 환불 건수/금액
}
```

#### 리포트 생성
```dart
// 정산 리포트
Future<RevenueReport> generateRevenueReport({
  required DateTime startDate,
  required DateTime endDate,
  ReportType type, // daily, weekly, monthly
});

// 판매자별 정산 리포트
Future<SellerSettlementReport> generateSellerReport({
  required String sellerId,
  required DateTime startDate,
  required DateTime endDate,
});
```

### 1.5.4 Admin 강화 - 고급 검색/필터

#### 통합 검색 기능
**파일**: `lib/features/admin/presentation/widgets/advanced_search_widget.dart`

```dart
class AdvancedSearchWidget extends StatefulWidget {
  // 검색 대상
  // - 주문: 주문번호, 주문자명, 상품명
  // - 사용자: 이름, 이메일, 전화번호
  // - 매물: 상품명, 판매자명

  // 필터 옵션
  // - 기간: 오늘, 이번주, 이번달, 커스텀
  // - 상태: 결제대기, 결제완료, 배송중, 배송완료, 환불 등
  // - 금액 범위: 최소~최대
  // - 카테고리: CPU, GPU, RAM 등
  // - 정렬: 최신순, 금액순, 상태순
}
```

#### Firestore 복합 쿼리 최적화
```typescript
// firestore.indexes.json 추가 인덱스
{
  "collectionGroup": "orders",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "status", "order": "ASCENDING" },
    { "fieldPath": "createdAt", "order": "DESCENDING" },
    { "fieldPath": "totalPrice", "order": "DESCENDING" }
  ]
}
```

### 1.5.5 구현 체크리스트

#### 백엔드 (Cloud Functions)
- [ ] pdfkit 의존성 추가 (`functions/package.json`)
- [ ] `invoice_generator.ts` 구현
- [ ] `/invoice/generate` 엔드포인트
- [ ] `/invoice/{orderId}` 엔드포인트
- [ ] 결제 완료 트리거 (자동 송장 생성)
- [ ] Firestore `invoices` 컬렉션 보안 규칙

#### Flutter Admin
- [ ] `order_detail_management_page.dart` 생성
- [ ] `revenue_dashboard_page.dart` 생성
- [ ] `advanced_search_widget.dart` 생성
- [ ] 일괄 처리 기능 구현
- [ ] 엑셀 내보내기 기능

#### 데이터 모델
- [ ] `orders` 컬렉션에 `invoiceId`, `invoiceUrl` 필드 추가
- [ ] `invoices` 컬렉션 생성
- [ ] Firestore 인덱스 추가

---

## 🟠 Phase 2: 앱 리브랜딩 (3-5일)

> **목표**: 새 앱으로 Play Store 재출시를 위한 패키지/브랜딩 변경

### 2.1 패키지명 변경

#### Android
**파일**:
- `android/app/build.gradle`
- `android/app/src/main/AndroidManifest.xml`
- `android/app/src/main/kotlin/.../MainActivity.kt`

```gradle
// Before
applicationId "com.example.picom"

// After (예시)
applicationId "com.picom.partshop"
```

**필수 변경 항목**:
- [ ] `build.gradle` applicationId
- [ ] `AndroidManifest.xml` package
- [ ] Kotlin/Java 패키지 경로 변경
- [ ] Firebase google-services.json 재발급

#### iOS
**파일**: `ios/Runner.xcodeproj/project.pbxproj`

```
// Before
PRODUCT_BUNDLE_IDENTIFIER = com.example.picom

// After
PRODUCT_BUNDLE_IDENTIFIER = com.picom.partshop
```

**필수 변경 항목**:
- [ ] Bundle Identifier 변경
- [ ] Firebase GoogleService-Info.plist 재발급

### 2.2 앱 아이콘/스플래시 변경

#### 아이콘 변경
```
assets/icons/
├── app_icon.png              # 1024x1024 마스터
├── app_icon_foreground.png   # Android Adaptive Icon
└── app_icon_background.png   # Android Adaptive Icon Background
```

**flutter_launcher_icons 사용**:
```yaml
# pubspec.yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1

flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icons/app_icon.png"
  adaptive_icon_foreground: "assets/icons/app_icon_foreground.png"
  adaptive_icon_background: "#FFFFFF"
```

#### 스플래시 변경
```yaml
# pubspec.yaml
dev_dependencies:
  flutter_native_splash: ^2.3.8

flutter_native_splash:
  color: "#FFFFFF"
  image: assets/icons/splash_logo.png
  android_12:
    icon_background_color: "#FFFFFF"
```

### 2.3 Firebase 프로젝트 설정

#### 옵션 A: 기존 프로젝트에 새 앱 추가 (권장)
- Firebase Console > 프로젝트 설정 > 앱 추가
- 새 패키지명으로 Android/iOS 앱 등록
- 새 google-services.json / GoogleService-Info.plist 다운로드

#### 옵션 B: 새 Firebase 프로젝트 생성
- 데이터 마이그레이션 필요
- Firestore/Storage/Auth 데이터 이전 작업 추가됨

### 2.4 스토어 메타데이터

#### 변경 필요 항목
- [ ] 앱 이름 (한글/영문)
- [ ] 앱 설명 (짧은 설명, 전체 설명)
- [ ] 스크린샷 (휴대폰, 태블릿)
- [ ] 그래픽 이미지 (1024x500)
- [ ] 기능 그래픽
- [ ] 카테고리 재선택

---

## 🟡 Phase 3: 코드 품질 강화 (1주)

### 3.1 Debug 코드 정리

**제거 대상 파일**:
- `lib/features/admin/data/repositories/admin_auth_repository.dart` - print() 문
- `lib/features/recommendation/data/datasources/compatibility_remote_datasource_impl.dart`
- 기타 print() 문이 있는 파일들

**교체 방법**:
```dart
// Before
print('Debug: $value');

// After (개발 모드에서만)
import 'package:flutter/foundation.dart';
debugPrint('Debug: $value');

// 또는 로깅 라이브러리 사용
import 'package:logger/logger.dart';
final logger = Logger();
logger.d('Debug: $value');
```

### 3.2 에러 핸들링 표준화

**통일된 에러 핸들링 클래스**:
```dart
// lib/core/errors/failures.dart
sealed class Failure {
  final String message;
  final String? code;
  const Failure(this.message, [this.code]);
}

class NetworkFailure extends Failure {
  const NetworkFailure([String message = '네트워크 연결을 확인해주세요'])
    : super(message, 'NETWORK_ERROR');
}

class AuthFailure extends Failure {
  const AuthFailure([String message = '인증에 실패했습니다'])
    : super(message, 'AUTH_ERROR');
}

class PaymentFailure extends Failure {
  const PaymentFailure([String message = '결제 처리 중 오류가 발생했습니다'])
    : super(message, 'PAYMENT_ERROR');
}

class ServerFailure extends Failure {
  const ServerFailure([String message = '서버 오류가 발생했습니다'])
    : super(message, 'SERVER_ERROR');
}
```

### 3.3 핵심 테스트 작성

**테스트 디렉토리 구조**:
```
test/
├── core/
│   └── models/
│       └── user_model_test.dart
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   └── repositories/
│   │   └── presentation/
│   │       └── providers/
│   │           └── auth_provider_test.dart
│   ├── cart/
│   │   └── presentation/
│   │       └── providers/
│   │           └── cart_provider_test.dart
│   └── payment/
│       └── presentation/
│           └── providers/
│               └── payment_provider_test.dart
└── test_helper.dart
```

**최소 테스트 커버리지 목표**: 핵심 기능 60%

---

## 🟢 Phase 4: 공유 패키지 추출 (2주)

### 4.1 모노레포 구조 전환

**목표 구조**:
```
pi_com/
├── packages/
│   └── picom_core/                    # 공유 비즈니스 로직
│       ├── lib/
│       │   ├── models/                # 데이터 모델
│       │   │   ├── user_model.dart
│       │   │   ├── listing_model.dart
│       │   │   ├── order_model.dart
│       │   │   └── ...
│       │   ├── repositories/          # Repository 추상화
│       │   │   ├── auth_repository.dart
│       │   │   ├── listing_repository.dart
│       │   │   └── ...
│       │   ├── services/              # 비즈니스 서비스
│       │   │   ├── cart_service.dart
│       │   │   ├── payment_service.dart
│       │   │   └── ...
│       │   └── picom_core.dart        # 배럴 파일
│       ├── pubspec.yaml
│       └── test/
│
├── apps/
│   └── mobile/                        # Flutter 모바일 앱
│       ├── lib/
│       │   ├── main.dart
│       │   ├── app.dart
│       │   ├── features/              # UI 레이어만
│       │   │   ├── auth/presentation/
│       │   │   ├── cart/presentation/
│       │   │   └── ...
│       │   └── core/
│       │       ├── di/                # 의존성 주입
│       │       └── router/            # 네비게이션
│       └── pubspec.yaml               # picom_core 의존성
│
└── melos.yaml                         # 모노레포 관리
```

### 4.2 Melos 설정

```yaml
# melos.yaml
name: picom
packages:
  - packages/**
  - apps/**

scripts:
  analyze:
    run: melos exec -- dart analyze
    description: Run analyzer in all packages

  test:
    run: melos exec -- flutter test
    description: Run tests in all packages

  build:mobile:
    run: cd apps/mobile && flutter build apk
    description: Build mobile app
```

### 4.3 추출 대상 코드

| 현재 위치 | 새 위치 | 파일 수 |
|----------|--------|--------|
| `lib/core/models/` | `packages/picom_core/lib/models/` | ~13개 |
| `lib/features/*/domain/entities/` | `packages/picom_core/lib/entities/` | ~10개 |
| `lib/features/*/domain/repositories/` | `packages/picom_core/lib/repositories/` | ~8개 |
| `lib/features/*/domain/usecases/` | `packages/picom_core/lib/usecases/` | ~15개 |

---

## 🔵 Phase 5: Flutter 모바일 앱 최적화 (2주)

### 5.1 웹 전용 코드 제거

**제거 대상**:
- [ ] `lib/features/web_public/` 전체 디렉토리
- [ ] GoRouter 관련 코드 및 의존성
- [ ] `kIsWeb` 분기 중 웹 전용 코드
- [ ] 웹 전용 HTML 자산 (landing, about 등)

**유지 대상**:
- `assets/html/daum_postcode.html` (모바일 WebView용)
- `assets/html/privacy.html`, `termsofuse.html` (WebView 표시용)

### 5.2 모바일 전용 최적화

#### 네비게이션 개선
```dart
// auto_route 또는 go_router for mobile 도입 검토
// 현재 Navigator 1.0 기반 → Navigator 2.0 업그레이드
```

#### UI/UX 개선
- [ ] 터치 타겟 최소 48x48dp 보장
- [ ] 스와이프 제스처 추가 (뒤로가기, 삭제 등)
- [ ] 풀-투-리프레시 일관성 있게 적용
- [ ] 로딩 상태 스켈레톤 UI 적용

#### 성능 최적화
- [ ] 이미지 레이지 로딩 강화
- [ ] 리스트 가상화 (ListView.builder 확인)
- [ ] 불필요한 리빌드 방지 (const, select)

### 5.3 오프라인 지원 강화

```dart
// Firestore 오프라인 캐시 설정
FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: true,
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);
```

---

## 🟣 Phase 6: JS 웹앱 신규 개발 (4-6주)

### 6.1 기술 스택

```json
{
  "framework": "Next.js 15 (App Router)",
  "language": "TypeScript 5.x",
  "state": "TanStack Query v5 + Zustand",
  "ui": "shadcn/ui + Tailwind CSS v4",
  "auth": "NextAuth.js v5 + Firebase Auth",
  "database": "Firebase Firestore (Admin SDK)",
  "deployment": "Vercel"
}
```

### 6.2 프로젝트 구조

```
apps/web/                              # 또는 pi_com_web/
├── app/
│   ├── (marketing)/                   # 마케팅 페이지 그룹
│   │   ├── page.tsx                   # 랜딩 페이지
│   │   ├── about/page.tsx
│   │   ├── terms/page.tsx
│   │   └── privacy/page.tsx
│   │
│   ├── (shop)/                        # 쇼핑 페이지 그룹
│   │   ├── layout.tsx                 # 쇼핑 레이아웃 (헤더, 푸터)
│   │   ├── parts/
│   │   │   ├── page.tsx               # 부품 목록
│   │   │   └── [category]/page.tsx    # 카테고리별 목록
│   │   ├── listing/[id]/page.tsx      # 상품 상세
│   │   └── cart/page.tsx              # 장바구니
│   │
│   ├── (user)/                        # 인증 필요 페이지
│   │   ├── layout.tsx                 # 인증 체크 레이아웃
│   │   ├── my-page/page.tsx
│   │   ├── checkout/page.tsx
│   │   ├── orders/page.tsx
│   │   └── orders/[id]/page.tsx
│   │
│   ├── admin/                         # 관리자 패널
│   │   ├── layout.tsx
│   │   ├── page.tsx                   # 대시보드
│   │   ├── listings/page.tsx
│   │   ├── orders/page.tsx
│   │   └── users/page.tsx
│   │
│   ├── api/                           # API 라우트
│   │   ├── auth/[...nextauth]/route.ts
│   │   └── webhooks/
│   │       └── payment/route.ts       # 결제 웹훅
│   │
│   ├── layout.tsx                     # 루트 레이아웃
│   └── globals.css
│
├── components/
│   ├── ui/                            # shadcn/ui 컴포넌트
│   ├── layout/                        # Header, Footer, Navigation
│   ├── listing/                       # 상품 관련 컴포넌트
│   ├── cart/                          # 장바구니 컴포넌트
│   └── forms/                         # 폼 컴포넌트
│
├── lib/
│   ├── firebase/
│   │   ├── admin.ts                   # Firebase Admin SDK
│   │   └── client.ts                  # Firebase Client SDK
│   ├── hooks/
│   │   ├── useListings.ts
│   │   ├── useCart.ts
│   │   └── useAuth.ts
│   ├── stores/
│   │   └── cartStore.ts               # Zustand 스토어
│   └── utils/
│       ├── formatters.ts
│       └── validators.ts
│
├── types/
│   ├── listing.ts
│   ├── user.ts
│   └── order.ts
│
├── next.config.js
├── tailwind.config.ts
├── tsconfig.json
└── package.json
```

### 6.3 Firebase 타입 공유

TypeScript 타입 정의를 공유하여 Flutter 모델과 동기화:

```typescript
// types/listing.ts
export interface Listing {
  id: string;
  sellerId: string;
  title: string;
  description: string;
  price: number;
  originalPrice: number;
  category: 'CPU' | 'GPU' | 'RAM' | 'SSD' | 'MOTHERBOARD' | 'POWER' | 'CASE' | 'COOLER';
  condition: 'NEW' | 'LIKE_NEW' | 'GOOD' | 'FAIR';
  images: string[];
  status: 'AVAILABLE' | 'RESERVED' | 'SOLD';
  createdAt: Timestamp;
  updatedAt: Timestamp;
}
```

### 6.4 인증 설정

```typescript
// lib/auth.ts
import NextAuth from 'next-auth';
import GoogleProvider from 'next-auth/providers/google';
import KakaoProvider from 'next-auth/providers/kakao';
import { FirestoreAdapter } from '@auth/firebase-adapter';
import { cert } from 'firebase-admin/app';

export const { handlers, signIn, signOut, auth } = NextAuth({
  providers: [
    GoogleProvider({
      clientId: process.env.GOOGLE_CLIENT_ID!,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET!,
    }),
    KakaoProvider({
      clientId: process.env.KAKAO_CLIENT_ID!,
      clientSecret: process.env.KAKAO_CLIENT_SECRET!,
    }),
  ],
  adapter: FirestoreAdapter({
    credential: cert({
      projectId: process.env.FIREBASE_PROJECT_ID,
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      privateKey: process.env.FIREBASE_PRIVATE_KEY,
    }),
  }),
});
```

---

## ⚫ Phase 7: 테스트 및 배포 (2주)

### 7.1 E2E 테스트

**Playwright 테스트 시나리오**:
```typescript
// e2e/checkout.spec.ts
test.describe('Checkout Flow', () => {
  test('should complete purchase with Kakao Pay', async ({ page }) => {
    await page.goto('/parts/gpu');
    await page.click('[data-testid="listing-card"]');
    await page.click('[data-testid="add-to-cart"]');
    await page.goto('/cart');
    await page.click('[data-testid="checkout-button"]');
    // ... 결제 플로우 테스트
  });
});
```

### 7.2 성능 테스트

**Lighthouse 목표**:
| 메트릭 | 목표 |
|--------|------|
| Performance | 90+ |
| Accessibility | 95+ |
| Best Practices | 95+ |
| SEO | 100 |

**Core Web Vitals**:
| 메트릭 | 목표 |
|--------|------|
| LCP (Largest Contentful Paint) | < 2.5s |
| FID (First Input Delay) | < 100ms |
| CLS (Cumulative Layout Shift) | < 0.1 |

### 7.3 배포 파이프라인

#### Flutter 모바일
```yaml
# .github/workflows/mobile-release.yml
name: Mobile Release
on:
  push:
    tags:
      - 'v*'
jobs:
  build-android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter build appbundle --release
      - uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.GOOGLE_PLAY_SA }}
          packageName: com.picom.partshop
          releaseFiles: build/app/outputs/bundle/release/*.aab
          track: internal
```

#### Next.js 웹
```yaml
# .github/workflows/web-deploy.yml
name: Web Deploy
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: amondnet/vercel-action@v25
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
          vercel-args: '--prod'
```

---

## 📅 전체 일정 요약

```
┌──────────────────────────────────────────────────────────────────┐
│ Phase   │ 작업                        │ 기간     │ 우선순위     │
├─────────┼─────────────────────────────┼──────────┼──────────────┤
│ 0       │ 긴급 수정 (Critical 버그)    │ 1-2일    │ 🔴 즉시     │
│ 1       │ Google Play 정책 준수        │ 1주      │ 🔴 최우선   │
│ 1.5     │ 백엔드 & Admin 강화 ⭐ NEW   │ 2주      │ 🔶 높음     │
│ 2       │ 앱 리브랜딩                 │ 3-5일    │ 🟠 높음     │
│ 3       │ 코드 품질 강화              │ 1주      │ 🟡 중간     │
│ 4       │ 공유 패키지 추출            │ 2주      │ 🟢 중간     │
│ 5       │ Flutter 앱 최적화           │ 2주      │ 🔵 중간     │
│ 6       │ JS 웹앱 개발                │ 4-6주    │ 🟣 낮음     │
│ 7       │ 테스트 및 배포              │ 2주      │ ⚫ 최종     │
└─────────┴─────────────────────────────┴──────────┴──────────────┘

총 예상 기간: 14-16주 (약 3.5-4개월)
```

---

## ✅ 체크리스트

### Phase 0-1 완료 기준 (Play Store 재출시 가능)
- [ ] Critical 버그 3개 수정 완료
- [ ] 보안 이슈 (API 키) 수정 완료
- [ ] 데이터 안전 섹션 작성 완료
- [ ] 개인정보처리방침 업데이트 완료
- [ ] 동의 UI 구현 완료
- [ ] 계정 삭제 기능 구현 완료

### Phase 1.5 완료 기준 (백엔드 & Admin 강화) ⭐ NEW
- [ ] 송장 시스템 구현
  - [ ] pdfkit 의존성 추가
  - [ ] invoice_generator.ts 구현
  - [ ] 자동 생성 트리거 연동
  - [ ] Admin에서 재발행 기능
- [ ] Admin 주문/배송 통합 관리
  - [ ] order_detail_management_page.dart 구현
  - [ ] 일괄 처리 기능 (대량 송장 발행)
  - [ ] 엑셀 내보내기
- [ ] 매출/정산 리포트
  - [ ] revenue_dashboard_page.dart 구현
  - [ ] 일별/주별/월별 매출 차트
  - [ ] 판매자별 정산 리포트
- [ ] 고급 검색/필터
  - [ ] advanced_search_widget.dart 구현
  - [ ] Firestore 복합 인덱스 추가
  - [ ] 기간별/상태별/금액별 필터

### Phase 2 완료 기준 (새 앱 출시)
- [ ] 패키지명 변경 완료
- [ ] 앱 아이콘/스플래시 변경 완료
- [ ] Firebase 앱 재등록 완료
- [ ] 스토어 메타데이터 준비 완료
- [ ] 테스트 빌드 Play Console 업로드

### Phase 3-5 완료 기준 (앱 분리)
- [ ] 공유 패키지 추출 완료
- [ ] Flutter 앱 웹 코드 제거 완료
- [ ] 모바일 최적화 완료
- [ ] 테스트 커버리지 60%+

### Phase 6-7 완료 기준 (웹 런칭)
- [ ] Next.js 웹앱 MVP 완료
- [ ] E2E 테스트 통과
- [ ] Lighthouse 점수 90+
- [ ] 프로덕션 배포 완료

---

## 📞 참고 자료

### Google Play 정책
- [데이터 안전 섹션 가이드](https://support.google.com/googleplay/android-developer/answer/10787469)
- [개인정보처리방침 요구사항](https://support.google.com/googleplay/android-developer/answer/9859455)
- [계정 삭제 요구사항](https://support.google.com/googleplay/android-developer/answer/13327111)

### 기술 문서
- [Flutter Melos](https://melos.invertase.dev/)
- [Next.js 15 Docs](https://nextjs.org/docs)
- [Firebase Admin SDK](https://firebase.google.com/docs/admin/setup)
- [shadcn/ui](https://ui.shadcn.com/)

---

*이 문서는 Alfred (MoAI-ADK)에 의해 생성되었습니다.*
*최종 수정: 2026-01-22*
