
# 🚀 플레이스토어 출시 가이드

## 📱 현재 상태
- 앱명: pi_com
- 패키지명: app.picom.team.pi_com
- 버전: 1.0.0 (versionCode: 1)
- targetSdk: 34 (Android 14)

---

## 🔴 필수 작업

### 1. 릴리즈 키스토어 생성 및 서명 설정

#### 1-1. 키스토어 생성 (한 번만 실행)

**중요:** 키스토어는 절대 잃어버리면 안 됩니다! 안전한 곳에 백업하세요.

```bash
cd C:\Users\PC\AndroidStudioProjects\pi_com\android\app

keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# 입력 예시:
# 비밀번호: [강력한 비밀번호 입력 - 반드시 기록!]
# 이름: PICOM Team
# 조직: PICOM
# 도시/지역: Seoul
# 시/도: Seoul
# 국가 코드: KR
```

**⚠️ 중요:** 생성된 `upload-keystore.jks` 파일과 비밀번호를 안전하게 보관하세요!

#### 1-2. key.properties 파일 생성

`android/key.properties` 파일을 생성하고 다음 내용을 입력:

```properties
storePassword=여기에_키스토어_비밀번호_입력
keyPassword=여기에_키_비밀번호_입력
keyAlias=upload
storeFile=app/upload-keystore.jks
```

**⚠️ 보안:** `key.properties`를 `.gitignore`에 추가하여 Git에 커밋되지 않도록 하세요!

```bash
# .gitignore에 추가
echo "android/key.properties" >> .gitignore
echo "android/app/upload-keystore.jks" >> .gitignore
```

#### 1-3. build.gradle.kts 수정

`android/app/build.gradle.kts` 파일을 다음과 같이 수정:

```kotlin
// 파일 최상단에 추가
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    // ... 기존 설정 ...

    // signingConfigs를 buildTypes 위에 추가
    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // debug에서 release로 변경
            signingConfig = signingConfigs.getByName("release")

            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        // ... 나머지 동일
    }
}
```

---

### 2. 앱 이름 및 아이콘 설정

#### 2-1. 앱 이름 변경

`android/app/src/main/AndroidManifest.xml`:
```xml
<application
    android:label="파이컴퓨터"  <!-- pi_com에서 사용자에게 보일 이름으로 변경 -->
    ...
```

#### 2-2. 앱 아이콘 생성

1. **아이콘 이미지 준비**
   - 최소 1024x1024 PNG 파일
   - 배경 없는 투명 PNG 권장

2. **자동 아이콘 생성 (추천)**

```bash
# flutter_launcher_icons 패키지 사용
flutter pub add dev:flutter_launcher_icons

# pubspec.yaml에 추가:
# flutter_launcher_icons:
#   android: true
#   ios: false
#   image_path: "assets/icon/app_icon.png"
#   adaptive_icon_background: "#FFFFFF"
#   adaptive_icon_foreground: "assets/icon/app_icon_foreground.png"

flutter pub run flutter_launcher_icons
```

또는 수동으로:
- https://romannurik.github.io/AndroidAssetStudio/ 에서 생성
- `android/app/src/main/res/mipmap-*/ic_launcher.png` 파일들을 교체

---

### 3. 개인정보처리방침 페이지

Google Play는 개인정보를 수집하는 앱에 대해 개인정보처리방침 URL을 필수로 요구합니다.

**옵션 1: Firebase Hosting 사용 (무료)**

```bash
# public/privacy-policy.html 파일 생성
firebase deploy --only hosting
```

**옵션 2: GitHub Pages 사용 (무료)**

1. GitHub 저장소에 `docs/privacy-policy.html` 파일 생성
2. 저장소 Settings → Pages에서 활성화
3. `https://[사용자명].github.io/[저장소명]/privacy-policy.html` URL 사용

**최소 내용:**
- 수집하는 정보 (이메일, 주소, 결제 정보 등)
- 정보 사용 목적
- 제3자 공유 여부 (Firebase, Kakao Pay 등)
- 사용자 권리 (정보 삭제, 수정 요청 등)
- 연락처

---

### 4. 앱 권한 확인

`android/app/src/main/AndroidManifest.xml`에 필요한 권한 추가:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- 인터넷 (Firebase, API 통신) -->
    <uses-permission android:name="android.permission.INTERNET"/>

    <!-- 카메라 (프로필 사진) -->
    <uses-permission android:name="android.permission.CAMERA"/>

    <!-- 갤러리 접근 (이미지 선택) -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>

    <application>
        ...
    </application>
</manifest>
```

---

### 5. ProGuard 규칙 확인

`android/app/proguard-rules.pro` 파일 생성 (없다면):

```proguard
# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Retrofit/OkHttp (API 통신)
-keepattributes Signature
-keepattributes *Annotation*
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okhttp3.**

# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# WebView
-keep class android.webkit.** { *; }

# Kakao Pay
-keep class com.kakao.** { *; }
```

---

## 🟡 권장 작업

### 6. 앱 버전 관리 전략

`pubspec.yaml`:
```yaml
version: 1.0.0+1
# 형식: major.minor.patch+buildNumber
# 예: 1.0.0+1 → 1.0.1+2 → 1.1.0+3 → 2.0.0+4
```

**업데이트 시:**
- 버그 수정: patch 증가 (1.0.0 → 1.0.1)
- 새 기능: minor 증가 (1.0.1 → 1.1.0)
- 대규모 변경: major 증가 (1.1.0 → 2.0.0)
- buildNumber는 항상 증가 (+1 → +2 → +3)

---

### 7. 스플래시 스크린 설정

`flutter_native_splash` 패키지 사용:

```bash
flutter pub add dev:flutter_native_splash
```

`pubspec.yaml`:
```yaml
flutter_native_splash:
  color: "#FFFFFF"
  image: assets/splash/logo.png
  android: true
  ios: false
```

```bash
flutter pub run flutter_native_splash:create
```

---

## 📸 Play Console 필수 자료

### 8. 스크린샷 준비

**최소 2개, 최대 8개 필요:**
- 해상도: 최소 320px, 최대 3840px
- 종횡비: 16:9 또는 9:16
- 형식: PNG 또는 JPEG

**권장 크기:**
- 1080 x 1920px (세로)
- 1920 x 1080px (가로)

**캡처할 화면 예시:**
1. 홈 화면 (상품 목록)
2. 상품 상세 페이지
3. 장바구니/결제 화면
4. 마이페이지
5. 드래곤볼 기능 소개

---

### 9. 앱 설명 작성

#### 짧은 설명 (80자 이내)
```
중고 PC 부품 거래 플랫폼 - 안전한 거래, 드래곤볼 무료 보관
```

#### 전체 설명 (최대 4000자)
```
🖥️ 파이컴퓨터 - 중고 PC 부품 전문 거래 플랫폼

안전하고 편리한 중고 PC 부품 거래를 위한 모바일 앱입니다.

✨ 주요 기능

📦 드래곤볼 서비스
• 구매한 부품을 최대 30일간 무료 보관
• 여러 부품을 한 번에 배송받아 배송비 절약
• 보관 중 부품 렌탈 서비스로 수익 창출

🛒 편리한 쇼핑
• 실시간 중고 부품 가격 비교
• 가격 알림 기능
• 안전한 카카오페이 결제

💰 간편한 판매
• 완제품 PC 판매 요청
• 간편한 부품 등록
• 판매 내역 관리

🔒 안전한 거래
• 본인 인증 시스템
• 거래 보호 정책
• 실시간 고객 지원

[나머지 자세한 설명 추가...]
```

---

### 10. 그래픽 자산

**앱 아이콘** (필수)
- 512 x 512px PNG (32비트)
- 투명 배경 없이

**기능 그래픽** (필수)
- 1024 x 500px PNG 또는 JPEG
- 앱의 주요 기능을 보여주는 배너

---

## 🚀 빌드 및 배포

### 11. 릴리즈 APK/AAB 빌드

#### AAB 빌드 (권장 - Play Store 필수)
```bash
cd C:\Users\PC\AndroidStudioProjects\pi_com

# 빌드 전 클린
flutter clean
flutter pub get

# AAB 빌드
flutter build appbundle --release

# 생성 위치: build/app/outputs/bundle/release/app-release.aab
```

#### APK 빌드 (테스트용)
```bash
flutter build apk --release --split-per-abi

# 생성 위치:
# build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
# build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
# build/app/outputs/flutter-apk/app-x86_64-release.apk
```

---

### 12. 앱 테스트

**로컬 테스트:**
```bash
# 릴리즈 APK 설치 후 테스트
flutter install --release
```

**체크리스트:**
- [ ] 모든 화면이 정상 작동
- [ ] 회원가입/로그인 작동
- [ ] Firebase 연동 확인
- [ ] 결제 프로세스 테스트
- [ ] 이미지 업로드 테스트
- [ ] 배송지 관리 테스트
- [ ] 뒤로가기 버튼 동작
- [ ] 푸시 알림 (있다면)

---

### 13. Google Play Console 설정

#### 13-1. 개발자 계정 생성
- https://play.google.com/console
- 일회성 등록비: $25 USD

#### 13-2. 앱 등록
1. **앱 만들기**
   - 앱 이름: 파이컴퓨터
   - 기본 언어: 한국어
   - 앱 또는 게임: 앱
   - 무료 또는 유료: 무료

2. **앱 콘텐츠**
   - 개인정보처리방침 URL 입력
   - 앱 액세스 권한 (로그인 필요 여부)
   - 광고 포함 여부
   - 콘텐츠 등급 설정 (PEGI, ESRB 등)
   - 타겟 대상층 및 콘텐츠 설정

3. **앱 카테고리**
   - 카테고리: 쇼핑
   - 태그: 중고거래, PC부품, 전자제품

4. **스토어 등록정보**
   - 스크린샷 업로드
   - 앱 설명 입력
   - 그래픽 자산 업로드

5. **프로덕션 트랙**
   - AAB 파일 업로드
   - 출시 노트 작성

#### 13-3. 내부 테스트 (선택사항 - 권장)
```
내부 테스트 → 폐쇄형 테스트 → 공개 테스트 → 프로덕션 순으로 진행 권장
```

---

## ✅ 최종 체크리스트

출시 전 반드시 확인:

### 기술적 요구사항
- [ ] 릴리즈 키스토어 생성 및 서명 설정
- [ ] key.properties를 .gitignore에 추가
- [ ] 앱 이름 변경 (사용자 친화적 이름)
- [ ] 앱 아이콘 설정
- [ ] targetSdkVersion 34 이상
- [ ] ProGuard 규칙 설정
- [ ] AAB 파일 생성 성공
- [ ] 릴리즈 빌드 테스트 완료

### 법적 요구사항
- [ ] 개인정보처리방침 URL
- [ ] 서비스 이용약관
- [ ] 환불 정책
- [ ] 저작권 표시

### Play Console
- [ ] 개발자 계정 생성 ($25)
- [ ] 앱 등록 완료
- [ ] 스크린샷 업로드 (최소 2개)
- [ ] 앱 설명 작성
- [ ] 그래픽 자산 업로드
- [ ] 콘텐츠 등급 설정
- [ ] AAB 업로드
- [ ] 출시 노트 작성

---

## 🔧 문제 해결

### 빌드 오류 시
```bash
# 캐시 삭제 후 재빌드
flutter clean
flutter pub get
cd android && ./gradlew clean
cd ..
flutter build appbundle --release
```

### ProGuard 오류 시
```bash
# build.gradle.kts에서 일시적으로 비활성화
isMinifyEnabled = false
isShrinkResources = false
```

### 서명 오류 시
```bash
# key.properties 파일 경로 확인
# 키스토어 파일이 올바른 위치에 있는지 확인
```

---

## 📞 추가 도움말

- Flutter 공식 문서: https://docs.flutter.dev/deployment/android
- Play Console 도움말: https://support.google.com/googleplay/android-developer
- Firebase 설정 가이드: https://firebase.google.com/docs/flutter/setup

---

**마지막 업데이트:** 2025년 1월
**작성자:** Claude Code
