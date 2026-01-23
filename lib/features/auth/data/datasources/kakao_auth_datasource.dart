// lib/features/auth/data/datasources/kakao_auth_datasource.dart

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:dio/dio.dart';
import 'package:pi_com/core/constants/app_constants.dart';
import 'package:pi_com/core/utils/app_logger.dart';
import 'web_kakao_auth.dart' if (dart.library.io) 'web_kakao_auth_stub.dart';

class KakaoAuthDataSource {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 카카오 로그인
  Future<User?> signIn() async {
    if (kIsWeb) {
      return await _signInWeb();
    } else {
      return await _signInMobile();
    }
  }

  /// 모바일 카카오 로그인 (공식 문서 권장 방식)
  Future<User?> _signInMobile() async {
    try {
      AppLogger.d('[Mobile] Starting Kakao Sign-In...', tag: 'KakaoAuth');

      kakao.OAuthToken token;

      // 카카오톡 설치 여부 확인 후 최적의 로그인 방식 선택
      if (await kakao.isKakaoTalkInstalled()) {
        AppLogger.d('Kakao Talk is installed, trying Kakao Talk login', tag: 'KakaoAuth');
        try {
          // 카카오톡으로 로그인
          token = await kakao.UserApi.instance.loginWithKakaoTalk();
          AppLogger.i('Kakao Talk login success', tag: 'KakaoAuth');
        } catch (error) {
          AppLogger.w('Kakao Talk login failed, fallback to Kakao Account: $error', tag: 'KakaoAuth');

          // 사용자가 카카오톡 로그인을 취소한 경우 등 예외 처리
          // 카카오계정으로 로그인 시도
          token = await kakao.UserApi.instance.loginWithKakaoAccount();
          AppLogger.i('Kakao Account login success (fallback)', tag: 'KakaoAuth');
        }
      } else {
        AppLogger.d('Kakao Talk not installed, using Kakao Account login', tag: 'KakaoAuth');
        // 카카오계정으로 로그인
        token = await kakao.UserApi.instance.loginWithKakaoAccount();
        AppLogger.i('Kakao Account login success', tag: 'KakaoAuth');
      }

      AppLogger.i('Kakao OAuth Token obtained: ${token.accessToken.substring(0, 20)}...', tag: 'KakaoAuth');

      // 카카오 사용자 정보 가져오기
      AppLogger.d('Getting Kakao user info...', tag: 'KakaoAuth');
      kakao.User kakaoUser = await kakao.UserApi.instance.me();

      AppLogger.i('Kakao user info obtained - ID: ${kakaoUser.id}, Email: ${kakaoUser.kakaoAccount?.email}', tag: 'KakaoAuth');

      // Cloud Function에 카카오 토큰 전송하여 Firebase Custom Token 받기
      AppLogger.d('Requesting Firebase Custom Token from Cloud Function...', tag: 'KakaoAuth');

      final customToken = await _getCustomTokenFromServer(token.accessToken);

      if (customToken == null) {
        throw Exception('Failed to get custom token from server');
      }

      AppLogger.i('Custom Token received: ${customToken.substring(0, 20)}...', tag: 'KakaoAuth');

      // Firebase에 Custom Token으로 로그인
      AppLogger.d('Signing in to Firebase with Custom Token...', tag: 'KakaoAuth');
      final UserCredential userCredential = await _auth.signInWithCustomToken(customToken);

      AppLogger.i('Kakao Sign-In Success: UID=${userCredential.user?.uid}, Email=${kakaoUser.kakaoAccount?.email}', tag: 'KakaoAuth');

      return userCredential.user;

    } catch (e, stackTrace) {
      AppLogger.e('Kakao Sign-In failed: $e', tag: 'KakaoAuth');
      AppLogger.e('StackTrace: $stackTrace', tag: 'KakaoAuth');
      rethrow;
    }
  }

  /// Cloud Function에서 Firebase Custom Token 받기
  Future<String?> _getCustomTokenFromServer(String kakaoAccessToken) async {
    try {
      // Firebase Cloud Functions API 엔드포인트
      const String cloudFunctionUrl = 'https://asia-northeast3-picom-team.cloudfunctions.net/api/auth/kakao';

      AppLogger.d('Sending request to Cloud Function: $cloudFunctionUrl', tag: 'KakaoAuth');

      final dio = Dio(BaseOptions(
        connectTimeout: AppConstants.httpConnectTimeout,
        receiveTimeout: AppConstants.httpReceiveTimeout,
      ));
      final response = await dio.post(
        cloudFunctionUrl,
        data: {'kakaoAccessToken': kakaoAccessToken},
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      AppLogger.i('Server response: ${response.statusCode}', tag: 'KakaoAuth');
      AppLogger.d('Response data: ${response.data}', tag: 'KakaoAuth');

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        if (data.containsKey('customToken')) {
          return data['customToken'] as String;
        }
      }

      AppLogger.e('Invalid response from server: ${response.data}', tag: 'KakaoAuth');
      return null;
    } catch (e) {
      AppLogger.e('Failed to get custom token: $e', tag: 'KakaoAuth');

      // DioException의 경우 더 자세한 정보 출력
      if (e is DioException) {
        AppLogger.e('Response status: ${e.response?.statusCode}', tag: 'KakaoAuth');
        AppLogger.e('Response data: ${e.response?.data}', tag: 'KakaoAuth');
        AppLogger.e('Response headers: ${e.response?.headers}', tag: 'KakaoAuth');
      }

      return null;
    }
  }

  // 웹에서 가져온 카카오 사용자 정보를 저장할 변수
  Map<String, dynamic>? _webKakaoUserInfo;

  /// 웹 카카오 로그인 (공식 Flutter SDK 방식 - 리다이렉트)
  Future<User?> _signInWeb() async {
    AppLogger.d('[Web] Starting Kakao Sign-In with AuthCodeClient...', tag: 'KakaoAuth');

    // 카카오 공식 방식: AuthCodeClient로 인가 코드 요청 (리다이렉트)
    final redirectUri = '${Uri.base.origin}/oauth/callback.html';
    AppLogger.d('Redirect URI: $redirectUri', tag: 'KakaoAuth');

    // 카카오 인증 화면으로 리다이렉트
    // 이 메서드는 페이지를 리다이렉트하므로 반환되지 않음
    await kakao.AuthCodeClient.instance.authorize(
      redirectUri: redirectUri,
    );

    // 이 코드는 실행되지 않음 (페이지가 리다이렉트됨)
    // 실제 로그인 처리 플로우:
    // 1. 카카오 인증 페이지로 리다이렉트
    // 2. 사용자 인증 완료
    // 3. callback.html로 리다이렉트 (인가 코드 포함)
    // 4. callback.html이 localStorage에 코드 저장 후 /#/auth로 이동
    // 5. auth_screen.dart의 signInWithCode()에서 로그인 완료
    return null;
  }

  /// 카카오 로그아웃 (공식 문서 방식)
  Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        // 모바일: 카카오 토큰 폐기
        try {
          await kakao.UserApi.instance.logout();
          AppLogger.i('Kakao logout success - tokens revoked', tag: 'KakaoAuth');
        } catch (error) {
          // 이미 로그아웃 상태이거나 토큰이 없는 경우
          AppLogger.w('Kakao logout warning (already logged out?): $error', tag: 'KakaoAuth');
        }
      } else {
        // 웹: 카카오 SDK 로그아웃 없이 Firebase만 로그아웃
        // (AuthCodeClient는 로그아웃 메서드를 제공하지 않음)
        // 웹 사용자 정보 초기화
        _webKakaoUserInfo = null;
        AppLogger.i('Web Kakao user info cleared', tag: 'KakaoAuth');
      }

      // Firebase 로그아웃
      await _auth.signOut();
      AppLogger.i('Firebase sign-out success', tag: 'KakaoAuth');
    } catch (e) {
      AppLogger.e('Sign-Out failed: $e', tag: 'KakaoAuth');
      rethrow;
    }
  }

  /// 현재 카카오 사용자 정보 가져오기
  Future<kakao.User?> getKakaoUser() async {
    if (kIsWeb) {
      // 웹: 저장된 사용자 정보가 없으면 null 반환
      // (웹에서는 kakao.User 객체를 만들 수 없으므로 null 반환)
      return null;
    }

    try {
      return await kakao.UserApi.instance.me();
    } catch (e) {
      AppLogger.e('Failed to get Kakao user: $e', tag: 'KakaoAuth');
      return null;
    }
  }

  /// 웹에서 가져온 카카오 사용자 정보 반환
  Map<String, dynamic>? getWebKakaoUserInfo() {
    return _webKakaoUserInfo;
  }

  /// 카카오 토큰 존재 여부 및 유효성 확인 (공식 문서 방식)
  Future<bool> hasValidToken() async {
    if (kIsWeb) {
      // 웹은 토큰 검증 불가 (AuthCodeClient 사용)
      return false;
    }

    try {
      // 토큰 존재 여부 확인
      if (await kakao.AuthApi.instance.hasToken()) {
        AppLogger.d('Token exists, validating...', tag: 'KakaoAuth');

        try {
          // 토큰 유효성 검증
          kakao.AccessTokenInfo tokenInfo =
              await kakao.UserApi.instance.accessTokenInfo();
          AppLogger.i('Token is valid - expires in ${tokenInfo.expiresIn} seconds', tag: 'KakaoAuth');
          return true;
        } catch (error) {
          AppLogger.w('Token validation failed (expired or invalid): $error', tag: 'KakaoAuth');
          return false;
        }
      } else {
        AppLogger.i('No token found', tag: 'KakaoAuth');
        return false;
      }
    } catch (error) {
      AppLogger.e('Token check failed: $error', tag: 'KakaoAuth');
      return false;
    }
  }

  /// 웹에서 인가 코드로 로그인 (리다이렉트 폴백용)
  Future<User?> signInWithCode(String code) async {
    if (!kIsWeb) {
      throw Exception('signInWithCode is only available on web');
    }

    try {
      AppLogger.d('[Web] Starting Kakao Sign-In with code...', tag: 'KakaoAuth');

      // 코드를 토큰으로 교환
      final loginResult = await WebKakaoAuth.exchangeCodeForToken(code);

      if (loginResult == null) {
        throw Exception('Failed to exchange code for token');
      }

      AppLogger.i('[Web] Token obtained: ${loginResult.accessToken.substring(0, 20)}...', tag: 'KakaoAuth');

      // 사용자 정보 저장
      if (loginResult.userInfo != null) {
        _webKakaoUserInfo = loginResult.userInfo;
        AppLogger.i('[Web] User info stored: $_webKakaoUserInfo', tag: 'KakaoAuth');
      }

      // Cloud Function에 카카오 토큰 전송하여 Firebase Custom Token 받기
      AppLogger.d('[Web] Requesting Firebase Custom Token from Cloud Function...', tag: 'KakaoAuth');
      final customToken = await _getCustomTokenFromServer(loginResult.accessToken);

      if (customToken == null) {
        throw Exception('Failed to get custom token from server');
      }

      AppLogger.i('[Web] Custom Token received: ${customToken.substring(0, 20)}...', tag: 'KakaoAuth');

      // Firebase에 Custom Token으로 로그인
      AppLogger.d('[Web] Signing in to Firebase with Custom Token...', tag: 'KakaoAuth');
      final UserCredential userCredential = await _auth.signInWithCustomToken(customToken);

      AppLogger.i('[Web] Kakao Sign-In Success: UID=${userCredential.user?.uid}', tag: 'KakaoAuth');

      return userCredential.user;

    } catch (e, stackTrace) {
      AppLogger.e('Web Kakao Sign-In with code failed: $e', tag: 'KakaoAuth');
      AppLogger.e('StackTrace: $stackTrace', tag: 'KakaoAuth');
      rethrow;
    }
  }

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
