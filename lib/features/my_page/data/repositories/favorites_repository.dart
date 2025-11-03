// lib/features/my_page/data/repositories/favorites_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// 찜 목록 Repository
class FavoritesRepository {
  final FirebaseFirestore _firestore;

  FavoritesRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// 찜 추가
  Future<void> addFavorite(String userId, String listingId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(listingId)
        .set({
      'listingId': listingId,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 찜 제거
  Future<void> removeFavorite(String userId, String listingId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(listingId)
        .delete();
  }

  /// 찜 여부 확인
  Future<bool> isFavorite(String userId, String listingId) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(listingId)
        .get();
    return doc.exists;
  }

  /// 찜 목록 조회 (실시간)
  Stream<List<String>> getFavoritesStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.id).toList();
    });
  }

  /// 찜 목록 조회 (한번만)
  Future<List<String>> getFavorites(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .orderBy('addedAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => doc.id).toList();
  }
}
