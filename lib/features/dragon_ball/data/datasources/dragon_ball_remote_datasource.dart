// lib/features/dragon_ball/data/datasources/dragon_ball_remote_datasource.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pi_com/core/models/dragon_ball_model.dart';

/// 드래곤볼 Remote DataSource 인터페이스
abstract class DragonBallRemoteDataSource {
  /// 사용자의 드래곤볼 목록 스트림
  Stream<List<DragonBallModel>> getUserDragonBalls(String userId);

  /// 특정 드래곤볼 조회
  Future<DragonBallModel?> getDragonBall(String userId, String dragonBallId);

  /// 드래곤볼 생성
  Future<String> createDragonBall(DragonBallModel dragonBall);

  /// 드래곤볼 업데이트
  Future<void> updateDragonBall(String userId, DragonBallModel dragonBall);

  /// 드래곤볼 삭제
  Future<void> deleteDragonBall(String userId, String dragonBallId);

  /// 보관 중인 드래곤볼만 조회
  Future<List<DragonBallModel>> getStoredDragonBalls(String userId);

  /// 만료 임박 드래곤볼 조회
  Future<List<DragonBallModel>> getExpiringSoonDragonBalls(String userId);
}

/// 드래곤볼 Remote DataSource 구현
class DragonBallRemoteDataSourceImpl implements DragonBallRemoteDataSource {
  final FirebaseFirestore _firestore;

  DragonBallRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<DragonBallModel>> getUserDragonBalls(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('dragonBalls')
        .orderBy('storedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        try {
          return DragonBallModel.fromFirestore(doc);
        } catch (e) {
          throw Exception('Failed to parse DragonBall: $e');
        }
      }).toList();
    });
  }

  @override
  Future<DragonBallModel?> getDragonBall(String userId, String dragonBallId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('dragonBalls')
          .doc(dragonBallId)
          .get();

      if (!doc.exists) return null;

      return DragonBallModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get DragonBall: $e');
    }
  }

  @override
  Future<String> createDragonBall(DragonBallModel dragonBall) async {
    try {
      final docRef = await _firestore
          .collection('users')
          .doc(dragonBall.userId)
          .collection('dragonBalls')
          .add(dragonBall.toMap());

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create DragonBall: $e');
    }
  }

  @override
  Future<void> updateDragonBall(String userId, DragonBallModel dragonBall) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('dragonBalls')
          .doc(dragonBall.dragonBallId)
          .update(dragonBall.toMap());
    } catch (e) {
      throw Exception('Failed to update DragonBall: $e');
    }
  }

  @override
  Future<void> deleteDragonBall(String userId, String dragonBallId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('dragonBalls')
          .doc(dragonBallId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete DragonBall: $e');
    }
  }

  @override
  Future<List<DragonBallModel>> getStoredDragonBalls(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('dragonBalls')
          .where('status', isEqualTo: 'stored')
          .orderBy('storedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return DragonBallModel.fromFirestore(doc);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get stored DragonBalls: $e');
    }
  }

  @override
  Future<List<DragonBallModel>> getExpiringSoonDragonBalls(String userId) async {
    try {
      // 현재 시간 + 3일
      final threeDaysLater = DateTime.now().add(const Duration(days: 3));

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('dragonBalls')
          .where('status', isEqualTo: 'stored')
          .where('expiresAt', isLessThan: Timestamp.fromDate(threeDaysLater))
          .orderBy('expiresAt', descending: false)
          .get();

      return snapshot.docs.map((doc) {
        return DragonBallModel.fromFirestore(doc);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get expiring DragonBalls: $e');
    }
  }
}
