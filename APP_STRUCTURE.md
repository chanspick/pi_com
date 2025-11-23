# 📱 PiCom 앱 구조 및 기능 현황

**최종 업데이트**: 2025-11-12
**현재 버전**: 1.0.3+4
**작성자**: Claude Code

---

## 📊 프로젝트 개요

- **앱 이름**: PiCom (파이컴퓨터)
- **패키지명**: app.picom.team.pi_com
- **플랫폼**: Flutter (Web + Mobile)
- **백엔드**: Firebase (Firestore, Auth, Storage, Functions)
- **결제**: 카카오페이 (KakaoPay)
- **목적**: 중고 PC 부품 거래 플랫폼

---

## 🏗️ 아키텍처

### Clean Architecture 기반
```
lib/
├── app.dart                    # 앱 진입점 (Web/Mobile 분기)
├── main.dart                   # Main 함수
├── core/                       # 공통 핵심 기능
│   ├── constants/              # 상수 정의
│   ├── data/                   # 공통 데이터 소스
│   ├── models/                 # 공통 모델
│   ├── providers/              # 전역 Provider
│   ├── repositories/           # 공통 Repository
│   ├── router/                 # 라우팅 (Navigator)
│   └── utils/                  # 유틸리티 함수
├── features/                   # 기능별 모듈 (19개)
│   ├── {feature}/
│   │   ├── data/              # 데이터 레이어
│   │   │   ├── datasources/   # Remote/Local 데이터 소스
│   │   │   ├── models/        # 데이터 모델
│   │   │   └── repositories/  # Repository 구현
│   │   ├── domain/            # 도메인 레이어
│   │   │   ├── entities/      # 엔티티
│   │   │   ├── repositories/  # Repository 인터페이스
│   │   │   ├── services/      # 비즈니스 서비스
│   │   │   └── usecases/      # UseCase
│   │   └── presentation/      # 프레젠테이션 레이어
│   │       ├── providers/     # Riverpod 상태 관리
│   │       ├── screens/       # 화면
│   │       └── widgets/       # 위젯
└── shared/                    # 공유 컴포넌트
    └── widgets/               # 공통 위젯
```

---

## 🎯 Feature 목록 (19개)

### ✅ 1. address (주소 관리)
**상태**: 작동 중
**주요 기능**:
- 다음 우편번호 API 연동
- 배송지 주소 입력 및 관리

**주요 파일**:
- `presentation/screens/address_form_screen.dart`
- `data/datasources/address_remote_datasource.dart`

---

### ✅ 2. admin (관리자)
**상태**: 작동 중
**주요 기능**:
- 관리자 대시보드
- 사용자 관리
- 매물(Listing) 관리
- 판매 요청 승인/거부
- 통계 대시보드
- 배송 관리

**주요 화면**:
- `/admin` - 관리자 로그인
- `/admin/dashboard` - 대시보드
- `/admin/users` - 사용자 목록
- `/admin/listings` - 매물 목록
- `/admin/sell-requests` - 판매 요청 목록
- `/admin/statistics` - 통계
- `/admin/shipping` - 배송 관리

**주요 파일**:
- `presentation/screens/admin_dashboard.dart`
- `presentation/screens/user_list_page.dart`
- `presentation/screens/listing_list_page.dart`
- `data/datasources/admin_datasource.dart`
- `domain/usecases/reject_sell_request.dart`
- `domain/usecases/send_notification_to_user.dart`

---

### ✅ 3. auth (인증)
**상태**: 작동 중
**주요 기능**:
- Google 로그인
- 익명 로그인
- Firebase Authentication
- 사용자 정보 관리

**주요 파일**:
- `presentation/screens/auth_screen.dart`
- `data/datasources/google_auth_datasource.dart`
- `data/datasources/firestore_user_datasource.dart`
- `domain/usecases/sign_in_with_google.dart`
- `domain/usecases/sign_out.dart`

---

### ✅ 4. cart (장바구니)
**상태**: 작동 중
**주요 기능**:
- 장바구니 상품 추가/제거
- 수량 변경
- 구매 검증 (재고 확인)

**주요 파일**:
- `presentation/screens/cart_screen.dart`
- `data/datasources/cart_remote_datasource.dart`
- `domain/usecases/add_to_cart.dart`
- `domain/usecases/remove_from_cart.dart`
- `domain/usecases/validate_purchase.dart`

---

### ⚠️ 5. checkout (결제)
**상태**: 작동 중 (긴급 수정 필요)
**주요 기능**:
- 카카오페이 결제 준비/승인/취소
- 주문 생성
- 드래곤볼 지급

**⚠️ 알려진 문제** (PRE_LAUNCH_CHECKLIST.md 참고):
- 결제-주문 불일치 위험 (에러 처리 미흡)
- 중복 결제 방지 미흡
- 타임아웃 설정 부재

**주요 파일**:
- `presentation/screens/checkout_screen.dart`
- `domain/usecases/purchase_usecase.dart`

**긴급 수정 필요 항목**:
1. 결제 승인 후 주문 생성 실패 시 롤백 로직 추가
2. UUID 기반 orderId 사용 (중복 방지)
3. Dio 타임아웃 설정 추가

---

### ✅ 6. dragon_ball (드래곤볼 - 부품 보관)
**상태**: 작동 중
**주요 기능**:
- 구매한 부품 무료 보관 (최대 30일)
- 보관 중 부품 목록 조회
- 일괄 배송 요청
- 보관료 계산

**주요 화면**:
- `pc_storage_screen.dart` - 보관 중인 부품 목록
- `batch_shipment_request_screen.dart` - 일괄 배송 요청

**주요 파일**:
- `data/datasources/dragon_ball_remote_datasource.dart`
- `domain/entities/dragon_ball_entity.dart`
- `domain/usecases/create_dragon_ball_usecase.dart`

**정책** (core/constants/storage_policy.dart):
- 기본 무료 보관: 30일
- 경고 시작: 만료 5일 전
- 긴급 경고: 만료 2일 전
- 보관료: 31일부터 하루 500원

---

### ✅ 7. home (홈 화면)
**상태**: 작동 중
**주요 기능**:
- 홈 배너
- 상품 목록 (최신 등록 순)
- 카테고리 원형 메뉴
- 빠른 액세스 버튼

**주요 파일**:
- `presentation/widgets/home_banner.dart`
- `presentation/widgets/circle_menu_section.dart`
- `presentation/widgets/product_list_section.dart`

---

### ✅ 8. listing (매물)
**상태**: 작동 중
**주요 기능**:
- 중고 부품 매물 등록
- 매물 상세 조회
- 매물 목록 (필터/정렬)
- 이미지 캐로셀
- 가격 정보
- BasePart 연동

**주요 화면**:
- `part_shop_screen.dart` - 부품 스토어
- `listing_detail_screen.dart` - 매물 상세
- `listings_by_base_part_screen.dart` - BasePart별 매물

**주요 파일**:
- `data/datasources/listing_remote_datasource.dart`
- `data/models/listing_model.dart`
- `domain/entities/listing_entity.dart`
- `domain/usecases/get_listings_usecase.dart`

---

### ✅ 9. my_page (마이페이지)
**상태**: 작동 중
**주요 기능**:
- 프로필 조회/수정
- 구매 내역
- 판매 내역
- 판매 요청 내역
- 즐겨찾기 (찜한 상품)
- 설정

**주요 화면**:
- `my_page_screen.dart` - 마이페이지 메인
- `profile_edit_screen.dart` - 프로필 수정
- `purchase_history_screen.dart` - 구매 내역
- `sales_history_screen.dart` - 판매 내역
- `sell_request_history_screen.dart` - 판매 요청 내역
- `favorites_screen.dart` - 찜한 상품
- `settings_screen.dart` - 설정

**주요 파일**:
- `data/repositories/favorites_repository.dart`
- `presentation/providers/favorites_provider.dart`

---

### ✅ 10. notification (알림)
**상태**: 작동 중
**주요 기능**:
- 실시간 알림 수신
- 알림 목록 조회
- 읽음 처리
- 알림 삭제
- 안 읽은 알림 개수 표시

**주요 파일**:
- `presentations/screens/notification_list_screen.dart`
- `data/datasources/notification_datasource.dart`
- `domain/usecases/get_notifications_stream.dart`
- `domain/usecases/mark_as_read.dart`

**Firestore 인덱스**:
- `userId` + `createdAt` (DESC)

---

### ✅ 11. order (주문)
**상태**: 작동 중
**주요 기능**:
- 주문 생성
- 주문 상태 조회
- 주문 내역 관리

**주요 파일**:
- `data/datasources/order_remote_datasource.dart`
- `data/repositories/order_repository_impl.dart`
- `domain/repositories/order_repository.dart`

---

### ✅ 12. parts_price (부품 가격 정보)
**상태**: 작동 중
**주요 기능**:
- BasePart (부품 기본 정보) 조회
- 카테고리별 부품 목록
- 부품 검색
- 가격 히스토리 조회
- 상세 스펙 표시 (CPU, GPU, 메인보드 등)

**주요 화면**:
- `part_category_screen.dart` - 카테고리별 부품
- `price_history_screen.dart` - 가격 히스토리
- `base_part_search_screen.dart` - 부품 검색

**주요 파일**:
- `data/models/base_part_model.dart`
- `data/models/part_model.dart`
- `domain/entities/base_part_entity.dart`
- `domain/usecases/get_base_parts_by_category_usecase.dart`
- `domain/usecases/search_base_parts_usecase.dart`

**주요 위젯**:
- `cpu_details_widget.dart` - CPU 상세 정보
- `gpu_details_widget.dart` - GPU 상세 정보
- `mainboard_details_widget.dart` - 메인보드 상세 정보

---

### ⚠️ 13. payment (결제 서비스)
**상태**: 작동 중 (개선 필요)
**주요 기능**:
- 카카오페이 API 연동
- 결제 준비 (Payment Ready)
- 결제 승인 (Payment Approve)
- 결제 취소 (Payment Cancel)

**⚠️ 알려진 문제**:
- 타임아웃 설정 없음 (무한 대기 위험)
- 에러 메시지가 기술적 (사용자 친화적 메시지 필요)

**주요 파일**:
- `data/datasources/payment_remote_datasource_impl.dart`
- `presentation/providers/payment_provider.dart`

**Firebase Functions**:
- `functions/src/index.ts` - 카카오페이 프록시 API

---

### ✅ 14. price_alert (가격 알림)
**상태**: 작동 중
**주요 기능**:
- 목표 가격 설정
- 가격 알림 목록 조회
- 가격 도달 시 알림 발송
- 알림 배지 표시

**주요 화면**:
- `price_alerts_screen.dart` - 가격 알림 목록
- `price_alert_setup_dialog.dart` - 알림 설정

**주요 파일**:
- `data/repositories/price_alert_repository.dart`
- `presentation/providers/price_alert_provider.dart`
- `presentation/widgets/price_alert_badge_icon.dart`

---

### ✅ 15. price_history (가격 히스토리)
**상태**: 작동 중
**주요 기능**:
- 부품별 가격 변동 추적
- 차트 시각화 (fl_chart)
- 통계 데이터 제공

**주요 파일**:
- `data/repositories/price_history_repository.dart`
- `presentation/widgets/price_history_chart.dart`

---

### ✅ 16. recommendation (PC 추천 시스템)
**상태**: 작동 중
**주요 기능**:
- 사용 목적별 PC 구성 추천
- 호환성 검증 (CPU-메인보드, PSU 용량 등)
- 예산 기반 추천
- 견적서 저장

**주요 화면**:
- `my_estimate_screen.dart` - 나의 견적서
- `pc_assembly_screen.dart` - PC 조립 추천

**주요 파일**:
- `data/models/estimate_sample_model.dart`
- `data/models/spec_profile_model.dart`
- `domain/entities/pc_build_entity.dart`
- `domain/entities/recommendation_criteria_entity.dart`
- `domain/services/ml_recommendation_service.dart`
- `domain/services/recommendation_engine_service.dart`
- `domain/usecases/get_compatible_parts_usecase.dart`
- `domain/usecases/get_recommendation_usecase.dart`

**데이터**:
- `assets/data/estimate_full.json` - 샘플 견적 데이터

---

### ✅ 17. sell_request (판매 요청)
**상태**: 작동 중
**주요 기능**:
- 부품 판매 요청 등록
- 완제품 PC 판매 요청
- 부품 검색 (자동완성)
- 이미지 업로드
- 관리자 승인 대기

**주요 화면**:
- `sell_request_screen.dart` - 부품 판매 요청
- `finished_pc_sell_screen.dart` - 완제품 PC 판매
- `part_search_screen.dart` - 부품 검색
- `sell_request_details_screen.dart` - 판매 요청 상세

**주요 파일**:
- `data/datasources/sell_request_datasource.dart`
- `data/repositories/sell_request_repository_impl.dart`
- `presentation/providers/sell_request_provider.dart`

---

### ✅ 18. web_public (웹 공개 페이지)
**상태**: 작동 중 (웹 전용)
**주요 기능**:
- 랜딩 페이지
- 소개 페이지
- 이용약관
- 개인정보 처리방침

**주요 화면** (GoRouter):
- `/` - 랜딩 페이지
- `/about` - 소개
- `/terms` - 이용약관
- `/privacy` - 개인정보 처리방침

**주요 파일**:
- `presentation/screens/landing_page.dart`
- `presentation/screens/about_page.dart`
- `presentation/screens/terms_page.dart`
- `presentation/screens/privacy_page.dart`

---

## 🔧 Scripts (데이터 관리)

### 주요 스크립트 (scripts 폴더)
```
scripts/
├── README.md                           # 스크립트 사용 가이드
├── package.json                        # Node.js 의존성
├── serviceAccountKey.json             # Firebase Admin SDK 키 (비공개)
│
├── upload_excel_to_firestore.js       # 엑셀 → Firestore 업로드
├── upload_excel_listings.js           # Listings 일괄 업로드
├── upload_images_to_storage.js        # 이미지 Firebase Storage 업로드
│
├── add_ram_ssd_firebase.js            # RAM/SSD 데이터 추가
├── add_case_cooler_psu_parts.js       # 케이스/쿨러/PSU 추가
├── add_missing_cpu_base_parts.js      # CPU 추가
├── add_missing_gpu_mainboard.js       # GPU/메인보드 추가
├── add_popular_psu.js                 # PSU 추가
│
├── inspect_data_structure.js          # 데이터 구조 검사
├── test_listing_connection.js         # Listing-BasePart 연결 테스트
├── test_condition_score.js            # 컨디션 점수 테스트
│
├── check_categories.js                # 카테고리 확인
├── check_listings_count.js            # Listings 개수 확인
├── check_base_parts_duplicates.js     # BasePart 중복 확인
├── delete_base_parts_no_listings.js   # 연결 안된 BasePart 삭제
│
├── backup_listings.js                 # Listings 백업
├── clean_for_fresh_start.js           # 데이터 초기화
├── reupload_listings.js               # Listings 재업로드
│
└── analyze_*.js                       # 각종 분석 스크립트
```

### 주요 데이터 파일 (datas/)
```
datas/
├── CPU.xlsx                           # CPU 데이터
├── GPU.xlsx                           # GPU 데이터
├── Mainboard.xlsx                     # 메인보드 데이터
├── images/                            # 부품 이미지
└── *.py                               # 데이터 생성 스크립트 (Python)
```

---

## 🗄️ Firebase 구조

### Firestore Collections

#### 1. users
- **용도**: 사용자 정보
- **보안**: 본인만 읽기/쓰기, 관리자 전체 읽기

#### 2. base_parts
- **용도**: 부품 기본 정보 (모델명, 스펙, 평균 가격)
- **보안**: 모두 읽기, 관리자만 쓰기
- **인덱스**:
  - `category` + `brand`
  - `modelName` (검색용)

#### 3. parts (현재 미사용)
- **용도**: 개별 부품 인스턴스
- **참고**: 현재는 base_parts만 사용 중

#### 4. listings
- **용도**: 중고 부품 매물
- **보안**: 모두 읽기, 본인만 쓰기, 관리자 전체 관리
- **인덱스**:
  - `status` + `createdAt` (DESC)
  - `status` + `basePartId` + `price`
  - `sellerId` + `status`

#### 5. orders
- **용도**: 주문 정보
- **보안**: 본인만 읽기, 시스템이 생성, 삭제 불가
- **인덱스**:
  - `userId` + `createdAt` (DESC)
  - `orderId` (고유)

#### 6. payments
- **용도**: 결제 정보
- **보안**: 본인만 읽기, 시스템이 생성, 삭제 불가 (감사 로그)
- **인덱스**:
  - `userId` + `createdAt` (DESC)
  - `orderId` (주문 연결)

#### 7. dragonBalls
- **용도**: 보관 중인 부품 (드래곤볼)
- **보안**: 본인만 읽기/쓰기, 관리자 전체 읽기
- **인덱스**:
  - `userId` + `status`
  - `status` + `expiresAt` (만료 관리)

#### 8. sellRequests
- **용도**: 판매 요청
- **보안**: 본인만 읽기/쓰기, 관리자 전체 관리
- **인덱스**:
  - `status` + `createdAt` (DESC)
  - `userId` + `status`

#### 9. notifications
- **용도**: 사용자 알림
- **보안**: 본인만 읽기/쓰기, 관리자 전송 가능
- **인덱스**:
  - `userId` + `createdAt` (DESC)
  - `userId` + `isRead`

#### 10. favorites
- **용도**: 찜한 상품
- **보안**: 본인만 읽기/쓰기

#### 11. priceAlerts
- **용도**: 가격 알림 설정
- **보안**: 본인만 읽기/쓰기

#### 12. priceHistory
- **용도**: 부품 가격 변동 기록
- **보안**: 모두 읽기, 시스템만 쓰기
- **인덱스**:
  - `basePartId` + `date` (DESC)

---

### Firebase Storage 구조
```
storage/
├── users/{userId}/
│   └── profile.jpg              # 프로필 사진
├── listings/{listingId}/
│   ├── image1.jpg               # 매물 사진 1
│   ├── image2.jpg               # 매물 사진 2
│   └── ...
├── sellRequests/{requestId}/
│   ├── image1.jpg               # 판매 요청 사진
│   └── ...
└── base_parts/{basePartId}/
    └── thumbnail.jpg            # 부품 썸네일
```

---

### Firebase Functions
```
functions/src/index.ts
├── paymentReady                 # 카카오페이 결제 준비
├── paymentApprove               # 카카오페이 결제 승인
├── paymentCancel                # 카카오페이 결제 취소
└── (추가 예정)
    ├── checkExpiredDragonBalls  # 만료된 드래곤볼 자동 처리
    ├── sendPriceAlerts          # 가격 알림 자동 발송
    └── updateBasePartStats      # BasePart 통계 자동 업데이트
```

---

## 🔒 보안 설정

### Firestore Security Rules
- **파일**: `firestore.rules`
- **상태**: 프로덕션 전환 완료 (v1.0.3)
- **주요 규칙**:
  - 사용자는 본인 데이터만 접근
  - 관리자는 `isAdmin` 함수로 구분 (users 컬렉션의 role 필드)
  - 결제/주문 정보는 삭제 불가 (감사 로그 보존)
  - 민감 정보는 읽기 전용

**상세 내용**: `SECURITY_GUIDE.md` 참고

---

### ProGuard (코드 난독화)
- **파일**: `android/app/proguard-rules.pro`
- **상태**: 활성화됨 (v1.0.3)
- **규칙**:
  - Firebase 클래스 보존
  - Flutter 플러그인 보존
  - WebView 보존
  - Kakao SDK 보존

---

## 📝 알려진 문제 및 개선 사항

### 🚨 긴급 수정 필요
1. **결제-주문 트랜잭션 보장** (checkout_screen.dart:443)
   - 결제 승인 후 주문 생성 실패 시 롤백 로직 없음
   - 해결: try-catch + 결제 취소 로직 추가

2. **중복 결제 방지** (checkout_screen.dart:394)
   - 타임스탬프 기반 orderId → UUID로 변경 필요

3. **타임아웃 설정** (payment_remote_datasource_impl.dart)
   - Dio 요청에 타임아웃 없음
   - 해결: Options에 connectTimeout, receiveTimeout 추가

4. **Order 생성 에러 처리** (order_remote_datasource_impl.dart:19)
   - try-catch 없음
   - 해결: FirebaseException 처리 추가

**상세 내용**: `PRE_LAUNCH_CHECKLIST.md` 참고

---

### ⚠️ 개선 권장
1. **사용자 친화적 에러 메시지**
   - 기술적 에러 메시지 → 일반 사용자용 메시지 변환

2. **Firebase Crashlytics 도입**
   - 프로덕션 에러 추적 및 분석

3. **드래곤볼 생성 실패 복구**
   - 결제 완료 후 드래곤볼 생성 실패 시 복구 로직

4. **print() 제거**
   - 프로덕션 코드에서 print() 사용 중 (46개)
   - Flutter의 debugPrint() 또는 로깅 라이브러리 사용

---

## 📦 배포 상태

### 현재 버전: 1.0.3 (Build 4)
- **상태**: 프로덕션 배포 준비 중
- **타겟 SDK**: 36 (Android 15)
- **빌드 설정**:
  - ProGuard 난독화: ✅ 활성화
  - 서명: ✅ Release Keystore 설정 필요
  - Firestore Rules: ✅ 프로덕션 전환 완료
  - Firebase Functions: ✅ 카카오페이 연동 완료

**배포 가이드**: `PLAYSTORE_GUIDE.md` 참고
**버전 히스토리**: `VERSION_HISTORY.md` 참고

---

## 🔗 관련 문서

- **[SECURITY_GUIDE.md](SECURITY_GUIDE.md)** - 보안 설정 가이드
- **[VERSION_HISTORY.md](VERSION_HISTORY.md)** - 버전 히스토리
- **[PLAYSTORE_GUIDE.md](PLAYSTORE_GUIDE.md)** - Play Store 배포 가이드
- **[PRE_LAUNCH_CHECKLIST.md](PRE_LAUNCH_CHECKLIST.md)** - 출시 전 체크리스트
- **[scripts/README.md](scripts/README.md)** - 데이터 관리 스크립트 가이드

---

## 📞 개발팀 연락처

- **팀 이름**: PiCom Team
- **프로젝트 저장소**: (비공개)
- **이슈 트래킹**: GitHub Issues
- **문의**: 앱 내 고객센터

---

## 📅 다음 업데이트 계획

### v1.0.4 (긴급 수정)
- [ ] 결제-주문 트랜잭션 보장
- [ ] UUID 기반 orderId
- [ ] Dio 타임아웃 설정
- [ ] Order 생성 에러 처리

### v1.1.0 (기능 개선)
- [ ] Firebase Crashlytics 도입
- [ ] 사용자 친화적 에러 메시지
- [ ] 드래곤볼 만료 자동 처리 (Cloud Function)
- [ ] 가격 알림 자동 발송 (Cloud Function)
- [ ] BasePart 통계 자동 업데이트

### v2.0.0 (대규모 업데이트)
- [ ] ML 기반 추천 시스템 고도화
- [ ] 실시간 채팅 기능
- [ ] 경매 시스템
- [ ] 부품 렌탈 서비스 (드래곤볼 활용)

---

**최종 작성자**: Claude Code
**최종 업데이트**: 2025-11-12
**다음 리뷰 예정일**: 긴급 수정 후 재검토
