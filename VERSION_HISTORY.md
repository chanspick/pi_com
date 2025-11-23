# 📱 PiCom 버전 관리 기록

## 버전 관리 규칙
- **versionName**: `MAJOR.MINOR.PATCH` 형식 (예: 1.0.3)
- **versionCode**: 정수, 이전보다 항상 큰 값 (예: 4)
- **pubspec.yaml**: `version: MAJOR.MINOR.PATCH+BUILD_NUMBER` (예: 1.0.3+4)

## ⚠️ 중요: 버전 업데이트 시 3곳 모두 수정 필요
1. `android/app/build.gradle.kts` - versionCode, versionName
2. `pubspec.yaml` - version
3. 이 파일 (VERSION_HISTORY.md) - 변경 이력 기록

---

## 버전 히스토리

### v1.0.4 (Build 5) - 2025-01-13 ⬅️ **현재 버전**
**출시 상태**: 프로덕션 배포 준비 중

**주요 변경사항**:
- 🌐 Flutter Web 완전 지원 (반응형 디자인)
- 🎨 웹 네비게이션 바 v2 (메가 메뉴, 클릭 기반)
- 🖼️ 히어로 배너 캐러셀 (자동 슬라이드, 스와이프)
- 📄 법적 문서 HTML 페이지 추가 (이용약관, 환불정책, 개인정보처리방침)
- 🔗 푸터 링크 개선 (웹/앱 분리 네비게이션)
- ✅ 카카오페이 가맹 심사 요구사항 완료

**웹 기능**:
- 반응형 디자인 (모바일/태블릿/데스크톱)
- 메가 메뉴 네비게이션 (6개 카테고리)
- 이미지 캐러셀 배너 (5초 자동 슬라이드)
- HTML 법적 문서 (termsofuse.html, privacy_policy.html, refund.html)

**카카오페이 심사 대응**:
- 사업자 정보 푸터 완비 (상호명, 사업자번호, 대표자, 주소, 전화)
- 상품 카테고리 6개 (CPU, GPU, RAM, 메인보드, SSD, 파워)
- 배송/교환/환불 규정 상세 페이지 명시
- 결제 시스템 통합 (카카오페이)

**파일 위치**:
- `android/app/build.gradle.kts`: versionCode = 5, versionName = "1.0.4"
- `pubspec.yaml`: version: 1.0.4+5
- `web/`: termsofuse.html, privacy_policy.html, refund.html

---

### v1.0.3 (Build 4) - 2025-01-12
**출시 상태**: 프로덕션 배포 준비 중

**주요 변경사항**:
- 🔒 Firestore Security Rules 프로덕션 전환 (관리자 권한 분리)
- 🛡️ ProGuard 난독화 활성화 (코드 보안 강화)
- 🎯 targetSdk 36 (Android 15)
- 📦 App Bundle 최적화

**보안 개선**:
- 사용자는 본인 데이터만 접근 가능
- 관리자 전용 기능 분리 (parts, orders, payments 관리)
- 결제 정보 삭제 불가 설정 (감사 로그 보존)
- ProGuard 코드 난독화 적용

**파일 위치**:
- `android/app/build.gradle.kts`: versionCode = 4, versionName = "1.0.3"
- `pubspec.yaml`: version: 1.0.3+4

---

### v1.0.2 (Build 3) - 2025-01-12
**출시 상태**: Google Play Console 업로드됨

**주요 변경사항**:
- versionCode 2 → 3 업데이트
- targetSdk 35 → 36 업데이트

**파일 위치**:
- App Bundle: `build/app/outputs/bundle/release/app-release.aab`

---

### v1.0.1 (Build 2) - 2025-01-12
**출시 상태**: 초기 업로드 시도 (versionCode 충돌)

**주요 변경사항**:
- 카카오페이 결제 시스템 통합
- Firebase Functions 연동
- 결제 준비/승인/취소 API 구현

---

### v1.0.0 (Build 1) - 2025-01-10
**출시 상태**: 초기 출시

**주요 기능**:
- 사용자 인증 (Firebase Auth)
- PC 부품 가격 정보 조회
- 중고 부품 매물 등록/구매
- 드래곤볼 시스템 (포인트)
- 장바구니 및 주문 관리

---

## 📋 다음 버전 업데이트 체크리스트

### 버전 업데이트 전 필수 확인사항
- [ ] `android/app/build.gradle.kts`의 versionCode를 이전보다 큰 값으로 변경
- [ ] `android/app/build.gradle.kts`의 versionName을 새 버전으로 변경
- [ ] `pubspec.yaml`의 version을 일치하도록 변경
- [ ] 이 파일(VERSION_HISTORY.md)에 변경 이력 기록
- [ ] 변경사항을 git commit으로 기록

### 빌드 전 체크리스트
- [ ] `flutter clean`
- [ ] `flutter pub get`
- [ ] `flutter build appbundle --release`
- [ ] App Bundle 생성 확인: `build/app/outputs/bundle/release/app-release.aab`

### 배포 전 체크리스트
- [ ] Firestore Rules 배포: `firebase deploy --only firestore:rules`
- [ ] Firebase Functions 배포: `firebase deploy --only functions`
- [ ] 카카오페이 CID가 프로덕션용인지 확인
- [ ] SECURITY_GUIDE.md 검토

---

## 🔢 빌드 넘버 현황

| 날짜 | Build | Version | 상태 | 비고 |
|------|-------|---------|------|------|
| 2025-01-13 | **5** | **1.0.4** | ✅ 준비 완료 | 웹 포팅, 카카오페이 심사 대응 |
| 2025-01-12 | 4 | 1.0.3 | ✅ 배포됨 | ProGuard 활성화, 보안 강화 |
| 2025-01-12 | 3 | 1.0.2 | ✅ 업로드됨 | targetSdk 36 |
| 2025-01-12 | 2 | 1.0.1 | ⚠️ 충돌 | 카카오페이 통합 |
| 2025-01-10 | 1 | 1.0.0 | ✅ 출시 | 초기 버전 |

**다음 빌드 넘버**: 6

---

## 📞 버전 관리 담당자
- **개발팀**: PiCom Team
- **마지막 업데이트**: 2025-01-12
- **문의**: 앱 내 고객센터

---

## 🔗 관련 문서
- [보안 가이드](SECURITY_GUIDE.md)
- [Play Store 배포 가이드](PLAYSTORE_GUIDE.md)
