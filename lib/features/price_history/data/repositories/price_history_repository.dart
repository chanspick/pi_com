// lib/features/price_history/data/repositories/price_history_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/models/price_history_model.dart';

/// 가격 이력 리포지토리
/// TODO: Cloud Functions로 가격 집계 및 저장 자동화 필요
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
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs.map((doc) => PriceHistory.fromFirestore(doc)).toList();
  }

  /// 가격 이력 추가 (Cloud Functions에서 사용)
  /// TODO: Cloud Functions 스케줄러로 매일 자동 실행
  Future<void> addPriceHistory(PriceHistory history) async {
    await _firestore
        .collection('priceHistory')
        .doc(history.id)
        .set(history.toFirestore());
  }

  /// 특정 날짜의 가격 이력 조회
  Future<PriceHistory?> getPriceHistoryByDate(
    String basePartId,
    DateTime date,
  ) async {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final docId = '${basePartId}_${dateOnly.year}-${dateOnly.month.toString().padLeft(2, '0')}-${dateOnly.day.toString().padLeft(2, '0')}';

    final doc = await _firestore.collection('priceHistory').doc(docId).get();

    if (!doc.exists) return null;
    return PriceHistory.fromFirestore(doc);
  }

  /// 부품별 가격 통계 계산 (현재 판매 중인 listings 기준)
  /// TODO: Cloud Functions로 자동화
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
}
