// lib/features/auth/domain/repositories/auth_repository.dart

import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/models/user_model.dart';

/// 인증 Repository 인터페이스 (추상 클래스)
/// Clean Architecture: Domain Layer는 구체적인 구현을 모름
abstract class AuthRepository {
  /// 현재 로그인한 Firebase User
  User? get currentUser;

  /// Firebase Auth 상태 변경 스트림
  Stream<User?> get authStateChanges;

  /// 카카오 로그인
  Future<UserModel> signInWithKakao();

  /// 이메일/비밀번호 로그인
  Future<UserModel> signInWithEmail(String email, String password);

  /// 이메일/비밀번호 회원가입
  Future<UserModel> signUpWithEmail(String email, String password, String displayName);

  /// 로그아웃
  Future<void> signOut();

  /// 계정 삭제
  Future<void> deleteAccount();

  /// Admin 여부 확인
  Future<bool> isAdmin(String uid);
}
