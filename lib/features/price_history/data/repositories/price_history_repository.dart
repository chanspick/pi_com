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

  // NOTE: createPriceSnapshot, createAllPriceSnapshots 메서드들은 제거됨
  // 이제 Cloud Functions가 listing 변경 시 자동으로 PriceHistory를 생성합니다.
}
