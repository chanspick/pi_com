// lib/features/auth/data/repositories/auth_repository_impl.dart

import 'package:flutter/foundation.dart'; // 🆕 추가
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/google_auth_datasource.dart';
import '../datasources/firestore_user_datasource.dart';

/// 인증 Repository 구현체
class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _auth;
  final GoogleAuthDataSource _googleAuth;
  final FirestoreUserDataSource _firestoreUser;

  AuthRepositoryImpl({
    required FirebaseAuth auth,
    required GoogleAuthDataSource googleAuth,
    required FirestoreUserDataSource firestoreUser,
  })  : _auth = auth,
        _googleAuth = googleAuth,
        _firestoreUser = firestoreUser;

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  Future<UserModel> signInAnonymously() async {
    try {
      final userCredential = await _auth.signInAnonymously();
      final user = userCredential.user!;

      final userModel = UserModel.fromFirebaseUser(
        user,
        provider: 'anonymous',
      );

      await _firestoreUser.createOrUpdateUser(userModel);
      return userModel;
    } catch (e) {
      throw Exception('Failed to sign in anonymously: $e');
    }
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      // ✅ 웹에서는 이 메서드를 호출하면 안 됨!
      if (kIsWeb) {
        throw Exception('signInWithGoogle() is not supported on web. Use renderButton instead.');
      }

      // 모바일: 정상 호출
      final user = await _googleAuth.signIn();

      if (user == null) {
        throw Exception('Google Sign-In returned null user');
      }

      final userModel = UserModel.fromFirebaseUser(
        user,
        provider: 'google',
      );

      await _firestoreUser.createOrUpdateUser(userModel);
      return userModel;
    } catch (e) {
      throw Exception('Failed to sign in with Google: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _googleAuth.signOut();
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

  @override
  Future<void> reauthenticateWithGoogle() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user signed in');

      // ✅ 웹에서는 이 메서드를 호출하면 안 됨!
      if (kIsWeb) {
        throw Exception('reauthenticateWithGoogle() is not supported on web.');
      }

      // 모바일: Google 재인증
      final freshUser = await _googleAuth.signIn();

      if (freshUser == null) {
        throw Exception('Reauthentication failed: User is null');
      }

      if (freshUser.uid != user.uid) {
        throw Exception('Reauthentication failed: User mismatch');
      }
    } catch (e) {
      throw Exception('Failed to reauthenticate: $e');
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
}
