// lib/features/auth/data/datasources/firestore_user_datasource.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/models/user_model.dart';

/// Firestore의 users 컬렉션 전용 데이터 소스
/// User 데이터의 CRUD만 담당
class FirestoreUserDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _usersCollection = 'users';

  /// User 생성 또는 업데이트 (일반)
  /// 주의: 이 메서드는 isAdmin 필드를 덮어씁니다.
  /// 카카오 로그인에서는 사용하지 말고 getUser()만 사용하세요.
  Future<void> createOrUpdateUser(UserModel user) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(user.uid)
          .set(
        user.toFirestore(),
        SetOptions(merge: true),
      );
      debugPrint('✅ [FirestoreUserDataSource] User created/updated: ${user.uid}');
    } catch (e) {
      throw Exception('Failed to create/update user: $e');
    }
  }

  /// User 생성 또는 업데이트 (isAdmin 필드 보존)
  /// 이메일 로그인 등에서 사용
  Future<void> createOrUpdateUserWithAdminPreserve(UserModel user) async {
    try {
      // 기존 사용자 정보 먼저 확인
      final existingDoc = await _firestore
          .collection(_usersCollection)
          .doc(user.uid)
          .get();

      // 업데이트할 데이터 준비
      final dataToUpdate = user.toFirestore();

      // 기존 사용자가 있고 isAdmin 필드가 있다면 보존
      if (existingDoc.exists) {
        final existingData = existingDoc.data() as Map<String, dynamic>;
        if (existingData.containsKey('isAdmin')) {
          final existingIsAdmin = existingData['isAdmin'];
          dataToUpdate['isAdmin'] = existingIsAdmin;  // 기존 값 유지
          debugPrint('⚠️ [FirestoreUserDataSource] Preserving isAdmin value: $existingIsAdmin for user ${user.uid}');
        }
      }

      await _firestore
          .collection(_usersCollection)
          .doc(user.uid)
          .set(
        dataToUpdate,
        SetOptions(merge: true),
      );

      debugPrint('✅ [FirestoreUserDataSource] User updated with admin preserve: ${user.uid}');
    } catch (e) {
      throw Exception('Failed to create/update user with admin preserve: $e');
    }
  }

  /// User 조회
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _firestore
          .collection(_usersCollection)
          .doc(uid)
          .get();

      if (!doc.exists) {
        debugPrint('⚠️ [FirestoreUserDataSource] User not found: $uid');
        return null;
      }

      final userModel = UserModel.fromFirestore(doc);
      debugPrint('✅ [FirestoreUserDataSource] User loaded: $uid, isAdmin: ${userModel.isAdmin}');
      return userModel;
    } catch (e) {
      debugPrint('❌ [FirestoreUserDataSource] Failed to get user: $e');
      throw Exception('Failed to get user: $e');
    }
  }

  /// User 삭제
  Future<void> deleteUser(String uid) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(uid)
          .delete();
      debugPrint('✅ [FirestoreUserDataSource] User deleted: $uid');
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  /// User 실시간 스트림
  Stream<UserModel?> userStream(String uid) {
    try {
      return _firestore
          .collection(_usersCollection)
          .doc(uid)
          .snapshots()
          .map((doc) {
        if (!doc.exists) return null;
        final userModel = UserModel.fromFirestore(doc);
        debugPrint('📡 [FirestoreUserDataSource] User stream update: $uid, isAdmin: ${userModel.isAdmin}');
        return userModel;
      });
    } catch (e) {
      throw Exception('Failed to get user stream: $e');
    }
  }
}