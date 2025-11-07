// lib/features/parts_price/data/datasources/part_remote_datasource.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/part_model.dart';
import '../models/base_part_model.dart';

abstract class PartRemoteDataSource {
  Future<PartModel?> getPartById(String partId);
  Stream<List<BasePartModel>> getBasePartsByCategory(String category);
  Future<List<Map<String, dynamic>>> getPriceHistory(String basePartId);
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
  Future<List<Map<String, dynamic>>> getPriceHistory(String basePartId) async {
    try {
      // priceHistory 컬렉션에서 6시간 간격 스냅샷 조회 (최근 30일)
      final startDate = DateTime.now().subtract(const Duration(days: 30));

      final querySnapshot = await _firestore
          .collection('priceHistory')
          .where('basePartId', isEqualTo: basePartId)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .orderBy('timestamp', descending: false)
          .get();

      final pricePoints = <Map<String, dynamic>>[];

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final timestamp = data['timestamp'] as Timestamp?;
        final averagePrice = data['averagePrice'] as num?;
        final lowestPrice = data['lowestPrice'] as num?;
        final availableCount = data['availableCount'] as num?;

        if (timestamp != null && averagePrice != null) {
          pricePoints.add({
            'date': timestamp.toDate().toIso8601String(),
            'price': averagePrice.toDouble(), // 평균가를 차트에 표시
            'count': availableCount ?? 0,
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
