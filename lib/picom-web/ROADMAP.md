# PiCom Web 마이그레이션 로드맵

> Flutter/Firebase → Next.js/Supabase 웹 마이그레이션
> 디자인: picom-design-system.jsx 기준

## 기술 스택

- **Framework**: Next.js 16.2.1 (App Router, Turbopack)
- **UI**: Tailwind CSS v4 + shadcn/ui v4 (base-ui/react)
- **DB**: Supabase (PostgreSQL, RLS, Realtime)
- **Data Fetching**: TanStack Query v5
- **Chart**: Recharts v3.8
- **Auth**: Supabase Auth (@supabase/ssr)
- **Forms**: React Hook Form + Zod v4
- **State**: Zustand v5
- **디자인**: picom-design-system.jsx 기준

## 디자인 시스템 (picom-design-system.jsx)

### 컬러
- **Primary**: Blue #3B82F6(500) ~ #2563EB(600), 900/800은 헤더·텍스트, 50~200은 배경·호버
- **Success**: #059669 (검증 완료/정상)
- **Warning**: #D97706 (검증 중/주의)
- **Error**: #DC2626 (불량/에러)
- **Gray**: Slate 계열 50~900

### 타이포그래피
- **Font**: Pretendard Variable (한글 최적화) + JetBrains Mono (코드)
- **Scale**: H1(28/800) → H2(22/700) → H3(17/600) → Body Large(15/500) → Body(14/400) → Caption(13/500) → Overline(11/600)

### 핵심 컴포넌트 패턴
- **버튼 위계**: Primary(gradient) → Secondary(outline) → Ghost(border) → Danger(error)
- **배지 시스템**: verified(녹색) / warning(주황) / error(빨강) / primary(파랑) / default(회색)
- **Product Card**: 이미지 영역(검증 배지 오버레이 + 찜 버튼) → 카테고리/배송 배지 → 제목 → 브랜드·사용기간 → 가격·등록시간
- **Verification Result Card**: 검증 통과 헤더 → 스펙 key-value 리스트 (GPU 모델, VRAM, 벤치점수, 온도, 팬 상태)
- **Input**: border 1.5px, rounded 8px, 포커스 시 primary ring

### 공간 & 형태
- **Spacing**: 4, 8, 12, 16, 20, 24, 32, 40, 48
- **Border Radius**: sm(6) / md(8) / default(10) / lg(12) / xl(16)
- **Shadow**: sm → md → lg (미니멀)

### 핵심 UX 원칙
> "검증(Verification)"이 PiCom의 핵심 차별점. 모든 매물에 검증 상태를 즉시 보여주는 것이 최우선.

## 제외 범위

다음 기능은 현재 마이그레이션 범위에서 **보류**:
- 드래곤볼 (부품 보관 서비스)
- 일괄배송 (batch_shipments)
- PC 조립 추천 / 견적 시스템
- 위탁판매 (consignment)

---

## 완료된 작업

### Phase 0: 기반 인프라 ✅

- [x] Supabase 스키마 설계 (18개 테이블, 11개 ENUM)
- [x] 마이그레이션 SQL (00001~00018)
- [x] RLS 정책 + 인덱스
- [x] DB 트리거 (listing 변경 시 base_parts 자동 업데이트)
- [x] Flutter <-> Supabase 스키마 갭 분석 및 정합 (00018)
- [x] TypeScript 타입 시스템 (database.types.ts - 18테이블 + ENUM)
- [x] Supabase 클라이언트 설정 (server/client/admin)
- [x] 공통 쿼리 함수 (queries.ts)
- [x] 유틸리티 (utils.ts - formatPrice, formatRelativeTime, categoryLabels 등)
- [x] 디자인 토큰 + 글로벌 CSS (picom-design-system.jsx CSS 변수 적용)
- [x] shadcn/ui 컴포넌트 (Badge, Button, Card, Input, Select, Separator, Sheet, Skeleton, Slider, Tabs, Avatar, DropdownMenu)
- [x] 레이아웃 (Navbar + Footer + ThemeToggle)
- [x] TanStack Query Provider + Theme Provider
- [x] Supabase Auth 미들웨어 + 로그인/회원가입 페이지
- [x] use-auth 훅

**디자인 보강 필요** (기존 구현에 디자인 시스템 정합):
- [ ] globals.css에 디자인 시스템 CSS 변수 완전 적용 (semantic colors, shadow 토큰)
- [ ] Badge 컴포넌트에 검증 상태 variant 추가 (verified/warning/error)
- [ ] Button 컴포넌트에 gradient primary, danger variant 추가
- [ ] Product Card 컴포넌트를 디자인 시스템 패턴으로 통일 (검증 배지 오버레이, 찜 버튼)

### Phase 1: 공개 페이지 + 시세 통합 ✅

- [x] 매물 목록 페이지 (/listings) - 필터/정렬/무한스크롤
- [x] 매물 상세 페이지 (/listings/[id]) - 이미지갤러리, 상태표시, 사양
- [x] 부품 시세 목록 (/parts) - 카테고리별 BasePart 그리드
- [x] 통합 검색 (/search) - 부품+매물 동시 검색
- [x] 각 페이지 SSR metadata 적용
- [x] BasePart 상세 페이지 리디자인 (/parts/[partId])
  - 최저가 강조, 가격 추이 차트 (7/30/90일)
  - 스펙 한글화, active 매물 인라인 목록
- [x] use-listings-by-part, fetchPriceHistoryExtended

---

## 예정된 작업

### Phase 2: 인증 강화 + 법적 페이지 ✅

> 마이페이지 전 필수 선행. 약관 동의 없이 서비스 이용 불가.

#### 2-1: 카카오 로그인
- [x] Supabase Auth 카카오 OAuth 프로바이더 설정
- [x] 로그인 페이지에 카카오 버튼 추가
- [x] 콜백 처리 (/callback)
- [x] 멀티 프로바이더 계정 연동 (Google + Kakao 동일 이메일)

#### 2-2: 이메일/비밀번호 로그인
- [x] Supabase Auth 이메일 회원가입 (displayName + email + password)
- [x] Supabase Auth 이메일 로그인
- [x] 로그인/회원가입 페이지에 이메일 폼 추가 (React Hook Form + Zod 검증)
- [x] 비밀번호 6자 이상 제한, 유효성 검사
- [x] 비밀번호 재설정 플로우 (Supabase resetPasswordForEmail)

#### 2-3: 법적 페이지
- [x] 이용약관 (/terms)
- [x] 개인정보처리방침 (/privacy)
- [x] 환불 정책 (/refund-policy)
- [x] Footer에 링크 추가

#### 2-4: 약관 동의 플로우
- [x] 회원가입 시 필수/선택 약관 동의 UI
- [x] 동의 내역 profiles 테이블에 저장
- [x] 미동의 시 서비스 접근 제한

#### 2-5: 이미지 업로드 유틸
- [x] Supabase Storage 버킷 설정 (sell-images, profile-avatars)
- [x] 이미지 업로드 유틸 함수 (압축/리사이즈/다중 업로드)
- [x] 업로드 프로그레스 UI 컴포넌트
- [x] 이미지 삭제 함수

#### 2-6: 미들웨어 경로 정리
- [x] middleware.ts 보호 경로를 ROADMAP 라우트 구조에 맞춰 업데이트
- [x] 미구현 보호 경로 접근 시 "준비 중" 안내 또는 홈으로 리디렉트

---

### Phase 3: 마이페이지 + 사용자 기능 ✅

> 로그인 사용자의 개인화 기능. 모든 /my 경로의 기반.

#### 3-1: 마이페이지 대시보드 (/my)
- [x] 프로필 카드 (아바타, 닉네임, 이메일, 가입 프로바이더) — Card 컴포넌트 + Avatar
- [x] 메뉴 네비게이션 (즐겨찾기, 장바구니, 주문내역, 판매내역, 알림, 설정)
- [x] Protected route (미로그인 시 리디렉트)

#### 3-2: 프로필 수정 (/my/profile/edit)
- [x] 닉네임, 아바타 변경
- [x] use-profile 훅 (fetchProfile, updateProfile)

#### 3-3: 배송지 관리 (/my/addresses)
- [x] 배송지 목록/추가/수정/삭제
- [x] 기본 배송지 설정
- [x] 다음 우편번호 검색 API 연동
- [x] use-addresses 훅

#### 3-4: 즐겨찾기 (/my/favorites)
- [x] 즐겨찾기 목록 UI (Product Card 그리드 — 검증 배지 + 찜 하트)
- [x] 즐겨찾기 토글 버튼 (listing 상세에서 하트 아이콘, 디자인 시스템 32px 원형 버튼)
- [x] use-favorites 훅 + Optimistic update
- [x] 빈 상태 UI

#### 3-5: 장바구니 (/my/cart)
- [x] 장바구니 목록 UI (이미지 + 제목 + 가격 + 삭제)
- [x] 총 결제금액 계산 섹션
- [x] 장바구니 추가 버튼 (listing 상세에서)
- [x] use-cart 훅 (fetchCartItems, addToCart, removeFromCart)
- [x] 결제 진행 버튼 → Phase 5로 연결

#### 3-6: 회원탈퇴 (/my/account/delete)
- [x] 탈퇴 사유 입력
- [x] account_deletions 테이블 insert
- [x] 30일 대기 후 삭제 안내

---

### Phase 4: 판매 신청 플로우 ✅

> 사용자가 중고 부품을 판매 등록하는 플로우. 이미지 업로드(Phase 2-4) 필수.

#### 4-1: 판매 신청 작성 (/sell/new)
- [x] 다단계 폼 (카테고리 → 부품정보 → 사진/설명 → 가격/상태)
- [x] 카테고리별 BasePart 검색 및 선택 (Select + Input 디자인 시스템 적용)
- [x] 이미지 업로드 (최대 5장, Supabase Storage)
- [x] 상태 점수 선택 UI (1~10 슬라이더)
- [x] 중고여부 / 보증여부 / 보증잔여기간 입력
- [x] 미리보기 화면 (Product Card 형태로 실제 등록될 모습 프리뷰)
- [x] sell_requests 테이블 insert

#### 4-2: 판매 신청 목록 (/my/sell-requests)
- [x] 내 판매신청 목록 (상태: 대기중/테스트중/승인/반려/판매완료/취소)
- [x] 상태별 필터 (Badge variant로 상태 표시: verified=승인, warning=대기/테스트, error=반려)
- [x] 관리자 메모 표시 (admin_note)
- [x] use-sell-requests 훅

#### 4-3: 검증 결과 페이지 (/listings/[id]/verification)
- [x] verification_results 테이블 타입 추가 (database.types.ts)
- [x] Verification Result Card 구현 (디자인 시스템 패턴)
- [x] 검증 항목 리스트 (GPU 모델, VRAM, 벤치점수, 온도, 팬 상태 등)
- [x] 검증 통과/미통과 헤더 (success/error 시맨틱 컬러)
- [x] 등급별 보증기간 표시 (S=24개월, A=18, B=12, C=6, D=3)

#### 4-4: 매물 직접 등록 (/sell/direct)
- [x] 판매 신청 없이 바로 매물 등록 (검증된 사용자만)
- [x] listings 테이블 직접 insert (status: active)
- [x] 등록 후 매물 상세로 리디렉트

---

### Phase 5: 구매/결제 플로우 ✅

> Toss Payments 연동. 배송지 관리(Phase 3-3) 필수 선행.

#### 5-1: 결제 페이지 (/checkout)
- [x] 주문 요약 (상품명, 가격, 배송비)
- [x] 배송지 선택 (Phase 3-3에서 구현한 주소록 연동)
- [x] 주문/결제 레코드 생성 (orders + toss_payments)
- [x] Toss Payments SDK 연동 위치 준비 (TODO placeholder)
- [x] 결제 성공/실패 콜백 (/checkout/success, /checkout/fail)

#### 5-2: 결제 후 처리
- [x] 주문 상태 업데이트 (confirmed)
- [x] 매물 상태 변경 (active → reserved)
- [x] 장바구니에서 자동 제거
- [ ] 판매자 알림 생성 (Phase 7에서 구현)

#### 5-3: 주문내역 (/my/orders)
- [x] 구매 주문 목록 (상태별 필터: 전체/진행중/배송중/완료/취소환불)
- [x] 주문 상세 (/my/orders/[orderId])
- [x] use-orders 훅 (fetchOrders, fetchOrderById, cancelOrder)
- [x] 주문 상태 라벨 한글화

#### 5-4: 판매내역 (/my/sales)
- [x] 내 판매 매물 목록 (상태별: 판매중/예약중/판매완료)
- [x] 매물 수정/삭제 기능
- [x] 판매 통계 요약 (총 판매액, 진행중 건수)
- [x] use-my-listings 훅

---

### Phase 6: 환불 + 정산 ✅

> 거래 후 프로세스. 결제(Phase 5) 완료 후 구현.

#### 6-1: 환불 시스템
- [x] 환불 요청 페이지 (/my/orders/[orderId]/refund)
- [x] 환불 사유 입력
- [x] refunds 테이블 CRUD + use-refunds 훅
- [x] 주문 상세에서 환불 요청 버튼 연결
- [ ] Toss Payments 환불 API 연동 (실제 결제 연동 시 구현)

#### 6-2: 정산 시스템
- [x] 판매자 정산 내역 (/my/settlements)
- [x] 정산 상태별 필터 (pending/processing/completed)
- [x] 정산 상세 (판매액, 수수료, 순수익)
- [x] use-settlements 훅

---

### Phase 7: 알림 시스템 ✅

> 실시간 알림 + 가격 알림. 주문/결제 흐름(Phase 5) 이후.

#### 7-1: 알림 센터 (/my/notifications)
- [x] 알림 목록 UI (타입별 아이콘: 주문/가격/시스템)
- [x] 읽음/안읽음 표시 + 전체 읽음 처리
- [x] 알림 클릭 시 관련 페이지로 이동
- [x] use-notifications 훅 (fetch, markAsRead, markAllRead, unreadCount 30초 폴링)

#### 7-2: 실시간 알림 (Supabase Realtime)
- [ ] notifications 테이블 Realtime 구독 (추후)
- [ ] 새 알림 시 토스트 UI (추후)

#### 7-3: 가격 알림
- [x] use-price-alerts 훅 (create, list, toggle, delete)
- [x] price_alerts 테이블 CRUD
- [x] 알림 관리 페이지 (/my/alerts)
- [ ] BasePart 상세에서 "가격 알림 설정" 버튼 (추후 연결)

#### 7-4: 가격 체크 백그라운드 (Edge Function)
- [ ] Supabase Edge Function: 주기적 가격 체크 (추후)
- [ ] 목표가 도달 시 notifications에 알림 생성 (추후)

---

### Phase 8: 홈 리디자인 + SEO ✅

> 실제 데이터 기반 홈. 매물/주문 데이터 축적 후 의미 있음.

#### 8-1: 홈 페이지 리디자인 (/)
- [x] 히어로 섹션 — gradient primary 900→700, π 로고, CTA 버튼
- [x] 카테고리 바로가기 그리드 (8개 카테고리, 아이콘)
- [x] 인기 매물 (view_count 상위 6개, SSR)
- [x] 최근 등록 매물 (최신 6개, SSR)

#### 8-2: SEO 강화
- [x] sitemap.xml 자동 생성 (src/app/sitemap.ts)
- [x] robots.txt (src/app/robots.ts)
- [x] 루트 layout 메타데이터 강화 (OG, Twitter Card, keywords)
- [ ] 동적 OG 이미지 생성 (추후)
- [ ] 구조화 데이터 JSON-LD (추후)

---

### Phase 9: 관리자 대시보드 ✅

> 운영 도구. 서비스 운영 시작 시 필요.

#### 9-1: 관리자 대시보드 (/admin)
- [x] 대시보드 통계 (오늘 매출, 신규주문, 판매신청 대기, 활성 매물)
- [x] is_admin 기반 접근 제어 (레이아웃에서 체크)
- [x] 사이드바 + 모바일 햄버거 메뉴

#### 9-2: 매물/주문 관리
- [x] 판매 신청 심사 (/admin/sell-requests) - 승인/반려/테스트 + admin_note
- [x] 주문 관리 (/admin/orders) - 배송상태 업데이트, tracking_number 입력
- [x] 매물 관리 placeholder (/admin/listings)

#### 9-3: 환불/정산 관리
- [x] 환불 관리 placeholder (/admin/refunds)

#### 9-4: 보증서 시스템
- [x] 보증서 조회 (/admin/invoices) - 목록 테이블
- [ ] QR코드 기반 보증 확인 (추후)
- [ ] PDF 보증서 다운로드 (추후)

---

## 스키마 보강 필요 사항

### 주문 상태 Enum 확장
Flutter 앱의 13단계 주문 상태를 Supabase에 반영 필요:
```
현재: pending, confirmed, shipping, delivered, cancelled, refunded
추가 필요: processing, refund_requested, refund_approved, refund_rejected,
          item_returning, refund_inspecting, refund_completed
```

### 판매 신청 상태 Enum 확장
```
현재: pending, reviewing, approved, rejected, completed
추가 필요: testing, cancelled, sold
```

---

## 의존관계 맵

```
Phase 2 (인증/법적)
  └→ Phase 3 (마이페이지) - 약관 동의, 프로필 필수
      ├→ Phase 4 (판매 신청) - 이미지 업로드, 프로필 필수 [판매자 경로]
      │    └→ Phase 9 (관리자) - 판매 심사, 검증 데이터 입력
      └→ Phase 5 (구매/결제) - 배송지, 장바구니 필수 [구매자 경로]
           ├→ Phase 6 (환불/정산) - 주문 데이터 필수
           └→ Phase 7 (알림) - 주문/결제/가격 이벤트
                └→ Phase 8 (홈 리디자인) - 축적 데이터 필요
```

> Phase 4(판매)와 Phase 5(구매)는 **병렬 진행 가능**. 둘 다 Phase 3에만 의존.

---

### Phase 10: UX/UI 보정

> Phase 0~9 완료 후 UX 감사에서 발견된 엔트리 포인트 누락 및 기능 연결 이슈 수정.

#### 10-1: CRITICAL (기능 미연결)
- [x] Navbar 검색 Input → `/search` 페이지로 form submit 연결
- [x] Navbar 장바구니 링크 `/cart` → `/my/cart` 수정
- [x] 매물 상세 "장바구니에 담기" 버튼 → `useAddToCart` 훅 연결
- [x] 매물 상세 "찜" 버튼 → `useToggleFavorite` 훅 연결

#### 10-2: IMPORTANT (엔트리 포인트 누락)
- [x] 마이페이지 설정 허브 (`/my/settings`) 페이지 생성 — 가격 알림, 배송지 관리, 계정 삭제 진입점 포함
- [x] 계정 삭제 (`/my/account/delete`) 진입점 추가 — 설정 페이지 "위험 영역" 섹션
- [x] Navbar에 판매신청 (Send 아이콘) + 알림 (Bell 아이콘) 버튼 추가 (데스크톱/모바일)
- [x] 부품 시세 상세에서 "가격 알림 설정" 버튼 추가 — `useCreatePriceAlert` 훅 연결
- [x] 직접 판매 등록 (`/sell/direct`) 진입점 — 마이페이지 메뉴에 추가

#### 10-3: MINOR (편의 기능)
- [x] Footer `/about` 링크 404 수정 — 회사 소개 페이지 생성 (사업자 정보 포함)
- [x] 글로벌 404 페이지 (`not-found.tsx`) 생성 — PiCom 브랜딩 적용
- [x] Footer 연락처 실제 정보로 업데이트 (전화/이메일/운영시간)
- [x] Navbar 알림 아이콘 (Bell) 추가
- [x] Navbar 장바구니 아이콘에 수량 배지 표시 — `useCart` 훅 연결
- [x] 관리자 사용자용 Navbar `/admin` 바로가기 링크 — `profile.is_admin` 체크
- [x] 매물 카드 hover 시 퀵 액션 (찜, 장바구니) — 호버 오버레이 버튼 추가

#### 10-4: 법적 페이지 실제 약관 반영
- [x] `/terms` — (주)파이컴퓨터 서비스 이용약관 17조 (2025.12.01 시행)
- [x] `/privacy` — (주)파이컴퓨터 개인정보 처리방침 12조 (2025.12.01 시행)
- [x] `/refund-policy` — (주)파이컴퓨터 환불 및 반품 정책 12조 (2025.12.01 시행)

---

## DB 마이그레이션 상태

| 파일 | 설명 | 실행 시점 | 상태 |
|------|------|---------|------|
| 00001~00016 | 기본 스키마 + RLS + 인덱스 | 최초 셋업 | Supabase에서 실행 필요 |
| 00017 | lowest_price 칼럼 + DB 트리거 | 최초 셋업 | Supabase에서 실행 필요 |
| 00018 | Flutter 스키마 정합 | 최초 셋업 | Supabase에서 실행 필요 |
| 00019 | sell_request_status Enum 확장 (+testing, cancelled, sold) | **Phase 4 시작 전** | 작성 필요 |
| 00020 | order_status Enum 확장 (13단계) | **Phase 5 시작 전** | 작성 필요 |
| 00021 | verification_results 테이블 생성 | **Phase 4-3 시작 전** | 작성 필요 |

> Supabase Dashboard SQL Editor에서 순서대로 실행해야 합니다.

## 보증 시스템 아키텍처 (결정 필요)

현재 Flutter 앱의 보증(Warranty) 시스템은 Firebase Cloud Functions 기반:
- VerificationTransaction (검증 거래), Warranty (보증), ServiceRequest (AS 요청)
- QR 기반 보증 활성화, 등급별 보증기간 (S=24개월 ~ D=3개월)

**선택지:**
1. **Supabase로 완전 이관** — warranty 관련 테이블 추가 마이그레이션 작성 (Phase 9-4 시점)
2. **Firebase 유지** — 보증 시스템만 기존 Cloud Functions 사용, picom-web에서 API 호출
3. **하이브리드** — 검증 결과는 Supabase (verification_results), 보증/AS는 추후 결정

> Phase 4-3에서 verification_results를 Supabase에 만들므로 옵션 3(하이브리드)으로 우선 진행.
