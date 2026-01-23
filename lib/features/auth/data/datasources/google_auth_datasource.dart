// lib/features/auth/data/datasources/google_auth_datasource.dart

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pi_com/core/utils/app_logger.dart' show AppLogger;

class GoogleAuthDataSource {
  // ✅ 6.2.1 버전에서는 이렇게만 해도 충분
  late final GoogleSignIn _googleSignIn;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  GoogleAuthDataSource() {
    // ✅ 웹과 모바일 분리
    if (kIsWeb) {
      // 웹에서는 GoogleSignIn 사용 안 함
      _googleSignIn = GoogleSignIn(); // 더미 인스턴스
    } else {
      // 모바일: google-services.json에서 자동으로 clientId 읽음
      _googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );
    }
  }

  Future<User?> signIn() async {
    if (kIsWeb) {
      AppLogger.w('Web: Using popup instead of GoogleSignIn', tag: 'GoogleAuth');
      try {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        final UserCredential userCredential =
        await _auth.signInWithPopup(googleProvider);
        AppLogger.i('Web Sign-In Success: ${userCredential.user?.email}', tag: 'GoogleAuth');
        return userCredential.user;
      } catch (e) {
        AppLogger.e('Web Sign-In failed: $e', tag: 'GoogleAuth');
        rethrow;
      }
    }

    // 모바일 로그인
    try {
      AppLogger.d('[1/5] Starting Google Sign-In...', tag: 'GoogleAuth');

      // ✅ 중요: 기존 로그인 상태 확인
      await _googleSignIn.signOut(); // 이전 세션 정리

      AppLogger.d('[2/5] Calling _googleSignIn.signIn()...', tag: 'GoogleAuth');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        AppLogger.w('[3/5] User canceled sign-in', tag: 'GoogleAuth');
        return null;
      }
      AppLogger.i('[3/5] GoogleSignInAccount obtained: ${googleUser.email}', tag: 'GoogleAuth');

      AppLogger.d('[4/5] Getting authentication...', tag: 'GoogleAuth');
      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      AppLogger.d('accessToken: ${googleAuth.accessToken != null ? "exists" : "null"}', tag: 'GoogleAuth');
      AppLogger.d('idToken: ${googleAuth.idToken != null ? "exists" : "null"}', tag: 'GoogleAuth');

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      AppLogger.d('[5/5] Signing in with credential...', tag: 'GoogleAuth');
      final UserCredential userCredential =
      await _auth.signInWithCredential(credential);

      AppLogger.i('Google Sign-In Success: ${userCredential.user?.email}', tag: 'GoogleAuth');
      return userCredential.user;
    } catch (e, stackTrace) {
      AppLogger.e('Google Sign-In failed: $e', tag: 'GoogleAuth');
      AppLogger.e('StackTrace: $stackTrace', tag: 'GoogleAuth');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      if (!kIsWeb) {
        await _googleSignIn.signOut();
      }
      AppLogger.i('Sign-Out Success', tag: 'GoogleAuth');
    } catch (e) {
      AppLogger.e('Sign-Out failed: $e', tag: 'GoogleAuth');
      rethrow;
    }
  }

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  GoogleSignIn get instance => _googleSignIn;
}
