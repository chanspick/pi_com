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
    // parts 컬렉션 사용 중단: base_parts를 사용하도록 변경됨
    // 이 메서드는 현재 사용되지 않으며, null을 반환합니다.
    return null;
  }

  @override
  Stream<List<BasePartModel>> getBasePartsByCategory(String category) {
    return _firestore
        .collection('base_parts')
        .where('category', isEqualTo: category)
        .orderBy('modelName')  // 모델명 기준 정렬 (매물 없어도 표시)
        .snapshots()
        .map((snapshot) {
          final parts = snapshot.docs
              .map((doc) => BasePartModel.fromFirestore(doc))
              .toList();
          // 클라이언트에서 매물 있는 것 우선 정렬
          parts.sort((a, b) {
            // 매물 있는 것 먼저
            if (a.listingCount > 0 && b.listingCount == 0) return -1;
            if (a.listingCount == 0 && b.listingCount > 0) return 1;
            // 둘 다 매물 있으면 매물 수 기준
            if (a.listingCount > 0 && b.listingCount > 0) {
              return b.listingCount.compareTo(a.listingCount);
            }
            // 둘 다 매물 없으면 모델명 기준
            return a.modelName.compareTo(b.modelName);
          });
          return parts;
        });
  }

  @override
  Future<List<Map<String, dynamic>>> getPriceHistory(String basePartId) async {
    try {
      // priceHistory 컬렉션에서 가격 변동 이력 조회 (최근 30일)
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
        final listingCount = data['listingCount'] as num?;

        if (timestamp != null && averagePrice != null && lowestPrice != null) {
          pricePoints.add({
            'date': timestamp.toDate().toIso8601String(),
            'averagePrice': averagePrice.toDouble(),
            'lowestPrice': lowestPrice.toDouble(),
            'count': listingCount ?? 0,
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
