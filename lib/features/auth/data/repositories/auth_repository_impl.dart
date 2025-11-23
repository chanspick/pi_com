// lib/features/auth/data/repositories/auth_repository_impl.dart

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/kakao_auth_datasource.dart';
import '../datasources/firestore_user_datasource.dart';

/// 인증 Repository 구현체 (카카오 로그인 전용)
class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _auth;
  final KakaoAuthDataSource _kakaoAuth;
  final FirestoreUserDataSource _firestoreUser;

  AuthRepositoryImpl({
    required FirebaseAuth auth,
    required KakaoAuthDataSource kakaoAuth,
    required FirestoreUserDataSource firestoreUser,
  })  : _auth = auth,
        _kakaoAuth = kakaoAuth,
        _firestoreUser = firestoreUser;

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  Future<UserModel> signInWithKakao() async {
    try {
      // 카카오 로그인 수행
      final user = await _kakaoAuth.signIn();

      if (user == null) {
        throw Exception('Kakao Sign-In returned null user');
      }

      // ✅ Cloud Functions에서 이미 사용자를 생성/업데이트했으므로
      // Firestore에서 사용자 정보를 읽기만 함
      debugPrint('🔍 [AuthRepository] Getting user from Firestore: ${user.uid}');

      // 약간의 지연을 주어 Cloud Functions가 완료될 시간을 확보
      await Future.delayed(const Duration(milliseconds: 500));

      final userModel = await _firestoreUser.getUser(user.uid);

      if (userModel == null) {
        // Cloud Functions가 아직 처리 중일 수 있으므로 재시도
        debugPrint('⚠️ [AuthRepository] User not found, retrying...');
        await Future.delayed(const Duration(seconds: 1));

        final retryUserModel = await _firestoreUser.getUser(user.uid);
        if (retryUserModel == null) {
          throw Exception('User not found in Firestore after sign-in');
        }
        return retryUserModel;
      }

      debugPrint('✅ [AuthRepository] User loaded from Firestore: ${userModel.toString()}');
      return userModel;

    } catch (e) {
      debugPrint('❌ [AuthRepository] Failed to sign in with Kakao: $e');
      throw Exception('Failed to sign in with Kakao: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _kakaoAuth.signOut();
      await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user signed in');

      await _firestoreUser.deleteUser(user.uid);
      await user.delete();
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }

  /// 웹에서 인가 코드로 카카오 로그인 (리다이렉트 폴백용)
  Future<UserModel> signInWithKakaoCode(String code) async {
    if (!kIsWeb) {
      throw Exception('signInWithKakaoCode is only available on web');
    }

    try {
      // 코드로 로그인
      final user = await _kakaoAuth.signInWithCode(code);

      if (user == null) {
        throw Exception('Kakao Sign-In with code returned null user');
      }

      // ✅ Cloud Functions에서 이미 사용자를 생성/업데이트했으므로
      // Firestore에서 사용자 정보를 읽기만 함
      debugPrint('🔍 [AuthRepository] Getting user from Firestore: ${user.uid}');

      // 약간의 지연을 주어 Cloud Functions가 완료될 시간을 확보
      await Future.delayed(const Duration(milliseconds: 500));

      final userModel = await _firestoreUser.getUser(user.uid);

      if (userModel == null) {
        // Cloud Functions가 아직 처리 중일 수 있으므로 재시도
        debugPrint('⚠️ [AuthRepository] User not found, retrying...');
        await Future.delayed(const Duration(seconds: 1));

        final retryUserModel = await _firestoreUser.getUser(user.uid);
        if (retryUserModel == null) {
          throw Exception('User not found in Firestore after sign-in');
        }
        return retryUserModel;
      }

      debugPrint('✅ [AuthRepository] User loaded from Firestore: ${userModel.toString()}');
      return userModel;

    } catch (e) {
      debugPrint('❌ [AuthRepository] Failed to sign in with Kakao code: $e');
      throw Exception('Failed to sign in with Kakao code: $e');
    }
  }

  @override
  Future<bool> isAdmin(String uid) async {
    try {
      final userModel = await _firestoreUser.getUser(uid);
      return userModel?.isAdmin ?? false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<UserModel> signInWithEmail(String email, String password) async {
    try {
      // Firebase Auth 이메일 로그인
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw Exception('Email Sign-In returned null user');
      }

      // Firestore에서 기존 사용자 정보 가져오기
      final existingUser = await _firestoreUser.getUser(user.uid);

      if (existingUser != null) {
        // ✅ 기존 사용자는 그대로 반환 (isAdmin 보존)
        return existingUser;
      }

      // 신규 사용자 (Firestore에 없는 경우)
      final userModel = UserModel(
        uid: user.uid,
        email: user.email ?? email,
        displayName: user.displayName ?? email.split('@')[0],
        photoURL: user.photoURL,
        provider: 'email',
        createdAt: DateTime.now(),
        isAdmin: false,  // 신규 사용자는 false
      );

      await _firestoreUser.createOrUpdateUserWithAdminPreserve(userModel);
      return userModel;
    } catch (e) {
      throw Exception('Failed to sign in with email: $e');
    }
  }

  @override
  Future<UserModel> signUpWithEmail(String email, String password, String displayName) async {
    try {
      // Firebase Auth 이메일 회원가입
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw Exception('Email Sign-Up returned null user');
      }

      // displayName 설정
      await user.updateDisplayName(displayName);

      // UserModel 생성
      final userModel = UserModel(
        uid: user.uid,
        email: email,
        displayName: displayName,
        photoURL: user.photoURL,
        provider: 'email',
        createdAt: DateTime.now(),
        isAdmin: false,  // 신규 사용자는 항상 false
      );

      await _firestoreUser.createOrUpdateUser(userModel);  // 신규 사용자는 그대로 생성
      return userModel;
    } catch (e) {
      throw Exception('Failed to sign up with email: $e');
    }
  }
}