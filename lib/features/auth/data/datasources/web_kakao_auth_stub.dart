// lib/features/auth/data/datasources/web_kakao_auth_stub.dart
// Stub for WebKakaoAuth on mobile platforms (dart.library.io)

/// Stub class for KakaoLoginResult (mobile platforms)
class KakaoLoginResult {
  final String accessToken;
  final Map<String, dynamic>? userInfo;

  KakaoLoginResult({
    required this.accessToken,
    this.userInfo,
  });
}

/// Stub class for WebKakaoAuth (mobile platforms)
/// This should never be called on mobile - runtime guards prevent execution
class WebKakaoAuth {
  static Future<KakaoLoginResult?> exchangeCodeForToken(String code) async {
    throw UnsupportedError('WebKakaoAuth is only available on web platforms');
  }
}
