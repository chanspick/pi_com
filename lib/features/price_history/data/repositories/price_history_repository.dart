// lib/features/price_history/data/repositories/price_history_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/models/price_history_model.dart';

/// 가격 이력 리포지토리 (6시간 간격 스냅샷)
/// 백엔드 스케줄러로 6시간마다 자동화 예정
class PriceHistoryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 특정 부품의 가격 이력 조회 (최근 N일)
  Future<List<PriceHistory>> getPriceHistory(
    String basePartId, {
    int days = 30,
  }) async {
    final startDate = DateTime.now().subtract(Duration(days: days));

    final snapshot = await _firestore
        .collection('priceHistory')
        .where('basePartId', isEqualTo: basePartId)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .orderBy('timestamp', descending: false) // 오래된 것부터 (차트용)
        .get();

    return snapshot.docs.map((doc) => PriceHistory.fromFirestore(doc)).toList();
  }

  /// 가격 이력 추가 또는 업데이트 (6시간 간격 스냅샷)
  Future<void> addOrUpdatePriceHistory(PriceHistory history) async {
    await _firestore
        .collection('priceHistory')
        .doc(history.id)
        .set(history.toFirestore(), SetOptions(merge: true));
  }

  /// 특정 타임스탬프의 가격 이력 조회
  Future<PriceHistory?> getPriceHistoryByTimestamp(
    String basePartId,
    DateTime timestamp,
  ) async {
    final docId = PriceHistory.generateId(basePartId, timestamp);

    final doc = await _firestore.collection('priceHistory').doc(docId).get();

    if (!doc.exists) return null;
    return PriceHistory.fromFirestore(doc);
  }

  /// 부품별 가격 통계 계산 (현재 판매 중인 AVAILABLE listings 기준)
  Future<Map<String, dynamic>> calculatePriceStats(String basePartId) async {
    final snapshot = await _firestore
        .collection('listings')
        .where('basePartId', isEqualTo: basePartId)
        .where('status', isEqualTo: 'available')
        .get();

    if (snapshot.docs.isEmpty) {
      return {
        'lowestPrice': 0,
        'averagePrice': 0,
        'highestPrice': 0,
        'count': 0,
      };
    }

    final prices = snapshot.docs.map((doc) => doc['price'] as int).toList();
    prices.sort();

    final lowest = prices.first;
    final highest = prices.last;
    final average = prices.reduce((a, b) => a + b) ~/ prices.length;

    return {
      'lowestPrice': lowest,
      'averagePrice': average,
      'highestPrice': highest,
      'count': prices.length,
    };
  }

  /// 현재 시각 기준으로 특정 basePart의 가격 스냅샷 생성
  Future<void> createPriceSnapshot(String basePartId) async {
    final stats = await calculatePriceStats(basePartId);

    if (stats['count'] == 0) {
      // 매물이 없으면 스냅샷 생성하지 않음
      return;
    }

    final now = DateTime.now();
    final alignedTime = PriceHistory.get6HourAlignedTimestamp(now);
    final docId = PriceHistory.generateId(basePartId, alignedTime);

    final snapshot = PriceHistory(
      id: docId,
      basePartId: basePartId,
      timestamp: alignedTime,
      lowestPrice: stats['lowestPrice'] as int,
      averagePrice: stats['averagePrice'] as int,
      highestPrice: stats['highestPrice'] as int,
      availableCount: stats['count'] as int,
      createdAt: now,
    );

    await addOrUpdatePriceHistory(snapshot);
  }

  /// 모든 basePart에 대해 가격 스냅샷 생성 (수동 실행용 / 스케줄러용)
  Future<void> createAllPriceSnapshots() async {
    // base_parts 컬렉션에서 모든 부품 조회
    final basePartsSnapshot = await _firestore
        .collection('base_parts')
        .where('listingCount', isGreaterThan: 0)
        .get();

    for (final doc in basePartsSnapshot.docs) {
      final basePartId = doc.id;
      try {
        await createPriceSnapshot(basePartId);
        print('✅ 스냅샷 생성 완료: $basePartId');
      } catch (e) {
        print('❌ 스냅샷 생성 실패: $basePartId - $e');
      }
    }

    print('🎉 모든 가격 스냅샷 생성 완료!');
  }
}
