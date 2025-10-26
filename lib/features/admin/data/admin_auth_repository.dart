// lib/features/admin/data/admin_auth_repository.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/user_model.dart';

/// Admin 전용 인증 Repository
class AdminAuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 현재 로그인된 사용자
  User? get currentUser => _auth.currentUser;

  /// 인증 상태 변화 스트림
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// 이메일/패스워드로 로그인 + Admin 체크
  Future<(UserModel?, String)> signInWithEmailAndCheckAdmin({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Firebase Auth 로그인
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        return (null, '로그인에 실패했습니다.');
      }

      // 2. Admin 체크
      return await _checkAdminAndGetUser(user.uid);

    } on FirebaseAuthException catch (e) {
      return (null, _getAuthErrorMessage(e.code));
    } catch (e) {
      return (null, '알 수 없는 오류: $e');
    }
  }

  /// 현재 사용자가 Admin인지 확인 ← 이 메서드가 필요합니다!
  Future<(UserModel?, String)> checkCurrentUserIsAdmin() async {
    final user = _auth.currentUser;
    if (user == null) {
      return (null, '로그인이 필요합니다.');
    }
    return await _checkAdminAndGetUser(user.uid);
  }

  /// Firestore에서 User 조회 + Admin 체크 (내부 메서드)
  Future<(UserModel?, String)> _checkAdminAndGetUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();

      if (!doc.exists) {
        await _auth.signOut();
        return (null, '사용자 정보를 찾을 수 없습니다.');
      }

      final userModel = UserModel.fromFirestore(doc);

      if (!userModel.isAdmin) {
        await _auth.signOut();
        return (null, '관리자 권한이 없습니다.');
      }

      // lastLoginAt 업데이트
      await _firestore
          .collection('users')
          .doc(uid)
          .update({'lastLoginAt': FieldValue.serverTimestamp()});

      return (userModel, '');
    } catch (e) {
      await _auth.signOut();
      return (null, '권한 확인 실패: $e');
    }
  }

  /// 로그아웃
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Auth 에러 메시지 변환
  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return '등록되지 않은 이메일입니다.';
      case 'wrong-password':
        return '비밀번호가 올바르지 않습니다.';
      case 'invalid-email':
        return '이메일 형식이 올바르지 않습니다.';
      case 'user-disabled':
        return '비활성화된 계정입니다.';
      case 'too-many-requests':
        return '너무 많은 시도가 있었습니다. 잠시 후 다시 시도해주세요.';
      case 'invalid-credential':
        return '이메일 또는 비밀번호가 올바르지 않습니다.';
      default:
        return '로그인에 실패했습니다. ($code)';
    }
  }
}
