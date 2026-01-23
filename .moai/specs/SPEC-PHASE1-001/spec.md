# SPEC-PHASE1-001: Phase 1 - Backend Stabilization

---

## TAG BLOCK

```yaml
spec_id: SPEC-PHASE1-001
title: Phase 1 - Backend Stabilization (백엔드 안정화)
created: 2026-01-23T00:00:00+09:00
completed: 2026-01-23T00:00:00+09:00
status: Completed
priority: High
lifecycle: spec-anchored
assigned: manager-tdd
related_specs: [SPEC-PHASE0-001]
epic: PiCom Play Store 재출시
labels: [backend, firebase, payment, scheduler, optimization, monitoring]
```

---

## 1. Environment (환경)

### 1.1 프로젝트 정보

| 항목 | 값 |
|------|-----|
| **프로젝트명** | PiCom - 중고 PC 부품 거래 플랫폼 |
| **프레임워크** | Firebase Cloud Functions (TypeScript) |
| **이전 SPEC** | SPEC-PHASE0-001 (전역 인프라 + Critical 수정) - COMPLETED |
| **현재 브랜치** | feature/SPEC-PHASE0-001-global-infra |
| **목표** | 결제/환불 플로우 안정화, 성능 최적화, 모니터링 구축 |

### 1.2 기술 스택

**Firebase Backend**
- Cloud Functions: TypeScript (firebase-functions v1)
- Firestore: 문서 데이터베이스
- 결제: KakaoPay, TossPayments API

**기존 인프라 (SPEC-PHASE0-001 완료)**
- AppLogger: 로깅 시스템 구축 완료
- Result 패턴: 성공/실패 처리 표준화
- Failure 타입: 에러 핸들링 표준화
- Admin Config: 환경변수 기반 관리자 UID 관리

### 1.3 현재 상태 분석

| 카테고리 | 문제점 | 영향 범위 |
|----------|--------|-----------|
| 결제 트랜잭션 | payment_transaction.ts 존재하나 실제 결제 플로우 미연동 | 결제 실패 시 데이터 불일치 가능 |
| 스케줄러 쿼리 | 배치 처리 limit 없음, 전체 조회 | 메모리 초과, 성능 저하 |
| Rate Limiting | 결제 엔드포인트 보호 없음 | DDoS/악용 취약 |
| DragonBalls 쿼리 | collectionGroup 사용 (비효율적) | 쿼리 비용 증가, 성능 저하 |
| 캐싱 | base_parts 캐싱 없음 | 반복 쿼리, 비용 증가 |
| 감사 로그 | auditLogs 컬렉션 없음 | 추적 불가 |
| 에러 모니터링 | errorLogs 컬렉션 없음 | 장애 감지 불가 |

---

## 2. Assumptions (가정)

### 2.1 기술적 가정

| 가정 | 신뢰도 | 근거 | 위험 |
|------|--------|------|------|
| Firestore 트랜잭션은 최대 500개 문서까지 지원 | High | Firebase 공식 문서 | 없음 |
| Cloud Functions 메모리 기본값 256MB로 충분 | Medium | 현재 운영 중 | 대용량 배치 시 문제 |
| express-rate-limit 패키지 사용 가능 | High | npm 공식 패키지 | 없음 |
| Firestore 캐싱은 인메모리로 구현 가능 | High | 일반적인 패턴 | 콜드 스타트 시 초기화 |

### 2.2 비즈니스 가정

| 가정 | 신뢰도 | 근거 | 위험 |
|------|--------|------|------|
| 결제 API 호출은 분당 5회 제한이 적절 | Medium | 일반적인 e-commerce 패턴 | 사용자 불편 가능 |
| 스케줄러 배치 크기 100개가 적절 | Medium | 메모리/성능 균형 | 처리량 부족 가능 |
| DragonBalls 컬렉션은 루트로 마이그레이션 가능 | Low | 데이터 구조 분석 필요 | 기존 앱 호환성 |

### 2.3 검증이 필요한 가정

- **DragonBalls 마이그레이션**: 현재 users/{uid}/dragonBalls 구조에서 루트 dragonBalls로 이전 시 클라이언트 호환성 확인 필요
- **캐시 TTL**: base_parts 1시간 캐시가 적절한지 비즈니스 확인 필요
- **Rate Limit 임계값**: 분당 5회가 실제 사용 패턴에 적합한지 모니터링 후 조정

---

## 3. Requirements (요구사항)

### 3.1 결제 트랜잭션 완성 (Week 1, Day 1-2)

#### REQ-PAY-001: 결제 플로우 트랜잭션 연동

**[Event-Driven]** **WHEN** 결제 승인이 성공하면 **THEN** processPaymentWithTransaction()을 호출하여 주문 상태와 상품 상태를 원자적으로 업데이트해야 한다.

**[Unwanted]** 시스템은 결제 승인 후 개별 문서를 순차적으로 업데이트**하지 않아야 한다**.

**[Event-Driven]** **WHEN** 트랜잭션이 실패하면 **THEN** 결제 취소 API를 호출하고 에러 로그를 기록해야 한다.

상세 스펙:
- 파일 위치: `functions/src/index.ts` (결제 승인 엔드포인트 수정)
- 연동 대상: `/payment/approve`, `/toss-payment/confirm` 엔드포인트
- 트랜잭션 포함: orders 업데이트, listings 상태 변경

#### REQ-PAY-002: 결제 취소 트랜잭션 연동

**[Event-Driven]** **WHEN** 결제 취소가 요청되면 **THEN** cancelPaymentWithTransaction()을 호출하여 주문과 상품 상태를 원자적으로 복원해야 한다.

**[State-Driven]** **IF** 주문 상태가 'paid' 또는 'confirmed'이면 **THEN** 취소 처리를 허용해야 한다.

**[Unwanted]** 시스템은 이미 'settled' 상태인 주문에 대해 취소 처리를**하지 않아야 한다**.

---

### 3.2 스케줄러 배치 처리 (Week 1, Day 3)

#### REQ-SCH-001: 스케줄러 쿼리 limit 추가

**[Ubiquitous]** 시스템은 **항상** 스케줄러 쿼리에 배치 크기 제한(limit)을 적용해야 한다.

**[State-Driven]** **IF** 처리할 문서가 배치 크기를 초과하면 **THEN** 다음 배치로 이월하여 처리해야 한다.

**[Unwanted]** 시스템은 제한 없이 전체 컬렉션을 조회**하지 않아야 한다**.

영향 파일:
- `functions/src/schedulers/storage_scheduler.ts`: 라인 24-27 (dragonBalls 쿼리)
- `functions/src/schedulers/settlement_scheduler.ts`: 라인 24-27 (orders 쿼리)
- `functions/src/refund/approval_deadline_scheduler.ts`: 라인 27-29 (refundRequests 쿼리)
- `functions/src/index.ts`: 라인 1466, 1508 (dragonBalls collectionGroup 쿼리)

배치 설정:
- 기본 배치 크기: 100
- 처리 로그: 처리된 문서 수, 남은 문서 수 기록

---

### 3.3 Rate Limiting 구현 (Week 1, Day 4)

#### REQ-RATE-001: 결제 API Rate Limiting

**[Ubiquitous]** 시스템은 **항상** 결제 관련 엔드포인트에 Rate Limiting을 적용해야 한다.

**[State-Driven]** **IF** 동일 IP에서 분당 5회 이상 결제 요청이 발생하면 **THEN** 429 Too Many Requests를 반환해야 한다.

**[Event-Driven]** **WHEN** Rate Limit이 초과되면 **THEN** 경고 로그를 기록하고 남은 대기 시간을 응답에 포함해야 한다.

영향 파일:
- `functions/src/index.ts`: Express 미들웨어 추가
- 신규 파일: `functions/src/middleware/rate_limiter.ts`

적용 대상:
- POST `/payment/prepare`
- POST `/payment/approve`
- POST `/payment/cancel`
- POST `/toss-payment/confirm`
- POST `/toss-payment/cancel`

---

### 3.4 DragonBalls 쿼리 최적화 (Week 2, Day 1-2)

#### REQ-OPT-001: CollectionGroup 쿼리 제거

**[Ubiquitous]** 시스템은 **항상** dragonBalls 데이터를 루트 컬렉션에서 조회해야 한다.

**[Unwanted]** 시스템은 collectionGroup("dragonBalls") 쿼리를 사용**하지 않아야 한다**.

마이그레이션 계획:
- 기존: `users/{uid}/dragonBalls/{dragonBallId}`
- 신규: `dragonBalls/{dragonBallId}` (userId 필드 포함)
- 마이그레이션 스크립트 필요
- 기존 쿼리 수정 필요

영향 파일:
- `functions/src/index.ts`: 라인 1466, 1508 (collectionGroup 사용 중)
- `functions/src/schedulers/storage_scheduler.ts`: 라인 24-25 (이미 루트 컬렉션 사용)

---

### 3.5 Base_parts 캐싱 구현 (Week 2, Day 3)

#### REQ-CACHE-001: 인메모리 캐싱 구현

**[Ubiquitous]** 시스템은 **항상** base_parts 조회 시 캐시를 우선 확인해야 한다.

**[State-Driven]** **IF** 캐시가 1시간 이내이면 **THEN** 캐시된 데이터를 반환해야 한다.

**[Event-Driven]** **WHEN** 캐시가 만료되거나 없으면 **THEN** Firestore에서 조회하고 캐시를 갱신해야 한다.

신규 파일:
- `functions/src/cache/base_parts_cache.ts`

캐시 설정:
- TTL: 1시간 (3600초)
- 키 패턴: `base_part:{basePartId}`
- 전체 캐시: `base_parts:list:{category}`

---

### 3.6 감사 로그 시스템 (Week 2, Day 4)

#### REQ-AUDIT-001: AuditLogs 컬렉션 생성

**[Event-Driven]** **WHEN** 중요 작업이 발생하면 **THEN** auditLogs 컬렉션에 로그를 기록해야 한다.

**[Ubiquitous]** 시스템은 **항상** 감사 로그에 timestamp, userId, action, details를 포함해야 한다.

중요 작업 목록:
- 결제 승인/취소
- 환불 신청/승인/거부
- 주문 상태 변경
- 관리자 승인/반려

신규 파일:
- `functions/src/audit/audit_logger.ts`

데이터 구조:
```typescript
interface AuditLog {
  id: string;
  timestamp: Timestamp;
  userId: string;
  action: string;
  targetCollection: string;
  targetId: string;
  details: Record<string, any>;
  ipAddress?: string;
}
```

---

### 3.7 에러 모니터링 시스템 (Week 2, Day 5)

#### REQ-ERROR-001: ErrorLogs 컬렉션 생성

**[Event-Driven]** **WHEN** 예외가 발생하면 **THEN** errorLogs 컬렉션에 에러를 기록해야 한다.

**[Ubiquitous]** 시스템은 **항상** 에러 로그에 timestamp, errorType, message, stack, context를 포함해야 한다.

**[Optional]** **가능하면** 심각한 에러 발생 시 Slack/이메일 알림을 발송해야 한다.

신규 파일:
- `functions/src/monitoring/error_logger.ts`
- `functions/src/monitoring/error_alerter.ts` (선택)

데이터 구조:
```typescript
interface ErrorLog {
  id: string;
  timestamp: Timestamp;
  errorType: string;
  message: string;
  stack?: string;
  context: {
    functionName: string;
    userId?: string;
    requestData?: Record<string, any>;
  };
  severity: 'low' | 'medium' | 'high' | 'critical';
}
```

---

## 4. Specifications (상세 명세)

### 4.1 파일 구조

```
functions/
├── src/
│   ├── middleware/
│   │   └── rate_limiter.ts          # 신규: Rate Limiting
│   ├── cache/
│   │   └── base_parts_cache.ts      # 신규: 캐싱
│   ├── audit/
│   │   └── audit_logger.ts          # 신규: 감사 로그
│   ├── monitoring/
│   │   ├── error_logger.ts          # 신규: 에러 로깅
│   │   └── error_alerter.ts         # 신규: 에러 알림 (선택)
│   ├── payment/
│   │   └── payment_transaction.ts   # 수정: 결제 플로우 연동
│   ├── schedulers/
│   │   ├── storage_scheduler.ts     # 수정: limit 추가
│   │   └── settlement_scheduler.ts  # 수정: limit 추가
│   ├── refund/
│   │   └── approval_deadline_scheduler.ts  # 수정: limit 추가
│   └── index.ts                     # 수정: Rate Limiting, 트랜잭션 연동
└── firestore.indexes.json           # 수정: 새 인덱스 추가
```

### 4.2 API 변경사항

#### Rate Limiter 미들웨어

```typescript
// functions/src/middleware/rate_limiter.ts
import rateLimit from 'express-rate-limit';

export const paymentRateLimiter = rateLimit({
  windowMs: 60 * 1000, // 1분
  max: 5, // 분당 5회
  message: {
    error: 'Too many payment requests',
    retryAfter: 60
  },
  standardHeaders: true,
  legacyHeaders: false,
});
```

#### Audit Logger API

```typescript
// functions/src/audit/audit_logger.ts
export async function logAudit(params: {
  userId: string;
  action: string;
  targetCollection: string;
  targetId: string;
  details?: Record<string, any>;
  ipAddress?: string;
}): Promise<void>;
```

#### Error Logger API

```typescript
// functions/src/monitoring/error_logger.ts
export async function logError(params: {
  error: Error;
  functionName: string;
  userId?: string;
  requestData?: Record<string, any>;
  severity?: 'low' | 'medium' | 'high' | 'critical';
}): Promise<void>;
```

### 4.3 의존성 추가

```json
// functions/package.json에 추가
{
  "dependencies": {
    "express-rate-limit": "^7.1.5"
  }
}
```

### 4.4 Firestore 인덱스 추가

```json
// firestore.indexes.json에 추가
{
  "collectionGroup": "auditLogs",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "userId", "order": "ASCENDING" },
    { "fieldPath": "timestamp", "order": "DESCENDING" }
  ]
},
{
  "collectionGroup": "auditLogs",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "action", "order": "ASCENDING" },
    { "fieldPath": "timestamp", "order": "DESCENDING" }
  ]
},
{
  "collectionGroup": "errorLogs",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "severity", "order": "ASCENDING" },
    { "fieldPath": "timestamp", "order": "DESCENDING" }
  ]
}
```

---

## 5. Traceability (추적성)

| 요구사항 ID | 관련 파일 | 테스트 케이스 | 검증 방법 |
|-------------|-----------|---------------|-----------|
| REQ-PAY-001 | index.ts, payment_transaction.ts | TC-PAY-001-* | Integration Test |
| REQ-PAY-002 | index.ts, payment_transaction.ts | TC-PAY-002-* | Integration Test |
| REQ-SCH-001 | storage_scheduler.ts, settlement_scheduler.ts | TC-SCH-001-* | Unit Test |
| REQ-RATE-001 | rate_limiter.ts, index.ts | TC-RATE-001-* | Integration Test |
| REQ-OPT-001 | index.ts, storage_scheduler.ts | TC-OPT-001-* | Query Analysis |
| REQ-CACHE-001 | base_parts_cache.ts | TC-CACHE-001-* | Unit Test |
| REQ-AUDIT-001 | audit_logger.ts | TC-AUDIT-001-* | Unit Test |
| REQ-ERROR-001 | error_logger.ts | TC-ERROR-001-* | Unit Test |

---

## 6. Risks (위험 요소)

| 위험 | 영향도 | 발생 가능성 | 완화 전략 |
|------|--------|-------------|-----------|
| DragonBalls 마이그레이션 시 기존 앱 호환성 문제 | High | Medium | 점진적 마이그레이션, 기존 쿼리 유지 기간 설정 |
| Rate Limiting으로 인한 정상 사용자 불편 | Medium | Low | 모니터링 후 임계값 조정, 화이트리스트 고려 |
| 인메모리 캐시 콜드 스타트 시 성능 저하 | Low | Medium | 캐시 워밍업 전략 수립 |
| 감사/에러 로그 증가로 인한 비용 증가 | Medium | Medium | 보존 기간 정책 수립, 오래된 로그 자동 삭제 |
| 배치 처리 limit으로 인한 처리 지연 | Low | Low | 배치 크기 모니터링 및 조정 |

---

*이 문서는 MoAI-ADK manager-spec 에이전트에 의해 생성되었습니다.*
*SPEC Version: 1.0.0*
*Last Updated: 2026-01-23*
