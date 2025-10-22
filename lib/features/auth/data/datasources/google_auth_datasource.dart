// lib/features/auth/data/datasources/google_auth_datasource.dart

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Google Sign-In 7.x 사용
class GoogleAuthDataSource {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isInitialized = false;

  /// ✅ Public 초기화 메서드
  Future<void> initialize() async {
    if (!_isInitialized) {
      if (kIsWeb) {
        await _googleSignIn.initialize();
      } else {
        await _googleSignIn.initialize(
          serverClientId:
          '329187044859-d2v6bhhsormrv5on2ff2krsm271gssir.apps.googleusercontent.com',
        );
      }
      _isInitialized = true;
      debugPrint('✅ GoogleSignIn initialized');
    }
  }

  /// Google 로그인 (모바일 전용!)
  Future<User?> signIn() async {
    // ⚠️ 웹에서는 이 메서드를 호출하면 안 됨!
    if (kIsWeb) {
      debugPrint('⚠️ signIn() is not supported on web. Use renderButton instead.');
      return null;
    }

    try {
      await initialize();

      // ✅ 모바일: authenticate() 사용
      final googleUser = await _googleSignIn.authenticate();

      // ✅ 7.x: authentication 속성으로 토큰 접근
      final idToken = googleUser.authentication.idToken;

      if (idToken == null) {
        throw Exception('Failed to get ID token');
      }

      // ✅ 7.x: idToken만 사용
      final credential = GoogleAuthProvider.credential(idToken: idToken);

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      debugPrint('✅ Google Sign-In Success: ${user?.email}');
      return user;
    } catch (e) {
      debugPrint('❌ Google Sign-In failed: $e');
      rethrow;
    }
  }

  /// 로그아웃
  Future<void> signOut() async {
    try {
      await initialize();
      await _auth.signOut();
      await _googleSignIn.disconnect();
      debugPrint('✅ Sign-Out Success');
    } catch (e) {
      debugPrint('❌ Sign-Out failed: $e');
      rethrow;
    }
  }

  /// 현재 사용자
  User? get currentUser => _auth.currentUser;

  /// 인증 상태 스트림
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// GoogleSignIn 인스턴스 (renderButton용)
  GoogleSignIn get instance => _googleSignIn;
}
