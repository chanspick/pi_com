// lib/features/auth/data/datasources/web_kakao_auth.dart

@JS()
library;

import 'dart:async';
import 'package:js/js.dart';
import 'dart:js_util' as js_util;

/// JavaScript window.kakaoExchangeCodeForToken() 함수
/// 인가 코드를 액세스 토큰으로 교환
@JS('kakaoExchangeCodeForToken')
external dynamic _kakaoExchangeCodeForToken(String code);

/// 카카오 로그인 결과를 담는 클래스
class KakaoLoginResult {
  final String accessToken;
  final Map<String, dynamic>? userInfo;

  KakaoLoginResult({
    required this.accessToken,
    this.userInfo,
  });
}

/// 웹 환경에서 카카오 인증 Helper
/// Flutter SDK의 AuthCodeClient가 인가 코드 요청을 처리하고,
/// 이 클래스는 코드→토큰 교환만 담당합니다.
class WebKakaoAuth {

  /// JavaScript 객체를 Dart Map으로 변환
  static Map<String, dynamic>? _convertJsObjectToMap(dynamic jsObject) {
    if (jsObject == null) return null;

    try {
      final map = <String, dynamic>{};

      // id
      if (js_util.hasProperty(jsObject, 'id')) {
        map['id'] = js_util.getProperty(jsObject, 'id');
      }

      // kakao_account
      if (js_util.hasProperty(jsObject, 'kakao_account')) {
        final kakaoAccount = js_util.getProperty(jsObject, 'kakao_account');
        final accountMap = <String, dynamic>{};

        // email
        if (js_util.hasProperty(kakaoAccount, 'email')) {
          accountMap['email'] = js_util.getProperty(kakaoAccount, 'email');
        }

        // profile
        if (js_util.hasProperty(kakaoAccount, 'profile')) {
          final profile = js_util.getProperty(kakaoAccount, 'profile');
          final profileMap = <String, dynamic>{};

          if (js_util.hasProperty(profile, 'nickname')) {
            profileMap['nickname'] = js_util.getProperty(profile, 'nickname');
          }
          if (js_util.hasProperty(profile, 'profile_image_url')) {
            profileMap['profile_image_url'] = js_util.getProperty(profile, 'profile_image_url');
          }

          accountMap['profile'] = profileMap;
        }

        map['kakao_account'] = accountMap;
      }

      return map;
    } catch (e) {
      print('❌ Failed to convert JS object to Map: $e');
      return null;
    }
  }

  /// 인가 코드를 액세스 토큰으로 교환
  static Future<KakaoLoginResult?> exchangeCodeForToken(String code) async {
    try {
      print('🔍 [Web] Exchanging code for token...');

      // JavaScript Promise를 Dart Future로 변환
      final promise = _kakaoExchangeCodeForToken(code);
      final result = await js_util.promiseToFuture(promise);

      if (result == null) {
        print('❌ No result received from code exchange');
        return null;
      }

      // 결과가 문자열인 경우 (토큰만)
      if (result is String) {
        print('✅ Token exchange success - Token only: ${result.substring(0, 20)}...');
        return KakaoLoginResult(accessToken: result);
      }

      // 결과가 객체인 경우 (토큰 + 사용자 정보)
      String? accessToken;
      Map<String, dynamic>? userInfo;

      // access_token 추출
      if (js_util.hasProperty(result, 'access_token')) {
        accessToken = js_util.getProperty(result, 'access_token') as String?;
      }

      // user_info 추출
      if (js_util.hasProperty(result, 'user_info')) {
        final userInfoJs = js_util.getProperty(result, 'user_info');
        userInfo = _convertJsObjectToMap(userInfoJs);
      }

      if (accessToken != null) {
        print('✅ Token exchange success - Token: ${accessToken.substring(0, 20)}...');
        if (userInfo != null) {
          print('✅ User info received: ID=${userInfo['id']}');
        }
        return KakaoLoginResult(
          accessToken: accessToken,
          userInfo: userInfo,
        );
      }

      print('❌ Invalid result structure');
      return null;

    } catch (e) {
      print('❌ Code exchange exception: $e');
      return null;
    }
  }
}