# 약관 파일 동기화 가이드

## 개요

약관 파일들이 여러 위치에 중복되어 있어 버전 관리가 어려운 문제를 해결하기 위한 자동 동기화 시스템입니다.

## 파일 구조

### 소스 파일 (루트 디렉토리)
다음 파일들이 **마스터 버전**입니다. 이 파일들만 수정하면 됩니다:

- `privacy_policy.html` - 개인정보처리방침
- `refund.html` - 환불 규정
- `storage_service_terms.html` - 보관 서비스 약관
- `termsofuse.html` - 이용약관

### 동기화 대상 디렉토리
소스 파일이 자동으로 복사되는 위치:

- `web/` - 웹 배포용
- `assets/html/` - 앱 내 표시용

**주의**: `build/` 및 `.firebase/` 디렉토리의 파일들은 빌드 산출물이므로 자동 생성됩니다.

## 사용 방법

### 약관 수정 시

1. **루트 디렉토리의 파일만 수정**하세요
   ```
   privacy_policy.html
   refund.html
   storage_service_terms.html
   termsofuse.html
   ```

2. **동기화 스크립트 실행**
   ```bash
   dart run scripts/sync_terms.dart
   ```

3. 성공 메시지 확인:
   ```
   📄 약관 파일 동기화 시작...
   ✅ privacy_policy.html → web/privacy_policy.html
   ✅ privacy_policy.html → assets/html/privacy_policy.html
   ...
   📊 동기화 완료: 성공: 8개, 실패: 0개
   ```

### 자동화 옵션

#### 빌드 전 자동 실행

`pubspec.yaml`에 다음을 추가할 수 있습니다:
```yaml
# 빌드 스크립트에서 호출
# flutter build 전에 dart run scripts/sync_terms.dart 실행
```

또는 셸 스크립트 생성:
```bash
# build_with_sync.sh
dart run scripts/sync_terms.dart && flutter build web
```

#### Git Pre-commit Hook

`.git/hooks/pre-commit` 파일 생성:
```bash
#!/bin/bash
# 약관 파일이 변경되었으면 자동 동기화
git diff --cached --name-only | grep -E "(privacy_policy|refund|storage_service_terms|termsofuse)\.html" && \
  dart run scripts/sync_terms.dart && \
  git add web/*.html assets/html/*.html
```

## 트러블슈팅

### 문제: 약관이 구버전으로 표시됨

**해결방법:**
1. 루트 디렉토리 파일이 최신인지 확인
2. `dart run scripts/sync_terms.dart` 실행
3. `flutter clean` 후 재빌드

### 문제: 동기화 스크립트 실패

**해결방법:**
1. 대상 디렉토리가 존재하는지 확인:
   - `web/` 디렉토리
   - `assets/html/` 디렉토리
2. 파일 권한 확인
3. 에러 메시지 확인 후 해당 파일/디렉토리 점검

## 주의사항

⚠️ **절대 하지 말아야 할 것:**
- `web/` 또는 `assets/html/` 디렉토리의 약관 파일 직접 수정
- `build/` 디렉토리의 파일 수정
- `.firebase/` 디렉토리의 파일 수정

✅ **올바른 워크플로우:**
1. 루트 디렉토리 파일 수정
2. 동기화 스크립트 실행
3. 변경사항 커밋
4. 빌드 및 배포

## 파일 위치 요약

```
pi_com/
├── privacy_policy.html              ← 여기만 수정!
├── refund.html                      ← 여기만 수정!
├── storage_service_terms.html       ← 여기만 수정!
├── termsofuse.html                  ← 여기만 수정!
├── scripts/
│   └── sync_terms.dart              ← 동기화 스크립트
├── web/
│   ├── privacy_policy.html          ← 자동 동기화됨
│   ├── refund.html                  ← 자동 동기화됨
│   ├── storage_service_terms.html   ← 자동 동기화됨
│   └── termsofuse.html              ← 자동 동기화됨
└── assets/html/
    ├── privacy_policy.html          ← 자동 동기화됨
    ├── refund.html                  ← 자동 동기화됨
    ├── storage_service_terms.html   ← 자동 동기화됨
    └── termsofuse.html              ← 자동 동기화됨
```
