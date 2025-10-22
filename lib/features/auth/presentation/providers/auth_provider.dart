// lib/features/auth/presentation/providers/auth_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/models/user_model.dart';
import '../../../../shared/providers.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/usecases/sign_in_with_google.dart';  // ✅ 추가
import '../../domain/usecases/sign_in_anonymously.dart';  // ✅ 추가
import '../../domain/usecases/sign_out.dart';  // ✅ 추가

/// ========================================
/// Auth Repository Provider
/// ========================================

/// AuthRepository 인스턴스 제공
final authRepositoryProvider = Provider<AuthRepositoryImpl>((ref) {
  return AuthRepositoryImpl(
    auth: ref.watch(firebaseAuthProvider),
    googleAuth: ref.watch(googleAuthDataSourceProvider),
    firestoreUser: ref.watch(firestoreUserDataSourceProvider),
  );
});

/// ========================================
/// Use Case Providers (✅ 추가)
/// ========================================

/// Google 로그인 Use Case
final signInWithGoogleUseCaseProvider = Provider<SignInWithGoogle>((ref) {
  return SignInWithGoogle(ref.watch(authRepositoryProvider));
});

/// 익명 로그인 Use Case
final signInAnonymouslyUseCaseProvider = Provider<SignInAnonymously>((ref) {
  return SignInAnonymously(ref.watch(authRepositoryProvider));
});

/// 로그아웃 Use Case
final signOutUseCaseProvider = Provider<SignOut>((ref) {
  return SignOut(ref.watch(authRepositoryProvider));
});

/// ========================================
/// 인증 상태 Providers
/// ========================================

/// Firebase Auth 상태 변경 스트림
final authStateChangesProvider = StreamProvider<User?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return auth.authStateChanges();
});

/// 현재 로그인한 Firebase User
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  return authState.value;
});

/// ========================================
/// UserModel Providers
/// ========================================

/// 현재 사용자의 UserModel (Firestore에서 실시간 스트림)
final currentUserModelStreamProvider = StreamProvider<UserModel?>((ref) {
  final user = ref.watch(currentUserProvider);

  if (user == null) {
    return Stream.value(null);
  }

  // Firestore에서 실시간으로 UserModel 가져오기
  final firestoreUser = ref.watch(firestoreUserDataSourceProvider);
  return firestoreUser.userStream(user.uid);
});

/// 현재 사용자의 UserModel (동기적으로 접근)
final currentUserModelProvider = Provider<UserModel?>((ref) {
  final userModelAsync = ref.watch(currentUserModelStreamProvider);
  return userModelAsync.value;
});

/// ========================================
/// Admin 여부 Provider
/// ========================================

/// 현재 사용자가 Admin인지 확인
final isAdminProvider = Provider<bool>((ref) {
  final userModel = ref.watch(currentUserModelProvider);
  return userModel?.isAdmin ?? false;
});

/// ========================================
/// 로그인 여부 Provider
/// ========================================

/// 사용자가 로그인했는지 확인
final isLoggedInProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});

/// ========================================
/// 사용자 표시 이름 Provider
/// ========================================

/// 현재 사용자의 표시 이름 (없으면 '게스트')
final userDisplayNameProvider = Provider<String>((ref) {
  final userModel = ref.watch(currentUserModelProvider);
  return userModel?.displayName ?? '게스트';
});
