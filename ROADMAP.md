# PiCom Web 마이그레이션 로드맵

> Flutter/Firebase → Next.js/Supabase 웹 마이그레이션

## 기술 스택

- **Framework**: Next.js 16.2.1 (App Router, Turbopack)
- **UI**: Tailwind CSS v4 + shadcn/ui v4 (base-ui/react)
- **DB**: Supabase (PostgreSQL, RLS, Realtime)
- **Data Fetching**: TanStack Query v5
- **Chart**: Recharts v3.8
- **Auth**: Supabase Auth (@supabase/ssr)
- **디자인**: Primary Blue #3B82F6/#2563EB, Pretendard 폰트, border-radius 10px

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
- [x] 디자인 토큰 + 글로벌 CSS
- [x] shadcn/ui 컴포넌트 (Badge, Button, Card, Input, Select, Separator, Sheet, Skeleton, Slider, Tabs, Avatar, DropdownMenu)
- [x] 레이아웃 (Navbar + Footer + ThemeToggle)
- [x] TanStack Query Provider + Theme Provider
- [x] Supabase Auth 미들웨어 + 로그인/회원가입 페이지
- [x] use-auth 훅

### Phase 0.5: 공개 페이지 (SEO + SSR) ✅

- [x] 매물 목록 페이지 (/listings) - 필터/정렬/무한스크롤
- [x] 매물 상세 페이지 (/listings/[id]) - 이미지갤러리, 상태표시, 사양
- [x] 부품 시세 목록 (/parts) - 카테고리별 BasePart 그리드
- [x] 통합 검색 (/search) - 부품+매물 동시 검색
- [x] 각 페이지 SSR metadata 적용

### Phase 1: 시세->매물 통합 페이지 ✅

- [x] BasePart 상세 페이지 리디자인 (/parts/[partId])
  - 최저가 강조 (primary 색상, 평균시세보다 상단)
  - 가격 추이 차트 (7/30/90일, 최저가 기준선)
  - 스펙 한글화 (specLabels 맵)
  - 해당 BasePart의 active 매물 인라인 목록
  - 정렬 기능 (최신순/낮은가격/높은가격)
- [x] use-listings-by-part 훅 (TanStack Query)
- [x] fetchListingsByBasePart 쿼리 함수
- [x] fetchPriceHistoryExtended (90일 확장)

---
## 예정된 작업

### Phase 2: 마이페이지 + 사용자 기능

> 로그인 사용자의 개인화 기능

#### 2-1: 즐겨찾기 페이지 (/my/favorites)
- [ ] 즐겨찾기 목록 UI (매물 카드 그리드)
- [ ] 즐겨찾기 토글 버튼 (listing 상세에서 하트 아이콘)
- [ ] use-favorites 훅 (fetchFavorites, toggleFavorite)
- [ ] Optimistic update (TanStack Query mutation)
- [ ] 빈 상태 UI

#### 2-2: 장바구니 페이지 (/my/cart)
- [ ] 장바구니 목록 UI (이미지 + 제목 + 가격 + 삭제)
- [ ] 총 결제금액 계산 섹션
- [ ] 장바구니 추가 버튼 (listing 상세에서)
- [ ] use-cart 훅 (fetchCartItems, addToCart, removeFromCart)
- [ ] 결제 진행 버튼 -> Phase 5 결제 플로우로 연결

#### 2-3: 마이페이지 대시보드 (/my)
- [ ] 프로필 카드 (아바타, 닉네임, 이메일)
- [ ] 프로필 수정 페이지 (/my/profile/edit)
- [ ] 메뉴 네비게이션 (즐겨찾기, 장바구니, 주문내역, 판매내역, 알림, 설정)
- [ ] use-profile 훅 (fetchProfile, updateProfile)
- [ ] Protected route (미로그인 시 리디렉트)

#### 2-4: 주문내역 페이지 (/my/orders)
- [ ] 구매 주문 목록 (상태별 필터: 전체/진행중/배송중/완료/취소)
- [ ] 주문 상세 페이지 (/my/orders/[orderId])
  - 주문 정보, 배송 정보, 결제 정보
  - 배송 추적 (tracking_number)
  - 환불 요청 버튼
- [ ] use-orders 훅 (fetchOrders, fetchOrderById)
- [ ] 주문 상태 라벨 한글화

#### 2-5: 판매내역 페이지 (/my/sales)
- [ ] 내 판매 매물 목록 (상태별: 판매중/예약중/판매완료)
- [ ] 매물 수정/삭제 기능
- [ ] 판매 통계 요약 (총 판매액, 진행중 건수)
- [ ] use-my-listings 훅

---
### Phase 3: 판매 신청 플로우

> 사용자가 중고 부품을 판매 등록하는 플로우

#### 3-1: 판매 신청 작성 (/sell/new)
- [ ] 다단계 폼 (Step 1: 카테고리 -> Step 2: 부품정보 -> Step 3: 사진/설명 -> Step 4: 가격/상태)
- [ ] 카테고리별 BasePart 검색 및 선택 (base_part_id 매칭)
- [ ] 이미지 업로드 (Supabase Storage, 최대 5장, 압축/리사이즈)
- [ ] 상태 점수 선택 UI (1~10 슬라이더)
- [ ] 중고여부 / 보증여부 / 보증잔여기간 입력
- [ ] 미리보기 화면
- [ ] Supabase sell_requests 테이블 insert

#### 3-2: 판매 신청 목록 (/my/sell-requests)
- [ ] 내 판매신청 목록 (상태: 대기중/심사중/승인/반려/완료)
- [ ] 상태별 필터
- [ ] 관리자 메모 표시 (admin_note)
- [ ] use-sell-requests 훅

#### 3-3: 매물 등록 직접 작성 (/sell/direct)
- [ ] 판매 신청 없이 바로 매물 등록 (검증된 사용자만)
- [ ] listings 테이블 직접 insert (status: active)
- [ ] 등록 후 매물 상세로 리디렉트

---

### Phase 4: 가격 알림 시스템

> 원하는 가격에 도달하면 알림

#### 4-1: 가격 알림 등록
- [ ] BasePart 상세에서 "가격 알림 설정" 버튼
- [ ] 목표 가격 입력 UI (Slider + Input)
- [ ] 현재가 대비 목표가 비율 표시
- [ ] use-price-alerts 훅 (create, list, toggle, delete)
- [ ] Supabase price_alerts 테이블 CRUD

#### 4-2: 알림 관리 페이지 (/my/alerts)
- [ ] 내 알림 목록 (활성/비활성 토글)
- [ ] 알림 삭제
- [ ] 알림 트리거 내역 (triggered_at, 당시 가격)

#### 4-3: 가격 체크 백그라운드 (Edge Function)
- [ ] Supabase Edge Function: 주기적 가격 체크
- [ ] 목표가 도달 시 notifications 테이블에 알림 생성
- [ ] 이메일/푸시 알림 발송 (추후)

---
### Phase 5: 구매/결제 플로우

> Toss Payments 연동 결제

#### 5-1: 배송지 관리
- [ ] 배송지 목록/추가/수정/삭제 (/my/addresses)
- [ ] 기본 배송지 설정
- [ ] 다음 우편번호 검색 API 연동
- [ ] use-addresses 훅

#### 5-2: 결제 페이지 (/checkout)
- [ ] 주문 요약 (상품명, 가격, 배송비)
- [ ] 배송지 선택/입력
- [ ] Toss Payments SDK 연동
  - orders 테이블 생성 (status: pending)
  - toss_payments 테이블 생성
  - 결제창 호출
- [ ] 결제 성공/실패 콜백 페이지 (/checkout/success, /checkout/fail)
- [ ] 결제 승인 API Route (서버사이드 Toss 결제 확인)

#### 5-3: 결제 후 처리
- [ ] 주문 상태 업데이트 (confirmed)
- [ ] 매물 상태 변경 (active -> sold/reserved)
- [ ] 판매자 알림 생성
- [ ] 장바구니에서 제거

---

### Phase 6: 알림 시스템

> 실시간 알림 + 알림 센터

#### 6-1: 알림 센터 페이지 (/my/notifications)
- [ ] 알림 목록 UI (타입별 아이콘: 주문/가격/시스템)
- [ ] 읽음/안읽음 표시 + 전체 읽음 처리
- [ ] 알림 클릭 시 관련 페이지로 이동 (related_order_id, related_listing_id 등)
- [ ] use-notifications 훅 (fetch, markAsRead, markAllRead)
- [ ] 알림 카운트 배지 (Navbar에 안읽음 수)

#### 6-2: 실시간 알림 (Supabase Realtime)
- [ ] notifications 테이블 Realtime 구독
- [ ] 새 알림 시 토스트 UI
- [ ] 브라우저 푸시 알림 (추후)

---
### Phase 7: 홈 화면 리디자인

> 램딩 페이지 -> 실제 데이터 기반 홈

#### 7-1: 홈 페이지 (/)
- [ ] 히어로 섹션 (중고 PC 부품 시세 플랫폼)
- [ ] 인기 매물 캐러셀 (view_count 상위)
- [ ] 카테고리 바로가기 그리드 (CPU/GPU/RAM/SSD/메보/파워/케이스/쿨러)
- [ ] 최근 가격 변동 TOP 5 (하락안/상승안)
- [ ] 최근 등록 매물

#### 7-2: SEO + OG 태그
- [ ] 동적 OG 이미지 생성 (Next.js ImageResponse)
- [ ] 구조화 데이터 (JSON-LD: Product, Offer)
- [ ] sitemap.xml 자동 생성
- [ ] robots.txt

---

### Phase 8: 환불/보관/정산

> 거래 후 프로세스

#### 8-1: 환불 시스템
- [ ] 환불 요청 페이지 (주문상세에서 접근)
- [ ] 환불 사유 입력
- [ ] refunds 테이블 CRUD
- [ ] 환불 상태 추적 (pending/approved/rejected/completed)
- [ ] Toss Payments 환불 API 연동

#### 8-2: 드래곤볼 (보관 시스템)
- [ ] 드래곤볼 대시보드 (/my/dragon-balls)
- [ ] 일반보관 / 렌탈보관 구분
- [ ] 보관료 누적 표시 (accumulated_fee)
- [ ] 위탁판매 전환 (consignment_converted_at)
- [ ] 일괄배송 신청 (/my/batch-shipment)
  - 보관중인 드래곤볼 선택
  - 배송지 입력 + 배송비 계산
  - batch_shipments 테이블 insert

#### 8-3: 정산 시스템
- [ ] 판매자 정산 내역 (/my/settlements)
- [ ] 정산 상태별 필터 (pending/processing/completed)
- [ ] 정산 상세 (판매액, 수수료, 순수익)
- [ ] settlements 테이블 조회

---
### Phase 9: 관리자 + 보증/법적

> 운영 도구 + 보증서 시스템

#### 9-1: 관리자 대시보드 (/admin)
- [ ] 매물 관리 (상태 변경, is_featured 토글)
- [ ] 판매 신청 심사 (approve/reject + admin_note)
- [ ] 주문 관리 (배송상태 업데이트, tracking_number 입력)
- [ ] 환불 관리 (approve/reject)
- [ ] 드래곤볼 관리 (보관 상태, 일괄배송 처리)
- [ ] 정산 관리 (정산 실행)
- [ ] 대시보드 통계 (오늘 매출, 신규주문, 신규판매신청)
- [ ] RLS: is_admin 기반 접근 제어

#### 9-2: 보증서 시스템
- [ ] 보증서 조회 (/my/invoices)
- [ ] QR코드 기반 보증 확인 페이지 (/warranty/[id])
- [ ] PDF 보증서 다운로드
- [ ] invoices 테이블 조회 + 리마인더

#### 9-3: 법적 페이지
- [ ] 이용약관 (/terms)
- [ ] 개인정보처리방침 (/privacy)
- [ ] 회원탈퇴 (/my/account/delete)
  - account_deletions 테이블 insert
  - 30일 대기 후 삭제 안내

---

## DB 마이그레이션 상태

| 파일 | 설명 | 상태 |
|------|------|------|
| 00001~00016 | 기본 스키마 + RLS + 인덱스 | Supabase에서 실행 필요 |
| 00017 | lowest_price 칼럼 + DB 트리거 | Supabase에서 실행 필요 |
| 00018 | Flutter 스키마 정합 (batch_shipments, refunds 등) | Supabase에서 실행 필요 |

> Supabase Dashboard SQL Editor에서 00001~00018을 순서대로 실행해야 합니다.
