# 카카오 로그인 통합 작업 완료 보고서

**작업 일자:** 2025년 11월 15일
**작업자:** Claude Code
**프로젝트:** PiCom (Pi_com)
**작업 내용:** 카카오 로그인 전용 인증 시스템 구축

---

## 📋 작업 개요

기존 구글 로그인 및 익명 로그인을 제거하고, **카카오 로그인만을 사용하는 인증 시스템**으로 전환했습니다. 웹과 모바일(Android/iOS) 모두 카카오 공식 문서에 따라 구현하였으며, 카카오 디자인 가이드를 준수한 로그인 버튼을 적용했습니다.

---

## ✅ 완료된 작업

### 1. 카카오 로그인 구현 (공식 문서 기준)

#### **웹 (Web)**
- Flutter SDK의 `AuthCodeClient.instance.authorize()` 사용
- OAuth 2.0 리다이렉트 방식 구현
- JavaScript SDK로 토큰 교환 및 사용자 정보 가져오기
- localStorage를 통한 인가 코드 임시 저장 및 자동 로그인

#### **모바일 (Android/iOS)**
- 카카오톡 앱 설치 여부 확인 후 최적 로그인 방식 선택
  - 카카오톡 설치 시: `loginWithKakaoTalk()` → 실패 시 `loginWithKakaoAccount()` 폴백
  - 카카오톡 미설치 시: `loginWithKakaoAccount()` 직접 사용
- 토큰 검증: `AuthApi.instance.hasToken()` + `accessTokenInfo()`
- 로그아웃: `UserApi.instance.logout()`

### 2. 인증 시스템 단순화

#### **제거된 기능**
- ❌ Google 로그인 (완전 제거)
- ❌ 익명 로그인 (완전 제거)

#### **남은 기능**
- ✅ 카카오 로그인 (단일 인증 수단)
- ✅ Firebase Custom Token 연동
- ✅ Firestore 사용자 데이터 저장

### 3. 카카오 디자인 가이드 준수 버튼

**공식 가이드라인:**
- 컨테이너 색상: `#FEE500` (카카오 노란색)
- 심볼·레이블 색상: `#000000` (검은색 85% 투명도)
- Border Radius: 12픽셀
- 레이블: "카카오 로그인"
- 심볼: 말풍선 아이콘

**구현 방식:**
- ~~이미지 asset 사용~~ → Asset 로딩 문제로 제거
- ✅ **Flutter 위젯으로 직접 구현** (안정적이고 유지보수 용이)

### 4. SDK 초기화 및 설정

#### **main.dart에서 전역 초기화**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 카카오 SDK 초기화
  KakaoSdk.init(
    nativeAppKey: '8e75eecf0338c9b84861f8000b664336',
    javaScriptAppKey: 'aabc80253972e0504d05951a66373200',
  );

  // Firebase 초기화
  await Firebase.initializeApp(...);

  runApp(MyApp());
}
```

#### **Android 설정 (AndroidManifest.xml)**
- `AuthCodeCustomTabsActivity` 추가 (OAuth 로그인용)
- Custom URL Scheme: `kakao8e75eecf0338c9b84861f8000b664336://oauth`
- KakaoTalk 공유 Scheme: `kakao8e75eecf0338c9b84861f8000b664336://kakaolink`
- `android:exported="true"` (Android 12+ 필수)
- `com.kakao.talk` 패키지 쿼리 권한

#### **웹 설정 (index.html)**
- Kakao JavaScript SDK 2.7.4 로드
- `KakaoSdk.init()` with JavaScript Key
- Promise 기반 API 호출 (success/fail 콜백 방식 deprecated)

---

## 🛠 수정한 파일 목록

### 핵심 파일

| 파일 경로 | 수정 내용 |
|----------|---------|
| `lib/main.dart` | 카카오 SDK 전역 초기화 추가 |
| `lib/features/auth/data/datasources/kakao_auth_datasource.dart` | 모바일/웹 로그인 로직, 중복 초기화 제거 |
| `lib/features/auth/data/datasources/web_kakao_auth.dart` | 웹 전용 토큰 교환 로직 (JavaScript interop) |
| `lib/features/auth/presentation/screens/auth_screen.dart` | localStorage 감지, 카카오 버튼 위젯 구현 |
| `lib/features/auth/domain/repositories/auth_repository.dart` | Google/익명 로그인 메서드 제거 |
| `lib/features/auth/data/repositories/auth_repository_impl.dart` | `signInWithKakaoCode()` 추가, Google 코드 제거 |
| `lib/features/auth/presentation/providers/auth_provider.dart` | Google/익명 provider 제거 |
| `web/index.html` | Kakao SDK 초기화, Promise 기반 API 수정 |
| `web/oauth/callback.html` | 인가 코드 localStorage 저장 및 리다이렉트 |
| `android/app/src/main/AndroidManifest.xml` | AuthCodeCustomTabsActivity, URL Scheme 추가 |
| `pubspec.yaml` | kakao_flutter_sdk 패키지 추가 |
| `firebase.json` | `/oauth/callback` rewrite 규칙 추가 |

### 삭제한 파일

- `lib/features/auth/domain/usecases/sign_in_with_google.dart`
- `lib/features/auth/domain/usecases/sign_in_anonymously.dart`

---

## 🐛 해결한 주요 문제

### 1. Asset 로딩 에러
**문제:**
```
Unable to load asset: "assets/images/kakao_login_button.png"
Unable to load asset: "AssetManifest.bin.json"
```

**원인:** 이미지 asset 참조 문제 및 빌드 캐시 이슈

**해결:**
- 이미지 asset 방식 제거
- Flutter 위젯으로 카카오 버튼 직접 구현 (더 안정적)

### 2. 카카오 API 토큰 교환 실패
**문제:**
```
Invalid parameter keys: success,fail at API.request
```

**원인:** Kakao JavaScript SDK 2.x에서 success/fail 콜백 방식이 deprecated됨

**해결:**
```javascript
// ❌ 이전 (작동 안함)
Kakao.API.request({
  url: '/v2/user/me',
  success: function(userInfo) { ... },
  fail: function(error) { ... }
});

// ✅ 수정 (Promise 기반)
Kakao.API.request({
  url: '/v2/user/me'
})
.then(function(userInfo) { ... })
.catch(function(error) { ... });
```

### 3. SDK 초기화 에러
**문제:**
```
Assertion failed: !isDisposed
"Trying to render a disposed EngineFlutterView."
```

**원인:** 카카오 SDK가 초기화되기 전에 위젯이 렌더링됨

**해결:**
- `main.dart`에서 `runApp()` 전에 `KakaoSdk.init()` 호출
- `kakao_auth_datasource.dart`의 중복 초기화 제거

### 4. 웹 리다이렉트 무한 로딩
**문제:** OAuth 리다이렉트 후 auth 화면에서 무한 로딩

**원인:**
- 리다이렉트된 인가 코드를 처리하지 못함
- localStorage에서 코드를 읽는 로직 누락

**해결:**
- `auth_screen.dart`의 `initState()`에서 `_checkLocalStorageForKakaoCode()` 추가
- `callback.html`에서 인가 코드를 localStorage에 저장 후 `/#/auth`로 리다이렉트

### 5. Firestore 사용자 정보 미저장
**문제:** 웹 로그인 후 사용자 정보가 Firestore에 저장되지 않음

**원인:** 웹에서 카카오 사용자 정보를 가져오지 못함

**해결:**
- JavaScript에서 `Kakao.API.request({ url: '/v2/user/me' })` 호출
- 사용자 정보를 `user_info` 객체에 포함하여 Dart로 전달
- `signInWithKakaoCode()`에서 Firestore에 저장

---

## 📊 최종 아키텍처

```
┌─────────────────────────────────────────────────┐
│                    사용자                        │
└────────────────┬────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────┐
│            카카오 로그인 버튼                     │
│  (auth_screen.dart - 카카오 디자인 가이드 준수)   │
└────────────────┬────────────────────────────────┘
                 │
         ┌───────┴────────┐
         │                │
         ▼                ▼
    ┌────────┐      ┌──────────┐
    │  Web   │      │  Mobile  │
    └────┬───┘      └─────┬────┘
         │                │
         ▼                ▼
┌──────────────┐  ┌────────────────┐
│ AuthCodeClient│  │  UserApi.login  │
│  .authorize() │  │  WithKakaoTalk │
└──────┬────────┘  └────────┬───────┘
       │                    │
       ▼                    ▼
┌──────────────┐  ┌────────────────┐
│callback.html │  │ Access Token   │
│(localStorage)│  │                │
└──────┬────────┘  └────────┬───────┘
       │                    │
       ▼                    │
┌──────────────┐            │
│ JS SDK       │            │
│ Token Exchange│           │
└──────┬────────┘           │
       │                    │
       └────────┬───────────┘
                │
                ▼
    ┌────────────────────────┐
    │  Firebase Cloud Function │
    │  (Custom Token 생성)      │
    └────────────┬─────────────┘
                 │
                 ▼
    ┌────────────────────────┐
    │   Firebase Auth        │
    │   (signInWithCustomToken)│
    └────────────┬─────────────┘
                 │
                 ▼
    ┌────────────────────────┐
    │   Firestore            │
    │   (사용자 데이터 저장)    │
    └────────────────────────┘
```

---

## 🧪 테스트 방법

### 웹 테스트
1. https://picom-team.web.app 접속
2. "카카오 로그인" 버튼 클릭
3. 카카오 계정으로 로그인
4. 리다이렉트 후 자동으로 앱 진입 확인

**예상 콘솔 로그:**
```
✅ Kakao SDK initialized
🔍 Found Kakao auth code in localStorage: ...
🔍 Processing Kakao login with code from localStorage...
✅ Access token received: ...
✅ User info received: { id: ..., kakao_account: { email: ... } }
✅ Custom Token received: ...
✅ Kakao Sign-In Success: UID=...
```

### Android 테스트
```bash
flutter run -d android
```

1. 카카오톡 설치 여부에 따라 로그인 방식 자동 선택
2. 로그인 완료 후 Firebase 연동 확인

### iOS 테스트 (설정 필요)
```bash
flutter run -d ios
```

**주의:** iOS는 Xcode에서 URL Scheme 설정 필요
- URL Types에 `kakao8e75eecf0338c9b84861f8000b664336` 추가
- Info.plist에 허용 스킴 추가

---

## 📦 의존성 패키지

```yaml
dependencies:
  kakao_flutter_sdk_common: ^1.9.6   # 카카오 SDK 공통
  kakao_flutter_sdk_user: ^1.9.6     # 카카오 로그인
  firebase_core: ^4.2.0              # Firebase Core
  firebase_auth: ^6.1.1              # Firebase Auth
  cloud_firestore: ^6.0.3            # Firestore
  cloud_functions: ^6.0.3            # Cloud Functions
  dio: ^5.4.0                        # HTTP 클라이언트
  flutter_dotenv: ^5.1.0             # 환경 변수
  js: ^0.7.1                         # JavaScript interop (웹)
```

---

## 🚀 배포 상태

### Firebase Hosting
- **URL:** https://picom-team.web.app
- **Status:** ✅ 배포 완료
- **마지막 배포:** 2025-11-15
- **빌드 상태:** 성공

### 설정 필요 사항

#### Kakao Developers Console
카카오 개발자 콘솔에서 Redirect URI 등록 필요:

**웹 플랫폼:**
- `http://localhost:7502/oauth/callback.html` (개발용)
- `https://picom-team.web.app/oauth/callback.html` (프로덕션)

**Android 플랫폼:**
- 패키지명: `app.picom.team.pi_com`
- 키 해시: (Android Studio에서 생성)

**iOS 플랫폼:**
- Bundle ID: (Xcode에서 확인)
- URL Scheme: `kakao8e75eecf0338c9b84861f8000b664336`

---

## 📝 주요 코드 스니펫

### 카카오 로그인 버튼 (Flutter 위젯)

```dart
// lib/features/auth/presentation/screens/auth_screen.dart:142
SizedBox(
  width: double.infinity,
  height: 50,
  child: ElevatedButton(
    onPressed: _handleKakaoSignIn,
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFFEE500), // 카카오 노란색
      foregroundColor: Colors.black.withOpacity(0.85),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // 12픽셀
      ),
      elevation: 0,
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 카카오 심볼 (말풍선)
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.85),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Icon(
              Icons.chat_bubble,
              size: 14,
              color: const Color(0xFFFEE500),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '카카오 로그인',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black.withOpacity(0.85),
          ),
        ),
      ],
    ),
  ),
)
```

### 모바일 로그인 로직

```dart
// lib/features/auth/data/datasources/kakao_auth_datasource.dart:31
Future<User?> _signInMobile() async {
  kakao.OAuthToken token;

  // 카카오톡 설치 여부 확인
  if (await kakao.isKakaoTalkInstalled()) {
    try {
      // 카카오톡으로 로그인
      token = await kakao.UserApi.instance.loginWithKakaoTalk();
    } catch (error) {
      // 실패 시 카카오계정으로 폴백
      token = await kakao.UserApi.instance.loginWithKakaoAccount();
    }
  } else {
    // 카카오계정으로 로그인
    token = await kakao.UserApi.instance.loginWithKakaoAccount();
  }

  // 사용자 정보 가져오기
  kakao.User kakaoUser = await kakao.UserApi.instance.me();

  // Cloud Function에서 Firebase Custom Token 받기
  final customToken = await _getCustomTokenFromServer(token.accessToken);

  // Firebase 로그인
  final userCredential = await _auth.signInWithCustomToken(customToken);

  return userCredential.user;
}
```

---

## 🎯 다음 단계 (Optional)

### 1. iOS 설정 완료
- [ ] Xcode에서 URL Scheme 설정
- [ ] Info.plist 설정
- [ ] iOS 빌드 테스트

### 2. 추가 기능
- [ ] 카카오톡 공유 기능 추가
- [ ] 카카오 친구 목록 연동
- [ ] 카카오 채널 추가

### 3. 성능 최적화
- [ ] 토큰 갱신 자동화
- [ ] 오프라인 모드 지원
- [ ] 로그인 상태 지속성 개선

---

## 📚 참고 문서

- [Kakao Flutter SDK 공식 문서](https://developers.kakao.com/docs/latest/ko/flutter/getting-started)
- [Kakao 로그인 디자인 가이드](https://developers.kakao.com/docs/latest/ko/kakaologin/design-guide)
- [Firebase Custom Token](https://firebase.google.com/docs/auth/admin/create-custom-tokens)

---

**작성자:** Claude Code
**최종 수정일:** 2025-11-15
**버전:** 1.0.4+5
