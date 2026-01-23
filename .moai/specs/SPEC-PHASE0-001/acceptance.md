# SPEC-PHASE0-001: Acceptance Criteria

---

## TAG BLOCK

```yaml
spec_id: SPEC-PHASE0-001
document_type: acceptance
created: 2026-01-22T00:00:00+09:00
status: Planned
```

---

## 1. 전역 인프라 구축 (0.1) 수락 기준

### AC-INFRA-001: Logger 시스템

#### TC-LOGGER-001: Debug 모드에서 모든 로그 레벨 출력

```gherkin
Feature: Logger 시스템 - Debug 모드 동작

  Scenario: Debug 모드에서 debug 레벨 로그 출력
    Given 앱이 Debug 모드로 실행 중이다
    When AppLogger.d("테스트 메시지", "TAG")를 호출한다
    Then 콘솔에 "[DEBUG] [TAG] 테스트 메시지"가 출력된다

  Scenario: Debug 모드에서 info 레벨 로그 출력
    Given 앱이 Debug 모드로 실행 중이다
    When AppLogger.i("정보 메시지")를 호출한다
    Then 콘솔에 "[INFO] 정보 메시지"가 출력된다

  Scenario: Debug 모드에서 warning 레벨 로그 출력
    Given 앱이 Debug 모드로 실행 중이다
    When AppLogger.w("경고 메시지", "AUTH")를 호출한다
    Then 콘솔에 "[WARNING] [AUTH] 경고 메시지"가 출력된다

  Scenario: Debug 모드에서 error 레벨 로그 출력 (스택 트레이스 포함)
    Given 앱이 Debug 모드로 실행 중이다
    And Exception("테스트 에러")가 발생했다
    When AppLogger.e("에러 발생", error, stackTrace, "PAYMENT")를 호출한다
    Then 콘솔에 "[ERROR] [PAYMENT] 에러 발생"이 출력된다
    And 콘솔에 "Error: 테스트 에러"가 출력된다
    And 콘솔에 스택 트레이스가 출력된다
```

#### TC-LOGGER-002: Release 모드에서 로그 제한

```gherkin
Feature: Logger 시스템 - Release 모드 동작

  Scenario: Release 모드에서 debug 레벨 로그 미출력
    Given 앱이 Release 모드로 실행 중이다
    When AppLogger.d("테스트 메시지")를 호출한다
    Then 콘솔에 아무것도 출력되지 않는다

  Scenario: Release 모드에서 info 레벨 로그 미출력
    Given 앱이 Release 모드로 실행 중이다
    When AppLogger.i("정보 메시지")를 호출한다
    Then 콘솔에 아무것도 출력되지 않는다

  Scenario: Release 모드에서 error 레벨은 Crashlytics로 전송
    Given 앱이 Release 모드로 실행 중이다
    And Crashlytics가 초기화되어 있다
    When AppLogger.e("심각한 에러", error, stackTrace)를 호출한다
    Then Crashlytics에 에러가 기록된다
```

---

### AC-INFRA-002: 통합 상수 파일

#### TC-CONST-001: 상수 값 정확성 검증

```gherkin
Feature: 통합 상수 파일 - 값 검증

  Scenario: 배송비 상수 값 확인
    Given AppConstants 클래스가 존재한다
    When defaultShippingFee 값을 조회한다
    Then 값이 4500이다

  Scenario: HTTP 타임아웃 상수 값 확인
    Given AppConstants 클래스가 존재한다
    When httpConnectTimeout 값을 조회한다
    Then 값이 Duration(seconds: 10)이다
    When httpReceiveTimeout 값을 조회한다
    Then 값이 Duration(seconds: 30)이다

  Scenario: 페이지네이션 상수 값 확인
    Given AppConstants 클래스가 존재한다
    When defaultPageSize 값을 조회한다
    Then 값이 20이다
    When maxPageSize 값을 조회한다
    Then 값이 100이다

  Scenario: 드래곤볼 상수 값 확인
    Given AppConstants 클래스가 존재한다
    When dragonBallStorageDays 값을 조회한다
    Then 값이 30이다
    When dragonBallWarningDays 값을 조회한다
    Then 값이 7이다

  Scenario: 환불 상수 값 확인
    Given AppConstants 클래스가 존재한다
    When refundApprovalDeadlineDays 값을 조회한다
    Then 값이 2이다
    When autoConfirmPurchaseDays 값을 조회한다
    Then 값이 7이다
```

---

### AC-INFRA-003: 에러 핸들링 표준화

#### TC-FAILURE-001: Failure 타입 생성 및 속성 검증

```gherkin
Feature: 에러 핸들링 - Failure 타입

  Scenario: NetworkFailure 생성
    When NetworkFailure()를 생성한다
    Then message가 "네트워크 연결을 확인해주세요"이다
    And code가 "NETWORK_ERROR"이다

  Scenario: AuthFailure 생성 (커스텀 메시지)
    When AuthFailure("세션이 만료되었습니다")를 생성한다
    Then message가 "세션이 만료되었습니다"이다
    And code가 "AUTH_ERROR"이다

  Scenario: PaymentFailure 생성
    When PaymentFailure()를 생성한다
    Then message가 "결제 처리 중 오류가 발생했습니다"이다
    And code가 "PAYMENT_ERROR"이다

  Scenario: ValidationFailure 생성
    When ValidationFailure("이메일 형식이 올바르지 않습니다")를 생성한다
    Then message가 "이메일 형식이 올바르지 않습니다"이다
    And code가 "VALIDATION_ERROR"이다

  Scenario: Failure toString 검증
    Given NetworkFailure()가 생성되었다
    When toString()을 호출한다
    Then "Failure(NETWORK_ERROR): 네트워크 연결을 확인해주세요"가 반환된다
```

---

### AC-INFRA-004: Result 타입

#### TC-RESULT-001: Result 성공 케이스

```gherkin
Feature: Result 타입 - 성공 케이스

  Scenario: Result.success 생성 및 when 패턴 매칭
    Given User 객체가 존재한다
    When Result.success(user)를 생성한다
    And when() 메서드로 결과를 처리한다
    Then success 콜백이 호출된다
    And success 콜백에 user 객체가 전달된다
    And failure 콜백은 호출되지 않는다
```

#### TC-RESULT-002: Result 실패 케이스

```gherkin
Feature: Result 타입 - 실패 케이스

  Scenario: Result.failure 생성 및 when 패턴 매칭
    Given NetworkFailure가 존재한다
    When Result.failure(failure)를 생성한다
    And when() 메서드로 결과를 처리한다
    Then failure 콜백이 호출된다
    And failure 콜백에 NetworkFailure가 전달된다
    And success 콜백은 호출되지 않는다
```

---

## 2. Critical 버그 수정 - Flutter (0.2) 수락 기준

### AC-FIX-001: Debug Print 제거

#### TC-PRINT-001: print/debugPrint 완전 제거 검증

```gherkin
Feature: Debug Print 제거

  Scenario: 프로젝트 전체에서 print 문 제거 확인
    Given lib/ 디렉토리가 존재한다
    When "print(" 패턴으로 검색한다 (정규식: print\()
    Then 검색 결과가 0개이다

  Scenario: 프로젝트 전체에서 debugPrint 문 제거 확인
    Given lib/ 디렉토리가 존재한다
    When "debugPrint(" 패턴으로 검색한다
    Then 검색 결과가 0개이다

  Scenario: checkout_screen.dart Logger 교체 확인
    Given lib/features/checkout/presentation/screens/checkout_screen.dart가 존재한다
    When 파일 내용을 검사한다
    Then "print(" 문자열이 없다
    And "AppLogger" import가 존재한다

  Scenario: purchase_usecase.dart Logger 교체 확인
    Given lib/features/checkout/domain/usecases/purchase_usecase.dart가 존재한다
    When 파일 내용을 검사한다
    Then "print(" 문자열이 없다
    And "AppLogger" import가 존재한다
```

---

### AC-FIX-002: 배송비 상수화

#### TC-SHIPPING-001: 배송비 하드코딩 제거 검증

```gherkin
Feature: 배송비 상수화

  Scenario: checkout_screen.dart 배송비 상수 사용 확인
    Given lib/features/checkout/presentation/screens/checkout_screen.dart가 존재한다
    When 파일 내용을 검사한다
    Then "4500" 하드코딩이 없다
    And "AppConstants.defaultShippingFee" 참조가 존재한다

  Scenario: cart_summary.dart 배송비 상수 사용 확인
    Given lib/features/cart/presentation/widgets/cart_summary.dart가 존재한다
    When 파일 내용을 검사한다
    Then "4500" 하드코딩이 없다
    And "AppConstants.defaultShippingFee" 참조가 존재한다

  Scenario: purchase_usecase.dart 배송비 수정 확인 (Critical)
    Given lib/features/checkout/domain/usecases/purchase_usecase.dart가 존재한다
    When 파일 내용을 검사한다
    Then "3000" 하드코딩이 없다
    And "AppConstants.defaultShippingFee" 참조가 존재한다
```

#### TC-SHIPPING-002: 배송비 일관성 검증

```gherkin
Feature: 배송비 일관성 검증

  Scenario: 장바구니와 결제 화면의 배송비 일치
    Given 사용자가 상품을 장바구니에 추가했다
    When 장바구니 화면에서 배송비를 확인한다
    Then 배송비가 4,500원으로 표시된다

    When 결제 화면으로 이동한다
    Then 결제 화면의 배송비도 4,500원으로 표시된다

  Scenario: 주문 완료 시 올바른 배송비 적용
    Given 사용자가 10,000원 상품을 결제한다
    When 결제를 완료한다
    Then 주문의 shippingFee가 4500이다
    And 총 결제 금액이 14,500원이다
```

---

### AC-FIX-003: HTTP 타임아웃 설정

#### TC-TIMEOUT-001: 타임아웃 설정 검증

```gherkin
Feature: HTTP 타임아웃 설정

  Scenario: HTTP 클라이언트에 연결 타임아웃 설정
    Given Payment Datasource가 존재한다
    When HTTP 클라이언트 설정을 검사한다
    Then 연결 타임아웃이 10초로 설정되어 있다

  Scenario: HTTP 클라이언트에 수신 타임아웃 설정
    Given Payment Datasource가 존재한다
    When HTTP 클라이언트 설정을 검사한다
    Then 수신 타임아웃이 30초로 설정되어 있다

  Scenario: 연결 타임아웃 발생 시 에러 처리
    Given 네트워크가 느린 상태이다
    When HTTP 연결이 10초 이상 걸린다
    Then ConnectionTimeout 에러가 발생한다
    And 사용자에게 네트워크 오류 메시지가 표시된다
```

---

### AC-FIX-004: Kakao SDK 키 환경변수 분리

#### TC-KAKAO-001: Kakao SDK 키 보안 검증

```gherkin
Feature: Kakao SDK 키 환경변수 분리

  Scenario: 소스 코드에 API 키 하드코딩 없음 확인
    Given lib/main.dart가 존재한다
    When 파일 내용을 검사한다
    Then Kakao Native App Key가 하드코딩되어 있지 않다

  Scenario: 환경 변수에서 Kakao 키 로드
    Given 환경 변수에 KAKAO_NATIVE_KEY가 설정되어 있다
    When 앱이 시작된다
    Then Kakao SDK가 환경 변수의 키로 초기화된다

  Scenario: 환경 변수 미설정 시 에러 처리
    Given 환경 변수에 KAKAO_NATIVE_KEY가 설정되어 있지 않다
    When 앱이 시작된다
    Then 명확한 에러 메시지가 로그에 기록된다
```

---

## 3. Critical 버그 수정 - Backend (0.3) 수락 기준

### AC-FIX-005: Admin UID 환경변수화

#### TC-ADMIN-001: Admin 설정 파일 검증

```gherkin
Feature: Admin UID 환경변수화

  Scenario: Admin 설정 파일 존재 확인
    Given functions/src/config/ 디렉토리가 존재한다
    Then functions/src/config/admin.ts 파일이 존재한다
    And getAdminUserIds() 함수가 export되어 있다
    And isAdmin() 함수가 export되어 있다

  Scenario: 환경 변수에서 Admin UID 로드
    Given Firebase config에 admin.user_ids가 "uid1,uid2,uid3"으로 설정되어 있다
    When getAdminUserIds()를 호출한다
    Then ["uid1", "uid2", "uid3"] 배열이 반환된다

  Scenario: 환경 변수 미설정 시 빈 배열 반환
    Given Firebase config에 admin.user_ids가 설정되어 있지 않다
    When getAdminUserIds()를 호출한다
    Then 빈 배열이 반환된다
    And 경고 로그가 기록된다
```

#### TC-ADMIN-002: 하드코딩 제거 검증

```gherkin
Feature: Admin UID 하드코딩 제거

  Scenario: approval_deadline_scheduler.ts 하드코딩 제거 확인
    Given functions/src/refund/approval_deadline_scheduler.ts가 존재한다
    When 파일 내용을 검사한다
    Then "ADMIN_UID_1" 문자열이 없다
    And getAdminUserIds import가 존재한다

  Scenario: process_refund.ts 하드코딩 제거 확인
    Given functions/src/refund/process_refund.ts가 존재한다
    When 파일 내용을 검사한다
    Then "ADMIN_UID_1" 문자열이 없다
    And "ADMIN_UID_2" 문자열이 없다
    And getAdminUserIds import가 존재한다
```

---

### AC-FIX-006: Firestore 인덱스 배포

#### TC-INDEX-001: 인덱스 파일 검증

```gherkin
Feature: Firestore 인덱스 배포

  Scenario: 인덱스 파일 존재 및 유효성 확인
    Given firestore.indexes.json 파일이 존재한다
    When 파일을 JSON으로 파싱한다
    Then 유효한 JSON 구조이다
    And indexes 배열이 존재한다

  Scenario: 인덱스 배포 성공
    Given firestore.indexes.json이 업데이트되었다
    When firebase deploy --only firestore:indexes를 실행한다
    Then 배포가 성공적으로 완료된다
    And Firebase 콘솔에서 인덱스가 확인된다
```

---

### AC-FIX-007: 결제 트랜잭션 로직 구현

#### TC-TRANSACTION-001: 트랜잭션 파일 존재 확인

```gherkin
Feature: 결제 트랜잭션 로직 구현

  Scenario: 트랜잭션 파일 존재 확인
    Given functions/src/payment/ 디렉토리가 존재한다
    Then functions/src/payment/payment_transaction.ts 파일이 존재한다
    And processPaymentWithTransaction 함수가 export되어 있다
```

#### TC-TRANSACTION-002: 트랜잭션 성공 케이스

```gherkin
Feature: 결제 트랜잭션 - 성공 케이스

  Scenario: 정상 결제 처리
    Given 유효한 주문 정보가 있다
    And 결제 정보가 유효하다
    And 상품 재고가 충분하다
    When processPaymentWithTransaction()을 호출한다
    Then 주문 상태가 "paid"로 업데이트된다
    And 상품 상태가 "sold"로 업데이트된다
    And 성공 응답이 반환된다
```

#### TC-TRANSACTION-003: 트랜잭션 실패 및 롤백

```gherkin
Feature: 결제 트랜잭션 - 실패 및 롤백

  Scenario: 재고 부족으로 인한 롤백
    Given 유효한 주문 정보가 있다
    And 상품이 이미 판매되었다
    When processPaymentWithTransaction()을 호출한다
    Then 트랜잭션이 롤백된다
    And 주문 상태가 변경되지 않는다
    And 에러 응답이 반환된다

  Scenario: 중간 단계 실패로 인한 롤백
    Given 유효한 주문 정보가 있다
    And Firestore 쓰기 중 오류가 발생한다
    When processPaymentWithTransaction()을 호출한다
    Then 모든 변경 사항이 롤백된다
    And 에러가 기록된다
```

---

## 4. 통합 수락 기준

### AC-INTEGRATION-001: 정적 분석 통과

```gherkin
Feature: 정적 분석 통과

  Scenario: Flutter analyze 경고 없음
    Given 프로젝트가 빌드 가능하다
    When flutter analyze를 실행한다
    Then 경고(warning)가 0개이다
    And 에러(error)가 0개이다

  Scenario: TypeScript 컴파일 성공
    Given functions 디렉토리가 존재한다
    When npm run build를 실행한다
    Then 컴파일이 성공한다
    And 타입 에러가 없다
```

### AC-INTEGRATION-002: 테스트 통과

```gherkin
Feature: 테스트 통과

  Scenario: Flutter 단위 테스트 통과
    Given test/ 디렉토리에 테스트 파일이 존재한다
    When flutter test를 실행한다
    Then 모든 테스트가 통과한다

  Scenario: 신규 유틸리티 테스트 커버리지
    Given core/utils/, core/errors/ 테스트가 존재한다
    When flutter test --coverage를 실행한다
    Then 신규 파일의 커버리지가 80% 이상이다
```

### AC-INTEGRATION-003: 수동 검증 통과

```gherkin
Feature: 수동 검증 통과

  Scenario: 결제 플로우 전체 검증
    Given 사용자가 로그인되어 있다
    When 상품을 장바구니에 추가한다
    And 결제 화면으로 이동한다
    And 배송지를 입력한다
    And 결제를 완료한다
    Then 주문이 생성된다
    And 올바른 배송비(4,500원)가 적용된다
    And 판매자에게 알림이 발송된다

  Scenario: 관리자 알림 발송 검증
    Given 환불 요청이 존재한다
    And 환불 승인 기한이 임박했다
    When 스케줄러가 실행된다
    Then 관리자에게 알림이 발송된다
    And 알림에 올바른 정보가 포함된다
```

---

## 5. Definition of Done

### 5.1 코드 품질 기준

- [ ] 모든 print/debugPrint 문이 제거되었다
- [ ] 모든 하드코딩된 상수가 AppConstants로 이동되었다
- [ ] flutter analyze 경고가 0개이다
- [ ] TypeScript 컴파일 에러가 없다

### 5.2 테스트 기준

- [ ] 신규 유틸리티 (Logger, Result, Failures)에 대한 단위 테스트가 존재한다
- [ ] 테스트 커버리지가 80% 이상이다 (신규 파일 기준)
- [ ] 모든 자동화 테스트가 통과한다

### 5.3 문서화 기준

- [ ] 신규 파일에 적절한 문서 주석이 포함되었다
- [ ] SPEC 문서가 최신 상태로 업데이트되었다
- [ ] 변경 사항이 CHANGELOG에 기록되었다

### 5.4 배포 기준

- [ ] Firebase 환경 변수가 설정되었다 (ADMIN_USER_IDS)
- [ ] Firestore 인덱스가 배포되었다
- [ ] 수동 테스트가 완료되었다

### 5.5 검토 기준

- [ ] 코드 리뷰가 완료되었다
- [ ] 보안 검토가 완료되었다 (API 키, Admin UID)
- [ ] 성능 영향이 검토되었다

---

## 6. Quality Gate Checklist

### TRUST 5 Framework 검증

| 원칙 | 검증 항목 | 상태 |
|------|-----------|------|
| **Test-first** | 신규 파일 테스트 커버리지 80%+ | [ ] |
| **Readable** | 코드 명명 규칙 준수, 문서 주석 | [ ] |
| **Unified** | 일관된 에러 처리 패턴 적용 | [ ] |
| **Secured** | API 키 환경변수화, Admin UID 보안 | [ ] |
| **Trackable** | 커밋 메시지 규칙 준수 | [ ] |

---

*이 문서는 MoAI-ADK manager-spec 에이전트에 의해 생성되었습니다.*
*Acceptance Version: 1.0.0*
*Last Updated: 2026-01-22*
