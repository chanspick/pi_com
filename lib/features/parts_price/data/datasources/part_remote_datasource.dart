// lib/features/parts_price/data/datasources/part_remote_datasource.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/part_model.dart';
import '../models/base_part_model.dart';

abstract class PartRemoteDataSource {
  Future<PartModel?> getPartById(String partId);
  Stream<List<BasePartModel>> getBasePartsByCategory(String category);
  Future<List<Map<String, dynamic>>> getPriceHistory(String partId);
  Future<List<BasePartModel>> searchBaseParts(String query);
}

class PartRemoteDataSourceImpl implements PartRemoteDataSource {
  final FirebaseFirestore _firestore;

  PartRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<PartModel?> getPartById(String partId) async {
    try {
      final doc = await _firestore.collection('parts').doc(partId).get();
      if (!doc.exists) return null;
      return PartModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to fetch part: $e');
    }
  }

  @override
  Stream<List<BasePartModel>> getBasePartsByCategory(String category) {
    return _firestore
        .collection('base_parts')
        .where('category', isEqualTo: category)
        .orderBy('listingCount', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => BasePartModel.fromFirestore(doc)).toList());
  }

  @override
  Future<List<Map<String, dynamic>>> getPriceHistory(String partId) async {
    try {
      // listings 컬렉션에서 해당 partId의 판매 이력 조회
      final querySnapshot = await _firestore
          .collection('listings')
          .where('partId', isEqualTo: partId)
          .where('status', isEqualTo: 'sold')
          .orderBy('soldAt', descending: false)
          .limit(100)
          .get();

      final pricePoints = <Map<String, dynamic>>[];

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final soldAt = data['soldAt'] as Timestamp?;
        final price = data['price'] as num?;

        if (soldAt != null && price != null) {
          pricePoints.add({
            'date': soldAt.toDate().toIso8601String(),
            'price': price.toDouble(),
            'count': 1,
          });
        }
      }

      return pricePoints;
    } catch (e) {
      throw Exception('Failed to fetch price history: $e');
    }
  }

  @override
  Future<List<BasePartModel>> searchBaseParts(String query) async {
    try {
      // Firestore의 제한으로 인해 클라이언트 측에서 필터링
      final snapshot = await _firestore
          .collection('base_parts')
          .orderBy('listingCount', descending: true)
          .limit(200)
          .get();

      final lowerQuery = query.toLowerCase();
      final results = snapshot.docs
          .map((doc) => BasePartModel.fromFirestore(doc))
          .where((part) =>
      part.modelName.toLowerCase().contains(lowerQuery) ||
          part.category.toLowerCase().contains(lowerQuery))
          .toList();

      return results;
    } catch (e) {
      throw Exception('Failed to search parts: $e');
    }
  }
}
