# SPEC-PHASE2-001: Acceptance Criteria (인수 조건)

---

## TAG BLOCK

```yaml
spec_id: SPEC-PHASE2-001
document_type: acceptance
related_spec: SPEC-PHASE2-001/spec.md
created: 2026-01-23T00:00:00+09:00
```

---

## 1. Quality Gates (품질 게이트)

### 1.1 필수 조건

| 조건 | 기준 | 검증 방법 |
|------|------|-----------|
| 기능 완성도 | 모든 요구사항 구현 | 체크리스트 확인 |
| 테스트 커버리지 | 신규 코드 60% 이상 | flutter test --coverage |
| 빌드 성공 | flutter build 성공 | CI/CD 파이프라인 |
| 정적 분석 | dart analyze 경고 0개 | flutter analyze |
| Play Store 정책 | 데이터 안전 체크리스트 100% | 수동 검증 |

### 1.2 Play Store 데이터 안전 체크리스트

| 항목 | 필수 | 구현 상태 |
|------|------|-----------|
| 데이터 수집 공개 | Yes | - [ ] |
| 사용자 동의 획득 | Yes | - [ ] |
| 계정 삭제 기능 | Yes | - [ ] |
| 개인정보처리방침 링크 | Yes | - [ ] |
| 제3자 데이터 공유 공개 | Yes | - [ ] |

---

## 2. Acceptance Scenarios (인수 시나리오)

### 2.1 동의 화면 시나리오

#### Feature: 약관 동의 화면

```gherkin
Feature: 서비스 이용 동의

Scenario: 신규 사용자 최초 로그인 시 동의 화면 표시
  Given 사용자가 처음으로 앱에 로그인했다
  And 사용자의 동의 기록이 없다
  When 로그인이 완료된다
  Then 서비스 이용 동의 화면이 표시된다
  And "이용약관 동의 (필수)" 항목이 표시된다
  And "개인정보처리방침 동의 (필수)" 항목이 표시된다
  And "마케팅 정보 수신 동의 (선택)" 항목이 표시된다
  And "동의하고 시작하기" 버튼이 비활성화 상태이다

Scenario: 전체 동의 체크박스 선택
  Given 동의 화면이 표시되어 있다
  And 모든 체크박스가 해제되어 있다
  When 전체 동의 체크박스를 선택한다
  Then 이용약관 동의 체크박스가 선택된다
  And 개인정보처리방침 동의 체크박스가 선택된다
  And 마케팅 동의 체크박스가 선택된다
  And "동의하고 시작하기" 버튼이 활성화된다

Scenario: 필수 항목만 동의
  Given 동의 화면이 표시되어 있다
  When 이용약관 동의를 선택한다
  And 개인정보처리방침 동의를 선택한다
  And 마케팅 동의는 선택하지 않는다
  Then "동의하고 시작하기" 버튼이 활성화된다

Scenario: 필수 항목 미동의 시 진행 불가
  Given 동의 화면이 표시되어 있다
  When 이용약관 동의만 선택한다
  And 개인정보처리방침 동의는 선택하지 않는다
  Then "동의하고 시작하기" 버튼이 비활성화 상태이다

Scenario: 동의 완료 후 홈 화면 이동
  Given 모든 필수 항목에 동의했다
  When "동의하고 시작하기" 버튼을 탭한다
  Then 동의 이력이 서버에 저장된다
  And 홈 화면으로 이동한다
```

#### Feature: 약관 상세 보기

```gherkin
Feature: 약관 상세 내용 보기

Scenario: 이용약관 상세 보기
  Given 동의 화면이 표시되어 있다
  When 이용약관의 "보기" 버튼을 탭한다
  Then 이용약관 상세 화면이 표시된다
  And WebView에 이용약관 전문이 로드된다
  And 뒤로가기 버튼이 표시된다

Scenario: 개인정보처리방침 상세 보기
  Given 동의 화면이 표시되어 있다
  When 개인정보처리방침의 "보기" 버튼을 탭한다
  Then 개인정보처리방침 상세 화면이 표시된다
  And WebView에 개인정보처리방침 전문이 로드된다

Scenario: 상세 화면에서 뒤로가기
  Given 이용약관 상세 화면이 표시되어 있다
  When 뒤로가기 버튼을 탭한다
  Then 동의 화면으로 돌아간다
  And 이전에 선택한 체크박스 상태가 유지된다
```

---

### 2.2 기존 사용자 동의 시나리오

```gherkin
Feature: 기존 사용자 동의 획득

Scenario: 약관 업데이트 후 재동의 필요
  Given 사용자가 이전에 버전 "1.0.0" 약관에 동의했다
  And 현재 약관 버전이 "2.0.0"이다
  When 사용자가 앱에 로그인한다
  Then 동의 화면이 표시된다
  And "약관이 업데이트되었습니다" 안내 메시지가 표시된다

Scenario: 기존 사용자 동의 거부
  Given 기존 사용자에게 동의 화면이 표시되어 있다
  When 뒤로가기 버튼을 탭한다
  Then 서비스 이용이 불가하다는 안내가 표시된다
  And 로그아웃 처리된다

Scenario: 이미 동의한 사용자 로그인
  Given 사용자가 최신 버전 약관에 동의했다
  When 앱에 로그인한다
  Then 동의 화면이 표시되지 않는다
  And 바로 홈 화면으로 이동한다
```

---

### 2.3 계정 삭제 시나리오

#### Feature: 계정 삭제 요청

```gherkin
Feature: 계정 삭제 기능

Scenario: 계정 삭제 메뉴 접근
  Given 사용자가 마이페이지에 있다
  When 설정 메뉴를 탭한다
  Then "계정 삭제" 메뉴가 표시된다

Scenario: 계정 삭제 화면 표시
  Given 사용자가 설정 화면에 있다
  When "계정 삭제" 메뉴를 탭한다
  Then 계정 삭제 안내 화면이 표시된다
  And 삭제 시 영향받는 데이터 목록이 표시된다
  And "계정 삭제 요청" 버튼이 표시된다

Scenario: 진행 중인 거래가 있는 경우
  Given 사용자에게 진행 중인 주문이 있다
  When 계정 삭제 화면에 접근한다
  Then "진행 중인 거래가 있어 삭제할 수 없습니다" 메시지가 표시된다
  And "계정 삭제 요청" 버튼이 비활성화된다
  And 진행 중인 거래 목록이 표시된다

Scenario: 미정산 금액이 있는 경우
  Given 사용자에게 미정산 판매 금액이 있다
  When 계정 삭제 화면에 접근한다
  Then "미정산 금액이 있어 삭제할 수 없습니다" 메시지가 표시된다
  And "계정 삭제 요청" 버튼이 비활성화된다
  And 미정산 금액 정보가 표시된다
```

#### Feature: 계정 삭제 확인

```gherkin
Feature: 계정 삭제 최종 확인

Scenario: 삭제 확인 화면 표시
  Given 사용자가 계정 삭제가 가능한 상태이다
  When "계정 삭제 요청" 버튼을 탭한다
  Then 계정 삭제 최종 확인 화면이 표시된다
  And "계정 삭제" 입력 필드가 표시된다
  And "계정 영구 삭제" 버튼이 비활성화 상태이다

Scenario: 확인 텍스트 입력
  Given 계정 삭제 확인 화면이 표시되어 있다
  When 입력 필드에 "계정 삭제"를 입력한다
  Then "계정 영구 삭제" 버튼이 활성화된다

Scenario: 잘못된 확인 텍스트 입력
  Given 계정 삭제 확인 화면이 표시되어 있다
  When 입력 필드에 "계정삭제"(띄어쓰기 없음)를 입력한다
  Then "계정 영구 삭제" 버튼이 비활성화 상태이다

Scenario: 재인증 및 삭제 처리
  Given "계정 삭제"를 정확히 입력했다
  When "계정 영구 삭제" 버튼을 탭한다
  Then 재인증 화면이 표시된다
  And 재인증 성공 시 계정이 삭제된다
  And "계정이 삭제되었습니다" 메시지가 표시된다
  And 로그인 화면으로 이동한다

Scenario: 재인증 실패
  Given 삭제 확인 후 재인증 화면이 표시되어 있다
  When 재인증에 실패한다
  Then "인증에 실패했습니다" 메시지가 표시된다
  And 계정이 삭제되지 않는다
  And 확인 화면으로 돌아간다
```

---

### 2.4 개인정보처리방침 시나리오

```gherkin
Feature: 개인정보처리방침 검증

Scenario: 필수 항목 포함 확인
  Given 개인정보처리방침 HTML 파일이 있다
  When 내용을 검토한다
  Then "수집하는 개인정보 항목" 섹션이 포함되어 있다
  And "수집 및 이용 목적" 섹션이 포함되어 있다
  And "보유 및 이용 기간" 섹션이 포함되어 있다
  And "제3자 제공" 섹션이 포함되어 있다
  And "파기 절차 및 방법" 섹션이 포함되어 있다
  And "이용자 권리" 섹션이 포함되어 있다
  And "개인정보 보호책임자" 섹션이 포함되어 있다

Scenario: 제3자 제공 내역 확인
  Given 개인정보처리방침의 "제3자 제공" 섹션이 있다
  When 내용을 검토한다
  Then 결제 대행사 정보가 포함되어 있다
  And 제공 목적이 명시되어 있다
  And 제공 항목이 명시되어 있다

Scenario: WebView 렌더링 확인
  Given 앱에서 개인정보처리방침 상세 화면을 연다
  When WebView가 로드된다
  Then 모든 텍스트가 정상적으로 표시된다
  And 스크롤이 정상 동작한다
  And 링크가 정상 동작한다
```

---

### 2.5 동의 이력 저장 시나리오

```gherkin
Feature: 동의 이력 저장

Scenario: 동의 이력 Firestore 저장
  Given 사용자가 모든 필수 항목에 동의했다
  When "동의하고 시작하기"를 탭한다
  Then users/{uid}/consents 서브컬렉션에 문서가 생성된다
  And termsVersion 필드에 현재 약관 버전이 저장된다
  And privacyVersion 필드에 현재 개인정보처리방침 버전이 저장된다
  And marketingConsent 필드에 마케팅 동의 여부가 저장된다
  And consentedAt 필드에 현재 시간이 저장된다
  And ipAddress 필드에 사용자 IP가 저장된다

Scenario: 동의 이력 조회
  Given 사용자의 동의 이력이 저장되어 있다
  When 앱이 동의 상태를 확인한다
  Then 가장 최근 동의 기록의 버전을 조회한다
  And 현재 약관 버전과 비교한다

Scenario: 마케팅 동의 변경
  Given 사용자가 마케팅 동의를 했었다
  When 설정에서 마케팅 동의를 철회한다
  Then 새로운 동의 이력이 저장된다
  And marketingConsent가 false로 저장된다
```

---

## 3. Definition of Done (완료 정의)

### 3.1 개별 작업 완료 조건

- [ ] 코드 구현 완료
- [ ] Widget 테스트 작성 및 통과
- [ ] 정적 분석 통과 (dart analyze)
- [ ] 코드 리뷰 완료 (해당시)

### 3.2 마일스톤 완료 조건

#### M1: 동의 UI 구현
- [ ] consent_screen.dart 구현 완료
- [ ] privacy_detail_screen.dart 구현 완료
- [ ] terms_detail_screen.dart 구현 완료
- [ ] consent_repository.dart 구현 완료
- [ ] 동의 상태 Provider 구현 완료
- [ ] iOS/Android 양쪽 동작 확인

#### M2: 계정 삭제 기능
- [ ] account_delete_screen.dart 구현 완료
- [ ] account_delete_confirm_screen.dart 구현 완료
- [ ] delete_account.ts Cloud Function 구현 완료
- [ ] 재인증 로직 구현 완료
- [ ] 감사 로그 연동 완료

#### M3: 개인정보처리방침 및 통합
- [ ] privacy.html 7개 필수 항목 포함
- [ ] 로그인 플로우에 동의 화면 통합
- [ ] 기존 사용자 동의 로직 구현
- [ ] E2E 플로우 테스트 완료

#### M4: 테스트 및 검증
- [ ] Widget 테스트 커버리지 60% 이상
- [ ] Cloud Functions 동작 검증
- [ ] Play Store 데이터 안전 체크리스트 100%

### 3.3 SPEC 전체 완료 조건

- [ ] 모든 마일스톤 완료
- [ ] 모든 품질 게이트 통과
- [ ] Play Store 데이터 안전 섹션 작성 완료
- [ ] 문서 업데이트 완료

---

## 4. Verification Methods (검증 방법)

### 4.1 자동화 테스트

| 테스트 유형 | 도구 | 실행 방법 |
|-------------|------|-----------|
| Widget 테스트 | Flutter Test | `flutter test` |
| 정적 분석 | Dart Analyzer | `flutter analyze` |
| 코드 포맷 | Dart Format | `dart format --set-exit-if-changed .` |

### 4.2 수동 테스트

| 시나리오 | 검증 항목 | 플랫폼 |
|----------|-----------|--------|
| 동의 플로우 | 전체 동의 → 서비스 이용 | iOS, Android |
| 계정 삭제 | 요청 → 확인 → 재인증 → 삭제 | iOS, Android |
| WebView | 약관/방침 렌더링 | iOS, Android |

### 4.3 Play Store 검증

| 항목 | 검증 방법 |
|------|-----------|
| 데이터 수집 | 개인정보처리방침과 일치 확인 |
| 계정 삭제 | 실제 삭제 동작 확인 |
| 동의 획득 | 앱 내 동의 UI 스크린샷 |

---

## 5. Rollback Criteria (롤백 기준)

### 5.1 즉시 롤백

- 동의 화면 무한 루프 발생
- 계정 삭제 시 잘못된 데이터 삭제
- 앱 크래시율 > 1%
- 동의 저장 실패율 > 5%

### 5.2 모니터링 후 롤백

- 동의 완료율 < 90% (정상적인 사용자)
- 계정 삭제 오류율 > 5%
- WebView 로딩 실패율 > 10%

---

## 6. Play Store 제출 체크리스트

### 6.1 데이터 안전 섹션 준비

```
[ ] 데이터 유형
    [ ] 개인 정보: 이름, 이메일, 주소, 전화번호
    [ ] 금융 정보: 결제 정보 (PG사 처리)
    [ ] 위치: 배송 주소
    [ ] 앱 활동: 앱 상호작용, 검색 기록

[ ] 데이터 수집
    [ ] 필수 데이터: 예
    [ ] 선택 데이터: 마케팅 동의

[ ] 데이터 공유
    [ ] 결제 대행사 (KakaoPay, TossPayments)
    [ ] 배송 서비스

[ ] 보안 관행
    [ ] 전송 중 데이터 암호화: 예 (HTTPS)
    [ ] 데이터 삭제 요청 가능: 예

[ ] 계정 삭제
    [ ] 앱 내 삭제 옵션: 예
    [ ] 웹사이트 삭제 옵션: (해당시)
```

### 6.2 스크린샷 준비

- [ ] 동의 화면 스크린샷
- [ ] 개인정보처리방침 화면 스크린샷
- [ ] 계정 삭제 화면 스크린샷

---

*이 문서는 SPEC-PHASE2-001의 인수 조건입니다.*
*작성일: 2026-01-23*
