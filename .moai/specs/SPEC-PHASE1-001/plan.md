# SPEC-PHASE1-001: Implementation Plan (구현 계획)

---

## TAG BLOCK

```yaml
spec_id: SPEC-PHASE1-001
document_type: plan
related_spec: SPEC-PHASE1-001/spec.md
created: 2026-01-23T00:00:00+09:00
```

---

## 1. Overview (개요)

### 1.1 목표

Phase 1 Backend Stabilization의 목표는 PiCom 백엔드의 안정성과 성능을 향상시키는 것입니다.

**핵심 성과 지표:**
- 결제 트랜잭션 실패율: 0.1% 미만
- 스케줄러 처리 시간: 30초 이내
- API 응답 시간: 500ms 이내 (P95)
- 에러 감지 시간: 5분 이내

### 1.2 범위

**포함:**
- 결제 트랜잭션 연동
- 스케줄러 배치 처리 최적화
- Rate Limiting 구현
- DragonBalls 쿼리 최적화
- Base_parts 캐싱
- 감사 로그 시스템
- 에러 모니터링 시스템

**제외:**
- Flutter 클라이언트 변경
- UI/UX 변경
- 새로운 기능 추가

---

## 2. Milestones (마일스톤)

### M1: 핵심 플로우 안정화 (Primary Goal)

**기간:** Week 1 (5일)

| 작업 | 예상 난이도 | 의존성 |
|------|------------|--------|
| 결제 트랜잭션 연동 | Medium | SPEC-PHASE0-001 완료 |
| 결제 취소 트랜잭션 연동 | Medium | 결제 트랜잭션 연동 |
| 스케줄러 배치 limit 추가 | Low | 없음 |
| Rate Limiting 구현 | Low | 없음 |
| 통합 테스트 | Medium | 모든 작업 완료 |

**완료 조건:**
- 결제 승인/취소가 트랜잭션으로 처리됨
- 모든 스케줄러에 배치 limit 적용됨
- Rate Limiting이 결제 엔드포인트에 적용됨

---

### M2: 성능 최적화 (Secondary Goal)

**기간:** Week 2 Day 1-3

| 작업 | 예상 난이도 | 의존성 |
|------|------------|--------|
| DragonBalls collectionGroup 분석 | Low | 없음 |
| DragonBalls 쿼리 최적화 | High | 분석 완료 |
| Base_parts 캐싱 구현 | Medium | 없음 |

**완료 조건:**
- collectionGroup 쿼리 제거 또는 최적화
- base_parts 캐싱 동작 확인

---

### M3: 모니터링 시스템 (Tertiary Goal)

**기간:** Week 2 Day 4-5

| 작업 | 예상 난이도 | 의존성 |
|------|------------|--------|
| 감사 로그 시스템 구현 | Medium | 없음 |
| 에러 로깅 시스템 구현 | Medium | 없음 |
| Firestore 인덱스 배포 | Low | 로깅 시스템 완료 |

**완료 조건:**
- auditLogs 컬렉션 생성 및 로깅 동작
- errorLogs 컬렉션 생성 및 로깅 동작
- 필요한 Firestore 인덱스 배포

---

### M4: 테스트 및 배포 (Final Goal)

**기간:** Week 2 종료 후 또는 병렬 진행

| 작업 | 예상 난이도 | 의존성 |
|------|------------|--------|
| Staging 환경 테스트 | Medium | M1-M3 완료 |
| 성능 테스트 | Medium | Staging 테스트 완료 |
| Production 배포 | Low | 모든 테스트 통과 |

**완료 조건:**
- Staging 환경에서 모든 기능 검증
- 성능 지표 목표 달성
- Production 배포 완료

---

## 3. Technical Approach (기술적 접근)

### 3.1 결제 트랜잭션 연동

**현재 상태:**
- `payment_transaction.ts`에 `processPaymentWithTransaction()` 함수 존재
- `/payment/approve`, `/toss-payment/confirm` 엔드포인트에서 미사용

**구현 방향:**
1. 결제 승인 엔드포인트에서 `processPaymentWithTransaction()` 호출
2. 실패 시 결제 취소 API 호출 및 에러 로깅
3. 성공 시 감사 로그 기록

**코드 변경 위치:**
```typescript
// functions/src/index.ts - /payment/approve 엔드포인트
// 기존: Firestore에 개별 업데이트
// 변경: processPaymentWithTransaction() 호출
```

### 3.2 스케줄러 배치 처리

**현재 상태:**
- `storage_scheduler.ts`: `.collection("dragonBalls").where(...).get()` - limit 없음
- `settlement_scheduler.ts`: `.collection("orders").where(...).get()` - limit 없음
- `approval_deadline_scheduler.ts`: `.collection("refundRequests").where(...).get()` - limit 없음

**구현 방향:**
1. 모든 스케줄러 쿼리에 `.limit(100)` 추가
2. 처리된 문서 수 로깅
3. 남은 문서가 있으면 다음 실행에서 처리

**배치 처리 패턴:**
```typescript
const BATCH_SIZE = 100;

const snapshot = await db
  .collection("orders")
  .where("status", "==", "delivered")
  .limit(BATCH_SIZE)
  .get();

console.log(`처리 대상: ${snapshot.size}개 (배치 크기: ${BATCH_SIZE})`);
```

### 3.3 Rate Limiting 구현

**라이브러리:** express-rate-limit

**구현 방향:**
1. `rate_limiter.ts` 미들웨어 생성
2. 결제 관련 라우트에 적용
3. 429 응답 시 재시도 시간 안내

**적용 방법:**
```typescript
// functions/src/index.ts
import { paymentRateLimiter } from './middleware/rate_limiter';

app.use('/payment', paymentRateLimiter);
app.use('/toss-payment', paymentRateLimiter);
```

### 3.4 DragonBalls 쿼리 최적화

**현재 상태:**
- `index.ts`에서 `collectionGroup("dragonBalls")` 사용
- `storage_scheduler.ts`에서는 이미 `.collection("dragonBalls")` 사용 (일관성 없음)

**옵션 분석:**
1. **Option A: 루트 컬렉션 마이그레이션** - 장기적으로 최적, 마이그레이션 필요
2. **Option B: collectionGroup 인덱스 최적화** - 단기 해결책
3. **Option C: 하이브리드 접근** - 기존 유지하면서 신규는 루트 사용

**권장:** Option C (하이브리드)
- 기존 collectionGroup 쿼리 유지 (호환성)
- 신규 DragonBall은 루트 컬렉션에도 저장
- 점진적 마이그레이션 계획 수립

### 3.5 Base_parts 캐싱

**캐싱 전략:**
- 인메모리 캐싱 (Cloud Functions 인스턴스 수준)
- TTL: 1시간
- 캐시 키: basePartId 또는 category

**구현 패턴:**
```typescript
// functions/src/cache/base_parts_cache.ts
const cache = new Map<string, { data: any; expiresAt: number }>();
const CACHE_TTL = 60 * 60 * 1000; // 1시간

export async function getCachedBasePart(basePartId: string): Promise<any> {
  const cached = cache.get(basePartId);
  if (cached && cached.expiresAt > Date.now()) {
    return cached.data;
  }

  const doc = await db.collection("base_parts").doc(basePartId).get();
  const data = doc.data();

  cache.set(basePartId, { data, expiresAt: Date.now() + CACHE_TTL });
  return data;
}
```

### 3.6 감사 로그 시스템

**로깅 대상 이벤트:**
| 이벤트 | Action 값 | 세부 정보 |
|--------|-----------|-----------|
| 결제 승인 | PAYMENT_APPROVED | orderId, amount, paymentMethod |
| 결제 취소 | PAYMENT_CANCELLED | orderId, cancelReason |
| 환불 신청 | REFUND_REQUESTED | orderId, refundId, reason |
| 환불 승인 | REFUND_APPROVED | refundId, approvedBy |
| 관리자 승인 | ADMIN_APPROVED | targetId, adminId |

### 3.7 에러 모니터링 시스템

**에러 심각도 분류:**
| 심각도 | 설명 | 예시 |
|--------|------|------|
| critical | 서비스 중단 | 결제 API 장애 |
| high | 핵심 기능 장애 | 트랜잭션 실패 |
| medium | 부분 기능 장애 | 스케줄러 오류 |
| low | 경미한 오류 | 로깅 실패 |

---

## 4. Architecture Design (아키텍처 설계)

### 4.1 결제 플로우 (수정 후)

```
┌─────────────┐     ┌─────────────┐     ┌─────────────────────┐
│   Client    │────>│  /payment/  │────>│ processPaymentWith  │
│ (Flutter)   │     │   approve   │     │    Transaction()    │
└─────────────┘     └─────────────┘     └─────────────────────┘
                           │                      │
                           │                      ▼
                    ┌──────▼──────┐     ┌─────────────────────┐
                    │    Rate     │     │  Firestore 트랜잭션  │
                    │   Limiter   │     │ - orders 업데이트    │
                    └─────────────┘     │ - listings 업데이트  │
                                        └─────────────────────┘
                                                  │
                           ┌──────────────────────┼──────────────────────┐
                           │                      │                      │
                           ▼                      ▼                      ▼
                    ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
                    │  auditLogs  │     │   Success   │     │ errorLogs   │
                    │   기록      │     │   Response  │     │  (실패시)   │
                    └─────────────┘     └─────────────┘     └─────────────┘
```

### 4.2 캐싱 레이어

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Request   │────>│  In-Memory  │────>│  Firestore  │
│             │     │    Cache    │     │             │
└─────────────┘     └─────────────┘     └─────────────┘
                           │                   │
                    ┌──────▼──────┐            │
                    │  캐시 히트?  │            │
                    └─────────────┘            │
                     Yes │   No │              │
                         │     └───────────────┘
                         ▼
                    ┌─────────────┐
                    │   Response  │
                    └─────────────┘
```

---

## 5. Dependencies (의존성)

### 5.1 외부 의존성

| 패키지 | 버전 | 용도 |
|--------|------|------|
| express-rate-limit | ^7.1.5 | Rate Limiting |

### 5.2 내부 의존성

| 모듈 | 의존 대상 |
|------|-----------|
| rate_limiter.ts | index.ts (Express app) |
| base_parts_cache.ts | index.ts, searchParts |
| audit_logger.ts | index.ts, payment endpoints |
| error_logger.ts | 모든 try-catch 블록 |

### 5.3 SPEC 의존성

- **SPEC-PHASE0-001**: 전역 인프라 (AppLogger, Result, Failures) - COMPLETED
  - AppLogger: 로깅에 활용
  - Admin Config: 관리자 확인에 활용

---

## 6. Risk Mitigation (위험 완화)

### 6.1 DragonBalls 마이그레이션 위험

**위험:** 기존 앱과의 호환성 문제

**완화 전략:**
1. 하이브리드 접근: 기존 구조 유지하면서 신규 데이터는 루트에도 저장
2. 마이그레이션 스크립트 별도 작성
3. 앱 업데이트 후 마이그레이션 완료

### 6.2 Rate Limiting 사용자 불편

**위험:** 정상 사용자가 제한에 걸림

**완화 전략:**
1. 초기 임계값을 관대하게 설정 (분당 10회)
2. 모니터링 후 점진적 조정
3. 429 응답에 재시도 시간 명시

### 6.3 캐시 일관성 문제

**위험:** 캐시된 데이터와 실제 데이터 불일치

**완화 전략:**
1. TTL을 적절히 설정 (1시간)
2. 데이터 변경 시 캐시 무효화 로직 추가
3. 중요 데이터는 캐시 우회 옵션 제공

---

## 7. Testing Strategy (테스트 전략)

### 7.1 단위 테스트

| 대상 | 테스트 항목 |
|------|-------------|
| rate_limiter.ts | 요청 제한 동작, 429 응답 |
| base_parts_cache.ts | 캐시 저장/조회, TTL 만료 |
| audit_logger.ts | 로그 저장, 필드 검증 |
| error_logger.ts | 에러 저장, 심각도 분류 |

### 7.2 통합 테스트

| 시나리오 | 검증 항목 |
|----------|-----------|
| 결제 승인 성공 | 트랜잭션 완료, 주문/상품 상태 변경 |
| 결제 승인 실패 | 롤백 동작, 에러 로깅 |
| Rate Limit 초과 | 429 응답, 재시도 시간 |
| 스케줄러 배치 처리 | limit 적용, 로깅 |

### 7.3 성능 테스트

| 메트릭 | 목표 |
|--------|------|
| 결제 API 응답 시간 | < 1초 (P95) |
| 캐시 히트율 | > 80% |
| 스케줄러 실행 시간 | < 30초 |

---

## 8. Deployment Plan (배포 계획)

### 8.1 배포 순서

1. **Firestore 인덱스 배포** (선행)
   ```bash
   firebase deploy --only firestore:indexes
   ```

2. **Functions 배포**
   ```bash
   firebase deploy --only functions
   ```

3. **환경 변수 설정** (필요시)
   ```bash
   firebase functions:config:set rate_limit.max_requests=5
   ```

### 8.2 롤백 계획

- 문제 발생 시 이전 버전으로 롤백
- Cloud Functions 버전 히스토리 활용
- Firestore 인덱스는 롤백 불필요 (추가만 수행)

---

*이 문서는 SPEC-PHASE1-001의 구현 계획입니다.*
*작성일: 2026-01-23*
