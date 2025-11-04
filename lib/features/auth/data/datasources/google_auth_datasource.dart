// lib/features/auth/data/datasources/google_auth_datasource.dart

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      debugPrint('⚠️ Web: Using popup instead of GoogleSignIn');
      try {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        final UserCredential userCredential =
        await _auth.signInWithPopup(googleProvider);
        debugPrint('✅ Web Sign-In Success: ${userCredential.user?.email}');
        return userCredential.user;
      } catch (e) {
        debugPrint('❌ Web Sign-In failed: $e');
        rethrow;
      }
    }

    // 모바일 로그인
    try {
      debugPrint('🔍 [1/5] Starting Google Sign-In...');

      // ✅ 중요: 기존 로그인 상태 확인
      await _googleSignIn.signOut(); // 이전 세션 정리

      debugPrint('🔍 [2/5] Calling _googleSignIn.signIn()...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('⚠️ [3/5] User canceled sign-in');
        return null;
      }
      debugPrint('✅ [3/5] GoogleSignInAccount obtained: ${googleUser.email}');

      debugPrint('🔍 [4/5] Getting authentication...');
      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      debugPrint('🔍 accessToken: ${googleAuth.accessToken != null ? "exists" : "null"}');
      debugPrint('🔍 idToken: ${googleAuth.idToken != null ? "exists" : "null"}');

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      debugPrint('🔍 [5/5] Signing in with credential...');
      final UserCredential userCredential =
      await _auth.signInWithCredential(credential);

      debugPrint('✅ Google Sign-In Success: ${userCredential.user?.email}');
      return userCredential.user;
    } catch (e, stackTrace) {
      debugPrint('❌ Google Sign-In failed: $e');
      debugPrint('❌ StackTrace: $stackTrace');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      if (!kIsWeb) {
        await _googleSignIn.signOut();
      }
      debugPrint('✅ Sign-Out Success');
    } catch (e) {
      debugPrint('❌ Sign-Out failed: $e');
      rethrow;
    }
  }

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  GoogleSignIn get instance => _googleSignIn;
}
