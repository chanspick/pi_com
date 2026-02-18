# PiComputer 앱 배포 매뉴얼

> **패키지명**: `app.picomputer`
> **버전**: 2.0.0+9
> **작성일**: 2026-01-26

---

## 목차

1. [사전 준비](#1-사전-준비)
2. [Keystore 생성](#2-keystore-생성)
3. [릴리즈 빌드](#3-릴리즈-빌드)
4. [Google Play Console 등록](#4-google-play-console-등록)
5. [App Store 등록](#5-app-store-등록-선택)
6. [외부 서비스 설정](#6-외부-서비스-설정)
7. [배포 후 체크리스트](#7-배포-후-체크리스트)

---

## 1. 사전 준비

### 필수 계정
| 서비스 | URL | 비용 |
|--------|-----|------|
| Google Play Console | https://play.google.com/console | $25 (1회) |
| Apple Developer | https://developer.apple.com | $99/년 |
| Firebase Console | https://console.firebase.google.com | 무료 |

### 필수 파일 확인
```bash
# 프로젝트 루트에서 확인
ls -la android/app/google-services.json    # Firebase Android
ls -la ios/Runner/GoogleService-Info.plist # Firebase iOS
```

### 환경 확인
```bash
flutter doctor
flutter --version  # 3.x 이상 권장
```

---

## 2. Keystore 생성

### 2.1 Keystore 파일 생성 (최초 1회)

```bash
cd C:\Users\jocha\pi_com

# keystore 디렉토리 생성
mkdir -p android/keystore

# Keystore 생성
keytool -genkey -v \
  -keystore android/keystore/picomputer-release.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias picomputer
```

**입력 정보:**
| 항목 | 예시 |
|------|------|
| 키 비밀번호 | (안전한 비밀번호) |
| 이름 | Your Name |
| 조직 단위 | Development |
| 조직 | PiComputer |
| 도시 | Seoul |
| 주 | Seoul |
| 국가 코드 | KR |

> ⚠️ **중요**: Keystore 파일과 비밀번호를 잃어버리면 앱 업데이트 불가!
> 안전한 곳에 백업 필수.

### 2.2 key.properties 설정

```bash
# 템플릿 복사
cp android/key.properties.template android/key.properties

# 편집
notepad android/key.properties
```

**내용:**
```properties
storePassword=생성시_입력한_비밀번호
keyPassword=생성시_입력한_비밀번호
keyAlias=picomputer
storeFile=../keystore/picomputer-release.jks
```

---

## 3. 릴리즈 빌드

### 3.1 Android App Bundle (.aab)

```bash
cd C:\Users\jocha\pi_com

# 클린 빌드
flutter clean
flutter pub get

# 릴리즈 빌드
flutter build appbundle --release
```

**결과물:**
```
build/app/outputs/bundle/release/app-release.aab
```

### 3.2 APK (테스트용)

```bash
flutter build apk --release
```

**결과물:**
```
build/app/outputs/flutter-apk/app-release.apk
```

### 3.3 iOS (macOS 필요)

```bash
flutter build ipa --release
```

---

## 4. Google Play Console 등록

### 4.1 앱 생성

1. [Play Console](https://play.google.com/console) 접속
2. **앱 만들기** 클릭
3. 앱 정보 입력:
   - 앱 이름: `PiComputer`
   - 기본 언어: 한국어
   - 앱/게임: 앱
   - 무료/유료: 무료

### 4.2 스토어 등록 정보

#### 필수 에셋

| 항목 | 규격 | 필수 |
|------|------|------|
| 앱 아이콘 | 512x512 PNG | ✅ |
| 기능 그래픽 | 1024x500 PNG | ❌ |
| 휴대전화 스크린샷 | 최소 2개, 16:9 또는 9:16 | ✅ |
| 태블릿 스크린샷 | 최소 1개 | ❌ |

#### 앱 설명 예시

**짧은 설명 (80자 이내):**
```
중고 PC 부품을 안전하게 거래하세요. 검수 시스템으로 신뢰할 수 있는 거래!
```

**전체 설명 (4000자 이내):**
```
PiComputer는 중고 PC 부품 전문 거래 플랫폼입니다.

✅ 주요 기능
• 중고 PC 부품 검색 및 구매
• 안전한 결제 시스템 (카카오페이, 토스페이먼츠)
• 전문 검수 시스템
• 실시간 가격 알림
• 드래곤볼 적립 시스템

✅ 안전한 거래
• 모든 거래는 검수 후 배송
• 환불 및 반품 지원
• 판매자 인증 시스템

✅ 지원 카테고리
• CPU, GPU, RAM, SSD/HDD
• 메인보드, 파워서플라이, 케이스
• 쿨러, 모니터, 주변기기
```

### 4.3 앱 콘텐츠

#### 개인정보처리방침
- URL 필요 (호스팅 필요)
- 예: `https://picomputer.app/privacy`

#### 앱 액세스 권한
- **앱의 모든 기능이 제한 없이 제공됨** 선택
- 또는 테스트 계정 제공

#### 광고
- 앱에 광고 포함 여부 선택

#### 콘텐츠 등급
- 설문지 작성 → 등급 자동 산정

### 4.4 데이터 안전 섹션

> 📄 참고: `.moai/specs/PLAY-STORE-DATA-SAFETY.md`

#### 필수 답변

| 질문 | 답변 |
|------|------|
| 사용자 데이터 수집? | 예 |
| 데이터 전송 중 암호화? | 예 (HTTPS) |
| 데이터 삭제 요청 방법? | 앱 내 설정 → 계정 삭제 |

#### 수집 데이터 유형
- ✅ 이름, 이메일, 전화번호, 주소 (필수)
- ✅ 결제 정보 (결제 처리)
- ✅ 기기 식별자 (푸시 알림)

### 4.5 앱 출시

#### 테스트 트랙 순서
```
내부 테스트 → 비공개 테스트 → 공개 테스트 → 프로덕션
```

#### 내부 테스트 (권장 시작점)
1. **테스트** → **내부 테스트** → **새 버전 만들기**
2. `app-release.aab` 업로드
3. 테스터 이메일 추가 (최대 100명)
4. **출시 검토 시작**

#### 프로덕션 출시
1. 모든 정책 준수 확인
2. **프로덕션** → **새 버전 만들기**
3. 내부 테스트에서 승격 또는 새로 업로드
4. **검토 요청**

---

## 5. App Store 등록 (선택)

### 5.1 App Store Connect

1. [App Store Connect](https://appstoreconnect.apple.com) 접속
2. **My Apps** → **+** → **New App**

### 5.2 빌드 업로드

```bash
# Xcode에서 Archive
open ios/Runner.xcworkspace

# 또는 CLI
flutter build ipa --release
```

Transporter 앱으로 업로드 또는 Xcode Organizer 사용

---

## 6. 외부 서비스 설정

### 6.1 Kakao Developers

1. [Kakao Developers](https://developers.kakao.com) 접속
2. 내 애플리케이션 → 앱 선택
3. **플랫폼** → Android/iOS 패키지명 변경
   - Android: `app.picomputer`
   - iOS: `app.picomputer`
4. 키 해시 업데이트 (릴리즈 빌드 후 로그에서 확인)

### 6.2 토스페이먼츠

1. [토스페이먼츠 개발자센터](https://developers.tosspayments.com) 접속
2. 상점관리 → 앱 설정
3. 패키지명 업데이트

### 6.3 Google Cloud Console

1. [Google Cloud Console](https://console.cloud.google.com) 접속
2. API 및 서비스 → 사용자 인증 정보
3. OAuth 클라이언트 ID → 패키지명 업데이트

---

## 7. 배포 후 체크리스트

### 즉시 확인
- [ ] 앱 설치 및 실행
- [ ] 로그인 (Google, Kakao)
- [ ] 결제 테스트 (테스트 모드)
- [ ] 푸시 알림 수신

### 1주일 내
- [ ] 크래시 리포트 확인 (Firebase Crashlytics)
- [ ] 사용자 피드백 모니터링
- [ ] 스토어 리뷰 응답

### 정기 점검
- [ ] 월간 성능 지표 확인
- [ ] 보안 업데이트 적용
- [ ] 의존성 패키지 업데이트

---

## 팁 & 트러블슈팅

### Google Play 심사 통과 팁

1. **개인정보처리방침 URL 필수**
   - 실제 접근 가능한 URL이어야 함
   - Firebase Hosting으로 간단히 호스팅 가능

2. **스크린샷 품질**
   - 실제 앱 화면 캡처 사용
   - 목업이나 가상 이미지 지양

3. **앱 설명 명확히**
   - 앱 기능을 구체적으로 설명
   - 과장 광고 금지

4. **데이터 안전 섹션 정확히**
   - 실제 수집 데이터와 일치해야 함
   - 거짓 정보 시 정지 사유

5. **테스트 계정 제공**
   - 로그인 필수 앱은 테스트 계정 필수
   - 심사자가 모든 기능 확인 가능해야 함

### 흔한 거부 사유

| 사유 | 해결 방법 |
|------|----------|
| 개인정보처리방침 없음 | URL 추가 |
| 데이터 안전 불일치 | 실제 수집 데이터와 맞춤 |
| 앱 충돌 | Crashlytics로 디버깅 |
| 기능 작동 안 함 | 테스트 계정 제공 |
| 결제 문제 | 테스트 모드 확인 |

### 유용한 명령어

```bash
# SHA-1 인증서 지문 확인 (Google Sign-In용)
keytool -list -v -keystore android/keystore/picomputer-release.jks

# 카카오 키 해시 확인 (앱 실행 시 로그)
adb logcat | grep KAKAO_KEY_HASH

# 빌드 버전 확인
flutter build appbundle --release -v
```

---

## 연락처 및 지원

- **Firebase Console**: https://console.firebase.google.com/project/picom-team
- **Play Console**: https://play.google.com/console
- **GitHub**: https://github.com/chanspick/pi_com

---

*마지막 업데이트: 2026-01-26*
