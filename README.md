# PiCom - 중고 PC 부품 거래 플랫폼

PiCom은 중고 PC 부품의 안전한 거래를 위한 모바일 플랫폼입니다. QR 기반 AS 보증 시스템, PDF 보증서 자동 생성, 토스페이먼츠 결제 연동 등을 통해 신뢰할 수 있는 중고 부품 거래 환경을 제공합니다.

**Version:** 2.0.0+9

---

## 기술 스택

### 프론트엔드 (모바일 앱)

| 분류 | 기술 | 설명 |
|------|------|------|
| 프레임워크 | Flutter (Dart ^3.8.1) | 크로스 플랫폼 모바일 앱 |
| 상태관리 | flutter_riverpod | 반응형 상태 관리 |
| 라우팅 | go_router | 선언적 네비게이션 |
| 인증 | firebase_auth, google_sign_in, kakao_flutter_sdk | 소셜 로그인 |
| 결제 | tosspayments_widget_sdk_flutter | 토스페이먼츠 결제 위젯 |
| UI | google_fonts, material_symbols_icons, cached_network_image | UI 컴포넌트 |
| 차트 | fl_chart | 시세 차트 시각화 |
| 네트워크 | dio | HTTP 클라이언트 |
| 유틸리티 | excel, share_plus, path_provider | 데이터 내보내기 |

### 백엔드 (Cloud Functions)

| 분류 | 기술 | 설명 |
|------|------|------|
| 런타임 | Firebase Cloud Functions (TypeScript) | 서버리스 백엔드 |
| 데이터베이스 | Cloud Firestore | NoSQL 문서 데이터베이스 |
| 스토리지 | Firebase Storage | 파일 저장소 |
| 인증 | Firebase Auth | 사용자 인증 |
| 보안 | Firebase App Check | 앱 무결성 검증 |

---

## 프로젝트 구조

```
pi_com/
├── lib/
│   ├── main.dart                    # 앱 진입점
│   ├── app.dart                     # 앱 설정
│   ├── core/                        # 공통 상수, 모델
│   ├── shared/                      # 공유 위젯, 프로바이더
│   └── features/                    # 기능별 모듈 (Clean Architecture)
│       ├── admin/                   # 관리자 대시보드
│       ├── auth/                    # 인증 (Google, Kakao)
│       ├── cart/                    # 장바구니
│       ├── dragon_ball/             # 보관 배송 서비스
│       ├── home/                    # 홈 화면
│       ├── listing/                 # 상품 목록
│       ├── my_page/                 # 마이페이지
│       ├── notification/            # 알림
│       ├── address/                 # 주소 관리
│       ├── parts_price/             # 부품 시세 조회
│       ├── payment/                 # 결제 처리
│       ├── price_alert/             # 가격 알림
│       ├── sell_request/            # 판매 요청
│       ├── warranty/                # QR 보증 시스템
│       └── web_public/              # 웹 공개 페이지
├── functions/
│   └── src/                         # Firebase Cloud Functions (TypeScript)
│       ├── index.ts                 # 함수 진입점
│       ├── warranty/                # QR 기반 AS 보증 시스템
│       ├── invoice/                 # PDF 보증서 생성
│       ├── payment/                 # 결제 트랜잭션
│       ├── refund/                  # 환불 처리
│       ├── schedulers/              # 백그라운드 스케줄러
│       ├── cache/                   # 데이터 캐싱
│       ├── logging/                 # 감사 및 에러 로깅
│       ├── middleware/              # Rate Limiting
│       ├── admin/                   # 관리자 일괄 작업
│       ├── dragonballs/             # 보관 배송 서비스
│       └── __tests__/               # 테스트 코드
└── assets/
    ├── html/                        # 약관, 개인정보처리방침
    ├── data/                        # JSON 데이터 파일
    ├── photos/                      # 앱 아이콘
    └── images/                      # 이미지 리소스
```

각 feature 모듈은 Clean Architecture 패턴(data / domain / presentation)을 따릅니다.

---

## 시작하기

### 사전 요구사항

- Flutter SDK (Dart ^3.8.1)
- Node.js 18+ (Cloud Functions 개발용)
- Firebase CLI
- Android Studio 또는 VS Code
- Firebase 프로젝트 설정 완료

### 설치

```bash
# 저장소 클론
git clone <repository-url>
cd pi_com

# Flutter 의존성 설치
flutter pub get

# 환경 변수 설정
cp .env.example .env
# .env 파일에 Firebase, Kakao, Toss 키 설정

# Cloud Functions 의존성 설치
cd functions
npm install
cd ..
```

### 실행

```bash
# 앱 실행 (디버그 모드)
flutter run

# Cloud Functions 로컬 실행
cd functions
npm run serve

# Cloud Functions 배포
firebase deploy --only functions

# 테스트 실행 (Cloud Functions)
cd functions
npm test
```

---

## 주요 기능

### 중고 PC 부품 거래

- 부품 카테고리별 상품 목록 및 검색
- 장바구니 및 구매 프로세스
- 판매 요청 및 관리자 승인 워크플로우
- 부품 시세 조회 및 가격 추이 차트 (CPU, GPU, 메인보드)
- 가격 알림 설정

### QR 기반 AS 보증 시스템

- QR 코드 생성 및 보증 등록
- 보증 점수 산출 시스템
- 보증 이력 조회 및 관리
- 보증 검증 트랜잭션 처리

### PDF 보증서 자동 생성

- 거래 완료 시 보증서 자동 생성
- Cloud Functions 기반 PDF 렌더링
- 보증서 다운로드 및 공유

### 결제 시스템

- 토스페이먼츠 위젯 SDK 연동
- 결제 준비, 승인, 취소 처리
- 카카오페이 환불 지원
- 결제 트랜잭션 안전 처리

### 보관 배송 서비스 (드래곤볼)

- 부품 보관 및 일괄 배송 관리
- 보관 기한 관리 및 만료 알림
- 일괄 배송 생성 및 추적

### 관리자 기능

- 판매 요청 승인/거절
- 사용자 알림 발송
- 일괄 작업 처리
- 대시보드 통계

---

## 개발 이력

| 단계 | SPEC ID | 설명 | 상태 |
|------|---------|------|------|
| Phase 0 | SPEC-PHASE0-001 | 전역 인프라 구축 및 Critical 버그 수정 | 완료 |
| Phase 1 | SPEC-PHASE1-001 | Backend Stabilization (Cloud Functions 안정화) | 완료 |
| Phase 2 | SPEC-PHASE2-001 | QR 기반 AS 보증 시스템 + Play Store 정책 준수 | 진행중 |

---

## 라이선스

이 프로젝트는 비공개 프로젝트입니다.
