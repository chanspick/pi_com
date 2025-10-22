import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/models/user_model.dart';

/// Firestore의 users 컬렉션 전용 데이터 소스
/// User 데이터의 CRUD만 담당
class FirestoreUserDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _usersCollection = 'users';

  /// User 생성 또는 업데이트
  Future<void> createOrUpdateUser(UserModel user) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(user.uid)
          .set(
        user.toFirestore(),
        SetOptions(merge: true),
      );
    } catch (e) {
      throw Exception('Failed to create/update user: $e');
    }
  }

  /// User 조회
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _firestore
          .collection(_usersCollection)
          .doc(uid)
          .get();

      if (!doc.exists) return null;

      return UserModel.fromFirestore(doc);
    } catch (e) {
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
        return UserModel.fromFirestore(doc);
      });
    } catch (e) {
      throw Exception('Failed to get user stream: $e');
    }
  }
}
