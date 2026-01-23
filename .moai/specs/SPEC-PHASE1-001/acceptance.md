# SPEC-PHASE1-001: Acceptance Criteria (인수 조건)

---

## TAG BLOCK

```yaml
spec_id: SPEC-PHASE1-001
document_type: acceptance
related_spec: SPEC-PHASE1-001/spec.md
created: 2026-01-23T00:00:00+09:00
```

---

## 1. Quality Gates (품질 게이트)

### 1.1 필수 조건

| 조건 | 기준 | 검증 방법 |
|------|------|-----------|
| 기능 완성도 | 모든 요구사항 구현 | 체크리스트 확인 |
| 테스트 커버리지 | 신규 코드 70% 이상 | Jest 커버리지 리포트 |
| 빌드 성공 | npm run build 성공 | CI/CD 파이프라인 |
| 보안 검사 | 취약점 0개 | npm audit |
| 타입 검사 | 타입 에러 0개 | tsc --noEmit |

### 1.2 성능 조건

| 메트릭 | 목표 | 측정 방법 |
|--------|------|-----------|
| 결제 API 응답 시간 | < 1초 (P95) | Firebase Functions 로그 |
| 스케줄러 실행 시간 | < 30초 | 실행 로그 분석 |
| 캐시 히트율 | > 80% | 캐시 로그 분석 |
| Cold Start 시간 | < 5초 | Functions 로그 |

---

## 2. Acceptance Scenarios (인수 시나리오)

### 2.1 결제 트랜잭션 시나리오

#### Scenario 1: 결제 승인 성공

```gherkin
Feature: 결제 트랜잭션 처리

Scenario: 정상적인 결제 승인
  Given 사용자가 유효한 결제 정보로 결제를 요청했다
  And 상품이 "available" 상태이다
  And 가격이 일치한다
  When 결제 승인 API가 호출된다
  Then 결제가 성공적으로 처리된다
  And 주문 상태가 "paid"로 변경된다
  And 상품 상태가 "sold"로 변경된다
  And 감사 로그에 "PAYMENT_APPROVED" 이벤트가 기록된다
  And 응답 상태 코드는 200이다

Scenario: 이미 판매된 상품 결제 시도
  Given 사용자가 결제를 요청했다
  And 상품이 이미 "sold" 상태이다
  When 결제 승인 API가 호출된다
  Then 트랜잭션이 실패한다
  And 응답 메시지는 "이미 판매된 상품입니다"이다
  And 응답 상태 코드는 400이다
  And 에러 로그에 기록된다

Scenario: 가격 불일치로 인한 결제 실패
  Given 사용자가 결제를 요청했다
  And 요청 금액과 상품 가격이 다르다
  When 결제 승인 API가 호출된다
  Then 트랜잭션이 실패한다
  And 응답 메시지는 "상품 가격이 변경되었습니다"를 포함한다
  And 주문 상태는 변경되지 않는다
  And 상품 상태는 변경되지 않는다
```

#### Scenario 2: 결제 취소

```gherkin
Scenario: 정상적인 결제 취소
  Given 주문이 "paid" 상태이다
  When 결제 취소가 요청된다
  Then 주문 상태가 "cancelled"로 변경된다
  And 상품 상태가 "available"로 복원된다
  And 감사 로그에 "PAYMENT_CANCELLED" 이벤트가 기록된다

Scenario: 이미 취소된 주문 재취소 시도
  Given 주문이 이미 "cancelled" 상태이다
  When 결제 취소가 요청된다
  Then 응답 메시지는 "이미 취소된 주문입니다"이다
  And 응답 상태 코드는 400이다
```

---

### 2.2 Rate Limiting 시나리오

```gherkin
Feature: API Rate Limiting

Scenario: 정상 범위 내 요청
  Given 사용자가 분당 5회 미만의 결제 요청을 보낸다
  When 결제 API가 호출된다
  Then 요청이 정상적으로 처리된다
  And 응답 상태 코드는 200이다

Scenario: Rate Limit 초과
  Given 사용자가 분당 5회의 결제 요청을 이미 보냈다
  When 6번째 결제 요청이 들어온다
  Then 응답 상태 코드는 429이다
  And 응답에 "Too many payment requests" 메시지가 포함된다
  And 응답 헤더에 "Retry-After"가 포함된다
  And 에러 로그에 Rate Limit 초과가 기록된다

Scenario: Rate Limit 리셋 후 요청
  Given 사용자가 Rate Limit에 도달했다
  And 1분이 경과했다
  When 결제 요청이 들어온다
  Then 요청이 정상적으로 처리된다
```

---

### 2.3 스케줄러 배치 처리 시나리오

```gherkin
Feature: 스케줄러 배치 처리

Scenario: 배치 크기 이내 처리
  Given 처리 대상 문서가 50개이다
  And 배치 크기가 100개이다
  When 스케줄러가 실행된다
  Then 50개 문서가 모두 처리된다
  And 로그에 "처리 대상: 50개"가 기록된다

Scenario: 배치 크기 초과 처리
  Given 처리 대상 문서가 150개이다
  And 배치 크기가 100개이다
  When 스케줄러가 실행된다
  Then 100개 문서만 처리된다
  And 로그에 "처리 대상: 100개 (배치 크기: 100)"가 기록된다
  And 다음 실행에서 나머지 50개가 처리된다

Scenario: 처리 대상 없음
  Given 처리 대상 문서가 0개이다
  When 스케줄러가 실행된다
  Then 로그에 "처리 대상 없음"이 기록된다
  And 오류 없이 완료된다
```

---

### 2.4 캐싱 시나리오

```gherkin
Feature: Base_parts 캐싱

Scenario: 캐시 미스 후 저장
  Given "base_part_001"의 캐시가 없다
  When "base_part_001" 조회가 요청된다
  Then Firestore에서 데이터를 조회한다
  And 캐시에 데이터를 저장한다
  And 데이터를 반환한다

Scenario: 캐시 히트
  Given "base_part_001"의 캐시가 존재한다
  And 캐시가 1시간 이내에 저장되었다
  When "base_part_001" 조회가 요청된다
  Then Firestore를 조회하지 않는다
  And 캐시된 데이터를 반환한다

Scenario: 캐시 만료
  Given "base_part_001"의 캐시가 존재한다
  And 캐시가 1시간 이상 전에 저장되었다
  When "base_part_001" 조회가 요청된다
  Then Firestore에서 새 데이터를 조회한다
  And 캐시를 갱신한다
  And 새 데이터를 반환한다
```

---

### 2.5 감사 로그 시나리오

```gherkin
Feature: 감사 로그 기록

Scenario: 결제 승인 감사 로그
  Given 결제 승인이 성공했다
  When 감사 로그가 기록된다
  Then auditLogs 컬렉션에 새 문서가 생성된다
  And action 필드는 "PAYMENT_APPROVED"이다
  And userId 필드에 사용자 ID가 기록된다
  And timestamp 필드에 현재 시간이 기록된다
  And details 필드에 orderId, amount, paymentMethod가 포함된다

Scenario: 환불 신청 감사 로그
  Given 환불 신청이 접수되었다
  When 감사 로그가 기록된다
  Then auditLogs 컬렉션에 새 문서가 생성된다
  And action 필드는 "REFUND_REQUESTED"이다
  And details 필드에 orderId, refundId, reason이 포함된다
```

---

### 2.6 에러 모니터링 시나리오

```gherkin
Feature: 에러 로깅

Scenario: 결제 실패 에러 로그
  Given 결제 처리 중 예외가 발생했다
  When 에러 로거가 호출된다
  Then errorLogs 컬렉션에 새 문서가 생성된다
  And errorType 필드에 에러 타입이 기록된다
  And message 필드에 에러 메시지가 기록된다
  And stack 필드에 스택 트레이스가 기록된다
  And severity 필드는 "high"이다
  And context 필드에 functionName과 userId가 포함된다

Scenario: 경미한 에러 로그
  Given 로깅 중 예외가 발생했다
  When 에러 로거가 호출된다
  Then errorLogs 컬렉션에 새 문서가 생성된다
  And severity 필드는 "low"이다
```

---

## 3. Definition of Done (완료 정의)

### 3.1 개별 작업 완료 조건

- [ ] 코드 구현 완료
- [ ] 단위 테스트 작성 및 통과
- [ ] 코드 리뷰 완료 (해당시)
- [ ] 기술 문서 업데이트 (해당시)

### 3.2 마일스톤 완료 조건

#### M1: 핵심 플로우 안정화
- [ ] 결제 승인 트랜잭션 연동 완료
- [ ] 결제 취소 트랜잭션 연동 완료
- [ ] 모든 스케줄러에 배치 limit 적용
- [ ] Rate Limiting 구현 및 적용
- [ ] Staging 환경 테스트 통과

#### M2: 성능 최적화
- [ ] DragonBalls 쿼리 분석 완료
- [ ] 쿼리 최적화 적용 (또는 마이그레이션 계획 수립)
- [ ] Base_parts 캐싱 구현 및 동작 확인

#### M3: 모니터링 시스템
- [ ] 감사 로그 시스템 구현
- [ ] 에러 로깅 시스템 구현
- [ ] Firestore 인덱스 배포
- [ ] 로그 조회 및 검증

#### M4: 테스트 및 배포
- [ ] 통합 테스트 통과
- [ ] 성능 테스트 목표 달성
- [ ] Production 배포 완료
- [ ] 배포 후 모니터링 24시간 정상

### 3.3 SPEC 전체 완료 조건

- [ ] 모든 마일스톤 완료
- [ ] 모든 품질 게이트 통과
- [ ] 성능 지표 목표 달성
- [ ] 문서 업데이트 완료
- [ ] 팀 리뷰 및 승인

---

## 4. Verification Methods (검증 방법)

### 4.1 자동화 테스트

| 테스트 유형 | 도구 | 실행 방법 |
|-------------|------|-----------|
| 단위 테스트 | Jest | `npm test` |
| 통합 테스트 | Jest + Firestore Emulator | `npm run test:integration` |
| 타입 검사 | TypeScript | `npm run typecheck` |

### 4.2 수동 테스트

| 시나리오 | 검증 항목 | 담당자 |
|----------|-----------|--------|
| 결제 플로우 | 전체 결제-취소 사이클 | QA |
| Rate Limiting | 제한 동작 확인 | 개발자 |
| 스케줄러 | 배치 처리 확인 | 개발자 |

### 4.3 모니터링

| 메트릭 | 모니터링 도구 | 알림 조건 |
|--------|---------------|-----------|
| 에러율 | Firebase Console | > 1% |
| 응답 시간 | Firebase Functions 로그 | P95 > 2초 |
| Rate Limit 초과 | errorLogs 컬렉션 | > 10회/시간 |

---

## 5. Rollback Criteria (롤백 기준)

### 5.1 즉시 롤백

- 결제 API 응답 시간 > 5초
- 결제 실패율 > 5%
- 500 에러율 > 2%
- 트랜잭션 데이터 불일치 발견

### 5.2 모니터링 후 롤백

- 결제 API 응답 시간 P95 > 2초 (1시간 지속)
- Rate Limit으로 인한 정상 사용자 불만 > 10건
- 캐시 관련 데이터 불일치 발견

---

*이 문서는 SPEC-PHASE1-001의 인수 조건입니다.*
*작성일: 2026-01-23*
